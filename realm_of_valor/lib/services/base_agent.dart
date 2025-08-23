import 'dart:async';

import 'event_bus.dart';

abstract class BaseAgent {
  BaseAgent(this.bus, {this.heartbeatInterval = const Duration(seconds: 15)});

  final EventBus bus;
  final Duration heartbeatInterval;

  Timer? _heartbeatTimer;
  bool _initialized = false;

  String get name;

  Future<void> initialize() async {
    if (_initialized) return;
    await onInitialize();
    _startHeartbeat();
    _initialized = true;
  }

  Future<void> onInitialize();

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      bus.publish(Event(type: 'agent.heartbeat', data: {'agent': name}));
    });
  }

  Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    await onDispose();
  }

  Future<void> onDispose();
}