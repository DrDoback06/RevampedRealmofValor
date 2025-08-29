import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum SynergyType {
  elemental,
  combat,
  support,
  defensive,
  offensive,
  utility,
  hybrid,
}

enum ComboType {
  chain,
  burst,
  sustained,
  defensive,
  utility,
  ultimate,
}

class SkillSynergy extends Equatable {
  final String id;
  final String name;
  final String description;
  final SynergyType type;
  final List<String> requiredSkills;
  final Map<String, double> synergyBonuses;
  final Map<String, dynamic> specialEffects;
  final int activationThreshold;
  final String icon;
  final Color color;
  final String lore;

  const SkillSynergy({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.requiredSkills,
    required this.synergyBonuses,
    required this.specialEffects,
    required this.activationThreshold,
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
    requiredSkills,
    synergyBonuses,
    specialEffects,
    activationThreshold,
    icon,
    color,
    lore,
  ];
}

class SkillCombo extends Equatable {
  final String id;
  final String name;
  final String description;
  final ComboType type;
  final List<String> comboSequence;
  final Map<String, double> comboEffects;
  final Map<String, dynamic> specialEffects;
  final int comboMultiplier;
  final double successRate;
  final String icon;
  final Color color;
  final String lore;

  const SkillCombo({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.comboSequence,
    required this.comboEffects,
    required this.specialEffects,
    required this.comboMultiplier,
    required this.successRate,
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
    comboSequence,
    comboEffects,
    specialEffects,
    comboMultiplier,
    successRate,
    icon,
    color,
    lore,
  ];
}

class SynergyProgress extends Equatable {
  final String synergyId;
  final int activationCount;
  final double totalBonus;
  final DateTime firstActivation;
  final DateTime lastActivation;
  final Map<String, int> skillUsageCount;

  const SynergyProgress({
    required this.synergyId,
    required this.activationCount,
    required this.totalBonus,
    required this.firstActivation,
    required this.lastActivation,
    required this.skillUsageCount,
  });

  @override
  List<Object?> get props => [
    synergyId,
    activationCount,
    totalBonus,
    firstActivation,
    lastActivation,
    skillUsageCount,
  ];
}

class ComboProgress extends Equatable {
  final String comboId;
  final int successfulExecutions;
  final int totalAttempts;
  final double successRate;
  final DateTime firstExecution;
  final DateTime lastExecution;
  final Map<String, int> sequenceUsageCount;

  const ComboProgress({
    required this.comboId,
    required this.successfulExecutions,
    required this.totalAttempts,
    required this.successRate,
    required this.firstExecution,
    required this.lastExecution,
    required this.sequenceUsageCount,
  });

