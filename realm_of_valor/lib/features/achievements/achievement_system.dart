import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/achievement_model.dart';
import '../../../services/event_bus.dart';
import '../../../core/di.dart';

class AchievementSystem {
  static final List<Achievement> _achievements = [
    // Battle Achievements
    Achievement(
      id: 'first_battle',
      name: 'First Blood',
      description: 'Win your first battle',
      category: AchievementCategory.battle,
      rarity: AchievementRarity.common,
      icon: '⚔️',
      points: 10,
      requirements: {'battles_won': 1},
    ),
    Achievement(
      id: 'battle_master',
      name: 'Battle Master',
      description: 'Win 100 battles',
      category: AchievementCategory.battle,
      rarity: AchievementRarity.epic,
      icon: '🏆',
      points: 100,
      requirements: {'battles_won': 100},
    ),
    Achievement(
      id: 'perfect_victory',
      name: 'Perfect Victory',
      description: 'Win a battle without taking damage',
      category: AchievementCategory.battle,
      rarity: AchievementRarity.rare,
      icon: '✨',
      points: 50,
      requirements: {'perfect_battles': 1},
    ),

    // Quest Achievements
    Achievement(
      id: 'quest_starter',
      name: 'Quest Starter',
      description: 'Complete your first quest',
      category: AchievementCategory.quest,
      rarity: AchievementRarity.common,
      icon: '📜',
      points: 10,
      requirements: {'quests_completed': 1},
    ),
    Achievement(
      id: 'quest_master',
      name: 'Quest Master',
      description: 'Complete 50 quests',
      category: AchievementCategory.quest,
      rarity: AchievementRarity.rare,
      icon: '👑',
      points: 75,
      requirements: {'quests_completed': 50},
    ),
    Achievement(
      id: 'speed_runner',
      name: 'Speed Runner',
      description: 'Complete 5 quests in one day',
      category: AchievementCategory.quest,
      rarity: AchievementRarity.epic,
      icon: '⚡',
      points: 100,
      requirements: {'quests_in_day': 5},
    ),

    // Card Achievements
    Achievement(
      id: 'card_collector',
      name: 'Card Collector',
      description: 'Collect 50 unique cards',
      category: AchievementCategory.collection,
      rarity: AchievementRarity.rare,
      icon: '🃏',
      points: 75,
      requirements: {'unique_cards': 50},
    ),
    Achievement(
      id: 'legendary_finder',
      name: 'Legendary Finder',
      description: 'Find your first legendary card',
      category: AchievementCategory.collection,
      rarity: AchievementRarity.epic,
      icon: '🌟',
      points: 100,
      requirements: {'legendary_cards': 1},
    ),
    Achievement(
      id: 'complete_set',
      name: 'Complete Set',
      description: 'Collect all cards from a set',
      category: AchievementCategory.collection,
      rarity: AchievementRarity.legendary,
      icon: '📚',
      points: 200,
      requirements: {'complete_sets': 1},
    ),

    // Fitness Achievements
    Achievement(
      id: 'fitness_starter',
      name: 'Fitness Starter',
      description: 'Track your first workout',
      category: AchievementCategory.fitness,
      rarity: AchievementRarity.common,
      icon: '💪',
      points: 10,
      requirements: {'workouts_tracked': 1},
    ),
    Achievement(
      id: 'marathon_runner',
      name: 'Marathon Runner',
      description: 'Run 10km in a single session',
      category: AchievementCategory.fitness,
      rarity: AchievementRarity.rare,
      icon: '🏃',
      points: 75,
      requirements: {'distance_10km': 1},
    ),
    Achievement(
      id: 'fitness_master',
      name: 'Fitness Master',
      description: 'Track 100 workouts',
      category: AchievementCategory.fitness,
      rarity: AchievementRarity.epic,
      icon: '🏋️',
      points: 150,
      requirements: {'workouts_tracked': 100},
    ),

    // Social Achievements
    Achievement(
      id: 'social_butterfly',
      name: 'Social Butterfly',
      description: 'Add 10 friends',
      category: AchievementCategory.social,
      rarity: AchievementRarity.rare,
      icon: '🦋',
      points: 50,
      requirements: {'friends_added': 10},
    ),
    Achievement(
      id: 'guild_leader',
      name: 'Guild Leader',
      description: 'Create a guild',
      category: AchievementCategory.social,
      rarity: AchievementRarity.epic,
      icon: '👑',
      points: 100,
      requirements: {'guilds_created': 1},
    ),
    Achievement(
      id: 'popular_post',
      name: 'Popular Post',
      description: 'Get 100 likes on a single post',
      category: AchievementCategory.social,
      rarity: AchievementRarity.rare,
      icon: '🔥',
      points: 75,
      requirements: {'post_likes': 100},
    ),

    // Exploration Achievements
    Achievement(
      id: 'explorer',
      name: 'Explorer',
      description: 'Visit 10 different locations',
      category: AchievementCategory.exploration,
      rarity: AchievementRarity.rare,
      icon: '🗺️',
      points: 50,
      requirements: {'locations_visited': 10},
    ),
    Achievement(
      id: 'world_traveler',
      name: 'World Traveler',
      description: 'Visit 50 different locations',
      category: AchievementCategory.exploration,
      rarity: AchievementRarity.epic,
      icon: '🌍',
      points: 150,
      requirements: {'locations_visited': 50},
    ),

    // Special Achievements
    Achievement(
      id: 'early_adopter',
      name: 'Early Adopter',
      description: 'Join during the beta phase',
      category: AchievementCategory.special,
      rarity: AchievementRarity.legendary,
      icon: '🚀',
      points: 500,
      requirements: {'beta_user': 1},
    ),
    Achievement(
      id: 'perfect_day',
      name: 'Perfect Day',
      description: 'Complete all daily goals in one day',
      category: AchievementCategory.special,
      rarity: AchievementRarity.epic,
      icon: '⭐',
      points: 200,
      requirements: {'perfect_days': 1},
    ),
  ];

