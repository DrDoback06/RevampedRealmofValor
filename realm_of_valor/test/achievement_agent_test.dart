import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_of_valor/data/models/achievement_model.dart';
import 'package:realm_of_valor/services/agents/achievement_agent.dart';
import 'package:realm_of_valor/services/event_bus.dart';

void main() {
  test('Unlocks on first battle win and emits reward XP via battle_result', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);
    final agent = AchievementAgent(bus, definitions: [
      AchievementDefinition(id: 'first_win', title: 'First Victory', eventType: 'battle_ended', threshold: 1, rewardXp: 20),
    ]);
    await agent.initialize();

    final unlocked = Completer<Event>();
    final reward = Completer<Event>();
    bus.subscribe('achievement_unlocked', (e, b) => unlocked.complete(e));
    bus.subscribe('battle_result', (e, b) => reward.complete(e));

    bus.publish(Event(type: 'battle_ended', data: {'winner': 'player'}));

    final u = await unlocked.future.timeout(const Duration(seconds: 2));
    expect(u.data?['id'], 'first_win');
    final r = await reward.future.timeout(const Duration(seconds: 2));
    expect((r.data?['xp'] as int) >= 20, true);
  });

  test('Unlocks on fitness goal reached', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);
    final agent = AchievementAgent(bus, definitions: [
      AchievementDefinition(id: 'step_starter', title: 'Step Starter', eventType: 'fitness_goal_reached', threshold: 1, rewardXp: 10),
    ]);
    await agent.initialize();

    final unlocked = Completer<Event>();
    bus.subscribe('achievement_unlocked', (e, b) => unlocked.complete(e));

    bus.publish(Event(type: 'fitness_goal_reached'));
    final u = await unlocked.future.timeout(const Duration(seconds: 2));
    expect(u.data?['id'], 'step_starter');
  });
}