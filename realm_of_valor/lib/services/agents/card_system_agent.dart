import 'dart:math';

import '../../data/models/card_model.dart';
import '../../data/models/inventory_model.dart';
import '../base_agent.dart';
import '../event_bus.dart';
import 'package:flutter/foundation.dart';

class CardSystemAgent extends BaseAgent {
  CardSystemAgent(super.bus);

  final Map<String, GameCard> _cardDb = <String, GameCard>{};
  final List<CardInstance> _collection = <CardInstance>[];
  final Map<String, String?> _equipmentSlots = <String, String?>{
    'head': null,
    'chest': null,
    'legs': null,
    'weapon': null,
    'offhand': null,
    'ring': null,
    'amulet': null,
  };

  @override
  String get name => 'CardSystem';

  @override
  Future<void> onInitialize() async {
    // Initialize card database with more cards
    _initializeCardDatabase();
    
    bus.subscribe('card_db.load', (evt, b) {
      final list = evt.data?['cards'] as List<dynamic>?;
      if (list != null) {
        for (final item in list) {
          final json = Map<String, dynamic>.from(item as Map);
          final card = GameCard.fromJson(json);
          _cardDb[card.id] = card;
        }
      }
    });

    bus.subscribe('card.obtain', (evt, b) => _onObtain(evt));
    bus.subscribe('card.equip', (evt, b) => _onEquip(evt));
    bus.subscribe('card.unequip', (evt, b) => _onUnequip(evt));
    bus.subscribe('card.pack_open', (evt, b) => _onPackOpen(evt));
  }

  @override
  Future<void> onDispose() async {}

