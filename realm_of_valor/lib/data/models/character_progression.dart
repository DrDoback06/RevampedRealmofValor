import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'character_classes.dart';
import 'character_achievements.dart';
import 'skill_analytics.dart';

enum MilestoneType {
  level,
  experience,
  skill,
  achievement,
  exploration,
  social,
  collection,
  combat,
  time,
  special,
}

enum ProgressionCategory {
  overall,
  combat,
  exploration,
  social,
  collection,
  skills,
  achievements,
  customization,
}

class Milestone extends Equatable {
  final String id;
  final String name;
  final String description;
  final MilestoneType type;
  final ProgressionCategory category;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> rewards;
  final String icon;
  final Color color;
  final String lore;
  final bool isRepeatable;
  final bool isHidden;
  final DateTime? releaseDate;
  final DateTime? expiryDate;

  const Milestone({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.requirements,
    required this.rewards,
    required this.icon,
    required this.color,
    required this.lore,
    this.isRepeatable = false,
    this.isHidden = false,
    this.releaseDate,
    this.expiryDate,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    type,
    category,
    requirements,
    rewards,
    icon,
    color,
    lore,
    isRepeatable,
    isHidden,
    releaseDate,
    expiryDate,
  ];
}

class MilestoneProgress extends Equatable {
  final String milestoneId;
  final bool isCompleted;
  final DateTime? completionDate;
  final int completionCount;
  final Map<String, dynamic> currentProgress;
  final Map<String, dynamic> bestProgress;
  final DateTime firstAttempt;
  final DateTime lastAttempt;

  const MilestoneProgress({
    required this.milestoneId,
    required this.isCompleted,
    this.completionDate,
    required this.completionCount,
    required this.currentProgress,
    required this.bestProgress,
    required this.firstAttempt,
    required this.lastAttempt,
  });

  @override
  List<Object?> get props => [
    milestoneId,
    isCompleted,
    completionDate,
    completionCount,
    currentProgress,
    bestProgress,
    firstAttempt,
    lastAttempt,
  ];
}

class CharacterProgression extends Equatable {
  final String characterId;
  final int level;
  final int experience;
  final int totalExperience;
  final Map<String, int> skillLevels;
  final Map<String, int> skillExperience;
  final List<String> achievements;
  final List<String> milestones;
  final Map<String, MilestoneProgress> milestoneProgress;
  final Map<String, dynamic> statistics;
  final Map<String, dynamic> records;
  final DateTime creationDate;
  final DateTime lastUpdated;
  final int playTime;
  final Map<String, dynamic> progressionData;

  const CharacterProgression({
    required this.characterId,
    required this.level,
    required this.experience,
    required this.totalExperience,
    required this.skillLevels,
    required this.skillExperience,
    required this.achievements,
    required this.milestones,
    required this.milestoneProgress,
    required this.statistics,
    required this.records,
    required this.creationDate,
    required this.lastUpdated,
    required this.playTime,
    required this.progressionData,
  });

  @override
  List<Object?> get props => [
    characterId,
    level,
    experience,
    totalExperience,
    skillLevels,
    skillExperience,
    achievements,
    milestones,
    milestoneProgress,
    statistics,
    records,
    creationDate,
    lastUpdated,
    playTime,
    progressionData,
  ];
}

class ProgressionReport extends Equatable {
  final String characterId;
  final DateTime reportDate;
  final ProgressionCategory category;
  final Map<String, dynamic> summary;
  final List<Milestone> availableMilestones;
  final List<Milestone> completedMilestones;
  final List<Milestone> recommendedMilestones;
  final Map<String, double> progressPercentages;
  final List<String> insights;
  final Map<String, dynamic> recommendations;

  const ProgressionReport({
    required this.characterId,
    required this.reportDate,
    required this.category,
    required this.summary,
    required this.availableMilestones,
    required this.completedMilestones,
    required this.recommendedMilestones,
    required this.progressPercentages,
    required this.insights,
    required this.recommendations,
  });

