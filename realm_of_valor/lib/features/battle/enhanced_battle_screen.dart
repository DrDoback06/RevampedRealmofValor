import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import 'dart:async';
import '../../../data/models/character_model.dart';
import '../../../data/models/card_model.dart';
import '../../../services/event_bus.dart';
import '../../../core/di.dart';
import '../character/providers.dart';
import '../inventory/providers.dart';
import 'battle_models.dart';

class EnhancedBattleScreen extends ConsumerStatefulWidget {
  final String enemyId;
  final String enemyName;
  final int enemyLevel;
  final int enemyHp;
  final int enemyAtk;
  final int enemyDef;

  const EnhancedBattleScreen({
    super.key,
    required this.enemyId,
    required this.enemyName,
    required this.enemyLevel,
    required this.enemyHp,
    required this.enemyAtk,
    required this.enemyDef,
  });

  @override
  ConsumerState<EnhancedBattleScreen> createState() => _EnhancedBattleScreenState();
}

class _EnhancedBattleScreenState extends ConsumerState<EnhancedBattleScreen> {
  // Battle state
  bool _isPlayerTurn = true;
  bool _battleEnded = false;
  String? _winner;
  int _turnNumber = 1;
  Timer? _turnTimer;
  int _timeRemaining = 60; // 1 minute per turn
  
  // Battle phases
  BattlePhase _currentPhase = BattlePhase.draw;
  int _phaseTimeRemaining = 10; // 10 seconds per phase
  Timer? _phaseTimer;
  
  // Player state
  int _playerHp = 100;
  int _playerMana = 10;
  int _playerMaxMana = 10;
  List<GameCard> _playerHand = [];
  List<GameCard> _loadedCards = [];
  List<GameCard> _actionCards = [];
  
  // Deck management
  List<GameCard> _playerDeck = [];
  List<GameCard> _playerDiscardPile = [];
  List<GameCard> _enemyDeck = [];
  List<GameCard> _enemyDiscardPile = [];
  int _cardsDrawnThisTurn = 0;
  int _maxCardsPerTurn = 3;
  
  // Enemy state
  int _enemyHp = 100;
  int _enemyMana = 10;
  List<GameCard> _enemyHand = [];
  
  // Lasting effects
  Map<String, int> _playerEffects = {}; // effect_name: duration
  Map<String, int> _enemyEffects = {};
  
  // Battle log
  final List<String> _battleLog = [];
  final Random _random = Random();
  
  // Battle animations and effects
  bool _isAnimating = false;
  List<AnimationEffect> _activeAnimations = [];
  Map<String, AnimationController> _animationControllers = {};
  bool _showDamageNumbers = true;
  bool _showParticleEffects = true;
  
  // Battle settings
  bool _autoPlayEnabled = false;
  bool _fastModeEnabled = false;
  bool _showBattleTips = true;
  int _turnTimeLimit = 60;
  bool _allowUndo = true;
  
  // Tutorial and help
  bool _showTutorial = true;
  int _tutorialStep = 0;
  List<String> _tutorialSteps = [
    'Welcome to the battle system! This is a card-based combat game.',
    'You have two types of cards: Action cards (red) and Skill cards (blue).',
    'Action cards are free to play and provide basic attacks.',
    'Skill cards cost mana and have powerful effects.',
    'Use your cards strategically to defeat the enemy!',
    'Watch your health and mana bars at the top.',
    'The enemy will play cards during their turn.',
    'Good luck, warrior!',
  ];
  
  // Battle statistics
  BattleStatistics _battleStats = BattleStatistics(
    turnsPlayed: 0,
    cardsPlayed: 0,
    damageDealt: 0,
    damageTaken: 0,
    healingDone: 0,
    manaSpent: 0,
    specialEffectsUsed: [],
    battleStartTime: DateTime.now(),
  );
  
  // Battle replay
  List<BattleAction> _battleActions = [];
  bool _isReplayMode = false;
  int _replayIndex = 0;
  Timer? _replayTimer;

  @override
  void initState() {
    super.initState();
    _initializeBattle();
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    super.dispose();
  }

  void _initializeBattle() {
    _logDebug('Initializing enhanced battle');
    
    // Set player HP based on character stats
    final character = ref.read(characterWithEquipmentProvider).value;
    if (character != null) {
      _playerHp = character.stats.vitality * 10;
      _playerMaxMana = character.stats.intelligence * 2;
      _playerMana = _playerMaxMana;
    }
    
    // Set enemy HP
    _enemyHp = widget.enemyHp;
    _enemyMana = widget.enemyLevel * 2;
    
    // Deal initial hands
    _dealInitialHands();
    
    _addToLog('Battle started! ${character?.name ?? 'Hero'} vs ${widget.enemyName}');
    _addToLog('Turn $_turnNumber - Your turn!');
    
    _startTurnTimer();
  }

  void _dealInitialHands() {
    _logDebug('Dealing initial hands');

    // Initialize decks
    _initializeDecks();

    // Deal 5 action cards to each player
    _actionCards = _generateActionCards(5);
    _enemyHand = _generateActionCards(5);

    // Deal 5 skill/inventory cards to player
    _playerHand = _drawCardsFromDeck(5);

    _addToLog('Dealt 5 action cards and 5 skill cards');
  }
  
  void _initializeDecks() {
    // Create player deck from inventory
    final inventory = ref.read(inventoryStreamProvider).value;
    if (inventory != null) {
      final cardDatabase = ref.read(cardDatabaseProvider).value ?? [];
      
      for (final cardInstance in inventory.items) {
        final card = cardDatabase.firstWhere(
          (card) => card.id == cardInstance.cardId,
          orElse: () => GameCard(
            id: 'default',
            name: 'Default Card',
            description: 'A default card',
            type: CardType.spell,
            rarity: CardRarity.common,
            element: CardElement.none,
            manaCost: 1,
            stats: {'damage': 10},
          ),
        );
        
        // Add multiple copies based on inventory count
        for (int i = 0; i < cardInstance.quantity; i++) {
          _playerDeck.add(card);
        }
      }
    }
    
    // Shuffle player deck
    _playerDeck.shuffle(_random);
    
    // Create enemy deck based on enemy type
    _enemyDeck = _generateEnemyDeck();
    _enemyDeck.shuffle(_random);
    
    _addToLog('Decks initialized - Player: ${_playerDeck.length}, Enemy: ${_enemyDeck.length}');
  }
  
  List<GameCard> _generateEnemyDeck() {
    final enemyType = widget.enemyName.toLowerCase();
    final deck = <GameCard>[];
    
    if (enemyType.contains('goblin')) {
      deck.addAll(_generateGoblinDeck());
    } else if (enemyType.contains('dragon')) {
      deck.addAll(_generateDragonDeck());
    } else if (enemyType.contains('wizard')) {
      deck.addAll(_generateWizardDeck());
    } else {
      deck.addAll(_generateGenericDeck());
    }
    
    return deck;
  }
  