  @override
  List<Object?> get props => [
    comboId,
    successfulExecutions,
    totalAttempts,
    successRate,
    firstExecution,
    lastExecution,
    sequenceUsageCount,
  ];
}

class SkillSynergyService {
  static final Map<String, SkillSynergy> _synergies = {
    // Elemental Synergies
    'fire_mastery': SkillSynergy(
      id: 'fire_mastery',
      name: 'Fire Mastery',
      description: 'Mastery of fire magic enhances all fire-based abilities',
      type: SynergyType.elemental,
      requiredSkills: ['fire_bolt', 'fireball', 'flame_burst'],
      synergyBonuses: {
        'fire_damage': 0.25,
        'burn_chance': 0.15,
        'burn_duration': 0.5,
      },
      specialEffects: {
        'fire_immunity': 0.1,
        'phoenix_rebirth': 0.01,
      },
      activationThreshold: 3,
      icon: '🔥',
      color: Colors.red,
      lore: 'True masters of fire can control the very essence of flame.',
    ),
    
    'ice_mastery': SkillSynergy(
      id: 'ice_mastery',
      name: 'Ice Mastery',
      description: 'Mastery of ice magic enhances all ice-based abilities',
      type: SynergyType.elemental,
      requiredSkills: ['ice_shard', 'frost_nova', 'blizzard'],
      synergyBonuses: {
        'ice_damage': 0.25,
        'freeze_chance': 0.15,
        'freeze_duration': 0.5,
      },
      specialEffects: {
        'ice_immunity': 0.1,
        'eternal_winter': 0.01,
      },
      activationThreshold: 3,
      icon: '❄️',
      color: Colors.cyan,
      lore: 'The power of ice flows through those who master its secrets.',
    ),
    
    'lightning_mastery': SkillSynergy(
      id: 'lightning_mastery',
      name: 'Lightning Mastery',
      description: 'Mastery of lightning magic enhances all lightning-based abilities',
      type: SynergyType.elemental,
      requiredSkills: ['lightning_bolt', 'chain_lightning', 'thunder_storm'],
      synergyBonuses: {
        'lightning_damage': 0.25,
        'chain_chance': 0.2,
        'chain_targets': 2,
      },
      specialEffects: {
        'lightning_immunity': 0.1,
        'storm_caller': 0.01,
      },
      activationThreshold: 3,
      icon: '⚡',
      color: Colors.yellow,
      lore: 'Lightning strikes with the fury of the storm itself.',
    ),

    // Combat Synergies
    'weapon_mastery': SkillSynergy(
      id: 'weapon_mastery',
      name: 'Weapon Mastery',
      description: 'Mastery of weapons enhances all combat abilities',
      type: SynergyType.combat,
      requiredSkills: ['sword_mastery', 'axe_mastery', 'spear_mastery'],
      synergyBonuses: {
        'weapon_damage': 0.3,
        'critical_chance': 0.1,
        'critical_damage': 0.25,
      },
      specialEffects: {
        'weapon_switching': 0.5,
        'master_striker': 0.05,
      },
      activationThreshold: 3,
      icon: '⚔️',
      color: Colors.grey,
      lore: 'A true warrior masters all weapons, not just one.',
    ),
    
    'battle_tactics': SkillSynergy(
      id: 'battle_tactics',
      name: 'Battle Tactics',
      description: 'Advanced battle tactics enhance combat effectiveness',
      type: SynergyType.combat,
      requiredSkills: ['battle_cry', 'tactical_stance', 'warrior_spirit'],
      synergyBonuses: {
        'damage_dealt': 0.2,
        'damage_taken': -0.15,
        'initiative': 0.1,
      },
      specialEffects: {
        'battle_instinct': 0.1,
        'tactical_advantage': 0.05,
      },
      activationThreshold: 3,
      icon: '🎖️',
      color: Colors.brown,
      lore: 'Victory comes not from strength alone, but from tactical brilliance.',
    ),

    // Support Synergies
    'healing_mastery': SkillSynergy(
      id: 'healing_mastery',
      name: 'Healing Mastery',
      description: 'Mastery of healing magic enhances all support abilities',
      type: SynergyType.support,
      requiredSkills: ['heal', 'greater_heal', 'mass_heal'],
      synergyBonuses: {
        'healing_power': 0.3,
        'healing_efficiency': 0.2,
        'healing_range': 0.5,
      },
      specialEffects: {
        'auto_heal': 0.1,
        'divine_blessing': 0.05,
      },
      activationThreshold: 3,
      icon: '💚',
      color: Colors.green,
      lore: 'The power to heal is the greatest gift of all.',
    ),
    
    'protection_mastery': SkillSynergy(
      id: 'protection_mastery',
      name: 'Protection Mastery',
      description: 'Mastery of protective magic enhances defensive abilities',
      type: SynergyType.defensive,
      requiredSkills: ['shield', 'barrier', 'divine_protection'],
      synergyBonuses: {
        'damage_reduction': 0.25,
        'shield_strength': 0.3,
        'protection_duration': 0.5,
      },
      specialEffects: {
        'auto_shield': 0.1,
        'divine_guardian': 0.05,
      },
      activationThreshold: 3,
      icon: '🛡️',
      color: Colors.blue,
      lore: 'The best offense is a defense that cannot be broken.',
    ),
  };

