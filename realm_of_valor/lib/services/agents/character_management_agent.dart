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

  final Map<String, Character> _characters = <String, Character>{};
  String? _activeId;
  Inventory? _inventory;

  @override
  String get name => 'CharacterManagement';

  @override
  Future<void> onInitialize() async {
    bus.subscribe('character.load', _onLoad);
    bus.subscribe('character.switch', _onSwitch);
    bus.subscribe('fitness.update', _onFitnessUpdate);
    bus.subscribe('battle.result', _onBattleResult);
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
        _characters[value.id] = value;
        _activeId ??= value.id;
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

  void _onSwitch(Event evt, EventBus b) {
    final id = evt.data?['characterId'] as String?;
    if (id != null && _characters.containsKey(id)) {
      _activeId = id;
      _emitUpdated();
    }
  }

  void _onFitnessUpdate(Event evt, EventBus b) {
    final steps = (evt.data?['steps'] as num?)?.toInt() ?? 0;
    if (_active == null || steps <= 0) return;
    _grantXp((steps ~/ 1000) * 10);
  }

  void _onBattleResult(Event evt, EventBus b) {
    if (_active == null) return;
    final win = evt.data?['win'] == true;
    final xp = (evt.data?['xp'] as num?)?.toInt() ?? (win ? 50 : 10);
    _grantXp(xp);
  }

  void _onEquipmentChanged(Event evt, EventBus b) {
    if (_active == null || _inventory == null) return;
    _emitUpdated();
  }

  Character? get _active => _activeId == null ? null : _characters[_activeId!];

  void _grantXp(int amount) {
    if (_active == null || amount <= 0) return;
    final current = _active!;
    var xp = current.xp + amount;
    var level = current.level;
    var stats = current.stats;
    var skillPoints = current.skillPoints;
    while (xp >= _xpToNext(level)) {
      xp -= _xpToNext(level);
      level += 1;
      skillPoints += 1;
      stats = CharacterStats(
        strength: stats.strength + 1,
        agility: stats.agility + 1,
        intelligence: stats.intelligence + 1,
        vitality: stats.vitality + 1,
      );
      bus.publish(Event(type: 'character.level_up', data: {'level': level}));
    }
    final updated = Character(
      uid: current.uid,
      id: current.id,
      name: current.name,
      level: level,
      xp: xp,
      stats: stats,
      equipment: current.equipment,
      skillPoints: skillPoints,
      unlockedSkills: current.unlockedSkills,
    );
    _characters[current.id] = updated;
    _persist();
    _emitUpdated();
  }

  int _xpToNext(int level) => 100 + (level - 1) * 50;

  Map<String, num> _aggregateEquipmentStats() {
    final inv = _inventory;
    final c = _active;
    if (inv == null || c == null) return <String, num>{};
    final slotToInstance = <String, String?>{
      'head': c.equipment.head,
      'chest': c.equipment.chest,
      'legs': c.equipment.legs,
      'weapon': c.equipment.weapon,
      'offhand': c.equipment.offhand,
      'ring': c.equipment.ring,
      'amulet': c.equipment.amulet,
    };
    final stats = <String, num>{};
    for (final inst in inv.items) {
      if (slotToInstance.containsValue(inst.instanceId)) {
        final cardStats = inst.upgrades ?? const <String, num>{};
        for (final entry in cardStats.entries) {
          stats.update(entry.key, (v) => v + entry.value, ifAbsent: () => entry.value);
        }
      }
    }
    return stats;
  }

  Map<String, int> _derivedStats() {
    final c = _active;
    if (c == null) return <String, int>{};
    final equipment = _aggregateEquipmentStats();
    final str = c.stats.strength + (equipment['str']?.toInt() ?? 0);
    final agi = c.stats.agility + (equipment['agi']?.toInt() ?? 0);
    final vit = c.stats.vitality + (equipment['vit']?.toInt() ?? 0);
    final atk = str * 2 + (equipment['atk']?.toInt() ?? 0);
    final def = (vit + agi) + (equipment['def']?.toInt() ?? 0);
    final hp = vit * 20 + (equipment['hp']?.toInt() ?? 0);
    return <String, int>{'atk': atk, 'def': def, 'hp': hp};
  }

  void _emitUpdated() {
    final c = _active;
    if (c == null) return;
    final derived = _derivedStats();
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
      },
      'derived': derived,
      'skill_points': c.skillPoints,
    }));
  }

  Future<void> _persist() async {
    final c = _active;
    if (c == null) return;
    await characterRepo.save(c);
    bus.publish(Event(type: 'data.save', data: {'entity': 'character', 'id': c.id, 'payload': c.toJson()}));
  }
}
