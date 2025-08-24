import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'character_model.g.dart';

@JsonSerializable()
class CharacterStats extends Equatable {
  const CharacterStats({
    this.strength = 5,
    this.agility = 5,
    this.intelligence = 5,
    this.vitality = 5,
  });

  final int strength;
  final int agility;
  final int intelligence;
  final int vitality;

  factory CharacterStats.fromJson(Map<String, dynamic> json) => _$CharacterStatsFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterStatsToJson(this);

  @override
  List<Object?> get props => [strength, agility, intelligence, vitality];
}

@JsonSerializable()
class EquipmentSlots extends Equatable {
  const EquipmentSlots({
    this.head,
    this.chest,
    this.legs,
    this.weapon,
    this.offhand,
    this.ring,
    this.amulet,
  });

  final String? head;
  final String? chest;
  final String? legs;
  final String? weapon;
  final String? offhand;
  final String? ring;
  final String? amulet;

  factory EquipmentSlots.fromJson(Map<String, dynamic> json) => _$EquipmentSlotsFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentSlotsToJson(this);

  @override
  List<Object?> get props => [head, chest, legs, weapon, offhand, ring, amulet];
}

@JsonSerializable()
class Character extends Equatable {
  const Character({
    required this.uid,
    required this.id,
    required this.name,
    this.level = 1,
    this.xp = 0,
    this.stats = const CharacterStats(),
    this.equipment = const EquipmentSlots(),
    this.skillPoints = 0,
    this.unlockedSkills = const <String>[],
  });

  final String uid;
  final String id; // character id
  final String name;
  final int level;
  final int xp;
  final CharacterStats stats;
  final EquipmentSlots equipment;
  final int skillPoints;
  final List<String> unlockedSkills;

  factory Character.fromJson(Map<String, dynamic> json) => _$CharacterFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterToJson(this);

  @override
  List<Object?> get props => [uid, id, name, level, xp, stats, equipment, skillPoints, unlockedSkills];
}