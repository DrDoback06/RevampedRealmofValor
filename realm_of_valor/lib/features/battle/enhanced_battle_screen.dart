import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:async';
import '../../../data/models/character_model.dart';
import '../../../data/models/card_model.dart';
import '../../../services/event_bus.dart';
import '../../../core/di.dart';
import '../character/providers.dart';
import '../inventory/providers.dart';

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
  
  // Player state
  int _playerHp = 100;
  int _playerMana = 10;
  int _playerMaxMana = 10;
  List<GameCard> _playerHand = [];
  List<GameCard> _loadedCards = [];
  List<GameCard> _actionCards = [];
  
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

    // Deal 5 action cards to each player
    _actionCards = _generateActionCards(5);
    _enemyHand = _generateActionCards(5);

    // Deal 5 skill/inventory cards to player
    _playerHand = _generateSkillCards(5);

    _addToLog('Dealt 5 action cards and 5 skill cards');
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

      // Draw a card
      _drawCard();

      // Apply lasting effects
      _applyLastingEffects();

      _startTurnTimer();
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

    // Simple AI: prioritize attacks when low on HP, use buffs early
    final enemyCard = _enemyHand.isNotEmpty ? _enemyHand.first : null;
    if (enemyCard != null) {
      _enemyHand.removeAt(0);
      _playCard(enemyCard, isEnemy: true);
    }

    // End enemy turn after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!_battleEnded) {
        _endTurn();
      }
    });
  }

  void _playCard(GameCard card, {bool isEnemy = false}) {
    _addToLog('${isEnemy ? 'Enemy' : 'You'} played: ${card.name}');

    // Apply card effects
    _applyCardEffect(card, isEnemy: isEnemy);

    // Check for battle end
    _checkBattleEnd();
  }

  void _applyCardEffect(GameCard card, {bool isEnemy = false}) {
    final target = isEnemy ? 'enemy' : 'player';
    final effect = card.stats?['effect'] as String?;
    final damage = card.stats?['damage'] as int? ?? 0;
    final healing = card.stats?['healing'] as int? ?? 0;
    final manaCost = card.manaCost;

    // Apply damage
    if (damage > 0) {
      if (isEnemy) {
        _playerHp = max(0, _playerHp - damage);
        _addToLog('You took $damage damage!');
      } else {
        _enemyHp = max(0, _enemyHp - damage);
        _addToLog('Enemy took $damage damage!');
      }
    }

    // Apply healing
    if (healing > 0) {
      if (isEnemy) {
        _enemyHp = min(widget.enemyHp, _enemyHp + healing);
        _addToLog('Enemy healed $healing HP!');
      } else {
        _playerHp = min(100, _playerHp + healing);
        _addToLog('You healed $healing HP!');
      }
    }

    // Apply special effects
    switch (effect) {
      case 'double_attack':
        if (!isEnemy) {
          _playerEffects['double_attack'] = 1;
          _addToLog('Double attack active for 1 turn!');
        }
        break;
      case 'mana_boost':
        if (!isEnemy) {
          _playerMana = min(_playerMaxMana, _playerMana + 5);
          _addToLog('Gained 5 mana!');
        }
        break;
      case 'swap_cards':
        if (!isEnemy) {
          final tempHand = List<GameCard>.from(_playerHand);
          _playerHand = List<GameCard>.from(_enemyHand);
          _enemyHand = tempHand;
          _addToLog('Cards swapped!');
        }
        break;
      case 'miss_turn':
        if (!isEnemy) {
          _addToLog('Enemy will miss their next turn!');
          _enemyEffects['miss_turn'] = 1;
        }
        break;
      case 'stop_action':
        if (!isEnemy) {
          _addToLog('Enemy action cancelled!');
        }
        break;
    }

    // Consume mana
    if (!isEnemy && manaCost > 0) {
      _playerMana = max(0, _playerMana - manaCost);
    }
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_winner == 'player' ? 'Victory!' : 'Defeat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_winner == 'player' ? 'You won the battle!' : 'You were defeated!'),
            const SizedBox(height: 16),
            if (_winner == 'player') ...[
              Text('XP Gained: ${widget.enemyLevel * 10}'),
              Text('Gold Gained: ${widget.enemyLevel * 5}'),
              const SizedBox(height: 8),
              const Text('Rewards:'),
              ..._generateBattleRewards().map((reward) => Text('• $reward')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  List<String> _generateBattleRewards() {
    final rewards = <String>[];
    
    // Always give XP and gold
    rewards.add('${widget.enemyLevel * 10} XP');
    rewards.add('${widget.enemyLevel * 5} Gold');
    
    // Random chance for items
    if (_random.nextDouble() < 0.3) {
      rewards.add('Random Card');
    }
    
    if (_random.nextDouble() < 0.1) {
      rewards.add('Rare Item');
    }
    
    return rewards;
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
}
