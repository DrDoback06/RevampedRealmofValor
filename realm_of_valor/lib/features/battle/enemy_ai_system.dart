import 'dart:math';
import '../../../data/models/card_model.dart';

class EnemyAISystem {
  static final EnemyAISystem _instance = EnemyAISystem._internal();
  factory EnemyAISystem() => _instance;
  EnemyAISystem._internal();

  final Random _random = Random();

  /// Generate AI decision for enemy turn
  AIAction generateAIAction(EnemyAIState aiState, BattleState battleState) {
    // Update AI state based on current battle situation
    _updateAIState(aiState, battleState);
    
    // Determine action based on AI personality and current state
    switch (aiState.personality) {
      case AIPersonality.aggressive:
        return _generateAggressiveAction(aiState, battleState);
      case AIPersonality.defensive:
        return _generateDefensiveAction(aiState, battleState);
      case AIPersonality.tactical:
        return _generateTacticalAction(aiState, battleState);
      case AIPersonality.random:
        return _generateRandomAction(aiState, battleState);
      case AIPersonality.adaptive:
        return _generateAdaptiveAction(aiState, battleState);
    }
  }

  /// Update AI state based on battle situation
  void _updateAIState(EnemyAIState aiState, BattleState battleState) {
    // Update health percentage
    aiState.healthPercentage = battleState.enemyHp / battleState.enemyMaxHp;
    
    // Update threat level
    aiState.threatLevel = _calculateThreatLevel(battleState);
    
    // Update resource availability
    aiState.manaAvailable = battleState.enemyMana;
    aiState.cardsInHand = battleState.enemyHand.length;
    
    // Update battle phase
    aiState.battlePhase = _determineBattlePhase(battleState);
    
    // Update learning from previous actions
    _updateLearning(aiState, battleState);
  }

  AIAction _generateAggressiveAction(EnemyAIState aiState, BattleState battleState) {
    // Aggressive AI prioritizes damage dealing
    final availableCards = battleState.enemyHand.where((card) => 
        card.cost <= battleState.enemyMana).toList();
    
    if (availableCards.isEmpty) {
      return AIAction(type: ActionType.pass, card: null, target: null);
    }
    
    // Sort by damage potential
    availableCards.sort((a, b) => b.damage.compareTo(a.damage));
    
    // Consider combo potential
    final combos = _findEnemyCombos(availableCards);
    if (combos.isNotEmpty) {
      final bestCombo = combos.first;
      return AIAction(
        type: ActionType.playCombo,
        card: bestCombo.cards.first,
        target: 'player',
        combo: bestCombo,
      );
    }
    
    // Play highest damage card
    final bestCard = availableCards.first;
    return AIAction(
      type: ActionType.playCard,
      card: bestCard,
      target: 'player',
    );
  }

  AIAction _generateDefensiveAction(EnemyAIState aiState, BattleState battleState) {
    // Defensive AI prioritizes survival and healing
    final availableCards = battleState.enemyHand.where((card) => 
        card.cost <= battleState.enemyMana).toList();
    
    if (availableCards.isEmpty) {
      return AIAction(type: ActionType.pass, card: null, target: null);
    }
    
    // Check if health is low and healing is available
    if (aiState.healthPercentage < 0.3) {
      final healingCards = availableCards.where((card) => 
          card.keywords.contains('healing')).toList();
      if (healingCards.isNotEmpty) {
        return AIAction(
          type: ActionType.playCard,
          card: healingCards.first,
          target: 'self',
        );
      }
    }
    
    // Look for defensive cards
    final defensiveCards = availableCards.where((card) => 
        card.keywords.contains('defense') || 
        card.keywords.contains('shield') ||
        card.defense > 0).toList();
    
    if (defensiveCards.isNotEmpty) {
      return AIAction(
        type: ActionType.playCard,
        card: defensiveCards.first,
        target: 'self',
      );
    }
    
    // If no defensive options, play best available card
    availableCards.sort((a, b) => (b.defense + b.damage).compareTo(a.defense + a.damage));
    return AIAction(
      type: ActionType.playCard,
      card: availableCards.first,
      target: 'player',
    );
  }

  AIAction _generateTacticalAction(EnemyAIState aiState, BattleState battleState) {
    // Tactical AI considers multiple factors and adapts strategy
    final availableCards = battleState.enemyHand.where((card) => 
        card.cost <= battleState.enemyMana).toList();
    
    if (availableCards.isEmpty) {
      return AIAction(type: ActionType.pass, card: null, target: null);
    }
    
    // Calculate card scores based on multiple factors
    final cardScores = <GameCard, double>{};
    for (final card in availableCards) {
      double score = 0;
      
      // Base damage/defense score
      score += card.damage * 0.5;
      score += card.defense * 0.3;
      
      // Health-based adjustments
      if (aiState.healthPercentage < 0.3 && card.keywords.contains('healing')) {
        score += 50;
      }
      
      // Mana efficiency
      score += (card.damage + card.defense) / card.cost * 10;
      
      // Elemental advantages
      if (_hasElementalAdvantage(card, battleState)) {
        score += 20;
      }
      
      // Combo potential
      if (_hasComboPotential(card, availableCards)) {
        score += 15;
      }
      
      cardScores[card] = score;
    }
    
    // Play best scoring card
    final bestCard = cardScores.entries
        .reduce((a, b) => a.value > b.value ? a : b).key;
    
    final target = bestCard.keywords.contains('healing') ? 'self' : 'player';
    
    return AIAction(
      type: ActionType.playCard,
      card: bestCard,
      target: target,
    );
  }

