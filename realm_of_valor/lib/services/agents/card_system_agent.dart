import 'dart:math';

import '../../data/models/card_model.dart';
import '../../data/models/inventory_model.dart';
import '../base_agent.dart';
import '../event_bus.dart';

class CardSystemAgent extends BaseAgent {
  CardSystemAgent(super.bus);

  final Map<String, GameCard> _cardDb = <String, GameCard>{};
  final List<CardInstance> _collection = <CardInstance>[];
  final Map<String, String?> _equipmentSlots = <String, String?>{
    'head': null,
    'chest': null,
    'legs': null,
    'weapon': null,
    'offhand': null,
    'ring': null,
    'amulet': null,
  };

  @override
  String get name => 'CardSystem';

  @override
  Future<void> onInitialize() async {
    bus.subscribe('card_db.load', (evt, b) {
      final list = evt.data?['cards'] as List<dynamic>?;
      if (list != null) {
        for (final item in list) {
          final json = Map<String, dynamic>.from(item as Map);
          final card = GameCard.fromJson(json);
          _cardDb[card.id] = card;
        }
      }
    });

    bus.subscribe('card.obtain', (evt, b) => _onObtain(evt));
    bus.subscribe('card.equip', (evt, b) => _onEquip(evt));
    bus.subscribe('card.unequip', (evt, b) => _onUnequip(evt));
    bus.subscribe('card.pack_open', (evt, b) => _onPackOpen(evt));
  }

  @override
  Future<void> onDispose() async {}

  void _onObtain(Event evt) {
    final cardId = evt.data?['cardId'] as String?;
    if (cardId == null || !_cardDb.containsKey(cardId)) return;
    final instance = CardInstance(instanceId: '${cardId}_${_collection.length + 1}', cardId: cardId);
    _collection.add(instance);
    bus.publish(Event(type: 'card_obtained', data: {'instanceId': instance.instanceId, 'cardId': cardId}));
  }

  void _onEquip(Event evt) {
    final instanceId = evt.data?['instanceId'] as String?;
    final slot = evt.data?['slot'] as String?;
    if (instanceId == null || slot == null || !_equipmentSlots.containsKey(slot)) return;
    _equipmentSlots[slot] = instanceId;
    bus.publish(Event(type: 'equipment_changed', data: {'slot': slot, 'instanceId': instanceId}));
  }

  void _onUnequip(Event evt) {
    final slot = evt.data?['slot'] as String?;
    if (slot == null || !_equipmentSlots.containsKey(slot)) return;
    _equipmentSlots[slot] = null;
    bus.publish(Event(type: 'equipment_changed', data: {'slot': slot, 'instanceId': null}));
  }

  void _onPackOpen(Event evt) {
    final count = (evt.data?['count'] as num?)?.toInt() ?? 3;
    final rng = Random(42);
    final cardIds = _cardDb.keys.toList();
    for (var i = 0; i < count; i++) {
      if (cardIds.isEmpty) break;
      final roll = rng.nextInt(cardIds.length);
      bus.publish(Event(type: 'card.obtain', data: {'cardId': cardIds[roll]}));
    }
  }
}