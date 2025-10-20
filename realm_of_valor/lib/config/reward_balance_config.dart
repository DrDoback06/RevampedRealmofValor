/// REWARD BALANCE CONFIGURATION
/// Incentivizes outdoor real-world gameplay over pure online grinding
/// Following user's requirement: "make it a real grind to do it online only"
/// "We just don't want people to exclusively be online"
/// 
/// DESIGN PHILOSOPHY:
/// - Outdoor activities = FULL rewards + bonuses
/// - Online-only raids = Reduced rewards + diminishing returns
/// - Best strategy = Mix of outdoor exploration + occasional online raids

class RewardBalanceConfig {
  /// === OUTDOOR ACTIVITY MULTIPLIERS ===
  /// These apply to quests/battles at real-world locations
  
  static const double outdoorBaseMultiplier = 1.0; // Full rewards
  static const double outdoorDistanceBonusPerKm = 0.05; // +5% per km traveled
  static const double outdoorMaxDistanceBonus = 0.5; // Max +50% at 10km+
  static const double outdoorWeatherBonus = 0.1; // +10% in bad weather (brave!)
  static const double outdoorTimeOfDayBonus = 0.15; // +15% during sunrise/sunset
  static const double outdoorStreakBonus = 0.2; // +20% for 7-day outdoor streak
  
  /// === ONLINE-ONLY MULTIPLIERS ===
  /// These apply to Hearthstone-style matchmaking raids
  
  /// Base online multiplier (intentionally lower)
  static const double onlineBaseMultiplier = 0.5; // 50% of outdoor rewards
  
  /// Diminishing returns for repeated online raids (same day)
  static const Map<int, double> onlineDiminishingReturns = {
    0: 1.0,    // First raid: 100% of online base (50% overall)
    1: 0.8,    // Second: 80% (40% overall)
    2: 0.6,    // Third: 60% (30% overall)
    3: 0.4,    // Fourth: 40% (20% overall)
    4: 0.2,    // Fifth: 20% (10% overall)
    5: 0.1,    // Sixth+: 10% (5% overall) - Extreme grind!
  };
  
  /// Daily online raid limit before severe penalties
  static const int onlineSoftCap = 3; // After 3, rewards drop significantly
  static const int onlineHardCap = 10; // After 10, rewards are negligible
  
  /// === HYBRID BONUS ===
  /// Reward players who mix outdoor + online
  
  /// Bonus if player did outdoor activity today before online raid
  static const double outdoorFirstBonus = 0.3; // +30% to online raids
  
  /// Bonus per outdoor activity done today (stacks)
  static const double perOutdoorActivityBonus = 0.05; // +5% each, max +25%
  static const int maxOutdoorActivitiesForBonus = 5;
  
  /// === EXAMPLE CALCULATIONS ===
  
  /// Example 1: Outdoor Boss Raid at Snowdon
  /// - Base: 1000 XP
  /// - Outdoor multiplier: 1.0 (full rewards)
  /// - Distance bonus: +30% (6km from home)
  /// - Weather bonus: +10% (raining)
  /// - Total: 1000 * 1.0 * 1.3 * 1.1 = 1430 XP ✅
  
  /// Example 2: First Online Raid (no outdoor today)
  /// - Base: 1000 XP
  /// - Online multiplier: 0.5 (50% penalty)
  /// - Diminishing returns: 1.0 (first raid)
  /// - Total: 1000 * 0.5 * 1.0 = 500 XP ⚠️
  
  /// Example 3: Third Online Raid (no outdoor today)
  /// - Base: 1000 XP
  /// - Online multiplier: 0.5
  /// - Diminishing returns: 0.6 (third raid)
  /// - Total: 1000 * 0.5 * 0.6 = 300 XP ⚠️⚠️
  
  /// Example 4: Online Raid AFTER outdoor activity
  /// - Base: 1000 XP
  /// - Online multiplier: 0.5
  /// - Diminishing returns: 1.0 (first online)
  /// - Outdoor first bonus: +30%
  /// - Total: 1000 * 0.5 * 1.0 * 1.3 = 650 XP ✅
  
  /// Example 5: Sixth Online Raid (pure grinding)
  /// - Base: 1000 XP
  /// - Online multiplier: 0.5
  /// - Diminishing returns: 0.1 (sixth raid)
  /// - Total: 1000 * 0.5 * 0.1 = 50 XP 💀💀💀
  
