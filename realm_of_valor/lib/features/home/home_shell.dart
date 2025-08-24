import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  void _onTap(int idx) {
    setState(() => _index = idx);
    switch (idx) {
      case 0:
        context.go('${Routes.home}map');
        break;
      case 1:
        context.go('${Routes.home}quests');
        break;
      case 2:
        context.go('${Routes.home}character');
        break;
      case 3:
        context.go('${Routes.home}inventory');
        break;
      case 4:
        context.go('${Routes.home}settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const _ShellPlaceholder(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('${Routes.home}scan'),
        child: const Icon(Icons.qr_code_scanner),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Quests'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), label: 'Character'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

class _ShellPlaceholder extends StatelessWidget {
  const _ShellPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Select a tab'),
    );
  }
}
