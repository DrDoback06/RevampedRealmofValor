import 'card_model.dart';
import 'dart:math';

class ExampleCards {
  static final Random _random = Random();

  /// Get all available cards
  static List<GameCard> getAllCards() {
    return [
      ...getCommonCards(),
      ...getUncommonCards(),
      ...getRareCards(),
      ...getEpicCards(),
      ...getLegendaryCards(),
    ];
  }

  /// Get common cards
  static List<GameCard> getCommonCards() {
    return [
      GameCard(
        id: 'basic_sword',
        name: 'Iron Sword',
        description: 'A reliable iron sword for basic combat',
        type: CardType.equipment,
        rarity: CardRarity.common,
        element: CardElement.none,
        level: 1,
        manaCost: 1,
        stats: {'damage': 5, 'durability': 10},
        abilities: ['attack'],
        tags: ['weapon', 'sword'],
      ),
      GameCard(
        id: 'leather_armor',
        name: 'Leather Armor',
        description: 'Light leather armor offering basic protection',
        type: CardType.equipment,
        rarity: CardRarity.common,
        element: CardElement.none,
        level: 1,
        manaCost: 1,
        stats: {'defense': 3, 'durability': 8},
        abilities: ['defend'],
        tags: ['armor', 'leather'],
      ),
      GameCard(
        id: 'health_potion',
        name: 'Health Potion',
        description: 'Restores a small amount of health',
        type: CardType.consumable,
        rarity: CardRarity.common,
        element: CardElement.none,
        level: 1,
        manaCost: 0,
        stats: {'healing': 15},
        abilities: ['heal'],
        tags: ['potion', 'healing'],
      ),
      GameCard(
        id: 'fire_bolt',
        name: 'Fire Bolt',
        description: 'A simple fire spell',
        type: CardType.spell,
        rarity: CardRarity.common,
        element: CardElement.fire,
        level: 1,
        manaCost: 2,
        stats: {'damage': 8},
        abilities: ['spell', 'fire'],
        tags: ['spell', 'fire'],
      ),
      GameCard(
        id: 'ice_shard',
        name: 'Ice Shard',
        description: 'A sharp shard of ice',
        type: CardType.spell,
        rarity: CardRarity.common,
        element: CardElement.ice,
        level: 1,
        manaCost: 2,
        stats: {'damage': 7, 'slow': 1},
        abilities: ['spell', 'ice'],
        tags: ['spell', 'ice'],
      ),
      GameCard(
        id: 'lightning_strike',
        name: 'Lightning Strike',
        description: 'A quick lightning attack',
        type: CardType.spell,
        rarity: CardRarity.common,
        element: CardElement.lightning,
        level: 1,
        manaCost: 2,
        stats: {'damage': 9},
        abilities: ['spell', 'lightning'],
        tags: ['spell', 'lightning'],
      ),
      GameCard(
        id: 'heal_wounds',
        name: 'Heal Wounds',
        description: 'Basic healing magic',
        type: CardType.spell,
        rarity: CardRarity.common,
        element: CardElement.light,
        level: 1,
        manaCost: 2,
        stats: {'healing': 12},
        abilities: ['heal'],
        tags: ['spell', 'healing'],
      ),
      GameCard(
        id: 'shield_block',
        name: 'Shield Block',
        description: 'Block incoming damage',
        type: CardType.skill,
        rarity: CardRarity.common,
        element: CardElement.none,
        level: 1,
        manaCost: 1,
        stats: {'block': 8},
        abilities: ['defend'],
        tags: ['skill', 'defensive'],
      ),
    ];
  }

