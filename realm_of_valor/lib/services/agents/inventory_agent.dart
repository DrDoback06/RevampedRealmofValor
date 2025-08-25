import '../base_agent.dart';
import '../event_bus.dart';
import '../../data/models/inventory_model.dart';
import '../../domain/inventory/inventory_repository.dart';
import 'package:flutter/foundation.dart';

class InventoryAgent extends BaseAgent {
  InventoryAgent(super.bus, {required this.inventoryRepo});

  final InventoryRepository inventoryRepo;
  Inventory? _currentInventory;

  @override
  String get name => 'Inventory';

  @override
  Future<void> onInitialize() async {
    bus.subscribe('inventory.deduct_gold', _onDeductGold);
    bus.subscribe('inventory.add_gold', _onAddGold);
    bus.subscribe('card.obtain', _onCardObtain);
    bus.subscribe('character.add_xp', _onAddXP);
  }

  @override
  Future<void> onDispose() async {}

  void _onDeductGold(Event evt, EventBus b) {
    final goldAmount = evt.data?['gold'] as int? ?? 0;
    if (goldAmount <= 0) return;

    debugPrint('InventoryAgent: Deducting $goldAmount gold');
    
    // For now, just log the deduction
    // In a full implementation, this would update the actual inventory
    bus.publish(Event(
      type: 'inventory_updated',
      data: {
        'gold_deducted': goldAmount,
        'message': 'Deducted $goldAmount gold',
      },
    ));
  }

  void _onAddGold(Event evt, EventBus b) {
    final goldAmount = evt.data?['gold'] as int? ?? 0;
    if (goldAmount <= 0) return;

    debugPrint('InventoryAgent: Adding $goldAmount gold');
    
    bus.publish(Event(
      type: 'inventory_updated',
      data: {
        'gold_added': goldAmount,
        'message': 'Added $goldAmount gold',
      },
    ));
  }

  void _onCardObtain(Event evt, EventBus b) {
    final cardId = evt.data?['cardId'] as String?;
    if (cardId == null) return;

    debugPrint('InventoryAgent: Obtained card $cardId');
    
    bus.publish(Event(
      type: 'inventory_updated',
      data: {
        'card_obtained': cardId,
        'message': 'Obtained card: $cardId',
      },
    ));
  }

  void _onAddXP(Event evt, EventBus b) {
    final xpAmount = evt.data?['xp'] as int? ?? 0;
    if (xpAmount <= 0) return;

    debugPrint('InventoryAgent: Adding $xpAmount XP');
    
    bus.publish(Event(
      type: 'character_updated',
      data: {
        'xp_added': xpAmount,
        'message': 'Added $xpAmount XP',
      },
    ));
  }
}
