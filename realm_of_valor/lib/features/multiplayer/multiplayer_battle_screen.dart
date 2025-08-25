import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../data/models/card_model.dart';
import '../../../data/models/character_model.dart';
import '../../../services/event_bus.dart';
import '../../../core/di.dart';
import '../character/providers.dart';
import '../inventory/providers.dart';

class MultiplayerBattleScreen extends ConsumerStatefulWidget {
  final String opponentId;
  final String opponentName;
  final int opponentLevel;

  const MultiplayerBattleScreen({
    super.key,
    required this.opponentId,
    required this.opponentName,
    required this.opponentLevel,
  });

  @override
  ConsumerState<MultiplayerBattleScreen> createState() => _MultiplayerBattleScreenState();
}

class _MultiplayerBattleScreenState extends ConsumerState<MultiplayerBattleScreen> {
  late Character _player;
  late Character _opponent;
  List<String> _battleLog = [];
  bool _isPlayerTurn = true;
  bool _isBattleEnded = false;
  String? _winner;
  List<GameCard> _playerHand = [];
  List<GameCard> _opponentHand = [];
  int _playerMana = 3;
  int _opponentMana = 3;
  int _turnNumber = 1;

  @override
  void initState() {
    super.initState();
    _initializeBattle();
  }

  void _initializeBattle() {
    final characterAsync = ref.read(characterWithEquipmentProvider);
    characterAsync.when(
      data: (character) {
        if (character != null) {
          setState(() {
            _player = character;
            _opponent = _createOpponent();
            _dealInitialHands();
            _addToLog('Battle started! ${_player.name} vs ${_opponent.name}');
          });
        }
      },
      loading: () {},
      error: (error, stack) {},
    );
  }

  Character _createOpponent() {
    return Character(
      uid: widget.opponentId,
      id: widget.opponentId,
      name: widget.opponentName,
      level: widget.opponentLevel,
      xp: 0,
      stats: CharacterStats(
        strength: widget.opponentLevel * 3,
        agility: widget.opponentLevel * 2,
        intelligence: widget.opponentLevel * 2,
        vitality: widget.opponentLevel * 4,
      ),
    );
  }

  void _dealInitialHands() {
    final cardDatabase = ref.read(cardDatabaseProvider);
    cardDatabase.when(
      data: (cards) {
        final random = Random();
        final spellCards = cards.where((card) => card.type == CardType.spell).toList();
        
        // Deal 3 cards to each player
        for (int i = 0; i < 3; i++) {
          if (spellCards.isNotEmpty) {
            _playerHand.add(spellCards[random.nextInt(spellCards.length)]);
            _opponentHand.add(spellCards[random.nextInt(spellCards.length)]);
          }
        }
      },
      loading: () {},
      error: (error, stack) {},
    );
  }

  void _addToLog(String message) {
    setState(() {
      _battleLog.add('${DateTime.now().toString().substring(11, 19)}: $message');
      if (_battleLog.length > 50) {
        _battleLog.removeAt(0);
      }
    });
  }

  void _playCard(GameCard card) {
    if (!_isPlayerTurn || _isBattleEnded) return;
    
    if (_playerMana < card.manaCost) {
      _addToLog('Not enough mana to play ${card.name}');
      return;
    }

    setState(() {
      _playerMana -= card.manaCost;
      _playerHand.remove(card);
    });

    // Calculate damage
    final damage = _calculateDamage(card, _player);
    final newVitality = _opponent.stats.vitality - damage;
    _opponent = Character(
      uid: _opponent.uid,
      id: _opponent.id,
      name: _opponent.name,
      level: _opponent.level,
      xp: _opponent.xp,
      stats: CharacterStats(
        strength: _opponent.stats.strength,
        agility: _opponent.stats.agility,
        intelligence: _opponent.stats.intelligence,
        vitality: newVitality,
      ),
      equipment: _opponent.equipment,
      skillPoints: _opponent.skillPoints,
      unlockedSkills: _opponent.unlockedSkills,
    );

    _addToLog('${_player.name} plays ${card.name} for $damage damage!');

    if (newVitality <= 0) {
      _endBattle(_player.name);
      return;
    }

    _isPlayerTurn = false;
    _addToLog('Opponent\'s turn...');
    
    // AI opponent turn
    Future.delayed(const Duration(seconds: 2), () {
      _opponentTurn();
    });
  }

