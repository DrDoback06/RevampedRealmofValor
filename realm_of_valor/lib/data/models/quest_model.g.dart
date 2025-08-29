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
      type: json['type'] as String? ?? 'general',
    );

Map<String, dynamic> _$QuestObjectiveToJson(QuestObjective instance) =>
    <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'target': instance.target,
      'progress': instance.progress,
      'type': instance.type,
    };

QuestLocation _$QuestLocationFromJson(Map<String, dynamic> json) =>
    QuestLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toDouble() ?? 50,
      name: json['name'] as String?,
      address: json['address'] as String?,
    );

Map<String, dynamic> _$QuestLocationToJson(QuestLocation instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radius': instance.radius,
      'name': instance.name,
      'address': instance.address,
    };

QuestRewards _$QuestRewardsFromJson(Map<String, dynamic> json) => QuestRewards(
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      gold: (json['gold'] as num?)?.toInt() ?? 0,
      gems: (json['gems'] as num?)?.toInt() ?? 0,
      items:
          (json['items'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      skillPoints: (json['skillPoints'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$QuestRewardsToJson(QuestRewards instance) =>
    <String, dynamic>{
      'xp': instance.xp,
      'gold': instance.gold,
      'gems': instance.gems,
      'items': instance.items,
      'skillPoints': instance.skillPoints,
    };

Quest _$QuestFromJson(Map<String, dynamic> json) => Quest(
      id: json['id'] as String,
      title: json['title'] as String,
      type: $enumDecode(_$QuestTypeEnumMap, json['type']),
      category: $enumDecode(_$QuestCategoryEnumMap, json['category']),
      status: $enumDecode(_$QuestStatusEnumMap, json['status']),
      description: json['description'] as String? ?? '',
      objectives: (json['objectives'] as List<dynamic>?)
              ?.map((e) => QuestObjective.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <QuestObjective>[],
      rewards: json['rewards'] == null
          ? const QuestRewards()
          : QuestRewards.fromJson(json['rewards'] as Map<String, dynamic>),
      location: json['location'] == null
          ? null
          : QuestLocation.fromJson(json['location'] as Map<String, dynamic>),
      timeLimit: (json['timeLimit'] as num?)?.toInt(),
      prerequisites: (json['prerequisites'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$QuestToJson(Quest instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'type': _$QuestTypeEnumMap[instance.type]!,
      'category': _$QuestCategoryEnumMap[instance.category]!,
      'status': _$QuestStatusEnumMap[instance.status]!,
      'description': instance.description,
      'objectives': instance.objectives,
      'rewards': instance.rewards,
      'location': instance.location,
      'timeLimit': instance.timeLimit,
      'prerequisites': instance.prerequisites,
      'tags': instance.tags,
      'createdAt': instance.createdAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
    };

const _$QuestTypeEnumMap = {
  QuestType.story: 'story',
  QuestType.daily: 'daily',
  QuestType.weekly: 'weekly',
  QuestType.location: 'location',
  QuestType.fitness: 'fitness',
  QuestType.battle: 'battle',
  QuestType.social: 'social',
  QuestType.treasure: 'treasure',
};

const _$QuestCategoryEnumMap = {
  QuestCategory.main: 'main',
  QuestCategory.adventure: 'adventure',
  QuestCategory.side: 'side',
};

const _$QuestStatusEnumMap = {
  QuestStatus.notStarted: 'notStarted',
  QuestStatus.inProgress: 'inProgress',
  QuestStatus.completed: 'completed',
  QuestStatus.claimed: 'claimed',
  QuestStatus.abandoned: 'abandoned',
};
