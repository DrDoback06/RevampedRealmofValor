import 'dart:math';

/// Fitness activity data
class FitnessActivity {
  final double distanceKm;
  final double elevationMeters;
  final int durationSeconds;
  final int averageHeartRate;
  final int maxHeartRate;
  final String activityType; // 'running', 'hiking', 'cycling', 'circuit_training', 'walking'
  final DateTime timestamp;

  const FitnessActivity({
    required this.distanceKm,
    required this.elevationMeters,
    required this.durationSeconds,
    required this.averageHeartRate,
    required this.maxHeartRate,
    required this.activityType,
    required this.timestamp,
  });
}

/// Temporary stat buff from fitness activities
class FitnessBuff {
  final String name;
  final int attackBonus;
  final int defenseBonus;
  final int hpBonus;
  final DateTime expiresAt;

  const FitnessBuff({
    required this.name,
    required this.attackBonus,
    required this.defenseBonus,
    required this.hpBonus,
    required this.expiresAt,
  });

  bool get isActive => DateTime.now().isBefore(expiresAt);

  int get remainingMinutes =>
      expiresAt.difference(DateTime.now()).inMinutes.clamp(0, 9999);
}

/// Rewards from fitness activities
class FitnessRewards {
  final int goldEarned;
  final int xpEarned;
  final FitnessBuff? buff;
  final double streakBonusMultiplier;
  final String rewardReason;

  const FitnessRewards({
    required this.goldEarned,
    required this.xpEarned,
    this.buff,
    required this.streakBonusMultiplier,
    required this.rewardReason,
  });
}

/// User's fitness streak data
class FitnessStreak {
  final int currentStreak;
  final DateTime lastActivityDate;
  final int longestStreak;

  const FitnessStreak({
    required this.currentStreak,
    required this.lastActivityDate,
    required this.longestStreak,
  });

  double get bonusMultiplier {
    if (currentStreak >= 30) return 1.5; // 30-day: +50%
    if (currentStreak >= 7) return 1.2; // 7-day: +20%
    if (currentStreak >= 3) return 1.1; // 3-day: +10%
    return 1.0; // No bonus
  }

  String get streakDescription {
    if (currentStreak >= 30) return '🔥 30-Day Streak! (+50% XP)';
    if (currentStreak >= 7) return '⚡ 7-Day Streak! (+20% XP)';
    if (currentStreak >= 3) return '✨ 3-Day Streak! (+10% XP)';
    return 'Start a streak!';
  }
}

/// Fitness reward calculation engine
class FitnessRewardCalculator {
  // Daily caps to prevent abuse
  static const int maxGoldPerDay = 30; // 20 from distance + 10 from elevation
  static const int maxXpPerDay = 500;
  static const Duration buffDuration = Duration(minutes: 10);

  /// Calculate rewards from a fitness activity
  static FitnessRewards calculateRewards({
    required FitnessActivity activity,
    required FitnessStreak streak,
    required int goldEarnedToday,
    required int xpEarnedToday,
    int? maxHeartRateForAge, // User's calculated max HR
  }) {
    // Calculate base rewards
    int goldFromDistance = _calculateDistanceGold(activity.distanceKm);
    int goldFromElevation = _calculateElevationGold(activity.elevationMeters);
    int baseXp = _calculateBaseXP(activity);

    // Apply daily caps
    final goldAvailable = maxGoldPerDay - goldEarnedToday;
    final xpAvailable = maxXpPerDay - xpEarnedToday;

    var totalGold = (goldFromDistance + goldFromElevation).clamp(0, goldAvailable);
    var totalXp = baseXp.clamp(0, xpAvailable);

    // Apply streak bonus to XP
    totalXp = (totalXp * streak.bonusMultiplier).round();

    // Apply activity type bonuses
    final activityMultipliers = _getActivityTypeMultipliers(activity.activityType);
    totalXp = (totalXp * activityMultipliers['xp']!).round();
    totalGold = (totalGold * activityMultipliers['gold']!).round();

    // Check for heart rate-based temporary buff
    FitnessBuff? buff;
    if (maxHeartRateForAge != null) {
      buff = _calculateHeartRateBuff(
        activity: activity,
        maxHeartRate: maxHeartRateForAge,
      );
    }

    final reasonParts = <String>[];
    if (goldFromDistance > 0) {
      reasonParts.add('${activity.distanceKm.toStringAsFixed(1)}km');
    }
    if (goldFromElevation > 0) {
      reasonParts.add('${activity.elevationMeters.toStringAsFixed(0)}m elevation');
    }
    if (streak.currentStreak >= 3) {
      reasonParts.add('${streak.currentStreak}-day streak');
    }
    if (buff != null) {
      reasonParts.add('High intensity');
    }

    return FitnessRewards(
      goldEarned: totalGold,
      xpEarned: totalXp,
      buff: buff,
      streakBonusMultiplier: streak.bonusMultiplier,
      rewardReason: reasonParts.isEmpty ? 'Fitness activity' : reasonParts.join(', '),
    );
  }

  /// Calculate gold from distance (1 gold per 0.5km, max 20/day)
  static int _calculateDistanceGold(double distanceKm) {
    return (distanceKm / 0.5).floor().clamp(0, 20);
  }

