import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum PrestigeType {
  normal,
  legendary,
  mythical,
  divine,
  transcendent,
}

enum RebirthType {
  first,
  second,
  third,
  fourth,
  fifth,
  ultimate,
}

class PrestigeData extends Equatable {
  final String id;
  final String name;
  final String description;
  final PrestigeType type;
  final int requiredLevel;
  final int requiredExperience;
  final Map<String, double> statMultipliers;
  final Map<String, dynamic> specialBonuses;
  final List<String> unlockedFeatures;
  final String icon;
  final Color color;
  final String lore;

  const PrestigeData({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.requiredLevel,
    required this.requiredExperience,
    required this.statMultipliers,
    required this.specialBonuses,
    required this.unlockedFeatures,
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
    requiredLevel,
    requiredExperience,
    statMultipliers,
    specialBonuses,
    unlockedFeatures,
    icon,
    color,
    lore,
  ];
}

class RebirthData extends Equatable {
  final String id;
  final String name;
  final String description;
  final RebirthType type;
  final int requiredPrestigeLevel;
  final int requiredTotalLevel;
  final Map<String, double> permanentBonuses;
  final Map<String, dynamic> rebirthEffects;
  final List<String> rebirthRewards;
  final String icon;
  final Color color;
  final String lore;

  const RebirthData({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.requiredPrestigeLevel,
    required this.requiredTotalLevel,
    required this.permanentBonuses,
    required this.rebirthEffects,
    required this.rebirthRewards,
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
    requiredPrestigeLevel,
    requiredTotalLevel,
    permanentBonuses,
    rebirthEffects,
    rebirthRewards,
    icon,
    color,
    lore,
  ];
}

class PrestigeProgress extends Equatable {
  final String characterId;
  final PrestigeType currentPrestige;
  final int prestigeLevel;
  final int totalPrestigeLevels;
  final int prestigeExperience;
  final int experienceToNextPrestige;
  final List<PrestigeType> unlockedPrestiges;
  final Map<String, int> prestigeAchievements;
  final DateTime lastPrestigeDate;

  const PrestigeProgress({
    required this.characterId,
    required this.currentPrestige,
    required this.prestigeLevel,
    required this.totalPrestigeLevels,
    required this.prestigeExperience,
    required this.experienceToNextPrestige,
    required this.unlockedPrestiges,
    required this.prestigeAchievements,
    required this.lastPrestigeDate,
  });

  double get prestigeProgress => prestigeExperience / experienceToNextPrestige;
  bool get canPrestige => prestigeExperience >= experienceToNextPrestige;

  @override
  List<Object?> get props => [
    characterId,
    currentPrestige,
    prestigeLevel,
    totalPrestigeLevels,
    prestigeExperience,
    experienceToNextPrestige,
    unlockedPrestiges,
    prestigeAchievements,
    lastPrestigeDate,
  ];
}

class RebirthProgress extends Equatable {
  final String characterId;
  final RebirthType currentRebirth;
  final int rebirthCount;
  final int totalRebirths;
  final int rebirthExperience;
  final int experienceToNextRebirth;
  final List<RebirthType> unlockedRebirths;
  final Map<String, int> rebirthAchievements;
  final DateTime lastRebirthDate;
  final Map<String, double> accumulatedBonuses;

  const RebirthProgress({
    required this.characterId,
    required this.currentRebirth,
    required this.rebirthCount,
    required this.totalRebirths,
    required this.rebirthExperience,
    required this.experienceToNextRebirth,
    required this.unlockedRebirths,
    required this.rebirthAchievements,
    required this.lastRebirthDate,
    required this.accumulatedBonuses,
  });

  double get rebirthProgress => rebirthExperience / experienceToNextRebirth;
  bool get canRebirth => rebirthExperience >= experienceToNextRebirth;

