import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../../data/models/character_model.dart';
import '../../data/models/battle_model.dart';
import '../../services/event_bus.dart';
import '../../core/di.dart';
import '../character/providers.dart';
import '../inventory/providers.dart';

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

class _BattleScreenState extends ConsumerState<BattleScreen> {
  BattleState? _battleState;
  bool _isPlayerTurn = true;
  bool _battleEnded = false;
  String? _winner;
  final List<String> _battleLog = [];

  @override
  void initState() {
    super.initState();
    _initializeBattle();
  }

  void _initializeBattle() {
    final character = ref.read(characterStreamProvider).value;
    final computedStats = ref.read(computedStatsProvider);
    if (character == null) return;

    // Use computed stats if available, otherwise fall back to base stats
    final hp = computedStats?.maxHp ?? (character.stats.vitality * 10);
    final atk = computedStats?.attack ?? character.stats.strength;
    final def = computedStats?.defense ?? (character.stats.agility ~/ 2);

    final player = BattleEntity(
      id: 'player',
      name: character.name,
      hp: hp,
      atk: atk,
      def: def,
    );

    final enemy = BattleEntity(
      id: widget.enemyId,
      name: widget.enemyName,
      hp: widget.enemyHp,
      atk: widget.enemyAtk,
      def: widget.enemyDef,
    );

    _battleState = BattleState(player: player, enemy: enemy);
    _addToLog('Battle started! ${player.name} vs ${enemy.name}');
    _addToLog('Player stats - HP: $hp, ATK: $atk, DEF: $def');
  }

  void _addToLog(String message) {
    setState(() {
      _battleLog.add('${DateTime.now().toString().substring(11, 19)}: $message');
      if (_battleLog.length > 20) {
        _battleLog.removeAt(0);
      }
    });
  }

  void _attack() {
    if (_battleState == null || _battleEnded || !_isPlayerTurn) return;

    final damage = (_battleState!.player.atk - _battleState!.enemy.def).clamp(1, 9999);
    _battleState!.enemy.hp = (_battleState!.enemy.hp - damage).clamp(0, 9999);

    _addToLog('${_battleState!.player.name} attacks for $damage damage!');
    _addToLog('${_battleState!.enemy.name} HP: ${_battleState!.enemy.hp}');

    if (_battleState!.enemy.hp <= 0) {
      _endBattle('player');
      return;
    }

    _isPlayerTurn = false;
    _enemyTurn();
  }

  void _enemyTurn() {
    if (_battleState == null || _battleEnded) return;

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      final damage = (_battleState!.enemy.atk - _battleState!.player.def).clamp(1, 9999);
      _battleState!.player.hp = (_battleState!.player.hp - damage).clamp(0, 9999);

      _addToLog('${_battleState!.enemy.name} attacks for $damage damage!');
      _addToLog('${_battleState!.player.name} HP: ${_battleState!.player.hp}');

      if (_battleState!.player.hp <= 0) {
        _endBattle('enemy');
        return;
      }

      setState(() {
        _isPlayerTurn = true;
      });
    });
  }

  void _endBattle(String winner) {
    setState(() {
      _battleEnded = true;
      _winner = winner;
    });

    if (winner == 'player') {
      final xpGained = widget.enemyLevel * 15;
      final goldGained = widget.enemyLevel * 10;
      
      _addToLog('Victory! You defeated ${_battleState!.enemy.name}!');
      _addToLog('You gained $xpGained XP and $goldGained Gold!');
      
      // Add rewards to character and inventory
      final eventBus = ref.read(eventBusProvider);
      eventBus.publish(Event(
        type: 'character.add_xp',
        data: {'xp': xpGained},
      ));
      
      eventBus.publish(Event(
        type: 'inventory.add_gold',
        data: {'gold': goldGained},
      ));
      
      // Add random item reward
      final randomItems = ['basic_weapon', 'basic_armor', 'basic_spell', 'health_potion', 'mana_potion'];
      final randomItem = randomItems[Random().nextInt(randomItems.length)];
      eventBus.publish(Event(
        type: 'card.obtain',
        data: {'cardId': randomItem},
      ));
      
      _addToLog('You also found a $randomItem!');
      
      // Publish battle victory event
      eventBus.publish(Event(
        type: 'battle.victory',
        data: {
          'enemy_id': widget.enemyId,
          'enemy_name': widget.enemyName,
          'enemy_level': widget.enemyLevel,
          'xp_gained': xpGained,
          'gold_gained': goldGained,
          'item_gained': randomItem,
        },
      ));
    } else {
      _addToLog('Defeat! You were defeated by ${_battleState!.enemy.name}');
      
      // Still give some XP for trying
      final eventBus = ref.read(eventBusProvider);
      eventBus.publish(Event(
        type: 'character.add_xp',
        data: {'xp': 5},
      ));
    }
  }

  void _flee() {
    if (_battleEnded) return;

    setState(() {
      _battleEnded = true;
      _winner = 'flee';
    });

    _addToLog('You fled from battle!');
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_battleState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Battle: ${_battleState!.enemy.name}'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Battle Status
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Player Status
                Expanded(
                  child: _buildEntityStatus(
                    _battleState!.player,
                    Colors.blue,
                    _isPlayerTurn && !_battleEnded,
                  ),
                ),
                const SizedBox(width: 16),
                // VS
                const Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                // Enemy Status
                Expanded(
                  child: _buildEntityStatus(
                    _battleState!.enemy,
                    Colors.red,
                    !_isPlayerTurn && !_battleEnded,
                  ),
                ),
              ],
            ),
          ),

          // Battle Actions
          if (!_battleEnded)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_isPlayerTurn) ...[
                    ElevatedButton.icon(
                      onPressed: _attack,
                      icon: const Icon(Icons.sports_kabaddi),
                      label: const Text('Attack'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _flee,
                      icon: const Icon(Icons.directions_run),
                      label: const Text('Flee'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ] else ...[
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 16),
                            Text('Enemy is thinking...'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Battle Result
          if (_battleEnded)
            Container(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: _winner == 'player' ? Colors.green[100] : Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        _winner == 'player' ? Icons.emoji_events : Icons.warning,
                        size: 48,
                        color: _winner == 'player' ? Colors.green : Colors.red,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _winner == 'player' ? 'Victory!' : 'Defeat!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Battle Log
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.history, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Battle Log',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
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
        ],
      ),
    );
  }

  Widget _buildEntityStatus(BattleEntity entity, Color color, bool isActive) {
    final maxHp = entity.id == 'player' ? 100 : widget.enemyHp;
    final hpPercentage = entity.hp / maxHp;

    return Card(
      color: isActive ? color.withOpacity(0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              entity.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            // HP Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('HP'),
                    Text('${entity.hp}/$maxHp'),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: hpPercentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    hpPercentage > 0.5 ? Colors.green : 
                    hpPercentage > 0.25 ? Colors.orange : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('ATK', style: TextStyle(fontSize: 12)),
                    Text('${entity.atk}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    const Text('DEF', style: TextStyle(fontSize: 12)),
                    Text('${entity.def}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
