import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum EnhancementType {
  upgrade,
  enchantment,
  socket,
  gem,
  reforge,
  transmute,
}

enum EnhancementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

enum GemType {
  ruby,      // Strength
  sapphire,  // Intelligence
  emerald,   // Dexterity
  diamond,   // Vitality
  amethyst,  // Charisma
  topaz,     // Luck
  onyx,      // Critical
  pearl,     // Defense
}

class EnhancementData extends Equatable {
  final String id;
  final String name;
  final String description;
  final EnhancementType type;
  final EnhancementRarity rarity;
  final Map<String, double> statBonuses;
  final Map<String, dynamic> specialEffects;
  final int maxLevel;
  final double successRate;
  final List<String> materials;
  final int materialCost;
  final String icon;
  final Color color;

  const EnhancementData({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.statBonuses,
    required this.specialEffects,
    required this.maxLevel,
    required this.successRate,
    required this.materials,
    required this.materialCost,
    required this.icon,
    required this.color,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    type,
    rarity,
    statBonuses,
    specialEffects,
    maxLevel,
    successRate,
    materials,
    materialCost,
    icon,
    color,
  ];
}

class GemData extends Equatable {
  final String id;
  final String name;
  final String description;
  final GemType type;
  final EnhancementRarity rarity;
  final Map<String, double> statBonuses;
  final Map<String, dynamic> specialEffects;
  final int maxLevel;
  final String icon;
  final Color color;
  final String lore;

  const GemData({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.statBonuses,
    required this.specialEffects,
    required this.maxLevel,
    required this.icon,
    required this.color,
    required this.lore,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    type,
    rarity,
    statBonuses,
    specialEffects,
    maxLevel,
    icon,
    color,
    lore,
  ];
}

class EquipmentEnhancement extends Equatable {
  final String id;
  final String equipmentId;
  final EnhancementType type;
  final EnhancementData enhancement;
  final int level;
  final double successRate;
  final DateTime appliedDate;
  final String appliedBy;
  final Map<String, dynamic> currentEffects;

  const EquipmentEnhancement({
    required this.id,
    required this.equipmentId,
    required this.type,
    required this.enhancement,
    required this.level,
    required this.successRate,
    required this.appliedDate,
    required this.appliedBy,
    required this.currentEffects,
  });

  @override
  List<Object?> get props => [
    id,
    equipmentId,
    type,
    enhancement,
    level,
    successRate,
    appliedDate,
    appliedBy,
    currentEffects,
  ];
}

class EquipmentSocket extends Equatable {
  final String id;
  final String equipmentId;
  final int socketNumber;
  final GemData? gem;
  final int gemLevel;
  final bool isUnlocked;
  final DateTime unlockDate;

  const EquipmentSocket({
    required this.id,
    required this.equipmentId,
    required this.socketNumber,
    this.gem,
    this.gemLevel = 1,
    this.isUnlocked = false,
    required this.unlockDate,
  });