  /// Get uncommon cards
  static List<GameCard> getUncommonCards() {
    return [
      GameCard(
        id: 'steel_sword',
        name: 'Steel Sword',
        description: 'A well-crafted steel sword',
        type: CardType.equipment,
        rarity: CardRarity.uncommon,
        element: CardElement.none,
        level: 3,
        manaCost: 2,
        stats: {'damage': 8, 'durability': 15},
        abilities: ['attack', 'pierce'],
        tags: ['weapon', 'sword'],
      ),
      GameCard(
        id: 'chain_mail',
        name: 'Chain Mail',
        description: 'Flexible metal armor',
        type: CardType.equipment,
        rarity: CardRarity.uncommon,
        element: CardElement.none,
        level: 3,
        manaCost: 2,
        stats: {'defense': 6, 'durability': 12},
        abilities: ['defend'],
        tags: ['armor', 'metal'],
      ),
      GameCard(
        id: 'fireball',
        name: 'Fireball',
        description: 'A powerful fire explosion',
        type: CardType.spell,
        rarity: CardRarity.uncommon,
        element: CardElement.fire,
        level: 3,
        manaCost: 3,
        stats: {'damage': 15, 'burn': 2},
        abilities: ['spell', 'fire', 'aoe'],
        tags: ['spell', 'fire', 'aoe'],
      ),
      GameCard(
        id: 'frost_nova',
        name: 'Frost Nova',
        description: 'Freeze enemies in an area',
        type: CardType.spell,
        rarity: CardRarity.uncommon,
        element: CardElement.ice,
        level: 3,
        manaCost: 3,
        stats: {'damage': 10, 'freeze': 2},
        abilities: ['spell', 'ice', 'aoe'],
        tags: ['spell', 'ice', 'aoe'],
      ),
      GameCard(
        id: 'chain_lightning',
        name: 'Chain Lightning',
        description: 'Lightning that jumps between enemies',
        type: CardType.spell,
        rarity: CardRarity.uncommon,
        element: CardElement.lightning,
        level: 3,
        manaCost: 3,
        stats: {'damage': 12, 'chain': 3},
        abilities: ['spell', 'lightning', 'chain'],
        tags: ['spell', 'lightning', 'chain'],
      ),
      GameCard(
        id: 'greater_heal',
        name: 'Greater Heal',
        description: 'Powerful healing magic',
        type: CardType.spell,
        rarity: CardRarity.uncommon,
        element: CardElement.light,
        level: 3,
        manaCost: 3,
        stats: {'healing': 25},
        abilities: ['heal'],
        tags: ['spell', 'healing'],
      ),
      GameCard(
        id: 'berserker_rage',
        name: 'Berserker Rage',
        description: 'Increase attack power at the cost of defense',
        type: CardType.skill,
        rarity: CardRarity.uncommon,
        element: CardElement.none,
        level: 3,
        manaCost: 2,
        stats: {'attack_buff': 5, 'defense_debuff': 2},
        abilities: ['buff', 'rage'],
        tags: ['skill', 'buff'],
      ),
      GameCard(
        id: 'poison_strike',
        name: 'Poison Strike',
        description: 'Attack that poisons the target',
        type: CardType.skill,
        rarity: CardRarity.uncommon,
        element: CardElement.none,
        level: 3,
        manaCost: 2,
        stats: {'damage': 6, 'poison': 3},
        abilities: ['attack', 'poison'],
        tags: ['skill', 'poison'],
      ),
    ];
  }

