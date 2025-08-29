import 'dart:math';
import '../../../data/models/card_model.dart';

class AdvancedCardMechanics {
  static final AdvancedCardMechanics _instance = AdvancedCardMechanics._internal();
  factory AdvancedCardMechanics() => _instance;
  AdvancedCardMechanics._internal();

  final Random _random = Random();

  /// Check for card combos in hand
  List<CardCombo> findCardCombos(List<GameCard> hand) {
    final combos = <CardCombo>[];
    
    // Check for same-type combos
    final typeGroups = <String, List<GameCard>>{};
    for (final card in hand) {
      typeGroups.putIfAbsent(card.type.name, () => []).add(card);
    }
    
    for (final entry in typeGroups.entries) {
      if (entry.value.length >= 2) {
        combos.add(CardCombo(
          id: '${entry.key}_combo_${DateTime.now().millisecondsSinceEpoch}',
          name: '${entry.key.toUpperCase()} Combo',
          description: 'Play ${entry.value.length} ${entry.key} cards together for bonus effects',
          cards: entry.value,
          type: ComboType.sameType,
          bonusDamage: entry.value.length * 5,
          bonusEffects: _getComboEffects(entry.key, entry.value.length),
        ));
      }
    }
    
    // Check for element synergies
    final elementCombos = _findElementCombos(hand);
    combos.addAll(elementCombos);
    
    // Check for specific card combinations
    final specificCombos = _findSpecificCombos(hand);
    combos.addAll(specificCombos);
    
    // Check for chain combos
    final chainCombos = _findChainCombos(hand);
    combos.addAll(chainCombos);
    
    return combos;
  }

  /// Execute a card combo
  ComboResult executeCombo(CardCombo combo, List<GameCard> hand) {
    final result = ComboResult(
      combo: combo,
      damageDealt: combo.bonusDamage,
      effectsApplied: combo.bonusEffects,
      cardsUsed: combo.cards,
    );
    
    // Apply combo effects
    for (final effect in combo.bonusEffects) {
      result.effectsApplied.add(effect);
    }
    
    // Remove cards from hand
    for (final card in combo.cards) {
      hand.remove(card);
    }
    
    // Apply special combo mechanics
    _applySpecialComboMechanics(combo, result);
    
    return result;
  }

  /// Check for card synergies
  List<CardSynergy> findCardSynergies(List<GameCard> hand, List<GameCard> playedCards) {
    final synergies = <CardSynergy>[];
    
    for (final handCard in hand) {
      for (final playedCard in playedCards) {
        final synergy = _checkCardSynergy(handCard, playedCard);
        if (synergy != null) {
          synergies.add(synergy);
        }
      }
    }
    
    return synergies;
  }

  /// Apply card synergy effects
  void applyCardSynergy(CardSynergy synergy, GameCard targetCard) {
    switch (synergy.type) {
      case SynergyType.damageBoost:
        // Update damage in stats map
        final currentStats = Map<String, dynamic>.from(targetCard.stats ?? {});
        final currentDamage = currentStats['damage'] ?? 0;
        currentStats['damage'] = (currentDamage * synergy.multiplier).round();
        // Note: This would require a copyWith method to actually update the card
        break;
      case SynergyType.costReduction:
        // Note: manaCost is final, would need to create new card instance
        break;
      case SynergyType.effectEnhancement:
        // Enhance card effects
        break;
      case SynergyType.drawBonus:
        // Add draw bonus
        break;
    }
  }

  /// Check for special card interactions
  List<SpecialInteraction> findSpecialInteractions(List<GameCard> hand, BattleState battleState) {
    final interactions = <SpecialInteraction>[];
    
    for (final card in hand) {
      // Check for environmental interactions
      final environmentalInteraction = _checkEnvironmentalInteraction(card, battleState);
      if (environmentalInteraction != null) {
        interactions.add(environmentalInteraction);
      }
      
      // Check for status-based interactions
      final statusInteraction = _checkStatusInteraction(card, battleState);
      if (statusInteraction != null) {
        interactions.add(statusInteraction);
      }
      
      // Check for turn-based interactions
      final turnInteraction = _checkTurnInteraction(card, battleState);
      if (turnInteraction != null) {
        interactions.add(turnInteraction);
      }
    }
    
    return interactions;
  }

