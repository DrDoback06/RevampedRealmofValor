import '../base_agent.dart';
import '../event_bus.dart';

enum CompanionPersonality { mentor, playful, coach }

class AICompanionAgent extends BaseAgent {
  AICompanionAgent(super.bus);

  CompanionPersonality _persona = CompanionPersonality.mentor;

  @override
  String get name => 'AICompanion';

  @override
  Future<void> onInitialize() async {
    bus.subscribe('companion.set_personality', (evt, b) {
      final p = (evt.data?['personality'] as String?)?.toLowerCase();
      if (p == 'playful') _persona = CompanionPersonality.playful;
      if (p == 'coach') _persona = CompanionPersonality.coach;
      if (p == 'mentor') _persona = CompanionPersonality.mentor;
      b.publish(Event(type: 'ui.notify', data: {'level': 'info', 'message': 'Companion set to $p'}));
    });

    bus.subscribe('companion.ask', (evt, b) {
      final q = evt.data?['q'] as String? ?? '';
      final reply = _answer(q);
      b.publish(Event(type: 'companion.reply', data: {'text': reply}));
    });

    bus.subscribe('battle_ended', (evt, b) {
      final win = evt.data?['winner'] == 'player';
      final tip = win ? _tone('Nice win! Consider tougher foes next.') : _tone('Don\'t worry, try equipping better gear and attack weak spots.');
      b.publish(Event(type: 'companion.reply', data: {'text': tip}));
    });

    bus.subscribe('fitness_goal_reached', (evt, b) {
      b.publish(Event(type: 'companion.reply', data: {'text': _tone('Great job meeting your goal! Enjoy the bonus XP.')}));
    });
  }

  @override
  Future<void> onDispose() async {}

  String _answer(String q) {
    final lower = q.toLowerCase();
    if (lower.contains('level') || lower.contains('xp')) {
      return _tone('You gain XP from battles and steps. Aim for daily goals and quests.');
    }
    if (lower.contains('equip') || lower.contains('gear')) {
      return _tone('Open inventory and equip a weapon in the weapon slot for more ATK.');
    }
    if (lower.contains('quest')) {
      return _tone('Check the quest log; visit marked locations or win a battle to progress.');
    }
    return _tone("I'm here to help! Ask about leveling, gear, or quests.");
  }

  String _tone(String text) {
    switch (_persona) {
      case CompanionPersonality.playful:
        return '😸 $text';
      case CompanionPersonality.coach:
        return '🏋️ $text';
      case CompanionPersonality.mentor:
        return '🧙 $text';
    }
  }
}