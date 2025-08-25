import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryStreamProvider);
    final cardsAsync = ref.watch(cardDatabaseProvider);
    final actions = ref.watch(inventoryActionsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
      ),
      body: inventoryAsync.when(
        data: (inventory) {
          if (inventory == null) {
            return const Center(
              child: Text('No inventory data'),
            );
          }
          
          return CustomScrollView(
            slivers: [
              // Currency Header
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Currency',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.paid, color: Colors.amber, size: 32),
                                const SizedBox(height: 4),
                                Text(
                                  inventory.gold.toString(),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Text(
                                  'Gold',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Card Pack Opening Section
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Card Packs',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: inventory.gold >= 100
                                    ? () => actions.openCardPack('basic')
                                    : null,
                                icon: const Icon(Icons.paid),
                                label: const Text('Basic Pack (100 Gold)'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: inventory.gold >= 1000
                                    ? () => actions.openCardPack('premium')
                                    : null,
                                icon: const Icon(Icons.diamond),
                                label: const Text('Premium Pack (1000 Gold)'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Cards Grid
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (inventory.items.isEmpty) {
                        if (index == 0) {
                          return const Card(
                            child: Center(
                              child: Text(
                                'No cards yet\n\nOpen packs to get cards!',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        return null;
                      }
                      
                      if (index >= inventory.items.length) return null;
                      
                      final item = inventory.items[index];
                      
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            // Show card details
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Card #${item.cardId}'),
                                content: const Text('Card details would appear here'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.style, size: 48),
                              const SizedBox(height: 8),
                              Text(
                                'Card #${item.cardId}',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: inventory.items.isEmpty ? 1 : inventory.items.length,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