  static final Map<String, SkillCombo> _combos = {
    // Chain Combos
    'fire_chain': SkillCombo(
      id: 'fire_chain',
      name: 'Fire Chain',
      description: 'Chain multiple fire spells for devastating effect',
      type: ComboType.chain,
      comboSequence: ['fire_bolt', 'fireball', 'flame_burst'],
      comboEffects: {
        'damage_multiplier': 2.5,
        'burn_chance': 0.3,
        'burn_duration': 2.0,
      },
      specialEffects: {
        'chain_reaction': 0.2,
        'inferno': 0.1,
      },
      comboMultiplier: 3,
      successRate: 0.8,
      icon: '🔥🔥🔥',
      color: Colors.red,
      lore: 'Fire feeds fire, creating an unstoppable inferno.',
    ),
    
    'ice_chain': SkillCombo(
      id: 'ice_chain',
      name: 'Ice Chain',
      description: 'Chain multiple ice spells for freezing effect',
      type: ComboType.chain,
      comboSequence: ['ice_shard', 'frost_nova', 'blizzard'],
      comboEffects: {
        'damage_multiplier': 2.0,
        'freeze_chance': 0.4,
        'freeze_duration': 3.0,
      },
      specialEffects: {
        'ice_prison': 0.15,
        'eternal_frost': 0.1,
      },
      comboMultiplier: 3,
      successRate: 0.8,
      icon: '❄️❄️❄️',
      color: Colors.cyan,
      lore: 'Ice upon ice creates an impenetrable prison of frost.',
    ),

    // Burst Combos
    'lightning_burst': SkillCombo(
      id: 'lightning_burst',
      name: 'Lightning Burst',
      description: 'Rapid lightning strikes for massive burst damage',
      type: ComboType.burst,
      comboSequence: ['lightning_bolt', 'chain_lightning', 'thunder_storm'],
      comboEffects: {
        'damage_multiplier': 3.0,
        'chain_targets': 5,
        'stun_chance': 0.25,
      },
      specialEffects: {
        'lightning_storm': 0.2,
        'thunder_god': 0.1,
      },
      comboMultiplier: 3,
      successRate: 0.7,
      icon: '⚡⚡⚡',
      color: Colors.yellow,
      lore: 'The fury of the storm unleashed in a single moment.',
    ),
    
    'weapon_burst': SkillCombo(
      id: 'weapon_burst',
      name: 'Weapon Burst',
      description: 'Rapid weapon strikes for devastating damage',
      type: ComboType.burst,
      comboSequence: ['quick_strike', 'power_strike', 'finishing_blow'],
      comboEffects: {
        'damage_multiplier': 2.5,
        'critical_chance': 0.3,
        'critical_damage': 0.5,
      },
      specialEffects: {
        'weapon_mastery': 0.2,
        'death_blow': 0.1,
      },
      comboMultiplier: 3,
      successRate: 0.75,
      icon: '⚔️⚔️⚔️',
      color: Colors.grey,
      lore: 'The perfect combination of speed, power, and precision.',
    ),

    // Sustained Combos
    'healing_sustained': SkillCombo(
      id: 'healing_sustained',
      name: 'Sustained Healing',
      description: 'Continuous healing for long-term support',
      type: ComboType.sustained,
      comboSequence: ['heal', 'renew', 'divine_favor'],
      comboEffects: {
        'healing_over_time': 2.0,
        'healing_duration': 3.0,
        'healing_efficiency': 0.5,
      },
      specialEffects: {
        'divine_blessing': 0.2,
        'immortality': 0.05,
      },
      comboMultiplier: 3,
      successRate: 0.9,
      icon: '💚💚💚',
      color: Colors.green,
      lore: 'The divine power of healing flows endlessly.',
    ),

    // Defensive Combos
    'protection_combo': SkillCombo(
      id: 'protection_combo',
      name: 'Protection Combo',
      description: 'Layered protection for maximum defense',
      type: ComboType.defensive,
      comboSequence: ['shield', 'barrier', 'divine_protection'],
      comboEffects: {
        'damage_reduction': 0.5,
        'shield_strength': 2.0,
        'protection_duration': 3.0,
      },
      specialEffects: {
        'invulnerability': 0.1,
        'divine_guardian': 0.2,
      },
      comboMultiplier: 3,
      successRate: 0.85,
      icon: '🛡️🛡️🛡️',
      color: Colors.blue,
      lore: 'Layered defenses create an impenetrable fortress.',
    ),

    // Ultimate Combos
    'elemental_mastery': SkillCombo(
      id: 'elemental_mastery',
      name: 'Elemental Mastery',
      description: 'Master all elements in a devastating combination',
      type: ComboType.ultimate,
      comboSequence: ['fire_mastery', 'ice_mastery', 'lightning_mastery'],
      comboEffects: {
        'all_elemental_damage': 3.0,
        'elemental_resistance': 0.5,
        'elemental_mastery': 1.0,
      },
      specialEffects: {
        'elemental_lord': 0.3,
        'reality_bending': 0.1,
      },
      comboMultiplier: 5,
      successRate: 0.5,
      icon: '🌪️',
      color: Colors.purple,
      lore: 'The ultimate mastery of all elements combined.',
    ),
  };

