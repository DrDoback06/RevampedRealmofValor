import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/models/quest_model.dart';
import '../../../services/navigation_service.dart';
import '../battle/enhanced_battle_screen.dart';
import '../map/map_screen.dart';

class QuestDetailScreen extends ConsumerStatefulWidget {
  final Quest quest;

  const QuestDetailScreen({
    super.key,
    required this.quest,
  });

  @override
  ConsumerState<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends ConsumerState<QuestDetailScreen> {
  LatLng? _currentPosition;
  RouteInfo? _routeInfo;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _getRouteToQuest();
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _getRouteToQuest() async {
    if (_currentPosition == null || widget.quest.location == null) return;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final route = await NavigationService.getRoute(
        origin: _currentPosition!,
        destination: LatLng(
          widget.quest.location!.latitude,
          widget.quest.location!.longitude,
        ),
      );

      setState(() {
        _routeInfo = route;
        _isLoadingRoute = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRoute = false;
      });
      debugPrint('Error getting route: $e');
    }
  }

  double _calculateDistance() {
    if (_currentPosition == null || widget.quest.location == null) return 0;
    
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.quest.location!.latitude,
      widget.quest.location!.longitude,
    );
  }

  String _getQuestTypeString(QuestType type) {
    switch (type) {
      case QuestType.battle:
        return 'Battle Quest';
      case QuestType.treasure:
        return 'Treasure Hunt';
      case QuestType.location:
        return 'Exploration';
      case QuestType.story:
        return 'Story Quest';
      case QuestType.fitness:
        return 'Fitness Challenge';
      case QuestType.social:
        return 'Social Quest';
      case QuestType.daily:
        return 'Daily Quest';
      case QuestType.weekly:
        return 'Weekly Quest';
    }
  }

  Color _getQuestTypeColor(QuestType type) {
    switch (type) {
      case QuestType.battle:
        return Colors.red;
      case QuestType.treasure:
        return Colors.blue;
      case QuestType.location:
        return Colors.green;
      case QuestType.story:
        return Colors.purple;
      case QuestType.fitness:
        return Colors.orange;
      case QuestType.social:
        return Colors.cyan;
      case QuestType.daily:
        return Colors.yellow;
      case QuestType.weekly:
        return Colors.indigo;
    }
  }

  IconData _getQuestTypeIcon(QuestType type) {
    switch (type) {
      case QuestType.battle:
        return Icons.sword;
      case QuestType.treasure:
        return Icons.chest;
      case QuestType.location:
        return Icons.explore;
      case QuestType.story:
        return Icons.book;
      case QuestType.fitness:
        return Icons.fitness_center;
      case QuestType.social:
        return Icons.people;
      case QuestType.daily:
        return Icons.today;
      case QuestType.weekly:
        return Icons.calendar_view_week;
    }
  }

  void _startBattle() {
    if (widget.quest.type == QuestType.battle) {
      // Extract enemy stats from quest tags
      final enemyLevel = int.tryParse(
        widget.quest.tags.firstWhere(
          (tag) => tag.startsWith('enemy_level:'),
          orElse: () => 'enemy_level:1',
        ).split(':')[1],
      ) ?? 1;

      final enemyHp = int.tryParse(
        widget.quest.tags.firstWhere(
          (tag) => tag.startsWith('enemy_hp:'),
          orElse: () => 'enemy_hp:100',
        ).split(':')[1],
      ) ?? 100;

      final enemyAtk = int.tryParse(
        widget.quest.tags.firstWhere(
          (tag) => tag.startsWith('enemy_atk:'),
          orElse: () => 'enemy_atk:10',
        ).split(':')[1],
      ) ?? 10;

      final enemyDef = int.tryParse(
        widget.quest.tags.firstWhere(
          (tag) => tag.startsWith('enemy_def:'),
          orElse: () => 'enemy_def:5',
        ).split(':')[1],
      ) ?? 5;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EnhancedBattleScreen(
            enemyId: widget.quest.id,
            enemyName: widget.quest.title,
            enemyLevel: enemyLevel,
            enemyHp: enemyHp,
            enemyAtk: enemyAtk,
            enemyDef: enemyDef,
          ),
        ),
      );
    }
  }

  void _navigateToQuest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MapScreen(),
      ),
    );
  }

  void _trackFitness() {
    if (widget.quest.type == QuestType.fitness) {
      // TODO: Implement fitness tracking
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fitness tracking started!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final distance = _calculateDistance();
    final questColor = _getQuestTypeColor(widget.quest.type);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quest.title),
        backgroundColor: questColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement quest sharing
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quest header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: questColor,
                          child: Icon(
                            _getQuestTypeIcon(widget.quest.type),
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getQuestTypeString(widget.quest.type),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: questColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.quest.title,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.quest.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location and distance
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Location',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.quest.location != null) ...[
                      Text(
                        '${widget.quest.location!.latitude.toStringAsFixed(4)}, ${widget.quest.location!.longitude.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.directions_walk, size: 16),
                          const SizedBox(width: 4),
                          Text('${distance.toStringAsFixed(0)}m away'),
                          const Spacer(),
                          if (_routeInfo != null)
                            Text(
                              '${_routeInfo!.duration.inMinutes} min walk',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ] else
                      const Text('No location specified'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Objectives
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.checklist, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Objectives',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...widget.quest.objectives.map((objective) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            objective.progress >= objective.target
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: objective.progress >= objective.target
                                ? Colors.green
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(objective.description),
                          ),
                          Text(
                            '${objective.progress}/${objective.target}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rewards
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          'Rewards',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (widget.quest.rewards.xp > 0) ...[
                          _buildRewardChip(
                            '${widget.quest.rewards.xp} XP',
                            Icons.trending_up,
                            Colors.green,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (widget.quest.rewards.gold > 0) ...[
                          _buildRewardChip(
                            '${widget.quest.rewards.gold} Gold',
                            Icons.monetization_on,
                            Colors.amber,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (widget.quest.rewards.gems > 0) ...[
                          _buildRewardChip(
                            '${widget.quest.rewards.gems} Gems',
                            Icons.diamond,
                            Colors.blue,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (widget.quest.rewards.skillPoints > 0) ...[
                          _buildRewardChip(
                            '${widget.quest.rewards.skillPoints} SP',
                            Icons.psychology,
                            Colors.purple,
                          ),
                        ],
                      ],
                    ),
                    if (widget.quest.rewards.items.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Items: ${widget.quest.rewards.items.join(', ')}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _navigateToQuest,
                            icon: const Icon(Icons.navigation),
                            label: const Text('Navigate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (widget.quest.type == QuestType.battle)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _startBattle,
                              icon: const Icon(Icons.sword),
                              label: const Text('Start Battle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        if (widget.quest.type == QuestType.fitness)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _trackFitness,
                              icon: const Icon(Icons.fitness_center),
                              label: const Text('Track Fitness'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildRewardChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

