import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum CharacterClass {
  warrior,
  mage,
  rogue,
  cleric,
  ranger,
  paladin,
  warlock,
  monk,
}

enum ClassSpecialization {
  // Warrior specializations
  berserker,
  guardian,
  weaponMaster,
  
  // Mage specializations
  elementalist,
  necromancer,
  illusionist,
  
  // Rogue specializations
  assassin,
  scout,
  trickster,
  
  // Cleric specializations
  healer,
  battlePriest,
  divineMage,
  
  // Ranger specializations
  beastMaster,
  marksman,
  survivalist,
  
  // Paladin specializations
  holyWarrior,
  protector,
  avenger,
  
  // Warlock specializations
  demonologist,
  soulBinder,
  chaosMage,
  
  // Monk specializations
  martialArtist,
  spiritualist,
  shadowDancer,
}

class CharacterClassData extends Equatable {
  final CharacterClass characterClass;
  final String name;
  final String description;
  final String lore;
  final Map<String, int> baseStats;
  final Map<String, int> statGrowth;
  final List<String> startingSkills;
  final List<String> classAbilities;
  final Map<String, dynamic> classPassives;
  final List<ClassSpecialization> availableSpecializations;
  final String classIcon;
  final String classColor;

  const CharacterClassData({
    required this.characterClass,
    required this.name,
    required this.description,
    required this.lore,
    required this.baseStats,
    required this.statGrowth,
    required this.startingSkills,
    required this.classAbilities,
    required this.classPassives,
    required this.availableSpecializations,
    required this.classIcon,
    required this.classColor,
  });

  @override
  List<Object?> get props => [
    characterClass,
    name,
    description,
    lore,
    baseStats,
    statGrowth,
    startingSkills,
    classAbilities,
    classPassives,
    availableSpecializations,
    classIcon,
    classColor,
  ];
}

class ClassSpecializationData extends Equatable {
  final ClassSpecialization specialization;
  final String name;
  final String description;
  final String lore;
  final Map<String, int> statBonuses;
  final List<String> specializationSkills;
  final Map<String, dynamic> specializationPassives;
  final List<String> uniqueAbilities;
  final int requiredLevel;
  final List<String> prerequisites;
  final String specializationIcon;
  final String specializationColor;

  const ClassSpecializationData({
    required this.specialization,
    required this.name,
    required this.description,
    required this.lore,
    required this.statBonuses,
    required this.specializationSkills,
    required this.specializationPassives,
    required this.uniqueAbilities,
    required this.requiredLevel,
    required this.prerequisites,
    required this.specializationIcon,
    required this.specializationColor,
  });

  @override
  List<Object?> get props => [
    specialization,
    name,
    description,
    lore,
    statBonuses,
    specializationSkills,
    specializationPassives,
    uniqueAbilities,
    requiredLevel,
    prerequisites,
    specializationIcon,
    specializationColor,
  ];
}

class CharacterClassProgression extends Equatable {
  final CharacterClass characterClass;
  final ClassSpecialization? specialization;
  final int classLevel;
  final int classExperience;
  final Map<String, int> classSkillLevels;
  final List<String> unlockedClassAbilities;
  final Map<String, dynamic> classPassiveEffects;
  final DateTime specializationDate;

  const CharacterClassProgression({
    required this.characterClass,
    this.specialization,
    required this.classLevel,
    required this.classExperience,
    required this.classSkillLevels,
    required this.unlockedClassAbilities,
    required this.classPassiveEffects,
    required this.specializationDate,
  });

  @override
  List<Object?> get props => [
    characterClass,
    specialization,
    classLevel,
    classExperience,
    classSkillLevels,
    unlockedClassAbilities,
    classPassiveEffects,
    specializationDate,
  ];
}

