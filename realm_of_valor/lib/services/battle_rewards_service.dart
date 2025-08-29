import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/battle_models.dart';
import '../data/models/quest_models.dart';

class BattleReward {
  final String id;
  final String name;
  final String description;
  final RewardType type;
  final int baseAmount;
  final double rarity;
  final Map<String, dynamic> properties;
  final String icon;
  final bool isStackable;
  final int maxStack;

  BattleReward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.baseAmount,
    required this.rarity,
    required this.properties,
    required this.icon,
    this.isStackable = true,
    this.maxStack = 99,
  });

  factory BattleReward.fromJson(Map<String, dynamic> json) {
    return BattleReward(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: RewardType.values.firstWhere((e) => e.name == json['type']),
      baseAmount: json['baseAmount'],
      rarity: json['rarity']?.toDouble() ?? 1.0,
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      icon: json['icon'],
      isStackable: json['isStackable'] ?? true,
      maxStack: json['maxStack'] ?? 99,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'baseAmount': baseAmount,
      'rarity': rarity,
      'properties': properties,
      'icon': icon,
      'isStackable': isStackable,
      'maxStack': maxStack,
    };
  }
}

enum RewardType {
  experience,
  gold,
  card,
  item,
  equipment,
  currency,
  material,
  cosmetic,
  title,
  achievement,
}

class LootTable {
  final String id;
  final String name;
  final List<LootEntry> entries;
  final double totalWeight;
  final int minDrops;
  final int maxDrops;
  final bool allowDuplicates;

  LootTable({
    required this.id,
    required this.name,
    required this.entries,
    required this.totalWeight,
    required this.minDrops,
    required this.maxDrops,
    this.allowDuplicates = false,
  });

  factory LootTable.fromJson(Map<String, dynamic> json) {
    return LootTable(
      id: json['id'],
      name: json['name'],
      entries: (json['entries'] as List)
          .map((e) => LootEntry.fromJson(e))
          .toList(),
      totalWeight: json['totalWeight']?.toDouble() ?? 0.0,
      minDrops: json['minDrops'] ?? 1,
      maxDrops: json['maxDrops'] ?? 3,
      allowDuplicates: json['allowDuplicates'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'entries': entries.map((e) => e.toJson()).toList(),
      'totalWeight': totalWeight,
      'minDrops': minDrops,
      'maxDrops': maxDrops,
      'allowDuplicates': allowDuplicates,
    };
  }
}

class LootEntry {
  final BattleReward reward;
  final double weight;
  final int minQuantity;
  final int maxQuantity;
  final List<String> conditions;

  LootEntry({
    required this.reward,
    required this.weight,
    required this.minQuantity,
    required this.maxQuantity,
    this.conditions = const [],
  });