  AIAction _generateRandomAction(EnemyAIState aiState, BattleState battleState) {
    // Random AI makes unpredictable decisions
    final availableCards = battleState.enemyHand.where((card) => 
        card.cost <= battleState.enemyMana).toList();
    
    if (availableCards.isEmpty) {
      return AIAction(type: ActionType.pass, card: null, target: null);
    }
    
    // Randomly choose action type
    final actionTypes = [ActionType.playCard, ActionType.pass];
    final chosenType = actionTypes[_random.nextInt(actionTypes.length)];
    
    if (chosenType == ActionType.pass) {
      return AIAction(type: ActionType.pass, card: null, target: null);
    }
    
    // Randomly choose card
    final randomCard = availableCards[_random.nextInt(availableCards.length)];
    final target = _random.nextBool() ? 'player' : 'self';
    
    return AIAction(
      type: ActionType.playCard,
      card: randomCard,
      target: target,
    );
  }

  AIAction _generateAdaptiveAction(EnemyAIState aiState, BattleState battleState) {
    // Adaptive AI learns from battle and adjusts strategy
    final availableCards = battleState.enemyHand.where((card) => 
        card.cost <= battleState.enemyMana).toList();
    
    if (availableCards.isEmpty) {
      return AIAction(type: ActionType.pass, card: null, target: null);
    }
    
    // Analyze previous actions effectiveness
    final effectiveStrategies = _analyzeEffectiveStrategies(aiState);
    
    // Choose strategy based on effectiveness
    if (effectiveStrategies.contains('aggressive') && aiState.healthPercentage > 0.5) {
      return _generateAggressiveAction(aiState, battleState);
    } else if (effectiveStrategies.contains('defensive') || aiState.healthPercentage < 0.4) {
      return _generateDefensiveAction(aiState, battleState);
    } else {
      return _generateTacticalAction(aiState, battleState);
    }
  }

  /// Calculate threat level from player
  double _calculateThreatLevel(BattleState battleState) {
    double threat = 0;
    
    // Player health (lower health = higher threat)
    threat += (1 - battleState.playerHp / battleState.playerMaxHp) * 30;
    
    // Player mana (higher mana = higher threat)
    threat += (battleState.playerMana / battleState.playerMaxMana) * 20;
    
    // Cards in hand (more cards = higher threat)
    threat += battleState.playerHand.length * 5;
    
    // Active effects
    for (final effect in battleState.playerEffects.keys) {
      if (['damage_boost', 'critical_chance', 'spell_power'].contains(effect)) {
        threat += 10;
      }
    }
    
    return threat.clamp(0, 100);
  }

  /// Determine current battle phase
  BattlePhase _determineBattlePhase(BattleState battleState) {
    final turnNumber = battleState.turnNumber;
    
    if (turnNumber <= 3) {
      return BattlePhase.early;
    } else if (turnNumber <= 7) {
      return BattlePhase.mid;
    } else {
      return BattlePhase.late;
    }
  }

  /// Update AI learning from battle outcomes
  void _updateLearning(EnemyAIState aiState, BattleState battleState) {
    // Track action effectiveness
    if (aiState.lastAction != null) {
      final effectiveness = _calculateActionEffectiveness(aiState.lastAction!, battleState);
      aiState.actionHistory.add(ActionRecord(
        action: aiState.lastAction!,
        effectiveness: effectiveness,
        turnNumber: battleState.turnNumber,
      ));
    }
    
    // Update strategy preferences
    _updateStrategyPreferences(aiState);
  }

  /// Find enemy card combos
  List<CardCombo> _findEnemyCombos(List<GameCard> availableCards) {
    // Similar to player combo detection but for enemy cards
    final combos = <CardCombo>[];
    
    // Check for same-type combos
    final typeGroups = <String, List<GameCard>>{};
    for (final card in availableCards) {
      typeGroups.putIfAbsent(card.type, () => []).add(card);
    }
    
    for (final entry in typeGroups.entries) {
      if (entry.value.length >= 2) {
        combos.add(CardCombo(
          id: 'enemy_${entry.key}_combo',
          name: '${entry.key.toUpperCase()} Combo',
          description: 'Enemy ${entry.key} combo',
          cards: entry.value,
          type: ComboType.sameType,
          bonusDamage: entry.value.length * 5,
          bonusEffects: [],
        ));
      }
    }
    
    return combos;
  }