  @override
  List<Object?> get props => [
    characterId,
    reportDate,
    category,
    summary,
    availableMilestones,
    completedMilestones,
    recommendedMilestones,
    progressPercentages,
    insights,
    recommendations,
  ];
}

class CharacterProgressionService {
  static final Map<String, Milestone> _milestones = {
    // Level Milestones
    'level_10': Milestone(
      id: 'level_10',
      name: 'Novice Adventurer',
      description: 'Reach level 10',
      type: MilestoneType.level,
      category: ProgressionCategory.overall,
      requirements: {'level': 10},
      rewards: {'experience': 500, 'skill_points': 2, 'title': 'novice_adventurer'},
      icon: '⭐',
      color: Colors.green,
      lore: 'The first step on a long journey.',
    ),
    
    'level_25': Milestone(
      id: 'level_25',
      name: 'Experienced Warrior',
      description: 'Reach level 25',
      type: MilestoneType.level,
      category: ProgressionCategory.overall,
      requirements: {'level': 25},
      rewards: {'experience': 1000, 'skill_points': 5, 'title': 'experienced_warrior'},
      icon: '⭐⭐',
      color: Colors.blue,
      lore: 'Experience brings wisdom and power.',
    ),
    
    'level_50': Milestone(
      id: 'level_50',
      name: 'Veteran Hero',
      description: 'Reach level 50',
      type: MilestoneType.level,
      category: ProgressionCategory.overall,
      requirements: {'level': 50},
      rewards: {'experience': 2000, 'skill_points': 10, 'title': 'veteran_hero'},
      icon: '⭐⭐⭐',
      color: Colors.purple,
      lore: 'A true hero of the realm.',
    ),
    
    'level_100': Milestone(
      id: 'level_100',
      name: 'Legendary Champion',
      description: 'Reach level 100',
      type: MilestoneType.level,
      category: ProgressionCategory.overall,
      requirements: {'level': 100},
      rewards: {'experience': 5000, 'skill_points': 25, 'title': 'legendary_champion'},
      icon: '⭐⭐⭐⭐',
      color: Colors.orange,
      lore: 'Legends speak of your deeds.',
    ),

    // Experience Milestones
    'exp_100k': Milestone(
      id: 'exp_100k',
      name: 'Knowledge Seeker',
      description: 'Gain 100,000 total experience',
      type: MilestoneType.experience,
      category: ProgressionCategory.overall,
      requirements: {'total_experience': 100000},
      rewards: {'experience': 1000, 'skill_points': 3},
      icon: '📚',
      color: Colors.blue,
      lore: 'Knowledge is the greatest weapon.',
    ),
    
    'exp_1m': Milestone(
      id: 'exp_1m',
      name: 'Wisdom Keeper',
      description: 'Gain 1,000,000 total experience',
      type: MilestoneType.experience,
      category: ProgressionCategory.overall,
      requirements: {'total_experience': 1000000},
      rewards: {'experience': 5000, 'skill_points': 10, 'title': 'wisdom_keeper'},
      icon: '📚📚',
      color: Colors.purple,
      lore: 'Wisdom flows like a river.',
    ),

    // Skill Milestones
    'skill_master_1': Milestone(
      id: 'skill_master_1',
      name: 'Skill Master',
      description: 'Master your first skill to level 10',
      type: MilestoneType.skill,
      category: ProgressionCategory.skills,
      requirements: {'skill_level_10': 1},
      rewards: {'experience': 500, 'skill_points': 2},
      icon: '🎯',
      color: Colors.green,
      lore: 'Mastery begins with a single skill.',
    ),
    
    'skill_master_5': Milestone(
      id: 'skill_master_5',
      name: 'Multi-Skill Master',
      description: 'Master 5 skills to level 10',
      type: MilestoneType.skill,
      category: ProgressionCategory.skills,
      requirements: {'skill_level_10': 5},
      rewards: {'experience': 1000, 'skill_points': 5, 'title': 'multi_skill_master'},
      icon: '🎯🎯🎯🎯🎯',
      color: Colors.blue,
      lore: 'Versatility is the key to success.',
    ),

    // Achievement Milestones
    'achievement_collector': Milestone(
      id: 'achievement_collector',
      name: 'Achievement Collector',
      description: 'Unlock 10 achievements',
      type: MilestoneType.achievement,
      category: ProgressionCategory.achievements,
      requirements: {'achievements': 10},
      rewards: {'experience': 500, 'skill_points': 2},
      icon: '🏆',
      color: Colors.green,
      lore: 'Every achievement tells a story.',
    ),
    
    'achievement_master': Milestone(
      id: 'achievement_master',
      name: 'Achievement Master',
      description: 'Unlock 50 achievements',
      type: MilestoneType.achievement,
      category: ProgressionCategory.achievements,
      requirements: {'achievements': 50},
      rewards: {'experience': 2000, 'skill_points': 10, 'title': 'achievement_master'},
      icon: '🏆🏆🏆',
      color: Colors.purple,
      lore: 'A master of all challenges.',
    ),

    // Exploration Milestones
    'explorer_novice': Milestone(
      id: 'explorer_novice',
      name: 'Novice Explorer',
      description: 'Visit 10 different locations',
      type: MilestoneType.exploration,
      category: ProgressionCategory.exploration,
      requirements: {'locations_visited': 10},
      rewards: {'experience': 300, 'skill_points': 1},
      icon: '🗺️',
      color: Colors.green,
      lore: 'The world is vast and full of wonders.',
    ),
    
    'explorer_expert': Milestone(
      id: 'explorer_expert',
      name: 'Expert Explorer',
      description: 'Visit 50 different locations',
      type: MilestoneType.exploration,
      category: ProgressionCategory.exploration,
      requirements: {'locations_visited': 50},
      rewards: {'experience': 1000, 'skill_points': 5, 'title': 'expert_explorer'},
      icon: '🗺️🗺️',
      color: Colors.blue,
      lore: 'No corner of the realm is unknown to you.',
    ),

    // Social Milestones
    'social_butterfly': Milestone(
      id: 'social_butterfly',
      name: 'Social Butterfly',
      description: 'Add 20 friends to your list',
      type: MilestoneType.social,
      category: ProgressionCategory.social,
      requirements: {'friends_count': 20},
      rewards: {'experience': 500, 'skill_points': 2},
      icon: '🦋',
      color: Colors.pink,
      lore: 'Friendship is the greatest treasure.',
    ),
    
    'guild_leader': Milestone(
      id: 'guild_leader',
      name: 'Guild Leader',
      description: 'Lead a guild with 100 members',
      type: MilestoneType.social,
      category: ProgressionCategory.social,
      requirements: {'guild_members': 100, 'guild_leader': true},
      rewards: {'experience': 2000, 'skill_points': 10, 'title': 'guild_leader'},
      icon: '👑',
      color: Colors.purple,
      lore: 'Leadership is not about power, but about responsibility.',
    ),

    // Collection Milestones
    'collector_novice': Milestone(
      id: 'collector_novice',
      name: 'Novice Collector',
      description: 'Collect 50 different items',
      type: MilestoneType.collection,
      category: ProgressionCategory.collection,
      requirements: {'unique_items': 50},
      rewards: {'experience': 300, 'skill_points': 1},
      icon: '📦',
      color: Colors.green,
      lore: 'Every item has a story.',
    ),
    
    'collector_expert': Milestone(
      id: 'collector_expert',
      name: 'Expert Collector',
      description: 'Collect 200 different items',
      type: MilestoneType.collection,
      category: ProgressionCategory.collection,
      requirements: {'unique_items': 200},
      rewards: {'experience': 1000, 'skill_points': 5, 'title': 'expert_collector'},
      icon: '📦📦',
      color: Colors.blue,
      lore: 'A true connoisseur of rare items.',
    ),

    // Combat Milestones
    'combat_novice': Milestone(
      id: 'combat_novice',
      name: 'Combat Novice',
      description: 'Win 10 battles',
      type: MilestoneType.combat,
      category: ProgressionCategory.combat,
      requirements: {'battles_won': 10},
      rewards: {'experience': 300, 'skill_points': 1},
      icon: '⚔️',
      color: Colors.green,
      lore: 'Victory in battle brings honor.',
    ),
    
    'combat_veteran': Milestone(
      id: 'combat_veteran',
      name: 'Combat Veteran',
      description: 'Win 100 battles',
      type: MilestoneType.combat,
      category: ProgressionCategory.combat,
      requirements: {'battles_won': 100},
      rewards: {'experience': 1000, 'skill_points': 5, 'title': 'combat_veteran'},
      icon: '⚔️⚔️',
      color: Colors.blue,
      lore: 'Experience in battle is invaluable.',
    ),
    
    'combat_legend': Milestone(
      id: 'combat_legend',
      name: 'Combat Legend',
      description: 'Win 1000 battles',
      type: MilestoneType.combat,
      category: ProgressionCategory.combat,
      requirements: {'battles_won': 1000},
      rewards: {'experience': 5000, 'skill_points': 25, 'title': 'combat_legend'},
      icon: '⚔️⚔️⚔️',
      color: Colors.purple,
      lore: 'Your name is feared on the battlefield.',
    ),

    // Time Milestones
    'time_dedicated': Milestone(
      id: 'time_dedicated',
      name: 'Dedicated Player',
      description: 'Play for 100 hours',
      type: MilestoneType.time,
      category: ProgressionCategory.overall,
      requirements: {'play_time_hours': 100},
      rewards: {'experience': 500, 'skill_points': 2},
      icon: '⏰',
      color: Colors.green,
      lore: 'Time spent in adventure is never wasted.',
    ),
    
    'time_legendary': Milestone(
      id: 'time_legendary',
      name: 'Legendary Dedication',
      description: 'Play for 1000 hours',
      type: MilestoneType.time,
      category: ProgressionCategory.overall,
      requirements: {'play_time_hours': 1000},
      rewards: {'experience': 2000, 'skill_points': 10, 'title': 'legendary_dedication'},
      icon: '⏰⏰⏰',
      color: Colors.purple,
      lore: 'Your dedication knows no bounds.',
    ),

    // Special Milestones
    'first_prestige': Milestone(
      id: 'first_prestige',
      name: 'First Prestige',
      description: 'Complete your first prestige',
      type: MilestoneType.special,
      category: ProgressionCategory.overall,
      requirements: {'prestige_count': 1},
      rewards: {'experience': 5000, 'skill_points': 25, 'title': 'prestige_master'},
      icon: '🌟',
      color: Colors.amber,
      lore: 'Transcending mortal limits.',
    ),
    
    'all_achievements': Milestone(
      id: 'all_achievements',
      name: 'Completionist',
      description: 'Unlock all achievements in the game',
      type: MilestoneType.special,
      category: ProgressionCategory.achievements,
      requirements: {'all_achievements': true},
      rewards: {'experience': 10000, 'skill_points': 50, 'title': 'completionist'},
      icon: '🏆🏆🏆🏆🏆',
      color: Colors.amber,
      lore: 'The ultimate completionist.',
    ),
  };