  static SkillSynergy getSynergy(String id) {
    return _synergies[id] ?? _synergies['fire_mastery']!;
  }

  static SkillCombo getCombo(String id) {
    return _combos[id] ?? _combos['fire_chain']!;
  }

  static List<SkillSynergy> getSynergiesByType(SynergyType type) {
    return _synergies.values.where((s) => s.type == type).toList();
  }

  static List<SkillCombo> getCombosByType(ComboType type) {
    return _combos.values.where((c) => c.type == type).toList();
  }

  static List<SkillSynergy> getAllSynergies() {
    return _synergies.values.toList();
  }

  static List<SkillCombo> getAllCombos() {
    return _combos.values.toList();
  }

  static bool canActivateSynergy(SkillSynergy synergy, List<String> unlockedSkills) {
    final requiredCount = synergy.activationThreshold;
    final unlockedCount = synergy.requiredSkills
        .where((skill) => unlockedSkills.contains(skill))
        .length;
    
    return unlockedCount >= requiredCount;
  }

  static bool canExecuteCombo(SkillCombo combo, List<String> unlockedSkills) {
    return combo.comboSequence.every((skill) => unlockedSkills.contains(skill));
  }

  static Map<String, double> calculateSynergyBonuses(SkillSynergy synergy, int activationLevel) {
    final bonuses = <String, double>{};
    
    // Apply base synergy bonuses
    for (final entry in synergy.synergyBonuses.entries) {
      bonuses[entry.key] = entry.value * activationLevel;
    }
    
    // Apply special effects
    for (final entry in synergy.specialEffects.entries) {
      if (entry.value is double) {
        bonuses[entry.key] = (entry.value as double) * activationLevel;
      } else {
        bonuses[entry.key] = entry.value.toDouble();
      }
    }
    
    return bonuses;
  }

  static Map<String, double> calculateComboEffects(SkillCombo combo, int comboLevel) {
    final effects = <String, double>{};
    
    // Apply combo effects
    for (final entry in combo.comboEffects.entries) {
      effects[entry.key] = entry.value * comboLevel;
    }
    
    // Apply special effects
    for (final entry in combo.specialEffects.entries) {
      if (entry.value is double) {
        effects[entry.key] = (entry.value as double) * comboLevel;
      } else {
        effects[entry.key] = entry.value.toDouble();
      }
    }
    
    return effects;
  }

  static double calculateComboSuccessRate(SkillCombo combo, int playerLevel, int comboMastery) {
    double baseRate = combo.successRate;
    
    // Player level bonus
    baseRate += (playerLevel * 0.01);
    
    // Combo mastery bonus
    baseRate += (comboMastery * 0.02);
    
    // Ensure rate is between 0.1 and 0.95
    return baseRate.clamp(0.1, 0.95);
  }

  static List<SkillSynergy> getAvailableSynergies(List<String> unlockedSkills) {
    return _synergies.values
        .where((synergy) => canActivateSynergy(synergy, unlockedSkills))
        .toList();
  }

  static List<SkillCombo> getAvailableCombos(List<String> unlockedSkills) {
    return _combos.values
        .where((combo) => canExecuteCombo(combo, unlockedSkills))
        .toList();
  }

  static List<String> getSynergyRecommendations(List<String> unlockedSkills) {
    final recommendations = <String>[];
    
    for (final synergy in _synergies.values) {
      if (!canActivateSynergy(synergy, unlockedSkills)) {
        final missingSkills = synergy.requiredSkills
            .where((skill) => !unlockedSkills.contains(skill))
            .toList();
        
        if (missingSkills.length <= 2) {
          recommendations.add('${synergy.name}: Missing ${missingSkills.join(', ')}');
        }
      }
    }
    
    return recommendations;
  }

  static List<String> getComboRecommendations(List<String> unlockedSkills) {
    final recommendations = <String>[];
    
    for (final combo in _combos.values) {
      if (!canExecuteCombo(combo, unlockedSkills)) {
        final missingSkills = combo.comboSequence
            .where((skill) => !unlockedSkills.contains(skill))
            .toList();
        
        if (missingSkills.length <= 2) {
          recommendations.add('${combo.name}: Missing ${missingSkills.join(', ')}');
        }
      }
    }
    
    return recommendations;
  }
}
