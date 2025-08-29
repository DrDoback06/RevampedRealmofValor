import '../../../data/models/card_model.dart';
import 'dart:ui';

enum SkillSpecialization {
  combat,
  magic,
  support,
  hybrid,
}

class SkillNode {
  final String id;
  final String name;
  final String description;
  final int tier;
  final Offset position;
  final int requiredSkillPoints;
  final CardType cardType;
  final CardElement element;
  final List<String> prerequisites;
  final SkillSpecialization? specialization;
  final int masteryLevel;
  final int maxMasteryLevel;
  final List<String> synergies;

  const SkillNode({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.position,
    required this.requiredSkillPoints,
    required this.cardType,
    required this.element,
    this.prerequisites = const [],
    this.specialization,
    this.masteryLevel = 0,
    this.maxMasteryLevel = 5,
    this.synergies = const [],
  });

  bool get isUnlocked => masteryLevel > 0;
  bool get isMaxed => masteryLevel >= maxMasteryLevel;
  double get masteryProgress => (masteryLevel / maxMasteryLevel) * 100;
}

class SkillProgress {
  final String skillId;
  final String skillName;
  final DateTime unlockDate;
  final int usageCount;
  final double masteryProgress;

  const SkillProgress({
    required this.skillId,
    required this.skillName,
    required this.unlockDate,
    required this.usageCount,
    required this.masteryProgress,
  });
}

class SkillBuild {
  final String name;
  final String description;
  final List<String> skills;
  final int totalPoints;
  final List<String> specializations;
  final DateTime createdAt;

  const SkillBuild({
    required this.name,
    required this.description,
    required this.skills,
    required this.totalPoints,
    required this.specializations,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'skills': skills,
      'total_points': totalPoints,
      'specializations': specializations,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SkillBuild.fromJson(Map<String, dynamic> json) {
    return SkillBuild(
      name: json['name'] as String,
      description: json['description'] as String,
      skills: List<String>.from(json['skills']),
      totalPoints: json['total_points'] as int,
      specializations: List<String>.from(json['specializations']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class CharacterStats {
  final int strength;
  final int dexterity;
  final int intelligence;
  final int vitality;
  final int charisma;
  final int luck;

  const CharacterStats({
    required this.strength,
    required this.dexterity,
    required this.intelligence,
    required this.vitality,
    required this.charisma,
    required this.luck,
  });

  int get totalStats => strength + dexterity + intelligence + vitality + charisma + luck;
  
  CharacterStats copyWith({
    int? strength,
    int? dexterity,
    int? intelligence,
    int? vitality,
    int? charisma,
    int? luck,
  }) {
    return CharacterStats(
      strength: strength ?? this.strength,
      dexterity: dexterity ?? this.dexterity,
      intelligence: intelligence ?? this.intelligence,
      vitality: vitality ?? this.vitality,
      charisma: charisma ?? this.charisma,
      luck: luck ?? this.luck,
    );
  }
}

class CharacterProgression {
  final int level;
  final int experience;
  final int experienceToNext;
  final int skillPoints;
  final List<String> unlockedSkills;
  final Map<String, int> skillMastery;

  const CharacterProgression({
    required this.level,
    required this.experience,
    required this.experienceToNext,
    required this.skillPoints,
    required this.unlockedSkills,
    required this.skillMastery,
  });

  double get levelProgress => experience / experienceToNext;
  bool get canLevelUp => experience >= experienceToNext;
  
  CharacterProgression copyWith({
    int? level,
    int? experience,
    int? experienceToNext,
    int? skillPoints,
    List<String>? unlockedSkills,
    Map<String, int>? skillMastery,
  }) {
    return CharacterProgression(
      level: level ?? this.level,
      experience: experience ?? this.experience,
      experienceToNext: experienceToNext ?? this.experienceToNext,
      skillPoints: skillPoints ?? this.skillPoints,
      unlockedSkills: unlockedSkills ?? this.unlockedSkills,
      skillMastery: skillMastery ?? this.skillMastery,
    );
  }
}