  @override
  List<Object?> get props => [
    id,
    equipmentId,
    socketNumber,
    gem,
    gemLevel,
    isUnlocked,
    unlockDate,
  ];
}

class EnhancementService {
  static final Map<String, EnhancementData> _enhancements = {
    // Upgrade Enhancements
    'strength_upgrade': EnhancementData(
      id: 'strength_upgrade',
      name: 'Strength Upgrade',
      description: 'Increases the strength bonus of equipment',
      type: EnhancementType.upgrade,
      rarity: EnhancementRarity.common,
      statBonuses: {'strength': 5.0},
      specialEffects: {},
      maxLevel: 10,
      successRate: 0.9,
      materials: ['iron_ore', 'steel_ingot'],
      materialCost: 100,
      icon: '⚔️',
      color: Colors.red,
    ),
    
    'intelligence_upgrade': EnhancementData(
      id: 'intelligence_upgrade',
      name: 'Intelligence Upgrade',
      description: 'Increases the intelligence bonus of equipment',
      type: EnhancementType.upgrade,
      rarity: EnhancementRarity.common,
      statBonuses: {'intelligence': 5.0},
      specialEffects: {},
      maxLevel: 10,
      successRate: 0.9,
      materials: ['arcane_crystal', 'mana_dust'],
      materialCost: 100,
      icon: '🧠',
      color: Colors.blue,
    ),
    
    'dexterity_upgrade': EnhancementData(
      id: 'dexterity_upgrade',
      name: 'Dexterity Upgrade',
      description: 'Increases the dexterity bonus of equipment',
      type: EnhancementType.upgrade,
      rarity: EnhancementRarity.common,
      statBonuses: {'dexterity': 5.0},
      specialEffects: {},
      maxLevel: 10,
      successRate: 0.9,
      materials: ['leather', 'silk'],
      materialCost: 100,
      icon: '🏹',
      color: Colors.green,
    ),

    // Enchantment Enhancements
    'fire_enchantment': EnhancementData(
      id: 'fire_enchantment',
      name: 'Fire Enchantment',
      description: 'Adds fire damage to attacks',
      type: EnhancementType.enchantment,
      rarity: EnhancementRarity.rare,
      statBonuses: {'fire_damage': 15.0},
      specialEffects: {
        'burn_chance': 0.1,
        'burn_duration': 3.0,
      },
      maxLevel: 5,
      successRate: 0.7,
      materials: ['fire_essence', 'phoenix_feather'],
      materialCost: 500,
      icon: '🔥',
      color: Colors.orange,
    ),
    
    'ice_enchantment': EnhancementData(
      id: 'ice_enchantment',
      name: 'Ice Enchantment',
      description: 'Adds ice damage and freezing effects',
      type: EnhancementType.enchantment,
      rarity: EnhancementRarity.rare,
      statBonuses: {'ice_damage': 15.0},
      specialEffects: {
        'freeze_chance': 0.08,
        'freeze_duration': 2.0,
      },
      maxLevel: 5,
      successRate: 0.7,
      materials: ['ice_essence', 'frost_crystal'],
      materialCost: 500,
      icon: '❄️',
      color: Colors.cyan,
    ),
    
    'lightning_enchantment': EnhancementData(
      id: 'lightning_enchantment',
      name: 'Lightning Enchantment',
      description: 'Adds lightning damage and chain effects',
      type: EnhancementType.enchantment,
      rarity: EnhancementRarity.rare,
      statBonuses: {'lightning_damage': 15.0},
      specialEffects: {
        'chain_chance': 0.15,
        'chain_targets': 3,
      },
      maxLevel: 5,
      successRate: 0.7,
      materials: ['lightning_essence', 'storm_crystal'],
      materialCost: 500,
      icon: '⚡',
      color: Colors.yellow,
    ),

    // Socket Enhancements
    'socket_unlock': EnhancementData(
      id: 'socket_unlock',
      name: 'Socket Unlock',
      description: 'Unlocks a gem socket on equipment',
      type: EnhancementType.socket,
      rarity: EnhancementRarity.epic,
      statBonuses: {},
      specialEffects: {},
      maxLevel: 1,
      successRate: 0.5,
      materials: ['socket_chisel', 'precious_metal'],
      materialCost: 1000,
      icon: '💎',
      color: Colors.purple,
    ),
  };

  static final Map<GemType, GemData> _gems = {
    GemType.ruby: GemData(
      id: 'ruby',
      name: 'Ruby',
      description: 'A precious red gem that enhances strength',
      type: GemType.ruby,
      rarity: EnhancementRarity.rare,
      statBonuses: {'strength': 10.0},
      specialEffects: {
        'critical_damage_bonus': 0.05,
      },
      maxLevel: 5,
      icon: '💎',
      color: Colors.red,
      lore: 'Rubies are said to contain the essence of fire itself.',
    ),
    
    GemType.sapphire: GemData(
      id: 'sapphire',
      name: 'Sapphire',
      description: 'A brilliant blue gem that enhances intelligence',
      type: GemType.sapphire,
      rarity: EnhancementRarity.rare,
      statBonuses: {'intelligence': 10.0},
      specialEffects: {
        'mana_regeneration': 0.1,
      },
      maxLevel: 5,
      icon: '💎',
      color: Colors.blue,
      lore: 'Sapphires are believed to enhance magical abilities.',
    ),
    
    GemType.emerald: GemData(
      id: 'emerald',
      name: 'Emerald',
      description: 'A vibrant green gem that enhances dexterity',
      type: GemType.emerald,
      rarity: EnhancementRarity.rare,
      statBonuses: {'dexterity': 10.0},
      specialEffects: {
        'dodge_chance': 0.03,
      },
      maxLevel: 5,
      icon: '💎',
      color: Colors.green,
      lore: 'Emeralds are known to improve agility and reflexes.',
    ),
    
    GemType.diamond: GemData(
      id: 'diamond',
      name: 'Diamond',
      description: 'A pure white gem that enhances vitality',
      type: GemType.diamond,
      rarity: EnhancementRarity.epic,
      statBonuses: {'vitality': 10.0},
      specialEffects: {
        'damage_resistance': 0.05,
      },
      maxLevel: 5,
      icon: '💎',
      color: Colors.white,
      lore: 'Diamonds are the hardest substance known, providing great protection.',
    ),
    
    GemType.amethyst: GemData(
      id: 'amethyst',
      name: 'Amethyst',
      description: 'A mystical purple gem that enhances charisma',
      type: GemType.amethyst,
      rarity: EnhancementRarity.rare,
      statBonuses: {'charisma': 10.0},
      specialEffects: {
        'persuasion_bonus': 0.1,
      },
      maxLevel: 5,
      icon: '💎',
      color: Colors.purple,
      lore: 'Amethysts are said to enhance one\'s ability to influence others.',
    ),
    
    GemType.topaz: GemData(
      id: 'topaz',
      name: 'Topaz',
      description: 'A golden gem that enhances luck',
      type: GemType.topaz,
      rarity: EnhancementRarity.rare,
      statBonuses: {'luck': 10.0},
      specialEffects: {
        'critical_chance': 0.02,
      },
      maxLevel: 5,
      icon: '💎',
      color: Colors.amber,
      lore: 'Topaz is believed to bring good fortune to its bearer.',
    ),
    
    GemType.onyx: GemData(
      id: 'onyx',
      name: 'Onyx',
      description: 'A dark gem that enhances critical abilities',
      type: GemType.onyx,
      rarity: EnhancementRarity.epic,
      statBonuses: {},
      specialEffects: {
        'critical_chance': 0.05,
        'critical_damage': 0.15,
      },
      maxLevel: 5,
      icon: '💎',
      color: Colors.black,
      lore: 'Onyx is the gem of precision and deadly accuracy.',
    ),
    
    GemType.pearl: GemData(
      id: 'pearl',
      name: 'Pearl',
      description: 'A lustrous gem that enhances defensive abilities',
      type: GemType.pearl,
      rarity: EnhancementRarity.rare,
      statBonuses: {},
      specialEffects: {
        'damage_resistance': 0.08,
        'healing_bonus': 0.1,
      },
      maxLevel: 5,
      icon: '💎',
      color: Colors.pink,
      lore: 'Pearls are symbols of purity and protection.',
    ),
  };

