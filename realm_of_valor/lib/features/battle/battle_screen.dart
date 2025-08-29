import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'dart:async';
import '../../../data/models/character_model.dart';
import '../../../data/models/card_model.dart';
import '../../../data/models/battle_model.dart' as battle_model;
import '../../../services/event_bus.dart';
import '../../../core/di.dart';
import '../character/providers.dart';
import '../inventory/providers.dart';
import 'advanced_card_mechanics.dart';

class BattleScreen extends ConsumerStatefulWidget {
  final String enemyId;
  final String enemyName;
  final int enemyLevel;
  final int enemyHp;
  final int enemyAtk;
  final int enemyDef;

  const BattleScreen({
    super.key,
    required this.enemyId,
    required this.enemyName,
    required this.enemyLevel,
    required this.enemyHp,
    required this.enemyAtk,
    required this.enemyDef,
  });

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> 
    with TickerProviderStateMixin {
  battle_model.BattleState? _battleState;
  bool _isPlayerTurn = true;
  bool _battleEnded = false;
  String? _winner;
  final List<BattleLogEntry> _battleLog = [];
  
  // Card system
  List<GameCard> _playerHand = [];
  List<GameCard> _playerDeck = [];
  List<GameCard> _playerDiscardPile = [];
  List<GameCard> _enemyHand = [];
  List<GameCard> _enemyDeck = [];
  List<GameCard> _enemyDiscardPile = [];
  
  // Battle state
  int _playerMana = 10;
  int _enemyMana = 10;
  int _turnNumber = 1;
  final Random _random = Random();
  
  // Animations
  late AnimationController _cardAnimationController;
  late AnimationController _damageAnimationController;
  late AnimationController _turnAnimationController;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _damageScaleAnimation;
  late Animation<double> _turnIndicatorAnimation;
  
  // UI State
  GameCard? _selectedCard;
  bool _isProcessingAction = false;
  Timer? _turnTimer;
  int _turnTimeRemaining = 30; // 30 seconds per turn
  
  // Visual effects
  bool _showDamageEffect = false;
  String _lastDamageText = '';
  Offset _damagePosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeBattle();
  }