  void _initializeCardDatabase() {
    // Equipment (Weapons)
    _cardDb['basic_sword'] = GameCard(
      id: 'basic_sword',
      name: 'Basic Sword',
      description: 'A simple but reliable sword for beginners',
      type: CardType.equipment,
      rarity: CardRarity.common,
      element: CardElement.none,
      manaCost: 0,
      stats: {'attack': 10, 'durability': 50},
    );
    
    _cardDb['iron_sword'] = GameCard(
      id: 'iron_sword',
      name: 'Iron Sword',
      description: 'A sturdy iron sword with good balance',
      type: CardType.equipment,
      rarity: CardRarity.uncommon,
      element: CardElement.none,
      manaCost: 0,
      stats: {'attack': 15, 'durability': 75},
    );
    
    _cardDb['magic_staff'] = GameCard(
      id: 'magic_staff',
      name: 'Magic Staff',
      description: 'A staff imbued with magical energy',
      type: CardType.equipment,
      rarity: CardRarity.rare,
      element: CardElement.arcane,
      manaCost: 0,
      stats: {'magic_attack': 20, 'mana_boost': 10},
    );
    
    _cardDb['legendary_blade'] = GameCard(
      id: 'legendary_blade',
      name: 'Legendary Blade',
      description: 'A blade of legend with incredible power',
      type: CardType.equipment,
      rarity: CardRarity.legendary,
      element: CardElement.light,
      manaCost: 0,
      stats: {'attack': 30, 'critical_chance': 0.25, 'durability': 100},
    );

    // Equipment (Armor)
    _cardDb['leather_armor'] = GameCard(
      id: 'leather_armor',
      name: 'Leather Armor',
      description: 'Light leather armor for mobility',
      type: CardType.equipment,
      rarity: CardRarity.common,
      element: CardElement.none,
      manaCost: 0,
      stats: {'defense': 8, 'agility': 5},
    );
    
    _cardDb['iron_armor'] = GameCard(
      id: 'iron_armor',
      name: 'Iron Armor',
      description: 'Heavy iron armor for maximum protection',
      type: CardType.equipment,
      rarity: CardRarity.uncommon,
      element: CardElement.none,
      manaCost: 0,
      stats: {'defense': 15, 'vitality': 10},
    );
    
    _cardDb['magic_robe'] = GameCard(
      id: 'magic_robe',
      name: 'Magic Robe',
      description: 'A robe woven with magical threads',
      type: CardType.equipment,
      rarity: CardRarity.rare,
      element: CardElement.arcane,
      manaCost: 0,
      stats: {'magic_defense': 12, 'mana_regeneration': 5},
    );

    // Spells
    _cardDb['fireball'] = GameCard(
      id: 'fireball',
      name: 'Fireball',
      description: 'A powerful ball of fire',
      type: CardType.spell,
      rarity: CardRarity.common,
      element: CardElement.fire,
      manaCost: 3,
      stats: {'damage': 25, 'burn_chance': 0.3},
    );
    
    _cardDb['heal'] = GameCard(
      id: 'heal',
      name: 'Heal',
      description: 'Restore health to yourself or allies',
      type: CardType.spell,
      rarity: CardRarity.common,
      element: CardElement.light,
      manaCost: 2,
      stats: {'healing': 20},
    );
    
    _cardDb['lightning_bolt'] = GameCard(
      id: 'lightning_bolt',
      name: 'Lightning Bolt',
      description: 'A bolt of lightning that strikes instantly',
      type: CardType.spell,
      rarity: CardRarity.uncommon,
      element: CardElement.lightning,
      manaCost: 4,
      stats: {'damage': 35, 'stun_chance': 0.2},
    );

    // Items
    _cardDb['health_potion'] = GameCard(
      id: 'health_potion',
      name: 'Health Potion',
      description: 'Restore health instantly',
      type: CardType.item,
      rarity: CardRarity.common,
      element: CardElement.none,
      manaCost: 0,
      stats: {'healing': 30},
    );
    
    _cardDb['mana_potion'] = GameCard(
      id: 'mana_potion',
      name: 'Mana Potion',
      description: 'Restore mana instantly',
      type: CardType.item,
      rarity: CardRarity.common,
      element: CardElement.none,
      manaCost: 0,
      stats: {'mana_restore': 25},
    );
    
    _cardDb['strength_potion'] = GameCard(
      id: 'strength_potion',
      name: 'Strength Potion',
      description: 'Temporarily increase strength',
      type: CardType.item,
      rarity: CardRarity.uncommon,
      element: CardElement.none,
      manaCost: 0,
      stats: {'strength_boost': 10, 'duration': 300},
    );

    // Guaranteed items for card packs
    _cardDb['basic_weapon'] = GameCard(
      id: 'basic_weapon',
      name: 'Training Sword',
      description: 'A basic training sword for new adventurers',
      type: CardType.equipment,
      rarity: CardRarity.common,
      element: CardElement.none,
      manaCost: 0,
      stats: {'attack': 8, 'durability': 40},
    );
    
    _cardDb['basic_armor'] = GameCard(
      id: 'basic_armor',
      name: 'Training Armor',
      description: 'Basic training armor for protection',
      type: CardType.equipment,
      rarity: CardRarity.common,
      element: CardElement.none,
      manaCost: 0,
      stats: {'defense': 6, 'vitality': 5},
    );
    
    _cardDb['basic_spell'] = GameCard(
      id: 'basic_spell',
      name: 'Magic Missile',
      description: 'A simple magical projectile',
      type: CardType.spell,
      rarity: CardRarity.common,
      element: CardElement.arcane,
      manaCost: 1,
      stats: {'damage': 15},
    );
    
    _cardDb['premium_weapon'] = GameCard(
      id: 'premium_weapon',
      name: 'Enchanted Blade',
      description: 'A blade enhanced with magical properties',
      type: CardType.equipment,
      rarity: CardRarity.rare,
      element: CardElement.arcane,
      manaCost: 0,
      stats: {'attack': 20, 'magic_attack': 10, 'durability': 80},
    );
    
    _cardDb['premium_armor'] = GameCard(
      id: 'premium_armor',
      name: 'Enchanted Armor',
      description: 'Armor protected by magical wards',
      type: CardType.equipment,
      rarity: CardRarity.rare,
      element: CardElement.arcane,
      manaCost: 0,
      stats: {'defense': 18, 'magic_defense': 12, 'vitality': 15},
    );
    
    _cardDb['premium_spell'] = GameCard(
      id: 'premium_spell',
      name: 'Arcane Burst',
      description: 'A powerful burst of arcane energy',
      type: CardType.spell,
      rarity: CardRarity.rare,
      element: CardElement.arcane,
      manaCost: 5,
      stats: {'damage': 45, 'area_effect': true},
    );
    
    _cardDb['premium_skill'] = GameCard(
      id: 'premium_skill',
      name: 'Combat Mastery',
      description: 'Master the art of combat',
      type: CardType.skill,
      rarity: CardRarity.rare,
      element: CardElement.none,
      manaCost: 0,
      stats: {'attack_boost': 15, 'critical_chance': 0.1},
    );

    // Misc items
    _cardDb['treasure_map'] = GameCard(
      id: 'treasure_map',
      name: 'Treasure Map',
      description: 'A map leading to hidden treasure',
      type: CardType.item,
      rarity: CardRarity.uncommon,
      element: CardElement.none,
      manaCost: 0,
      stats: {'quest_trigger': true},
    );
    
    _cardDb['lucky_charm'] = GameCard(
      id: 'lucky_charm',
      name: 'Lucky Charm',
      description: 'A charm that brings good fortune',
      type: CardType.item,
      rarity: CardRarity.rare,
      element: CardElement.none,
      manaCost: 0,
      stats: {'luck_boost': 0.1, 'critical_chance': 0.05},
    );
  }