  static Milestone getMilestone(String id) {
    return _milestones[id] ?? _milestones['level_10']!;
  }

  static List<Milestone> getMilestonesByType(MilestoneType type) {
    return _milestones.values.where((m) => m.type == type).toList();
  }

  static List<Milestone> getMilestonesByCategory(ProgressionCategory category) {
    return _milestones.values.where((m) => m.category == category).toList();
  }

  static List<Milestone> getAllMilestones() {
    return _milestones.values.toList();
  }

  static CharacterProgression createDefaultProgression(String characterId) {
    return CharacterProgression(
      characterId: characterId,
      level: 1,
      experience: 0,
      totalExperience: 0,
      skillLevels: {},
      skillExperience: {},
      achievements: [],
      milestones: [],
      milestoneProgress: {},
      statistics: {
        'battles_won': 0,
        'battles_lost': 0,
        'locations_visited': 0,
        'quests_completed': 0,
        'items_collected': 0,
        'friends_count': 0,
        'guild_members': 0,
        'play_time_hours': 0,
      },
      records: {
        'highest_level': 1,
        'most_experience': 0,
        'longest_win_streak': 0,
        'fastest_quest_completion': null,
        'most_damage_dealt': 0,
        'most_healing_done': 0,
      },
      creationDate: DateTime.now(),
      lastUpdated: DateTime.now(),
      playTime: 0,
      progressionData: {},
    );
  }