  /// Check for elemental advantages
  bool _hasElementalAdvantage(GameCard card, BattleState battleState) {
    if (card.element == null) return false;
    
    // Check against player's active effects
    for (final effect in battleState.playerEffects.keys) {
      if (effect.contains(card.element!)) {
        return true;
      }
    }
    
    return false;
  }

  /// Check for combo potential
  bool _hasComboPotential(GameCard card, List<GameCard> availableCards) {
    // Check if this card can combo with others
    for (final otherCard in availableCards) {
      if (card != otherCard && card.element == otherCard.element) {
        return true;
      }
    }
    
    return false;
  }

  /// Analyze effective strategies from action history
  List<String> _analyzeEffectiveStrategies(EnemyAIState aiState) {
    final strategies = <String>[];
    final recentActions = aiState.actionHistory
        .where((record) => record.turnNumber >= aiState.currentTurn - 3)
        .toList();
    
    if (recentActions.isEmpty) return strategies;
    
    // Calculate average effectiveness by strategy type
    final strategyEffectiveness = <String, double>{};
    
    for (final record in recentActions) {
      final strategy = _classifyActionStrategy(record.action);
      strategyEffectiveness[strategy] = (strategyEffectiveness[strategy] ?? 0) + record.effectiveness;
    }
    
    // Return strategies with above-average effectiveness
    final avgEffectiveness = strategyEffectiveness.values.reduce((a, b) => a + b) / strategyEffectiveness.length;
    
    for (final entry in strategyEffectiveness.entries) {
      if (entry.value > avgEffectiveness) {
        strategies.add(entry.key);
      }
    }
    
    return strategies;
  }

  /// Calculate action effectiveness
  double _calculateActionEffectiveness(AIAction action, BattleState battleState) {
    double effectiveness = 0;
    
    if (action.card != null) {
      // Base effectiveness from card stats
      effectiveness += action.card!.damage * 0.5;
      effectiveness += action.card!.defense * 0.3;
      
      // Bonus for successful targeting
      if (action.target == 'player' && battleState.playerHp < battleState.playerMaxHp) {
        effectiveness += 10;
      }
      
      if (action.target == 'self' && battleState.enemyHp < battleState.enemyMaxHp) {
        effectiveness += 10;
      }
    }
    
    return effectiveness;
  }

  /// Update strategy preferences based on effectiveness
  void _updateStrategyPreferences(EnemyAIState aiState) {
    final recentActions = aiState.actionHistory
        .where((record) => record.turnNumber >= aiState.currentTurn - 5)
        .toList();
    
    if (recentActions.isEmpty) return;
    
    // Calculate effectiveness by strategy
    final strategyScores = <String, double>{};
    
    for (final record in recentActions) {
      final strategy = _classifyActionStrategy(record.action);
      strategyScores[strategy] = (strategyScores[strategy] ?? 0) + record.effectiveness;
    }
    
    // Update preferences
    aiState.strategyPreferences.clear();
    final sortedStrategies = strategyScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedStrategies) {
      aiState.strategyPreferences[entry.key] = entry.value;
    }
  }

  /// Classify action by strategy
  String _classifyActionStrategy(AIAction action) {
    if (action.type == ActionType.pass) return 'defensive';
    
    if (action.card != null) {
      if (action.card!.keywords.contains('healing') || action.target == 'self') {
        return 'defensive';
      } else if (action.card!.damage > action.card!.defense) {
        return 'aggressive';
      } else {
        return 'tactical';
      }
    }
    
    return 'tactical';
  }
}

class EnemyAIState {
  AIPersonality personality;
  double healthPercentage = 1.0;
  double threatLevel = 0.0;
  int manaAvailable = 0;
  int cardsInHand = 0;
  BattlePhase battlePhase = BattlePhase.early;
  int currentTurn = 1;
  
  // Learning and adaptation
  final List<ActionRecord> actionHistory = [];
  final Map<String, double> strategyPreferences = {};
  AIAction? lastAction;
  
  // Personality-specific traits
  double aggressionLevel = 0.5;
  double cautionLevel = 0.5;
  double adaptabilityLevel = 0.5;

  EnemyAIState({
    required this.personality,
  });
}

enum AIPersonality {
  aggressive,
  defensive,
  tactical,
  random,
  adaptive,
}

enum BattlePhase {
  early,
  mid,
  late,
}

class AIAction {
  final ActionType type;
  final GameCard? card;
  final String? target;
  final CardCombo? combo;

  AIAction({
    required this.type,
    this.card,
    this.target,
    this.combo,
  });
}

enum ActionType {
  playCard,
  playCombo,
  pass,
  useAbility,
}

class ActionRecord {
  final AIAction action;
  final double effectiveness;
  final int turnNumber;

  ActionRecord({
    required this.action,
    required this.effectiveness,
    required this.turnNumber,
  });
}