  static List<Achievement> get allAchievements => _achievements;

  static List<Achievement> getByCategory(AchievementCategory category) {
    return _achievements.where((a) => a.category == category).toList();
  }

  static List<Achievement> getByRarity(AchievementRarity rarity) {
    return _achievements.where((a) => a.rarity == rarity).toList();
  }

  static Achievement? getById(String id) {
    try {
      return _achievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  static void checkAchievements(Map<String, int> stats, EventBus eventBus) {
    for (final achievement in _achievements) {
      if (!achievement.isUnlocked) {
        bool shouldUnlock = true;
        
        for (final requirement in achievement.requirements.entries) {
          final currentValue = stats[requirement.key] ?? 0;
          if (currentValue < requirement.value) {
            shouldUnlock = false;
            break;
          }
        }
        
        if (shouldUnlock) {
          achievement.unlock();
          eventBus.publish(Event(
            type: 'achievement.unlocked',
            data: {
              'achievement_id': achievement.id,
              'achievement_name': achievement.name,
              'points': achievement.points,
            },
          ));
        }
      }
    }
  }
}

// Achievement Provider
final achievementsProvider = Provider<List<Achievement>>((ref) {
  return AchievementSystem.allAchievements;
});

final unlockedAchievementsProvider = Provider<List<Achievement>>((ref) {
  final achievements = ref.watch(achievementsProvider);
  return achievements.where((a) => a.isUnlocked).toList();
});

final achievementPointsProvider = Provider<int>((ref) {
  final unlocked = ref.watch(unlockedAchievementsProvider);
  return unlocked.fold(0, (sum, achievement) => sum + achievement.points);
});

final achievementProgressProvider = Provider<Map<String, double>>((ref) {
  final achievements = ref.watch(achievementsProvider);
  final progress = <String, double>{};
  
  for (final achievement in achievements) {
    if (achievement.isUnlocked) {
      progress[achievement.id] = 1.0;
    } else {
      // Calculate progress based on requirements
      double minProgress = 1.0;
      for (final requirement in achievement.requirements.entries) {
        // This would need to be connected to actual game stats
        final currentValue = 0; // Get from game stats
        final requiredValue = requirement.value;
        final requirementProgress = currentValue / requiredValue;
        if (requirementProgress < minProgress) {
          minProgress = requirementProgress;
        }
      }
      progress[achievement.id] = minProgress.clamp(0.0, 1.0);
    }
  }
  
  return progress;
});