  /// Get rare cards
  static List<GameCard> getRareCards() {
    return [
      GameCard(
        id: 'flame_sword',
        name: 'Flame Sword',
        description: 'A sword wreathed in magical flames',
        type: CardType.equipment,
        rarity: CardRarity.rare,
        element: CardElement.fire,
        level: 5,
        manaCost: 3,
        stats: {'damage': 12, 'fire_damage': 5, 'durability': 20},
        abilities: ['attack', 'fire'],
        tags: ['weapon', 'sword', 'fire'],
      ),
      GameCard(
        id: 'ice_armor',
        name: 'Ice Armor',
        description: 'Armor made of enchanted ice',
        type: CardType.equipment,
        rarity: CardRarity.rare,
        element: CardElement.ice,
        level: 5,
        manaCost: 3,
        stats: {'defense': 10, 'ice_resistance': 5, 'durability': 18},
        abilities: ['defend', 'ice'],
        tags: ['armor', 'ice'],
      ),
      GameCard(
        id: 'thunder_hammer',
        name: 'Thunder Hammer',
        description: 'A hammer that crackles with lightning',
        type: CardType.equipment,
        rarity: CardRarity.rare,
        element: CardElement.lightning,
        level: 5,
        manaCost: 3,
        stats: {'damage': 15, 'lightning_damage': 8, 'durability': 25},
        abilities: ['attack', 'lightning'],
        tags: ['weapon', 'hammer', 'lightning'],
      ),
      GameCard(
        id: 'inferno',
        name: 'Inferno',
        description: 'Create a massive firestorm',
        type: CardType.spell,
        rarity: CardRarity.rare,
        element: CardElement.fire,
        level: 5,
        manaCost: 5,
        stats: {'damage': 25, 'burn': 5, 'aoe': 3},
        abilities: ['spell', 'fire', 'aoe'],
        tags: ['spell', 'fire', 'aoe'],
      ),
      GameCard(
        id: 'blizzard',
        name: 'Blizzard',
        description: 'Summon a devastating ice storm',
        type: CardType.spell,
        rarity: CardRarity.rare,
        element: CardElement.ice,
        level: 5,
        manaCost: 5,
        stats: {'damage': 20, 'freeze': 4, 'aoe': 3},
        abilities: ['spell', 'ice', 'aoe'],
        tags: ['spell', 'ice', 'aoe'],
      ),
      GameCard(
        id: 'storm_call',
        name: 'Storm Call',
        description: 'Summon the power of lightning',
        type: CardType.spell,
        rarity: CardRarity.rare,
        element: CardElement.lightning,
        level: 5,
        manaCost: 5,
        stats: {'damage': 22, 'stun': 2, 'aoe': 2},
        abilities: ['spell', 'lightning', 'aoe'],
        tags: ['spell', 'lightning', 'aoe'],
      ),
      GameCard(
        id: 'divine_heal',
        name: 'Divine Heal',
        description: 'Miraculous healing from the divine',
        type: CardType.spell,
        rarity: CardRarity.rare,
        element: CardElement.light,
        level: 5,
        manaCost: 4,
        stats: {'healing': 40, 'cleanse': 1},
        abilities: ['heal', 'cleanse'],
        tags: ['spell', 'healing', 'divine'],
      ),
      GameCard(
        id: 'shadow_step',
        name: 'Shadow Step',
        description: 'Teleport through shadows',
        type: CardType.skill,
        rarity: CardRarity.rare,
        element: CardElement.none,
        level: 5,
        manaCost: 3,
        stats: {'teleport': 1, 'stealth': 2},
        abilities: ['teleport', 'stealth'],
        tags: ['skill', 'stealth'],
      ),
    ];
  }

