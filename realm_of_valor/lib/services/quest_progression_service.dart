import 'dart:math';
import '../../../data/models/quest_model.dart';
import '../../../data/models/character_model.dart';

class QuestProgressionService {
  static final QuestProgressionService _instance = QuestProgressionService._internal();
  factory QuestProgressionService() => _instance;
  QuestProgressionService._internal();

  final Map<String, PlayerProgression> _playerProgression = {};
  final List<QuestMilestone> _milestones = [];
  final List<QuestAchievement> _achievements = [];

  /// Initialize progression system
  void initialize() {
    _createMilestones();
    _createAchievements();
  }

  /// Get player progression
  PlayerProgression getPlayerProgression(String playerId) {
    return _playerProgression.putIfAbsent(
      playerId, 
      () => PlayerProgression(playerId: playerId),
    );
  }

  /// Update player progression when quest is completed
  void updateProgression({
    required String playerId,
    required Quest quest,
    required QuestRewards rewards,
    required Duration completionTime,
  }) {
    final progression = getPlayerProgression(playerId);
    
    // Update basic stats
    progression.totalQuestsCompleted++;
    progression.totalXPEarned += rewards.xp;
    progression.totalGoldEarned += rewards.gold;
    progression.totalGemsEarned += rewards.gems;
    
    // Update quest type stats
    _updateQuestTypeStats(progression, quest);
    
    // Update time-based stats
    _updateTimeBasedStats(progression, completionTime);
    
    // Update location-based stats
    if (quest.location != null) {
      _updateLocationStats(progression, quest.location!);
    }
    
    // Check for milestone unlocks
    _checkMilestoneUnlocks(progression);
    
    // Check for achievement unlocks
    _checkAchievementUnlocks(progression);
    
    // Update progression level
    _updateProgressionLevel(progression);
  }

  /// Get available milestones for a player
  List<QuestMilestone> getAvailableMilestones(String playerId) {
    final progression = getPlayerProgression(playerId);
    return _milestones.where((milestone) => 
        !progression.unlockedMilestones.contains(milestone.id)).toList();
  }

  /// Get unlocked milestones for a player
  List<QuestMilestone> getUnlockedMilestones(String playerId) {
    final progression = getPlayerProgression(playerId);
    return _milestones.where((milestone) => 
        progression.unlockedMilestones.contains(milestone.id)).toList();
  }

  /// Get available achievements for a player
  List<QuestAchievement> getAvailableAchievements(String playerId) {
    final progression = getPlayerProgression(playerId);
    return _achievements.where((achievement) => 
        !progression.unlockedAchievements.contains(achievement.id)).toList();
  }

  /// Get unlocked achievements for a player
  List<QuestAchievement> getUnlockedAchievements(String playerId) {
    final progression = getPlayerProgression(playerId);
    return _achievements.where((achievement) => 
        progression.unlockedAchievements.contains(achievement.id)).toList();
  }

  /// Get progression summary for a player
  ProgressionSummary getProgressionSummary(String playerId) {
    final progression = getPlayerProgression(playerId);
    
    return ProgressionSummary(
      playerId: playerId,
      totalQuestsCompleted: progression.totalQuestsCompleted,
      totalXPEarned: progression.totalXPEarned,
      totalGoldEarned: progression.totalGoldEarned,
      progressionLevel: progression.progressionLevel,
      unlockedMilestones: progression.unlockedMilestones.length,
      totalMilestones: _milestones.length,
      unlockedAchievements: progression.unlockedAchievements.length,
      totalAchievements: _achievements.length,
      questTypeMastery: _calculateQuestTypeMastery(progression),
      completionRate: _calculateCompletionRate(progression),
      averageCompletionTime: _calculateAverageCompletionTime(progression),
    );
  }

