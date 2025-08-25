import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_of_valor/services/agents/ai_companion_agent.dart';
import 'package:realm_of_valor/services/event_bus.dart';

void main() {
  test('Set personality and ask for leveling tip', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);
    final agent = AICompanionAgent(bus);
    await agent.initialize();

    bus.publish(Event(type: 'companion.set_personality', data: {'personality': 'coach'}));

    final reply = Completer<Event>();
    bus.subscribe('companion.reply', (e, b) => reply.complete(e));

    bus.publish(Event(type: 'companion.ask', data: {'q': 'How do I level up faster?'}));
    final evt = await reply.future.timeout(const Duration(seconds: 2));
    expect((evt.data?['text'] as String).contains('XP'), true);
  });

  test('Battle loss triggers encouragement tip', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);
    final agent = AICompanionAgent(bus);
    await agent.initialize();

    final reply = Completer<Event>();
    bus.subscribe('companion.reply', (e, b) => reply.complete(e));

    bus.publish(Event(type: 'battle_ended', data: {'winner': 'enemy'}));
    final evt = await reply.future.timeout(const Duration(seconds: 2));
    expect((evt.data?['text'] as String).toLowerCase().contains('don'), true);
  });
}
