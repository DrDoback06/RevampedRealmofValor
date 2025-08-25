import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_of_valor/core/errors.dart';
import 'package:realm_of_valor/core/result.dart';
import 'package:realm_of_valor/data/models/character_model.dart';
import 'package:realm_of_valor/data/models/inventory_model.dart';
import 'package:realm_of_valor/domain/characters/character_repository.dart';
import 'package:realm_of_valor/domain/inventory/inventory_repository.dart';
import 'package:realm_of_valor/services/agents/character_management_agent.dart';
import 'package:realm_of_valor/services/event_bus.dart';

class MemoryCharacterRepo implements CharacterRepository {
  Character? stored;
  @override
  Future<Result<Character, AppError>> load(String uid, String characterId) async {
    return Ok(stored ?? Character(uid: uid, id: characterId, name: 'Hero'));
  }

  @override
  Future<Result<void, AppError>> save(Character character) async {
    stored = character;
    return const Ok(null);
  }
}

class MemoryInventoryRepo implements InventoryRepository {
  @override
  Future<Result<Inventory, AppError>> load(String uid) async {
    return Ok(Inventory(ownerUid: uid));
  }

  @override
  Future<Result<void, AppError>> save(Inventory inventory) async => const Ok(null);
}

void main() {
  test('Character gains XP from fitness update and can level up', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);

    final charRepo = MemoryCharacterRepo();
    final invRepo = MemoryInventoryRepo();
    final agent = CharacterManagementAgent(bus, characterRepo: charRepo, inventoryRepo: invRepo);
    await agent.initialize();

    bus.publish(Event(type: 'character.load', data: {'uid': 'u', 'characterId': 'c'}));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final lvlUp = Completer<Event>();
    bus.subscribe('character_level_up', (e, b) => lvlUp.complete(e));

    // 1000 steps = 10 XP; trigger many updates to pass 100 XP
    for (var i = 0; i < 11; i++) {
      bus.publish(Event(type: 'fitness_update', data: {'steps': 1000}));
    }

    await lvlUp.future.timeout(const Duration(seconds: 2));
  });

  test('equipment_changed emits character_updated', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);

    final charRepo = MemoryCharacterRepo();
    final invRepo = MemoryInventoryRepo();
    final agent = CharacterManagementAgent(bus, characterRepo: charRepo, inventoryRepo: invRepo);
    await agent.initialize();

    bus.publish(Event(type: 'character.load', data: {'uid': 'u', 'characterId': 'c'}));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final updated = Completer<Event>();
    bus.subscribe('character_updated', (e, b) => updated.complete(e));

    bus.publish(Event(type: 'equipment_changed'));

    await updated.future.timeout(const Duration(seconds: 2));
  });
}