  void _opponentTurn() {
    if (_isBattleEnded) return;

    // Simple AI: play a random card if possible
    if (_opponentHand.isNotEmpty && _opponentMana > 0) {
      final playableCards = _opponentHand.where((card) => card.manaCost <= _opponentMana).toList();
      
      if (playableCards.isNotEmpty) {
        final random = Random();
        final card = playableCards[random.nextInt(playableCards.length)];
        
        setState(() {
          _opponentMana -= card.manaCost;
          _opponentHand.remove(card);
        });

        final damage = _calculateDamage(card, _opponent);
        final newPlayerVitality = _player.stats.vitality - damage;
        _player = Character(
          uid: _player.uid,
          id: _player.id,
          name: _player.name,
          level: _player.level,
          xp: _player.xp,
          stats: CharacterStats(
            strength: _player.stats.strength,
            agility: _player.stats.agility,
            intelligence: _player.stats.intelligence,
            vitality: newPlayerVitality,
          ),
          equipment: _player.equipment,
          skillPoints: _player.skillPoints,
          unlockedSkills: _player.unlockedSkills,
        );

        _addToLog('${_opponent.name} plays ${card.name} for $damage damage!');

        if (newPlayerVitality <= 0) {
          _endBattle(_opponent.name);
          return;
        }
      }
    }

    _nextTurn();
  }

  void _nextTurn() {
    setState(() {
      _turnNumber++;
      _isPlayerTurn = true;
      _playerMana = min(3 + _turnNumber ~/ 3, 10); // Increase mana every 3 turns, max 10
      _opponentMana = min(3 + _turnNumber ~/ 3, 10);
    });

    _addToLog('Turn $_turnNumber - Mana: $_playerMana');

    // Draw a card
    _drawCard();
  }

  void _drawCard() {
    final cardDatabase = ref.read(cardDatabaseProvider);
    cardDatabase.when(
      data: (cards) {
        final random = Random();
        final spellCards = cards.where((card) => card.type == CardType.spell).toList();
        
        if (spellCards.isNotEmpty && _playerHand.length < 7) {
          setState(() {
            _playerHand.add(spellCards[random.nextInt(spellCards.length)]);
          });
          _addToLog('Drew a card');
        }
      },
      loading: () {},
      error: (error, stack) {},
    );
  }

  int _calculateDamage(GameCard card, Character caster) {
    if (card.stats == null || !card.stats!.containsKey('damage')) {
      return 5; // Default damage
    }

    final baseDamage = card.stats!['damage'] as int;
    final intelligence = caster.stats.intelligence;
    final spellPower = intelligence * 0.1; // Intelligence increases spell damage
    
    return (baseDamage + spellPower).round();
  }

  void _endBattle(String winner) {
    setState(() {
      _isBattleEnded = true;
      _winner = winner;
    });

    _addToLog('$winner wins the battle!');

    // Publish battle result event
    final eventBus = ref.read(eventBusProvider);
    eventBus.publish(Event(
      type: 'battle.multiplayer_result',
      data: {
        'winner': winner,
        'player': _player.name,
        'opponent': _opponent.name,
        'turns': _turnNumber,
      },
    ));
  }

  void _surrender() {
    _endBattle(_opponent.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Battle vs ${widget.opponentName}'),
        actions: [
          if (!_isBattleEnded)
            TextButton(
              onPressed: _surrender,
              child: const Text('Surrender', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Battle Status
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: _buildPlayerStatus(_player, 'Player', Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPlayerStatus(_opponent, 'Opponent', Colors.red),
                ),
              ],
            ),
          ),

          // Turn Info
          Container(
            padding: const EdgeInsets.all(8),
            color: _isPlayerTurn ? Colors.green[100] : Colors.orange[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isPlayerTurn ? 'Your Turn' : 'Opponent\'s Turn',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Turn $_turnNumber • Mana: $_playerMana'),
              ],
            ),
          ),

          // Battle Log
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Battle Log',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _battleLog.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _battleLog[index],
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Player Hand
          if (!_isBattleEnded)
            Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Hand',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _playerHand.length,
                      itemBuilder: (context, index) {
                        final card = _playerHand[index];
                        final canPlay = _isPlayerTurn && _playerMana >= card.manaCost;
                        
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 8),
                          child: Card(
                            color: canPlay ? null : Colors.grey[300],
                            child: InkWell(
                              onTap: canPlay ? () => _playCard(card) : null,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  children: [
                                    Text(
                                      card.name,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${card.manaCost}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${card.stats?['damage'] ?? 0}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Battle Result
          if (_isBattleEnded)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '$_winner wins!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Return to Map'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatus(Character character, String label, Color color) {
    final maxHp = character.stats.vitality * 10;
    final currentHp = character.stats.vitality * 10;
    final hpPercentage = currentHp / maxHp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${character.name}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text('Level ${character.level}'),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: hpPercentage,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        Text('HP: $currentHp/$maxHp'),
      ],
    );
  }
}