  void _onObtain(Event evt) {
    final cardId = evt.data?['cardId'] as String?;
    if (cardId == null || !_cardDb.containsKey(cardId)) return;
    final instance = CardInstance(instanceId: '${cardId}_${_collection.length + 1}', cardId: cardId);
    _collection.add(instance);
    bus.publish(Event(type: 'card_obtained', data: {'instanceId': instance.instanceId, 'cardId': cardId}));
  }

  void _onEquip(Event evt) {
    final instanceId = evt.data?['instanceId'] as String?;
    final slot = evt.data?['slot'] as String?;
    if (instanceId == null || slot == null || !_equipmentSlots.containsKey(slot)) return;
    _equipmentSlots[slot] = instanceId;
    bus.publish(Event(type: 'equipment_changed', data: {'slot': slot, 'instanceId': instanceId}));
  }

  void _onUnequip(Event evt) {
    final slot = evt.data?['slot'] as String?;
    if (slot == null || !_equipmentSlots.containsKey(slot)) return;
    _equipmentSlots[slot] = null;
    bus.publish(Event(type: 'equipment_changed', data: {'slot': slot, 'instanceId': null}));
  }

  void _onPackOpen(Event evt) {
    final packType = evt.data?['packType'] as String? ?? 'basic';
    debugPrint('CardSystemAgent: Processing pack_open event for $packType');
    
    // Determine pack contents based on type
    int cardCount;
    List<CardRarity> rarityPool;
    List<String> guaranteedItems;
    int goldCost;
    
    switch (packType) {
      case 'premium':
        cardCount = 10; // 10 random cards as requested
        goldCost = 200;
        rarityPool = [
          CardRarity.common,
          CardRarity.common,
          CardRarity.common,
          CardRarity.uncommon,
          CardRarity.uncommon,
          CardRarity.uncommon,
          CardRarity.rare,
          CardRarity.rare,
          CardRarity.epic,
          CardRarity.legendary,
        ];
        guaranteedItems = ['premium_weapon', 'premium_armor', 'premium_spell', 'premium_skill'];
        debugPrint('CardSystemAgent: Premium pack - $cardCount cards, ${rarityPool.length} rarity options, $goldCost gold cost');
        break;
      case 'basic':
      default:
        cardCount = 10; // 10 random cards as requested
        goldCost = 50;
        rarityPool = [
          CardRarity.common,
          CardRarity.common,
          CardRarity.common,
          CardRarity.common,
          CardRarity.uncommon,
          CardRarity.uncommon,
          CardRarity.uncommon,
          CardRarity.rare,
          CardRarity.rare,
          CardRarity.epic,
        ];
        guaranteedItems = ['basic_weapon', 'basic_armor', 'basic_spell'];
        debugPrint('CardSystemAgent: Basic pack - $cardCount cards, ${rarityPool.length} rarity options, $goldCost gold cost');
        break;
    }
    
    final rng = Random(DateTime.now().millisecondsSinceEpoch);
    final obtainedCards = <String>[];
    
    // Deduct gold cost first
    bus.publish(Event(
      type: 'inventory.deduct_gold',
      data: {'gold': goldCost},
    ));
    debugPrint('CardSystemAgent: Deducted $goldCost gold for $packType pack');
    
    // Add guaranteed items first
    for (final itemId in guaranteedItems) {
      if (_cardDb.containsKey(itemId)) {
        obtainedCards.add(itemId);
        debugPrint('CardSystemAgent: Added guaranteed item $itemId');
        
        // Publish card obtained event
        bus.publish(Event(
          type: 'card.obtain',
          data: {'cardId': itemId},
        ));
      }
    }
    
    // Add random cards
    for (var i = 0; i < cardCount; i++) {
      // Select rarity
      final selectedRarity = rarityPool[rng.nextInt(rarityPool.length)];
      
      // Get cards of that rarity
      final cardsOfRarity = _cardDb.entries
          .where((entry) => entry.value.rarity == selectedRarity)
          .map((entry) => entry.key)
          .toList();
      
      debugPrint('CardSystemAgent: Selected rarity $selectedRarity, found ${cardsOfRarity.length} cards');
      
      if (cardsOfRarity.isNotEmpty) {
        final selectedCard = cardsOfRarity[rng.nextInt(cardsOfRarity.length)];
        obtainedCards.add(selectedCard);
        
        debugPrint('CardSystemAgent: Selected card $selectedCard for pack $i');
        
        // Publish card obtained event
        bus.publish(Event(
          type: 'card.obtain',
          data: {'cardId': selectedCard},
        ));
      } else {
        debugPrint('CardSystemAgent: No cards found for rarity $selectedRarity');
      }
    }
    
    debugPrint('CardSystemAgent: Pack opened successfully, obtained ${obtainedCards.length} cards: $obtainedCards');
    
    // Publish pack opened event
    bus.publish(Event(
      type: 'card_pack_opened',
      data: {
        'packType': packType,
        'obtainedCards': obtainedCards,
        'cardCount': obtainedCards.length,
      },
    ));
  }
}
