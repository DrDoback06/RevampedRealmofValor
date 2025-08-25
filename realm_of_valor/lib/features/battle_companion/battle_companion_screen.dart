import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../../../data/models/character_model.dart';
import '../../../data/models/card_model.dart';
import '../character/providers.dart';
import '../inventory/providers.dart';

class BattleCompanionScreen extends ConsumerStatefulWidget {
  const BattleCompanionScreen({super.key});

  @override
  ConsumerState<BattleCompanionScreen> createState() => _BattleCompanionScreenState();
}

class _BattleCompanionScreenState extends ConsumerState<BattleCompanionScreen> {
  final TextEditingController _playerAtkController = TextEditingController();
  final TextEditingController _playerDefController = TextEditingController();
  final TextEditingController _enemyAtkController = TextEditingController();
  final TextEditingController _enemyDefController = TextEditingController();
  final TextEditingController _playerHpController = TextEditingController();
  final TextEditingController _enemyHpController = TextEditingController();
  
  double _criticalChance = 0.15; // 15% base critical chance
  double _criticalMultiplier = 2.0; // 2x damage on crit
  bool _showAdvancedStats = false;
  final List<String> _battleLog = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadCharacterStats();
  }

  @override
  void dispose() {
    _playerAtkController.dispose();
    _playerDefController.dispose();
    _enemyAtkController.dispose();
    _enemyDefController.dispose();
    _playerHpController.dispose();
    _enemyHpController.dispose();
    super.dispose();
  }

  void _loadCharacterStats() {
    final characterAsync = ref.read(characterWithEquipmentProvider);
    characterAsync.when(
      data: (character) {
        if (character != null) {
          setState(() {
            _playerAtkController.text = character.stats.strength.toString();
            _playerDefController.text = (character.stats.agility ~/ 2).toString();
            _playerHpController.text = (character.stats.vitality * 10).toString();
          });
        }
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  void _addToLog(String message) {
    setState(() {
      _battleLog.add('${DateTime.now().toString().substring(11, 19)}: $message');
      if (_battleLog.length > 20) {
        _battleLog.removeAt(0);
      }
    });
  }

  void _calculateDamage() {
    try {
      final playerAtk = int.tryParse(_playerAtkController.text) ?? 0;
      final playerDef = int.tryParse(_playerDefController.text) ?? 0;
      final enemyAtk = int.tryParse(_enemyAtkController.text) ?? 0;
      final enemyDef = int.tryParse(_enemyDefController.text) ?? 0;
      final playerHp = int.tryParse(_playerHpController.text) ?? 100;
      final enemyHp = int.tryParse(_enemyHpController.text) ?? 100;

      if (playerAtk <= 0 || enemyHp <= 0) {
        _showErrorDialog('Please enter valid attack and HP values.');
        return;
      }

      _simulateBattle(playerAtk, playerDef, enemyAtk, enemyDef, playerHp, enemyHp);
    } catch (e) {
      _showErrorDialog('Error calculating damage: $e');
    }
  }

  void _simulateBattle(int playerAtk, int playerDef, int enemyAtk, int enemyDef, int playerHp, int enemyHp) {
    _addToLog('=== Battle Simulation Started ===');
    _addToLog('Player: ATK=$playerAtk, DEF=$playerDef, HP=$playerHp');
    _addToLog('Enemy: ATK=$enemyAtk, DEF=$enemyDef, HP=$enemyHp');
    _addToLog('');

    int currentPlayerHp = playerHp;
    int currentEnemyHp = enemyHp;
    int turn = 1;

    while (currentPlayerHp > 0 && currentEnemyHp > 0 && turn <= 20) {
      _addToLog('--- Turn $turn ---');
      
      // Player attacks
      final playerDamage = _calculateAttackDamage(playerAtk, enemyDef, 'Player');
      currentEnemyHp = (currentEnemyHp - playerDamage).clamp(0, enemyHp);
      _addToLog('Enemy HP: $currentEnemyHp/$enemyHp');
      
      if (currentEnemyHp <= 0) {
        _addToLog('🎉 Player wins!');
        break;
      }

      // Enemy attacks
      final enemyDamage = _calculateAttackDamage(enemyAtk, playerDef, 'Enemy');
      currentPlayerHp = (currentPlayerHp - enemyDamage).clamp(0, playerHp);
      _addToLog('Player HP: $currentPlayerHp/$playerHp');
      
      if (currentPlayerHp <= 0) {
        _addToLog('💀 Enemy wins!');
        break;
      }

      turn++;
    }

    if (turn > 20) {
      _addToLog('⏰ Battle timed out after 20 turns');
    }

    _addToLog('=== Battle Simulation Ended ===');
  }

  int _calculateAttackDamage(int attack, int defense, String attacker) {
    final baseDamage = (attack - defense).clamp(1, 9999);
    
    // Check for critical hit
    final isCritical = _random.nextDouble() < _criticalChance;
    final damage = isCritical ? (baseDamage * _criticalMultiplier).round() : baseDamage;
    
    if (isCritical) {
      _addToLog('💥 $attacker lands a CRITICAL HIT!');
      _addToLog('   Base damage: $baseDamage → Critical damage: $damage');
    } else {
      _addToLog('⚔️ $attacker deals $damage damage');
    }
    
    return damage;
  }

  void _rollDice() {
    final diceType = _showDiceTypeDialog();
    if (diceType != null) {
      final result = _random.nextInt(diceType) + 1;
      _addToLog('🎲 Rolling d$diceType: $result');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎲 d$diceType: $result'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  int? _showDiceTypeDialog() {
    int? selectedDice;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Dice Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDiceButton(context, 4, () => selectedDice = 4),
            _buildDiceButton(context, 6, () => selectedDice = 6),
            _buildDiceButton(context, 8, () => selectedDice = 8),
            _buildDiceButton(context, 10, () => selectedDice = 10),
            _buildDiceButton(context, 12, () => selectedDice = 12),
            _buildDiceButton(context, 20, () => selectedDice = 20),
            _buildDiceButton(context, 100, () => selectedDice = 100),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
    return selectedDice;
  }

  Widget _buildDiceButton(BuildContext context, int sides, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: () {
          onPressed();
          Navigator.of(context).pop();
        },
        child: Text('d$sides'),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Battle Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Critical Hit Chance: ${(_criticalChance * 100).toStringAsFixed(1)}%'),
            Text('Critical Hit Multiplier: ${_criticalMultiplier}x'),
            const SizedBox(height: 16),
            const Text('Damage Formula:'),
            const Text('Base Damage = Attack - Defense'),
            const Text('Critical Damage = Base Damage × Multiplier'),
            const SizedBox(height: 16),
            const Text('Tips:'),
            const Text('• Higher attack increases damage'),
            const Text('• Higher defense reduces incoming damage'),
            const Text('• Critical hits deal bonus damage'),
            const Text('• HP determines battle endurance'),
          ],
        ),
        actions: [
          ElevatedButton(
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
        title: const Text('Battle Companion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showStatsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.casino),
            onPressed: _rollDice,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Character Stats Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Character Stats',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final characterAsync = ref.watch(characterWithEquipmentProvider);
                        return characterAsync.when(
                          data: (character) {
                            if (character == null) {
                              return const Text('No character data');
                            }
                            return Column(
                              children: [
                                Text('Level: ${character.level}'),
                                Text('Strength: ${character.stats.strength}'),
                                Text('Agility: ${character.stats.agility}'),
                                Text('Intelligence: ${character.stats.intelligence}'),
                                Text('Vitality: ${character.stats.vitality}'),
                              ],
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Text('Error loading character'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Battle Calculator
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Battle Calculator',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // Player Stats
                    const Text('Player Stats:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _playerAtkController,
                            decoration: const InputDecoration(
                              labelText: 'Attack',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _playerDefController,
                            decoration: const InputDecoration(
                              labelText: 'Defense',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _playerHpController,
                            decoration: const InputDecoration(
                              labelText: 'HP',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Enemy Stats
                    const Text('Enemy Stats:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _enemyAtkController,
                            decoration: const InputDecoration(
                              labelText: 'Attack',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _enemyDefController,
                            decoration: const InputDecoration(
                              labelText: 'Defense',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _enemyHpController,
                            decoration: const InputDecoration(
                              labelText: 'HP',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Critical Hit Settings
                    ExpansionTile(
                      title: const Text('Critical Hit Settings'),
                      children: [
                        Column(
                          children: [
                            Row(
                              children: [
                                const Text('Critical Chance: '),
                                Expanded(
                                  child: Slider(
                                    value: _criticalChance,
                                    min: 0.0,
                                    max: 1.0,
                                    divisions: 20,
                                    label: '${(_criticalChance * 100).toStringAsFixed(1)}%',
                                    onChanged: (value) {
                                      setState(() {
                                        _criticalChance = value;
                                      });
                                    },
                                  ),
                                ),
                                Text('${(_criticalChance * 100).toStringAsFixed(1)}%'),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('Critical Multiplier: '),
                                Expanded(
                                  child: Slider(
                                    value: _criticalMultiplier,
                                    min: 1.0,
                                    max: 5.0,
                                    divisions: 40,
                                    label: _criticalMultiplier.toStringAsFixed(1),
                                    onChanged: (value) {
                                      setState(() {
                                        _criticalMultiplier = value;
                                      });
                                    },
                                  ),
                                ),
                                Text('${_criticalMultiplier.toStringAsFixed(1)}x'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Calculate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _calculateDamage,
                        icon: const Icon(Icons.calculate),
                        label: const Text('Simulate Battle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Battle Log
            if (_battleLog.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Battle Log',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _battleLog.clear();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _battleLog.length,
                          itemBuilder: (context, index) {
                            final message = _battleLog[index];
                            Color textColor = Colors.black;
                            
                            if (message.contains('CRITICAL')) {
                              textColor = Colors.red;
                            } else if (message.contains('wins')) {
                              textColor = Colors.green;
                            } else if (message.contains('Turn')) {
                              textColor = Colors.blue;
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                message,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor,
                                  fontWeight: message.contains('CRITICAL') ? FontWeight.bold : FontWeight.normal,
                                ),
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
      ),
    );
  }
}
