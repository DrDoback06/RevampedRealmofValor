import '../base_agent.dart';
import '../event_bus.dart';

enum CompanionPersonality { mentor, playful, coach }

enum CompanionVerbosity { concise, normal, verbose }

class AICompanionAgent extends BaseAgent {
  AICompanionAgent(super.bus);

  CompanionPersonality _persona = CompanionPersonality.mentor;
  CompanionVerbosity _verbosity = CompanionVerbosity.normal;
  bool _proactiveEnabled = true;
  Duration _tipCooldown = const Duration(seconds: 20);
  DateTime? _lastTip;

  final List<String> _recent = <String>[];
  final int _recentMax = 20;

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

    bus.subscribe('companion.set_verbosity', (evt, b) {
      final v = (evt.data?['level'] as String?)?.toLowerCase();
      if (v == 'concise') _verbosity = CompanionVerbosity.concise;
      if (v == 'normal') _verbosity = CompanionVerbosity.normal;
      if (v == 'verbose') _verbosity = CompanionVerbosity.verbose;
      b.publish(Event(type: 'ui.notify', data: {'level': 'info', 'message': 'Companion verbosity $v'}));
    });

    bus.subscribe('companion.toggle_proactive', (evt, b) {
      _proactiveEnabled = evt.data?['enabled'] != false;
    });

    bus.subscribe('companion.set_cooldown_ms', (evt, b) {
      final ms = (evt.data?['ms'] as num?)?.toInt();
      if (ms != null && ms >= 0) _tipCooldown = Duration(milliseconds: ms);
    });

    bus.subscribe('companion.ask', (evt, b) {
      final q = evt.data?['q'] as String? ?? '';
      final reply = _answer(q);
      b.publish(Event(type: 'companion.reply', data: {'text': reply}));
      _remember('Q:$q');
    });

    // Proactive subscriptions
    bus.subscribe('battle_ended', (evt, b) {
      final win = evt.data?['winner'] == 'player';
      final tip = win
          ? _tone(_say('Nice win! Consider tougher foes next or try a quest.'))
          : _tone(_say("Don't worry, equip better gear and target weaker enemies."));
      _remember(win ? 'battle:win' : 'battle:loss');
      _maybeSpeak(tip, b);
    });

    bus.subscribe('fitness_goal_reached', (evt, b) {
      _remember('fitness:goal');
      _maybeSpeak(_tone(_say('Great job meeting your goal! Enjoy the bonus XP.')), b);
    });

    bus.subscribe('quest_completed', (evt, b) {
      _remember('quest:completed');
      _maybeSpeak(_tone(_say('Quest complete! Check the log for new adventures.')), b);
    });

    bus.subscribe('character_level_up', (evt, b) {
      _remember('character:level_up');
      _maybeSpeak(_tone(_say('Level up! Spend skill points to grow your power.')), b);
    });

    bus.subscribe('equipment_changed', (evt, b) {
      _remember('equipment:changed');
      _maybeSpeak(_tone(_say('Equipment updated. Review derived stats to optimize ATK/DEF.')), b);
    });

    bus.subscribe('weather_changed', (evt, b) {
      final cond = (evt.data?['condition'] as String?) ?? 'Weather';
      _remember('weather:$cond');
      _maybeSpeak(_tone(_say('$cond today. Weather can affect battles and quests!')), b);
    });
  }

  @override
  Future<void> onDispose() async {}

  String _answer(String q) {
    final intent = _intent(q);
    switch (intent) {
      case 'leveling':
        return _tone(_say('Gain XP from battles, daily steps, and quests; keep streaks for bonuses.'));
      case 'gear':
        return _tone(_say('Open Inventory and equip a weapon for ATK, armor for DEF; synergy boosts derived stats.'));
      case 'quest':
        return _tone(_say('Open your quest log; travel to marked locations or win battles to progress.'));
      case 'battle':
        return _tone(_say('Use attacks after a buff, watch enemy DEF, and exploit weather advantages.'));
      case 'fitness':
        return _tone(_say('Set a daily goal; every 1,000 steps gives XP. Keep streaks alive!'));
      case 'cards':
        return _tone(_say('Open packs for new cards; equip gear cards to boost ATK/DEF; craft duplicates later.'));
      default:
        final recent = _recent.isNotEmpty ? ' Recently: ${_recent.take(3).join(', ')}.' : '';
        return _tone(_say("I'm here to help with leveling, gear, quests, cards, fitness, and battles.$recent"));
    }
  }

  String _intent(String q) {
    final l = q.toLowerCase();
    if (l.contains('level') || l.contains('xp')) return 'leveling';
    if (l.contains('equip') || l.contains('gear') || l.contains('weapon') || l.contains('armor')) return 'gear';
    if (l.contains('quest') || l.contains('mission')) return 'quest';
    if (l.contains('fight') || l.contains('battle')) return 'battle';
    if (l.contains('fitness') || l.contains('steps') || l.contains('health')) return 'fitness';
    if (l.contains('card') || l.contains('deck') || l.contains('pack')) return 'cards';
    return 'general';
  }

  String _say(String base) {
    switch (_verbosity) {
      case CompanionVerbosity.concise:
        return base;
      case CompanionVerbosity.normal:
        return base;
      case CompanionVerbosity.verbose:
        return '$base Tip: check Settings to customize goals and companion tone.';
    }
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

  void _remember(String note) {
    _recent.insert(0, note);
    if (_recent.length > _recentMax) {
      _recent.removeLast();
    }
  }

  void _maybeSpeak(String text, EventBus b) {
    if (!_proactiveEnabled) return;
    final now = DateTime.now();
    if (_lastTip != null && now.difference(_lastTip!) < _tipCooldown) return;
    _lastTip = now;
    b.publish(Event(type: 'companion.reply', data: {'text': text}));
  }
}