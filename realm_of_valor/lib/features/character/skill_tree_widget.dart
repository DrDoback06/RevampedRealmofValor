import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/character_model.dart';
import '../../../data/models/card_model.dart';
import '../../../data/models/inventory_model.dart';
import '../inventory/providers.dart';
import 'providers.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeSkillTree();
  }

  void _initializeSkillTree() {
    // Define skill tree structure
    _skillNodes.addAll([
      // Tier 1 - Basic Skills
      SkillNode(
        id: 'basic_attack',
        name: 'Basic Attack',
        description: 'A fundamental attack skill',
        tier: 1,
        position: const Offset(0, 0),
        requiredSkillPoints: 1,
        cardType: CardType.spell,
        element: CardElement.none,
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
      ),

      // Tier 2 - Intermediate Skills
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
      ),

      // Tier 3 - Advanced Skills
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

  void _unlockSkill(SkillNode node, GameCard card) {
    if (!_canUnlockSkill(node)) return;

    setState(() {
      _unlockedNodes.add(node);
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

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryStreamProvider);
    final characterAsync = ref.watch(characterStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Tree'),
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Skill points display
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple[100],
            child: Row(
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
          ),

          // Skill tree visualization
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: CustomPaint(
                size: Size.infinite,
                painter: SkillTreePainter(
                  nodes: _skillNodes,
                  unlockedNodes: _unlockedNodes,
                  draggedCard: _draggedCard,
                ),
                child: Stack(
                  children: _skillNodes.map((node) {
                    final isUnlocked = _unlockedNodes.any((unlocked) => unlocked.id == node.id);
                    final canUnlock = _canUnlockSkill(node);
                    final isDraggingValid = _draggedCard != null && _canDragCardToNode(_draggedCard!, node);

                    return Positioned(
                      left: node.position.dx * 120,
                      top: node.position.dy * 120,
                      child: DragTarget<GameCard>(
                        onWillAccept: (card) => card != null && _canDragCardToNode(card, node),
                        onAccept: (card) => _unlockSkill(node, card),
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            width: 100,
                            height: 100,
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