import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/character_model.dart';
import '../../../data/models/card_model.dart';
import '../../../data/models/inventory_model.dart';
import '../inventory/providers.dart';
import 'providers.dart';
import 'character_models.dart';

class SkillTreeWidget extends ConsumerStatefulWidget {
  final Character character;

  const SkillTreeWidget({
    super.key,
    required this.character,
  });

  @override
  ConsumerState<SkillTreeWidget> createState() => _SkillTreeWidgetState();
}

class _SkillTreeWidgetState extends ConsumerState<SkillTreeWidget> {
  final List<SkillNode> _skillNodes = [];
  final List<SkillNode> _unlockedNodes = [];
  GameCard? _draggedCard;
  
  // Skill tree visualization
  bool _showConnections = true;
  bool _showAnimations = true;
  bool _showTooltips = true;
  double _zoomLevel = 1.0;
  Offset _panOffset = Offset.zero;
  SkillNode? _hoveredNode;
  
  // Skill analytics
  Map<String, int> _skillUsage = {};
  Map<String, DateTime> _skillUnlockDates = {};
  List<SkillProgress> _skillProgress = [];
  
  // Search and filtering
  String _searchQuery = '';
  SkillSpecialization? _selectedSpecialization;
  int? _selectedTier;
  bool _showUnlockedOnly = false;

  @override
  void initState() {
    super.initState();
    _initializeSkillTree();
  }