  @override
  List<Object?> get props => [
    characterId,
    currentRebirth,
    rebirthCount,
    totalRebirths,
    rebirthExperience,
    experienceToNextRebirth,
    unlockedRebirths,
    rebirthAchievements,
    lastRebirthDate,
    accumulatedBonuses,
  ];
}

class PrestigeService {
  static final Map<PrestigeType, PrestigeData> _prestigeData = {
    PrestigeType.normal: PrestigeData(
      id: 'normal_prestige',
      name: 'Normal Prestige',
      description: 'The first step in transcending mortal limits',
      type: PrestigeType.normal,
      requiredLevel: 50,
      requiredExperience: 100000,
      statMultipliers: {
        'strength': 1.1,
        'dexterity': 1.1,
        'intelligence': 1.1,
        'vitality': 1.1,
        'charisma': 1.1,
        'luck': 1.1,
      },
      specialBonuses: {
        'experience_gain': 0.1,
        'skill_point_gain': 0.05,
      },
      unlockedFeatures: ['prestige_shop', 'prestige_quests'],
      icon: '⭐',
      color: Colors.yellow,
      lore: 'The first transcendence, marking the beginning of true power.',
    ),
    
    PrestigeType.legendary: PrestigeData(
      id: 'legendary_prestige',
      name: 'Legendary Prestige',
      description: 'Achieve legendary status through great deeds',
      type: PrestigeType.legendary,
      requiredLevel: 100,
      requiredExperience: 500000,
      statMultipliers: {
        'strength': 1.2,
        'dexterity': 1.2,
        'intelligence': 1.2,
        'vitality': 1.2,
        'charisma': 1.2,
        'luck': 1.2,
      },
      specialBonuses: {
        'experience_gain': 0.2,
        'skill_point_gain': 0.1,
        'legendary_abilities': true,
      },
      unlockedFeatures: ['legendary_shop', 'legendary_quests', 'legendary_equipment'],
      icon: '🌟',
      color: Colors.orange,
      lore: 'Legends are born from those who dare to dream beyond the ordinary.',
    ),
    
    PrestigeType.mythical: PrestigeData(
      id: 'mythical_prestige',
      name: 'Mythical Prestige',
      description: 'Become a figure of myth and legend',
      type: PrestigeType.mythical,
      requiredLevel: 200,
      requiredExperience: 2000000,
      statMultipliers: {
        'strength': 1.3,
        'dexterity': 1.3,
        'intelligence': 1.3,
        'vitality': 1.3,
        'charisma': 1.3,
        'luck': 1.3,
      },
      specialBonuses: {
        'experience_gain': 0.3,
        'skill_point_gain': 0.15,
        'mythical_abilities': true,
        'reality_bending': 0.05,
      },
      unlockedFeatures: ['mythical_shop', 'mythical_quests', 'mythical_equipment', 'reality_manipulation'],
      icon: '✨',
      color: Colors.purple,
      lore: 'Myths become reality for those who reach this level of power.',
    ),
    
    PrestigeType.divine: PrestigeData(
      id: 'divine_prestige',
      name: 'Divine Prestige',
      description: 'Ascend to divine status and wield godlike power',
      type: PrestigeType.divine,
      requiredLevel: 500,
      requiredExperience: 10000000,
      statMultipliers: {
        'strength': 1.5,
        'dexterity': 1.5,
        'intelligence': 1.5,
        'vitality': 1.5,
        'charisma': 1.5,
        'luck': 1.5,
      },
      specialBonuses: {
        'experience_gain': 0.5,
        'skill_point_gain': 0.25,
        'divine_abilities': true,
        'reality_bending': 0.1,
        'immortality': 0.01,
      },
      unlockedFeatures: ['divine_shop', 'divine_quests', 'divine_equipment', 'divine_realms'],
      icon: '👑',
      color: Colors.amber,
      lore: 'Divine power flows through those who have transcended mortality.',
    ),
    
    PrestigeType.transcendent: PrestigeData(
      id: 'transcendent_prestige',
      name: 'Transcendent Prestige',
      description: 'Transcend all known limits and become truly infinite',
      type: PrestigeType.transcendent,
      requiredLevel: 1000,
      requiredExperience: 100000000,
      statMultipliers: {
        'strength': 2.0,
        'dexterity': 2.0,
        'intelligence': 2.0,
        'vitality': 2.0,
        'charisma': 2.0,
        'luck': 2.0,
      },
      specialBonuses: {
        'experience_gain': 1.0,
        'skill_point_gain': 0.5,
        'transcendent_abilities': true,
        'reality_bending': 0.25,
        'immortality': 0.1,
        'omniscience': 0.01,
      },
      unlockedFeatures: ['transcendent_shop', 'transcendent_quests', 'transcendent_equipment', 'infinite_realms'],
      icon: '∞',
      color: Colors.white,
      lore: 'Beyond all comprehension lies the realm of the transcendent.',
    ),
  };

