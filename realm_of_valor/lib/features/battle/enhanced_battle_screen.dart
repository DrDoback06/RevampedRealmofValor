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
    'Skill cards cost mana but provide powerful effects.',
    'Use your cards wisely to defeat the enemy!',
  ];

  @override
  void initState() {
    super.initState();
    _initializeBattle();
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _phaseTimer?.cancel();
    super.dispose();
  }

  void _initializeBattle() {
    _enemyHp = widget.enemyHp;
    _playerHp = 100;
    _playerMana = _playerMaxMana;
    _enemyMana = 10;
    
    // Initialize decks (placeholder)
    _playerDeck = [];
    _enemyDeck = [];
    
    _startTurn();
  }

  void _startTurn() {
    if (_battleEnded) return;
    
    setState(() {
      _isPlayerTurn = !_isPlayerTurn;
      _turnNumber++;
      _timeRemaining = _turnTimeLimit;
      _currentPhase = BattlePhase.draw;
      _phaseTimeRemaining = 10;
      _cardsDrawnThisTurn = 0;
    });
    
    if (_isPlayerTurn) {
      _playerTurn();
    } else {
      _enemyTurn();
    }
  }

  void _playerTurn() {
    _drawCards(3);
    _startPhaseTimer();
  }

  void _enemyTurn() {
    // Simple AI: draw cards and make a basic attack
    _enemyHp = (_enemyHp - 10).clamp(0, widget.enemyHp);
    _addToLog('Enemy attacks for 10 damage!');
    
    if (_enemyHp <= 0) {
      _endBattle('player');
      return;
    }
    
    _startTurn();
  }

  void _drawCards(int count) {
    // Placeholder implementation
    for (int i = 0; i < count && _playerDeck.isNotEmpty; i++) {
      if (_playerDeck.isNotEmpty) {
        final card = _playerDeck.removeAt(0);
        _playerHand.add(card);
      }
    }
    _addToLog('Drew $count cards');
  }

  void _startPhaseTimer() {
    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _phaseTimeRemaining--;
      });
      
      if (_phaseTimeRemaining <= 0) {
        timer.cancel();
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    switch (_currentPhase) {
      case BattlePhase.draw:
        _currentPhase = BattlePhase.action;
        _phaseTimeRemaining = 30;
        break;
      case BattlePhase.action:
        _currentPhase = BattlePhase.end;
        _phaseTimeRemaining = 5;
        break;
      case BattlePhase.end:
        _endTurn();
        return;
    }
    _startPhaseTimer();
  }

  void _endTurn() {
    _phaseTimer?.cancel();
    _startTurn();
  }

  void _endBattle(String winner) {
    setState(() {
      _battleEnded = true;
      _winner = winner;
    });
    _addToLog('Battle ended! ${winner == 'player' ? 'You' : 'Enemy'} won!');
  }

  void _addToLog(String message) {
    setState(() {
      _battleLog.add('[$_turnNumber] $message');
      if (_battleLog.length > 50) {
        _battleLog.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Battle vs ${widget.enemyName}'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showBattleSettings,
          ),
          IconButton(
            icon: const Icon(Icons.help),
            onPressed: _showHelp,
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
              Colors.red[500]!,
            ],
          ),
        ),
        child: Column(
          children: [
            // Battle status
            _buildBattleStatus(),
            
            // Battle area
            Expanded(
              child: Row(
                children: [
                  // Player side
                  Expanded(
                    child: _buildPlayerSide(),
                  ),
                  
                  // Battle log
                  Container(
                    width: 200,
                    padding: const EdgeInsets.all(8),
                    child: _buildBattleLog(),
                  ),
                ],
              ),
            ),
            
            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleStatus() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: _buildEnhancedPlayerStatus(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildEnhancedEnemyStatus(),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPlayerStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.2),
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
        color: Colors.red.withValues(alpha: 0.2),
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
            color: Colors.black.withValues(alpha: 0.3),
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
            color: Colors.black.withValues(alpha: 0.3),
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

  Widget _buildPlayerSide() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hand
          Expanded(
            child: _buildHand(),
          ),
          
          // Phase indicator
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Phase: ${_currentPhase.name.toUpperCase()} (${_phaseTimeRemaining}s)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHand() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _playerHand.isEmpty
          ? const Center(
              child: Text(
                'No cards in hand',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _playerHand.length,
              itemBuilder: (context, index) {
                final card = _playerHand[index];
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8),
                  child: Card(
                    color: Colors.blue[800],
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            card.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${card.manaCost}',
                            style: TextStyle(
                              color: Colors.blue[200],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildBattleLog() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: _battleLog.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(
              _battleLog[index],
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: _battleEnded ? null : _endTurn,
            child: const Text('End Turn'),
          ),
          ElevatedButton(
            onPressed: _showBattleSettings,
            child: const Text('Settings'),
          ),
          ElevatedButton(
            onPressed: _showHelp,
            child: const Text('Help'),
          ),
        ],
      ),
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

enum BattlePhase {
  draw,
  action,
  end,
}

class AnimationEffect {
  final String id;
  final String type;
  final Duration duration;
  
  AnimationEffect({
    required this.id,
    required this.type,
    required this.duration,
  });
}