  factory LootEntry.fromJson(Map<String, dynamic> json) {
    return LootEntry(
      reward: BattleReward.fromJson(json['reward']),
      weight: json['weight']?.toDouble() ?? 1.0,
      minQuantity: json['minQuantity'] ?? 1,
      maxQuantity: json['maxQuantity'] ?? 1,
      conditions: List<String>.from(json['conditions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reward': reward.toJson(),
      'weight': weight,
      'minQuantity': minQuantity,
      'maxQuantity': maxQuantity,
      'conditions': conditions,
    };
  }
}

class BattleRewardsService {
  static final Map<String, BattleReward> _rewardTemplates = {
    // Experience rewards
    'xp_small': BattleReward(
      id: 'xp_small',
      name: 'Small Experience',
      description: 'A small amount of experience points',
      type: RewardType.experience,
      baseAmount: 50,
      rarity: 1.0,
      properties: {},
      icon: 'assets/icons/xp_small.png',
    ),
    
    'xp_medium': BattleReward(
      id: 'xp_medium',
      name: 'Medium Experience',
      description: 'A moderate amount of experience points',
      type: RewardType.experience,
      baseAmount: 150,
      rarity: 0.7,
      properties: {},
      icon: 'assets/icons/xp_medium.png',
    ),
    
    'xp_large': BattleReward(
      id: 'xp_large',
      name: 'Large Experience',
      description: 'A large amount of experience points',
      type: RewardType.experience,
      baseAmount: 300,
      rarity: 0.4,
      properties: {},
      icon: 'assets/icons/xp_large.png',
    ),
    
    // Gold rewards
    'gold_small': BattleReward(
      id: 'gold_small',
      name: 'Small Gold Pouch',
      description: 'A small amount of gold coins',
      type: RewardType.gold,
      baseAmount: 25,
      rarity: 1.0,
      properties: {},
      icon: 'assets/icons/gold_small.png',
    ),
    
    'gold_medium': BattleReward(
      id: 'gold_medium',
      name: 'Medium Gold Pouch',
      description: 'A moderate amount of gold coins',
      type: RewardType.gold,
      baseAmount: 75,
      rarity: 0.7,
      properties: {},
      icon: 'assets/icons/gold_medium.png',
    ),
    
    'gold_large': BattleReward(
      id: 'gold_large',
      name: 'Large Gold Pouch',
      description: 'A large amount of gold coins',
      type: RewardType.gold,
      baseAmount: 150,
      rarity: 0.4,
      properties: {},
      icon: 'assets/icons/gold_large.png',
    ),
    
    // Card rewards
    'common_card': BattleReward(
      id: 'common_card',
      name: 'Common Card',
      description: 'A common card from the deck',
      type: RewardType.card,
      baseAmount: 1,
      rarity: 0.8,
      properties: {'rarity': 'common'},
      icon: 'assets/icons/card_common.png',
    ),
    
    'rare_card': BattleReward(
      id: 'rare_card',
      name: 'Rare Card',
      description: 'A rare card from the deck',
      type: RewardType.card,
      baseAmount: 1,
      rarity: 0.3,
      properties: {'rarity': 'rare'},
      icon: 'assets/icons/card_rare.png',
    ),
    
    'epic_card': BattleReward(
      id: 'epic_card',
      name: 'Epic Card',
      description: 'An epic card from the deck',
      type: RewardType.card,
      baseAmount: 1,
      rarity: 0.1,
      properties: {'rarity': 'epic'},
      icon: 'assets/icons/card_epic.png',
    ),
    
    'legendary_card': BattleReward(
      id: 'legendary_card',
      name: 'Legendary Card',
      description: 'A legendary card from the deck',
      type: RewardType.card,
      baseAmount: 1,
      rarity: 0.02,
      properties: {'rarity': 'legendary'},
      icon: 'assets/icons/card_legendary.png',
    ),
    
    // Item rewards
    'health_potion': BattleReward(
      id: 'health_potion',
      name: 'Health Potion',
      description: 'Restores health during battle',
      type: RewardType.item,
      baseAmount: 1,
      rarity: 0.6,
      properties: {'healing': 50, 'type': 'consumable'},
      icon: 'assets/icons/health_potion.png',
    ),
    
    'mana_potion': BattleReward(
      id: 'mana_potion',
      name: 'Mana Potion',
      description: 'Restores mana during battle',
      type: RewardType.item,
      baseAmount: 1,
      rarity: 0.6,
      properties: {'mana': 50, 'type': 'consumable'},
      icon: 'assets/icons/mana_potion.png',
    ),
    
    'strength_potion': BattleReward(
      id: 'strength_potion',
      name: 'Strength Potion',
      description: 'Temporarily increases attack power',
      type: RewardType.item,
      baseAmount: 1,
      rarity: 0.4,
      properties: {'attack_boost': 20, 'duration': 3, 'type': 'consumable'},
      icon: 'assets/icons/strength_potion.png',
    ),
    
    // Equipment rewards
    'iron_sword': BattleReward(
      id: 'iron_sword',
      name: 'Iron Sword',
      description: 'A basic iron sword',
      type: RewardType.equipment,
      baseAmount: 1,
      rarity: 0.5,
      properties: {'attack': 15, 'type': 'weapon', 'slot': 'main_hand'},
      icon: 'assets/icons/iron_sword.png',
    ),
    
    'leather_armor': BattleReward(
      id: 'leather_armor',
      name: 'Leather Armor',
      description: 'Basic leather armor',
      type: RewardType.equipment,
      baseAmount: 1,
      rarity: 0.5,
      properties: {'defense': 10, 'type': 'armor', 'slot': 'chest'},
      icon: 'assets/icons/leather_armor.png',
    ),
    
    // Currency rewards
    'premium_currency': BattleReward(
      id: 'premium_currency',
      name: 'Premium Currency',
      description: 'Special currency for premium items',
      type: RewardType.currency,
      baseAmount: 5,
      rarity: 0.1,
      properties: {'currency_type': 'premium'},
      icon: 'assets/icons/premium_currency.png',
    ),
    
    // Material rewards
    'iron_ore': BattleReward(
      id: 'iron_ore',
      name: 'Iron Ore',
      description: 'Raw iron ore for crafting',
      type: RewardType.material,
      baseAmount: 1,
      rarity: 0.7,
      properties: {'crafting_material': true, 'tier': 1},
      icon: 'assets/icons/iron_ore.png',
      isStackable: true,
      maxStack: 999,
    ),
    
    'magic_crystal': BattleReward(
      id: 'magic_crystal',
      name: 'Magic Crystal',
      description: 'A crystal infused with magical energy',
      type: RewardType.material,
      baseAmount: 1,
      rarity: 0.2,
      properties: {'crafting_material': true, 'tier': 3, 'magical': true},
      icon: 'assets/icons/magic_crystal.png',
      isStackable: true,
      maxStack: 99,
    ),
    
    // Cosmetic rewards
    'battle_emote': BattleReward(
      id: 'battle_emote',
      name: 'Victory Emote',
      description: 'A special emote for battle victories',
      type: RewardType.cosmetic,
      baseAmount: 1,
      rarity: 0.05,
      properties: {'cosmetic_type': 'emote', 'animation': 'victory_dance'},
      icon: 'assets/icons/battle_emote.png',
    ),
    
    // Title rewards
    'warrior_title': BattleReward(
      id: 'warrior_title',
      name: 'Warrior Title',
      description: 'The title of a skilled warrior',
      type: RewardType.title,
      baseAmount: 1,
      rarity: 0.01,
      properties: {'title': 'Warrior', 'prestige': 1},
      icon: 'assets/icons/warrior_title.png',
    ),
  };

  static final Map<String, LootTable> _lootTables = {
    // Basic enemy loot table
    'basic_enemy': LootTable(
      id: 'basic_enemy',
      name: 'Basic Enemy Loot',
      entries: [
        LootEntry(
          reward: _rewardTemplates['xp_small']!,
          weight: 100,
          minQuantity: 1,
          maxQuantity: 1,
        ),
        LootEntry(
          reward: _rewardTemplates['gold_small']!,
          weight: 80,
          minQuantity: 1,
          maxQuantity: 2,
        ),
        LootEntry(
          reward: _rewardTemplates['common_card']!,
          weight: 30,
          minQuantity: 1,
          maxQuantity: 1,
        ),
        LootEntry(
          reward: _rewardTemplates['health_potion']!,
          weight: 20,
          minQuantity: 1,
          maxQuantity: 1,
        ),
      ],
      totalWeight: 230,
      minDrops: 2,
      maxDrops: 3,
    ),
    
    // Elite enemy loot table
    'elite_enemy': LootTable(
      id: 'elite_enemy',
      name: 'Elite Enemy Loot',
      entries: [
        LootEntry(
          reward: _rewardTemplates['xp_medium']!,
          weight: 100,
          minQuantity: 1,
          maxQuantity: 1,
        ),
        LootEntry(
          reward: _rewardTemplates['gold_medium']!,
          weight: 100,
          minQuantity: 1,
          maxQuantity: 2,
        ),
        LootEntry(
          reward: _rewardTemplates['rare_card']!,
          weight: 50,
          minQuantity: 1,
          maxQuantity: 1,
        ),
        LootEntry(
          reward: _rewardTemplates['strength_potion']!,
          weight: 40,
          minQuantity: 1,
          maxQuantity: 1,
        ),
        LootEntry(
          reward: _rewardTemplates['iron_sword']!,
          weight: 20,
          minQuantity: 1,
          maxQuantity: 1,
        ),
      ],
      totalWeight: 310,
      minDrops: 3,
      maxDrops: 4,
    ),
    
    // Boss enemy loot table
    'boss_enemy': LootTable(
      id: 'boss_enemy',
      name: 'Boss Enemy Loot',
      entries: [
        LootEntry(
          reward: _rewardTemplates['xp_large']!,
          weight: 100,
          minQuantity: 1,
          maxQuantity: 1,
        ),
        LootEntry(
          reward: _rewardTemplates['gold_large']!,
          weight: 100,
          minQuantity: 1,
          maxQuantity: 2,
        ),
        LootEntry(
          reward: _rewardTemplates['epic_card']!,
          weight: 80,
          minQuantity: 1,
          maxQuantity: 1,
        ),
        LootEntry(
          reward: _rewardTemplates['legendary_card']!,
          weight: 10,
          minQuantity: 1,
          maxQuantity: 1,
        ),
        LootEntry(
          reward: _rewardTemplates['premium_currency']!,
          weight: 50,
          minQuantity: 1,
          maxQuantity: 2,
        ),
        LootEntry(
          reward: _rewardTemplates['magic_crystal']!,
          weight: 60,
          minQuantity: 1,
          maxQuantity: 2,
        ),
      ],
      totalWeight: 400,
      minDrops: 4,
      maxDrops: 6,
    ),
  };

  static BattleRewards generateBattleRewards({
    required String enemyType,
    required BattleStatistics battleStats,
    required Quest? quest,
    required double difficultyMultiplier,
    required bool isVictory,
  }) {
    if (!isVictory) {
      return BattleRewards(
        experience: 0,
        gold: 0,
        cards: [],
        items: [],
        specialRewards: {},
      );
    }

    // Get base loot table
    LootTable? lootTable = _lootTables[enemyType];
    if (lootTable == null) {
      lootTable = _lootTables['basic_enemy']!;
    }

    // Generate loot
    List<BattleReward> generatedLoot = _generateLootFromTable(
      lootTable,
      difficultyMultiplier: difficultyMultiplier,
      battleStats: battleStats,
    );

    // Calculate base rewards
    int baseExperience = _calculateBaseExperience(enemyType, difficultyMultiplier);
    int baseGold = _calculateBaseGold(enemyType, difficultyMultiplier);

    // Apply performance bonuses
    double performanceBonus = _calculatePerformanceBonus(battleStats);
    int finalExperience = (baseExperience * performanceBonus).round();
    int finalGold = (baseGold * performanceBonus).round();

    // Apply quest bonuses
    if (quest != null) {
      finalExperience = (finalExperience * _getQuestBonus(quest)).round();
      finalGold = (finalGold * _getQuestBonus(quest)).round();
    }

    // Process generated loot
    List<String> cards = [];
    List<String> items = [];
    Map<String, dynamic> specialRewards = {};

    for (var reward in generatedLoot) {
      switch (reward.type) {
        case RewardType.card:
          cards.add(reward.id);
          break;
        case RewardType.item:
        case RewardType.equipment:
        case RewardType.material:
        case RewardType.cosmetic:
        case RewardType.title:
          items.add(reward.id);
          break;
        case RewardType.currency:
          specialRewards[reward.id] = reward.baseAmount;
          break;
        default:
          break;
      }
    }

    return BattleRewards(
      experience: finalExperience,
      gold: finalGold,
      cards: cards,
      items: items,
      specialRewards: specialRewards,
    );
  }

  static List<BattleReward> _generateLootFromTable(
    LootTable lootTable, {
    required double difficultyMultiplier,
    required BattleStatistics battleStats,
  }) {
    List<BattleReward> loot = [];
    Random random = Random();
    
    int numDrops = random.nextInt(
      lootTable.maxDrops - lootTable.minDrops + 1
    ) + lootTable.minDrops;

    for (int i = 0; i < numDrops; i++) {
      double roll = random.nextDouble() * lootTable.totalWeight;
      double currentWeight = 0;

      for (var entry in lootTable.entries) {
        currentWeight += entry.weight;
        
        // Apply difficulty and performance modifiers
        double modifiedWeight = entry.weight;
        if (difficultyMultiplier > 1.0) {
          modifiedWeight *= (1 + (difficultyMultiplier - 1) * 0.5);
        }
        
        if (battleStats.totalTurns < 10) {
          modifiedWeight *= 1.2; // Bonus for quick victory
        }

        if (roll <= currentWeight) {
          // Check if we already have this item (if duplicates not allowed)
          if (!lootTable.allowDuplicates && 
              loot.any((r) => r.id == entry.reward.id)) {
            continue;
          }

          int quantity = random.nextInt(
            entry.maxQuantity - entry.minQuantity + 1
          ) + entry.minQuantity;

          for (int j = 0; j < quantity; j++) {
            loot.add(entry.reward);
          }
          break;
        }
      }
    }

    return loot;
  }

  static int _calculateBaseExperience(String enemyType, double difficultyMultiplier) {
    switch (enemyType) {
      case 'basic_enemy':
        return (50 * difficultyMultiplier).round();
      case 'elite_enemy':
        return (150 * difficultyMultiplier).round();
      case 'boss_enemy':
        return (300 * difficultyMultiplier).round();
      default:
        return (50 * difficultyMultiplier).round();
    }
  }

  static int _calculateBaseGold(String enemyType, double difficultyMultiplier) {
    switch (enemyType) {
      case 'basic_enemy':
        return (25 * difficultyMultiplier).round();
      case 'elite_enemy':
        return (75 * difficultyMultiplier).round();
      case 'boss_enemy':
        return (150 * difficultyMultiplier).round();
      default:
        return (25 * difficultyMultiplier).round();
    }
  }

  static double _calculatePerformanceBonus(BattleStatistics battleStats) {
    double bonus = 1.0;
    
    // Quick victory bonus
    if (battleStats.totalTurns < 10) {
      bonus += 0.2;
    }
    
    // Low damage taken bonus
    if (battleStats.damageReceived < 50) {
      bonus += 0.1;
    }
    
    // High damage dealt bonus
    if (battleStats.damageDealt > 100) {
      bonus += 0.1;
    }
    
    // Efficient card usage bonus
    if (battleStats.cardsPlayed < 8) {
      bonus += 0.1;
    }
    
    return bonus;
  }

  static double _getQuestBonus(Quest quest) {
    double bonus = 1.0;
    
    if (quest.tags.contains('boss')) {
      bonus += 0.5;
    }
    
    if (quest.tags.contains('time_limit')) {
      bonus += 0.3;
    }
    
    if (quest.difficulty == 'hard') {
      bonus += 0.2;
    }
    
    return bonus;
  }

  static BattleReward? getRewardTemplate(String rewardId) {
    return _rewardTemplates[rewardId];
  }

  static List<BattleReward> getAllRewardTemplates() {
    return _rewardTemplates.values.toList();
  }

  static LootTable? getLootTable(String tableId) {
    return _lootTables[tableId];
  }

  static List<LootTable> getAllLootTables() {
    return _lootTables.values.toList();
  }
}

// Riverpod providers
final battleRewardsServiceProvider = Provider<BattleRewardsService>((ref) {
  return BattleRewardsService();
});