  static final Map<RebirthType, RebirthData> _rebirthData = {
    RebirthType.first: RebirthData(
      id: 'first_rebirth',
      name: 'First Rebirth',
      description: 'Begin your journey of infinite rebirth',
      type: RebirthType.first,
      requiredPrestigeLevel: 1,
      requiredTotalLevel: 100,
      permanentBonuses: {
        'all_stats': 0.05,
        'experience_gain': 0.1,
        'skill_point_gain': 0.05,
      },
      rebirthEffects: {
        'level_reset': true,
        'skill_reset': true,
        'equipment_preserve': true,
        'prestige_preserve': true,
      },
      rebirthRewards: ['rebirth_token', 'cosmic_essence', 'eternal_memory'],
      icon: '🔄',
      color: Colors.blue,
      lore: 'The first step in the cycle of infinite rebirth.',
    ),
    
    RebirthType.second: RebirthData(
      id: 'second_rebirth',
      name: 'Second Rebirth',
      description: 'Strengthen your soul through rebirth',
      type: RebirthType.second,
      requiredPrestigeLevel: 2,
      requiredTotalLevel: 250,
      permanentBonuses: {
        'all_stats': 0.1,
        'experience_gain': 0.2,
        'skill_point_gain': 0.1,
        'rebirth_efficiency': 0.1,
      },
      rebirthEffects: {
        'level_reset': true,
        'skill_reset': true,
        'equipment_preserve': true,
        'prestige_preserve': true,
        'soul_strengthening': true,
      },
      rebirthRewards: ['rebirth_token', 'cosmic_essence', 'eternal_memory', 'soul_fragment'],
      icon: '🔄🔄',
      color: Colors.green,
      lore: 'Each rebirth strengthens the soul and deepens understanding.',
    ),
    
    RebirthType.third: RebirthData(
      id: 'third_rebirth',
      name: 'Third Rebirth',
      description: 'Master the art of rebirth',
      type: RebirthType.third,
      requiredPrestigeLevel: 3,
      requiredTotalLevel: 500,
      permanentBonuses: {
        'all_stats': 0.15,
        'experience_gain': 0.3,
        'skill_point_gain': 0.15,
        'rebirth_efficiency': 0.2,
        'reality_understanding': 0.05,
      },
      rebirthEffects: {
        'level_reset': true,
        'skill_reset': true,
        'equipment_preserve': true,
        'prestige_preserve': true,
        'soul_strengthening': true,
        'reality_manipulation': true,
      },
      rebirthRewards: ['rebirth_token', 'cosmic_essence', 'eternal_memory', 'soul_fragment', 'reality_shard'],
      icon: '🔄🔄🔄',
      color: Colors.orange,
      lore: 'Mastery of rebirth brings understanding of reality itself.',
    ),
    
    RebirthType.fourth: RebirthData(
      id: 'fourth_rebirth',
      name: 'Fourth Rebirth',
      description: 'Transcend the cycle of rebirth',
      type: RebirthType.fourth,
      requiredPrestigeLevel: 4,
      requiredTotalLevel: 1000,
      permanentBonuses: {
        'all_stats': 0.25,
        'experience_gain': 0.5,
        'skill_point_gain': 0.25,
        'rebirth_efficiency': 0.3,
        'reality_understanding': 0.1,
        'transcendence': 0.05,
      },
      rebirthEffects: {
        'level_reset': true,
        'skill_reset': true,
        'equipment_preserve': true,
        'prestige_preserve': true,
        'soul_strengthening': true,
        'reality_manipulation': true,
        'transcendence': true,
      },
      rebirthRewards: ['rebirth_token', 'cosmic_essence', 'eternal_memory', 'soul_fragment', 'reality_shard', 'transcendence_crystal'],
      icon: '🔄🔄🔄🔄',
      color: Colors.purple,
      lore: 'Transcending the cycle brings true understanding of existence.',
    ),
    
    RebirthType.fifth: RebirthData(
      id: 'fifth_rebirth',
      name: 'Fifth Rebirth',
      description: 'Achieve ultimate mastery of rebirth',
      type: RebirthType.fifth,
      requiredPrestigeLevel: 5,
      requiredTotalLevel: 2000,
      permanentBonuses: {
        'all_stats': 0.5,
        'experience_gain': 1.0,
        'skill_point_gain': 0.5,
        'rebirth_efficiency': 0.5,
        'reality_understanding': 0.2,
        'transcendence': 0.1,
        'omniscience': 0.05,
      },
      rebirthEffects: {
        'level_reset': true,
        'skill_reset': true,
        'equipment_preserve': true,
        'prestige_preserve': true,
        'soul_strengthening': true,
        'reality_manipulation': true,
        'transcendence': true,
        'omniscience': true,
      },
      rebirthRewards: ['rebirth_token', 'cosmic_essence', 'eternal_memory', 'soul_fragment', 'reality_shard', 'transcendence_crystal', 'omniscience_orb'],
      icon: '🔄🔄🔄🔄🔄',
      color: Colors.amber,
      lore: 'Ultimate mastery brings omniscience and infinite understanding.',
    ),
    
    RebirthType.ultimate: RebirthData(
      id: 'ultimate_rebirth',
      name: 'Ultimate Rebirth',
      description: 'The final rebirth - become truly infinite',
      type: RebirthType.ultimate,
      requiredPrestigeLevel: 5,
      requiredTotalLevel: 5000,
      permanentBonuses: {
        'all_stats': 1.0,
        'experience_gain': 2.0,
        'skill_point_gain': 1.0,
        'rebirth_efficiency': 1.0,
        'reality_understanding': 0.5,
        'transcendence': 0.25,
        'omniscience': 0.1,
        'infinity': 0.01,
      },
      rebirthEffects: {
        'level_reset': true,
        'skill_reset': true,
        'equipment_preserve': true,
        'prestige_preserve': true,
        'soul_strengthening': true,
        'reality_manipulation': true,
        'transcendence': true,
        'omniscience': true,
        'infinity': true,
      },
      rebirthRewards: ['rebirth_token', 'cosmic_essence', 'eternal_memory', 'soul_fragment', 'reality_shard', 'transcendence_crystal', 'omniscience_orb', 'infinity_gem'],
      icon: '∞',
      color: Colors.white,
      lore: 'The ultimate rebirth - becoming truly infinite and eternal.',
    ),
  };

