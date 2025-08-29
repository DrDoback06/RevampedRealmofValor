import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di.dart';
import '../../data/models/character_model.dart';
import '../../services/event_bus.dart';
import '../auth/providers.dart';

/// Provides the current user's character
final characterStreamProvider = StreamProvider<Character?>((ref) async* {
  final characterRepo = ref.watch(characterRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.value?.uid == null) {
    yield null;
    return;
  }

  // Yield a default character immediately
  yield _createDefaultCharacter(authState.value!.uid);
  
  // Listen for character updates from event bus
  final eventBus = ref.watch(eventBusProvider);
  await for (final event in eventBus.stream) {
    if (event.type == 'character_updated' && event.data?['character'] != null) {
      yield Character.fromJson(event.data!['character'] as Map<String, dynamic>);
    } else if (event.type == 'character.add_xp') {
      // Handle XP addition
      final currentCharacter = _createDefaultCharacter(authState.value!.uid);
      final xpToAdd = event.data?['xp'] as int? ?? 0;
      final updatedCharacter = Character(
        uid: currentCharacter.uid,
        id: currentCharacter.id,
        name: currentCharacter.name,
        level: currentCharacter.level,
        xp: currentCharacter.xp + xpToAdd,
        stats: currentCharacter.stats,
        equipment: currentCharacter.equipment,
        skillPoints: currentCharacter.skillPoints,
        unlockedSkills: currentCharacter.unlockedSkills,
      );
      yield updatedCharacter;
    } else if (event.type == 'character.add_skill_points') {
      // Handle skill points addition
      final currentCharacter = _createDefaultCharacter(authState.value!.uid);
      final skillPointsToAdd = event.data?['skillPoints'] as int? ?? 0;
      final updatedCharacter = Character(
        uid: currentCharacter.uid,
        id: currentCharacter.id,
        name: currentCharacter.name,
        level: currentCharacter.level,
        xp: currentCharacter.xp,
        stats: currentCharacter.stats,
        equipment: currentCharacter.equipment,
        skillPoints: currentCharacter.skillPoints + skillPointsToAdd,
        unlockedSkills: currentCharacter.unlockedSkills,
      );
      yield updatedCharacter;
    }
  }
});

Character _createDefaultCharacter(String uid) {
  return Character(
    uid: uid,
    id: 'default_character',
    name: 'Adventurer',
    level: 1,
    xp: 0,
    stats: const CharacterStats(
      strength: 10,
      agility: 10,
      intelligence: 10,
      vitality: 10,
    ),
    equipment: const EquipmentSlots(
      head: null,
      chest: null,
      legs: null,
      weapon: null,
      offhand: null,
      ring: null,
      amulet: null,
    ),
    skillPoints: 5,
    unlockedSkills: ['basic_attack'],
  );
}

/// Actions for character management
final characterActionsProvider = Provider((ref) {
  final eventBus = ref.watch(eventBusProvider);
  return CharacterActions(eventBus);
});

class CharacterActions {
  final EventBus _eventBus;
  CharacterActions(this._eventBus);

  void levelUpCharacter(String characterId) {
    _eventBus.publish(Event(
      type: 'character.level_up',
      data: {'characterId': characterId},
    ));
  }

  void addSkillPoint(String characterId, String skillName) {
    _eventBus.publish(Event(
      type: 'character.add_skill_point',
      data: {'characterId': characterId, 'skillName': skillName},
    ));
  }
}