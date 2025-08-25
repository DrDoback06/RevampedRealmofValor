import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/firebase_service.dart';
import '../data/sources/mock_firebase_service.dart';
import '../data/sources/local_store.dart';
import '../domain/cards/card_repository.dart';
import '../domain/characters/character_repository.dart';
import '../domain/inventory/inventory_repository.dart';
import '../domain/quests/quest_repository.dart';
import '../integration/fitness_service.dart';
import '../integration/weather_service.dart';
import '../services/event_bus.dart';
import '../services/integration_orchestrator_agent.dart';
import '../services/agents/character_management_agent.dart';
import '../services/agents/data_persistence_agent.dart';
import '../services/agents/fitness_tracking_agent.dart';
import '../services/agents/battle_system_agent.dart';
import '../services/agents/achievement_agent.dart';
import '../services/agents/card_system_agent.dart';
import '../services/agents/inventory_agent.dart';
import '../services/agents/adventure_quest_agent.dart';
import '../services/agents/location_services_agent.dart';
import '../services/agents/ui_ux_agent.dart';
import '../services/agents/weather_integration_agent.dart';
import '../services/agents/audio_agent.dart';
import '../services/agents/ai_companion_agent.dart';
import '../data/models/achievement_model.dart';
import '../data/models/card_model.dart';
import '../data/models/character_model.dart';
import '../data/models/inventory_model.dart';
import '../data/models/quest_model.dart';
import '../core/errors.dart';
import '../core/result.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final localStoreProvider = FutureProvider<LocalStore>((ref) async {
  return LocalStore.create();
});

final fitnessServiceProvider = Provider<FitnessService>((ref) {
  return StubFitnessService();
});

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return StubWeatherService();
});

final eventBusProvider = Provider<EventBus>((ref) {
  final bus = EventBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final orchestratorProvider = Provider<IntegrationOrchestratorAgent>((ref) {
  final bus = ref.watch(eventBusProvider);
  final orchestrator = IntegrationOrchestratorAgent(bus);

  final local = ref.read(localStoreProvider).maybeWhen(data: (v) => v, orElse: () => null);
  if (local != null) {
    orchestrator.registerAgent(AgentDescriptor(
      name: 'DataPersistence',
      factory: (b) => DataPersistenceAgent(b, firebase: ref.read(firebaseServiceProvider), local: local),
      essential: true,
    ));
  }

  orchestrator.registerAgent(AgentDescriptor(
    name: 'CharacterManagement',
    factory: (b) => CharacterManagementAgent(
      b,
      characterRepo: ref.read(characterRepositoryProvider),
      inventoryRepo: ref.read(inventoryRepositoryProvider),
    ),
    essential: true,
  ));

  orchestrator.registerAgent(AgentDescriptor(
    name: 'FitnessTracking',
    factory: (b) => FitnessTrackingAgent(b, service: ref.read(fitnessServiceProvider)),
    essential: false,
  ));

  orchestrator.registerAgent(AgentDescriptor(
    name: 'BattleSystem',
    factory: (b) => BattleSystemAgent(b),
    essential: false,
  ));

  orchestrator.registerAgent(AgentDescriptor(
    name: 'Achievement',
    factory: (b) => AchievementAgent(b, achievements: [
      Achievement(
        id: 'first_win',
        name: 'First Victory',
        description: 'Win your first battle',
        category: AchievementCategory.battle,
        rarity: AchievementRarity.common,
        icon: '⚔️',
        points: 10,
        requirements: {'battle_ended': 1},
      ),
      Achievement(
        id: 'step_starter',
        name: 'Step Starter',
        description: 'Reach your first fitness goal',
        category: AchievementCategory.fitness,
        rarity: AchievementRarity.common,
        icon: '👟',
        points: 5,
        requirements: {'fitness_goal_reached': 1},
      ),
    ]),
    essential: false,
  ));

  orchestrator.registerAgent(AgentDescriptor(
    name: 'CardSystem',
    factory: (b) => CardSystemAgent(b),
    essential: false,
  ));

  orchestrator.registerAgent(AgentDescriptor(
    name: 'Inventory',
    factory: (b) => InventoryAgent(b, inventoryRepo: ref.read(inventoryRepositoryProvider)),
    essential: false,
  ));

  orchestrator.registerAgent(AgentDescriptor(
    name: 'AdventureQuest',
    factory: (b) => AdventureQuestAgent(b),
    essential: false,
  ));

  orchestrator.registerAgent(AgentDescriptor(
    name: 'LocationServices',
    factory: (b) => LocationServicesAgent(b, updateInterval: const Duration(milliseconds: 100)),
    essential: false,
  ));

  orchestrator.registerAgent(AgentDescriptor(
    name: 'UIUX',
    factory: (b) => UIUXAgent(b),
    essential: false,
  ));

  orchestrator.registerAgent(AgentDescriptor(
    name: 'WeatherIntegration',
    factory: (b) => WeatherIntegrationAgent(b, service: ref.read(weatherServiceProvider)),
    essential: false,
  ));

  orchestrator.registerAgent(AgentDescriptor(
    name: 'Audio',
    factory: (b) => AudioAgent(b),
    essential: false,
  ));

  orchestrator.registerAgent(AgentDescriptor(
    name: 'AICompanion',
    factory: (b) => AICompanionAgent(b),
    essential: false,
  ));

  return orchestrator;
});

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return FirebaseCardRepository(ref.watch(firebaseServiceProvider));
});

final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  return FirebaseCharacterRepository(ref.watch(firebaseServiceProvider));
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return FirebaseInventoryRepository(ref.watch(firebaseServiceProvider));
});

final questRepositoryProvider = Provider<QuestRepository>((ref) {
  return FirebaseQuestRepository(ref.watch(firebaseServiceProvider));
});
