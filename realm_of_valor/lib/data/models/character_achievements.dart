import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum AchievementType {
  combat,
  exploration,
  social,
  collection,
  progression,
  special,
  seasonal,
  event,
}

enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

enum TitleType {
  combat,
  social,
  exploration,
  collection,
  prestige,
  special,
  seasonal,
  event,
}

class Achievement extends Equatable {
  final String id;
  final String name;
  final String description;
  final AchievementType type;
  final AchievementRarity rarity;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> rewards;
  final String icon;
  final Color color;
  final String lore;
  final bool isHidden;
  final bool isRepeatable;
  final DateTime? releaseDate;
  final DateTime? expiryDate;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.requirements,
    required this.rewards,
    required this.icon,
    required this.color,
    required this.lore,
    this.isHidden = false,
    this.isRepeatable = false,
    this.releaseDate,
    this.expiryDate,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    type,
    rarity,
    requirements,
    rewards,
    icon,
    color,
    lore,
    isHidden,
    isRepeatable,
    releaseDate,
    expiryDate,
  ];
}

class Title extends Equatable {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final TitleType type;
  final AchievementRarity rarity;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> effects;
  final String icon;
  final Color color;
  final String lore;
  final bool isEquippable;
  final bool isPermanent;
  final DateTime? releaseDate;
  final DateTime? expiryDate;

  const Title({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.type,
    required this.rarity,
    required this.requirements,
    required this.effects,
    required this.icon,
    required this.color,
    required this.lore,
    this.isEquippable = true,
    this.isPermanent = false,
    this.releaseDate,
    this.expiryDate,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    displayName,
    description,
    type,
    rarity,
    requirements,
    effects,
    icon,
    color,
    lore,
    isEquippable,
    isPermanent,
    releaseDate,
    expiryDate,
  ];
}

class AchievementProgress extends Equatable {
  final String achievementId;
  final bool isCompleted;
  final DateTime? completionDate;
  final int progress;
  final int requiredProgress;
  final int completionCount;
  final Map<String, dynamic> currentProgress;

  const AchievementProgress({
    required this.achievementId,
    required this.isCompleted,
    this.completionDate,
    required this.progress,
    required this.requiredProgress,
    required this.completionCount,
    required this.currentProgress,
  });

  double get progressPercentage => progress / requiredProgress;

  @override
  List<Object?> get props => [
    achievementId,
    isCompleted,
    completionDate,
    progress,
    requiredProgress,
    completionCount,
    currentProgress,
  ];
}

class TitleProgress extends Equatable {
  final String titleId;
  final bool isUnlocked;
  final DateTime? unlockDate;
  final bool isEquipped;
  final DateTime? equipDate;
  final int usageCount;

  const TitleProgress({
    required this.titleId,
    required this.isUnlocked,
    this.unlockDate,
    required this.isEquipped,
    this.equipDate,
    required this.usageCount,
  });

