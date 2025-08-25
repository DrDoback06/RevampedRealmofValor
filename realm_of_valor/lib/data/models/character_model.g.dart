// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CharacterStats _$CharacterStatsFromJson(Map<String, dynamic> json) =>
    CharacterStats(
      strength: (json['strength'] as num?)?.toInt() ?? 5,
      agility: (json['agility'] as num?)?.toInt() ?? 5,
      intelligence: (json['intelligence'] as num?)?.toInt() ?? 5,
      vitality: (json['vitality'] as num?)?.toInt() ?? 5,
    );

Map<String, dynamic> _$CharacterStatsToJson(CharacterStats instance) =>
    <String, dynamic>{
      'strength': instance.strength,
      'agility': instance.agility,
      'intelligence': instance.intelligence,
      'vitality': instance.vitality,
    };

EquipmentSlots _$EquipmentSlotsFromJson(Map<String, dynamic> json) =>
    EquipmentSlots(
      head: json['head'] as String?,
      chest: json['chest'] as String?,
      legs: json['legs'] as String?,
      weapon: json['weapon'] as String?,
      offhand: json['offhand'] as String?,
      ring: json['ring'] as String?,
      amulet: json['amulet'] as String?,
    );

Map<String, dynamic> _$EquipmentSlotsToJson(EquipmentSlots instance) =>
    <String, dynamic>{
      'head': instance.head,
      'chest': instance.chest,
      'legs': instance.legs,
      'weapon': instance.weapon,
      'offhand': instance.offhand,
      'ring': instance.ring,
      'amulet': instance.amulet,
    };

Character _$CharacterFromJson(Map<String, dynamic> json) => Character(
      uid: json['uid'] as String,
      id: json['id'] as String,
      name: json['name'] as String,
      level: (json['level'] as num?)?.toInt() ?? 1,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      stats: json['stats'] == null
          ? const CharacterStats()
          : CharacterStats.fromJson(json['stats'] as Map<String, dynamic>),
      equipment: json['equipment'] == null
          ? const EquipmentSlots()
          : EquipmentSlots.fromJson(json['equipment'] as Map<String, dynamic>),
      skillPoints: (json['skillPoints'] as num?)?.toInt() ?? 0,
      unlockedSkills: (json['unlockedSkills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$CharacterToJson(Character instance) => <String, dynamic>{
      'uid': instance.uid,
      'id': instance.id,
      'name': instance.name,
      'level': instance.level,
      'xp': instance.xp,
      'stats': instance.stats,
      'equipment': instance.equipment,
      'skillPoints': instance.skillPoints,
      'unlockedSkills': instance.unlockedSkills,
    };