  void _createMilestones() {
    _milestones.addAll([
      // Quest completion milestones
      QuestMilestone(
        id: 'first_quest',
        title: 'First Steps',
        description: 'Complete your first quest',
        type: MilestoneType.questCompletion,
        requirement: MilestoneRequirement(
          type: 'quests_completed',
          target: 1,
        ),
        rewards: MilestoneRewards(
          xp: 50,
          gold: 25,
          gems: 5,
          items: ['beginner_badge'],
        ),
      ),
      
      QuestMilestone(
        id: 'quest_master_10',
        title: 'Quest Apprentice',
        description: 'Complete 10 quests',
        type: MilestoneType.questCompletion,
        requirement: MilestoneRequirement(
          type: 'quests_completed',
          target: 10,
        ),
        rewards: MilestoneRewards(
          xp: 200,
          gold: 100,
          gems: 10,
          items: ['apprentice_badge'],
        ),
      ),
      
      QuestMilestone(
        id: 'quest_master_50',
        title: 'Quest Adept',
        description: 'Complete 50 quests',
        type: MilestoneType.questCompletion,
        requirement: MilestoneRequirement(
          type: 'quests_completed',
          target: 50,
        ),
        rewards: MilestoneRewards(
          xp: 500,
          gold: 250,
          gems: 25,
          items: ['adept_badge'],
        ),
      ),
      
      QuestMilestone(
        id: 'quest_master_100',
        title: 'Quest Master',
        description: 'Complete 100 quests',
        type: MilestoneType.questCompletion,
        requirement: MilestoneRequirement(
          type: 'quests_completed',
          target: 100,
        ),
        rewards: MilestoneRewards(
          xp: 1000,
          gold: 500,
          gems: 50,
          items: ['master_badge'],
        ),
      ),
      
      // Quest type milestones
      QuestMilestone(
        id: 'battle_master',
        title: 'Battle Master',
        description: 'Complete 25 battle quests',
        type: MilestoneType.questType,
        requirement: MilestoneRequirement(
          type: 'battle_quests_completed',
          target: 25,
        ),
        rewards: MilestoneRewards(
          xp: 300,
          gold: 150,
          gems: 15,
          items: ['battle_master_badge'],
        ),
      ),
      
      QuestMilestone(
        id: 'treasure_hunter',
        title: 'Treasure Hunter',
        description: 'Complete 20 treasure quests',
        type: MilestoneType.questType,
        requirement: MilestoneRequirement(
          type: 'treasure_quests_completed',
          target: 20,
        ),
        rewards: MilestoneRewards(
          xp: 250,
          gold: 200,
          gems: 20,
          items: ['treasure_hunter_badge'],
        ),
      ),
      
      // Time-based milestones
      QuestMilestone(
        id: 'speed_runner',
        title: 'Speed Runner',
        description: 'Complete 10 quests in under 5 minutes each',
        type: MilestoneType.timeBased,
        requirement: MilestoneRequirement(
          type: 'fast_quests_completed',
          target: 10,
        ),
        rewards: MilestoneRewards(
          xp: 400,
          gold: 200,
          gems: 20,
          items: ['speed_runner_badge'],
        ),
      ),
      
      // Location-based milestones
      QuestMilestone(
        id: 'explorer',
        title: 'Explorer',
        description: 'Complete quests in 10 different locations',
        type: MilestoneType.locationBased,
        requirement: MilestoneRequirement(
          type: 'unique_locations_visited',
          target: 10,
        ),
        rewards: MilestoneRewards(
          xp: 300,
          gold: 150,
          gems: 15,
          items: ['explorer_badge'],
        ),
      ),
    ]);
  }

