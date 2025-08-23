import '../base_agent.dart';
import '../event_bus.dart';

class AudioAgent extends BaseAgent {
  AudioAgent(super.bus);

  @override
  String get name => 'Audio';

  @override
  Future<void> onInitialize() async {
    bus.subscribe('battle_started', (evt, b) {
      b.publish(Event(type: 'audio.play', data: {'asset': 'music/battle_theme.mp3', 'loop': true}));
    });

    bus.subscribe('battle_ended', (evt, b) {
      final win = evt.data?['winner'] == 'player';
      b.publish(Event(type: 'audio.play', data: {'asset': win ? 'sfx/victory.wav' : 'sfx/defeat.wav'}));
      b.publish(Event(type: 'audio.stop', data: {'asset': 'music/battle_theme.mp3'}));
    });

    bus.subscribe('achievement_unlocked', (evt, b) {
      b.publish(Event(type: 'audio.play', data: {'asset': 'sfx/achievement.wav'}));
    });
  }

  @override
  Future<void> onDispose() async {}
}