import '../data/models/character_model.dart';
import '../data/models/quest_model.dart';
import '../data/models/card_model.dart';
import 'stat_calculator.dart';

/// Result of applying quest rewards to a character
class ProgressionResult {
  final Character updatedCharacter;
  final bool leveledUp;
  final int levelsGained;
  final int goldGained;
  final List<String> cardsGained;
  final CharacterStats? oldStats;
  final CharacterStats? newStats;

  const ProgressionResult({
    required this.updatedCharacter,
    required this.leveledUp,
    required this.levelsGained,
    required this.goldGained,
    required this.cardsGained,
    this.oldStats,
    this.newStats,
  });
}

/// Utility class for managing character progression and leveling
class CharacterProgression {
  /// Calculate XP rewards based on quest rarity
  static int calculateQuestXP(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return 50;
      case CardRarity.uncommon:
        return 100;
      case CardRarity.rare:
        return 150;
      case CardRarity.epic:
        return 300;
      case CardRarity.legendary:
        return 500;
      case CardRarity.mythic:
        return 1000;
    }
  }

  /// Calculate gold rewards based on quest rarity
  static int calculateQuestGold(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return 25;
      case CardRarity.uncommon:
        return 50;
      case CardRarity.rare:
        return 100;
      case CardRarity.epic:
        return 200;
      case CardRarity.legendary:
        return 400;
      case CardRarity.mythic:
        return 800;
    }
  }

  /// Apply quest completion rewards to a character
  /// Returns updated character and progression details
  static ProgressionResult applyQuestRewards({
    required Character character,
    required Quest quest,
    CardRarity? overrideRarity,
  }) {
    // Determine quest rarity (default to common if not specified)
    final rarity = overrideRarity ?? CardRarity.common;

    // Calculate rewards
    final xpGained = quest.rewards.xp > 0 
        ? quest.rewards.xp 
        : calculateQuestXP(rarity);
    final goldGained = quest.rewards.gold > 0 
        ? quest.rewards.gold 
        : calculateQuestGold(rarity);
    final cardsGained = quest.rewards.items;

    // Apply XP and handle level ups
    var currentXp = character.xp + xpGained;
    var currentLevel = character.level;
    var currentStats = character.stats;
    var skillPoints = character.skillPoints;
    
    final oldStats = currentStats;
    int levelsGained = 0;

    // Check for level ups
    while (currentXp >= StatCalculator.xpForNextLevel(currentLevel)) {
      currentXp -= StatCalculator.xpForNextLevel(currentLevel);
      currentLevel++;
      levelsGained++;
      skillPoints++;

      // Calculate new stats based on class (use character name as proxy for class)
      currentStats = StatCalculator.calculateLevelUpStats(
        currentStats: currentStats,
        characterClass: _inferClass(character.name),
      );
    }

    // Create updated character
    final updatedCharacter = Character(
      uid: character.uid,
      id: character.id,
      name: character.name,
      level: currentLevel,
      xp: currentXp,
      stats: currentStats,
      equipment: character.equipment,
      skillPoints: skillPoints,
      unlockedSkills: character.unlockedSkills,
    );

    return ProgressionResult(
      updatedCharacter: updatedCharacter,
      leveledUp: levelsGained > 0,
      levelsGained: levelsGained,
      goldGained: goldGained,
      cardsGained: cardsGained,
      oldStats: oldStats,
      newStats: levelsGained > 0 ? currentStats : null,
    );
  }

  /// Apply XP directly to a character (e.g., from fitness or battle)
  static ProgressionResult applyXP({
    required Character character,
    required int xp,
  }) {
    var currentXp = character.xp + xp;
    var currentLevel = character.level;
    var currentStats = character.stats;
    var skillPoints = character.skillPoints;
    
    final oldStats = currentStats;
    int levelsGained = 0;

    // Check for level ups
    while (currentXp >= StatCalculator.xpForNextLevel(currentLevel)) {
      currentXp -= StatCalculator.xpForNextLevel(currentLevel);
      currentLevel++;
      levelsGained++;
      skillPoints++;

      currentStats = StatCalculator.calculateLevelUpStats(
        currentStats: currentStats,
        characterClass: _inferClass(character.name),
      );
    }

    final updatedCharacter = Character(
      uid: character.uid,
      id: character.id,
      name: character.name,
      level: currentLevel,
      xp: currentXp,
      stats: currentStats,
      equipment: character.equipment,
      skillPoints: skillPoints,
      unlockedSkills: character.unlockedSkills,
    );

    return ProgressionResult(
      updatedCharacter: updatedCharacter,
      leveledUp: levelsGained > 0,
      levelsGained: levelsGained,
      goldGained: 0,
      cardsGained: [],
      oldStats: oldStats,
      newStats: levelsGained > 0 ? currentStats : null,
    );
  }

  /// Infer character class from name (simple heuristic)
  /// In a real implementation, this would be a proper field on Character
  static String _inferClass(String characterName) {
    final name = characterName.toLowerCase();
    
    if (name.contains('warrior') || name.contains('knight') || name.contains('fighter')) {
      return 'warrior';
    } else if (name.contains('mage') || name.contains('wizard') || name.contains('sorcerer')) {
      return 'mage';
    } else if (name.contains('rogue') || name.contains('assassin') || name.contains('thief')) {
      return 'rogue';
    } else if (name.contains('cleric') || name.contains('priest') || name.contains('healer')) {
      return 'cleric';
    } else if (name.contains('ranger') || name.contains('archer') || name.contains('hunter')) {
      return 'ranger';
    }
    
    return 'balanced'; // Default class with balanced stat growth
  }

  /// Get progress towards next level as a percentage (0.0 to 1.0)
  static double getLevelProgress(Character character) {
    final xpNeeded = StatCalculator.xpForNextLevel(character.level);
    return character.xp / xpNeeded;
  }

  /// Get XP remaining until next level
  static int getXPToNextLevel(Character character) {
    final xpNeeded = StatCalculator.xpForNextLevel(character.level);
    return (xpNeeded - character.xp).clamp(0, xpNeeded);
  }

  /// Generate stat comparison text for level up
  static String generateStatComparisonText(CharacterStats oldStats, CharacterStats newStats) {
    final strDiff = newStats.strength - oldStats.strength;
    final agiDiff = newStats.agility - oldStats.agility;
    final intDiff = newStats.intelligence - oldStats.intelligence;
    final vitDiff = newStats.vitality - oldStats.vitality;

    final changes = <String>[];
    if (strDiff > 0) changes.add('STR +$strDiff');
    if (agiDiff > 0) changes.add('AGI +$agiDiff');
    if (intDiff > 0) changes.add('INT +$intDiff');
    if (vitDiff > 0) changes.add('VIT +$vitDiff');

    return changes.join(', ');
  }
}
