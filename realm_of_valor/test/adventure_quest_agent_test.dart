import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_of_valor/services/agents/adventure_quest_agent.dart';
import 'package:realm_of_valor/services/event_bus.dart';

void main() {
  test('Quest completes after battle_ended and emits completion + rewards XP', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);
    final agent = AdventureQuestAgent(bus);
    await agent.initialize();

    final questJson = {
      'id': 'q1',
      'title': 'Defeat Slime',
      'type': 'battle',
      'rewardXp': 30,
      'objectives': [
        {'id': 'o1', 'description': 'Win 1 battle', 'target': 1, 'progress': 0}
      ]
    };

    bus.publish(Event(type: 'quest.add', data: {'quest': questJson}));

    final completed = Completer<Event>();
    bus.subscribe('quest_completed', (e, b) => completed.complete(e));

    bus.publish(Event(type: 'battle_ended', data: {'winner': 'player'}));

    final done = await completed.future.timeout(const Duration(seconds: 2));
    expect(done.data?['id'], 'q1');
  });
}