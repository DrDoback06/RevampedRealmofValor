import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_screen.dart' as home;
import '../features/home/home_shell.dart';
import '../features/map/map_screen.dart';
import '../features/quests/quest_list_screen.dart';
import '../features/character/character_screen.dart';
import '../features/scanner/scan_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/battle/battle_screen.dart';
import '../features/battle_companion/battle_companion_screen.dart';
import '../features/social/social_screen.dart';
import '../features/card_collection/card_collection_screen.dart';
import '../features/achievements/achievements_screen.dart';
import '../features/weather/weather_screen.dart';
import '../features/events/events_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/auth/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const home.HomeScreen(),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/quests',
            builder: (context, state) => const QuestListScreen(),
          ),
          GoRoute(
            path: '/character',
            builder: (context, state) => const CharacterScreen(),
          ),
          GoRoute(
            path: '/scan',
            builder: (context, state) => const ScanScreen(),
          ),
          GoRoute(
            path: '/battle-companion',
            builder: (context, state) => const BattleCompanionScreen(),
          ),
          GoRoute(
            path: '/social',
            builder: (context, state) => const SocialScreen(),
          ),
          GoRoute(
            path: '/card-collection',
            builder: (context, state) => const CardCollectionScreen(),
          ),
          GoRoute(
            path: '/achievements',
            builder: (context, state) => const AchievementsScreen(),
          ),
          GoRoute(
            path: '/weather',
            builder: (context, state) => const WeatherScreen(),
          ),
          GoRoute(
            path: '/events',
            builder: (context, state) => const EventsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/battle',
            builder: (context, state) {
              final params = state.uri.queryParameters;
              return BattleScreen(
                enemyId: params['enemyId'] ?? '',
                enemyName: params['enemyName'] ?? 'Unknown Enemy',
                enemyLevel: int.tryParse(params['enemyLevel'] ?? '1') ?? 1,
                enemyHp: int.tryParse(params['enemyHp'] ?? '100') ?? 100,
                enemyAtk: int.tryParse(params['enemyAtk'] ?? '20') ?? 20,
                enemyDef: int.tryParse(params['enemyDef'] ?? '5') ?? 5,
              );
            },
          ),
        ],
      ),
    ],
  );
});