  void _createAchievements() {
    _achievements.addAll([
      // Special achievements
      QuestAchievement(
        id: 'perfect_completion',
        title: 'Perfect Completion',
        description: 'Complete a quest with 100% objective completion',
        type: AchievementType.special,
        requirement: AchievementRequirement(
          type: 'perfect_quest_completion',
          target: 1,
        ),
        points: 100,
        rewards: AchievementRewards(
          xp: 100,
          gold: 50,
          gems: 10,
          items: ['perfect_completion_trophy'],
        ),
      ),
      
      QuestAchievement(
        id: 'streak_master',
        title: 'Streak Master',
        description: 'Complete 5 quests in a row without failing',
        type: AchievementType.special,
        requirement: AchievementRequirement(
          type: 'quest_streak',
          target: 5,
        ),
        points: 150,
        rewards: AchievementRewards(
          xp: 200,
          gold: 100,
          gems: 20,
          items: ['streak_master_trophy'],
        ),
      ),
      
      QuestAchievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Complete 10 quests before 9 AM',
        type: AchievementType.timeBased,
        requirement: AchievementRequirement(
          type: 'early_morning_quests',
          target: 10,
        ),
        points: 75,
        rewards: AchievementRewards(
          xp: 150,
          gold: 75,
          gems: 15,
          items: ['early_bird_badge'],
        ),
      ),
      
      QuestAchievement(
        id: 'night_owl',
        title: 'Night Owl',
        description: 'Complete 10 quests after 10 PM',
        type: AchievementType.timeBased,
        requirement: AchievementRequirement(
          type: 'late_night_quests',
          target: 10,
        ),
        points: 75,
        rewards: AchievementRewards(
          xp: 150,
          gold: 75,
          gems: 15,
          items: ['night_owl_badge'],
        ),
      ),
      
      QuestAchievement(
        id: 'social_butterfly',
        title: 'Social Butterfly',
        description: 'Complete 5 social quests',
        type: AchievementType.social,
        requirement: AchievementRequirement(
          type: 'social_quests_completed',
          target: 5,
        ),
        points: 100,
        rewards: AchievementRewards(
          xp: 200,
          gold: 100,
          gems: 20,
          items: ['social_butterfly_badge'],
        ),
      ),
    ]);
  }

  void _updateQuestTypeStats(PlayerProgression progression, Quest quest) {
    switch (quest.type) {
      case QuestType.battle:
        progression.battleQuestsCompleted++;
        break;
      case QuestType.treasure:
        progression.treasureQuestsCompleted++;
        break;
      case QuestType.location:
        progression.locationQuestsCompleted++;
        break;
      case QuestType.fitness:
        progression.fitnessQuestsCompleted++;
        break;
      case QuestType.social:
        progression.socialQuestsCompleted++;
        break;
      case QuestType.story:
        progression.storyQuestsCompleted++;
        break;
      case QuestType.daily:
        progression.dailyQuestsCompleted++;
        break;
      case QuestType.weekly:
        progression.weeklyQuestsCompleted++;
        break;
    }
  }

  void _updateTimeBasedStats(PlayerProgression progression, Duration completionTime) {
    progression.totalCompletionTime += completionTime;
    progression.averageCompletionTime = Duration(
      milliseconds: progression.totalCompletionTime.inMilliseconds ~/ 
                   progression.totalQuestsCompleted,
    );
    
    // Track fast completions
    if (completionTime.inMinutes < 5) {
      progression.fastQuestsCompleted++;
    }
    
    // Track time of day
    final hour = DateTime.now().hour;
    if (hour < 9) {
      progression.earlyMorningQuests++;
    } else if (hour >= 22) {
      progression.lateNightQuests++;
    }
  }

  void _updateLocationStats(PlayerProgression progression, QuestLocation location) {
    final locationKey = '${location.latitude}_${location.longitude}';
    if (!progression.visitedLocations.contains(locationKey)) {
      progression.visitedLocations.add(locationKey);
    }
  }

  void _checkMilestoneUnlocks(PlayerProgression progression) {
    for (final milestone in _milestones) {
      if (progression.unlockedMilestones.contains(milestone.id)) continue;
      
      if (_isMilestoneUnlocked(progression, milestone)) {
        progression.unlockedMilestones.add(milestone.id);
        progression.totalMilestoneRewards.xp += milestone.rewards.xp;
        progression.totalMilestoneRewards.gold += milestone.rewards.gold;
        progression.totalMilestoneRewards.gems += milestone.rewards.gems;
        progression.totalMilestoneRewards.items.addAll(milestone.rewards.items);
      }
    }
  }

  void _checkAchievementUnlocks(PlayerProgression progression) {
    for (final achievement in _achievements) {
      if (progression.unlockedAchievements.contains(achievement.id)) continue;
      
      if (_isAchievementUnlocked(progression, achievement)) {
        progression.unlockedAchievements.add(achievement.id);
        progression.totalAchievementPoints += achievement.points;
        progression.totalAchievementRewards.xp += achievement.rewards.xp;
        progression.totalAchievementRewards.gold += achievement.rewards.gold;
        progression.totalAchievementRewards.gems += achievement.rewards.gems;
        progression.totalAchievementRewards.items.addAll(achievement.rewards.items);
      }
    }
  }

  bool _isMilestoneUnlocked(PlayerProgression progression, QuestMilestone milestone) {
    final requirement = milestone.requirement;
    
    switch (requirement.type) {
      case 'quests_completed':
        return progression.totalQuestsCompleted >= requirement.target;
      case 'battle_quests_completed':
        return progression.battleQuestsCompleted >= requirement.target;
      case 'treasure_quests_completed':
        return progression.treasureQuestsCompleted >= requirement.target;
      case 'fast_quests_completed':
        return progression.fastQuestsCompleted >= requirement.target;
      case 'unique_locations_visited':
        return progression.visitedLocations.length >= requirement.target;
      default:
        return false;
    }
  }

  bool _isAchievementUnlocked(PlayerProgression progression, QuestAchievement achievement) {
    final requirement = achievement.requirement;
    
    switch (requirement.type) {
      case 'perfect_quest_completion':
        return progression.perfectCompletions >= requirement.target;
      case 'quest_streak':
        return progression.currentStreak >= requirement.target;
      case 'early_morning_quests':
        return progression.earlyMorningQuests >= requirement.target;
      case 'late_night_quests':
        return progression.lateNightQuests >= requirement.target;
      case 'social_quests_completed':
        return progression.socialQuestsCompleted >= requirement.target;
      default:
        return false;
    }
  }

  void _updateProgressionLevel(PlayerProgression progression) {
    final totalXP = progression.totalXPEarned + 
                   progression.totalMilestoneRewards.xp + 
                   progression.totalAchievementRewards.xp;
    
    // Calculate level based on total XP (1000 XP per level)
    progression.progressionLevel = (totalXP / 1000).floor() + 1;
  }

  Map<QuestType, double> _calculateQuestTypeMastery(PlayerProgression progression) {
    final mastery = <QuestType, double>{};
    final totalQuests = progression.totalQuestsCompleted;
    
    if (totalQuests > 0) {
      mastery[QuestType.battle] = progression.battleQuestsCompleted / totalQuests;
      mastery[QuestType.treasure] = progression.treasureQuestsCompleted / totalQuests;
      mastery[QuestType.location] = progression.locationQuestsCompleted / totalQuests;
      mastery[QuestType.fitness] = progression.fitnessQuestsCompleted / totalQuests;
      mastery[QuestType.social] = progression.socialQuestsCompleted / totalQuests;
      mastery[QuestType.story] = progression.storyQuestsCompleted / totalQuests;
      mastery[QuestType.daily] = progression.dailyQuestsCompleted / totalQuests;
      mastery[QuestType.weekly] = progression.weeklyQuestsCompleted / totalQuests;
    }
    
    return mastery;
  }

  double _calculateCompletionRate(PlayerProgression progression) {
    final totalAttempted = progression.totalQuestsCompleted + progression.failedQuests;
    if (totalAttempted == 0) return 0.0;
    
    return progression.totalQuestsCompleted / totalAttempted;
  }

  Duration _calculateAverageCompletionTime(PlayerProgression progression) {
    if (progression.totalQuestsCompleted == 0) return Duration.zero;
    
    return Duration(
      milliseconds: progression.totalCompletionTime.inMilliseconds ~/ 
                   progression.totalQuestsCompleted,
    );
  }
}

