// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameCard _$GameCardFromJson(Map<String, dynamic> json) => GameCard(
  id: json['id'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$CardTypeEnumMap, json['type']),
  rarity: $enumDecode(_$CardRarityEnumMap, json['rarity']),
  allowedClasses: (json['allowedClasses'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  stats: (json['stats'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as num),
  ),
  lore: json['lore'] as String?,
);

Map<String, dynamic> _$GameCardToJson(GameCard instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$CardTypeEnumMap[instance.type]!,
  'rarity': _$CardRarityEnumMap[instance.rarity]!,
  'allowedClasses': instance.allowedClasses,
  'stats': instance.stats,
  'lore': instance.lore,
};

const _$CardTypeEnumMap = {
  CardType.weapon: 'weapon',
  CardType.armor: 'armor',
  CardType.spell: 'spell',
  CardType.consumable: 'consumable',
  CardType.misc: 'misc',
};

const _$CardRarityEnumMap = {
  CardRarity.common: 'common',
  CardRarity.uncommon: 'uncommon',
  CardRarity.rare: 'rare',
  CardRarity.epic: 'epic',
  CardRarity.legendary: 'legendary',
};
