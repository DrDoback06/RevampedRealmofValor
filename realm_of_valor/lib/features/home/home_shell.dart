import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/di.dart';
import '../../services/event_bus.dart';
import '../map/map_screen.dart';
import '../quests/quest_list_screen.dart';
import '../character/character_screen.dart';

class HomeShell extends StatelessWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Character',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scanner',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.group),
            label: 'Social',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events),
            label: 'Achievements',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud),
            label: 'Weather',
          ),
          NavigationDestination(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/map');
              break;
            case 2:
              context.go('/character');
              break;
            case 3:
              context.go('/scan');
              break;
            case 4:
              context.go('/card-collection');
              break;
            case 5:
              context.go('/social');
              break;
            case 6:
              context.go('/achievements');
              break;
            case 7:
              context.go('/weather');
              break;
            case 8:
              context.go('/events');
              break;
            case 9:
              context.go('/notifications');
              break;
          }
        },
        selectedIndex: _getSelectedIndex(context),
      ),
    );
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    
    switch (location) {
      case '/':
        return 0;
      case '/map':
        return 1;
      case '/character':
        return 2;
      case '/scan':
        return 3;
      case '/card-collection':
        return 4;
      case '/social':
        return 5;
      case '/achievements':
        return 6;
      case '/weather':
        return 7;
      case '/events':
        return 8;
      case '/notifications':
        return 9;
      default:
        return 0;
    }
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Welcome to Realm of Valor',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your adventure awaits!',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _QuickActionCard(
                  icon: Icons.fitness_center,
                  label: 'Track Fitness',
                  color: Colors.orange,
                  onTap: () {
                    ref.read(eventBusProvider).publish(Event(
                      type: 'fitness.start_tracking',
                      data: {},
                    ));
                  },
                ),
                _QuickActionCard(
                  icon: Icons.sports_kabaddi,
                  label: 'Start Battle',
                  color: Colors.red,
                  onTap: () {
                    ref.read(eventBusProvider).publish(Event(
                      type: 'battle.start',
                      data: {
                        'player': {'id': 'player', 'hp': 100, 'atk': 10},
                        'enemy': {'id': 'goblin', 'hp': 50, 'atk': 5},
                      },
                    ));
                  },
                ),
                _QuickActionCard(
                  icon: Icons.explore,
                  label: 'Explore Map',
                  color: Colors.green,
                  onTap: () => context.go('${Routes.home}map'),
                ),
                _QuickActionCard(
                  icon: Icons.chat,
                  label: 'AI Companion',
                  color: Colors.blue,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => _CompanionDialog(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Tips Section
            Text(
              'Tips',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('• Complete quests to earn XP and gold'),
                    SizedBox(height: 4),
                    Text('• Track your fitness to gain bonus rewards'),
                    SizedBox(height: 4),
                    Text('• Open card packs to collect powerful equipment'),
                    SizedBox(height: 4),
                    Text('• Battle enemies to progress in your adventure'),
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

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.4),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanionDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CompanionDialog> createState() => _CompanionDialogState();
}

class _CompanionDialogState extends ConsumerState<_CompanionDialog> {
  final _controller = TextEditingController();
  String? _response;
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    
    ref.read(eventBusProvider).publish(Event(
      type: 'companion.ask',
      data: {'question': _controller.text},
    ));
    
    setState(() {
      _response = 'Thinking...';
    });
    
    // Listen for response
    ref.read(eventBusProvider).stream
        .where((e) => e.type == 'companion.reply')
        .first
        .then((event) {
      if (mounted) {
        setState(() {
          _response = event.data?['reply'] ?? 'No response';
        });
      }
    });
    
    _controller.clear();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI Companion'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_response != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_response!),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Ask your companion',
              hintText: 'How do I get stronger?',
            ),
            onSubmitted: (_) => _sendMessage(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: _sendMessage,
          child: const Text('Ask'),
        ),
      ],
    );
  }
}

