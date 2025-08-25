import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_of_valor/services/agents/battle_system_agent.dart';
import 'package:realm_of_valor/services/event_bus.dart';

void main() {
  test('Simple PvE battle flow produces battle_ended with player winner', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);
    final agent = BattleSystemAgent(bus);
    await agent.initialize();

    bus.publish(Event(type: 'battle.start', data: {
      'player_name': 'Hero',
      'player_hp': 100,
      'player_atk': 25,
      'player_def': 5,
      'enemy_name': 'Slime',
      'enemy_hp': 50,
      'enemy_atk': 5,
      'enemy_def': 1,
    }));

    // Drive a few turns with player attacks
    final ended = Completer<Event>();
    bus.subscribe('battle_ended', (e, b) => ended.complete(e));

    for (var i = 0; i < 10; i++) {
      bus.publish(Event(type: 'battle.command', data: {'action': 'attack'}));
    }

    final result = await ended.future.timeout(const Duration(seconds: 2));
    expect(result.data?['winner'], 'player');
  });
}