  @override
  List<Object?> get props => [
    titleId,
    isUnlocked,
    unlockDate,
    isEquipped,
    equipDate,
    usageCount,
  ];
}

class AchievementService {
  static final Map<String, Achievement> _achievements = {
    // Combat Achievements
    'first_victory': Achievement(
      id: 'first_victory',
      name: 'First Victory',
      description: 'Win your first battle',
      type: AchievementType.combat,
      rarity: AchievementRarity.common,
      requirements: {'battles_won': 1},
      rewards: {'experience': 100, 'skill_points': 1},
      icon: '⚔️',
      color: Colors.green,
      lore: 'Every warrior remembers their first victory.',
    ),
    
    'battle_master': Achievement(
      id: 'battle_master',
      name: 'Battle Master',
      description: 'Win 100 battles',
      type: AchievementType.combat,
      rarity: AchievementRarity.rare,
      requirements: {'battles_won': 100},
      rewards: {'experience': 1000, 'skill_points': 5, 'title': 'battle_master'},
      icon: '🏆',
      color: Colors.orange,
      lore: 'A true master of combat.',
    ),
    
    'undefeated': Achievement(
      id: 'undefeated',
      name: 'Undefeated',
      description: 'Win 10 battles in a row without losing',
      type: AchievementType.combat,
      rarity: AchievementRarity.epic,
      requirements: {'win_streak': 10},
      rewards: {'experience': 2000, 'skill_points': 10, 'title': 'undefeated'},
      icon: '👑',
      color: Colors.purple,
      lore: 'Unstoppable force meets immovable object.',
    ),

    // Exploration Achievements
    'explorer': Achievement(
      id: 'explorer',
      name: 'Explorer',
      description: 'Visit 10 different locations',
      type: AchievementType.exploration,
      rarity: AchievementRarity.common,
      requirements: {'locations_visited': 10},
      rewards: {'experience': 200, 'skill_points': 2},
      icon: '🗺️',
      color: Colors.blue,
      lore: 'The world is vast and full of wonders.',
    ),
    
    'adventurer': Achievement(
      id: 'adventurer',
      name: 'Adventurer',
      description: 'Complete 50 quests',
      type: AchievementType.exploration,
      rarity: AchievementRarity.uncommon,
      requirements: {'quests_completed': 50},
      rewards: {'experience': 500, 'skill_points': 3, 'title': 'adventurer'},
      icon: '🏔️',
      color: Colors.green,
      lore: 'Adventure awaits around every corner.',
    ),
    
    'world_wanderer': Achievement(
      id: 'world_wanderer',
      name: 'World Wanderer',
      description: 'Visit all major locations in the realm',
      type: AchievementType.exploration,
      rarity: AchievementRarity.legendary,
      requirements: {'all_locations_visited': true},
      rewards: {'experience': 5000, 'skill_points': 20, 'title': 'world_wanderer'},
      icon: '🌍',
      color: Colors.cyan,
      lore: 'The entire realm has felt your footsteps.',
    ),

    // Social Achievements
    'friend_maker': Achievement(
      id: 'friend_maker',
      name: 'Friend Maker',
      description: 'Add 10 friends to your list',
      type: AchievementType.social,
      rarity: AchievementRarity.common,
      requirements: {'friends_count': 10},
      rewards: {'experience': 150, 'skill_points': 1},
      icon: '🤝',
      color: Colors.green,
      lore: 'Friendship is the greatest treasure.',
    ),
    
    'guild_master': Achievement(
      id: 'guild_master',
      name: 'Guild Master',
      description: 'Create and lead a guild with 50 members',
      type: AchievementType.social,
      rarity: AchievementRarity.epic,
      requirements: {'guild_members': 50, 'guild_leader': true},
      rewards: {'experience': 3000, 'skill_points': 15, 'title': 'guild_master'},
      icon: '🏰',
      color: Colors.purple,
      lore: 'Leadership is not about power, but about responsibility.',
    ),

    // Collection Achievements
    'card_collector': Achievement(
      id: 'card_collector',
      name: 'Card Collector',
      description: 'Collect 100 different cards',
      type: AchievementType.collection,
      rarity: AchievementRarity.rare,
      requirements: {'unique_cards': 100},
      rewards: {'experience': 1000, 'skill_points': 5, 'title': 'card_collector'},
      icon: '🃏',
      color: Colors.blue,
      lore: 'Every card tells a story.',
    ),
    
    'master_collector': Achievement(
      id: 'master_collector',
      name: 'Master Collector',
      description: 'Collect all cards in the game',
      type: AchievementType.collection,
      rarity: AchievementRarity.mythic,
      requirements: {'all_cards_collected': true},
      rewards: {'experience': 10000, 'skill_points': 50, 'title': 'master_collector'},
      icon: '📚',
      color: Colors.amber,
      lore: 'The ultimate collector of knowledge and power.',
    ),

    // Progression Achievements
    'level_master': Achievement(
      id: 'level_master',
      name: 'Level Master',
      description: 'Reach level 100',
      type: AchievementType.progression,
      rarity: AchievementRarity.epic,
      requirements: {'level': 100},
      rewards: {'experience': 2000, 'skill_points': 10, 'title': 'level_master'},
      icon: '⭐',
      color: Colors.yellow,
      lore: 'Power comes with experience.',
    ),
    
    'prestige_master': Achievement(
      id: 'prestige_master',
      name: 'Prestige Master',
      description: 'Reach the highest prestige level',
      type: AchievementType.progression,
      rarity: AchievementRarity.mythic,
      requirements: {'max_prestige': true},
      rewards: {'experience': 50000, 'skill_points': 100, 'title': 'prestige_master'},
      icon: '🌟',
      color: Colors.white,
      lore: 'Transcending all known limits.',
    ),

    // Special Achievements
    'first_blood': Achievement(
      id: 'first_blood',
      name: 'First Blood',
      description: 'Deal the first damage in a battle',
      type: AchievementType.special,
      rarity: AchievementRarity.common,
      requirements: {'first_damage_dealt': 1},
      rewards: {'experience': 50, 'skill_points': 1},
      icon: '🩸',
      color: Colors.red,
      lore: 'The first strike is often the most important.',
    ),
    
    'lucky_strike': Achievement(
      id: 'lucky_strike',
      name: 'Lucky Strike',
      description: 'Land a critical hit with 1% chance',
      type: AchievementType.special,
      rarity: AchievementRarity.rare,
      requirements: {'critical_hit_1_percent': 1},
      rewards: {'experience': 500, 'skill_points': 3, 'title': 'lucky_strike'},
      icon: '🍀',
      color: Colors.green,
      lore: 'Sometimes luck is better than skill.',
    ),
  };

