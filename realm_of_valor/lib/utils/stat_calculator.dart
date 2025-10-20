import '../data/models/character_model.dart';
import '../data/models/card_model.dart';
import '../data/models/inventory_model.dart';

/// Computed stats derived from base stats and equipment
class ComputedStats {
  final int strength;
  final int agility;
  final int intelligence;
  final int vitality;
  final int attack;
  final int defense;
  final int hp;
  final int maxHp;
  final int mana;
  final int maxMana;
  final double critChance;
  final double critDamage;
  final double evasion;
  final double accuracy;
  
  const ComputedStats({
    required this.strength,
    required this.agility,
    required this.intelligence,
    required this.vitality,
    required this.attack,
    required this.defense,
    required this.hp,
    required this.maxHp,
    required this.mana,
    required this.maxMana,
    this.critChance = 0.05,
    this.critDamage = 1.5,
    this.evasion = 0.0,
    this.accuracy = 1.0,
  });

  ComputedStats copyWith({
    int? strength,
    int? agility,
    int? intelligence,
    int? vitality,
    int? attack,
    int? defense,
    int? hp,
    int? maxHp,
    int? mana,
    int? maxMana,
    double? critChance,
    double? critDamage,
    double? evasion,
    double? accuracy,
  }) {
    return ComputedStats(
      strength: strength ?? this.strength,
      agility: agility ?? this.agility,
      intelligence: intelligence ?? this.intelligence,
      vitality: vitality ?? this.vitality,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      mana: mana ?? this.mana,
      maxMana: maxMana ?? this.maxMana,
      critChance: critChance ?? this.critChance,
      critDamage: critDamage ?? this.critDamage,
      evasion: evasion ?? this.evasion,
      accuracy: accuracy ?? this.accuracy,
    );
  }
}

/// Utility class for calculating character stats including equipment bonuses
class StatCalculator {
  /// Calculate comprehensive stats for a character including equipment bonuses
  static ComputedStats calculateCharacterStats({
    required Character character,
    required Inventory inventory,
    Map<String, GameCard>? cardDatabase,
  }) {
    // Start with base stats
    var str = character.stats.strength;
    var agi = character.stats.agility;
    var int_ = character.stats.intelligence;
    var vit = character.stats.vitality;

    // Aggregate equipment bonuses
    final equipmentStats = _aggregateEquipmentStats(
      character: character,
      inventory: inventory,
      cardDatabase: cardDatabase,
    );

    // Apply equipment bonuses to base stats
    str += equipmentStats['str']?.toInt() ?? 0;
    agi += equipmentStats['agi']?.toInt() ?? 0;
    int_ += equipmentStats['int']?.toInt() ?? 0;
    vit += equipmentStats['vit']?.toInt() ?? 0;

    // Calculate derived combat stats
    // Attack: Strength * 2 + equipment ATK bonuses
    final atk = str * 2 + (equipmentStats['atk']?.toInt() ?? 0);
    
    // Defense: (Vitality + Agility) + equipment DEF bonuses
    final def = (vit + agi) + (equipmentStats['def']?.toInt() ?? 0);
    
    // HP: Vitality * 20 + equipment HP bonuses
    final maxHp = vit * 20 + (equipmentStats['hp']?.toInt() ?? 0);
    
    // Mana: Intelligence * 10 + equipment Mana bonuses
    final maxMana = int_ * 10 + (equipmentStats['mana']?.toInt() ?? 0);

    // Advanced stats
    // Crit chance: Base 5% + (Agility / 100) + equipment bonuses
    final critChance = 0.05 + (agi / 100.0) + (equipmentStats['crit_chance']?.toDouble() ?? 0.0);
    
    // Crit damage: Base 150% + equipment bonuses
    final critDamage = 1.5 + (equipmentStats['crit_damage']?.toDouble() ?? 0.0);
    
    // Evasion: (Agility / 200) + equipment bonuses
    final evasion = (agi / 200.0) + (equipmentStats['evasion']?.toDouble() ?? 0.0);
    
    // Accuracy: Base 100% + equipment bonuses
    final accuracy = 1.0 + (equipmentStats['accuracy']?.toDouble() ?? 0.0);

    return ComputedStats(
      strength: str,
      agility: agi,
      intelligence: int_,
      vitality: vit,
      attack: atk,
      defense: def,
      hp: maxHp, // Start at max HP
      maxHp: maxHp,
      mana: maxMana, // Start at max mana
      maxMana: maxMana,
      critChance: critChance.clamp(0.0, 1.0),
      critDamage: critDamage.clamp(1.0, 5.0),
      evasion: evasion.clamp(0.0, 0.8), // Max 80% evasion
      accuracy: accuracy.clamp(0.5, 2.0), // 50% to 200% accuracy
    );
  }

