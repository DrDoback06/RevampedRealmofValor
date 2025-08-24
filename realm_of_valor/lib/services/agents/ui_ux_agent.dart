import '../base_agent.dart';
import '../event_bus.dart';

class UIUXAgent extends BaseAgent {
  UIUXAgent(super.bus);

  @override
  String get name => 'UIUX';

  @override
  Future<void> onInitialize() async {
    bus.subscribe('achievement_unlocked', (evt, b) {
      final title = evt.data?['title'] as String? ?? 'Achievement unlocked';
      b.publish(Event(type: 'ui.notify', data: {'level': 'success', 'message': title}));
    });

    bus.subscribe('battle_ended', (evt, b) {
      final winner = evt.data?['winner'] as String?;
      final text = winner == 'player' ? 'Victory!' : 'Defeat...';
      b.publish(Event(type: 'ui.banner', data: {'text': text}));
    });

    bus.subscribe('quest_completed', (evt, b) {
      b.publish(Event(type: 'ui.notify', data: {'level': 'info', 'message': 'Quest completed!'}));
    });
  }

  @override
  Future<void> onDispose() async {}
}