class PlayerProgression {
  final String playerId;
  int totalQuestsCompleted = 0;
  int failedQuests = 0;
  int totalXPEarned = 0;
  int totalGoldEarned = 0;
  int totalGemsEarned = 0;
  int progressionLevel = 1;
  
  // Quest type stats
  int battleQuestsCompleted = 0;
  int treasureQuestsCompleted = 0;
  int locationQuestsCompleted = 0;
  int fitnessQuestsCompleted = 0;
  int socialQuestsCompleted = 0;
  int storyQuestsCompleted = 0;
  int dailyQuestsCompleted = 0;
  int weeklyQuestsCompleted = 0;
  
  // Time-based stats
  Duration totalCompletionTime = Duration.zero;
  Duration averageCompletionTime = Duration.zero;
  int fastQuestsCompleted = 0;
  int earlyMorningQuests = 0;
  int lateNightQuests = 0;
  
  // Location stats
  final Set<String> visitedLocations = {};
  
  // Streak tracking
  int currentStreak = 0;
  int longestStreak = 0;
  
  // Special stats
  int perfectCompletions = 0;
  
  // Milestones and achievements
  final Set<String> unlockedMilestones = {};
  final Set<String> unlockedAchievements = {};
  final MilestoneRewards totalMilestoneRewards = MilestoneRewards();
  final AchievementRewards totalAchievementRewards = AchievementRewards();
  int totalAchievementPoints = 0;