  static bool checkMilestoneCompletion(Milestone milestone, CharacterProgression progression) {
    for (final requirement in milestone.requirements.entries) {
      final requiredValue = requirement.value;
      final currentValue = _getProgressionValue(progression, requirement.key);
      
      if (currentValue == null) return false;
      
      if (requiredValue is bool) {
        if (currentValue != requiredValue) return false;
      } else if (requiredValue is int) {
        if (currentValue < requiredValue) return false;
      } else if (requiredValue is double) {
        if (currentValue < requiredValue) return false;
      }
    }
    
    return true;
  }

  static dynamic _getProgressionValue(CharacterProgression progression, String key) {
    switch (key) {
      case 'level':
        return progression.level;
      case 'total_experience':
        return progression.totalExperience;
      case 'achievements':
        return progression.achievements.length;
      case 'skill_level_10':
        return progression.skillLevels.values.where((level) => level >= 10).length;
      case 'locations_visited':
        return progression.statistics['locations_visited'] ?? 0;
      case 'friends_count':
        return progression.statistics['friends_count'] ?? 0;
      case 'guild_members':
        return progression.statistics['guild_members'] ?? 0;
      case 'unique_items':
        return progression.statistics['items_collected'] ?? 0;
      case 'battles_won':
        return progression.statistics['battles_won'] ?? 0;
      case 'play_time_hours':
        return progression.playTime / 3600; // Convert seconds to hours
      case 'prestige_count':
        return progression.progressionData['prestige_count'] ?? 0;
      case 'all_achievements':
        // This would need to be calculated based on total available achievements
        return false;
      default:
        return progression.statistics[key] ?? progression.progressionData[key];
    }
  }