  /// Apply special card mechanics
  void applySpecialCardMechanics(GameCard card, BattleState battleState) {
    // Apply card-specific mechanics
    switch (card.id) {
      case 'lightning_strike':
        _applyLightningStrikeMechanics(card, battleState);
        break;
      case 'fireball':
        _applyFireballMechanics(card, battleState);
        break;
      case 'ice_shield':
        _applyIceShieldMechanics(card, battleState);
        break;
      case 'healing_potion':
        _applyHealingPotionMechanics(card, battleState);
        break;
      case 'poison_dart':
        _applyPoisonDartMechanics(card, battleState);
        break;
    }
    
    // Apply rarity-based mechanics
    _applyRarityMechanics(card, battleState);
    
    // Apply element-based mechanics
    _applyElementMechanics(card, battleState);
  }

  List<CardCombo> _findElementCombos(List<GameCard> hand) {
    final combos = <CardCombo>[];
    final elementGroups = <String, List<GameCard>>{};
    
    for (final card in hand) {
      if (card.element != CardElement.none) {
        elementGroups.putIfAbsent(card.element.name, () => []).add(card);
      }
    }
    
    // Check for element combinations
    final elements = elementGroups.keys.toList();
    for (int i = 0; i < elements.length; i++) {
      for (int j = i + 1; j < elements.length; j++) {
        final element1 = elements[i];
        final element2 = elements[j];
        final combo = _getElementCombo(element1, element2, elementGroups[element1]!, elementGroups[element2]!);
        if (combo != null) {
          combos.add(combo);
        }
      }
    }
    
    return combos;
  }

  CardCombo? _getElementCombo(String element1, String element2, List<GameCard> cards1, List<GameCard> cards2) {
    // Define element combinations
    final elementCombos = {
      'fire_ice': 'steam_explosion',
      'fire_lightning': 'plasma_storm',
      'ice_lightning': 'frost_shock',
      'fire_earth': 'lava_burst',
      'ice_earth': 'crystal_barrier',
      'lightning_earth': 'magnetic_pulse',
    };
    
    final comboKey = '${element1}_${element2}';
    final reverseComboKey = '${element2}_${element1}';
    
    String? comboName;
    if (elementCombos.containsKey(comboKey)) {
      comboName = elementCombos[comboKey];
    } else if (elementCombos.containsKey(reverseComboKey)) {
      comboName = elementCombos[reverseComboKey];
    }
    
    if (comboName != null) {
      final allCards = [...cards1, ...cards2];
      return CardCombo(
        id: '${comboName}_${DateTime.now().millisecondsSinceEpoch}',
        name: comboName.replaceAll('_', ' ').toUpperCase(),
        description: 'Combine $element1 and $element2 elements for powerful effects',
        cards: allCards,
        type: ComboType.elemental,
        bonusDamage: allCards.length * 10,
        bonusEffects: _getElementalComboEffects(comboName),
      );
    }
    
    return null;
  }