  void _initializeSkillTree() {
    // Define skill tree structure with specializations
    _skillNodes.addAll([
      // Tier 1 - Basic Skills (Foundation)
      SkillNode(
        id: 'basic_attack',
        name: 'Basic Attack',
        description: 'A fundamental attack skill',
        tier: 1,
        position: const Offset(0, 0),
        requiredSkillPoints: 1,
        cardType: CardType.spell,
        element: CardElement.none,
        specialization: SkillSpecialization.combat,
      ),
      SkillNode(
        id: 'basic_defense',
        name: 'Basic Defense',
        description: 'A fundamental defense skill',
        tier: 1,
        position: const Offset(1, 0),
        requiredSkillPoints: 1,
        cardType: CardType.spell,
        element: CardElement.none,
        specialization: SkillSpecialization.combat,
      ),
      SkillNode(
        id: 'mana_control',
        name: 'Mana Control',
        description: 'Improve mana efficiency',
        tier: 1,
        position: const Offset(2, 0),
        requiredSkillPoints: 1,
        cardType: CardType.spell,
        element: CardElement.arcane,
        specialization: SkillSpecialization.magic,
      ),
      SkillNode(
        id: 'meditation',
        name: 'Meditation',
        description: 'Enhance mental focus and recovery',
        tier: 1,
        position: const Offset(3, 0),
        requiredSkillPoints: 1,
        cardType: CardType.spell,
        element: CardElement.light,
        specialization: SkillSpecialization.support,
      ),

      // Tier 2 - Intermediate Skills (Specialization Paths)
      SkillNode(
        id: 'fire_magic',
        name: 'Fire Magic',
        description: 'Master the element of fire',
        tier: 2,
        position: const Offset(0, 1),
        requiredSkillPoints: 2,
        cardType: CardType.spell,
        element: CardElement.fire,
        prerequisites: ['basic_attack'],
        specialization: SkillSpecialization.magic,
        masteryLevel: 0,
        maxMasteryLevel: 5,
      ),
      SkillNode(
        id: 'ice_magic',
        name: 'Ice Magic',
        description: 'Master the element of ice',
        tier: 2,
        position: const Offset(1, 1),
        requiredSkillPoints: 2,
        cardType: CardType.spell,
        element: CardElement.ice,
        prerequisites: ['basic_attack'],
        specialization: SkillSpecialization.magic,
        masteryLevel: 0,
        maxMasteryLevel: 5,
      ),
      SkillNode(
        id: 'healing_magic',
        name: 'Healing Magic',
        description: 'Learn to heal wounds',
        tier: 2,
        position: const Offset(2, 1),
        requiredSkillPoints: 2,
        cardType: CardType.spell,
        element: CardElement.light,
        prerequisites: ['mana_control'],
        specialization: SkillSpecialization.support,
        masteryLevel: 0,
        maxMasteryLevel: 5,
      ),
      SkillNode(
        id: 'weapon_mastery',
        name: 'Weapon Mastery',
        description: 'Master the art of combat',
        tier: 2,
        position: const Offset(3, 1),
        requiredSkillPoints: 2,
        cardType: CardType.spell,
        element: CardElement.none,
        prerequisites: ['basic_attack', 'basic_defense'],
        specialization: SkillSpecialization.combat,
        masteryLevel: 0,
        maxMasteryLevel: 5,
      ),

      // Tier 3 - Advanced Skills (Synergy Paths)
      SkillNode(
        id: 'dual_casting',
        name: 'Dual Casting',
        description: 'Cast two spells simultaneously',
        tier: 3,
        position: const Offset(0.5, 2),
        requiredSkillPoints: 3,
        cardType: CardType.spell,
        element: CardElement.arcane,
        prerequisites: ['fire_magic', 'ice_magic'],
        specialization: SkillSpecialization.magic,
        masteryLevel: 0,
        maxMasteryLevel: 5,
        synergies: ['fire_magic', 'ice_magic'],
      ),
      SkillNode(
        id: 'elemental_mastery',
        name: 'Elemental Mastery',
        description: 'Master all elements',
        tier: 3,
        position: const Offset(1.5, 2),
        requiredSkillPoints: 3,
        cardType: CardType.spell,
        element: CardElement.none,
        prerequisites: ['fire_magic', 'ice_magic', 'healing_magic'],
        specialization: SkillSpecialization.magic,
        masteryLevel: 0,
        maxMasteryLevel: 5,
        synergies: ['fire_magic', 'ice_magic', 'healing_magic'],
      ),
      SkillNode(
        id: 'battle_healing',
        name: 'Battle Healing',
        description: 'Heal while in combat',
        tier: 3,
        position: const Offset(2.5, 2),
        requiredSkillPoints: 3,
        cardType: CardType.spell,
        element: CardElement.light,
        prerequisites: ['healing_magic', 'weapon_mastery'],
        specialization: SkillSpecialization.support,
        masteryLevel: 0,
        maxMasteryLevel: 5,
        synergies: ['weapon_mastery'],
      ),

      // Tier 4 - Master Skills
      SkillNode(
        id: 'ultimate_magic',
        name: 'Ultimate Magic',
        description: 'The pinnacle of magical power',
        tier: 4,
        position: const Offset(1, 3),
        requiredSkillPoints: 5,
        cardType: CardType.spell,
        element: CardElement.arcane,
        prerequisites: ['dual_casting', 'elemental_mastery'],
      ),
    ]);

    // Mark already unlocked skills
    for (final skillId in widget.character.unlockedSkills) {
      final node = _skillNodes.firstWhere(
        (node) => node.id == skillId,
        orElse: () => SkillNode(
          id: skillId,
          name: 'Unknown Skill',
          description: 'Unknown skill',
          tier: 1,
          position: const Offset(0, 0),
          requiredSkillPoints: 1,
          cardType: CardType.spell,
          element: CardElement.none,
        ),
      );
      _unlockedNodes.add(node);
    }
  }

  bool _canUnlockSkill(SkillNode node) {
    // Check if already unlocked
    if (_unlockedNodes.any((unlocked) => unlocked.id == node.id)) {
      return false;
    }

    // Check if has enough skill points
    if (widget.character.skillPoints < node.requiredSkillPoints) {
      return false;
    }

    // Check prerequisites
    for (final prerequisite in node.prerequisites) {
      if (!_unlockedNodes.any((unlocked) => unlocked.id == prerequisite)) {
        return false;
      }
    }

    return true;
  }

  bool _canDragCardToNode(GameCard card, SkillNode node) {
    // Check if node can be unlocked
    if (!_canUnlockSkill(node)) {
      return false;
    }

    // Check if card type matches
    if (card.type != node.cardType) {
      return false;
    }

    // Check if element matches (if node has specific element)
    if (node.element != CardElement.none && card.element != node.element) {
      return false;
    }

    return true;
  }
  