  /// Calculate gold from elevation (1 gold per 100m, max 10/day)
  static int _calculateElevationGold(double elevationMeters) {
    return (elevationMeters / 100).floor().clamp(0, 10);
  }

  /// Calculate base XP from activity
  static int _calculateBaseXP(FitnessActivity activity) {
    // XP based on duration and intensity
    final durationMinutes = activity.durationSeconds / 60.0;
    
    // Base: 10 XP per 5 minutes of activity
    var xp = (durationMinutes / 5.0 * 10).round();

    // Bonus for distance
    xp += (activity.distanceKm * 5).round();

    // Bonus for elevation
    xp += (activity.elevationMeters / 10).round();

    return xp.clamp(0, 200); // Cap base XP per activity
  }

  /// Get activity type multipliers for rewards
  static Map<String, double> _getActivityTypeMultipliers(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'running':
        return {'xp': 1.2, 'gold': 1.0}; // +20% XP
      case 'hiking':
        return {'xp': 1.0, 'gold': 1.3}; // +30% gold
      case 'cycling':
        return {'xp': 1.1, 'gold': 1.1}; // +10% both
      case 'circuit_training':
      case 'strength':
        return {'xp': 1.0, 'gold': 1.0}; // But grants stat buffs more easily
      case 'walking':
        return {'xp': 0.8, 'gold': 1.0}; // -20% XP (lower intensity)
      default:
        return {'xp': 1.0, 'gold': 1.0};
    }
  }

  /// Calculate heart rate-based temporary buff
  /// If user maintains 70%+ of max HR for 120+ seconds, grant temporary stats
  static FitnessBuff? _calculateHeartRateBuff({
    required FitnessActivity activity,
    required int maxHeartRate,
  }) {
    final hrThreshold = (maxHeartRate * 0.7).round();
    
    // Check if average HR was above 70% max
    if (activity.averageHeartRate < hrThreshold) {
      return null;
    }

    // Check if duration was at least 120 seconds
    if (activity.durationSeconds < 120) {
      return null;
    }

    // Calculate buff strength based on intensity and duration
    final intensityFactor = (activity.averageHeartRate / maxHeartRate).clamp(0.7, 1.0);
    final durationFactor = min(activity.durationSeconds / 600.0, 1.5); // Cap at 10min for 1.5x

    var attackBonus = (2 * intensityFactor * durationFactor).round().clamp(1, 5);
    var defenseBonus = (1 * intensityFactor * durationFactor).round().clamp(0, 3);
    var hpBonus = (5 * intensityFactor * durationFactor).round().clamp(2, 15);

    // Activity-specific bonuses
    switch (activity.activityType.toLowerCase()) {
      case 'circuit_training':
      case 'strength':
        attackBonus += 2;
        hpBonus += 5;
        break;
      case 'running':
      case 'cycling':
        defenseBonus += 1;
        break;
    }

    return FitnessBuff(
      name: 'Adrenaline Rush',
      attackBonus: attackBonus,
      defenseBonus: defenseBonus,
      hpBonus: hpBonus,
      expiresAt: DateTime.now().add(buffDuration),
    );
  }

  /// Update user's fitness streak
  static FitnessStreak updateStreak(FitnessStreak current, DateTime newActivityDate) {
    final today = DateTime(newActivityDate.year, newActivityDate.month, newActivityDate.day);
    final lastDate = DateTime(
      current.lastActivityDate.year,
      current.lastActivityDate.month,
      current.lastActivityDate.day,
    );

    final daysDiff = today.difference(lastDate).inDays;

    if (daysDiff == 0) {
      // Same day, no change to streak
      return current;
    } else if (daysDiff == 1) {
      // Consecutive day, increment streak
      final newStreak = current.currentStreak + 1;
      return FitnessStreak(
        currentStreak: newStreak,
        lastActivityDate: newActivityDate,
        longestStreak: max(current.longestStreak, newStreak),
      );
    } else {
      // Streak broken, start over
      return FitnessStreak(
        currentStreak: 1,
        lastActivityDate: newActivityDate,
        longestStreak: current.longestStreak,
      );
    }
  }

  /// Calculate user's estimated max heart rate based on age
  static int estimateMaxHeartRate(int age) {
    // Standard formula: 220 - age
    return 220 - age;
  }

  /// Verify activity is legitimate (anti-cheat checks)
  static bool verifyActivity(FitnessActivity activity) {
    // Check for impossibly fast speeds
    if (activity.distanceKm > 0 && activity.durationSeconds > 0) {
      final speedKmh = (activity.distanceKm / (activity.durationSeconds / 3600.0));
      
      switch (activity.activityType.toLowerCase()) {
        case 'walking':
          if (speedKmh > 8) return false; // Max walking speed ~8 km/h
          break;
        case 'running':
          if (speedKmh > 25) return false; // Max running speed ~25 km/h
          break;
        case 'cycling':
          if (speedKmh > 60) return false; // Max cycling speed ~60 km/h
          break;
      }
    }

    // Check for impossible heart rates
    if (activity.averageHeartRate > 220 || activity.maxHeartRate > 220) {
      return false;
    }

    // Check for impossible elevation
    if (activity.elevationMeters > 5000) {
      return false; // Max reasonable elevation gain per activity
    }

    return true;
  }
}