  List<CardCombo> _findSpecificCombos(List<GameCard> hand) {
    final combos = <CardCombo>[];
    
    // Check for specific card combinations
    final cardIds = hand.map((c) => c.id).toSet();
    
    // Fire combo
    if (cardIds.contains('fireball') && cardIds.contains('flame_burst') && cardIds.contains('inferno')) {
      final fireCards = hand.where((c) => ['fireball', 'flame_burst', 'inferno'].contains(c.id)).toList();
      combos.add(CardCombo(
        id: 'fire_trinity_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Fire Trinity',
        description: 'Unleash the power of fire with three fire spells',
        cards: fireCards,
        type: ComboType.specific,
        bonusDamage: 50,
        bonusEffects: [
          CardEffect(type: 'burn', duration: 3, value: 10),
          CardEffect(type: 'area_damage', duration: 1, value: 20),
        ],
      ));
    }
    
    // Lightning combo
    if (cardIds.contains('lightning_strike') && cardIds.contains('thunder_clap') && cardIds.contains('storm_call')) {
      final lightningCards = hand.where((c) => ['lightning_strike', 'thunder_clap', 'storm_call'].contains(c.id)).toList();
      combos.add(CardCombo(
        id: 'lightning_storm_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Lightning Storm',
        description: 'Channel the power of lightning and thunder',
        cards: lightningCards,
        type: ComboType.specific,
        bonusDamage: 60,
        bonusEffects: [
          CardEffect(type: 'stun', duration: 2, value: 1),
          CardEffect(type: 'chain_lightning', duration: 1, value: 15),
        ],
      ));
    }
    
    return combos;
  }

  List<CardCombo> _findChainCombos(List<GameCard> hand) {
    final combos = <CardCombo>[];
    
    // Find cards that can chain together
    final chainableCards = hand.where((c) => c.tags?.contains('chain') ?? false).toList();
    
    if (chainableCards.length >= 2) {
      // Sort by chain order
      chainableCards.sort((a, b) {
        final orderA = a.tags?.firstWhere((k) => k.startsWith('chain_'), orElse: () => 'chain_0') ?? 'chain_0';
        final orderB = b.tags?.firstWhere((k) => k.startsWith('chain_'), orElse: () => 'chain_0') ?? 'chain_0';
        return orderA.compareTo(orderB);
      });
      
      combos.add(CardCombo(
        id: 'chain_combo_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Chain Reaction',
        description: 'Execute a chain of ${chainableCards.length} cards',
        cards: chainableCards,
        type: ComboType.chain,
        bonusDamage: chainableCards.length * 15,
        bonusEffects: [
          CardEffect(type: 'chain_bonus', duration: 1, value: chainableCards.length * 5),
        ],
      ));
    }
    
    return combos;
  }

  List<CardEffect> _getComboEffects(String type, int count) {
    switch (type) {
      case 'attack':
        return [
          CardEffect(type: 'damage_boost', duration: 1, value: count * 5),
          CardEffect(type: 'critical_chance', duration: 1, value: count * 10),
        ];
      case 'defense':
        return [
          CardEffect(type: 'armor_boost', duration: 2, value: count * 3),
          CardEffect(type: 'damage_reduction', duration: 1, value: count * 5),
        ];
      case 'magic':
        return [
          CardEffect(type: 'mana_boost', duration: 1, value: count * 2),
          CardEffect(type: 'spell_power', duration: 2, value: count * 3),
        ];
      default:
        return [];
    }
  }

  List<CardEffect> _getElementalComboEffects(String comboName) {
    switch (comboName) {
      case 'steam_explosion':
        return [
          CardEffect(type: 'blind', duration: 2, value: 1),
          CardEffect(type: 'area_damage', duration: 1, value: 25),
        ];
      case 'plasma_storm':
        return [
          CardEffect(type: 'stun', duration: 1, value: 1),
          CardEffect(type: 'chain_damage', duration: 1, value: 20),
        ];
      case 'frost_shock':
        return [
          CardEffect(type: 'freeze', duration: 2, value: 1),
          CardEffect(type: 'vulnerability', duration: 1, value: 15),
        ];
      default:
        return [];
    }
  }

  void _applySpecialComboMechanics(CardCombo combo, ComboResult result) {
    switch (combo.type) {
      case ComboType.elemental:
        result.damageDealt = (result.damageDealt * 1.5).round();
        break;
      case ComboType.chain:
        result.damageDealt = (result.damageDealt * 1.3).round();
        break;
      case ComboType.specific:
        result.damageDealt = (result.damageDealt * 1.2).round();
        break;
      case ComboType.sameType:
        // Standard bonus
        break;
    }
  }

