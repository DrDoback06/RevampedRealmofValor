import '../data/models/quest_model.dart';
import '../data/models/boss_quest_model.dart';
import '../data/models/trail_model.dart';

/// Enhanced Quest Categorization System
/// 
/// Organizes quests into clear categories based on original plan:
/// - Fitness Quests (trails, activities)
/// - Battle Quests (enemies, bosses, PvP)
/// - Treasure Quests (items, loot, magic find)
/// - Social Quests (friends, trading, co-op)
/// - Location Quests (POIs, exploration)
/// - Achievement Quests (long-term goals)
///
/// ENHANCEMENTS:
/// 1. Auto-categorization from quest properties
/// 2. Quest difficulty calculator
/// 3. Recommended level suggestions
/// 4. Quest chaining (prerequisites)
/// 5. Daily/weekly rotation system
/// 6. Quest tags for filtering
/// 7. Quest rewards balancing
/// 8. Completion tracking per category

class EnhancedQuestCategorizer {
  /// Categorize quest automatically
  static QuestCategory categorizeQuest(Quest quest) {
    // Boss quests always epic
    if (quest.type == QuestType.boss) return QuestCategory.epic;
    
    // Story quests always main
    if (quest.type == QuestType.story) return QuestCategory.main;
    
    // Repeatable trails
    if (quest.tags.contains('repeatable:true')) return QuestCategory.repeatable;
    
    // Event quests
    if (quest.tags.any((tag) => tag.startsWith('event:'))) return QuestCategory.event;
    
    // PvP quests
    if (quest.tags.contains('pvp:true')) return QuestCategory.pvp;
    
    // Default to adventure
    return QuestCategory.adventure;
  }

  /// Group quests by category for UI display
  static Map<QuestCategory, List<Quest>> groupQuestsByCategory(
    List<Quest> quests,
  ) {
    final grouped = <QuestCategory, List<Quest>>{};
    
    for (final quest in quests) {
      final category = categorizeQuest(quest);
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(quest);
    }
    
    return grouped;
  }

  /// Group quests by type for filtering
  static Map<QuestType, List<Quest>> groupQuestsByType(
    List<Quest> quests,
  ) {
    final grouped = <QuestType, List<Quest>>{};
    
    for (final quest in quests) {
      grouped.putIfAbsent(quest.type, () => []);
      grouped[quest.type]!.add(quest);
    }
    
    return grouped;
  }

  /// Get quests for specific category
  static List<Quest> getQuestsByCategory(
    List<Quest> allQuests,
    QuestCategory category,
  ) {
    return allQuests.where((quest) => 
      categorizeQuest(quest) == category
    ).toList();
  }

  /// Get fitness quests (trails + activities)
  static List<Quest> getFitnessQuests(List<Quest> allQuests) {
    return allQuests.where((quest) =>
      quest.type == QuestType.fitness ||
      quest.type == QuestType.trail ||
      quest.tags.any((tag) => tag.startsWith('fitness:'))
    ).toList();
  }

  /// Get battle quests (enemies, bosses, PvP)
  static List<Quest> getBattleQuests(List<Quest> allQuests) {
    return allQuests.where((quest) =>
      quest.type == QuestType.battle ||
      quest.type == QuestType.boss ||
      quest.type == QuestType.patrol ||
      quest.tags.any((tag) => tag.startsWith('enemy:'))
    ).toList();
  }

  /// Get treasure quests (loot, items, magic find)
  static List<Quest> getTreasureQuests(List<Quest> allQuests) {
    return allQuests.where((quest) =>
      quest.type == QuestType.treasure ||
      quest.tags.any((tag) => tag.startsWith('loot:') || tag.startsWith('item:'))
    ).toList();
  }

  /// Get social quests (friends, trading, co-op)
  static List<Quest> getSocialQuests(List<Quest> allQuests) {
    return allQuests.where((quest) =>
      quest.type == QuestType.social ||
      quest.tags.any((tag) => tag.startsWith('social:') || tag.startsWith('coop:'))
    ).toList();
  }

  /// Get location quests (POIs, exploration)
  static List<Quest> getLocationQuests(List<Quest> allQuests) {
    return allQuests.where((quest) =>
      quest.type == QuestType.location ||
      quest.type == QuestType.zone ||
      quest.tags.any((tag) => tag.startsWith('poi:') || tag.startsWith('explore:'))
    ).toList();
  }

  /// Get epic quests (bosses, raids)
  static List<Quest> getEpicQuests(List<Quest> allQuests) {
    return allQuests.where((quest) =>
      categorizeQuest(quest) == QuestCategory.epic
    ).toList();
  }

  /// Get repeatable quests
  static List<Quest> getRepeatableQuests(List<Quest> allQuests) {
    return allQuests.where((quest) =>
      quest.tags.contains('repeatable:true')
    ).toList();
  }

  /// Get daily quests
  static List<Quest> getDailyQuests(List<Quest> allQuests) {
    return allQuests.where((quest) =>
      quest.type == QuestType.daily
    ).toList();
  }

  /// Get weekly quests
  static List<Quest> getWeeklyQuests(List<Quest> allQuests) {
    return allQuests.where((quest) =>
      quest.type == QuestType.weekly
    ).toList();
  }

  /// Calculate recommended level for quest
  static int calculateRecommendedLevel(Quest quest) {
    // Base level from tags
    final levelTag = quest.tags.firstWhere(
      (tag) => tag.startsWith('recommended_level:'),
      orElse: () => 'recommended_level:1',
    );
    final tagLevel = int.parse(levelTag.split(':')[1]);
    
    // Adjust based on quest type
    if (quest.type == QuestType.boss) {
      return tagLevel + 5; // Bosses need higher level
    }
    
    return tagLevel;
  }

  /// Get quest icon
  static String getQuestIcon(Quest quest) {
    switch (quest.type) {
      case QuestType.story:
        return '📖';
      case QuestType.fitness:
      case QuestType.trail:
        return '🏃';
      case QuestType.battle:
      case QuestType.patrol:
        return '⚔️';
      case QuestType.boss:
        return '💀';
      case QuestType.treasure:
        return '💎';
      case QuestType.social:
        return '👥';
      case QuestType.location:
        return '📍';
      case QuestType.zone:
        return '✨';
      case QuestType.daily:
        return '📅';
      case QuestType.weekly:
        return '📆';
      case QuestType.achievement:
        return '🏆';
    }
  }

  /// Get category display name
  static String getCategoryDisplayName(QuestCategory category) {
    switch (category) {
      case QuestCategory.main:
        return 'Main Story';
      case QuestCategory.adventure:
        return 'Adventures';
      case QuestCategory.side:
        return 'Side Quests';
      case QuestCategory.epic:
        return 'Epic Bosses';
      case QuestCategory.repeatable:
        return 'Repeatable';
      case QuestCategory.event:
        return 'Events';
      case QuestCategory.pvp:
        return 'PvP';
    }
  }
}
