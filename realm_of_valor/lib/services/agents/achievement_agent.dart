import '../../data/models/achievement_model.dart';
import '../base_agent.dart';
import '../event_bus.dart';

class AchievementAgent extends BaseAgent {
  AchievementAgent(super.bus, {required List<AchievementDefinition> definitions}) : _defs = definitions;

  final List<AchievementDefinition> _defs;
  final Map<String, AchievementProgress> _progress = <String, AchievementProgress>{};

  @override
  String get name => 'Achievement';

  @override
  Future<void> onInitialize() async {
    for (final d in _defs) {
      _progress[d.id] = AchievementProgress(defId: d.id);
      bus.subscribe(d.eventType, (evt, b) => _handleEvent(d, evt));
    }
  }

  @override
  Future<void> onDispose() async {}

  void _handleEvent(AchievementDefinition def, Event evt) {
    final prog = _progress[def.id]!;
    if (prog.unlocked) return;
    prog.count += 1;
    if (prog.count >= def.threshold) {
      prog.unlocked = true;
      bus.publish(Event(type: 'achievement_unlocked', data: {
        'id': def.id,
        'title': def.title,
      }));
      if (def.rewardXp > 0) {
        bus.publish(Event(type: 'battle_result', data: {'win': true, 'xp': def.rewardXp}));
      }
    }
  }
}