  CardSynergy? _checkCardSynergy(GameCard card1, GameCard card2) {
    // Check for element synergy
    if (card1.element == card2.element && card1.element != null) {
      return CardSynergy(
        type: SynergyType.damageBoost,
        multiplier: 1.5,
        description: '${card1.element} synergy: +50% damage',
      );
    }
    
    // Check for type synergy
    if (card1.type == card2.type) {
      return CardSynergy(
        type: SynergyType.costReduction,
        multiplier: 0.8,
        description: '${card1.type} synergy: -20% cost',
      );
    }
    
    // Check for specific card synergies
    if (_hasSpecificSynergy(card1, card2)) {
      return CardSynergy(
        type: SynergyType.effectEnhancement,
        multiplier: 1.3,
        description: 'Special synergy: +30% effect',
      );
    }
    
    return null;
  }

  bool _hasSpecificSynergy(GameCard card1, GameCard card2) {
    final synergyPairs = [
      ['fireball', 'flame_burst'],
      ['lightning_strike', 'thunder_clap'],
      ['ice_shield', 'frost_nova'],
      ['healing_potion', 'vitality_boost'],
    ];
    
    for (final pair in synergyPairs) {
      if ((pair[0] == card1.id && pair[1] == card2.id) ||
          (pair[0] == card2.id && pair[1] == card1.id)) {
        return true;
      }
    }
    
    return false;
  }

  SpecialInteraction? _checkEnvironmentalInteraction(GameCard card, BattleState battleState) {
    // Check for weather-based interactions
    if (battleState.weather != null) {
      if (card.element == 'fire' && battleState.weather!.contains('rain')) {
        return SpecialInteraction(
          type: InteractionType.environmental,
          description: 'Fire spells are weakened in rain',
          effect: CardEffect(type: 'damage_reduction', duration: 1, value: 20),
        );
      }
      
      if (card.element == 'lightning' && battleState.weather!.contains('storm')) {
        return SpecialInteraction(
          type: InteractionType.environmental,
          description: 'Lightning spells are enhanced in storms',
          effect: CardEffect(type: 'damage_boost', duration: 1, value: 30),
        );
      }
    }
    
    return null;
  }

  SpecialInteraction? _checkStatusInteraction(GameCard card, BattleState battleState) {
    // Check for status-based interactions
    if (battleState.playerEffects.containsKey('poisoned')) {
      if (card.tags?.contains('healing') ?? false) {
        return SpecialInteraction(
          type: InteractionType.status,
          description: 'Healing spells are more effective when poisoned',
          effect: CardEffect(type: 'healing_boost', duration: 1, value: 25),
        );
      }
    }
    
    if (battleState.enemyEffects.containsKey('burning')) {
      if (card.element == CardElement.ice) {
        return SpecialInteraction(
          type: InteractionType.status,
          description: 'Ice spells deal extra damage to burning enemies',
          effect: CardEffect(type: 'damage_boost', duration: 1, value: 40),
        );
      }
    }
    
    return null;
  }

  SpecialInteraction? _checkTurnInteraction(GameCard card, BattleState battleState) {
    // Check for turn-based interactions
    if (battleState.turnNumber == 1) {
      if (card.tags?.contains('opening') ?? false) {
        return SpecialInteraction(
          type: InteractionType.turn,
          description: 'Opening cards are enhanced on the first turn',
          effect: CardEffect(type: 'damage_boost', duration: 1, value: 20),
        );
      }
    }
    
    if (battleState.turnNumber >= 10) {
      if (card.tags?.contains('finisher') ?? false) {
        return SpecialInteraction(
          type: InteractionType.turn,
          description: 'Finisher cards are enhanced in late game',
          effect: CardEffect(type: 'damage_boost', duration: 1, value: 35),
        );
      }
    }
    
    return null;
  }

