import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/firebase_service.dart';
import '../data/sources/local_store.dart';
import '../domain/cards/card_repository.dart';
import '../domain/characters/character_repository.dart';
import '../domain/inventory/inventory_repository.dart';
import '../domain/quests/quest_repository.dart';
import '../integration/fitness_service.dart';
import '../services/event_bus.dart';
import '../services/integration_orchestrator_agent.dart';
import '../services/agents/character_management_agent.dart';
import '../services/agents/data_persistence_agent.dart';
import '../services/agents/fitness_tracking_agent.dart';
import '../services/agents/battle_system_agent.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService(ref.watch(firestoreProvider));
});

final localStoreProvider = FutureProvider<LocalStore>((ref) async {
  return LocalStore.create();
});

final fitnessServiceProvider = Provider<FitnessService>((ref) {
  return StubFitnessService();
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