  /// Get epic cards
  static List<GameCard> getEpicCards() {
    return [
      GameCard(
        id: 'dragon_sword',
        name: 'Dragon Sword',
        description: 'Forged from dragon scales and fire',
        type: CardType.equipment,
        rarity: CardRarity.epic,
        element: CardElement.fire,
        level: 8,
        manaCost: 4,
        stats: {'damage': 20, 'fire_damage': 10, 'durability': 30},
        abilities: ['attack', 'fire', 'dragon'],
        tags: ['weapon', 'sword', 'fire', 'dragon'],
      ),
      GameCard(
        id: 'crystal_armor',
        name: 'Crystal Armor',
        description: 'Armor made of pure magical crystal',
        type: CardType.equipment,
        rarity: CardRarity.epic,
        element: CardElement.none,
        level: 8,
        manaCost: 4,
        stats: {'defense': 15, 'magic_resistance': 10, 'durability': 35},
        abilities: ['defend', 'magic'],
        tags: ['armor', 'crystal', 'magic'],
      ),
      GameCard(
        id: 'storm_breaker',
        name: 'Storm Breaker',
        description: 'A legendary axe that controls storms',
        type: CardType.equipment,
        rarity: CardRarity.epic,
        element: CardElement.lightning,
        level: 8,
        manaCost: 4,
        stats: {'damage': 25, 'lightning_damage': 15, 'durability': 40},
        abilities: ['attack', 'lightning', 'storm'],
        tags: ['weapon', 'axe', 'lightning', 'storm'],
      ),
      GameCard(
        id: 'meteor_strike',
        name: 'Meteor Strike',
        description: 'Summon a meteor from the heavens',
        type: CardType.spell,
        rarity: CardRarity.epic,
        element: CardElement.fire,
        level: 8,
        manaCost: 7,
        stats: {'damage': 40, 'burn': 8, 'aoe': 4},
        abilities: ['spell', 'fire', 'aoe', 'meteor'],
        tags: ['spell', 'fire', 'aoe', 'meteor'],
      ),
      GameCard(
        id: 'eternal_winter',
        name: 'Eternal Winter',
        description: 'Freeze time itself with ice magic',
        type: CardType.spell,
        rarity: CardRarity.epic,
        element: CardElement.ice,
        level: 8,
        manaCost: 7,
        stats: {'damage': 35, 'freeze': 6, 'aoe': 4},
        abilities: ['spell', 'ice', 'aoe', 'time'],
        tags: ['spell', 'ice', 'aoe', 'time'],
      ),
      GameCard(
        id: 'thunder_god',
        name: 'Thunder God',
        description: 'Channel the power of the thunder god',
        type: CardType.spell,
        rarity: CardRarity.epic,
        element: CardElement.lightning,
        level: 8,
        manaCost: 7,
        stats: {'damage': 45, 'stun': 4, 'aoe': 3},
        abilities: ['spell', 'lightning', 'aoe', 'god'],
        tags: ['spell', 'lightning', 'aoe', 'god'],
      ),
      GameCard(
        id: 'resurrection',
        name: 'Resurrection',
        description: 'Bring the dead back to life',
        type: CardType.spell,
        rarity: CardRarity.epic,
        element: CardElement.light,
        level: 8,
        manaCost: 8,
        stats: {'revive': 1, 'healing': 50},
        abilities: ['revive', 'heal'],
        tags: ['spell', 'healing', 'divine'],
      ),
      GameCard(
        id: 'time_warp',
        name: 'Time Warp',
        description: 'Manipulate the flow of time',
        type: CardType.skill,
        rarity: CardRarity.epic,
        element: CardElement.none,
        level: 8,
        manaCost: 5,
        stats: {'time_manipulation': 1, 'cooldown_reduction': 2},
        abilities: ['time', 'manipulation'],
        tags: ['skill', 'time'],
      ),
    ];
  }

  /// Get legendary cards
  static List<GameCard> getLegendaryCards() {
    return [
      GameCard(
        id: 'excalibur',
        name: 'Excalibur',
        description: 'The legendary sword of kings',
        type: CardType.equipment,
        rarity: CardRarity.legendary,
        element: CardElement.none,
        level: 10,
        manaCost: 5,
        stats: {'damage': 30, 'holy_damage': 20, 'durability': 50},
        abilities: ['attack', 'holy', 'legendary'],
        tags: ['weapon', 'sword', 'holy', 'legendary'],
      ),
      GameCard(
        id: 'armor_of_the_gods',
        name: 'Armor of the Gods',
        description: 'Divine armor blessed by the gods',
        type: CardType.equipment,
        rarity: CardRarity.legendary,
        element: CardElement.light,
        level: 10,
        manaCost: 5,
        stats: {'defense': 25, 'holy_resistance': 15, 'durability': 60},
        abilities: ['defend', 'holy', 'legendary'],
        tags: ['armor', 'holy', 'legendary'],
      ),
      GameCard(
        id: 'world_ender',
        name: 'World Ender',
        description: 'A weapon that can destroy worlds',
        type: CardType.equipment,
        rarity: CardRarity.legendary,
        element: CardElement.none,
        level: 10,
        manaCost: 6,
        stats: {'damage': 50, 'world_damage': 30, 'durability': 100},
        abilities: ['attack', 'world', 'legendary'],
        tags: ['weapon', 'legendary', 'world'],
      ),
      GameCard(
        id: 'apocalypse',
        name: 'Apocalypse',
        description: 'Unleash the end of days',
        type: CardType.spell,
        rarity: CardRarity.legendary,
        element: CardElement.none,
        level: 10,
        manaCost: 10,
        stats: {'damage': 100, 'aoe': 10, 'apocalypse': 1},
        abilities: ['spell', 'aoe', 'apocalypse'],
        tags: ['spell', 'legendary', 'apocalypse'],
      ),
      GameCard(
        id: 'creation',
        name: 'Creation',
        description: 'Create something from nothing',
        type: CardType.spell,
        rarity: CardRarity.legendary,
        element: CardElement.none,
        level: 10,
        manaCost: 10,
        stats: {'creation': 1, 'power': 100},
        abilities: ['create', 'legendary'],
        tags: ['spell', 'legendary', 'creation'],
      ),
    ];
  }

