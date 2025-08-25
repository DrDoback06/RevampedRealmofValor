import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_of_valor/integration/fitness_service.dart';
import 'package:realm_of_valor/services/agents/fitness_tracking_agent.dart';
import 'package:realm_of_valor/services/event_bus.dart';

class FakeFitness implements FitnessService {
  int steps = 0;
  double km = 0.0;
  @override
  Future<double> distanceTodayKm() async => km;
  @override
  Future<int> stepsToday() async => steps;
}

void main() {
  test('Fitness agent publishes updates and detects goal streak', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);
    final fake = FakeFitness();
    final agent = FitnessTrackingAgent(bus, service: fake, pollInterval: const Duration(milliseconds: 100));
    await agent.initialize();

    final updates = Completer<Event>();
    bus.subscribe('fitness_update', (e, b) => updates.complete(e));

    fake.steps = 1500;
    fake.km = 1.0;

    final first = await updates.future.timeout(const Duration(seconds: 2));
    expect(first.data?['steps'], 1500);

    // Set goal to small and ensure streak increments once per day boundary
    bus.publish(Event(type: 'fitness.set_goal', data: {'steps': 1000}));

    final goal = Completer<Event>();
    bus.subscribe('fitness_goal_reached', (e, b) => goal.complete(e));

    final reached = await goal.future.timeout(const Duration(seconds: 2));
    expect((reached.data?['streak_days'] as int) >= 1, true);
  });
}
