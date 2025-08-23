import 'dart:async';

import 'base_agent.dart';
import 'event_bus.dart';

class AgentDescriptor {
  AgentDescriptor({required this.name, required this.factory, this.essential = true});
  final String name;
  final BaseAgent Function(EventBus bus) factory;
  final bool essential;
}

class IntegrationOrchestratorAgent extends BaseAgent {
  IntegrationOrchestratorAgent(super.bus);

  final Map<String, BaseAgent> _agents = <String, BaseAgent>{};
  final Map<String, int> _restartCounts = <String, int>{};
  final Map<String, DateTime> _lastHeartbeat = <String, DateTime>{};
  final List<Event> _offlineQueue = <Event>[];

  Duration heartbeatTimeout = const Duration(seconds: 45);

  final List<AgentDescriptor> _registry = <AgentDescriptor>[];

  void registerAgent(AgentDescriptor descriptor) {
    _registry.add(descriptor);
  }

  @override
  String get name => 'IntegrationOrchestrator';

  @override
  Future<void> onInitialize() async {
    // Subscribe to heartbeats
    bus.subscribe('agent.heartbeat', (evt, _) {
      final agent = evt.data?['agent'] as String?;
      if (agent != null) _lastHeartbeat[agent] = DateTime.now();
    });

    // Subscribe to persistence offline/online
    bus.subscribe('persistence.offline', (evt, _) {
      // Start queueing non-essential events
      // Orchestrator could set a flag; for simplicity, we just store here
    });
    bus.subscribe('persistence.online', (evt, _) {
      // Replay queued events
      for (final e in List<Event>.from(_offlineQueue)) {
        bus.publish(e);
        _offlineQueue.remove(e);
      }
    });

    // Initialize essential agents immediately
    for (final desc in _registry.where((a) => a.essential)) {
      await _startAgent(desc);
    }

    // Lazy-load non-essential agents after a short delay
    Future<void>.delayed(const Duration(milliseconds: 500), () async {
      for (final desc in _registry.where((a) => !a.essential)) {
        await _startAgent(desc);
      }
    });

    // Health monitoring loop
    Timer.periodic(const Duration(seconds: 20), (_) => _checkHealth());
  }

  Future<void> _startAgent(AgentDescriptor desc) async {
    try {
      final instance = desc.factory(bus);
      await instance.initialize();
      _agents[desc.name] = instance;
      _lastHeartbeat[desc.name] = DateTime.now();
    } catch (e) {
      _scheduleRestart(desc.name);
    }
  }

  void _scheduleRestart(String agentName) {
    final count = (_restartCounts[agentName] ?? 0) + 1;
    _restartCounts[agentName] = count;
    final backoff = Duration(seconds: (count * 2).clamp(2, 60));
    Timer(backoff, () async {
      final desc = _registry.firstWhere((a) => a.name == agentName, orElse: () => AgentDescriptor(name: agentName, factory: (b) => _NoopAgent(b)));
      await _startAgent(desc);
    });
  }

  void _checkHealth() {
    final now = DateTime.now();
    for (final entry in _agents.entries) {
      final agentName = entry.key;
      final last = _lastHeartbeat[agentName];
      if (last == null) continue;
      if (now.difference(last) > heartbeatTimeout) {
        // Missed heartbeat; try restart
        entry.value.dispose();
        _scheduleRestart(agentName);
      }
    }
  }

  @override
  Future<void> onDispose() async {
    for (final agent in _agents.values) {
      await agent.dispose();
    }
    _agents.clear();
  }
}

class _NoopAgent extends BaseAgent {
  _NoopAgent(super.bus);
  @override
  String get name => 'Noop';
  @override
  Future<void> onInitialize() async {}
  @override
  Future<void> onDispose() async {}
}