  /// Aggregate stats from all equipped items
  static Map<String, num> _aggregateEquipmentStats({
    required Character character,
    required Inventory inventory,
    Map<String, GameCard>? cardDatabase,
  }) {
    final stats = <String, num>{};
    
    // Map equipment slots to instance IDs
    final slotToInstance = <String, String?>{
      'head': character.equipment.head,
      'chest': character.equipment.chest,
      'legs': character.equipment.legs,
      'weapon': character.equipment.weapon,
      'offhand': character.equipment.offhand,
      'ring': character.equipment.ring,
      'amulet': character.equipment.amulet,
    };

    // Iterate through equipped items
    for (final slot in slotToInstance.entries) {
      final instanceId = slot.value;
      if (instanceId == null) continue;

      // Find the card instance in inventory
      final cardInstance = inventory.items.firstWhere(
        (item) => item.instanceId == instanceId,
        orElse: () => CardInstance(instanceId: '', cardId: ''),
      );

      if (cardInstance.instanceId.isEmpty) continue;

      // Add stats from card instance upgrades
      if (cardInstance.upgrades != null) {
        for (final entry in cardInstance.upgrades!.entries) {
          stats.update(
            entry.key,
            (value) => value + entry.value,
            ifAbsent: () => entry.value,
          );
        }
      }

      // If card database is provided, also add base card stats
      if (cardDatabase != null) {
        final card = cardDatabase[cardInstance.cardId];
        if (card != null && card.stats != null) {
          _addCardStats(stats, card);
        }
      }
    }

    return stats;
  }

  /// Add stats from a game card to the aggregate stats map
  static void _addCardStats(Map<String, num> stats, GameCard card) {
    if (card.stats == null) return;

    for (final entry in card.stats!.entries) {
      final value = entry.value;
      if (value is num) {
        // Apply card level scaling (10% per level above 1)
        final scaledValue = value * (1.0 + (card.level - 1) * 0.1);
        stats.update(
          entry.key,
          (existingValue) => existingValue + scaledValue,
          ifAbsent: () => scaledValue,
        );
      }
    }
  }

  /// Calculate XP required for next level
  static int xpForNextLevel(int currentLevel) {
    // Exponential curve: 100, 250, 500, 1000, 2000, 3500, 5500, 8000, ...
    if (currentLevel == 1) return 100;
    if (currentLevel == 2) return 250;
    if (currentLevel == 3) return 500;
    return 100 + (currentLevel - 1) * 50 + ((currentLevel - 1) * (currentLevel - 1)) * 25;
  }

  /// Calculate stat increases on level up based on character class
  /// Returns a map of stat increases
  static CharacterStats calculateLevelUpStats({
    required CharacterStats currentStats,
    required String characterClass,
  }) {
    // Base stat increases per level
    int strIncrease = 1;
    int agiIncrease = 1;
    int intIncrease = 1;
    int vitIncrease = 2; // Everyone gets +2 HP worth of vitality

    // Class-specific bonuses
    switch (characterClass.toLowerCase()) {
      case 'warrior':
      case 'knight':
      case 'paladin':
        strIncrease += 2; // +3 STR total
        vitIncrease += 1; // +3 VIT total
        break;
      case 'rogue':
      case 'assassin':
      case 'ranger':
        agiIncrease += 2; // +3 AGI total
        strIncrease += 1; // +2 STR total
        break;
      case 'mage':
      case 'wizard':
      case 'sorcerer':
        intIncrease += 3; // +4 INT total
        break;
      case 'cleric':
      case 'priest':
      case 'healer':
        intIncrease += 2; // +3 INT total
        vitIncrease += 1; // +3 VIT total
        break;
      default:
        // Balanced growth for unknown classes
        strIncrease += 1;
        agiIncrease += 1;
        intIncrease += 1;
        break;
    }

    return CharacterStats(
      strength: currentStats.strength + strIncrease,
      agility: currentStats.agility + agiIncrease,
      intelligence: currentStats.intelligence + intIncrease,
      vitality: currentStats.vitality + vitIncrease,
    );
  }

  /// Calculate damage dealt in battle with crits and evasion
  static int calculateBattleDamage({
    required ComputedStats attacker,
    required ComputedStats defender,
    bool allowCrit = true,
    bool allowEvasion = true,
  }) {
    // Check for evasion first
    if (allowEvasion) {
      final hitChance = attacker.accuracy * (1.0 - defender.evasion);
      final random = DateTime.now().microsecond / 1000000.0;
      if (random > hitChance) {
        return 0; // Miss!
      }
    }

    // Base damage: ATK - DEF (minimum 1)
    var damage = (attacker.attack - defender.defense).clamp(1, 9999);

    // Check for critical hit
    if (allowCrit) {
      final random = DateTime.now().microsecond / 1000000.0;
      if (random < attacker.critChance) {
        damage = (damage * attacker.critDamage).round();
      }
    }

    return damage;
  }
}
