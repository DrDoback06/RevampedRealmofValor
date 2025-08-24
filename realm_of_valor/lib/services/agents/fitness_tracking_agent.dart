import 'dart:async';

import '../../integration/fitness_service.dart';
import '../base_agent.dart';
import '../event_bus.dart';

class FitnessTrackingAgent extends BaseAgent {
  FitnessTrackingAgent(super.bus, {required this.service, this.pollInterval = const Duration(minutes: 5)});

  final FitnessService service;
  final Duration pollInterval;

  Timer? _timer;
  int _lastSteps = 0;
  int _dailyGoal = 10000;
  int _streakDays = 0;
  DateTime? _lastGoalDate;

  @override
  String get name => 'FitnessTracking';

  @override
  Future<void> onInitialize() async {
    bus.subscribe('fitness.set_goal', (evt, _) {
      final goal = (evt.data?['steps'] as num?)?.toInt();
      if (goal != null && goal > 0) _dailyGoal = goal;
    });
    _timer = Timer.periodic(pollInterval, (_) => _poll());
    // Initial poll shortly after start
    Future<void>.delayed(const Duration(seconds: 1), _poll);
  }

  @override
  Future<void> onDispose() async {
    _timer?.cancel();
  }

  Future<void> _poll() async {
    try {
      final steps = await service.stepsToday();
      final distance = await service.distanceTodayKm();
      if (steps != _lastSteps) {
        _lastSteps = steps;
        bus.publish(Event(type: 'fitness_update', data: {'steps': steps, 'distance_km': distance}));
      }
      _checkGoal(steps);
    } catch (e) {
      bus.publish(Event(type: 'ui.notify', data: {'level': 'warning', 'message': 'Fitness sync failed: $e'}));
    }
  }

  void _checkGoal(int steps) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastDate = _lastGoalDate == null ? null : DateTime(_lastGoalDate!.year, _lastGoalDate!.month, _lastGoalDate!.day);

    if (steps >= _dailyGoal) {
      if (lastDate != todayDate) {
        // New day goal reached
        _streakDays = (lastDate == null || lastDate == todayDate.subtract(const Duration(days: 1))) ? _streakDays + 1 : 1;
        _lastGoalDate = today;
        bus.publish(Event(type: 'fitness_goal_reached', data: {'steps': steps, 'streak_days': _streakDays}));
      }
    }
  }
}