import '../data/models/quest_model.dart';
import '../data/models/trail_model.dart';
import 'dart:math';

/// Repeatable Quest System
/// 
/// ENHANCEMENTS:
/// 1. Quests can be completed multiple times
/// 2. Rewards scale with each completion (diminishing returns)
/// 3. Completion history tracked per quest
/// 4. Daily/weekly quest limits
/// 5. Bonus rewards for streaks
/// 6. Special rewards for milestones (10th, 50th, 100th completion)
/// 7. Leaderboards for most completions
/// 8. Quest cooldown periods

class RepeatableQuestService {
  // Track quest completions: questId -> [completion timestamps]
  final Map<String, List<DateTime>> _completionHistory = {};
  
  // Quest cooldown periods (in hours)
  static const Map<String, int> _cooldownHours = {
    'trail': 24,      // Can repeat trail once per day
    'battle': 6,      // Can repeat battle every 6 hours
    'treasure': 12,   // Can repeat treasure hunt every 12 hours
    'location': 4,    // Can repeat location visit every 4 hours
  };
  
  /// Check if quest can be repeated
  bool canRepeatQuest(String questId, String questType) {
    final completions = _completionHistory[questId];
    if (completions == null || completions.isEmpty) {
      return true; // Never completed, can start
    }
    
    final lastCompletion = completions.last;
    final cooldownHours = _cooldownHours[questType] ?? 24;
    final cooldownEnd = lastCompletion.add(Duration(hours: cooldownHours));
    
    return DateTime.now().isAfter(cooldownEnd);
  }
  
  /// Get time remaining until quest can be repeated
  Duration? getTimeUntilRepeat(String questId, String questType) {
    if (canRepeatQuest(questId, questType)) return null;
    
    final lastCompletion = _completionHistory[questId]!.last;
    final cooldownHours = _cooldownHours[questType] ?? 24;
    final cooldownEnd = lastCompletion.add(Duration(hours: cooldownHours));
    
    return cooldownEnd.difference(DateTime.now());
  }
  
  /// Get completion count for quest
  int getCompletionCount(String questId) {
    return _completionHistory[questId]?.length ?? 0;
  }
  
  /// Record quest completion
  void recordCompletion(String questId) {
    _completionHistory.putIfAbsent(questId, () => []);
    _completionHistory[questId]!.add(DateTime.now());
  }
  
  /// Calculate scaled rewards for repeat completion
  QuestRewards calculateScaledRewards({
    required Quest originalQuest,
    required int completionNumber,
  }) {
    // Base rewards
    final baseXp = originalQuest.rewards.xp;
    final baseGold = originalQuest.rewards.gold;
    final baseItems = originalQuest.rewards.items;
    
    // Scaling formula: diminishing returns after first completion
    // 1st: 100%, 2nd: 75%, 3rd: 60%, 4th+: 50%
    double multiplier;
    if (completionNumber == 1) {
      multiplier = 1.0;  // First time: full rewards
    } else if (completionNumber == 2) {
      multiplier = 0.75; // Second time: 75%
    } else if (completionNumber == 3) {
      multiplier = 0.60; // Third time: 60%
    } else {
      multiplier = 0.50; // 4th+: 50%
    }
    
    // Check for milestone bonuses
    final milestoneBonus = _getMilestoneBonus(completionNumber);
    multiplier += milestoneBonus;
    
    // Check for streak bonus (completing same quest multiple days in a row)
    final streakBonus = _getStreakBonus(originalQuest.id);
    multiplier += streakBonus;
    
    return QuestRewards(
      xp: (baseXp * multiplier).round(),
      gold: (baseGold * multiplier).round(),
      gems: originalQuest.rewards.gems,
      items: completionNumber <= 5 ? baseItems : [], // Only give items for first 5 completions
    );
  }
  
  /// Get bonus for milestone completions
  double _getMilestoneBonus(int completionNumber) {
    if (completionNumber == 10) return 0.5;   // 10th completion: +50%
    if (completionNumber == 25) return 0.75;  // 25th: +75%
    if (completionNumber == 50) return 1.0;   // 50th: +100%
    if (completionNumber == 100) return 2.0;  // 100th: +200%
    return 0.0;
  }
  
  /// Get streak bonus
  double _getStreakBonus(String questId) {
    final completions = _completionHistory[questId];
    if (completions == null || completions.length < 2) return 0.0;
    
    // Check if last N completions were on consecutive days
    int streakDays = 1;
    for (int i = completions.length - 1; i > 0; i--) {
      final current = DateTime(
        completions[i].year,
        completions[i].month,
        completions[i].day,
      );
      final previous = DateTime(
        completions[i-1].year,
        completions[i-1].month,
        completions[i-1].day,
      );
      
      if (current.difference(previous).inDays == 1) {
        streakDays++;
      } else {
        break;
      }
    }
    
    // Streak bonus: +5% per consecutive day, max +50%
    return min((streakDays - 1) * 0.05, 0.5);
  }
  
  /// Get all completions for a quest
  List<DateTime> getCompletionHistory(String questId) {
    return _completionHistory[questId] ?? [];
  }
  
