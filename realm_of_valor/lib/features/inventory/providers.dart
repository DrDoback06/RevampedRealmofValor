import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../core/di.dart';
import '../../data/models/inventory_model.dart';
import '../../data/models/card_model.dart';
import '../../data/models/character_model.dart';
import '../../services/event_bus.dart';
import '../auth/providers.dart';
import '../character/providers.dart';

final inventoryStreamProvider = StreamProvider<Inventory?>((ref) async* {
  final inventoryRepo = ref.watch(inventoryRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.value?.uid == null) {
    yield null;
    return;
  }

  // First, yield a default inventory immediately
  yield _createDefaultInventory(authState.value!.uid);
  
  // Then listen for inventory updates from event bus
  final eventBus = ref.watch(eventBusProvider);
  await for (final event in eventBus.stream) {
    if (event.type == 'inventory_updated' && event.data?['inventory'] != null) {
      yield Inventory.fromJson(event.data!['inventory'] as Map<String, dynamic>);
    } else if (event.type == 'card.obtain') {
      // Handle card obtain events
      final cardId = event.data?['cardId'] as String?;
      if (cardId != null) {
        debugPrint('InventoryAgent: Adding card $cardId to inventory');
        final currentInventory = _createDefaultInventory(authState.value!.uid);
        final newCardInstance = CardInstance(
          instanceId: 'card_${DateTime.now().millisecondsSinceEpoch}',
          cardId: cardId,
          durability: 100,
        );
        
        final updatedItems = List<CardInstance>.from(currentInventory.items);
        updatedItems.add(newCardInstance);
        
        debugPrint('InventoryAgent: Inventory now has ${updatedItems.length} items');
        
        final updatedInventory = Inventory(
          ownerUid: currentInventory.ownerUid,
          items: updatedItems,
          gold: currentInventory.gold,
        );
        
        yield updatedInventory;
        debugPrint('InventoryAgent: Yielded updated inventory');
      }
    }
  }
});

/// Provider for character with calculated stats from equipment
final characterWithEquipmentProvider = StreamProvider<Character?>((ref) async* {
  final characterAsync = ref.watch(characterStreamProvider);
  final inventoryAsync = ref.watch(inventoryStreamProvider);
  final cardDatabaseAsync = ref.watch(cardDatabaseProvider);
  
  // Wait for all async values to resolve
  final character = await characterAsync.when(
    data: (data) => data,
    loading: () => null,
    error: (_, __) => null,
  );
  
  final inventory = await inventoryAsync.when(
    data: (data) => data,
    loading: () => null,
    error: (_, __) => null,
  );
  
  final cardDatabaseList = await cardDatabaseAsync.when(
    data: (data) => data,
    loading: () => <GameCard>[],
    error: (_, __) => <GameCard>[],
  );
  
  // Convert list to map for easier lookup
  final cardDatabase = <String, GameCard>{};
  for (final card in cardDatabaseList) {
    cardDatabase[card.id] = card;
  }
  
  if (character == null || inventory == null) {
    yield character;
    return;
  }
  
  // Calculate stats from equipped items
  final calculatedStats = _calculateStatsFromEquipment(character, inventory, cardDatabase);
  
  final updatedCharacter = Character(
    uid: character.uid,
    id: character.id,
    name: character.name,
    level: character.level,
    xp: character.xp,
    skillPoints: character.skillPoints,
    stats: calculatedStats,
    equipment: character.equipment,
    unlockedSkills: character.unlockedSkills,
  );
  
  yield updatedCharacter;
  
  // Listen for equipment changes
  final eventBus = ref.watch(eventBusProvider);
  await for (final event in eventBus.stream) {
    if (event.type == 'card.equip' || event.type == 'card.unequip') {
      // Recalculate stats when equipment changes
      final newCalculatedStats = _calculateStatsFromEquipment(character, inventory, cardDatabase);
      final newUpdatedCharacter = Character(
        uid: character.uid,
        id: character.id,
        name: character.name,
        level: character.level,
        xp: character.xp,
        skillPoints: character.skillPoints,
        stats: newCalculatedStats,
        equipment: character.equipment,
        unlockedSkills: character.unlockedSkills,
      );
      yield newUpdatedCharacter;
    }
  }
});

