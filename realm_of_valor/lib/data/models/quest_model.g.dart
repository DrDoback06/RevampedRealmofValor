// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestObjective _$QuestObjectiveFromJson(Map<String, dynamic> json) =>
    QuestObjective(
      id: json['id'] as String,
      description: json['description'] as String,
      target: (json['target'] as num?)?.toInt() ?? 1,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$QuestObjectiveToJson(QuestObjective instance) =>
    <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'target': instance.target,
      'progress': instance.progress,
    };

Quest _$QuestFromJson(Map<String, dynamic> json) => Quest(
  id: json['id'] as String,
  title: json['title'] as String,
  type: $enumDecode(_$QuestTypeEnumMap, json['type']),
  status: $enumDecode(_$QuestStatusEnumMap, json['status']),
  objectives:
      (json['objectives'] as List<dynamic>?)
          ?.map((e) => QuestObjective.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <QuestObjective>[],
  rewardXp: (json['rewardXp'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$QuestToJson(Quest instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'type': _$QuestTypeEnumMap[instance.type]!,
  'status': _$QuestStatusEnumMap[instance.status]!,
  'objectives': instance.objectives,
  'rewardXp': instance.rewardXp,
};

const _$QuestTypeEnumMap = {
  QuestType.story: 'story',
  QuestType.daily: 'daily',
  QuestType.weekly: 'weekly',
  QuestType.location: 'location',
  QuestType.fitness: 'fitness',
  QuestType.battle: 'battle',
};

const _$QuestStatusEnumMap = {
  QuestStatus.notStarted: 'notStarted',
  QuestStatus.inProgress: 'inProgress',
  QuestStatus.completed: 'completed',
  QuestStatus.claimed: 'claimed',
};
