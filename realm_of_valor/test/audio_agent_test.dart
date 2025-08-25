import 'package:flutter_test/flutter_test.dart';
import 'package:realm_of_valor/services/agents/audio_agent.dart';
import 'package:realm_of_valor/services/event_bus.dart';

void main() {
  test('Battle start/end and achievement trigger audio.play/stop', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);
    final agent = AudioAgent(bus);
    await agent.initialize();

    final plays = <Event>[];
    final stops = <Event>[];
    bus.subscribe('audio.play', (e, b) => plays.add(e));
    bus.subscribe('audio.stop', (e, b) => stops.add(e));

    bus.publish(Event(type: 'battle_started'));
    bus.publish(Event(type: 'battle_ended', data: {'winner': 'player'}));
    bus.publish(Event(type: 'achievement_unlocked', data: {'title': 'Tester'}));

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(plays.isNotEmpty, true);
    expect(stops.isNotEmpty, true);
  });
}