  List<GameCard> _generateGoblinDeck() {
    return [
      GameCard(
        id: 'goblin_attack',
        name: 'Goblin Strike',
        description: 'A quick attack',
        type: CardType.spell,
        rarity: CardRarity.common,
        element: CardElement.none,
        manaCost: 1,
        stats: {'damage': 8},
      ),
      GameCard(
        id: 'goblin_poison',
        name: 'Poison Dart',
        description: 'Poisonous attack',
        type: CardType.spell,
        rarity: CardRarity.uncommon,
        element: CardElement.nature,
        manaCost: 2,
        stats: {'damage': 5, 'effect': 'poison', 'duration': 3},
      ),
    ];
  }
  
  List<GameCard> _generateDragonDeck() {
    return [
      GameCard(
        id: 'dragon_breath',
        name: 'Dragon Breath',
        description: 'Fiery breath attack',
        type: CardType.spell,
        rarity: CardRarity.rare,
        element: CardElement.fire,
        manaCost: 3,
        stats: {'damage': 15},
      ),
      GameCard(
        id: 'dragon_wing',
        name: 'Wing Buffet',
        description: 'Powerful wing attack',
        type: CardType.spell,
        rarity: CardRarity.uncommon,
        element: CardElement.none,
        manaCost: 2,
        stats: {'damage': 12, 'effect': 'stun', 'duration': 1},
      ),
    ];
  }
  
  List<GameCard> _generateWizardDeck() {
    return [
      GameCard(
        id: 'wizard_fireball',
        name: 'Fireball',
        description: 'Explosive fire magic',
        type: CardType.spell,
        rarity: CardRarity.rare,
        element: CardElement.fire,
        manaCost: 3,
        stats: {'damage': 18},
      ),
      GameCard(
        id: 'wizard_heal',
        name: 'Healing Light',
        description: 'Restore health',
        type: CardType.spell,
        rarity: CardRarity.uncommon,
        element: CardElement.light,
        manaCost: 2,
        stats: {'healing': 10},
      ),
    ];
  }
  
  List<GameCard> _generateGenericDeck() {
    return [
      GameCard(
        id: 'basic_attack',
        name: 'Basic Attack',
        description: 'A basic attack',
        type: CardType.spell,
        rarity: CardRarity.common,
        element: CardElement.none,
        manaCost: 1,
        stats: {'damage': 10},
      ),
    ];
  }
  
  List<GameCard> _drawCardsFromDeck(int count) {
    final drawnCards = <GameCard>[];
    
    for (int i = 0; i < count; i++) {
      if (_playerDeck.isNotEmpty) {
        drawnCards.add(_playerDeck.removeLast());
      } else if (_playerDiscardPile.isNotEmpty) {
        // Reshuffle discard pile into deck
        _playerDeck.addAll(_playerDiscardPile);
        _playerDiscardPile.clear();
        _playerDeck.shuffle(_random);
        
        if (_playerDeck.isNotEmpty) {
          drawnCards.add(_playerDeck.removeLast());
        }
      }
    }
    
    return drawnCards;
  }
  
  void _discardCard(GameCard card) {
    _playerDiscardPile.add(card);
    _addToLog('Card discarded: ${card.name}');
  }

  List<GameCard> _generateActionCards(int count) {
    final actionCardTemplates = [
      GameCard(
        id: 'miss_turn',
        name: 'Miss a Turn',
        description: 'Skip your next turn',
        type: CardType.spell,
        rarity: CardRarity.common,
        element: CardElement.none,
        manaCost: 0,
        stats: {'effect': 'miss_turn'},
      ),
      GameCard(
        id: 'double_attack',
        name: 'Double Attack',
        description: 'Deal double damage this turn',
        type: CardType.spell,
        rarity: CardRarity.uncommon,
        element: CardElement.none,
        manaCost: 2,
        stats: {'effect': 'double_attack'},
      ),
      GameCard(
        id: 'swap_cards',
        name: 'Swap Cards',
        description: 'Swap your hand with opponent',
        type: CardType.spell,
        rarity: CardRarity.rare,
        element: CardElement.none,
        manaCost: 3,
        stats: {'effect': 'swap_cards'},
      ),
      GameCard(
        id: 'stop_action',
        name: 'Stop Action',
        description: 'Cancel opponent\'s last action',
        type: CardType.spell,
        rarity: CardRarity.epic,
        element: CardElement.none,
        manaCost: 4,
        stats: {'effect': 'stop_action'},
      ),
      GameCard(
        id: 'mana_boost',
        name: 'Mana Boost',
        description: 'Gain 5 mana',
        type: CardType.spell,
        rarity: CardRarity.common,
        element: CardElement.none,
        manaCost: 0,
        stats: {'effect': 'mana_boost', 'amount': 5},
      ),
    ];

    final cards = <GameCard>[];
    for (var i = 0; i < count; i++) {
      cards.add(actionCardTemplates[_random.nextInt(actionCardTemplates.length)]);
    }
    return cards;
  }

  List<GameCard> _generateSkillCards(int count) {
    // Get cards from inventory
    final inventory = ref.read(inventoryStreamProvider).value;
    if (inventory == null) return [];

    final cardDatabase = ref.read(cardDatabaseProvider).value ?? [];
    final availableCards = <GameCard>[];

    for (final cardInstance in inventory.items) {
      final card = cardDatabase.firstWhere(
        (card) => card.id == cardInstance.cardId,
        orElse: () => GameCard(
          id: 'default',
          name: 'Default Card',
          description: 'A default card',
          type: CardType.spell,
          rarity: CardRarity.common,
          element: CardElement.none,
          manaCost: 1,
          stats: {'damage': 10},
        ),
      );
      availableCards.add(card);
    }

    // If not enough cards, add some basic ones
    while (availableCards.length < count) {
      availableCards.add(GameCard(
        id: 'basic_attack_${availableCards.length}',
        name: 'Basic Attack',
        description: 'A basic attack',
        type: CardType.spell,
        rarity: CardRarity.common,
        element: CardElement.none,
        manaCost: 1,
        stats: {'damage': 15},
      ));
    }

    // Shuffle and take count
    availableCards.shuffle(_random);
    return availableCards.take(count).toList();
  }