CharacterStats _calculateStatsFromEquipment(Character character, Inventory inventory, Map<String, GameCard> cardDatabase) {
  // Start with base stats
  int strength = character.stats.strength;
  int agility = character.stats.agility;
  int intelligence = character.stats.intelligence;
  int vitality = character.stats.vitality;
  
  // Add stats from equipped items
  final equippedItems = [
    character.equipment.head,
    character.equipment.chest,
    character.equipment.legs,
    character.equipment.weapon,
    character.equipment.offhand,
    character.equipment.ring,
    character.equipment.amulet,
  ];
  
  for (final itemId in equippedItems) {
    if (itemId != null) {
      // Find the card instance in inventory
      final cardInstance = inventory.items.firstWhere(
        (item) => item.instanceId == itemId,
        orElse: () => const CardInstance(instanceId: '', cardId: ''),
      );
      
      if (cardInstance.instanceId.isNotEmpty) {
        final card = cardDatabase[cardInstance.cardId];
        if (card != null && card.stats != null) {
          // Apply stats from the card
          strength += (card.stats!['strength'] as num?)?.toInt() ?? 0;
          agility += (card.stats!['agility'] as num?)?.toInt() ?? 0;
          intelligence += (card.stats!['intelligence'] as num?)?.toInt() ?? 0;
          vitality += (card.stats!['vitality'] as num?)?.toInt() ?? 0;
        }
      }
    }
  }
  
  return CharacterStats(
    strength: strength,
    agility: agility,
    intelligence: intelligence,
    vitality: vitality,
  );
}

Inventory _createDefaultInventory(String uid) {
  return Inventory(
    ownerUid: uid,
    items: [
      const CardInstance(
        instanceId: 'card_1',
        cardId: 'basic_sword',
        durability: 100,
        upgrades: null,
        flags: null,
      ),
      const CardInstance(
        instanceId: 'card_2',
        cardId: 'health_potion',
        durability: 1,
        upgrades: null,
        flags: null,
      ),
    ],
    gold: 100,
  );
}

