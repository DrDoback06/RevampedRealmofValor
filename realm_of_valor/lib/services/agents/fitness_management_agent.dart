import '../base_agent.dart';
import '../event_bus.dart';
import '../../utils/fitness_rewards.dart';
import 'dart:async';

class FitnessManagementAgent extends BaseAgent {
  FitnessManagementAgent(super.bus);

  // Track daily rewards to enforce caps
  int _goldEarnedToday = 0;
  int _xpEarnedToday = 0;
  DateTime _lastResetDate = DateTime.now();
  
  // User's fitness streak
  FitnessStreak _streak = FitnessStreak(
    currentStreak: 0,
    lastActivityDate: DateTime.now().subtract(const Duration(days: 2)),
    longestStreak: 0,
  );

  // Active fitness buffs
  final List<FitnessBuff> _activeBuffs = [];

  @override
  String get name => 'FitnessManagement';

  @override
  Future<void> onInitialize() async {
    bus.subscribe('fitness.sync', _onSync);
    bus.subscribe('fitness.submit_activity', _onSubmitActivity);
    bus.subscribe('fitness.check_buffs', _onCheckBuffs);
    
    // Start periodic buff cleanup
    Timer.periodic(const Duration(minutes: 1), (_) => _cleanupExpiredBuffs());
  }

  @override
  Future<void> onDispose() async {}

  void _onSync(Event evt, EventBus b) {
    _checkDailyReset();
    b.publish(Event(type: 'fitness_data_synced', data: {
      'timestamp': DateTime.now().toIso8601String(),
      'goldEarnedToday': _goldEarnedToday,
      'xpEarnedToday': _xpEarnedToday,
      'streak': _streak.currentStreak,
      'activeBuffs': _activeBuffs.length,
    }));
  }

  void _onSubmitActivity(Event evt, EventBus b) {
    _checkDailyReset();
    
    // Parse activity data
    final data = evt.data;
    if (data == null) return;

    final activity = FitnessActivity(
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0.0,
      elevationMeters: (data['elevationMeters'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
      averageHeartRate: (data['averageHeartRate'] as num?)?.toInt() ?? 70,
      maxHeartRate: (data['maxHeartRate'] as num?)?.toInt() ?? 180,
      activityType: data['activityType'] as String? ?? 'walking',
      timestamp: data['timestamp'] != null 
          ? DateTime.parse(data['timestamp'] as String)
          : DateTime.now(),
    );

    // Verify activity is legitimate
    if (!FitnessRewardCalculator.verifyActivity(activity)) {
      b.publish(Event(type: 'fitness_activity_rejected', data: {
        'reason': 'Activity failed verification checks',
      }));
      return;
    }

    // Calculate user's max heart rate (assuming age 30 if not provided)
    final userAge = (data['userAge'] as num?)?.toInt() ?? 30;
    final maxHeartRate = FitnessRewardCalculator.estimateMaxHeartRate(userAge);

    // Update streak
    _streak = FitnessRewardCalculator.updateStreak(_streak, activity.timestamp);

    // Calculate rewards
    final rewards = FitnessRewardCalculator.calculateRewards(
      activity: activity,
      streak: _streak,
      goldEarnedToday: _goldEarnedToday,
      xpEarnedToday: _xpEarnedToday,
      maxHeartRateForAge: maxHeartRate,
    );

    // Update daily totals
    _goldEarnedToday += rewards.goldEarned;
    _xpEarnedToday += rewards.xpEarned;

    // Add buff if earned
    if (rewards.buff != null) {
      _activeBuffs.add(rewards.buff!);
      _cleanupExpiredBuffs();
    }

    // Publish rewards events
    if (rewards.goldEarned > 0) {
      b.publish(Event(type: 'inventory.add_gold', data: {'gold': rewards.goldEarned}));
    }

    if (rewards.xpEarned > 0) {
      b.publish(Event(type: 'character.add_xp', data: {'xp': rewards.xpEarned}));
    }

    // Publish activity completed event with details
    b.publish(Event(type: 'fitness_activity_completed', data: {
      'activityType': activity.activityType,
      'distanceKm': activity.distanceKm,
      'goldEarned': rewards.goldEarned,
      'xpEarned': rewards.xpEarned,
      'buff': rewards.buff != null ? {
        'name': rewards.buff!.name,
        'attack': rewards.buff!.attackBonus,
        'defense': rewards.buff!.defenseBonus,
        'hp': rewards.buff!.hpBonus,
        'expiresAt': rewards.buff!.expiresAt.toIso8601String(),
      } : null,
      'streak': _streak.currentStreak,
      'streakBonus': rewards.streakBonusMultiplier,
      'reason': rewards.rewardReason,
    }));

    // Publish streak update
    if (_streak.currentStreak >= 3) {
      b.publish(Event(type: 'fitness_streak_milestone', data: {
        'streak': _streak.currentStreak,
        'description': _streak.streakDescription,
      }));
    }
  }

  void _onCheckBuffs(Event evt, EventBus b) {
    _cleanupExpiredBuffs();
    
    // Calculate total buff bonuses
    var totalAttack = 0;
    var totalDefense = 0;
    var totalHp = 0;
    
    for (final buff in _activeBuffs) {
      totalAttack += buff.attackBonus;
      totalDefense += buff.defenseBonus;
      totalHp += buff.hpBonus;
    }

    b.publish(Event(type: 'fitness_buffs_updated', data: {
      'activeBuffs': _activeBuffs.length,
      'totalAttack': totalAttack,
      'totalDefense': totalDefense,
      'totalHp': totalHp,
      'buffs': _activeBuffs.map((buff) => {
        'name': buff.name,
        'attack': buff.attackBonus,
        'defense': buff.defenseBonus,
        'hp': buff.hpBonus,
        'remainingMinutes': buff.remainingMinutes,
      }).toList(),
    }));
  }

  void _cleanupExpiredBuffs() {
    _activeBuffs.removeWhere((buff) => !buff.isActive);
  }

  void _checkDailyReset() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReset = DateTime(
      _lastResetDate.year,
      _lastResetDate.month,
      _lastResetDate.day,
    );

    if (today.isAfter(lastReset)) {
      _goldEarnedToday = 0;
      _xpEarnedToday = 0;
      _lastResetDate = now;
      
      bus.publish(Event(type: 'fitness_daily_reset', data: {
        'date': today.toIso8601String(),
      }));
    }
  }

  /// Get current fitness stats for UI
  Map<String, dynamic> getStats() {
    _cleanupExpiredBuffs();
    return {
      'goldEarnedToday': _goldEarnedToday,
      'xpEarnedToday': _xpEarnedToday,
      'goldRemaining': FitnessRewardCalculator.maxGoldPerDay - _goldEarnedToday,
      'xpRemaining': FitnessRewardCalculator.maxXpPerDay - _xpEarnedToday,
      'streak': _streak.currentStreak,
      'longestStreak': _streak.longestStreak,
      'streakDescription': _streak.streakDescription,
      'activeBuffs': _activeBuffs.length,
    };
  }
}