  static final Map<String, Title> _titles = {
    // Combat Titles
    'battle_master': Title(
      id: 'battle_master',
      name: 'Battle Master',
      displayName: 'Battle Master',
      description: 'A master of combat who has won countless battles',
      type: TitleType.combat,
      rarity: AchievementRarity.rare,
      requirements: {'achievement': 'battle_master'},
      effects: {'damage_dealt': 0.05, 'critical_chance': 0.02},
      icon: '⚔️',
      color: Colors.orange,
      lore: 'Victory is not just about strength, but about mastery.',
    ),
    
    'undefeated': Title(
      id: 'undefeated',
      name: 'Undefeated',
      displayName: 'The Undefeated',
      description: 'One who has never tasted defeat',
      type: TitleType.combat,
      rarity: AchievementRarity.epic,
      requirements: {'achievement': 'undefeated'},
      effects: {'damage_dealt': 0.1, 'damage_taken': -0.05, 'critical_chance': 0.05},
      icon: '👑',
      color: Colors.purple,
      lore: 'Unstoppable force meets immovable object.',
    ),

    // Exploration Titles
    'adventurer': Title(
      id: 'adventurer',
      name: 'Adventurer',
      displayName: 'The Adventurer',
      description: 'A brave soul who seeks adventure',
      type: TitleType.exploration,
      rarity: AchievementRarity.uncommon,
      requirements: {'achievement': 'adventurer'},
      effects: {'experience_gain': 0.1, 'quest_rewards': 0.05},
      icon: '🏔️',
      color: Colors.green,
      lore: 'Adventure awaits around every corner.',
    ),
    
    'world_wanderer': Title(
      id: 'world_wanderer',
      name: 'World Wanderer',
      displayName: 'World Wanderer',
      description: 'One who has explored every corner of the realm',
      type: TitleType.exploration,
      rarity: AchievementRarity.legendary,
      requirements: {'achievement': 'world_wanderer'},
      effects: {'experience_gain': 0.2, 'quest_rewards': 0.1, 'movement_speed': 0.1},
      icon: '🌍',
      color: Colors.cyan,
      lore: 'The entire realm has felt your footsteps.',
    ),

    // Social Titles
    'guild_master': Title(
      id: 'guild_master',
      name: 'Guild Master',
      displayName: 'Guild Master',
      description: 'A leader of many, respected by all',
      type: TitleType.social,
      rarity: AchievementRarity.epic,
      requirements: {'achievement': 'guild_master'},
      effects: {'charisma': 0.2, 'guild_bonus': 0.1},
      icon: '🏰',
      color: Colors.purple,
      lore: 'Leadership is not about power, but about responsibility.',
    ),

    // Collection Titles
    'card_collector': Title(
      id: 'card_collector',
      name: 'Card Collector',
      displayName: 'The Collector',
      description: 'One who seeks to collect all knowledge',
      type: TitleType.collection,
      rarity: AchievementRarity.rare,
      requirements: {'achievement': 'card_collector'},
      effects: {'card_drop_rate': 0.1, 'card_power': 0.05},
      icon: '🃏',
      color: Colors.blue,
      lore: 'Every card tells a story.',
    ),
    
    'master_collector': Title(
      id: 'master_collector',
      name: 'Master Collector',
      displayName: 'Master Collector',
      description: 'The ultimate collector of knowledge and power',
      type: TitleType.collection,
      rarity: AchievementRarity.mythic,
      requirements: {'achievement': 'master_collector'},
      effects: {'card_drop_rate': 0.2, 'card_power': 0.1, 'all_stats': 0.05},
      icon: '📚',
      color: Colors.amber,
      lore: 'The ultimate collector of knowledge and power.',
    ),

    // Progression Titles
    'level_master': Title(
      id: 'level_master',
      name: 'Level Master',
      displayName: 'Level Master',
      description: 'One who has reached the pinnacle of power',
      type: TitleType.special,
      rarity: AchievementRarity.epic,
      requirements: {'achievement': 'level_master'},
      effects: {'experience_gain': 0.15, 'skill_point_gain': 0.1},
      icon: '⭐',
      color: Colors.yellow,
      lore: 'Power comes with experience.',
    ),
    
    'prestige_master': Title(
      id: 'prestige_master',
      name: 'Prestige Master',
      displayName: 'Prestige Master',
      description: 'One who has transcended all known limits',
      type: TitleType.prestige,
      rarity: AchievementRarity.mythic,
      requirements: {'achievement': 'prestige_master'},
      effects: {'all_stats': 0.1, 'experience_gain': 0.25, 'reality_bending': 0.05},
      icon: '🌟',
      color: Colors.white,
      lore: 'Transcending all known limits.',
    ),

    // Special Titles
    'lucky_strike': Title(
      id: 'lucky_strike',
      name: 'Lucky Strike',
      displayName: 'Lucky Strike',
      description: 'One blessed with extraordinary luck',
      type: TitleType.special,
      rarity: AchievementRarity.rare,
      requirements: {'achievement': 'lucky_strike'},
      effects: {'luck': 0.2, 'critical_chance': 0.05, 'rare_drop_rate': 0.1},
      icon: '🍀',
      color: Colors.green,
      lore: 'Sometimes luck is better than skill.',
    ),
  };