  /// Get cards by rarity
  static List<GameCard> getCardsByRarity(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return getCommonCards();
      case CardRarity.uncommon:
        return getUncommonCards();
      case CardRarity.rare:
        return getRareCards();
      case CardRarity.epic:
        return getEpicCards();
      case CardRarity.legendary:
        return getLegendaryCards();
      case CardRarity.mythic:
        return getLegendaryCards(); // Mythic cards are treated as legendary for now
    }
  }

  /// Get cards by element
  static List<GameCard> getCardsByElement(CardElement element) {
    return getAllCards().where((card) => card.element == element).toList();
  }

  /// Get cards by type
  static List<GameCard> getCardsByType(CardType type) {
    return getAllCards().where((card) => card.type == type).toList();
  }

  /// Get a random card
  static GameCard getRandomCard() {
    final allCards = getAllCards();
    return allCards[_random.nextInt(allCards.length)];
  }

  /// Get a random card by rarity
  static GameCard getRandomCardByRarity(CardRarity rarity) {
    final cards = getCardsByRarity(rarity);
    return cards[_random.nextInt(cards.length)];
  }

  /// Open a card pack
  static List<GameCard> openPack() {
    final pack = <GameCard>[];
    
    // Common cards (70% chance)
    for (int i = 0; i < 5; i++) {
      if (_random.nextDouble() < 0.7) {
        pack.add(getRandomCardByRarity(CardRarity.common));
      }
    }
    
    // Uncommon cards (20% chance)
    for (int i = 0; i < 3; i++) {
      if (_random.nextDouble() < 0.2) {
        pack.add(getRandomCardByRarity(CardRarity.uncommon));
      }
    }
    
    // Rare cards (8% chance)
    for (int i = 0; i < 2; i++) {
      if (_random.nextDouble() < 0.08) {
        pack.add(getRandomCardByRarity(CardRarity.rare));
      }
    }
    
    // Epic cards (1.5% chance)
    if (_random.nextDouble() < 0.015) {
      pack.add(getRandomCardByRarity(CardRarity.epic));
    }
    
    // Legendary cards (0.5% chance)
    if (_random.nextDouble() < 0.005) {
      pack.add(getRandomCardByRarity(CardRarity.legendary));
    }
    
    // Ensure at least 3 cards
    while (pack.length < 3) {
      pack.add(getRandomCardByRarity(CardRarity.common));
    }
    
    return pack;
  }

  /// Open a premium pack (better odds)
  static List<GameCard> openPremiumPack() {
    final pack = <GameCard>[];
    
    // Common cards (50% chance)
    for (int i = 0; i < 5; i++) {
      if (_random.nextDouble() < 0.5) {
        pack.add(getRandomCardByRarity(CardRarity.common));
      }
    }
    
    // Uncommon cards (30% chance)
    for (int i = 0; i < 3; i++) {
      if (_random.nextDouble() < 0.3) {
        pack.add(getRandomCardByRarity(CardRarity.uncommon));
      }
    }
    
    // Rare cards (15% chance)
    for (int i = 0; i < 2; i++) {
      if (_random.nextDouble() < 0.15) {
        pack.add(getRandomCardByRarity(CardRarity.rare));
      }
    }
    
    // Epic cards (4% chance)
    if (_random.nextDouble() < 0.04) {
      pack.add(getRandomCardByRarity(CardRarity.epic));
    }
    
    // Legendary cards (1% chance)
    if (_random.nextDouble() < 0.01) {
      pack.add(getRandomCardByRarity(CardRarity.legendary));
    }
    
    // Ensure at least 5 cards
    while (pack.length < 5) {
      pack.add(getRandomCardByRarity(CardRarity.uncommon));
    }
    
    return pack;
  }
}
