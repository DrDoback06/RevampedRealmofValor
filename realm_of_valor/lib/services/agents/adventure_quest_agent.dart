import '../../data/models/quest_model.dart';
import '../base_agent.dart';
import '../event_bus.dart';

class AdventureQuestAgent extends BaseAgent {
  AdventureQuestAgent(super.bus);

  final Map<String, Quest> _active = <String, Quest>{};

  @override
  String get name => 'AdventureQuest';

  @override
  Future<void> onInitialize() async {
    bus.subscribe('quest.add', (evt, b) => _addQuest(evt));
    bus.subscribe('quest.location_reached', (evt, b) => _progressByType(evt, QuestType.location));
    bus.subscribe('battle_ended', (evt, b) => _progressByType(evt, QuestType.battle));
    bus.subscribe('fitness_goal_reached', (evt, b) => _progressByType(evt, QuestType.fitness));
  }

  @override
  Future<void> onDispose() async {}

  void _addQuest(Event evt) {
    final raw = Map<String, dynamic>.from(evt.data?['quest'] as Map);
    final id = raw['id'] as String;
    final title = raw['title'] as String;
    final typeStr = (raw['type'] as String).toLowerCase();
    final type = typeStr.endsWith('battle')
        ? QuestType.battle
        : typeStr.endsWith('location')
            ? QuestType.location
            : typeStr.endsWith('fitness')
                ? QuestType.fitness
                : typeStr.endsWith('daily')
                    ? QuestType.daily
                    : typeStr.endsWith('weekly')
                        ? QuestType.weekly
                        : QuestType.story;
    final rewardXp = (raw['rewardXp'] as num?)?.toInt() ?? 0;
    final objectivesRaw = List<Map<String, dynamic>>.from(raw['objectives'] as List);
    final objectives = objectivesRaw
        .map((o) => QuestObjective(
              id: o['id'] as String,
              description: o['description'] as String,
              target: (o['target'] as num?)?.toInt() ?? 1,
              progress: (o['progress'] as num?)?.toInt() ?? 0,
            ))
        .toList();
    final q = Quest(
      id: id, 
      title: title, 
      type: type, 
      category: QuestCategory.adventure,
      status: QuestStatus.notStarted, 
      objectives: objectives,
      rewards: const QuestRewards(xp: 100),
    );
    _active[q.id] = q;
    bus.publish(Event(type: 'quest_added', data: {'id': q.id}));
  }

  void _progressByType(Event evt, QuestType type) {
    final entries = List<MapEntry<String, Quest>>.from(_active.entries);
    for (final entry in entries) {
      final q = entry.value;
      if (q.status == QuestStatus.completed || q.type != type) continue;
      final updatedObjs = q.objectives.map((o) {
        final newCount = (o.progress + 1).clamp(0, o.target);
        return QuestObjective(id: o.id, description: o.description, target: o.target, progress: newCount);
      }).toList();
      final done = updatedObjs.every((o) => o.progress >= o.target);
      final newStatus = done ? QuestStatus.completed : QuestStatus.inProgress;
      _active[q.id] = Quest(
        id: q.id, 
        title: q.title, 
        type: q.type, 
        category: q.category,
        status: newStatus, 
        objectives: updatedObjs, 
        rewards: q.rewards,
      );
      bus.publish(Event(type: 'quest_progress', data: {'id': q.id, 'status': newStatus.name}));
      if (done) {
        bus.publish(Event(type: 'quest_completed', data: {'id': q.id}));
        if (q.rewards.xp > 0) {
          bus.publish(Event(type: 'battle_result', data: {'win': true, 'xp': q.rewards.xp}));
        }
      }
    }
  }
}
