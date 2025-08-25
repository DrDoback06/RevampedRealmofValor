import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_of_valor/services/agents/ui_ux_agent.dart';
import 'package:realm_of_valor/services/event_bus.dart';

void main() {
  test('Achievement triggers ui.notify', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);
    final agent = UIUXAgent(bus);
    await agent.initialize();

    final notified = Completer<Event>();
    bus.subscribe('ui.notify', (e, b) => notified.complete(e));

    bus.publish(Event(type: 'achievement_unlocked', data: {'title': 'Tester'}));

    final evt = await notified.future.timeout(const Duration(seconds: 2));
    expect(evt.data?['message'], 'Tester');
  });

  test('Battle end triggers ui.banner', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);
    final agent = UIUXAgent(bus);
    await agent.initialize();

    final banner = Completer<Event>();
    bus.subscribe('ui.banner', (e, b) => banner.complete(e));

    bus.publish(Event(type: 'battle_ended', data: {'winner': 'player'}));
    final evt = await banner.future.timeout(const Duration(seconds: 2));
    expect(evt.data?['text'], 'Victory!');
  });
}
