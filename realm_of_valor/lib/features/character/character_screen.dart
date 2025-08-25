import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../inventory/providers.dart';
import '../../../data/models/character_model.dart';
import '../../../data/models/inventory_model.dart';
import '../../../data/models/card_model.dart';

class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterAsync = ref.watch(characterStreamProvider);
    final inventoryAsync = ref.watch(inventoryStreamProvider);
    final cardDatabaseAsync = ref.watch(cardDatabaseProvider);
    final characterActions = ref.watch(characterActionsProvider);
    final inventoryActions = ref.watch(inventoryActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Character & Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showCharacterCustomization(context),
          ),
          IconButton(
            icon: const Icon(Icons.psychology),
            onPressed: () => _showSkillTree(context),
          ),
        ],
      ),
      body: characterAsync.when(
        data: (character) {
          if (character == null) {
            return const Center(
              child: Text('No character data'),
            );
          }
          
          return inventoryAsync.when(
            data: (inventory) {
              if (inventory == null) {
                return const Center(
                  child: Text('No inventory data'),
                );
              }
              
              return cardDatabaseAsync.when(
                data: (cardDatabase) {
                  return _buildCharacterContent(
                    context, 
                    character, 
                    inventory, 
                    cardDatabase, 
                    characterActions, 
                    inventoryActions,
                    ref,
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text('Error loading cards: $error'),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Text('Error loading inventory: $error'),
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading character...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterContent(
    BuildContext context, 
    Character character, 
    Inventory inventory, 
    List<GameCard> cardDatabaseList,
    CharacterActions characterActions, 
    InventoryActions inventoryActions,
    WidgetRef ref,
  ) {
    // Convert list to map for easier lookup
    final cardDatabase = <String, GameCard>{};
    for (final card in cardDatabaseList) {
      cardDatabase[card.id] = card;
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Character Header
          _buildCharacterHeader(context, character),
          const SizedBox(height: 24),
          
          // Stats Section
          _buildStatsSection(context, character),
          const SizedBox(height: 24),
          
          // Equipment Section with Drag & Drop
          _buildEquipmentSection(context, character, inventory, cardDatabase, inventoryActions),
          const SizedBox(height: 24),
          
          // Inventory Section with Drag & Drop
          _buildInventorySection(context, inventory, cardDatabase, inventoryActions),
          const SizedBox(height: 24),
          
          // Skills Section
          _buildSkillsSection(context, character, characterActions),
          const SizedBox(height: 24),
          
          // Character Info
          _buildCharacterInfo(context, character),
        ],
      ),
    );
  }

  Widget _buildCharacterHeader(BuildContext context, Character character) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Character Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                character.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Character Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Level ${character.level} Adventurer',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // XP Progress
                  LinearProgressIndicator(
                    value: (character.xp % 100) / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${character.xp % 100}/100 XP to next level',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, Character character) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center),
                const SizedBox(width: 8),
                Text(
                  'Stats',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Strength',
                    character.stats.strength,
                    Icons.fitness_center,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Agility',
                    character.stats.agility,
                    Icons.directions_run,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Intelligence',
                    character.stats.intelligence,
                    Icons.psychology,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Vitality',
                    character.stats.vitality,
                    Icons.favorite,
                    Colors.pink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String name, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection(
    BuildContext context, 
    Character character, 
    Inventory inventory, 
    Map<String, GameCard> cardDatabase,
    InventoryActions inventoryActions,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield),
                const SizedBox(width: 8),
                Text(
                  'Equipment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildEquipmentSlot(context, 'Head', character.equipment.head, Icons.face, inventoryActions),
                _buildEquipmentSlot(context, 'Chest', character.equipment.chest, Icons.person, inventoryActions),
                _buildEquipmentSlot(context, 'Legs', character.equipment.legs, Icons.accessibility, inventoryActions),
                _buildEquipmentSlot(context, 'Weapon', character.equipment.weapon, Icons.sports_kabaddi, inventoryActions),
                _buildEquipmentSlot(context, 'Offhand', character.equipment.offhand, Icons.shield, inventoryActions),
                _buildEquipmentSlot(context, 'Ring', character.equipment.ring, Icons.circle, inventoryActions),
                _buildEquipmentSlot(context, 'Amulet', character.equipment.amulet, Icons.diamond, inventoryActions),
                _buildEquipmentSlot(context, 'Back', null, Icons.backpack, inventoryActions),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentSlot(
    BuildContext context, 
    String name, 
    String? item, 
    IconData icon,
    InventoryActions inventoryActions,
  ) {
    final hasItem = item != null;
    return DragTarget<CardInstance>(
      onWillAccept: (data) => true,
      onAccept: (cardInstance) {
        // Equip the item
        inventoryActions.equipCard('default_character', cardInstance.instanceId, name.toLowerCase());
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            color: hasItem ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: candidateData.isNotEmpty ? Colors.blue : (hasItem ? Colors.green : Colors.grey),
              width: candidateData.isNotEmpty ? 3 : 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: hasItem ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: hasItem ? Colors.green : Colors.grey,
                ),
              ),
              if (hasItem)
                Text(
                  item!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (hasItem)
                GestureDetector(
                  onTap: () => inventoryActions.unequipCard('default_character', name.toLowerCase()),
                  child: const Icon(
                    Icons.remove_circle_outline,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInventorySection(
    BuildContext context, 
    Inventory inventory, 
    Map<String, GameCard> cardDatabase,
    InventoryActions inventoryActions,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory),
                const SizedBox(width: 8),
                Text(
                  'Inventory',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.paid, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${inventory.gold}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Card Pack Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: inventory.gold >= 50
                        ? () => _openCardPack(context, 'basic', inventoryActions)
                        : null,
                    icon: const Icon(Icons.card_giftcard),
                    label: const Text('Basic Pack (50g)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: inventory.gold >= 200
                        ? () => _openCardPack(context, 'premium', inventoryActions)
                        : null,
                    icon: const Icon(Icons.star),
                    label: const Text('Premium Pack (200g)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Inventory Items with Drag & Drop
            if (inventory.items.isEmpty)
              const Center(
                child: Text(
                  'No items in inventory.\nOpen card packs to get started!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                itemCount: inventory.items.length,
                itemBuilder: (context, index) {
                  final cardInstance = inventory.items[index];
                  final card = cardDatabase[cardInstance.cardId];
                  
                  return _buildInventoryCard(
                    context,
                    cardInstance,
                    card,
                    inventoryActions,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(
    BuildContext context,
    CardInstance cardInstance,
    GameCard? card,
    InventoryActions inventoryActions,
  ) {
    if (card == null) return const SizedBox.shrink();
    
    final rarityColor = _getRarityColor(card.rarity);
    
    return Draggable<CardInstance>(
      data: cardInstance,
      feedback: Material(
        elevation: 8,
        child: Container(
          width: 80,
          height: 100,
          decoration: BoxDecoration(
            color: rarityColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: rarityColor, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getCardTypeIcon(card.type),
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 4),
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
            ],
          ),
        ),
      ),
      childWhenDragging: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey, width: 2),
        ),
        child: const Center(
          child: Icon(Icons.remove, color: Colors.grey),
        ),
      ),
      child: GestureDetector(
        onTap: () => _showCardDetails(context, cardInstance, card, inventoryActions),
        child: Container(
          decoration: BoxDecoration(
            color: rarityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: rarityColor, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getCardTypeIcon(card.type),
                color: rarityColor,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                card.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: rarityColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: rarityColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  card.rarity.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (cardInstance.durability != null && cardInstance.durability! < 100)
                Text(
                  'Durability: ${cardInstance.durability}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontSize: 8,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRarityColor(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return Colors.grey;
      case CardRarity.uncommon:
        return Colors.green;
      case CardRarity.rare:
        return Colors.blue;
      case CardRarity.epic:
        return Colors.purple;
      case CardRarity.legendary:
        return Colors.orange;
      case CardRarity.mythic:
        return Colors.red;
    }
  }

  IconData _getCardTypeIcon(CardType type) {
    switch (type) {
      case CardType.equipment:
        return Icons.sports_kabaddi;
      case CardType.spell:
        return Icons.auto_awesome;
      case CardType.consumable:
        return Icons.medical_services;
      case CardType.item:
        return Icons.inventory;
      case CardType.artifact:
        return Icons.diamond;
      case CardType.legendary:
        return Icons.star;
      case CardType.quest:
        return Icons.assignment;
      case CardType.character:
        return Icons.person;
      case CardType.monster:
        return Icons.pets;
      case CardType.event:
        return Icons.event;
      case CardType.location:
        return Icons.location_on;
      case CardType.companion:
        return Icons.favorite;
      case CardType.mount:
        return Icons.directions_run;
      case CardType.pet:
        return Icons.pets;
      case CardType.title:
        return Icons.emoji_events;
      case CardType.emote:
        return Icons.emoji_emotions;
      case CardType.currency:
        return Icons.monetization_on;
      case CardType.material:
        return Icons.build;
      case CardType.recipe:
        return Icons.menu_book;
      case CardType.skill:
        return Icons.psychology;
      default:
        return Icons.star;
    }
  }

  Widget _buildSkillsSection(BuildContext context, Character character, CharacterActions actions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology),
                const SizedBox(width: 8),
                Text(
                  'Skills',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${character.skillPoints} SP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (character.unlockedSkills.isEmpty)
              const Center(
                child: Text(
                  'No skills unlocked yet.\nUse skill points to unlock new abilities!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: character.unlockedSkills.map((skill) {
                  return Chip(
                    avatar: const Icon(Icons.star, size: 16),
                    label: Text(skill),
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: character.skillPoints > 0
                    ? () => _showSkillTree(context)
                    : null,
                icon: const Icon(Icons.psychology),
                label: const Text('Skill Tree'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterInfo(BuildContext context, Character character) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info),
                const SizedBox(width: 8),
                Text(
                  'Character Info',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Character ID', character.id),
            _buildInfoRow('Total XP', character.xp.toString()),
            _buildInfoRow('Skill Points', character.skillPoints.toString()),
            _buildInfoRow('Unlocked Skills', character.unlockedSkills.length.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  void _openCardPack(BuildContext context, String packType, InventoryActions inventoryActions) {
    debugPrint('CharacterScreen: Opening $packType card pack');
    // Show opening animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CardPackOpeningDialog(packType: packType),
    );

    // Open the pack
    debugPrint('CharacterScreen: Publishing card.pack_open event for $packType');
    inventoryActions.openCardPack(packType);
  }

  void _showCardDetails(
    BuildContext context,
    CardInstance cardInstance,
    GameCard card,
    InventoryActions inventoryActions,
  ) {
    debugPrint('CharacterScreen: Showing card details for ${card.name}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getCardTypeIcon(card.type), color: _getRarityColor(card.rarity)),
            const SizedBox(width: 8),
            Expanded(child: Text(card.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${card.type.name}'),
            Text('Rarity: ${card.rarity.name}'),
            if (cardInstance.durability != null)
              Text('Durability: ${cardInstance.durability}%'),
            const SizedBox(height: 16),
            const Text('Card details coming soon!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('CharacterScreen: User closed card details dialog');
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              debugPrint('CharacterScreen: User clicked equip on card ${card.name}');
              Navigator.of(context).pop();
              // TODO: Implement equip logic
            },
            child: const Text('Equip'),
          ),
        ],
      ),
    );
  }

  void _showCharacterCustomization(BuildContext context) {
    debugPrint('CharacterScreen: Showing character customization dialog');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Character Customization'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Character customization coming soon!'),
            SizedBox(height: 16),
            Text('You\'ll be able to:'),
            Text('• Change your character\'s name'),
            Text('• Select different character classes'),
            Text('• Customize appearance'),
            Text('• Choose starting abilities'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('CharacterScreen: User closed character customization dialog');
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSkillTree(BuildContext context) {
    debugPrint('CharacterScreen: Showing skill tree dialog');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skill Tree'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Skill tree system coming soon!'),
            SizedBox(height: 16),
            Text('You\'ll be able to:'),
            Text('• Unlock new abilities'),
            Text('• Choose skill paths'),
            Text('• Specialize in different areas'),
            Text('• Create unique builds'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('CharacterScreen: User closed skill tree dialog');
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _CardPackOpeningDialog extends StatefulWidget {
  final String packType;
  
  const _CardPackOpeningDialog({required this.packType});
  
  @override
  State<_CardPackOpeningDialog> createState() => _CardPackOpeningDialogState();
}

class _CardPackOpeningDialogState extends State<_CardPackOpeningDialog> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 360).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward().then((_) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * 3.14159 / 180,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.withOpacity(0.9),
                      Colors.purple.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.card_giftcard,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Opening ${widget.packType} Pack!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '🎉',
                      style: TextStyle(fontSize: 32),
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
}

