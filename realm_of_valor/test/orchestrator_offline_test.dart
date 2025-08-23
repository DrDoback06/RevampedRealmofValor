import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_of_valor/services/event_bus.dart';
import 'package:realm_of_valor/services/integration_orchestrator_agent.dart';

void main() {
  test('Offline queue drops data.* and replays when back online', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);
    final orch = IntegrationOrchestratorAgent(bus);
    await orch.initialize();

    final delivered = <Event>[];
    bus.subscribe('data.save', (e, b) => delivered.add(e));

    // Go offline
    bus.publish(Event(type: 'persistence.offline'));

    // Publish data event; should be queued (not delivered yet)
    bus.publish(Event(type: 'data.save', data: {'x': 1}));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(delivered, isEmpty);

    // Back online -> replay queued
    bus.publish(Event(type: 'persistence.online'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(delivered.length, 1);
    expect(delivered.first.data?['x'], 1);
  });

  test('Errors are routed to ui.notify', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);
    final orch = IntegrationOrchestratorAgent(bus);
    await orch.initialize();

    final notified = Completer<Event>();
    bus.subscribe('ui.notify', (e, b) {
      if (!notified.isCompleted) notified.complete(e);
    });

    // Cause an error in a subscriber
    bus.subscribe('boom', (e, b) => throw StateError('boom'));
    bus.publish(Event(type: 'boom'));

    final evt = await notified.future.timeout(const Duration(seconds: 2));
    expect(evt.data?['level'], 'error');
  });
}