  static EnhancementData getEnhancement(String id) {
    return _enhancements[id] ?? _enhancements['strength_upgrade']!;
  }

  static GemData getGem(GemType type) {
    return _gems[type] ?? _gems[GemType.ruby]!;
  }

  static List<EnhancementData> getEnhancementsByType(EnhancementType type) {
    return _enhancements.values.where((e) => e.type == type).toList();
  }

  static List<EnhancementData> getEnhancementsByRarity(EnhancementRarity rarity) {
    return _enhancements.values.where((e) => e.rarity == rarity).toList();
  }

  static List<GemData> getAllGems() {
    return _gems.values.toList();
  }

  static bool canApplyEnhancement(String equipmentId, EnhancementData enhancement, List<EquipmentEnhancement> currentEnhancements) {
    // Check if enhancement is already applied
    final existingEnhancement = currentEnhancements.firstWhere(
      (e) => e.enhancement.id == enhancement.id,
      orElse: () => EquipmentEnhancement(
        id: '',
        equipmentId: '',
        type: EnhancementType.upgrade,
        enhancement: enhancement,
        level: 0,
        successRate: 0.0,
        appliedDate: DateTime.now(),
        appliedBy: '',
        currentEffects: {},
      ),
    );

    // Check if max level reached
    if (existingEnhancement.level >= enhancement.maxLevel) {
      return false;
    }

    // Check for conflicting enhancements
    if (enhancement.type == EnhancementType.enchantment) {
      final hasOtherEnchantment = currentEnhancements.any(
        (e) => e.type == EnhancementType.enchantment && e.enhancement.id != enhancement.id,
      );
      if (hasOtherEnchantment) {
        return false;
      }
    }

    return true;
  }

  static double calculateSuccessRate(EnhancementData enhancement, int currentLevel, int playerLevel) {
    double baseRate = enhancement.successRate;
    
    // Reduce success rate with each level
    baseRate -= (currentLevel * 0.05);
    
    // Player level bonus
    baseRate += (playerLevel * 0.01);
    
    // Ensure rate is between 0.05 and 0.95
    return baseRate.clamp(0.05, 0.95);
  }

  static Map<String, double> calculateEnhancementEffects(EnhancementData enhancement, int level) {
    final effects = <String, double>{};
    
    // Apply stat bonuses
    for (final entry in enhancement.statBonuses.entries) {
      effects[entry.key] = entry.value * level;
    }
    
    // Apply special effects
    for (final entry in enhancement.specialEffects.entries) {
      if (entry.value is double) {
        effects[entry.key] = (entry.value as double) * level;
      } else {
        effects[entry.key] = entry.value.toDouble();
      }
    }
    
    return effects;
  }

  static Map<String, double> calculateGemEffects(GemData gem, int level) {
    final effects = <String, double>{};
    
    // Apply stat bonuses
    for (final entry in gem.statBonuses.entries) {
      effects[entry.key] = entry.value * level;
    }
    
    // Apply special effects
    for (final entry in gem.specialEffects.entries) {
      if (entry.value is double) {
        effects[entry.key] = (entry.value as double) * level;
      } else {
        effects[entry.key] = entry.value.toDouble();
      }
    }
    
    return effects;
  }
}