  /// Get completion stats
  Map<String, dynamic> getCompletionStats(String questId) {
    final completions = _completionHistory[questId] ?? [];
    
    if (completions.isEmpty) {
      return {
        'total_completions': 0,
        'first_completed': null,
        'last_completed': null,
        'current_streak': 0,
        'best_streak': 0,
      };
    }
    
    return {
      'total_completions': completions.length,
      'first_completed': completions.first,
      'last_completed': completions.last,
      'current_streak': _getCurrentStreak(completions),
      'best_streak': _getBestStreak(completions),
    };
  }
  
  /// Calculate current streak
  int _getCurrentStreak(List<DateTime> completions) {
    if (completions.isEmpty) return 0;
    
    int streak = 1;
    for (int i = completions.length - 1; i > 0; i--) {
      final current = DateTime(
        completions[i].year,
        completions[i].month,
        completions[i].day,
      );
      final previous = DateTime(
        completions[i-1].year,
        completions[i-1].month,
        completions[i-1].day,
      );
      
      if (current.difference(previous).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
  
  /// Calculate best streak
  int _getBestStreak(List<DateTime> completions) {
    if (completions.isEmpty) return 0;
    
    int bestStreak = 1;
    int currentStreak = 1;
    
    for (int i = 1; i < completions.length; i++) {
      final current = DateTime(
        completions[i].year,
        completions[i].month,
        completions[i].day,
      );
      final previous = DateTime(
        completions[i-1].year,
        completions[i-1].month,
        completions[i-1].day,
      );
      
      if (current.difference(previous).inDays == 1) {
        currentStreak++;
        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
      }
    }
    
    return bestStreak;
  }
  
  /// Create a repeatable quest from a trail
  Quest createRepeatableTrailQuest({
    required Trail trail,
    int completionNumber = 1,
  }) {
    final baseQuest = Quest(
      id: 'trail_${trail.id}',
      title: 'Complete ${trail.name}',
      type: QuestType.fitness,
      category: QuestCategory.adventure,
      status: QuestStatus.notStarted,
      description: trail.description,
      objectives: [
        QuestObjective(
          id: 'complete_trail',
          description: 'Complete the trail route',
          target: 1,
          progress: 0,
          type: 'trail',
        ),
      ],
      rewards: QuestRewards(
        xp: _calculateTrailXP(trail),
        gold: _calculateTrailGold(trail),
        items: _getTrailRewardCards(trail, completionNumber),
      ),
      location: QuestLocation(
        latitude: trail.startLocation.latitude,
        longitude: trail.startLocation.longitude,
        radius: 50.0,
      ),
      tags: [
        'trail_id:${trail.id}',
        'trail_difficulty:${trail.difficulty.name}',
        'repeatable:true',
        'completion_number:$completionNumber',
      ],
    );
    
    // Scale rewards if this is a repeat
    if (completionNumber > 1) {
      final scaledRewards = calculateScaledRewards(
        originalQuest: baseQuest,
        completionNumber: completionNumber,
      );
      
      return baseQuest.copyWith(rewards: scaledRewards);
    }
    
    return baseQuest;
  }
  
  /// Calculate XP reward for trail
  int _calculateTrailXP(Trail trail) {
    final distanceXP = (trail.distance / 1000 * 10).toInt();
    final elevationXP = (trail.elevationGain / 10).toInt();
    final difficultyMultiplier = _getDifficultyMultiplier(trail.difficulty);
    
    return ((distanceXP + elevationXP) * difficultyMultiplier).toInt();
  }
  
  /// Calculate gold reward for trail
  int _calculateTrailGold(Trail trail) {
    final distanceGold = (trail.distance / 500).toInt();
    final elevationGold = (trail.elevationGain / 100).toInt();
    final difficultyMultiplier = _getDifficultyMultiplier(trail.difficulty);
    
    return ((distanceGold + elevationGold) * difficultyMultiplier).toInt().clamp(10, 200);
  }
  
  /// Get difficulty multiplier
  double _getDifficultyMultiplier(TrailDifficulty difficulty) {
    switch (difficulty) {
      case TrailDifficulty.easy:
        return 1.0;
      case TrailDifficulty.moderate:
        return 1.5;
      case TrailDifficulty.hard:
        return 2.0;
      case TrailDifficulty.expert:
        return 3.0;
    }
  }
  
  /// Get reward cards for trail
  List<String> _getTrailRewardCards(Trail trail, int completionNumber) {
    // Only give cards for first few completions
    if (completionNumber > 5) return [];
    
    final cards = <String>[];
    
    switch (trail.difficulty) {
      case TrailDifficulty.easy:
        cards.add('common_fitness_card');
        break;
      case TrailDifficulty.moderate:
        cards.add('uncommon_fitness_card');
        break;
      case TrailDifficulty.hard:
        cards.add('rare_fitness_card');
        break;
      case TrailDifficulty.expert:
        cards.addAll(['epic_fitness_card', 'trail_master_badge']);
        break;
    }
    
    // Bonus card for first completion
    if (completionNumber == 1) {
      cards.add('first_completion_badge_${trail.id}');
    }
    
    return cards;
  }
}

// Extension to add copyWith to Quest
extension QuestCopyWith on Quest {
  Quest copyWith({QuestRewards? rewards}) {
    return Quest(
      id: id,
      title: title,
      type: type,
      category: category,
      status: status,
      description: description,
      objectives: objectives,
      rewards: rewards ?? this.rewards,
      location: location,
      tags: tags,
    );
  }
}
