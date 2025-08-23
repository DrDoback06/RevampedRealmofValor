import 'dart:async';

import '../../data/models/character_model.dart';
import '../../data/models/inventory_model.dart';
import '../../domain/characters/character_repository.dart';
import '../../domain/inventory/inventory_repository.dart';
import '../base_agent.dart';
import '../event_bus.dart';

class CharacterManagementAgent extends BaseAgent {
  CharacterManagementAgent(super.bus, {required this.characterRepo, required this.inventoryRepo});

  final CharacterRepository characterRepo;
  final InventoryRepository inventoryRepo;

  Character? _active;
  Inventory? _inventory;

  @override
  String get name => 'CharacterManagement';

  @override
  Future<void> onInitialize() async {
    bus.subscribe('character.load', _onLoad);
    bus.subscribe('fitness_update', _onFitnessUpdate);
    bus.subscribe('battle_result', _onBattleResult);
    bus.subscribe('equipment_changed', _onEquipmentChanged);
  }

  @override
  Future<void> onDispose() async {}

  Future<void> _onLoad(Event evt, EventBus b) async {
    final uid = evt.data?['uid'] as String?;
    final characterId = evt.data?['characterId'] as String?;
    if (uid == null || characterId == null) return;

    final c = await characterRepo.load(uid, characterId);
    await c.when(
      ok: (value) async {
        _active = value;
        final inv = await inventoryRepo.load(uid);
        inv.when(
          ok: (i) => _inventory = i,
          err: (_) => _inventory = Inventory(ownerUid: uid),
        );
        _emitUpdated();
      },
      err: (e) async {
        b.publish(Event(type: 'ui.notify', data: {'level': 'error', 'message': e.message}));
      },
    );
  }

  void _onFitnessUpdate(Event evt, EventBus b) {
    final steps = (evt.data?['steps'] as num?)?.toInt() ?? 0;
    if (_active == null || steps <= 0) return;
    _grantXp((steps ~/ 1000) * 10); // 1000 steps => 10 XP
  }

  void _onBattleResult(Event evt, EventBus b) {
    if (_active == null) return;
    final win = evt.data?['win'] == true;
    final xp = (evt.data?['xp'] as num?)?.toInt() ?? (win ? 50 : 10);
    _grantXp(xp);
  }

  void _onEquipmentChanged(Event evt, EventBus b) {
    if (_active == null || _inventory == null) return;
    // In a full impl, recompute from inventory items equipped.
    _emitUpdated();
  }

  void _grantXp(int amount) {
    if (_active == null || amount <= 0) return;
    final current = _active!;
    var xp = current.xp + amount;
    var level = current.level;
    var stats = current.stats;
    while (xp >= _xpToNext(level)) {
      xp -= _xpToNext(level);
      level += 1;
      stats = CharacterStats(
        strength: stats.strength + 1,
        agility: stats.agility + 1,
        intelligence: stats.intelligence + 1,
        vitality: stats.vitality + 1,
      );
      bus.publish(Event(type: 'character_level_up', data: {'level': level}));
    }
    _active = Character(
      uid: current.uid,
      id: current.id,
      name: current.name,
      level: level,
      xp: xp,
      stats: stats,
      equipment: current.equipment,
    );
    _persist();
    _emitUpdated();
  }

  int _xpToNext(int level) => 100 + (level - 1) * 50;

  void _emitUpdated() {
    final c = _active;
    if (c == null) return;
    bus.publish(Event(type: 'character_updated', data: {
      'uid': c.uid,
      'id': c.id,
      'level': c.level,
      'xp': c.xp,
      'stats': {
        'str': c.stats.strength,
        'agi': c.stats.agility,
        'int': c.stats.intelligence,
        'vit': c.stats.vitality,
      }
    }));
  }

  Future<void> _persist() async {
    final c = _active;
    if (c == null) return;
    await characterRepo.save(c);
    bus.publish(Event(type: 'data.save', data: {'entity': 'character', 'id': c.id}));
  }
}