  void _showRespecDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Skill Tree'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reset your skill tree?'),
            const SizedBox(height: 16),
            Text('This will refund ${_unlockedNodes.length} skill points.'),
            const SizedBox(height: 8),
            const Text('Cost: 100 Gold', style: TextStyle(color: Colors.amber)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetSkillTree();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
  
  void _resetSkillTree() {
    // TODO: Check if player has enough gold
    final cost = 100;
    
    setState(() {
      // Refund skill points
      final refundedPoints = _unlockedNodes.length;
      
      // Clear unlocked nodes
      _unlockedNodes.clear();
      
      // Update character skill points
      // TODO: Update character provider
      
      // TODO: Deduct gold from inventory
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Skill tree reset! Refunded $_unlockedNodes.length skill points.'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _showPartialRespecDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partial Skill Reset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select skills to reset:'),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _unlockedNodes.length,
                itemBuilder: (context, index) {
                  final node = _unlockedNodes[index];
                  return CheckboxListTile(
                    title: Text(node.name),
                    subtitle: Text('Tier ${node.tier}'),
                    value: false, // TODO: Track selected nodes
                    onChanged: (value) {
                      // TODO: Update selection
                    },
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _partialResetSkillTree();
            },
            child: const Text('Reset Selected'),
          ),
        ],
      ),
    );
  }
  
  void _partialResetSkillTree() {
    // TODO: Implement partial reset logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partial reset not implemented yet')),
    );
  }
  
  void _showBuildTemplates() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skill Build Templates'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _buildTemplateCard('Fire Mage', 'Focus on fire magic and damage', [
                      'basic_attack', 'fire_magic', 'advanced_fire', 'dual_casting'
                    ], Colors.red),
                    _buildTemplateCard('Ice Mage', 'Focus on ice magic and control', [
                      'basic_attack', 'ice_magic', 'advanced_ice', 'dual_casting'
                    ], Colors.blue),
                    _buildTemplateCard('Healer', 'Focus on healing and support', [
                      'mana_control', 'healing_magic', 'battle_healing', 'meditation'
                    ], Colors.green),
                    _buildTemplateCard('Warrior', 'Focus on combat and defense', [
                      'basic_attack', 'basic_defense', 'weapon_mastery', 'battle_healing'
                    ], Colors.orange),
                    _buildTemplateCard('Elementalist', 'Master all elements', [
                      'fire_magic', 'ice_magic', 'healing_magic', 'elemental_mastery'
                    ], Colors.purple),
                  ],
                ),
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
  
  Widget _buildTemplateCard(String name, String description, List<String> skills, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(name[0], style: const TextStyle(color: Colors.white)),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Text('Skills: ${skills.length}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _applyTemplate(skills),
          child: const Text('Apply'),
        ),
      ),
    );
  }
  
  void _applyTemplate(List<String> skillIds) {
    // Check if player has enough skill points
    final totalCost = skillIds.length;
    if (widget.character.skillPoints < totalCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough skill points! Need $totalCost, have ${widget.character.skillPoints}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Apply template
    setState(() {
      _unlockedNodes.clear();
      for (final skillId in skillIds) {
        final node = _skillNodes.firstWhere((node) => node.id == skillId);
        _unlockedNodes.add(node);
      }
    });
    
    Navigator.of(context).pop(); // Close dialog
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied template with ${skillIds.length} skills!'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _exportBuild() {
    final buildData = {
      'name': 'Custom Build',
      'description': 'Custom skill build',
      'skills': _unlockedNodes.map((node) => node.id).toList(),
      'total_points': _unlockedNodes.length,
      'specializations': _unlockedNodes.map((node) => node.specialization?.name).toSet().toList(),
    };
    
    // TODO: Implement actual export functionality
    final buildString = buildData.toString();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Build exported! (${buildString.length} characters)'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  void _importBuild() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Build'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste build data:'),
            const SizedBox(height: 16),
            TextField(
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste build data here...',
              ),
              onChanged: (value) {
                // TODO: Parse build data
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Apply imported build
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Build import not implemented yet')),
              );
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _unlockSkill(SkillNode node, GameCard card) {
    if (!_canUnlockSkill(node)) return;

    setState(() {
      _unlockedNodes.add(node);
      
      // Track skill analytics
      _skillUnlockDates[node.id] = DateTime.now();
      _skillUsage[node.id] = 0;
      
      // Create progress tracking
      _skillProgress.add(SkillProgress(
        skillId: node.id,
        skillName: node.name,
        unlockDate: DateTime.now(),
        usageCount: 0,
        masteryProgress: 0.0,
      ));
    });

    // Update character in Firestore
    final characterActions = ref.read(characterActionsProvider);
    characterActions.unlockSkill(node.id);

    // Remove card from inventory
    final inventoryActions = ref.read(inventoryActionsProvider);
    inventoryActions.removeCard(card.id);

    // Consume skill points
    characterActions.spendSkillPoints(node.requiredSkillPoints);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unlocked ${node.name}!'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _showSkillAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skill Analytics'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: Column(
            children: [
              _buildAnalyticsSummary(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _skillProgress.length,
                  itemBuilder: (context, index) {
                    final progress = _skillProgress[index];
                    return _buildSkillProgressCard(progress);
                  },
                ),
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
  
  Widget _buildAnalyticsSummary() {
    final totalSkills = _unlockedNodes.length;
    final totalUsage = _skillUsage.values.fold<int>(0, (sum, usage) => sum + usage);
    final avgMastery = _skillProgress.isEmpty ? 0.0 : 
        _skillProgress.map((p) => p.masteryProgress).reduce((a, b) => a + b) / _skillProgress.length;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Total Skills: $totalSkills', style: const TextStyle(fontSize: 16)),
            Text('Total Usage: $totalUsage', style: const TextStyle(fontSize: 16)),
            Text('Average Mastery: ${avgMastery.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSkillProgressCard(SkillProgress progress) {
    final daysSinceUnlock = DateTime.now().difference(progress.unlockDate).inDays;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(progress.skillName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unlocked: $daysSinceUnlock days ago'),
            Text('Usage: ${progress.usageCount} times'),
            LinearProgressIndicator(
              value: progress.masteryProgress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            Text('Mastery: ${progress.masteryProgress.toStringAsFixed(1)}%'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.info),
          onPressed: () => _showSkillDetails(progress),
        ),
      ),
    );
  }
  
  void _showSkillDetails(SkillProgress progress) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(progress.skillName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unlock Date: ${progress.unlockDate.toString().split(' ')[0]}'),
            Text('Days Owned: ${DateTime.now().difference(progress.unlockDate).inDays}'),
            Text('Usage Count: ${progress.usageCount}'),
            Text('Mastery Progress: ${progress.masteryProgress.toStringAsFixed(1)}%'),
            const SizedBox(height: 16),
            const Text('Usage History:', style: TextStyle(fontWeight: FontWeight.bold)),
            // TODO: Add detailed usage history
            const Text('No detailed history available'),
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
  
  void _showSkillTreeSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skill Tree Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Show Connections'),
              subtitle: const Text('Display skill tree connections'),
              value: _showConnections,
              onChanged: (value) {
                setState(() {
                  _showConnections = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Show Animations'),
              subtitle: const Text('Display skill unlock animations'),
              value: _showAnimations,
              onChanged: (value) {
                setState(() {
                  _showAnimations = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Show Tooltips'),
              subtitle: const Text('Display skill information tooltips'),
              value: _showTooltips,
              onChanged: (value) {
                setState(() {
                  _showTooltips = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Zoom Level: '),
                Expanded(
                  child: Slider(
                    value: _zoomLevel,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: '${(_zoomLevel * 100).round()}%',
                    onChanged: (value) {
                      setState(() {
                        _zoomLevel = value;
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
  
  List<SkillNode> _getFilteredNodes() {
    return _skillNodes.where((node) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!node.name.toLowerCase().contains(query) &&
            !node.description.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // Specialization filter
      if (_selectedSpecialization != null && node.specialization != _selectedSpecialization) {
        return false;
      }
      
      // Tier filter
      if (_selectedTier != null && node.tier != _selectedTier) {
        return false;
      }
      
      // Unlocked only filter
      if (_showUnlockedOnly && !_unlockedNodes.any((unlocked) => unlocked.id == node.id)) {
        return false;
      }
      
      return true;
    }).toList();
  }
  
  Widget _buildSkillNode(SkillNode node, bool isUnlocked, bool canUnlock, bool isDraggingValid) {
    return DragTarget<GameCard>(
      onWillAccept: (card) => card != null && _canDragCardToNode(card, node),
      onAccept: (card) => _unlockSkill(node, card),
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () => _showSkillDetails(node),
          onHover: (isHovered) {
            setState(() {
              _hoveredNode = isHovered ? node : null;
            });
          },
          child: Container(
            width: 100 * _zoomLevel,
            height: 100 * _zoomLevel,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? Colors.green
                  : canUnlock
                      ? Colors.blue
                      : Colors.grey,
              border: Border.all(
                color: isDraggingValid ? Colors.yellow : Colors.black,
                width: isDraggingValid ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    node.name,
                    style: TextStyle(
                      fontSize: 10 * _zoomLevel,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Tier ${node.tier}',
                    style: TextStyle(
                      fontSize: 8 * _zoomLevel,
                      color: Colors.white70,
                    ),
                  ),
                  if (isUnlocked && node.masteryLevel > 0)
                    Text(
                      'Lv.${node.masteryLevel}',
                      style: TextStyle(
                        fontSize: 8 * _zoomLevel,
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _showSkillDetails(SkillNode node) {
    if (!_showTooltips) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(node.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(node.description),
            const SizedBox(height: 16),
            Text('Tier: ${node.tier}'),
            Text('Required Points: ${node.requiredSkillPoints}'),
            Text('Element: ${node.element.name}'),
            if (node.specialization != null)
              Text('Specialization: ${node.specialization!.name}'),
            if (node.masteryLevel > 0) ...[
              Text('Mastery Level: ${node.masteryLevel}/${node.maxMasteryLevel}'),
              Text('Mastery Progress: ${node.masteryProgress.toStringAsFixed(1)}%'),
            ],
            if (node.prerequisites.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Prerequisites:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...node.prerequisites.map((prereq) => Text('• $prereq')),
            ],
            if (node.synergies.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Synergies:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...node.synergies.map((synergy) => Text('• $synergy')),
            ],
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

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryStreamProvider);
    final characterAsync = ref.watch(characterStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Tree'),
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showSkillAnalytics,
            tooltip: 'Skill Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.template),
            onPressed: _showBuildTemplates,
            tooltip: 'Build Templates',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSkillTreeSettings,
            tooltip: 'Settings',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportBuild();
                  break;
                case 'import':
                  _importBuild();
                  break;
                case 'reset':
                  _showRespecDialog();
                  break;
                case 'partial_reset':
                  _showPartialRespecDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Text('Export Build'),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Text('Import Build'),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Text('Reset All'),
              ),
              const PopupMenuItem(
                value: 'partial_reset',
                child: Text('Partial Reset'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Skill points display
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple[100],
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      'Skill Points: ${widget.character.skillPoints}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      'Unlocked: ${_unlockedNodes.length}/${_skillNodes.length}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search skills...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                // Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<SkillSpecialization>(
                        value: _selectedSpecialization,
                        decoration: const InputDecoration(
                          labelText: 'Specialization',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All'),
                          ),
                          ...SkillSpecialization.values.map((spec) => DropdownMenuItem(
                            value: spec,
                            child: Text(spec.name.toUpperCase()),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSpecialization = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedTier,
                        decoration: const InputDecoration(
                          labelText: 'Tier',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All'),
                          ),
                          ...List.generate(4, (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('Tier ${index + 1}'),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTier = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _showUnlockedOnly,
                      onChanged: (value) {
                        setState(() {
                          _showUnlockedOnly = value;
                        });
                      },
                    ),
                    const Text('Unlocked Only'),
                  ],
                ),
              ],
            ),
          ),

          // Skill tree visualization
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: CustomPaint(
                size: Size.infinite,
                painter: SkillTreePainter(
                  nodes: _getFilteredNodes(),
                  unlockedNodes: _unlockedNodes,
                  draggedCard: _draggedCard,
                  showConnections: _showConnections,
                ),
                child: Stack(
                  children: _getFilteredNodes().map((node) {
                    final isUnlocked = _unlockedNodes.any((unlocked) => unlocked.id == node.id);
                    final canUnlock = _canUnlockSkill(node);
                    final isDraggingValid = _draggedCard != null && _canDragCardToNode(_draggedCard!, node);

                    return Positioned(
                      left: node.position.dx * 120 * _zoomLevel + _panOffset.dx,
                      top: node.position.dy * 120 * _zoomLevel + _panOffset.dy,
                      child: _showAnimations
                          ? Container(
                              width: 100 * _zoomLevel,
                              height: 100 * _zoomLevel,
                            ).animate()
                              .scale(duration: const Duration(milliseconds: 300))
                              .then()
                              .shimmer(duration: const Duration(seconds: 2))
                              .child(
                                _buildSkillNode(node, isUnlocked, canUnlock, isDraggingValid),
                              )
                          : _buildSkillNode(node, isUnlocked, canUnlock, isDraggingValid),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
                              border: Border.all(
                                color: isDraggingValid ? Colors.yellow : Colors.black,
                                width: isDraggingValid ? 3 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getSkillIcon(node),
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  node.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  '${node.requiredSkillPoints} SP',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Inventory cards for dragging
          Container(
            height: 120,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Drag cards to unlock skills:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: inventoryAsync.when(
                    data: (inventory) {
                      if (inventory == null) return const Text('No inventory data');

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
                          ),
                        );
                        availableCards.add(card);
                      }

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableCards.length,
                        itemBuilder: (context, index) {
                          final card = availableCards[index];
                          return Draggable<GameCard>(
                            data: card,
                            feedback: Material(
                              elevation: 8,
                              child: Container(
                                width: 80,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      card.name,
                                      style: const TextStyle(fontSize: 10),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      card.type.name,
                                      style: const TextStyle(fontSize: 8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            childWhenDragging: Container(
                              width: 80,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Container(
                              width: 80,
                              height: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    card.name,
                                    style: const TextStyle(fontSize: 10),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    card.type.name,
                                    style: const TextStyle(fontSize: 8),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Text('Error: $error'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSkillIcon(SkillNode node) {
    switch (node.element) {
      case CardElement.fire:
        return Icons.local_fire_department;
      case CardElement.ice:
        return Icons.ac_unit;
      case CardElement.light:
        return Icons.lightbulb;
      case CardElement.arcane:
        return Icons.auto_awesome;
      default:
        return Icons.psychology;
    }
  }
}

class SkillNode {
  final String id;
  final String name;
  final String description;
  final int tier;
  final Offset position;
  final int requiredSkillPoints;
  final CardType cardType;
  final CardElement element;
  final List<String> prerequisites;

  SkillNode({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.position,
    required this.requiredSkillPoints,
    required this.cardType,
    required this.element,
    this.prerequisites = const [],
  });
}

class SkillTreePainter extends CustomPainter {
  final List<SkillNode> nodes;
  final List<SkillNode> unlockedNodes;
  final GameCard? draggedCard;

  SkillTreePainter({
    required this.nodes,
    required this.unlockedNodes,
    this.draggedCard,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw connections between nodes
    for (final node in nodes) {
      for (final prerequisite in node.prerequisites) {
        final prerequisiteNode = nodes.firstWhere((n) => n.id == prerequisite);
        final isUnlocked = unlockedNodes.any((unlocked) => unlocked.id == node.id);
        
        paint.color = isUnlocked ? Colors.green : Colors.grey[400]!;
        
        canvas.drawLine(
          Offset(
            prerequisiteNode.position.dx * 120 + 50,
            prerequisiteNode.position.dy * 120 + 50,
          ),
          Offset(
            node.position.dx * 120 + 50,
            node.position.dy * 120 + 50,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