  static Achievement getAchievement(String id) {
    return _achievements[id] ?? _achievements['first_victory']!;
  }

  static Title getTitle(String id) {
    return _titles[id] ?? _titles['battle_master']!;
  }

  static List<Achievement> getAchievementsByType(AchievementType type) {
    return _achievements.values.where((a) => a.type == type).toList();
  }

  static List<Achievement> getAchievementsByRarity(AchievementRarity rarity) {
    return _achievements.values.where((a) => a.rarity == rarity).toList();
  }

  static List<Title> getTitlesByType(TitleType type) {
    return _titles.values.where((t) => t.type == type).toList();
  }

  static List<Title> getTitlesByRarity(AchievementRarity rarity) {
    return _titles.values.where((t) => t.rarity == rarity).toList();
  }

  static List<Achievement> getAllAchievements() {
    return _achievements.values.toList();
  }

  static List<Title> getAllTitles() {
    return _titles.values.toList();
  }

  static bool checkAchievementCompletion(Achievement achievement, Map<String, dynamic> playerStats) {
    for (final requirement in achievement.requirements.entries) {
      final requiredValue = requirement.value;
      final playerValue = playerStats[requirement.key];
      
      if (playerValue == null) return false;
      
      if (requiredValue is bool) {
        if (playerValue != requiredValue) return false;
      } else if (requiredValue is int) {
        if (playerValue < requiredValue) return false;
      } else if (requiredValue is double) {
        if (playerValue < requiredValue) return false;
      }
    }
    
    return true;
  }