  static CharacterProgression updateProgression(CharacterProgression progression, Map<String, dynamic> updates) {
    final updatedStatistics = Map<String, dynamic>.from(progression.statistics);
    final updatedProgressionData = Map<String, dynamic>.from(progression.progressionData);
    
    for (final entry in updates.entries) {
      if (entry.key == 'level') {
        // Handle level updates
        final newLevel = entry.value as int;
        if (newLevel > progression.level) {
          updatedProgressionData['highest_level'] = newLevel;
        }
      } else if (entry.key == 'experience') {
        // Handle experience updates
        final newExperience = entry.value as int;
        if (newExperience > progression.totalExperience) {
          updatedProgressionData['most_experience'] = newExperience;
        }
      } else if (entry.key == 'statistics') {
        // Handle statistics updates
        final stats = entry.value as Map<String, dynamic>;
        updatedStatistics.addAll(stats);
      } else {
        // Handle other progression data
        updatedProgressionData[entry.key] = entry.value;
      }
    }
    
    return CharacterProgression(
      characterId: progression.characterId,
      level: updates['level'] ?? progression.level,
      experience: updates['experience'] ?? progression.experience,
      totalExperience: updates['total_experience'] ?? progression.totalExperience,
      skillLevels: Map<String, int>.from(progression.skillLevels),
      skillExperience: Map<String, int>.from(progression.skillExperience),
      achievements: List<String>.from(progression.achievements),
      milestones: List<String>.from(progression.milestones),
      milestoneProgress: Map<String, MilestoneProgress>.from(progression.milestoneProgress),
      statistics: updatedStatistics,
      records: Map<String, dynamic>.from(progression.records),
      creationDate: progression.creationDate,
      lastUpdated: DateTime.now(),
      playTime: updates['play_time'] ?? progression.playTime,
      progressionData: updatedProgressionData,
    );
  }

  static MilestoneProgress createMilestoneProgress(String milestoneId) {
    return MilestoneProgress(
      milestoneId: milestoneId,
      isCompleted: false,
      completionCount: 0,
      currentProgress: {},
      bestProgress: {},
      firstAttempt: DateTime.now(),
      lastAttempt: DateTime.now(),
    );
  }

  static MilestoneProgress updateMilestoneProgress(MilestoneProgress progress, Map<String, dynamic> currentProgress) {
    final isCompleted = progress.isCompleted;
    final completionCount = progress.completionCount;
    final completionDate = progress.completionDate;
    
    return MilestoneProgress(
      milestoneId: progress.milestoneId,
      isCompleted: isCompleted,
      completionDate: completionDate,
      completionCount: completionCount,
      currentProgress: currentProgress,
      bestProgress: Map<String, dynamic>.from(progress.bestProgress),
      firstAttempt: progress.firstAttempt,
      lastAttempt: DateTime.now(),
    );
  }