  void _initializeAnimations() {
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _damageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _turnAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _cardSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    _damageScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _damageAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _turnIndicatorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _turnAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeBattle() {
    final character = ref.read(characterStreamProvider).value;
    if (character == null) return;

    final player = battle_model.BattleEntity(
      id: 'player',
      name: character.name,
      hp: character.stats.vitality * 10,
      atk: character.stats.strength,
      def: character.stats.agility ~/ 2,
    );

    final enemy = battle_model.BattleEntity(
      id: widget.enemyId,
      name: widget.enemyName,
      hp: widget.enemyHp,
      atk: widget.enemyAtk,
      def: widget.enemyDef,
    );

    _battleState = battle_model.BattleState(player: player, enemy: enemy);
    
    // Initialize card decks
    _initializeDecks();
    
    // Draw initial hands
    _drawCards(5, isPlayer: true);
    _drawCards(5, isPlayer: false);
    
    _addToLog('Battle started! ${player.name} vs ${enemy.name}', LogType.info);
    _addToLog('Cards drawn! Check your hand for combos.', LogType.info);
    
    // Start turn timer
    _startTurnTimer();
  }

  void _initializeDecks() {
    // Create player deck with character's cards
    _playerDeck = _generatePlayerDeck();
    _enemyDeck = _generateEnemyDeck();
    
    // Shuffle decks
    _playerDeck.shuffle(_random);
    _enemyDeck.shuffle(_random);
  }

  List<GameCard> _generatePlayerDeck() {
    final deck = <GameCard>[];
    
    // Add basic attack cards
    for (int i = 0; i < 8; i++) {
      deck.add(GameCard(
        id: 'basic_attack_$i',
        name: 'Slash',
        description: 'A swift sword strike',
        type: CardType.skill,
        rarity: CardRarity.common,
        element: CardElement.none,
        level: 1,
        manaCost: 1,
        stats: {'damage': 6},
        abilities: ['attack'],
        tags: ['basic'],
      ));
    }
    
    // Add element-based cards
    final elements = [CardElement.fire, CardElement.ice, CardElement.lightning];
    for (int i = 0; i < 4; i++) {
      final element = elements[i % elements.length];
      deck.add(GameCard(
        id: '${element.name}_spell_$i',
        name: '${element.name.capitalize()} Bolt',
        description: 'A powerful ${element.name} spell',
        type: CardType.spell,
        rarity: CardRarity.uncommon,
        element: element,
        level: 1,
        manaCost: 2,
        stats: {'damage': 10},
        abilities: ['spell', element.name],
        tags: ['elemental'],
      ));
    }
    
    // Add healing cards
    for (int i = 0; i < 3; i++) {
      deck.add(GameCard(
        id: 'heal_$i',
        name: 'Heal Wounds',
        description: 'Restore health with magic',
        type: CardType.spell,
        rarity: CardRarity.common,
        element: CardElement.light,
        level: 1,
        manaCost: 2,
        stats: {'healing': 12},
        abilities: ['heal'],
        tags: ['healing'],
      ));
    }
    
    // Add defensive cards
    for (int i = 0; i < 3; i++) {
      deck.add(GameCard(
        id: 'block_$i',
        name: 'Shield Block',
        description: 'Block incoming damage',
        type: CardType.skill,
        rarity: CardRarity.common,
        element: CardElement.none,
        level: 1,
        manaCost: 1,
        stats: {'block': 8},
        abilities: ['defend'],
        tags: ['defensive'],
      ));
    }
    
    return deck;
  }

  List<GameCard> _generateEnemyDeck() {
    final deck = <GameCard>[];
    
    for (int i = 0; i < 12; i++) {
      deck.add(GameCard(
        id: 'enemy_attack_$i',
        name: 'Claw Strike',
        description: 'Sharp claws tear through armor',
        type: CardType.skill,
        rarity: CardRarity.common,
        element: CardElement.none,
        level: widget.enemyLevel,
        manaCost: 1,
        stats: {'damage': widget.enemyAtk ~/ 2},
        abilities: ['attack'],
        tags: ['enemy'],
      ));
    }
    
    // Add enemy special abilities
    for (int i = 0; i < 3; i++) {
      deck.add(GameCard(
        id: 'enemy_special_$i',
        name: 'Feral Rage',
        description: 'Enemy becomes enraged',
        type: CardType.skill,
        rarity: CardRarity.uncommon,
        element: CardElement.none,
        level: widget.enemyLevel,
        manaCost: 2,
        stats: {'damage': widget.enemyAtk},
        abilities: ['attack', 'rage'],
        tags: ['enemy', 'special'],
      ));
    }
    
    return deck;
  }

  void _drawCards(int count, {required bool isPlayer}) {
    final deck = isPlayer ? _playerDeck : _enemyDeck;
    final hand = isPlayer ? _playerHand : _enemyHand;
    
    for (int i = 0; i < count && deck.isNotEmpty; i++) {
      hand.add(deck.removeAt(0));
    }
    
    if (isPlayer) {
      _addToLog('Drew $count cards', LogType.info);
      _cardAnimationController.forward().then((_) {
        _cardAnimationController.reverse();
      });
    }
  }

  void _playCard(GameCard card) {
    if (!_isPlayerTurn || _battleEnded || _isProcessingAction || _playerMana < card.manaCost) return;
    
    setState(() {
      _isProcessingAction = true;
      _selectedCard = card;
    });
    
    _playerMana -= card.manaCost;
    _playerHand.remove(card);
    _playerDiscardPile.add(card);
    
    // Apply card effects
    _applyCardEffects(card);
    
    _addToLog('Played ${card.name}', LogType.action);
    
    // Check for win condition
    if (_battleState!.enemy.hp <= 0) {
      _endBattle('player');
      return;
    }
    
    // End turn after a short delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        _isProcessingAction = false;
        _selectedCard = null;
      });
      _endPlayerTurn();
    });
  }

  void _applyCardEffects(GameCard card) {
    final stats = card.stats ?? {};
    
    if (stats.containsKey('damage')) {
      final damage = stats['damage'] as int;
      final finalDamage = (damage - _battleState!.enemy.def).clamp(1, 9999);
      _battleState!.enemy.hp = (_battleState!.enemy.hp - finalDamage).clamp(0, 9999);
      _showDamageEffect = true;
      _lastDamageText = '-$finalDamage';
      _damagePosition = const Offset(0.7, 0.3); // Enemy position
      _damageAnimationController.forward().then((_) {
        setState(() {
          _showDamageEffect = false;
        });
        _damageAnimationController.reset();
      });
      _addToLog('Dealt $finalDamage damage!', LogType.damage);
    }
    
    if (stats.containsKey('healing')) {
      final healing = stats['healing'] as int;
      _battleState!.player.hp = (_battleState!.player.hp + healing).clamp(0, _battleState!.player.hp + 100);
      _showDamageEffect = true;
      _lastDamageText = '+$healing';
      _damagePosition = const Offset(0.3, 0.3); // Player position
      _damageAnimationController.forward().then((_) {
        setState(() {
          _showDamageEffect = false;
        });
        _damageAnimationController.reset();
      });
      _addToLog('Healed $healing HP!', LogType.heal);
    }
    
    if (stats.containsKey('block')) {
      final block = stats['block'] as int;
      _addToLog('Gained $block block!', LogType.defend);
    }
  }

  void _endPlayerTurn() {
    _isPlayerTurn = false;
    _addToLog('Your turn ended', LogType.info);
    _stopTurnTimer();
    
    // Enemy turn
    Future.delayed(const Duration(seconds: 1), () {
      _enemyTurn();
    });
  }

  void _enemyTurn() {
    if (_battleEnded) return;
    
    _addToLog('Enemy turn...', LogType.info);
    
    // Simple AI: play random cards
    while (_enemyHand.isNotEmpty && _enemyMana > 0) {
      final playableCards = _enemyHand.where((card) => card.manaCost <= _enemyMana).toList();
      if (playableCards.isEmpty) break;
      
      final card = playableCards[_random.nextInt(playableCards.length)];
      _enemyMana -= card.manaCost;
      _enemyHand.remove(card);
      _enemyDiscardPile.add(card);
      
      // Apply enemy card effects
      final stats = card.stats ?? {};
      if (stats.containsKey('damage')) {
        final damage = stats['damage'] as int;
        final finalDamage = (damage - _battleState!.player.def).clamp(1, 9999);
        _battleState!.player.hp = (_battleState!.player.hp - finalDamage).clamp(0, 9999);
        _showDamageEffect = true;
        _lastDamageText = '-$finalDamage';
        _damagePosition = const Offset(0.3, 0.3); // Player position
        _damageAnimationController.forward().then((_) {
          setState(() {
            _showDamageEffect = false;
          });
          _damageAnimationController.reset();
        });
        _addToLog('Enemy dealt $finalDamage damage!', LogType.damage);
      }
    }
    
    // Check for player defeat
    if (_battleState!.player.hp <= 0) {
      _endBattle('enemy');
      return;
    }
    
    // End enemy turn
    _endEnemyTurn();
  }

  void _endEnemyTurn() {
    _turnNumber++;
    _isPlayerTurn = true;
    _playerMana = 10; // Reset mana each turn
    _enemyMana = 10;
    
    // Draw cards
    _drawCards(3, isPlayer: true);
    _drawCards(3, isPlayer: false);
    
    _addToLog('Turn $_turnNumber - Your turn! Mana: $_playerMana', LogType.info);
    _startTurnTimer();
  }

  void _startTurnTimer() {
    _turnTimeRemaining = 30;
    _turnTimer?.cancel();
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_turnTimeRemaining > 0) {
        setState(() {
          _turnTimeRemaining--;
        });
      } else {
        timer.cancel();
        if (_isPlayerTurn && !_battleEnded) {
          _addToLog('Turn time expired!', LogType.warning);
          _endPlayerTurn();
        }
      }
    });
  }

  void _stopTurnTimer() {
    _turnTimer?.cancel();
  }

  void _endBattle(String winner) {
    _battleEnded = true;
    _winner = winner;
    _stopTurnTimer();
    _addToLog('Battle ended! ${winner == 'player' ? 'You won!' : 'You lost!'}', 
        winner == 'player' ? LogType.victory : LogType.defeat);
    
    if (winner == 'player') {
      // Give rewards
      _addToLog('You gained 100 XP and 50 gold!', LogType.reward);
    }
  }

  void _addToLog(String message, LogType type) {
    setState(() {
      _battleLog.add(BattleLogEntry(
        message: message,
        type: type,
        timestamp: DateTime.now(),
      ));
      if (_battleLog.length > 15) {
        _battleLog.removeAt(0);
      }
    });
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _damageAnimationController.dispose();
    _turnAnimationController.dispose();
    _turnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_battleState == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Battle header
              _buildBattleHeader(),
              
              // Battle arena
              Expanded(
                child: _buildBattleArena(),
              ),
              
              // Player hand
              _buildPlayerHand(),
              
              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBattleHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          
          Expanded(
            child: Column(
              children: [
                Text(
                  'Battle vs ${widget.enemyName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Turn $_turnNumber',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Turn timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _turnTimeRemaining > 10 ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_turnTimeRemaining s',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleArena() {
    return Stack(
      children: [
        // Battle log
        Positioned(
          top: 0,
          right: 0,
          width: 200,
          height: 200,
          child: _buildBattleLog(),
        ),
        
        // Player status
        Positioned(
          left: 20,
          top: 20,
          child: _buildEntityStatus(_battleState!.player, isPlayer: true),
        ),
        
        // Enemy status
        Positioned(
          right: 20,
          top: 20,
          child: _buildEntityStatus(_battleState!.enemy, isPlayer: false),
        ),
        
        // Damage effect
        if (_showDamageEffect)
          Positioned(
            left: MediaQuery.of(context).size.width * _damagePosition.dx - 50,
            top: MediaQuery.of(context).size.height * _damagePosition.dy - 25,
            child: AnimatedBuilder(
              animation: _damageScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _damageScaleAnimation.value,
                  child: Text(
                    _lastDamageText,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _lastDamageText.startsWith('+') ? Colors.green : Colors.red,
                      shadows: const [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 4,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        
        // Turn indicator
        if (_isPlayerTurn)
          Positioned(
            left: 0,
            right: 0,
            top: 100,
            child: AnimatedBuilder(
              animation: _turnIndicatorAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _turnIndicatorAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'YOUR TURN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEntityStatus(battle_model.BattleEntity entity, {required bool isPlayer}) {
    final maxHp = isPlayer ? entity.hp + 100 : widget.enemyHp;
    final hpPercentage = entity.hp / maxHp;
    
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPlayer ? Colors.blue : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            entity.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          
          // HP Bar
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: hpPercentage,
              child: Container(
                decoration: BoxDecoration(
                  color: hpPercentage > 0.5 ? Colors.green : hpPercentage > 0.25 ? Colors.orange : Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 4),
          Text(
            'HP: ${entity.hp}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          
          if (isPlayer) ...[
            const SizedBox(height: 8),
            // Mana Bar
            Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _playerMana / 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            Text(
              'Mana: $_playerMana',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBattleLog() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: _battleLog.length,
        itemBuilder: (context, index) {
          final entry = _battleLog[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              entry.message,
              style: TextStyle(
                color: _getLogColor(entry.type),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getLogColor(LogType type) {
    switch (type) {
      case LogType.info:
        return Colors.white;
      case LogType.action:
        return Colors.cyan;
      case LogType.damage:
        return Colors.red;
      case LogType.heal:
        return Colors.green;
      case LogType.defend:
        return Colors.yellow;
      case LogType.warning:
        return Colors.orange;
      case LogType.victory:
        return Colors.green;
      case LogType.defeat:
        return Colors.red;
      case LogType.reward:
        return Colors.amber;
    }
  }

  Widget _buildPlayerHand() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Hand (${_playerHand.length} cards)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _playerHand.isEmpty
                ? Center(
                    child: Text(
                      'No cards in hand',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _playerHand.length,
                    itemBuilder: (context, index) {
                      final card = _playerHand[index];
                      final canPlay = _isPlayerTurn && !_battleEnded && !_isProcessingAction && _playerMana >= card.manaCost;
                      
                      return AnimatedBuilder(
                        animation: _cardSlideAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, (1 - _cardSlideAnimation.value) * 50),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: _buildCardWidget(card, canPlay),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWidget(GameCard card, bool canPlay) {
    return GestureDetector(
      onTap: canPlay ? () => _playCard(card) : null,
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          color: canPlay ? Colors.white : Colors.grey[600],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canPlay ? Colors.blue : Colors.grey[400]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: canPlay ? Colors.blue.withOpacity(0.3) : Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card name
              Text(
                card.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: canPlay ? Colors.black : Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Mana cost
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
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
              
              const SizedBox(height: 8),
              
              // Card description
              Expanded(
                child: Text(
                  card.description,
                  style: TextStyle(
                    fontSize: 10,
                    color: canPlay ? Colors.black87 : Colors.white70,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Card stats
              if (card.stats?.containsKey('damage') == true)
                Text(
                  'DMG: ${card.stats!['damage']}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: canPlay ? Colors.red : Colors.red[300],
                  ),
                ),
              
              if (card.stats?.containsKey('healing') == true)
                Text(
                  'HEAL: ${card.stats!['healing']}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: canPlay ? Colors.green : Colors.green[300],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _battleEnded ? null : () => _drawCards(1, isPlayer: true),
            icon: const Icon(Icons.add),
            label: const Text('Draw'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _battleEnded ? null : () => _endPlayerTurn(),
            icon: const Icon(Icons.skip_next),
            label: const Text('End Turn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Flee'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class BattleLogEntry {
  final String message;
  final LogType type;
  final DateTime timestamp;

  BattleLogEntry({
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

enum LogType {
  info,
  action,
  damage,
  heal,
  defend,
  warning,
  victory,
  defeat,
  reward,
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