  PlayerProgression({required this.playerId});
}

class QuestMilestone {
  final String id;
  final String title;
  final String description;
  final MilestoneType type;
  final MilestoneRequirement requirement;
  final MilestoneRewards rewards;

  QuestMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.requirement,
    required this.rewards,
  });
}

enum MilestoneType {
  questCompletion,
  questType,
  timeBased,
  locationBased,
  social,
}

class MilestoneRequirement {
  final String type;
  final int target;

  MilestoneRequirement({
    required this.type,
    required this.target,
  });
}

class MilestoneRewards {
  final int xp;
  final int gold;
  final int gems;
  final List<String> items;

  MilestoneRewards({
    this.xp = 0,
    this.gold = 0,
    this.gems = 0,
    this.items = const [],
  });
}

class QuestAchievement {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final AchievementRequirement requirement;
  final int points;
  final AchievementRewards rewards;

  QuestAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.requirement,
    required this.points,
    required this.rewards,
  });
}

enum AchievementType {
  special,
  timeBased,
  social,
  locationBased,
  questType,
}

class AchievementRequirement {
  final String type;
  final int target;

  AchievementRequirement({
    required this.type,
    required this.target,
  });
}

class AchievementRewards {
  final int xp;
  final int gold;
  final int gems;
  final List<String> items;

  AchievementRewards({
    this.xp = 0,
    this.gold = 0,
    this.gems = 0,
    this.items = const [],
  });
}

class ProgressionSummary {
  final String playerId;
  final int totalQuestsCompleted;
  final int totalXPEarned;
  final int totalGoldEarned;
  final int progressionLevel;
  final int unlockedMilestones;
  final int totalMilestones;
  final int unlockedAchievements;
  final int totalAchievements;
  final Map<QuestType, double> questTypeMastery;
  final double completionRate;
  final Duration averageCompletionTime;

  ProgressionSummary({
    required this.playerId,
    required this.totalQuestsCompleted,
    required this.totalXPEarned,
    required this.totalGoldEarned,
    required this.progressionLevel,
    required this.unlockedMilestones,
    required this.totalMilestones,
    required this.unlockedAchievements,
    required this.totalAchievements,
    required this.questTypeMastery,
    required this.completionRate,
    required this.averageCompletionTime,
  });
}