  static MilestoneProgress completeMilestone(MilestoneProgress progress) {
    return MilestoneProgress(
      milestoneId: progress.milestoneId,
      isCompleted: true,
      completionDate: DateTime.now(),
      completionCount: progress.completionCount + 1,
      currentProgress: Map<String, dynamic>.from(progress.currentProgress),
      bestProgress: Map<String, dynamic>.from(progress.bestProgress),
      firstAttempt: progress.firstAttempt,
      lastAttempt: DateTime.now(),
    );
  }

  static ProgressionReport generateReport({
    required String characterId,
    required CharacterProgression progression,
    required ProgressionCategory category,
  }) {
    final summary = <String, dynamic>{};
    final availableMilestones = <Milestone>[];
    final completedMilestones = <Milestone>[];
    final recommendedMilestones = <Milestone>[];
    final progressPercentages = <String, double>{};
    final insights = <String>[];
    final recommendations = <String, dynamic>{};

    // Generate summary based on category
    switch (category) {
      case ProgressionCategory.overall:
        summary['level'] = progression.level;
        summary['total_experience'] = progression.totalExperience;
        summary['achievements'] = progression.achievements.length;
        summary['milestones'] = progression.milestones.length;
        summary['play_time_hours'] = progression.playTime / 3600;
        break;
      case ProgressionCategory.combat:
        summary['battles_won'] = progression.statistics['battles_won'] ?? 0;
        summary['battles_lost'] = progression.statistics['battles_lost'] ?? 0;
        summary['win_rate'] = _calculateWinRate(progression);
        summary['total_damage_dealt'] = progression.records['most_damage_dealt'] ?? 0;
        break;
      case ProgressionCategory.exploration:
        summary['locations_visited'] = progression.statistics['locations_visited'] ?? 0;
        summary['quests_completed'] = progression.statistics['quests_completed'] ?? 0;
        break;
      case ProgressionCategory.social:
        summary['friends_count'] = progression.statistics['friends_count'] ?? 0;
        summary['guild_members'] = progression.statistics['guild_members'] ?? 0;
        break;
      case ProgressionCategory.collection:
        summary['items_collected'] = progression.statistics['items_collected'] ?? 0;
        break;
      case ProgressionCategory.skills:
        summary['total_skills'] = progression.skillLevels.length;
        summary['max_skill_level'] = progression.skillLevels.values.isNotEmpty 
            ? progression.skillLevels.values.reduce((a, b) => a > b ? a : b) 
            : 0;
        break;
      case ProgressionCategory.achievements:
        summary['achievements'] = progression.achievements.length;
        break;
      case ProgressionCategory.customization:
        // Customization data would be handled separately
        break;
    }

    // Process milestones for the category
    final categoryMilestones = getMilestonesByCategory(category);
    for (final milestone in categoryMilestones) {
      final progress = progression.milestoneProgress[milestone.id];
      
      if (progress != null && progress.isCompleted) {
        completedMilestones.add(milestone);
      } else if (checkMilestoneCompletion(milestone, progression)) {
        availableMilestones.add(milestone);
      } else {
        // Calculate progress percentage
        final percentage = _calculateMilestoneProgress(milestone, progression);
        progressPercentages[milestone.id] = percentage;
        
        if (percentage >= 0.8) {
          recommendedMilestones.add(milestone);
        }
      }
    }

    // Generate insights
    insights.addAll(_generateInsights(progression, category));

    // Generate recommendations
    recommendations.addAll(_generateRecommendations(progression, category));

    return ProgressionReport(
      characterId: characterId,
      reportDate: DateTime.now(),
      category: category,
      summary: summary,
      availableMilestones: availableMilestones,
      completedMilestones: completedMilestones,
      recommendedMilestones: recommendedMilestones,
      progressPercentages: progressPercentages,
      insights: insights,
      recommendations: recommendations,
    );
  }