class CharacterClassService {
  static final Map<CharacterClass, CharacterClassData> _classData = {
    CharacterClass.warrior: CharacterClassData(
      characterClass: CharacterClass.warrior,
      name: 'Warrior',
      description: 'A mighty warrior skilled in close combat and heavy armor.',
      lore: 'Warriors are the backbone of any army, trained in the art of war and combat.',
      baseStats: {
        'strength': 15,
        'dexterity': 8,
        'intelligence': 5,
        'vitality': 12,
        'charisma': 6,
        'luck': 4,
      },
      statGrowth: {
        'strength': 3,
        'dexterity': 1,
        'intelligence': 1,
        'vitality': 2,
        'charisma': 1,
        'luck': 1,
      },
      startingSkills: ['basic_attack', 'basic_defense', 'warrior_stance'],
      classAbilities: ['battle_cry', 'shield_bash', 'weapon_mastery'],
      classPassives: {
        'armor_mastery': 'Reduces damage taken by 10%',
        'weapon_expertise': 'Increases weapon damage by 15%',
        'battle_hardened': 'Gains 5% damage resistance per level',
      },
      availableSpecializations: [
        ClassSpecialization.berserker,
        ClassSpecialization.guardian,
        ClassSpecialization.weaponMaster,
      ],
      classIcon: '⚔️',
      classColor: '#8B4513',
    ),
    
    CharacterClass.mage: CharacterClassData(
      characterClass: CharacterClass.mage,
      name: 'Mage',
      description: 'A powerful spellcaster who wields the forces of magic.',
      lore: 'Mages study the arcane arts, mastering spells and magical theory.',
      baseStats: {
        'strength': 4,
        'dexterity': 6,
        'intelligence': 18,
        'vitality': 8,
        'charisma': 8,
        'luck': 6,
      },
      statGrowth: {
        'strength': 1,
        'dexterity': 1,
        'intelligence': 3,
        'vitality': 1,
        'charisma': 2,
        'luck': 2,
      },
      startingSkills: ['mana_control', 'basic_spell', 'meditation'],
      classAbilities: ['fireball', 'ice_shield', 'teleport'],
      classPassives: {
        'mana_affinity': 'Increases mana regeneration by 20%',
        'spell_mastery': 'Reduces spell cooldowns by 10%',
        'arcane_knowledge': 'Increases spell damage by 15%',
      },
      availableSpecializations: [
        ClassSpecialization.elementalist,
        ClassSpecialization.necromancer,
        ClassSpecialization.illusionist,
      ],
      classIcon: '🔮',
      classColor: '#4B0082',
    ),
    
    CharacterClass.rogue: CharacterClassData(
      characterClass: CharacterClass.rogue,
      name: 'Rogue',
      description: 'A stealthy fighter who excels in agility and precision.',
      lore: 'Rogues move in shadows, striking from the darkness with deadly precision.',
      baseStats: {
        'strength': 6,
        'dexterity': 16,
        'intelligence': 8,
        'vitality': 8,
        'charisma': 10,
        'luck': 12,
      },
      statGrowth: {
        'strength': 1,
        'dexterity': 3,
        'intelligence': 1,
        'vitality': 1,
        'charisma': 2,
        'luck': 2,
      },
      startingSkills: ['stealth', 'backstab', 'lockpicking'],
      classAbilities: ['shadow_step', 'poison_dagger', 'smoke_bomb'],
      classPassives: {
        'shadow_mastery': 'Increases stealth effectiveness by 25%',
        'critical_expertise': 'Increases critical hit chance by 15%',
        'agile_movement': 'Increases movement speed by 10%',
      },
      availableSpecializations: [
        ClassSpecialization.assassin,
        ClassSpecialization.scout,
        ClassSpecialization.trickster,
      ],
      classIcon: '🗡️',
      classColor: '#2F4F4F',
    ),
  };