  static PrestigeData getPrestigeData(PrestigeType type) {
    return _prestigeData[type] ?? _prestigeData[PrestigeType.normal]!;
  }

  static RebirthData getRebirthData(RebirthType type) {
    return _rebirthData[type] ?? _rebirthData[RebirthType.first]!;
  }

  static List<PrestigeData> getAllPrestiges() {
    return _prestigeData.values.toList();
  }

  static List<RebirthData> getAllRebirths() {
    return _rebirthData.values.toList();
  }

  static bool canPrestige(PrestigeType currentPrestige, int level, int experience) {
    final nextPrestige = _getNextPrestige(currentPrestige);
    if (nextPrestige == null) return false;
    
    final prestigeData = getPrestigeData(nextPrestige);
    return level >= prestigeData.requiredLevel && experience >= prestigeData.requiredExperience;
  }

  static bool canRebirth(RebirthType currentRebirth, int prestigeLevel, int totalLevel) {
    final nextRebirth = _getNextRebirth(currentRebirth);
    if (nextRebirth == null) return false;
    
    final rebirthData = getRebirthData(nextRebirth);
    return prestigeLevel >= rebirthData.requiredPrestigeLevel && 
           totalLevel >= rebirthData.requiredTotalLevel;
  }

  static PrestigeType? _getNextPrestige(PrestigeType current) {
    final types = PrestigeType.values;
    final currentIndex = types.indexOf(current);
    if (currentIndex < types.length - 1) {
      return types[currentIndex + 1];
    }
    return null;
  }

  static RebirthType? _getNextRebirth(RebirthType current) {
    final types = RebirthType.values;
    final currentIndex = types.indexOf(current);
    if (currentIndex < types.length - 1) {
      return types[currentIndex + 1];
    }
    return null;
  }

  static Map<String, double> calculatePrestigeBonuses(PrestigeProgress progress) {
    final bonuses = <String, double>{};
    final prestigeData = getPrestigeData(progress.currentPrestige);
    
    // Apply stat multipliers
    for (final entry in prestigeData.statMultipliers.entries) {
      bonuses[entry.key] = entry.value;
    }
    
    // Apply special bonuses
    for (final entry in prestigeData.specialBonuses.entries) {
      if (entry.value is double) {
        bonuses[entry.key] = entry.value as double;
      }
    }
    
    return bonuses;
  }

  static Map<String, double> calculateRebirthBonuses(RebirthProgress progress) {
    final bonuses = <String, double>{};
    
    // Apply accumulated bonuses from all rebirths
    for (final entry in progress.accumulatedBonuses.entries) {
      bonuses[entry.key] = entry.value;
    }
    
    // Apply current rebirth bonuses
    final rebirthData = getRebirthData(progress.currentRebirth);
    for (final entry in rebirthData.permanentBonuses.entries) {
      bonuses[entry.key] = (bonuses[entry.key] ?? 0) + entry.value;
    }
    
    return bonuses;
  }

  static int calculateExperienceToNextPrestige(PrestigeType currentPrestige) {
    final nextPrestige = _getNextPrestige(currentPrestige);
    if (nextPrestige == null) return 0;
    
    final prestigeData = getPrestigeData(nextPrestige);
    return prestigeData.requiredExperience;
  }

  static int calculateExperienceToNextRebirth(RebirthType currentRebirth) {
    final nextRebirth = _getNextRebirth(currentRebirth);
    if (nextRebirth == null) return 0;
    
    final rebirthData = getRebirthData(nextRebirth);
    return rebirthData.requiredTotalLevel * 1000; // Simplified calculation
  }
}
