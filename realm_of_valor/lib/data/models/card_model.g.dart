// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameCard _$GameCardFromJson(Map<String, dynamic> json) => GameCard(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$CardTypeEnumMap, json['type']),
      rarity: $enumDecode(_$CardRarityEnumMap, json['rarity']),
      element: $enumDecodeNullable(_$CardElementEnumMap, json['element']) ??
          CardElement.none,
      level: (json['level'] as num?)?.toInt() ?? 1,
      manaCost: (json['manaCost'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String?,
      stats: json['stats'] as Map<String, dynamic>?,
      abilities: (json['abilities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      effects: json['effects'] as Map<String, dynamic>?,
      flavorText: json['flavorText'] as String?,
      artist: json['artist'] as String?,
      set: json['set'] as String?,
      series: json['series'] as String?,
      isCollectible: json['isCollectible'] as bool? ?? true,
      isTradeable: json['isTradeable'] as bool? ?? true,
      maxStack: (json['maxStack'] as num?)?.toInt() ?? 1,
      qrCode: json['qrCode'] as String?,
      releaseDate: json['releaseDate'] == null
          ? null
          : DateTime.parse(json['releaseDate'] as String),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$GameCardToJson(GameCard instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$CardTypeEnumMap[instance.type]!,
      'rarity': _$CardRarityEnumMap[instance.rarity]!,
      'element': _$CardElementEnumMap[instance.element]!,
      'level': instance.level,
      'manaCost': instance.manaCost,
      'imageUrl': instance.imageUrl,
      'stats': instance.stats,
      'abilities': instance.abilities,
      'effects': instance.effects,
      'flavorText': instance.flavorText,
      'artist': instance.artist,
      'set': instance.set,
      'series': instance.series,
      'isCollectible': instance.isCollectible,
      'isTradeable': instance.isTradeable,
      'maxStack': instance.maxStack,
      'qrCode': instance.qrCode,
      'releaseDate': instance.releaseDate?.toIso8601String(),
      'tags': instance.tags,
      'metadata': instance.metadata,
    };

const _$CardTypeEnumMap = {
  CardType.item: 'item',
  CardType.spell: 'spell',
  CardType.skill: 'skill',
  CardType.quest: 'quest',
  CardType.character: 'character',
  CardType.monster: 'monster',
  CardType.equipment: 'equipment',
  CardType.consumable: 'consumable',
  CardType.artifact: 'artifact',
  CardType.legendary: 'legendary',
  CardType.event: 'event',
  CardType.location: 'location',
  CardType.companion: 'companion',
  CardType.mount: 'mount',
  CardType.pet: 'pet',
  CardType.title: 'title',
  CardType.emote: 'emote',
  CardType.currency: 'currency',
  CardType.material: 'material',
  CardType.recipe: 'recipe',
};

const _$CardRarityEnumMap = {
  CardRarity.common: 'common',
  CardRarity.uncommon: 'uncommon',
  CardRarity.rare: 'rare',
  CardRarity.epic: 'epic',
  CardRarity.legendary: 'legendary',
  CardRarity.mythic: 'mythic',
};

const _$CardElementEnumMap = {
  CardElement.none: 'none',
  CardElement.fire: 'fire',
  CardElement.water: 'water',
  CardElement.earth: 'earth',
  CardElement.air: 'air',
  CardElement.light: 'light',
  CardElement.dark: 'dark',
  CardElement.lightning: 'lightning',
  CardElement.ice: 'ice',
  CardElement.nature: 'nature',
  CardElement.arcane: 'arcane',
};

CardCollection _$CardCollectionFromJson(Map<String, dynamic> json) =>
    CardCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      cards: (json['cards'] as List<dynamic>)
          .map((e) => GameCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      minRarity: $enumDecode(_$CardRarityEnumMap, json['minRarity']),
      maxRarity: $enumDecode(_$CardRarityEnumMap, json['maxRarity']),
      theme: json['theme'] as String?,
      releaseDate: DateTime.parse(json['releaseDate'] as String),
      isLimited: json['isLimited'] as bool? ?? false,
      totalCards: (json['totalCards'] as num).toInt(),
      collectedCards: (json['collectedCards'] as num).toInt(),
    );

Map<String, dynamic> _$CardCollectionToJson(CardCollection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'cards': instance.cards,
      'minRarity': _$CardRarityEnumMap[instance.minRarity]!,
      'maxRarity': _$CardRarityEnumMap[instance.maxRarity]!,
      'theme': instance.theme,
      'releaseDate': instance.releaseDate.toIso8601String(),
      'isLimited': instance.isLimited,
      'totalCards': instance.totalCards,
      'collectedCards': instance.collectedCards,
    };

CardDeck _$CardDeckFromJson(Map<String, dynamic> json) => CardDeck(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      cards: (json['cards'] as List<dynamic>)
          .map((e) => GameCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      maxCards: (json['maxCards'] as num?)?.toInt() ?? 30,
      theme: json['theme'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] == null
          ? null
          : DateTime.parse(json['lastModified'] as String),
    );

Map<String, dynamic> _$CardDeckToJson(CardDeck instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'cards': instance.cards,
      'maxCards': instance.maxCards,
      'theme': instance.theme,
      'isPublic': instance.isPublic,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastModified': instance.lastModified?.toIso8601String(),
    };
