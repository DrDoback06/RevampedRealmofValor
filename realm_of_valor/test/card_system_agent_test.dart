import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_of_valor/data/models/card_model.dart';
import 'package:realm_of_valor/services/agents/card_system_agent.dart';
import 'package:realm_of_valor/services/event_bus.dart';

void main() {
  test('Obtain and equip card triggers equipment_changed', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);
    final agent = CardSystemAgent(bus);
    await agent.initialize();

    final sword = GameCard(id: 'sword_1', name: 'Iron Sword', type: CardType.weapon, rarity: CardRarity.common);
    bus.publish(Event(type: 'card_db.load', data: {
      'cards': [sword.toJson()],
    }));

    final obtained = Completer<Event>();
    bus.subscribe('card_obtained', (e, b) => obtained.complete(e));
    bus.publish(Event(type: 'card.obtain', data: {'cardId': 'sword_1'}));

    final got = await obtained.future.timeout(const Duration(seconds: 2));
    final instanceId = got.data?['instanceId'] as String;

    final equipped = Completer<Event>();
    bus.subscribe('equipment_changed', (e, b) => equipped.complete(e));
    bus.publish(Event(type: 'card.equip', data: {'slot': 'weapon', 'instanceId': instanceId}));

    final eq = await equipped.future.timeout(const Duration(seconds: 2));
    expect(eq.data?['slot'], 'weapon');
  });

  test('Pack opening yields cards', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);
    final agent = CardSystemAgent(bus);
    await agent.initialize();

    final cards = [
      GameCard(id: 'c1', name: 'A', type: CardType.misc, rarity: CardRarity.common).toJson(),
      GameCard(id: 'c2', name: 'B', type: CardType.misc, rarity: CardRarity.common).toJson(),
      GameCard(id: 'c3', name: 'C', type: CardType.misc, rarity: CardRarity.common).toJson(),
    ];
    bus.publish(Event(type: 'card_db.load', data: {'cards': cards}));

    int count = 0;
    bus.subscribe('card_obtained', (e, b) => count++);
    bus.publish(Event(type: 'card.pack_open', data: {'count': 3}));

    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(count > 0, true);
  });
}