  void _startTurnTimer() {
    _timeRemaining = 60;
    _turnTimer?.cancel();
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
        if (_timeRemaining <= 0) {
          _endTurn();
        }
      });
    });
  }

  void _endTurn() {
    _turnTimer?.cancel();
    _phaseTimer?.cancel();

    if (_isPlayerTurn) {
      _isPlayerTurn = false;
      _addToLog('Enemy\'s turn...');

      // Enemy AI turn
      Future.delayed(const Duration(seconds: 2), () {
        _enemyTurn();
      });
    } else {
      _isPlayerTurn = true;
      _turnNumber++;
      _addToLog('Turn $_turnNumber - Your turn!');

      // Start new turn with phases
      _startNewTurn();
    }
  }
  
  void _startNewTurn() {
    _currentPhase = BattlePhase.draw;
    _phaseTimeRemaining = 10;
    _cardsDrawnThisTurn = 0;
    
    // Apply lasting effects
    _applyLastingEffects();
    
    // Start phase timer
    _startPhaseTimer();
    
    _addToLog('Draw phase - Draw up to $_maxCardsPerTurn cards');
  }
  
  void _startPhaseTimer() {
    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_battleEnded) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _phaseTimeRemaining--;
      });
      
      if (_phaseTimeRemaining <= 0) {
        _advancePhase();
      }
    });
  }
  
  void _advancePhase() {
    switch (_currentPhase) {
      case BattlePhase.draw:
        _currentPhase = BattlePhase.action;
        _phaseTimeRemaining = 30;
        _addToLog('Action phase - Play your cards!');
        break;
      case BattlePhase.action:
        _currentPhase = BattlePhase.end;
        _phaseTimeRemaining = 5;
        _addToLog('End phase - Turn ending...');
        break;
      case BattlePhase.end:
        _endTurn();
        return;
    }
    
    setState(() {});
  }
  
  void _drawCard() {
    if (_cardsDrawnThisTurn < _maxCardsPerTurn && _playerDeck.isNotEmpty) {
      final newCard = _drawCardsFromDeck(1).firstOrNull;
      if (newCard != null) {
        setState(() {
          _playerHand.add(newCard);
          _cardsDrawnThisTurn++;
        });
        _addToLog('Drew: ${newCard.name}');
      }
    }
  }

  void _drawCard() {
    if (_isPlayerTurn) {
      final newCard = _generateSkillCards(1).firstOrNull;
      if (newCard != null) {
        setState(() {
          _playerHand.add(newCard);
        });
        _addToLog('Drew a card: ${newCard.name}');
      }
    }
  }

  void _applyLastingEffects() {
    // Apply player effects
    final playerEffectsToRemove = <String>[];
    for (final entry in _playerEffects.entries) {
      _playerEffects[entry.key] = entry.value - 1;
      if (_playerEffects[entry.key]! <= 0) {
        playerEffectsToRemove.add(entry.key);
      }
    }
    for (final effect in playerEffectsToRemove) {
      _playerEffects.remove(effect);
      _addToLog('Effect $effect expired');
    }

    // Apply enemy effects
    final enemyEffectsToRemove = <String>[];
    for (final entry in _enemyEffects.entries) {
      _enemyEffects[entry.key] = entry.value - 1;
      if (_enemyEffects[entry.key]! <= 0) {
        enemyEffectsToRemove.add(entry.key);
      }
    }
    for (final effect in enemyEffectsToRemove) {
      _enemyEffects.remove(effect);
    }
  }

  void _enemyTurn() {
    if (_battleEnded) return;

    _addToLog('Enemy is thinking...');

    // Advanced AI decision making
    final decision = _makeEnemyDecision();
    
    if (decision.card != null) {
      switch (decision.type) {
        case EnemyActionType.attack:
          _executeEnemyAttack(decision.card!);
          break;
        case EnemyActionType.defend:
          _executeEnemyDefense(decision.card!);
          break;
        case EnemyActionType.heal:
          _executeEnemyHeal(decision.card!);
          break;
        case EnemyActionType.special:
          _executeEnemySpecial(decision.card!);
          break;
      }
    } else {
      _addToLog('Enemy has no suitable cards to play');
    }

    // End enemy turn after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!_battleEnded) {
        _endTurn();
      }
    });
  }
  
  EnemyDecision _makeEnemyDecision() {
    final enemyType = widget.enemyName.toLowerCase();
    final currentHp = _enemyHp;
    final maxHp = widget.enemyHp;
    final availableCards = List<GameCard>.from(_enemyHand);
    
    // Calculate threat level
    final threatLevel = _calculateThreatLevel();
    final healthPercentage = currentHp / maxHp;
    
    // Different AI strategies based on enemy type
    if (enemyType.contains('goblin')) {
      return _goblinAI(availableCards, threatLevel, healthPercentage);
    } else if (enemyType.contains('dragon')) {
      return _dragonAI(availableCards, threatLevel, healthPercentage);
    } else if (enemyType.contains('wizard')) {
      return _wizardAI(availableCards, threatLevel, healthPercentage);
    } else {
      return _genericAI(availableCards, threatLevel, healthPercentage);
    }
  }
  
  double _calculateThreatLevel() {
    final playerDamage = _playerHand.fold<int>(0, (sum, card) {
      final damage = card.stats?['damage'] as int? ?? 0;
      return sum + damage;
    });
    
    final playerHealing = _playerHand.fold<int>(0, (sum, card) {
      final healing = card.stats?['healing'] as int? ?? 0;
      return sum + healing;
    });
    
    return (playerDamage - playerHealing) / 100.0;
  }
  
  EnemyDecision _goblinAI(List<GameCard> cards, double threatLevel, double healthPercentage) {
    // Goblins are aggressive and unpredictable
    if (healthPercentage < 0.3 && _hasHealingCard(cards)) {
      return EnemyDecision(
        type: EnemyActionType.heal,
        card: _findBestHealingCard(cards),
        priority: 1,
      );
    }
    
    // High threat level - go aggressive
    if (threatLevel > 0.5) {
      return EnemyDecision(
        type: EnemyActionType.attack,
        card: _findHighestDamageCard(cards),
        priority: 2,
      );
    }
    
    // Random aggressive behavior
    if (_random.nextDouble() < 0.7) {
      return EnemyDecision(
        type: EnemyActionType.attack,
        card: _findRandomAttackCard(cards),
        priority: 3,
      );
    }
    
    return EnemyDecision(
      type: EnemyActionType.defend,
      card: _findDefenseCard(cards),
      priority: 4,
    );
  }
  
  EnemyDecision _dragonAI(List<GameCard> cards, double threatLevel, double healthPercentage) {
    // Dragons are powerful but strategic
    if (healthPercentage < 0.5 && _hasHealingCard(cards)) {
      return EnemyDecision(
        type: EnemyActionType.heal,
        card: _findBestHealingCard(cards),
        priority: 1,
      );
    }
    
    // Use special abilities when available
    final specialCard = _findSpecialCard(cards);
    if (specialCard != null && _random.nextDouble() < 0.6) {
      return EnemyDecision(
        type: EnemyActionType.special,
        card: specialCard,
        priority: 2,
      );
    }
    
    // Powerful attacks
    return EnemyDecision(
      type: EnemyActionType.attack,
      card: _findHighestDamageCard(cards),
      priority: 3,
    );
  }
  
  EnemyDecision _wizardAI(List<GameCard> cards, double threatLevel, double healthPercentage) {
    // Wizards are tactical and use magic
    if (healthPercentage < 0.4 && _hasHealingCard(cards)) {
      return EnemyDecision(
        type: EnemyActionType.heal,
        card: _findBestHealingCard(cards),
        priority: 1,
      );
    }
    
    // Use elemental magic strategically
    final elementalCard = _findElementalCard(cards);
    if (elementalCard != null && _random.nextDouble() < 0.8) {
      return EnemyDecision(
        type: EnemyActionType.special,
        card: elementalCard,
        priority: 2,
      );
    }
    
    // Balanced approach
    if (_random.nextDouble() < 0.5) {
      return EnemyDecision(
        type: EnemyActionType.attack,
        card: _findHighestDamageCard(cards),
        priority: 3,
      );
    } else {
      return EnemyDecision(
        type: EnemyActionType.defend,
        card: _findDefenseCard(cards),
        priority: 4,
      );
    }
  }
  
  EnemyDecision _genericAI(List<GameCard> cards, double threatLevel, double healthPercentage) {
    // Generic balanced AI
    if (healthPercentage < 0.3 && _hasHealingCard(cards)) {
      return EnemyDecision(
        type: EnemyActionType.heal,
        card: _findBestHealingCard(cards),
        priority: 1,
      );
    }
    
    if (threatLevel > 0.4) {
      return EnemyDecision(
        type: EnemyActionType.attack,
        card: _findHighestDamageCard(cards),
        priority: 2,
      );
    }
    
    return EnemyDecision(
      type: EnemyActionType.attack,
      card: _findRandomAttackCard(cards),
      priority: 3,
    );
  }
  
  void _executeEnemyAttack(GameCard card) {
    _enemyHand.remove(card);
    _addToLog('Enemy attacks with: ${card.name}');
    _playCard(card, isEnemy: true);
  }
  
  void _executeEnemyDefense(GameCard card) {
    _enemyHand.remove(card);
    _addToLog('Enemy defends with: ${card.name}');
    _enemyEffects['defense'] = 1;
  }
  
  void _executeEnemyHeal(GameCard card) {
    _enemyHand.remove(card);
    _addToLog('Enemy heals with: ${card.name}');
    _playCard(card, isEnemy: true);
  }
  
  void _executeEnemySpecial(GameCard card) {
    _enemyHand.remove(card);
    _addToLog('Enemy uses special ability: ${card.name}');
    _playCard(card, isEnemy: true);
  }
  
  // Helper methods for AI decision making
  bool _hasHealingCard(List<GameCard> cards) {
    return cards.any((card) => (card.stats?['healing'] as int? ?? 0) > 0);
  }
  
  GameCard? _findBestHealingCard(List<GameCard> cards) {
    final healingCards = cards.where((card) => (card.stats?['healing'] as int? ?? 0) > 0).toList();
    if (healingCards.isEmpty) return null;
    
    healingCards.sort((a, b) => (card.stats?['healing'] as int? ?? 0).compareTo(b.stats?['healing'] as int? ?? 0));
    return healingCards.first;
  }
  
  GameCard? _findHighestDamageCard(List<GameCard> cards) {
    final attackCards = cards.where((card) => (card.stats?['damage'] as int? ?? 0) > 0).toList();
    if (attackCards.isEmpty) return null;
    
    attackCards.sort((a, b) => (b.stats?['damage'] as int? ?? 0).compareTo(a.stats?['damage'] as int? ?? 0));
    return attackCards.first;
  }
  
  GameCard? _findRandomAttackCard(List<GameCard> cards) {
    final attackCards = cards.where((card) => (card.stats?['damage'] as int? ?? 0) > 0).toList();
    if (attackCards.isEmpty) return null;
    
    return attackCards[_random.nextInt(attackCards.length)];
  }
  
  GameCard? _findDefenseCard(List<GameCard> cards) {
    final defenseCards = cards.where((card) => card.stats?['effect'] == 'defense').toList();
    if (defenseCards.isEmpty) return null;
    
    return defenseCards[_random.nextInt(defenseCards.length)];
  }
  
  GameCard? _findSpecialCard(List<GameCard> cards) {
    final specialCards = cards.where((card) => 
      card.stats?['effect'] != null && 
      card.stats?['effect'] != 'defense' &&
      card.stats?['effect'] != 'heal'
    ).toList();
    
    if (specialCards.isEmpty) return null;
    return specialCards[_random.nextInt(specialCards.length)];
  }
  
  GameCard? _findElementalCard(List<GameCard> cards) {
    final elementalCards = cards.where((card) => card.element != CardElement.none).toList();
    if (elementalCards.isEmpty) return null;
    
    return elementalCards[_random.nextInt(elementalCards.length)];
  }

  void _playCard(GameCard card, {bool isEnemy = false}) {
    _addToLog('${isEnemy ? 'Enemy' : 'You'} played: ${card.name}');

    // Record battle action
    _recordBattleAction(
      turnNumber: _turnNumber,
      isPlayerAction: !isEnemy,
      actionType: 'play_card',
      description: '${isEnemy ? 'Enemy' : 'Player'} played ${card.name}',
      data: {
        'card_id': card.id,
        'card_name': card.name,
        'mana_cost': card.manaCost,
        'damage': card.stats?['damage'] ?? 0,
        'healing': card.stats?['healing'] ?? 0,
      },
    );

    // Apply card effects
    _applyCardEffect(card, isEnemy: isEnemy);

    // Check for battle end
    _checkBattleEnd();
  }
  
  void _recordBattleAction({
    required int turnNumber,
    required bool isPlayerAction,
    required String actionType,
    required String description,
    required Map<String, dynamic> data,
  }) {
    _battleActions.add(BattleAction(
      turnNumber: turnNumber,
      isPlayerAction: isPlayerAction,
      actionType: actionType,
      description: description,
      data: data,
      timestamp: DateTime.now(),
    ));
  }
  
  void _showBattleReplay() {
    if (_battleActions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No battle actions to replay')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Battle Replay'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _battleActions.length,
                  itemBuilder: (context, index) {
                    final action = _battleActions[index];
                    return ListTile(
                      leading: Icon(
                        action.isPlayerAction ? Icons.person : Icons.computer,
                        color: action.isPlayerAction ? Colors.blue : Colors.red,
                      ),
                      title: Text('Turn ${action.turnNumber}'),
                      subtitle: Text(action.description),
                      trailing: Text(
                        '${action.timestamp.hour}:${action.timestamp.minute}:${action.timestamp.second}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _startReplay,
                    child: const Text('Start Replay'),
                  ),
                  ElevatedButton(
                    onPressed: _exportBattleData,
                    child: const Text('Export Data'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _startReplay() {
    if (_battleActions.isEmpty) return;
    
    setState(() {
      _isReplayMode = true;
      _replayIndex = 0;
    });
    
    Navigator.of(context).pop(); // Close dialog
    
    _replayTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_replayIndex >= _battleActions.length) {
        timer.cancel();
        setState(() {
          _isReplayMode = false;
        });
        _addToLog('Replay completed!');
        return;
      }
      
      final action = _battleActions[_replayIndex];
      _addToLog('[REPLAY] ${action.description}');
      _replayIndex++;
    });
  }
  
  void _exportBattleData() {
    final battleData = {
      'enemy': {
        'id': widget.enemyId,
        'name': widget.enemyName,
        'level': widget.enemyLevel,
        'hp': widget.enemyHp,
        'atk': widget.enemyAtk,
        'def': widget.enemyDef,
      },
      'battle_stats': {
        'turns_played': _battleStats.turnsPlayed,
        'cards_played': _battleStats.cardsPlayed,
        'damage_dealt': _battleStats.damageDealt,
        'damage_taken': _battleStats.damageTaken,
        'healing_done': _battleStats.healingDone,
        'mana_spent': _battleStats.manaSpent,
        'efficiency': _battleStats.efficiency,
        'duration': _battleStats.battleDuration.inSeconds,
      },
      'actions': _battleActions.map((action) => {
        'turn': action.turnNumber,
        'player_action': action.isPlayerAction,
        'type': action.actionType,
        'description': action.description,
        'data': action.data,
        'timestamp': action.timestamp.toIso8601String(),
      }).toList(),
    };
    
    // TODO: Implement actual export functionality
    _addToLog('Battle data exported (${battleData.toString().length} characters)');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Battle data exported successfully')),
    );
  }

  void _applyCardEffect(GameCard card, {bool isEnemy = false}) {
    final target = isEnemy ? 'enemy' : 'player';
    final effect = card.stats?['effect'] as String?;
    final damage = card.stats?['damage'] as int? ?? 0;
    final healing = card.stats?['healing'] as int? ?? 0;
    final manaCost = card.manaCost;
    final element = card.element;

    // Apply elemental bonuses
    final elementalBonus = _calculateElementalBonus(element, isEnemy);
    final finalDamage = (damage * elementalBonus).round();
    final finalHealing = (healing * elementalBonus).round();

    // Apply damage with animations and track statistics
    if (finalDamage > 0) {
      if (isEnemy) {
        _playerHp = max(0, _playerHp - finalDamage);
        _addToLog('You took $finalDamage damage!');
        _showDamageAnimation(finalDamage, isPlayer: true, isDamage: true);
        _updateBattleStats(damageTaken: finalDamage);
      } else {
        _enemyHp = max(0, _enemyHp - finalDamage);
        _addToLog('Enemy took $finalDamage damage!');
        _showDamageAnimation(finalDamage, isPlayer: false, isDamage: true);
        _updateBattleStats(damageDealt: finalDamage);
      }
    }

    // Apply healing with animations and track statistics
    if (finalHealing > 0) {
      if (isEnemy) {
        _enemyHp = min(widget.enemyHp, _enemyHp + finalHealing);
        _addToLog('Enemy healed $finalHealing HP!');
        _showDamageAnimation(finalHealing, isPlayer: false, isDamage: false);
      } else {
        _playerHp = min(100, _playerHp + finalHealing);
        _addToLog('You healed $finalHealing HP!');
        _showDamageAnimation(finalHealing, isPlayer: true, isDamage: false);
        _updateBattleStats(healingDone: finalHealing);
      }
    }

    // Apply advanced special effects
    _applyAdvancedEffects(card, isEnemy);

    // Consume mana and track statistics
    if (!isEnemy && manaCost > 0) {
      _playerMana = max(0, _playerMana - manaCost);
      _updateBattleStats(manaSpent: manaCost);
    }
    
    // Track card played
    _updateBattleStats(cardsPlayed: 1);
  }
  
  void _updateBattleStats({
    int? damageDealt,
    int? damageTaken,
    int? healingDone,
    int? manaSpent,
    int? cardsPlayed,
    int? turnsPlayed,
    String? specialEffect,
  }) {
    setState(() {
      _battleStats = _battleStats.copyWith(
        damageDealt: _battleStats.damageDealt + (damageDealt ?? 0),
        damageTaken: _battleStats.damageTaken + (damageTaken ?? 0),
        healingDone: _battleStats.healingDone + (healingDone ?? 0),
        manaSpent: _battleStats.manaSpent + (manaSpent ?? 0),
        cardsPlayed: _battleStats.cardsPlayed + (cardsPlayed ?? 0),
        turnsPlayed: _battleStats.turnsPlayed + (turnsPlayed ?? 0),
        specialEffectsUsed: specialEffect != null 
            ? [..._battleStats.specialEffectsUsed, specialEffect]
            : _battleStats.specialEffectsUsed,
      );
    });
  }
  
  double _calculateElementalBonus(CardElement element, bool isEnemy) {
    // Get enemy element from quest tags or default
    final enemyElement = CardElement.none; // TODO: Extract from enemy data
    
    // Elemental effectiveness chart
    final effectiveness = {
      CardElement.fire: {CardElement.ice: 1.5, CardElement.nature: 0.7},
      CardElement.ice: {CardElement.nature: 1.5, CardElement.fire: 0.7},
      CardElement.nature: {CardElement.fire: 1.5, CardElement.ice: 0.7},
      CardElement.light: {CardElement.dark: 1.5, CardElement.light: 0.5},
      CardElement.dark: {CardElement.light: 1.5, CardElement.dark: 0.5},
    };
    
    if (effectiveness.containsKey(element) && 
        effectiveness[element]!.containsKey(enemyElement)) {
      return effectiveness[element]![enemyElement]!;
    }
    
    return 1.0;
  }
  
  void _applyAdvancedEffects(GameCard card, bool isEnemy) {
    final effect = card.stats?['effect'] as String?;
    
    switch (effect) {
      case 'double_attack':
        if (!isEnemy) {
          _playerEffects['double_attack'] = 1;
          _addToLog('Double attack active for 1 turn!');
          _showEffectAnimation('Double Attack!', Colors.orange);
        }
        break;
      case 'mana_boost':
        if (!isEnemy) {
          final boost = card.stats?['amount'] as int? ?? 5;
          _playerMana = min(_playerMaxMana, _playerMana + boost);
          _addToLog('Gained $boost mana!');
          _showEffectAnimation('+$boost Mana', Colors.blue);
        }
        break;
      case 'swap_cards':
        if (!isEnemy) {
          final tempHand = List<GameCard>.from(_playerHand);
          _playerHand = List<GameCard>.from(_enemyHand);
          _enemyHand = tempHand;
          _addToLog('Cards swapped!');
          _showEffectAnimation('Cards Swapped!', Colors.purple);
        }
        break;
      case 'miss_turn':
        if (!isEnemy) {
          _addToLog('Enemy will miss their next turn!');
          _enemyEffects['miss_turn'] = 1;
          _showEffectAnimation('Enemy Stunned!', Colors.red);
        }
        break;
      case 'stop_action':
        if (!isEnemy) {
          _addToLog('Enemy action cancelled!');
          _showEffectAnimation('Action Blocked!', Colors.grey);
        }
        break;
      case 'chain_lightning':
        if (!isEnemy) {
          final chainDamage = card.stats?['chain_damage'] as int? ?? 10;
          _enemyHp = max(0, _enemyHp - chainDamage);
          _addToLog('Chain lightning deals $chainDamage damage!');
          _showEffectAnimation('Chain Lightning!', Colors.yellow);
        }
        break;
      case 'heal_over_time':
        if (!isEnemy) {
          final healAmount = card.stats?['heal_amount'] as int? ?? 5;
          final duration = card.stats?['duration'] as int? ?? 3;
          _playerEffects['heal_over_time'] = duration;
          _addToLog('Healing over time for $duration turns!');
          _showEffectAnimation('Healing Over Time', Colors.green);
        }
        break;
    }
  }
  
  void _showDamageAnimation(int amount, {required bool isPlayer, required bool isDamage}) {
    if (!_showDamageNumbers) return;
    
    final color = isDamage ? Colors.red : Colors.green;
    final prefix = isDamage ? '-' : '+';
    
    _activeAnimations.add(
      AnimationEffect(
        type: AnimationType.damageNumber,
        data: {
          'amount': amount,
          'color': color,
          'prefix': prefix,
          'isPlayer': isPlayer,
        },
      ),
    );
    
    setState(() {});
  }
  
  void _showEffectAnimation(String text, Color color) {
    if (!_showParticleEffects) return;
    
    _activeAnimations.add(
      AnimationEffect(
        type: AnimationType.effectText,
        data: {
          'text': text,
          'color': color,
        },
      ),
    );
    
    setState(() {});
  }

  void _checkBattleEnd() {
    if (_playerHp <= 0) {
      _battleEnded = true;
      _winner = 'enemy';
      _addToLog('You were defeated!');
      _showBattleResult();
    } else if (_enemyHp <= 0) {
      _battleEnded = true;
      _winner = 'player';
      _addToLog('Victory! You defeated ${widget.enemyName}!');
      _showBattleResult();
    }
  }

  void _showBattleResult() {
    final isVictory = _winner == 'player';
    final rewards = _calculateBattleRewards();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isVictory ? 'Victory!' : 'Defeat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isVictory ? 'You have defeated ${widget.enemyName}!' : 'You have been defeated by ${widget.enemyName}'),
            const SizedBox(height: 16),
            if (isVictory) ...[
              _buildRewardRow('Experience', '${rewards.experience} XP', Icons.star),
              _buildRewardRow('Gold', '${rewards.gold} Gold', Icons.monetization_on),
              if (rewards.cards.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Cards Earned:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...rewards.cards.map((card) => _buildRewardRow(card.name, card.rarity.name, Icons.style)),
              ],
            ],
            const SizedBox(height: 16),
            _buildBattleStatsSummary(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    
    // Apply rewards if victory
    if (isVictory) {
      _applyBattleRewards(rewards);
    }
  }
  
  BattleRewards _calculateBattleRewards() {
    final baseExperience = widget.enemyLevel * 10;
    final baseGold = widget.enemyLevel * 5;
    
    // Bonus based on battle performance
    final efficiencyBonus = _battleStats.efficiency / 10;
    final healthBonus = _playerHp / 100.0;
    final turnBonus = max(0, 10 - _battleStats.turnsPlayed) * 2;
    
    final totalExperience = (baseExperience * (1 + efficiencyBonus + healthBonus + turnBonus)).round();
    final totalGold = (baseGold * (1 + efficiencyBonus + healthBonus)).round();
    
    // Random card rewards
    final earnedCards = <GameCard>[];
    if (_random.nextDouble() < 0.3) { // 30% chance for card
      earnedCards.add(_generateRandomRewardCard());
    }
    
    return BattleRewards(
      experience: totalExperience,
      gold: totalGold,
      cards: earnedCards,
    );
  }
  
  GameCard _generateRandomRewardCard() {
    final cardTemplates = [
      GameCard(
        id: 'reward_fireball',
        name: 'Fireball',
        description: 'A powerful fire spell',
        type: CardType.spell,
        rarity: CardRarity.rare,
        element: CardElement.fire,
        manaCost: 3,
        stats: {'damage': 20},
      ),
      GameCard(
        id: 'reward_heal',
        name: 'Greater Heal',
        description: 'Restore significant health',
        type: CardType.spell,
        rarity: CardRarity.uncommon,
        element: CardElement.light,
        manaCost: 2,
        stats: {'healing': 15},
      ),
      GameCard(
        id: 'reward_lightning',
        name: 'Chain Lightning',
        description: 'Lightning that chains to multiple targets',
        type: CardType.spell,
        rarity: CardRarity.rare,
        element: CardElement.light,
        manaCost: 4,
        stats: {'damage': 15, 'effect': 'chain_lightning', 'chain_damage': 8},
      ),
    ];
    
    return cardTemplates[_random.nextInt(cardTemplates.length)];
  }
  
  void _applyBattleRewards(BattleRewards rewards) {
    // Apply experience to character
    final character = ref.read(characterWithEquipmentProvider).value;
    if (character != null) {
      // TODO: Update character experience
      _addToLog('Gained ${rewards.experience} experience!');
    }
    
    // Apply gold to inventory
    final inventory = ref.read(inventoryStreamProvider).value;
    if (inventory != null) {
      // TODO: Update inventory gold
      _addToLog('Gained ${rewards.gold} gold!');
    }
    
    // Add cards to inventory
    for (final card in rewards.cards) {
      // TODO: Add card to inventory
      _addToLog('Earned card: ${card.name}');
    }
  }
  
  Widget _buildRewardRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text('$label: $value'),
        ],
      ),
    );
  }
  
  Widget _buildBattleStatsSummary() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Battle Statistics:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Duration: ${_battleStats.battleDuration.inSeconds}s'),
          Text('Turns: ${_battleStats.turnsPlayed}'),
          Text('Cards Played: ${_battleStats.cardsPlayed}'),
          Text('Damage Dealt: ${_battleStats.damageDealt}'),
          Text('Damage Taken: ${_battleStats.damageTaken}'),
          Text('Healing Done: ${_battleStats.healingDone}'),
          Text('Mana Spent: ${_battleStats.manaSpent}'),
          Text('Efficiency: ${_battleStats.efficiency.toStringAsFixed(1)}'),
        ],
      ),
    );
  }

  void _useActionCard(GameCard card, bool isActionCard) {
    if (!_isPlayerTurn || _battleEnded) return;

    setState(() {
      if (isActionCard) {
        _actionCards.remove(card);
      }
    });

    _playCard(card);
    _endTurn();
  }

  void _loadCard(GameCard card) {
    if (!_isPlayerTurn || _battleEnded) return;

    // Check if player has enough mana
    if (_playerMana < card.manaCost) {
      _addToLog('Not enough mana! Need ${card.manaCost}, have $_playerMana');
      return;
    }

    setState(() {
      _playerHand.remove(card);
      _loadedCards.add(card);
      _playerMana -= card.manaCost;
    });

    _addToLog('Loaded ${card.name} (${card.manaCost} mana)');
  }

  void _executeAttack() {
    if (!_isPlayerTurn || _battleEnded || _loadedCards.isEmpty) return;

    final card = _loadedCards.first;
    _loadedCards.removeAt(0);

    _playCard(card);
    _endTurn();
  }

  void _showInventory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inventory'),
        content: const Text('Inventory feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

    // Simple AI: use a random action card if possible
    if (_enemyHand.isNotEmpty) {
      final actionCard = _enemyHand[_random.nextInt(_enemyHand.length)];
      _useActionCard(actionCard, false);
    }

    // Simple attack
    final damage = _calculateDamage(widget.enemyAtk, 0);
    setState(() {
      _playerHp = (_playerHp - damage).clamp(0, 9999);
    });
    _addToLog('Enemy attacks for $damage damage!');

    if (_playerHp <= 0) {
      _endBattle('enemy');
      return;
    }

    _endTurn();
  }

  void _useActionCard(GameCard card, bool isPlayer) {
    final effect = card.stats?['effect'] as String?;
    if (effect == null) return;

    _addToLog('${isPlayer ? 'You' : 'Enemy'} used ${card.name}');

    switch (effect) {
      case 'miss_turn':
        if (isPlayer) {
          _addToLog('You will miss your next turn!');
          _playerEffects['miss_turn'] = 1;
        }
        break;
      case 'double_attack':
        if (isPlayer) {
          _addToLog('Your next attack will deal double damage!');
          _playerEffects['double_attack'] = 1;
        }
        break;
      case 'mana_boost':
        final amount = card.stats?['amount'] as int? ?? 5;
        if (isPlayer) {
          setState(() {
            _playerMana = (_playerMana + amount).clamp(0, _playerMaxMana);
          });
          _addToLog('Gained $amount mana!');
        }
        break;
    }

    // Remove card from hand
    if (isPlayer) {
      setState(() {
        _actionCards.remove(card);
      });
    } else {
      setState(() {
        _enemyHand.remove(card);
      });
    }
  }

  void _loadCard(GameCard card) {
    if (_playerMana >= card.manaCost) {
      setState(() {
        _loadedCards.add(card);
        _playerHand.remove(card);
        _playerMana -= card.manaCost;
      });
      _addToLog('Loaded ${card.name} into attack');
    } else {
      _addToLog('Not enough mana to load ${card.name}');
    }
  }

  void _executeAttack() {
    if (_loadedCards.isEmpty) {
      // Basic attack
      final damage = _calculateDamage(10, 0);
      _dealDamage(damage, true);
    } else {
      // Enhanced attack
      int totalDamage = 0;
      for (final card in _loadedCards) {
        totalDamage += card.stats?['damage'] as int? ?? 10;
      }

      // Apply double attack effect
      if (_playerEffects.containsKey('double_attack')) {
        totalDamage *= 2;
        _playerEffects.remove('double_attack');
      }

      _dealDamage(totalDamage, true);

      setState(() {
        _loadedCards.clear();
      });
    }
  }

  void _dealDamage(int damage, bool isPlayer) {
    if (isPlayer) {
      setState(() {
        _enemyHp = (_enemyHp - damage).clamp(0, 9999);
      });
      _addToLog('You deal $damage damage!');

      if (_enemyHp <= 0) {
        _endBattle('player');
        return;
      }
    } else {
      setState(() {
        _playerHp = (_playerHp - damage).clamp(0, 9999);
      });
      _addToLog('Enemy deals $damage damage!');

      if (_playerHp <= 0) {
        _endBattle('enemy');
        return;
      }
    }
  }

  int _calculateDamage(int attack, int defense) {
    return (attack - defense).clamp(1, 9999);
  }

  void _endBattle(String winner) {
    _turnTimer?.cancel();

    setState(() {
      _battleEnded = true;
      _winner = winner;
    });

    if (winner == 'player') {
      final xpGained = widget.enemyLevel * 20;
      final goldGained = widget.enemyLevel * 15;

      _addToLog('🎉 Victory! You defeated ${widget.enemyName}!');
      _addToLog('You gained $xpGained XP and $goldGained Gold!');

      // Add rewards
      final eventBus = ref.read(eventBusProvider);
      eventBus.publish(Event(
        type: 'character.add_xp',
        data: {'xp': xpGained},
      ));

      eventBus.publish(Event(
        type: 'inventory.add_gold',
        data: {'gold': goldGained},
      ));

      // Add random item
      final randomItems = ['basic_weapon', 'basic_armor', 'basic_spell', 'health_potion', 'mana_potion'];
      final randomItem = randomItems[_random.nextInt(randomItems.length)];
      eventBus.publish(Event(
        type: 'card.obtain',
        data: {'cardId': randomItem},
      ));

      _addToLog('You also found a $randomItem!');
    } else {
      _addToLog('💀 Defeat! You were defeated by ${widget.enemyName}');

      // Still give some XP
      final eventBus = ref.read(eventBusProvider);
      eventBus.publish(Event(
        type: 'character.add_xp',
        data: {'xp': 5},
      ));
    }
  }

  void _addToLog(String message) {
    setState(() {
      _battleLog.add('${DateTime.now().toString().substring(11, 19)}: $message');
      if (_battleLog.length > 20) {
        _battleLog.removeAt(0);
      }
    });
  }

  void _logDebug(String message) {
    debugPrint('EnhancedBattleScreen: $message');
  }

  void _showCharacterSheet() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Character Sheet'),
        content: const Text('Character sheet will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showInventory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inventory'),
        content: const Text('Inventory will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('⚔️ Battle: ${widget.enemyName}'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _showCharacterSheet(),
            tooltip: 'Character Sheet',
          ),
          IconButton(
            icon: const Icon(Icons.inventory),
            onPressed: () => _showInventory(),
            tooltip: 'Inventory',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red[900]!,
              Colors.red[700]!,
              Colors.orange[800]!,
              Colors.orange[600]!,
            ],
          ),
        ),
        child: Column(
          children: [
            // Enhanced Battle Status
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Player Status
                  Expanded(
                    child: _buildEnhancedPlayerStatus(),
                  ),
                  const SizedBox(width: 16),
                  // Turn Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber, width: 1),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'TURN $_turnNumber',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        if (_isPlayerTurn && !_battleEnded)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _timeRemaining <= 10 ? Colors.red : Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_timeRemaining s',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Enemy Status
                  Expanded(
                    child: _buildEnhancedEnemyStatus(),
                  ),
                ],
              ),
            ),

            // Battle Actions
            if (!_battleEnded && _isPlayerTurn)
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Action Cards
                    if (_actionCards.isNotEmpty) ...[
                      const Text('Action Cards', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _actionCards.length,
                          itemBuilder: (context, index) {
                            final card = _actionCards[index];
                            return Card(
                              margin: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () => _useActionCard(card, true),
                                child: Container(
                                  width: 120,
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    children: [
                                      Text(
                                        card.name,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                      Text(
                                        card.description,
                                        style: const TextStyle(fontSize: 10),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Skill Cards
                    if (_playerHand.isNotEmpty) ...[
                      const Text('Skill Cards', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _playerHand.length,
                          itemBuilder: (context, index) {
                            final card = _playerHand[index];
                            return Card(
                              margin: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () => _loadCard(card),
                                child: Container(
                                  width: 120,
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    children: [
                                      Text(
                                        card.name,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                      Text(
                                        'Mana: ${card.manaCost}',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Loaded Cards
                    if (_loadedCards.isNotEmpty) ...[
                      const Text('Loaded Cards', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _loadedCards.length,
                          itemBuilder: (context, index) {
                            final card = _loadedCards[index];
                            return Card(
                              margin: const EdgeInsets.only(right: 8),
                              color: Colors.blue[100],
                              child: Container(
                                width: 100,
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    Text(
                                      card.name,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      'Mana: ${card.manaCost}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Active Effects
                    if (_playerEffects.isNotEmpty || _enemyEffects.isNotEmpty) ...[
                      const Text('Active Effects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_playerEffects.isNotEmpty) ...[
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Your Effects:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ..._playerEffects.entries.map((entry) => Text(
                                      '• ${entry.key} (${entry.value} turns)',
                                      style: const TextStyle(fontSize: 10),
                                    )),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_enemyEffects.isNotEmpty) ...[
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Enemy Effects:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ..._enemyEffects.entries.map((entry) => Text(
                                      '• ${entry.key} (${entry.value} turns)',
                                      style: const TextStyle(fontSize: 10),
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Attack Button
                    ElevatedButton.icon(
                      onPressed: _executeAttack,
                      icon: const Icon(Icons.sports_kabaddi),
                      label: const Text('Execute Attack'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),

            // Battle Result
            if (_battleEnded)
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _winner == 'player' ? '🎉 Victory!' : '💀 Defeat!',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Return to Map'),
                    ),
                  ],
                ),
              ),

            // Battle Log
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _battleLog.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _battleLog[index],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedPlayerStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _isPlayerTurn && !_battleEnded ? Colors.blue : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          _buildHealthBar(_playerHp, 100, Colors.green),
          const SizedBox(height: 4),
          _buildManaBar(_playerMana, _playerMaxMana),
          if (_playerEffects.isNotEmpty)
            Text(
              'Effects: ${_playerEffects.keys.join(", ")}',
              style: const TextStyle(fontSize: 10, color: Colors.orange),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedEnemyStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            widget.enemyName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: !_isPlayerTurn && !_battleEnded ? Colors.red : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          _buildHealthBar(_enemyHp, widget.enemyHp, Colors.red),
          const SizedBox(height: 4),
          Text('Level: ${widget.enemyLevel}', style: const TextStyle(color: Colors.white)),
          if (_enemyEffects.isNotEmpty)
            Text(
              'Effects: ${_enemyEffects.keys.join(", ")}',
              style: const TextStyle(fontSize: 10, color: Colors.orange),
            ),
        ],
      ),
    );
  }

  Widget _buildHealthBar(int current, int max, Color color) {
    final percentage = max > 0 ? current / max : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HP: $current/$max', style: const TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(height: 2),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManaBar(int current, int max) {
    final percentage = max > 0 ? current / max : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mana: $current/$max', style: const TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(height: 2),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  void _showBattleSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Battle Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Auto Play'),
              subtitle: const Text('Automatically play cards'),
              value: _autoPlayEnabled,
              onChanged: (value) {
                setState(() {
                  _autoPlayEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Fast Mode'),
              subtitle: const Text('Skip animations'),
              value: _fastModeEnabled,
              onChanged: (value) {
                setState(() {
                  _fastModeEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Show Damage Numbers'),
              subtitle: const Text('Display damage/healing numbers'),
              value: _showDamageNumbers,
              onChanged: (value) {
                setState(() {
                  _showDamageNumbers = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Show Particle Effects'),
              subtitle: const Text('Display visual effects'),
              value: _showParticleEffects,
              onChanged: (value) {
                setState(() {
                  _showParticleEffects = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Show Battle Tips'),
              subtitle: const Text('Display helpful tips'),
              value: _showBattleTips,
              onChanged: (value) {
                setState(() {
                  _showBattleTips = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Allow Undo'),
              subtitle: const Text('Allow undoing actions'),
              value: _allowUndo,
              onChanged: (value) {
                setState(() {
                  _allowUndo = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Turn Time Limit: '),
                Expanded(
                  child: Slider(
                    value: _turnTimeLimit.toDouble(),
                    min: 30,
                    max: 120,
                    divisions: 9,
                    label: '${_turnTimeLimit}s',
                    onChanged: (value) {
                      setState(() {
                        _turnTimeLimit = value.round();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _undoLastAction() {
    // TODO: Implement undo functionality
    _addToLog('Undo not implemented yet');
  }
  
  void _showBattleTip() {
    if (!_showBattleTips) return;
    
    final tips = [
      'Use elemental cards for bonus damage!',
      'Save mana for powerful spells',
      'Heal when your health is low',
      'Chain effects for maximum impact',
      'Watch the enemy\'s mana and cards',
    ];
    
    final randomTip = tips[_random.nextInt(tips.length)];
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💡 Tip: $randomTip'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  void _showTutorial() {
    if (!_showTutorial || _tutorialStep >= _tutorialSteps.length) {
      _showTutorial = false;
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Tutorial Step ${_tutorialStep + 1}'),
        content: Text(_tutorialSteps[_tutorialStep]),
        actions: [
          if (_tutorialStep > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  _tutorialStep--;
                });
                Navigator.of(context).pop();
                _showTutorial();
              },
              child: const Text('Previous'),
            ),
          TextButton(
            onPressed: () {
              setState(() {
                _tutorialStep++;
              });
              Navigator.of(context).pop();
              if (_tutorialStep < _tutorialSteps.length) {
                _showTutorial();
              } else {
                _showTutorial = false;
                _addToLog('Tutorial completed!');
              }
            },
            child: Text(_tutorialStep < _tutorialSteps.length - 1 ? 'Next' : 'Finish'),
          ),
        ],
      ),
    );
  }
  
  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Battle Help'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection('Card Types', [
                'Action Cards: Free to play, basic attacks',
                'Skill Cards: Cost mana, powerful effects',
                'Elemental Cards: Bonus damage vs weak elements',
              ]),
              _buildHelpSection('Battle Phases', [
                'Draw Phase: Draw cards from your deck',
                'Action Phase: Play cards and attack',
                'End Phase: Apply effects and end turn',
              ]),
              _buildHelpSection('Elements', [
                'Fire > Ice > Nature > Fire',
                'Light > Dark > Light',
                'Use elemental advantage for bonus damage!',
              ]),
              _buildHelpSection('Tips', [
                'Save mana for powerful spells',
                'Heal when health is low',
                'Watch enemy mana and cards',
                'Chain effects for maximum impact',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHelpSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Text('• $item'),
        )),
        const SizedBox(height: 16),
      ],
    );
  }
}
