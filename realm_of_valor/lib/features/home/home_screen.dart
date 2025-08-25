import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/providers.dart';
import '../character/providers.dart';
import '../inventory/providers.dart';
import '../quests/providers.dart';
import 'package:flutter/foundation.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<String> _debugLog = [];

  void _logDebug(String message) {
    final timestamp = DateTime.now().toString().split('.')[0];
    final logMessage = '[$timestamp] HomeScreen: $message';
    debugPrint(logMessage);
    setState(() {
      _debugLog.add(logMessage);
      if (_debugLog.length > 20) {
        _debugLog.removeAt(0);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _logDebug('HomeScreen initialized');
  }

  @override
  Widget build(BuildContext context) {
    _logDebug('Building HomeScreen');
    
    final authState = ref.watch(authStateProvider);
    final characterAsync = ref.watch(characterStreamProvider);
    final inventoryAsync = ref.watch(inventoryStreamProvider);
    final questsAsync = ref.watch(questsStreamProvider);

    _logDebug('Auth state: ${authState.value?.uid ?? 'null'}');
    _logDebug('Character loaded: ${characterAsync.hasValue}');
    _logDebug('Inventory loaded: ${inventoryAsync.hasValue}');
    _logDebug('Quests loaded: ${questsAsync.hasValue}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Realm of Valor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _logDebug('User logging out');
              ref.read(authActionsProvider).signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Debug Panel
          if (_debugLog.isNotEmpty)
            Container(
              height: 150,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Home Debug Log',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _debugLog.clear();
                          });
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _debugLog.length,
                      itemBuilder: (context, index) {
                        return Text(
                          _debugLog[index],
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${authState.value?.email ?? 'Adventurer'}!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  
                  // Character Stats
                  characterAsync.when(
                    data: (character) {
                      _logDebug('Displaying character: ${character?.name ?? 'Unknown'}');
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Character: ${character?.name ?? 'Unknown'}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text('Level: ${character?.level ?? 1}'),
                              Text('XP: ${character?.xp ?? 0}'),
                              Text('Strength: ${character?.stats.strength ?? 5}'),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () {
                      _logDebug('Character loading...');
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    error: (error, stack) {
                      _logDebug('Character error: $error');
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Error loading character: $error'),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _logDebug('Navigating to map');
                            context.go('/map');
                          },
                          icon: const Icon(Icons.map),
                          label: const Text('Adventure Map'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _logDebug('Navigating to quests');
                            context.go('/quests');
                          },
                          icon: const Icon(Icons.assignment),
                          label: const Text('Quests'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _logDebug('Navigating to character');
                            context.go('/character');
                          },
                          icon: const Icon(Icons.person),
                          label: const Text('Character'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _logDebug('Opening card pack');
                            _openCardPack();
                          },
                          icon: const Icon(Icons.card_giftcard),
                          label: const Text('Open Pack'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Recent Activity
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  
                  questsAsync.when(
                    data: (quests) {
                      _logDebug('Displaying ${quests.length} quests');
                      return Expanded(
                        child: ListView.builder(
                          itemCount: quests.take(3).length,
                          itemBuilder: (context, index) {
                            final quest = quests[index];
                            return ListTile(
                              title: Text(quest.title),
                              subtitle: Text(quest.description),
                              trailing: Text('${quest.type.name}'),
                            );
                          },
                        ),
                      );
                    },
                    loading: () {
                      _logDebug('Quests loading...');
                      return const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    error: (error, stack) {
                      _logDebug('Quests error: $error');
                      return Expanded(
                        child: Center(child: Text('Error loading quests: $error')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCardPack() {
    _logDebug('Opening basic card pack from home screen');
    ref.read(inventoryActionsProvider).openCardPack('basic');
  }
}