  static double _calculateWinRate(CharacterProgression progression) {
    final won = progression.statistics['battles_won'] ?? 0;
    final lost = progression.statistics['battles_lost'] ?? 0;
    final total = won + lost;
    
    return total > 0 ? won / total : 0.0;
  }

  static double _calculateMilestoneProgress(Milestone milestone, CharacterProgression progression) {
    double totalProgress = 0.0;
    int requirementCount = 0;
    
    for (final requirement in milestone.requirements.entries) {
      final requiredValue = requirement.value;
      final currentValue = _getProgressionValue(progression, requirement.key);
      
      if (currentValue != null && requiredValue is num) {
        totalProgress += (currentValue / requiredValue).clamp(0.0, 1.0);
        requirementCount++;
      }
    }
    
    return requirementCount > 0 ? totalProgress / requirementCount : 0.0;
  }

  static List<String> _generateInsights(CharacterProgression progression, ProgressionCategory category) {
    final insights = <String>[];
    
    switch (category) {
      case ProgressionCategory.overall:
        if (progression.level < 10) {
          insights.add('Focus on completing quests to gain experience and level up quickly.');
        }
        if (progression.achievements.length < 5) {
          insights.add('Try completing more achievements to unlock rewards and titles.');
        }
        break;
      case ProgressionCategory.combat:
        final winRate = _calculateWinRate(progression);
        if (winRate < 0.5) {
          insights.add('Your battle win rate is low. Consider upgrading your equipment or practicing your skills.');
        }
        break;
      case ProgressionCategory.exploration:
        if ((progression.statistics['locations_visited'] ?? 0) < 5) {
          insights.add('Explore more locations to discover new quests and opportunities.');
        }
        break;
      case ProgressionCategory.social:
        if ((progression.statistics['friends_count'] ?? 0) < 5) {
          insights.add('Make more friends to unlock social features and group activities.');
        }
        break;
      case ProgressionCategory.collection:
        if ((progression.statistics['items_collected'] ?? 0) < 20) {
          insights.add('Collect more items to unlock collection-based rewards.');
        }
        break;
      case ProgressionCategory.skills:
        if (progression.skillLevels.isEmpty) {
          insights.add('Start developing your skills to become more powerful.');
        }
        break;
      case ProgressionCategory.achievements:
        if (progression.achievements.length < 10) {
          insights.add('Complete more achievements to track your progress and earn rewards.');
        }
        break;
      case ProgressionCategory.customization:
        insights.add('Customize your character to express your unique style.');
        break;
    }
    
    return insights;
  }

  static Map<String, dynamic> _generateRecommendations(CharacterProgression progression, ProgressionCategory category) {
    final recommendations = <String, dynamic>{};
    
    switch (category) {
      case ProgressionCategory.overall:
        if (progression.level < 10) {
          recommendations['focus_quests'] = 0.8;
        }
        if (progression.achievements.length < 5) {
          recommendations['complete_achievements'] = 0.7;
        }
        break;
      case ProgressionCategory.combat:
        final winRate = _calculateWinRate(progression);
        if (winRate < 0.5) {
          recommendations['upgrade_equipment'] = 0.8;
          recommendations['practice_skills'] = 0.7;
        }
        break;
      case ProgressionCategory.exploration:
        if ((progression.statistics['locations_visited'] ?? 0) < 5) {
          recommendations['explore_more'] = 0.9;
        }
        break;
      case ProgressionCategory.social:
        if ((progression.statistics['friends_count'] ?? 0) < 5) {
          recommendations['make_friends'] = 0.8;
        }
        break;
      case ProgressionCategory.collection:
        if ((progression.statistics['items_collected'] ?? 0) < 20) {
          recommendations['collect_items'] = 0.7;
        }
        break;
      case ProgressionCategory.skills:
        if (progression.skillLevels.isEmpty) {
          recommendations['develop_skills'] = 0.9;
        }
        break;
      case ProgressionCategory.achievements:
        if (progression.achievements.length < 10) {
          recommendations['pursue_achievements'] = 0.8;
        }
        break;
      case ProgressionCategory.customization:
        recommendations['customize_character'] = 0.6;
        break;
    }
    
    return recommendations;
  }
}
