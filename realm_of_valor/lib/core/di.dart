import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/firebase_service.dart';
import '../domain/cards/card_repository.dart';
import '../domain/characters/character_repository.dart';
import '../domain/inventory/inventory_repository.dart';
import '../domain/quests/quest_repository.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService(ref.watch(firestoreProvider));
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