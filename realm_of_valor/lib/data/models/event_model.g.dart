// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameEvent _$GameEventFromJson(Map<String, dynamic> json) => GameEvent(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$EventTypeEnumMap, json['type']),
      status: $enumDecode(_$EventStatusEnumMap, json['status']),
      difficulty: $enumDecode(_$EventDifficultyEnumMap, json['difficulty']),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      radius: (json['radius'] as num?)?.toInt(),
      requirements: json['requirements'] as Map<String, dynamic>?,
      rewards: json['rewards'] as Map<String, dynamic>?,
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? 100,
      imageUrl: json['imageUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isRepeatable: json['isRepeatable'] as bool? ?? false,
      cooldownHours: (json['cooldownHours'] as num?)?.toInt(),
    );

Map<String, dynamic> _$GameEventToJson(GameEvent instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$EventTypeEnumMap[instance.type]!,
      'status': _$EventStatusEnumMap[instance.status]!,
      'difficulty': _$EventDifficultyEnumMap[instance.difficulty]!,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'location': instance.location,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radius': instance.radius,
      'requirements': instance.requirements,
      'rewards': instance.rewards,
      'participants': instance.participants,
      'maxParticipants': instance.maxParticipants,
      'imageUrl': instance.imageUrl,
      'metadata': instance.metadata,
      'isRepeatable': instance.isRepeatable,
      'cooldownHours': instance.cooldownHours,
    };

const _$EventTypeEnumMap = {
  EventType.battle: 'battle',
  EventType.quest: 'quest',
  EventType.social: 'social',
  EventType.fitness: 'fitness',
  EventType.achievement: 'achievement',
  EventType.weather: 'weather',
  EventType.seasonal: 'seasonal',
  EventType.special: 'special',
};

const _$EventStatusEnumMap = {
  EventStatus.upcoming: 'upcoming',
  EventStatus.active: 'active',
  EventStatus.completed: 'completed',
  EventStatus.cancelled: 'cancelled',
};

const _$EventDifficultyEnumMap = {
  EventDifficulty.easy: 'easy',
  EventDifficulty.medium: 'medium',
  EventDifficulty.hard: 'hard',
  EventDifficulty.extreme: 'extreme',
};

EventParticipation _$EventParticipationFromJson(Map<String, dynamic> json) =>
    EventParticipation(
      eventId: json['eventId'] as String,
      userId: json['userId'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      progress: json['progress'] as Map<String, dynamic>?,
      rewards: json['rewards'] as Map<String, dynamic>?,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );

Map<String, dynamic> _$EventParticipationToJson(EventParticipation instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'userId': instance.userId,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'progress': instance.progress,
      'rewards': instance.rewards,
      'isCompleted': instance.isCompleted,
    };

EventLeaderboard _$EventLeaderboardFromJson(Map<String, dynamic> json) =>
    EventLeaderboard(
      eventId: json['eventId'] as String,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => EventLeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$EventLeaderboardToJson(EventLeaderboard instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'entries': instance.entries,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };

EventLeaderboardEntry _$EventLeaderboardEntryFromJson(
        Map<String, dynamic> json) =>
    EventLeaderboardEntry(
      userId: json['userId'] as String,
      username: json['username'] as String,
      score: (json['score'] as num).toInt(),
      rank: (json['rank'] as num).toInt(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$EventLeaderboardEntryToJson(
        EventLeaderboardEntry instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'username': instance.username,
      'score': instance.score,
      'rank': instance.rank,
      'metadata': instance.metadata,
    };
