// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'effects_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Effect _$EffectFromJson(Map<String, dynamic> json) => Effect(
      id: json['id'] as String,
      type: $enumDecode(_$EffectTypeEnumMap, json['type']),
      modifiers: Map<String, num>.from(json['modifiers'] as Map),
      durationTurns: (json['durationTurns'] as num?)?.toInt(),
    );

Map<String, dynamic> _$EffectToJson(Effect instance) => <String, dynamic>{
      'id': instance.id,
      'type': _$EffectTypeEnumMap[instance.type]!,
      'modifiers': instance.modifiers,
      'durationTurns': instance.durationTurns,
    };

const _$EffectTypeEnumMap = {
  EffectType.buff: 'buff',
  EffectType.debuff: 'debuff',
  EffectType.dot: 'dot',
  EffectType.hot: 'hot',
  EffectType.shield: 'shield',
};
