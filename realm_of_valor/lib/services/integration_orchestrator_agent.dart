import 'dart:async';
import 'package:flutter/foundation.dart';

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
  bool _persistenceOnline = true;
  String? _activeQuestId;

  VoidCallback? _interceptorDisposer;
  StreamSubscription<Event>? _errorSub;
  Timer? _healthTimer;

  void registerAgent(AgentDescriptor descriptor) {
    _registry.add(descriptor);
  }

  @override
  String get name => 'IntegrationOrchestrator';

  @override
  Future<void> onInitialize() async {
    _interceptorDisposer = bus.addInterceptor((event) {
      if (event.type == 'persistence.offline') {
        _persistenceOnline = false;
        return event;
      }
      if (event.type == 'persistence.online') {
        _persistenceOnline = true;
        return event;
      }

      if (_activeQuestId != null && event.type.startsWith('quest.')) {
        return Event(
          type: event.type,
          data: event.data,
          priority: EventPriority.high,
          correlationId: event.correlationId,
          expectsReply: event.expectsReply,
          timestamp: event.timestamp,
        );
      }
      if (!_persistenceOnline && event.type.startsWith('data.')) {
        _offlineQueue.add(event);
        return null;
      }
      return event;
    });

    bus.subscribe('agent.heartbeat', (evt, _) {
      final agent = evt.data?['agent'] as String?;
      if (agent != null) _lastHeartbeat[agent] = DateTime.now();
    });

    bus.subscribe('persistence.offline', (evt, _) {
      bus.publish(Event(type: 'ui.notify', data: {'level': 'warning', 'message': 'Offline mode: changes will sync later.'}));
    });
    bus.subscribe('persistence.online', (evt, _) {
      for (final e in List<Event>.from(_offlineQueue)) {
        bus.publish(e);
        _offlineQueue.remove(e);
      }
      bus.publish(Event(type: 'ui.notify', data: {'level': 'info', 'message': 'Back online. Changes synced.'}));
    });

    bus.subscribe('quest.active_set', (evt, _) {
      _activeQuestId = evt.data?['questId'] as String?;
    });

    _errorSub = bus.stream.listen((_) {}, onError: (Object error, StackTrace st) {
      bus.publish(Event(type: 'ui.notify', data: {'level': 'error', 'message': error.toString()}));
    });

    bus.subscribe('app.shutdown', (evt, _) async {
      await onDispose();
    });

    for (final desc in _registry.where((a) => a.essential)) {
      await _startAgent(desc);
    }

    Future<void>.delayed(const Duration(milliseconds: 500), () async {
      for (final desc in _registry.where((a) => !a.essential)) {
        await _startAgent(desc);
      }
    });

    Timer.periodic(const Duration(seconds: 20), (_) => _checkHealth());

    // Periodic health summary
    _healthTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final stats = bus.getStats();
      final now = DateTime.now();
      final lateAgents = _lastHeartbeat.entries
          .where((e) => now.difference(e.value) > heartbeatTimeout)
          .map((e) => e.key)
          .toList();
      bus.publish(Event(type: 'orchestrator.health', data: {
        'queue_len': stats.queueLength,
        'drops': stats.droppedTotal,
        'drops_by_type': stats.droppedByType,
        'late_agents': lateAgents,
        'registry_size': _registry.length,
      }));
    });
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
        entry.value.dispose();
        _scheduleRestart(agentName);
      }
    }
  }

  @override
  Future<void> onDispose() async {
    _interceptorDisposer?.call();
    await _errorSub?.cancel();
    _healthTimer?.cancel();
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