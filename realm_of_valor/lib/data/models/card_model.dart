import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'card_model.g.dart';

enum CardType {
  item,
  spell,
  skill,
  quest,
  character,
  monster,
  equipment,
  consumable,
  artifact,
  legendary,
  event,
  location,
  companion,
  mount,
  pet,
  title,
  emote,
  currency,
  material,
  recipe,
}

enum CardRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

enum CardElement {
  none,
  fire,
  water,
  earth,
  air,
  light,
  dark,
  lightning,
  ice,
  nature,
  arcane,
}

@JsonSerializable()
class GameCard {
  final String id;
  final String name;
  final String description;
  final CardType type;
  final CardRarity rarity;
  final CardElement element;
  final int level;
  final int manaCost;
  final String? imageUrl;
  final Map<String, dynamic>? stats;
  final List<String>? abilities;
  final Map<String, dynamic>? effects;
  final String? flavorText;
  final String? artist;
  final String? set;
  final String? series;
  final bool isCollectible;
  final bool isTradeable;
  final int maxStack;
  final String? qrCode;
  final DateTime? releaseDate;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;

  GameCard({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    this.element = CardElement.none,
    this.level = 1,
    this.manaCost = 0,
    this.imageUrl,
    this.stats,
    this.abilities,
    this.effects,
    this.flavorText,
    this.artist,
    this.set,
    this.series,
    this.isCollectible = true,
    this.isTradeable = true,
    this.maxStack = 1,
    this.qrCode,
    this.releaseDate,
    this.tags,
    this.metadata,
  });

  factory GameCard.fromJson(Map<String, dynamic> json) => _$GameCardFromJson(json);
  Map<String, dynamic> toJson() => _$GameCardToJson(this);

  GameCard copyWith({
    String? id,
    String? name,
    String? description,
    CardType? type,
    CardRarity? rarity,
    CardElement? element,
    int? level,
    int? manaCost,
    String? imageUrl,
    Map<String, dynamic>? stats,
    List<String>? abilities,
    Map<String, dynamic>? effects,
    String? flavorText,
    String? artist,
    String? set,
    String? series,
    bool? isCollectible,
    bool? isTradeable,
    int? maxStack,
    String? qrCode,
    DateTime? releaseDate,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return GameCard(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      element: element ?? this.element,
      level: level ?? this.level,
      manaCost: manaCost ?? this.manaCost,
      imageUrl: imageUrl ?? this.imageUrl,
      stats: stats ?? this.stats,
      abilities: abilities ?? this.abilities,
      effects: effects ?? this.effects,
      flavorText: flavorText ?? this.flavorText,
      artist: artist ?? this.artist,
      set: set ?? this.set,
      series: series ?? this.series,
      isCollectible: isCollectible ?? this.isCollectible,
      isTradeable: isTradeable ?? this.isTradeable,
      maxStack: maxStack ?? this.maxStack,
      qrCode: qrCode ?? this.qrCode,
      releaseDate: releaseDate ?? this.releaseDate,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  String get rarityColor {
    switch (rarity) {
      case CardRarity.common:
        return '#9D9D9D';
      case CardRarity.uncommon:
        return '#1EFF00';
      case CardRarity.rare:
        return '#0070DD';
      case CardRarity.epic:
        return '#A335EE';
      case CardRarity.legendary:
        return '#FF8000';
      case CardRarity.mythic:
        return '#E5CC80';
    }
  }

  String get elementIcon {
    switch (element) {
      case CardElement.none:
        return '⚪';
      case CardElement.fire:
        return '🔥';
      case CardElement.water:
        return '💧';
      case CardElement.earth:
        return '🌍';
      case CardElement.air:
        return '💨';
      case CardElement.light:
        return '☀️';
      case CardElement.dark:
        return '🌙';
      case CardElement.lightning:
        return '⚡';
      case CardElement.ice:
        return '❄️';
      case CardElement.nature:
        return '🌿';
      case CardElement.arcane:
        return '✨';
    }
  }

  bool get isEquipment => type == CardType.equipment;
  bool get isConsumable => type == CardType.consumable;
  bool get isSpell => type == CardType.spell;
  bool get isSkill => type == CardType.skill;
  bool get isQuest => type == CardType.quest;
  bool get isMonster => type == CardType.monster;
  bool get isCharacter => type == CardType.character;
}

@JsonSerializable()
class CardCollection {
  final String id;
  final String name;
  final String description;
  final List<GameCard> cards;
  final CardRarity minRarity;
  final CardRarity maxRarity;
  final String? theme;
  final DateTime releaseDate;
  final bool isLimited;
  final int totalCards;
  final int collectedCards;

  CardCollection({
    required this.id,
    required this.name,
    required this.description,
    required this.cards,
    required this.minRarity,
    required this.maxRarity,
    this.theme,
    required this.releaseDate,
    this.isLimited = false,
    required this.totalCards,
    required this.collectedCards,
  });

  factory CardCollection.fromJson(Map<String, dynamic> json) => _$CardCollectionFromJson(json);
  Map<String, dynamic> toJson() => _$CardCollectionToJson(this);

  double get completionPercentage => (collectedCards / totalCards) * 100;
}

@JsonSerializable()
class CardDeck {
  final String id;
  final String name;
  final String description;
  final List<GameCard> cards;
  final int maxCards;
  final String? theme;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime? lastModified;

  CardDeck({
    required this.id,
    required this.name,
    required this.description,
    required this.cards,
    this.maxCards = 30,
    this.theme,
    this.isPublic = false,
    required this.createdAt,
    this.lastModified,
  });

  factory CardDeck.fromJson(Map<String, dynamic> json) => _$CardDeckFromJson(json);
  Map<String, dynamic> toJson() => _$CardDeckToJson(this);

  int get cardCount => cards.length;
  bool get isFull => cardCount >= maxCards;
  bool get isEmpty => cardCount == 0;

  int get totalManaCost => cards.fold(0, (sum, card) => sum + card.manaCost);
  double get averageManaCost => cardCount > 0 ? totalManaCost / cardCount : 0;

  Map<CardRarity, int> get rarityDistribution {
    final distribution = <CardRarity, int>{};
    for (final card in cards) {
      distribution[card.rarity] = (distribution[card.rarity] ?? 0) + 1;
    }
    return distribution;
  }

  Map<CardElement, int> get elementDistribution {
    final distribution = <CardElement, int>{};
    for (final card in cards) {
      distribution[card.element] = (distribution[card.element] ?? 0) + 1;
    }
    return distribution;
  }
}
