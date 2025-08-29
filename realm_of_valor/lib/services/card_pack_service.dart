import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/card_model.dart';
import '../data/models/inventory_model.dart';
import '../features/inventory/providers.dart';

class CardPackService {
  static final CardPackService _instance = CardPackService._internal();
  factory CardPackService() => _instance;
  CardPackService._internal();

  final Random _random = Random();

  /// Card pack types and their configurations
  static const Map<String, PackConfig> _packTypes = {
    'basic': PackConfig(
      name: 'Basic Pack',
      description: 'Contains common and uncommon cards',
      price: 100,
      cardCount: 5,
      rarityWeights: {
        CardRarity.common: 0.7,
        CardRarity.uncommon: 0.3,
      },
    ),
    'premium': PackConfig(
      name: 'Premium Pack',
      description: 'Contains rare and epic cards',
      price: 500,
      cardCount: 5,
      rarityWeights: {
        CardRarity.uncommon: 0.5,
        CardRarity.rare: 0.4,
        CardRarity.epic: 0.1,
      },
    ),
    'legendary': PackConfig(
      name: 'Legendary Pack',
      description: 'Contains epic and legendary cards',
      price: 1000,
      cardCount: 5,
      rarityWeights: {
        CardRarity.rare: 0.4,
        CardRarity.epic: 0.4,
        CardRarity.legendary: 0.2,
      },
    ),
    'mythic': PackConfig(
      name: 'Mythic Pack',
      description: 'Contains legendary and mythic cards',
      price: 2500,
      cardCount: 5,
      rarityWeights: {
        CardRarity.epic: 0.3,
        CardRarity.legendary: 0.5,
        CardRarity.mythic: 0.2,
      },
    ),
  };

  /// Get available pack types
  List<PackConfig> getAvailablePacks() {
    return _packTypes.values.toList();
  }

  /// Get pack configuration by type
  PackConfig? getPackConfig(String packType) {
    return _packTypes[packType];
  }

  /// Generate cards for a pack
  List<GameCard> generatePackCards(String packType, List<GameCard> cardDatabase) {
    final config = _packTypes[packType];
    if (config == null) return [];

    final cards = <GameCard>[];
    final availableCards = _filterCardsByRarity(cardDatabase, config.rarityWeights.keys.toList());

    for (int i = 0; i < config.cardCount; i++) {
      final rarity = _selectRarity(config.rarityWeights);
      final rarityCards = availableCards.where((card) => card.rarity == rarity).toList();
      
      if (rarityCards.isNotEmpty) {
        final selectedCard = rarityCards[_random.nextInt(rarityCards.length)];
        cards.add(selectedCard);
      }
    }

    return cards;
  }

  /// Filter cards by rarity
  List<GameCard> _filterCardsByRarity(List<GameCard> cards, List<CardRarity> rarities) {
    return cards.where((card) => rarities.contains(card.rarity)).toList();
  }

  /// Select rarity based on weights
  CardRarity _selectRarity(Map<CardRarity, double> weights) {
    final random = _random.nextDouble();
    double cumulative = 0;

    for (final entry in weights.entries) {
      cumulative += entry.value;
      if (random <= cumulative) {
        return entry.key;
      }
    }

    // Fallback to first rarity
    return weights.keys.first;
  }

  /// Open a pack and add cards to inventory
  Future<List<GameCard>> openPack(String packType, List<GameCard> cardDatabase, WidgetRef ref) async {
    final cards = generatePackCards(packType, cardDatabase);
    
    // Add cards to inventory
    final inventoryActions = ref.read(inventoryActionsProvider);
    for (final card in cards) {
      await inventoryActions.addCard(card.id);
    }

    return cards;
  }

  /// Generate a random card of specific rarity
  GameCard generateRandomCard(CardRarity rarity, List<GameCard> cardDatabase) {
    final rarityCards = cardDatabase.where((card) => card.rarity == rarity).toList();
    
    if (rarityCards.isEmpty) {
      // Generate a fallback card
      return GameCard(
        id: 'fallback_${rarity.name}_${DateTime.now().millisecondsSinceEpoch}',
        name: '${rarity.name} Card',
        description: 'A randomly generated ${rarity.name} card',
        type: CardType.spell,
        rarity: rarity,
        element: CardElement.none,
        manaCost: _random.nextInt(5) + 1,
        stats: {
          'damage': _random.nextInt(20) + 10,
          'healing': _random.nextInt(15) + 5,
        },
      );
    }

    return rarityCards[_random.nextInt(rarityCards.length)];
  }