  /// === COMPARISON CHART ===
  /// 
  /// Activity Type              | XP Reward | Time
  /// ---------------------------|-----------|-------
  /// Outdoor Boss (Snowdon)     | 1430 XP   | 3 hrs (includes travel/hike)
  /// Online Raid #1             | 500 XP    | 15 min
  /// Online Raid #2             | 400 XP    | 15 min
  /// Online Raid #3             | 300 XP    | 15 min
  /// Online Raid #4             | 200 XP    | 15 min
  /// Online Raid #5             | 100 XP    | 15 min
  /// Online Raid #6             | 50 XP     | 15 min
  /// 
  /// Total Online (6 raids)     | 1550 XP   | 1.5 hrs
  /// Total Outdoor (1 raid)     | 1430 XP   | 3 hrs
  /// 
  /// Result: Online grinding gets slightly more XP/hour BUT:
  /// - Misses out on distance bonuses
  /// - Misses out on weather bonuses  
  /// - Misses out on outdoor streaks
  /// - Misses out on exploration achievements
  /// - Misses out on location-based quests
  /// - Misses out on real fitness benefits!
  /// 
  /// BEST STRATEGY: Do outdoor activities + occasional online raids!
  
  /// === ARENA ACCESS ===
  /// Special arenas (like Hearthstone matchmaking) are available but:
  
  /// Arena types
  static const String arenaOnline = 'online_matchmaking'; // Hearthstone-style
  static const String arenaOutdoor = 'outdoor_location'; // Physical arena POI
  
  /// Minimum level for online arena access
  static const int onlineArenaMinLevel = 10; // Must be level 10+
  
  /// Daily online arena attempts (free)
  static const int dailyFreeOnlineRaids = 3; // First 3 are "free"
  
  /// Cost for additional online raids (after daily free)
  static const int additionalRaidGoldCost = 100; // 100 gold per extra raid
  
  /// === NOTIFICATION MESSAGES ===
  
  static String getRewardMessage({
    required bool isOutdoor,
    required int onlineRaidCount,
    required double finalMultiplier,
  }) {
    if (isOutdoor) {
      return '🌍 Outdoor Raid Complete! Full rewards + bonuses! (${(finalMultiplier * 100).toStringAsFixed(0)}%)';
    } else {
      if (onlineRaidCount == 0) {
        return '💻 Online Raid Complete! (${(finalMultiplier * 100).toStringAsFixed(0)}% - Go outside for more rewards!)';
      } else if (onlineRaidCount < 3) {
        return '💻 Online Raid Complete! (${(finalMultiplier * 100).toStringAsFixed(0)}% - Diminishing returns...)';
      } else if (onlineRaidCount < 6) {
        return '⚠️ Online Raid Complete! (${(finalMultiplier * 100).toStringAsFixed(0)}% - Severely reduced rewards!)';
      } else {
        return '💀 Online Raid Complete! (${(finalMultiplier * 100).toStringAsFixed(0)}% - EXTREME GRIND! Go outside!)';
      }
    }
  }
  
  static String getArenaAccessMessage(int level) {
    if (level < onlineArenaMinLevel) {
      return 'Reach level $onlineArenaMinLevel to unlock online arenas!';
    }
    return 'Online arena available! ($dailyFreeOnlineRaids free raids/day)';
  }
}

/// Helper class for calculating actual rewards
class RewardCalculator {
  /// Calculate final reward for outdoor activity
  static double calculateOutdoorMultiplier({
    required double distanceKm,
    bool badWeather = false,
    bool magicHour = false, // Sunrise/sunset
    int outdoorStreakDays = 0,
  }) {
    double multiplier = RewardBalanceConfig.outdoorBaseMultiplier;
    
    // Distance bonus (capped)
    final distanceBonus = (distanceKm * RewardBalanceConfig.outdoorDistanceBonusPerKm)
        .clamp(0.0, RewardBalanceConfig.outdoorMaxDistanceBonus);
    multiplier += distanceBonus;
    
    // Weather bonus
    if (badWeather) {
      multiplier += RewardBalanceConfig.outdoorWeatherBonus;
    }
    
    // Time of day bonus
    if (magicHour) {
      multiplier += RewardBalanceConfig.outdoorTimeOfDayBonus;
    }
    
    // Streak bonus
    if (outdoorStreakDays >= 7) {
      multiplier += RewardBalanceConfig.outdoorStreakBonus;
    }
    
    return multiplier;
  }
  
  /// Calculate final reward for online raid
  static double calculateOnlineMultiplier({
    required int onlineRaidCountToday,
    int outdoorActivitiesToday = 0,
  }) {
    double multiplier = RewardBalanceConfig.onlineBaseMultiplier;
    
    // Diminishing returns
    final diminishing = RewardBalanceConfig.onlineDiminishingReturns[
      onlineRaidCountToday.clamp(0, 5)
    ] ?? 0.1;
    multiplier *= diminishing;
    
    // Outdoor first bonus
    if (outdoorActivitiesToday > 0) {
      multiplier *= (1.0 + RewardBalanceConfig.outdoorFirstBonus);
      
      // Per-activity bonus
      final activityBonus = (outdoorActivitiesToday * 
          RewardBalanceConfig.perOutdoorActivityBonus)
          .clamp(0.0, RewardBalanceConfig.perOutdoorActivityBonus * 
              RewardBalanceConfig.maxOutdoorActivitiesForBonus);
      multiplier *= (1.0 + activityBonus);
    }
    
    return multiplier;
  }
}