// Enhanced card database with extensive examples
final cardDatabaseProvider = FutureProvider<List<GameCard>>((ref) async {
  return [
    // Equipment Cards
    GameCard(
      id: 'sword_001',
      name: 'Iron Sword',
      description: 'A basic iron sword forged by local blacksmiths.',
      type: CardType.equipment,
      rarity: CardRarity.common,
      element: CardElement.none,
      level: 1,
      manaCost: 0,
      stats: {'atk': 5, 'def': 0},
      abilities: ['Slash'],
      flavorText: 'Simple but effective.',
      artist: 'Blacksmith Guild',
      set: 'Core Set',
      series: 'Basic Equipment',
      qrCode: 'ROV_CARD:sword_001',
      tags: ['weapon', 'sword', 'melee'],
    ),
    GameCard(
      id: 'armor_001',
      name: 'Leather Armor',
      description: 'Light armor made from tanned leather.',
      type: CardType.equipment,
      rarity: CardRarity.common,
      element: CardElement.none,
      level: 1,
      manaCost: 0,
      stats: {'atk': 0, 'def': 3, 'agi': 1},
      abilities: ['Lightweight'],
      flavorText: 'Better than nothing.',
      artist: 'Leatherworker',
      set: 'Core Set',
      series: 'Basic Equipment',
      qrCode: 'ROV_CARD:armor_001',
      tags: ['armor', 'leather', 'light'],
    ),
    GameCard(
      id: 'staff_001',
      name: 'Apprentice Staff',
      description: 'A wooden staff imbued with basic magical properties.',
      type: CardType.equipment,
      rarity: CardRarity.uncommon,
      element: CardElement.arcane,
      level: 1,
      manaCost: 0,
      stats: {'atk': 2, 'def': 0, 'int': 3},
      abilities: ['Mana Focus'],
      flavorText: 'Every great mage started with one of these.',
      artist: 'Arcane Academy',
      set: 'Core Set',
      series: 'Basic Equipment',
      qrCode: 'ROV_CARD:staff_001',
      tags: ['weapon', 'staff', 'magic'],
    ),

    // Spell Cards
    GameCard(
      id: 'spell_001',
      name: 'Fireball',
      description: 'Launch a ball of fire at your enemies.',
      type: CardType.spell,
      rarity: CardRarity.common,
      element: CardElement.fire,
      level: 1,
      manaCost: 3,
      stats: {'damage': 8},
      abilities: ['Burn'],
      effects: {'burn_duration': 2, 'burn_damage': 2},
      flavorText: 'The first spell every fire mage learns.',
      artist: 'Pyromancer Guild',
      set: 'Core Set',
      series: 'Elemental Spells',
      qrCode: 'ROV_SPELL:spell_001',
      tags: ['spell', 'fire', 'damage'],
    ),
    GameCard(
      id: 'spell_002',
      name: 'Heal',
      description: 'Restore health to yourself or an ally.',
      type: CardType.spell,
      rarity: CardRarity.common,
      element: CardElement.light,
      level: 1,
      manaCost: 2,
      stats: {'healing': 6},
      abilities: ['Restore'],
      flavorText: 'The light of healing guides us.',
      artist: 'Temple of Light',
      set: 'Core Set',
      series: 'Healing Spells',
      qrCode: 'ROV_SPELL:spell_002',
      tags: ['spell', 'healing', 'support'],
    ),

    // Skill Cards
    GameCard(
      id: 'skill_001',
      name: 'Power Strike',
      description: 'A powerful melee attack that deals extra damage.',
      type: CardType.skill,
      rarity: CardRarity.uncommon,
      element: CardElement.none,
      level: 1,
      manaCost: 2,
      stats: {'damage': 10},
      abilities: ['Critical Chance'],
      effects: {'crit_chance': 0.25, 'crit_multiplier': 1.5},
      flavorText: 'Strike with all your might!',
      artist: 'Warrior Academy',
      set: 'Core Set',
      series: 'Combat Skills',
      qrCode: 'ROV_SKILL:skill_001',
      tags: ['skill', 'melee', 'damage'],
    ),
    GameCard(
      id: 'skill_002',
      name: 'Stealth',
      description: 'Become invisible to enemies for a short time.',
      type: CardType.skill,
      rarity: CardRarity.rare,
      element: CardElement.dark,
      level: 1,
      manaCost: 3,
      stats: {'duration': 3},
      abilities: ['Invisibility', 'Sneak Attack'],
      effects: {'stealth_duration': 3, 'sneak_damage': 1.5},
      flavorText: 'Shadows are your friend.',
      artist: 'Rogue Guild',
      set: 'Core Set',
      series: 'Stealth Skills',
      qrCode: 'ROV_SKILL:skill_002',
      tags: ['skill', 'stealth', 'utility'],
    ),

    // Quest Cards
    GameCard(
      id: 'quest_001',
      name: 'Goblin Hunt',
      description: 'Defeat 5 goblins in the nearby forest.',
      type: CardType.quest,
      rarity: CardRarity.common,
      element: CardElement.none,
      level: 1,
      manaCost: 0,
      stats: {'target_count': 5, 'reward_exp': 50, 'reward_gold': 25},
      abilities: ['Tracking'],
      effects: {'goblin_detection': true},
      flavorText: 'The village needs your help!',
      artist: 'Village Elder',
      set: 'Core Set',
      series: 'Hunting Quests',
      qrCode: 'ROV_QUEST:quest_001',
      tags: ['quest', 'hunting', 'combat'],
    ),
    GameCard(
      id: 'quest_002',
      name: 'Herb Gathering',
      description: 'Collect 10 healing herbs from the meadow.',
      type: CardType.quest,
      rarity: CardRarity.common,
      element: CardElement.nature,
      level: 1,
      manaCost: 0,
      stats: {'target_count': 10, 'reward_exp': 30, 'reward_gold': 15},
      abilities: ['Herb Sense'],
      effects: {'herb_detection': true},
      flavorText: 'Nature provides for those who seek.',
      artist: 'Druid Circle',
      set: 'Core Set',
      series: 'Gathering Quests',
      qrCode: 'ROV_QUEST:quest_002',
      tags: ['quest', 'gathering', 'nature'],
    ),

    // Monster Cards
    GameCard(
      id: 'monster_001',
      name: 'Goblin Warrior',
      description: 'A fierce goblin warrior with crude weapons.',
      type: CardType.monster,
      rarity: CardRarity.common,
      element: CardElement.none,
      level: 2,
      manaCost: 0,
      stats: {'hp': 15, 'atk': 4, 'def': 1},
      abilities: ['Pack Tactics'],
      effects: {'pack_bonus': 0.2},
      flavorText: 'Numbers are their strength.',
      artist: 'Monster Manual',
      set: 'Core Set',
      series: 'Goblin Enemies',
      qrCode: 'ROV_CARD:monster_001',
      tags: ['monster', 'goblin', 'warrior'],
    ),
    GameCard(
      id: 'monster_002',
      name: 'Fire Elemental',
      description: 'A being of pure flame and destruction.',
      type: CardType.monster,
      rarity: CardRarity.rare,
      element: CardElement.fire,
      level: 5,
      manaCost: 0,
      stats: {'hp': 25, 'atk': 8, 'def': 2},
      abilities: ['Fire Aura', 'Burn'],
      effects: {'fire_aura_damage': 2, 'burn_chance': 0.3},
      flavorText: 'Born from the heart of a volcano.',
      artist: 'Elemental Plane',
      set: 'Core Set',
      series: 'Elemental Beings',
      qrCode: 'ROV_CARD:monster_002',
      tags: ['monster', 'elemental', 'fire'],
    ),

    // Consumable Cards
    GameCard(
      id: 'potion_001',
      name: 'Health Potion',
      description: 'Restores 20 health points.',
      type: CardType.consumable,
      rarity: CardRarity.common,
      element: CardElement.none,
      level: 1,
      manaCost: 0,
      stats: {'healing': 20},
      abilities: ['Instant Use'],
      maxStack: 10,
      flavorText: 'The alchemist\'s most popular creation.',
      artist: 'Alchemist Guild',
      set: 'Core Set',
      series: 'Basic Potions',
      qrCode: 'ROV_CARD:potion_001',
      tags: ['consumable', 'potion', 'healing'],
    ),
    GameCard(
      id: 'scroll_001',
      name: 'Scroll of Fireball',
      description: 'Cast Fireball without using mana.',
      type: CardType.consumable,
      rarity: CardRarity.uncommon,
      element: CardElement.fire,
      level: 1,
      manaCost: 0,
      stats: {'spell_id': 'spell_001'},
      abilities: ['One-Time Use'],
      maxStack: 5,
      flavorText: 'Ancient knowledge preserved in parchment.',
      artist: 'Arcane Library',
      set: 'Core Set',
      series: 'Magic Scrolls',
      qrCode: 'ROV_CARD:scroll_001',
      tags: ['consumable', 'scroll', 'spell'],
    ),

    // Legendary Cards
    GameCard(
      id: 'legendary_001',
      name: 'Dragon\'s Breath Sword',
      description: 'A legendary sword that breathes fire.',
      type: CardType.equipment,
      rarity: CardRarity.legendary,
      element: CardElement.fire,
      level: 10,
      manaCost: 0,
      stats: {'atk': 25, 'def': 5, 'int': 10},
      abilities: ['Dragon\'s Breath', 'Fire Mastery'],
      effects: {'breath_damage': 15, 'fire_resistance': 0.5},
      flavorText: 'Forged in dragon fire, tempered in hero\'s blood.',
      artist: 'Dragon Smith',
      set: 'Legendary Collection',
      series: 'Dragon Equipment',
      qrCode: 'ROV_CARD:legendary_001',
      tags: ['legendary', 'weapon', 'dragon', 'fire'],
    ),

    // Artifact Cards
    GameCard(
      id: 'artifact_001',
      name: 'Crown of Wisdom',
      description: 'An ancient crown that enhances magical abilities.',
      type: CardType.artifact,
      rarity: CardRarity.epic,
      element: CardElement.arcane,
      level: 5,
      manaCost: 0,
      stats: {'int': 8, 'wis': 5},
      abilities: ['Arcane Mastery', 'Spell Efficiency'],
      effects: {'mana_cost_reduction': 0.2, 'spell_power': 1.3},
      flavorText: 'Worn by the greatest archmages of old.',
      artist: 'Ancient Kingdom',
      set: 'Artifact Collection',
      series: 'Royal Artifacts',
      qrCode: 'ROV_CARD:artifact_001',
      tags: ['artifact', 'crown', 'magic'],
    ),

    // Companion Cards
    GameCard(
      id: 'companion_001',
      name: 'Loyal Wolf',
      description: 'A faithful wolf companion that fights by your side.',
      type: CardType.companion,
      rarity: CardRarity.rare,
      element: CardElement.nature,
      level: 3,
      manaCost: 2,
      stats: {'hp': 20, 'atk': 6, 'def': 2, 'agi': 8},
      abilities: ['Pack Leader', 'Loyalty'],
      effects: {'companion_bonus': 0.15, 'loyalty_bonus': 0.1},
      flavorText: 'A bond stronger than steel.',
      artist: 'Wilderness',
      set: 'Companion Collection',
      series: 'Animal Companions',
      qrCode: 'ROV_CARD:companion_001',
      tags: ['companion', 'wolf', 'loyal'],
    ),

    // Mount Cards
    GameCard(
      id: 'mount_001',
      name: 'Swift Horse',
      description: 'A fast horse that increases travel speed.',
      type: CardType.mount,
      rarity: CardRarity.uncommon,
      element: CardElement.none,
      level: 1,
      manaCost: 0,
      stats: {'speed': 3, 'stamina': 10},
      abilities: ['Swift Travel', 'Carry Load'],
      effects: {'travel_speed': 1.5, 'carry_capacity': 2},
      flavorText: 'The wind in your hair, the road ahead.',
      artist: 'Stable Master',
      set: 'Mount Collection',
      series: 'Basic Mounts',
      qrCode: 'ROV_CARD:mount_001',
      tags: ['mount', 'horse', 'travel'],
    ),

    // Pet Cards
    GameCard(
      id: 'pet_001',
      name: 'Magical Cat',
      description: 'A mysterious cat with magical abilities.',
      type: CardType.pet,
      rarity: CardRarity.rare,
      element: CardElement.arcane,
      level: 1,
      manaCost: 0,
      stats: {'hp': 8, 'atk': 2, 'int': 5},
      abilities: ['Nine Lives', 'Magic Sense'],
      effects: {'revive_chance': 0.1, 'magic_detection': true},
      flavorText: 'Some say they can see into other worlds.',
      artist: 'Mystic Realm',
      set: 'Pet Collection',
      series: 'Magical Pets',
      qrCode: 'ROV_CARD:pet_001',
      tags: ['pet', 'cat', 'magic'],
    ),

    // Title Cards
    GameCard(
      id: 'title_001',
      name: 'Dragon Slayer',
      description: 'A prestigious title earned by defeating dragons.',
      type: CardType.title,
      rarity: CardRarity.legendary,
      element: CardElement.none,
      level: 1,
      manaCost: 0,
      stats: {'prestige': 100},
      abilities: ['Dragon Fear', 'Hero Status'],
      effects: {'dragon_damage': 1.2, 'npc_respect': 0.3},
      flavorText: 'The dragons themselves know your name.',
      artist: 'Royal Court',
      set: 'Title Collection',
      series: 'Achievement Titles',
      qrCode: 'ROV_CARD:title_001',
      tags: ['title', 'achievement', 'prestige'],
    ),

    // Emote Cards
    GameCard(
      id: 'emote_001',
      name: 'Victory Dance',
      description: 'Perform a celebratory dance.',
      type: CardType.emote,
      rarity: CardRarity.common,
      element: CardElement.none,
      level: 1,
      manaCost: 0,
      stats: {'duration': 3},
      abilities: ['Express Joy'],
      effects: {'morale_boost': 0.1},
      flavorText: 'Dance like nobody\'s watching!',
      artist: 'Social Guild',
      set: 'Emote Collection',
      series: 'Basic Emotes',
      qrCode: 'ROV_CARD:emote_001',
      tags: ['emote', 'dance', 'celebration'],
    ),

    // Currency Cards
    GameCard(
      id: 'currency_001',
      name: 'Gold Coin',
      description: 'Standard currency used throughout the realm.',
      type: CardType.currency,
      rarity: CardRarity.common,
      element: CardElement.none,
      level: 1,
      manaCost: 0,
      stats: {'value': 1},
      abilities: ['Trade'],
      maxStack: 999999,
      flavorText: 'The foundation of all commerce.',
      artist: 'Royal Mint',
      set: 'Currency Collection',
      series: 'Basic Currency',
      qrCode: 'ROV_CARD:currency_001',
      tags: ['currency', 'gold', 'trade'],
    ),

    // Material Cards
    GameCard(
      id: 'material_001',
      name: 'Iron Ore',
      description: 'Raw iron ore that can be smelted into bars.',
      type: CardType.material,
      rarity: CardRarity.common,
      element: CardElement.earth,
      level: 1,
      manaCost: 0,
      stats: {'quality': 1},
      abilities: ['Smelt'],
      maxStack: 100,
      flavorText: 'The earth\'s bounty.',
      artist: 'Miner Guild',
      set: 'Material Collection',
      series: 'Basic Materials',
      qrCode: 'ROV_CARD:material_001',
      tags: ['material', 'ore', 'crafting'],
    ),

    // Recipe Cards
    GameCard(
      id: 'recipe_001',
      name: 'Iron Sword Recipe',
      description: 'Instructions for crafting an iron sword.',
      type: CardType.recipe,
      rarity: CardRarity.common,
      element: CardElement.none,
      level: 1,
      manaCost: 0,
      stats: {'crafting_level': 1},
      abilities: ['Learn Recipe'],
      effects: {'unlocks': 'sword_001'},
      flavorText: 'Knowledge passed down through generations.',
      artist: 'Blacksmith Guild',
      set: 'Recipe Collection',
      series: 'Basic Recipes',
      qrCode: 'ROV_CARD:recipe_001',
      tags: ['recipe', 'crafting', 'weapon'],
    ),
  ];
});

final inventoryActionsProvider = Provider((ref) {
  final eventBus = ref.watch(eventBusProvider);
  return InventoryActions(eventBus);
});

class InventoryActions {
  final EventBus _eventBus;
  InventoryActions(this._eventBus);

  void openCardPack(String packType) {
    _eventBus.publish(Event(
      type: 'card.pack_open',
      data: {'packType': packType},
    ));
  }

  void equipCard(String characterId, String cardInstanceId, String slot) {
    _eventBus.publish(Event(
      type: 'card.equip',
      data: {'characterId': characterId, 'cardInstanceId': cardInstanceId, 'slot': slot},
    ));
  }

  void unequipCard(String characterId, String slot) {
    _eventBus.publish(Event(
      type: 'card.unequip',
      data: {'characterId': characterId, 'slot': slot},
    ));
  }
}