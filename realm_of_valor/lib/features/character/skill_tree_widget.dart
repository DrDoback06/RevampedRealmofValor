import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Tree'),
        actions: [
          IconButton(
            icon: Icon(_showConnections ? Icons.link : Icons.link_off),
            onPressed: () => setState(() => _showConnections = !_showConnections),
          ),
          IconButton(
            icon: Icon(_showTooltips ? Icons.info : Icons.info_outline),
            onPressed: () => setState(() => _showTooltips = !_showTooltips),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildControls(),
          Expanded(
            child: _buildSkillTree(),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search skills...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 8),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedSpecialization == null,
                  onSelected: (selected) => setState(() => _selectedSpecialization = null),
                ),
                const SizedBox(width: 8),
                ...SkillSpecialization.values.map((spec) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(spec.name),
                    selected: _selectedSpecialization == spec,
                    onSelected: (selected) => setState(() => _selectedSpecialization = selected ? spec : null),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillTree() {
    final filteredNodes = _skillNodes.where((node) {
      if (_searchQuery.isNotEmpty) {
        if (!node.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
            !node.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      if (_selectedSpecialization != null) {
        if (node.specialization != _selectedSpecialization) {
          return false;
        }
      }
      if (_showUnlockedOnly) {
        if (!node.isUnlocked) {
          return false;
        }
      }
      return true;
    }).toList();

    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(100),
      minScale: 0.5,
      maxScale: 2.0,
      child: CustomPaint(
        painter: SkillTreePainter(
          nodes: filteredNodes,
          showConnections: _showConnections,
          hoveredNode: _hoveredNode,
        ),
        child: Stack(
          children: filteredNodes.map((node) => _buildSkillNode(node)).toList(),
        ),
      ),
    );
  }

  Widget _buildSkillNode(SkillNode node) {
    final isUnlocked = node.isUnlocked;
    final isHovered = _hoveredNode == node;
    
    return Positioned(
      left: node.position.dx * 120,
      top: node.position.dy * 120,
      child: GestureDetector(
        onTap: () => _showSkillDetails(node),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getNodeColor(node),
            border: Border.all(
              color: isHovered ? Colors.white : Colors.grey,
              width: isHovered ? 3 : 1,
            ),
            boxShadow: isHovered ? [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getNodeIcon(node),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isUnlocked) ...[
                const SizedBox(height: 2),
                Text(
                  'Lv.${node.masteryLevel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getNodeColor(SkillNode node) {
    if (!node.isUnlocked) {
      return Colors.grey;
    }
    
    switch (node.specialization) {
      case SkillSpecialization.combat:
        return Colors.red;
      case SkillSpecialization.magic:
        return Colors.blue;
      case SkillSpecialization.support:
        return Colors.green;
      case SkillSpecialization.hybrid:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getNodeIcon(SkillNode node) {
    switch (node.specialization) {
      case SkillSpecialization.combat:
        return Icons.gps_fixed;
      case SkillSpecialization.magic:
        return Icons.auto_awesome;
      case SkillSpecialization.support:
        return Icons.healing;
      case SkillSpecialization.hybrid:
        return Icons.psychology;
      default:
        return Icons.star;
    }
  }

  void _showSkillDetails(SkillNode node) {
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
            Text('Specialization: ${node.specialization?.name ?? 'None'}'),
            Text('Element: ${node.element.name}'),
            if (node.isUnlocked) ...[
              Text('Mastery Level: ${node.masteryLevel}/${node.maxMasteryLevel}'),
              Text('Progress: ${node.masteryProgress.toStringAsFixed(1)}%'),
            ],
            if (node.prerequisites.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Prerequisites:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...node.prerequisites.map((prereq) => Text('• $prereq')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!node.isUnlocked && widget.character.skillPoints >= node.requiredSkillPoints)
            ElevatedButton(
              onPressed: () {
                _unlockSkill(node);
                Navigator.of(context).pop();
              },
              child: const Text('Unlock'),
            ),
        ],
      ),
    );
  }

  void _unlockSkill(SkillNode node) {
    // TODO: Implement skill unlocking logic
    setState(() {
      // This would need to be implemented with proper state management
    });
  }
}

class SkillTreePainter extends CustomPainter {
  final List<SkillNode> nodes;
  final bool showConnections;
  final SkillNode? hoveredNode;

  SkillTreePainter({
    required this.nodes,
    required this.showConnections,
    this.hoveredNode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showConnections) return;

    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw connections between nodes (simplified)
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final node1 = nodes[i];
        final node2 = nodes[j];
        
        // Simple connection logic - connect nodes in same tier or adjacent tiers
        if ((node1.tier == node2.tier && (node1.position.dx - node2.position.dx).abs() == 1) ||
            (node1.tier == node2.tier - 1 && node1.position.dx == node2.position.dx)) {
          final start = Offset(
            node1.position.dx * 120 + 50,
            node1.position.dy * 120 + 50,
          );
          final end = Offset(
            node2.position.dx * 120 + 50,
            node2.position.dy * 120 + 50,
          );
          canvas.drawLine(start, end, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