  static final Map<ClassSpecialization, ClassSpecializationData> _specializationData = {
    ClassSpecialization.berserker: ClassSpecializationData(
      specialization: ClassSpecialization.berserker,
      name: 'Berserker',
      description: 'A furious warrior who gains power through rage and battle.',
      lore: 'Berserkers channel their inner fury to become unstoppable forces of destruction.',
      statBonuses: {
        'strength': 5,
        'vitality': 3,
        'dexterity': 2,
      },
      specializationSkills: ['rage_mode', 'blood_frenzy', 'berserker_rage'],
      specializationPassives: {
        'battle_fury': 'Increases damage by 20% when below 50% health',
        'unstoppable': 'Cannot be stunned or knocked back',
        'blood_lust': 'Heals for 5% of damage dealt',
      },
      uniqueAbilities: ['berserker_ultimate'],
      requiredLevel: 10,
      prerequisites: ['warrior_stance'],
      specializationIcon: '😤',
      specializationColor: '#DC143C',
    ),
    
    ClassSpecialization.elementalist: ClassSpecializationData(
      specialization: ClassSpecialization.elementalist,
      name: 'Elementalist',
      description: 'A mage who commands the raw forces of nature.',
      lore: 'Elementalists bend fire, water, earth, and air to their will.',
      statBonuses: {
        'intelligence': 5,
        'charisma': 3,
        'dexterity': 2,
      },
      specializationSkills: ['elemental_burst', 'elemental_shield', 'elemental_mastery'],
      specializationPassives: {
        'elemental_affinity': 'Increases elemental damage by 25%',
        'elemental_resistance': 'Reduces elemental damage taken by 15%',
        'elemental_attunement': 'Spells have a 20% chance to trigger twice',
      },
      uniqueAbilities: ['elemental_storm'],
      requiredLevel: 10,
      prerequisites: ['mana_control'],
      specializationIcon: '🌪️',
      specializationColor: '#00CED1',
    ),
    
    ClassSpecialization.assassin: ClassSpecializationData(
      specialization: ClassSpecialization.assassin,
      name: 'Assassin',
      description: 'A deadly rogue who specializes in eliminating targets.',
      lore: 'Assassins are masters of death, striking with precision and disappearing without a trace.',
      statBonuses: {
        'dexterity': 5,
        'luck': 3,
        'strength': 2,
      },
      specializationSkills: ['death_mark', 'shadow_assault', 'silent_kill'],
      specializationPassives: {
        'lethal_precision': 'Critical hits deal 50% more damage',
        'shadow_walk': 'Can move through shadows undetected',
        'death_touch': 'Attacks have a 10% chance to instantly kill weak enemies',
      },
      uniqueAbilities: ['assassination'],
      requiredLevel: 10,
      prerequisites: ['stealth'],
      specializationIcon: '💀',
      specializationColor: '#000000',
    ),
  };

  static CharacterClassData getClassData(CharacterClass characterClass) {
    return _classData[characterClass] ?? _classData[CharacterClass.warrior]!;
  }

  static ClassSpecializationData getSpecializationData(ClassSpecialization specialization) {
    return _specializationData[specialization] ?? 
           _specializationData[ClassSpecialization.berserker]!;
  }

  static List<CharacterClassData> getAllClasses() {
    return _classData.values.toList();
  }

  static List<ClassSpecializationData> getSpecializationsForClass(CharacterClass characterClass) {
    final classData = getClassData(characterClass);
    return classData.availableSpecializations
        .map((spec) => getSpecializationData(spec))
        .toList();
  }

  static bool canSpecialize(CharacterClass characterClass, ClassSpecialization specialization, int level, List<String> unlockedSkills) {
    final specData = getSpecializationData(specialization);
    final classData = getClassData(characterClass);
    
    if (!classData.availableSpecializations.contains(specialization)) {
      return false;
    }
    
    if (level < specData.requiredLevel) {
      return false;
    }
    
    for (final prerequisite in specData.prerequisites) {
      if (!unlockedSkills.contains(prerequisite)) {
        return false;
      }
    }
    
    return true;
  }

  static Map<String, int> calculateTotalStats(CharacterClass characterClass, ClassSpecialization? specialization, int level) {
    final classData = getClassData(characterClass);
    final baseStats = Map<String, int>.from(classData.baseStats);
    
    // Add stat growth from levels
    for (final entry in classData.statGrowth.entries) {
      baseStats[entry.key] = (baseStats[entry.key] ?? 0) + (entry.value * (level - 1));
    }
    
    // Add specialization bonuses
    if (specialization != null) {
      final specData = getSpecializationData(specialization);
      for (final entry in specData.statBonuses.entries) {
        baseStats[entry.key] = (baseStats[entry.key] ?? 0) + entry.value;
      }
    }
    
    return baseStats;
  }
}