  /// Generate a card based on quest completion
  GameCard generateQuestRewardCard(QuestType questType, List<GameCard> cardDatabase) {
    // Determine card type based on quest type
    CardType cardType;
    CardElement element = CardElement.none;
    
    switch (questType) {
      case QuestType.battle:
        cardType = CardType.spell;
        element = CardElement.fire;
        break;
      case QuestType.treasure:
        cardType = CardType.item;
        break;
      case QuestType.location:
        cardType = CardType.location;
        element = CardElement.earth;
        break;
      case QuestType.fitness:
        cardType = CardType.spell;
        element = CardElement.light;
        break;
      case QuestType.social:
        cardType = CardType.companion;
        break;
      default:
        cardType = CardType.spell;
    }

    // Find matching cards
    final matchingCards = cardDatabase.where((card) => 
      card.type == cardType && 
      (element == CardElement.none || card.element == element)
    ).toList();

    if (matchingCards.isNotEmpty) {
      return matchingCards[_random.nextInt(matchingCards.length)];
    }

    // Generate a custom quest reward card
    return GameCard(
      id: 'quest_reward_${questType.name}_${DateTime.now().millisecondsSinceEpoch}',
      name: '${questType.name} Reward',
      description: 'A reward for completing ${questType.name} quests',
      type: cardType,
      rarity: CardRarity.rare,
      element: element,
      manaCost: _random.nextInt(3) + 1,
      stats: {
        'quest_bonus': 1.2,
        'damage': _random.nextInt(15) + 10,
      },
    );
  }

  /// Generate cards for special events
  List<GameCard> generateEventCards(String eventType, int count, List<GameCard> cardDatabase) {
    final cards = <GameCard>[];
    
    switch (eventType) {
      case 'seasonal':
        // Seasonal event cards with special themes
        for (int i = 0; i < count; i++) {
          cards.add(GameCard(
            id: 'seasonal_${DateTime.now().millisecondsSinceEpoch}_$i',
            name: 'Seasonal Card ${i + 1}',
            description: 'A special seasonal card',
            type: CardType.spell,
            rarity: CardRarity.epic,
            element: CardElement.nature,
            manaCost: _random.nextInt(4) + 2,
            stats: {
              'seasonal_bonus': 1.5,
              'damage': _random.nextInt(25) + 15,
            },
          ));
        }
        break;
        
      case 'holiday':
        // Holiday event cards
        for (int i = 0; i < count; i++) {
          cards.add(GameCard(
            id: 'holiday_${DateTime.now().millisecondsSinceEpoch}_$i',
            name: 'Holiday Card ${i + 1}',
            description: 'A special holiday card',
            type: CardType.spell,
            rarity: CardRarity.legendary,
            element: CardElement.light,
            manaCost: _random.nextInt(5) + 3,
            stats: {
              'holiday_bonus': 2.0,
              'damage': _random.nextInt(30) + 20,
            },
          ));
        }
        break;
        
      default:
        // Default event cards
        for (int i = 0; i < count; i++) {
          cards.add(generateRandomCard(CardRarity.rare, cardDatabase));
        }
    }
    
    return cards;
  }

  /// Check if player can afford a pack
  bool canAffordPack(String packType, int playerGold) {
    final config = _packTypes[packType];
    return config != null && playerGold >= config.price;
  }

  /// Get pack price
  int getPackPrice(String packType) {
    return _packTypes[packType]?.price ?? 0;
  }
}

class PackConfig {
  final String name;
  final String description;
  final int price;
  final int cardCount;
  final Map<CardRarity, double> rarityWeights;

  const PackConfig({
    required this.name,
    required this.description,
    required this.price,
    required this.cardCount,
    required this.rarityWeights,
  });
}

// Provider for CardPackService
final cardPackServiceProvider = Provider<CardPackService>((ref) {
  return CardPackService();
});

// Provider for available packs
final availablePacksProvider = Provider<List<PackConfig>>((ref) {
  final cardPackService = ref.read(cardPackServiceProvider);
  return cardPackService.getAvailablePacks();
});