  static bool checkTitleUnlock(Title title, Map<String, dynamic> playerStats, List<String> completedAchievements) {
    for (final requirement in title.requirements.entries) {
      if (requirement.key == 'achievement') {
        if (!completedAchievements.contains(requirement.value)) {
          return false;
        }
      } else {
        final requiredValue = requirement.value;
        final playerValue = playerStats[requirement.key];
        
        if (playerValue == null) return false;
        
        if (requiredValue is bool) {
          if (playerValue != requiredValue) return false;
        } else if (requiredValue is int) {
          if (playerValue < requiredValue) return false;
        } else if (requiredValue is double) {
          if (playerValue < requiredValue) return false;
        }
      }
    }
    
    return true;
  }

  static Map<String, double> calculateTitleEffects(Title title) {
    return Map<String, double>.from(title.effects);
  }

  static List<Achievement> getAvailableAchievements(Map<String, dynamic> playerStats) {
    return _achievements.values
        .where((achievement) => !checkAchievementCompletion(achievement, playerStats))
        .toList();
  }

  static List<Title> getAvailableTitles(Map<String, dynamic> playerStats, List<String> completedAchievements) {
    return _titles.values
        .where((title) => !checkTitleUnlock(title, playerStats, completedAchievements))
        .toList();
  }

  static List<String> getAchievementRecommendations(Map<String, dynamic> playerStats) {
    final recommendations = <String>[];
    
    for (final achievement in _achievements.values) {
      if (!checkAchievementCompletion(achievement, playerStats)) {
        final missingRequirements = <String>[];
        
        for (final requirement in achievement.requirements.entries) {
          final requiredValue = requirement.value;
          final playerValue = playerStats[requirement.key];
          
          if (playerValue == null) {
            missingRequirements.add('${requirement.key}: 0/${requiredValue}');
          } else if (requiredValue is int && playerValue < requiredValue) {
            missingRequirements.add('${requirement.key}: $playerValue/$requiredValue');
          }
        }
        
        if (missingRequirements.length <= 2) {
          recommendations.add('${achievement.name}: ${missingRequirements.join(', ')}');
        }
      }
    }
    
    return recommendations;
  }

  static List<String> getTitleRecommendations(Map<String, dynamic> playerStats, List<String> completedAchievements) {
    final recommendations = <String>[];
    
    for (final title in _titles.values) {
      if (!checkTitleUnlock(title, playerStats, completedAchievements)) {
        final missingRequirements = <String>[];
        
        for (final requirement in title.requirements.entries) {
          if (requirement.key == 'achievement') {
            if (!completedAchievements.contains(requirement.value)) {
              missingRequirements.add('Complete ${requirement.value} achievement');
            }
          } else {
            final requiredValue = requirement.value;
            final playerValue = playerStats[requirement.key];
            
            if (playerValue == null) {
              missingRequirements.add('${requirement.key}: 0/${requiredValue}');
            } else if (requiredValue is int && playerValue < requiredValue) {
              missingRequirements.add('${requirement.key}: $playerValue/$requiredValue');
            }
          }
        }
        
        if (missingRequirements.length <= 2) {
          recommendations.add('${title.name}: ${missingRequirements.join(', ')}');
        }
      }
    }
    
    return recommendations;
  }
}