  void _applyLightningStrikeMechanics(GameCard card, BattleState battleState) {
    // Lightning Strike has a chance to chain to other enemies
    if (_random.nextDouble() < 0.3) {
      battleState.addEffect('chain_lightning', 1);
    }
  }

  void _applyFireballMechanics(GameCard card, BattleState battleState) {
    // Fireball has a chance to cause burning
    if (_random.nextDouble() < 0.4) {
      battleState.addEffect('burning', 2);
    }
  }

  void _applyIceShieldMechanics(GameCard card, BattleState battleState) {
    // Ice Shield provides temporary invulnerability
    battleState.addEffect('invulnerable', 1);
  }

  void _applyHealingPotionMechanics(GameCard card, BattleState battleState) {
    // Healing Potion removes negative effects
    battleState.removeEffect('poisoned');
    battleState.removeEffect('burning');
  }

  void _applyPoisonDartMechanics(GameCard card, BattleState battleState) {
    // Poison Dart has a chance to cause poisoning
    if (_random.nextDouble() < 0.5) {
      battleState.addEffect('poisoned', 3);
    }
  }

  void _applyRarityMechanics(GameCard card, BattleState battleState) {
    // Note: Card properties are immutable, so we can't modify them directly
    // This would need to be handled through a different mechanism
    switch (card.rarity) {
      case CardRarity.rare:
        // Apply 1.2x damage multiplier through battle state
        break;
      case CardRarity.epic:
        // Apply 1.5x damage multiplier through battle state
        break;
      case CardRarity.legendary:
        // Apply 2.0x damage multiplier through battle state
        break;
      default:
        break;
    }
  }

  void _applyElementMechanics(GameCard card, BattleState battleState) {
    if (card.element != CardElement.none) {
      switch (card.element) {
        case CardElement.fire:
          // Apply 1.1x damage multiplier through battle state
          break;
        case CardElement.ice:
          // Apply 0.9x cost multiplier through battle state
          break;
        case CardElement.lightning:
          if (_random.nextDouble() < 0.2) {
            // Apply 1.5x damage multiplier through battle state
          }
          break;
        case CardElement.earth:
          // Apply 1.2x defense multiplier through battle state
          break;
        default:
          break;
      }
    }
  }
}

class CardCombo {
  final String id;
  final String name;
  final String description;
  final List<GameCard> cards;
  final ComboType type;
  final int bonusDamage;
  final List<CardEffect> bonusEffects;

  CardCombo({
    required this.id,
    required this.name,
    required this.description,
    required this.cards,
    required this.type,
    required this.bonusDamage,
    required this.bonusEffects,
  });
}

enum ComboType {
  sameType,
  elemental,
  specific,
  chain,
}

class ComboResult {
  final CardCombo combo;
  int damageDealt;
  final List<CardEffect> effectsApplied;
  final List<GameCard> cardsUsed;

  ComboResult({
    required this.combo,
    required this.damageDealt,
    required this.effectsApplied,
    required this.cardsUsed,
  });
}

class CardSynergy {
  final SynergyType type;
  final double multiplier;
  final String description;

  CardSynergy({
    required this.type,
    required this.multiplier,
    required this.description,
  });
}

enum SynergyType {
  damageBoost,
  costReduction,
  effectEnhancement,
  drawBonus,
}

class SpecialInteraction {
  final InteractionType type;
  final String description;
  final CardEffect effect;

  SpecialInteraction({
    required this.type,
    required this.description,
    required this.effect,
  });
}

enum InteractionType {
  environmental,
  status,
  turn,
}

class CardEffect {
  final String type;
  final int duration;
  final int value;

  CardEffect({
    required this.type,
    required this.duration,
    required this.value,
  });
}

class BattleState {
  int turnNumber = 1;
  String? weather;
  final Map<String, int> playerEffects = {};
  final Map<String, int> enemyEffects = {};

  void addEffect(String effect, int duration) {
    playerEffects[effect] = duration;
  }

  void removeEffect(String effect) {
    playerEffects.remove(effect);
  }
}
