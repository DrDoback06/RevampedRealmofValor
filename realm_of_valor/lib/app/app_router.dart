import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../features/auth/gate.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_shell.dart';
import '../features/map/map_screen.dart';
import '../features/quests/quest_detail_screen.dart';
import '../features/quests/quest_list_screen.dart';
import '../features/character/character_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/scanner/scan_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.home,
        name: RouteNames.home,
        builder: (context, state) => const Gate(),
        routes: [
          GoRoute(
            path: 'scan',
            name: RouteNames.scan,
            builder: (context, state) => const ScanScreen(),
          ),
          GoRoute(
            path: 'quests',
            name: RouteNames.quests,
            builder: (context, state) => const QuestListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: RouteNames.questDetail,
                builder: (context, state) => QuestDetailScreen(
                  questId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'character',
            name: RouteNames.character,
            builder: (context, state) => const CharacterScreen(),
          ),
          GoRoute(
            path: 'inventory',
            name: RouteNames.inventory,
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: 'map',
            name: RouteNames.map,
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: 'settings',
            name: RouteNames.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.shell,
        name: RouteNames.shell,
        builder: (context, state) => const HomeShell(),
      ),
    ],
  );
});
