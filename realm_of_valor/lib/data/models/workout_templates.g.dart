// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_templates.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutSegment _$WorkoutSegmentFromJson(Map<String, dynamic> json) =>
    WorkoutSegment(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$SegmentTypeEnumMap, json['type']),
      duration: (json['duration'] as num).toInt(),
      targetDistance: (json['targetDistance'] as num?)?.toDouble(),
      targetPace: (json['targetPace'] as num?)?.toDouble(),
      targetHeartRate: (json['targetHeartRate'] as num?)?.toInt(),
      instructions: json['instructions'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$WorkoutSegmentToJson(WorkoutSegment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$SegmentTypeEnumMap[instance.type]!,
      'duration': instance.duration,
      'targetDistance': instance.targetDistance,
      'targetPace': instance.targetPace,
      'targetHeartRate': instance.targetHeartRate,
      'instructions': instance.instructions,
      'parameters': instance.parameters,
    };

const _$SegmentTypeEnumMap = {
  SegmentType.warmup: 'warmup',
  SegmentType.workout: 'workout',
  SegmentType.cooldown: 'cooldown',
  SegmentType.rest: 'rest',
  SegmentType.interval: 'interval',
  SegmentType.tempo: 'tempo',
  SegmentType.endurance: 'endurance',
};

WorkoutTemplate _$WorkoutTemplateFromJson(Map<String, dynamic> json) =>
    WorkoutTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$WorkoutTypeEnumMap, json['type']),
      targetDuration: (json['targetDuration'] as num).toInt(),
      targetDistance: (json['targetDistance'] as num).toDouble(),
      targetCalories: (json['targetCalories'] as num).toInt(),
      segments: (json['segments'] as List<dynamic>)
          .map((e) => WorkoutSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
      difficulty: $enumDecode(_$DifficultyLevelEnumMap, json['difficulty']),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      usageCount: (json['usageCount'] as num).toInt(),
      averageRating: (json['averageRating'] as num).toDouble(),
      ratings: (json['ratings'] as List<dynamic>)
          .map((e) => TemplateRating.fromJson(e as Map<String, dynamic>))
          .toList(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      creatorId: json['creatorId'] as String?,
      isPublic: json['isPublic'] as bool? ?? true,
    );

Map<String, dynamic> _$WorkoutTemplateToJson(WorkoutTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$WorkoutTypeEnumMap[instance.type]!,
      'targetDuration': instance.targetDuration,
      'targetDistance': instance.targetDistance,
      'targetCalories': instance.targetCalories,
      'segments': instance.segments,
      'difficulty': _$DifficultyLevelEnumMap[instance.difficulty]!,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'usageCount': instance.usageCount,
      'averageRating': instance.averageRating,
      'ratings': instance.ratings,
      'isFavorite': instance.isFavorite,
      'creatorId': instance.creatorId,
      'isPublic': instance.isPublic,
    };

const _$WorkoutTypeEnumMap = {
  WorkoutType.running: 'running',
  WorkoutType.cycling: 'cycling',
  WorkoutType.swimming: 'swimming',
  WorkoutType.walking: 'walking',
  WorkoutType.hiking: 'hiking',
  WorkoutType.strength: 'strength',
  WorkoutType.yoga: 'yoga',
  WorkoutType.pilates: 'pilates',
  WorkoutType.crossfit: 'crossfit',
  WorkoutType.other: 'other',
};

const _$DifficultyLevelEnumMap = {
  DifficultyLevel.beginner: 'beginner',
  DifficultyLevel.intermediate: 'intermediate',
  DifficultyLevel.advanced: 'advanced',
  DifficultyLevel.expert: 'expert',
};

TemplateRating _$TemplateRatingFromJson(Map<String, dynamic> json) =>
    TemplateRating(
      id: json['id'] as String,
      userId: json['userId'] as String,
      rating: (json['rating'] as num).toDouble(),
      review: json['review'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$TemplateRatingToJson(TemplateRating instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'rating': instance.rating,
      'review': instance.review,
      'createdAt': instance.createdAt.toIso8601String(),
    };

RoutineDay _$RoutineDayFromJson(Map<String, dynamic> json) => RoutineDay(
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      templateId: json['templateId'] as String?,
      workoutType:
          $enumDecodeNullable(_$WorkoutTypeEnumMap, json['workoutType']),
      duration: (json['duration'] as num?)?.toInt(),
      distance: (json['distance'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      isRestDay: json['isRestDay'] as bool? ?? false,
    );

Map<String, dynamic> _$RoutineDayToJson(RoutineDay instance) =>
    <String, dynamic>{
      'dayOfWeek': instance.dayOfWeek,
      'templateId': instance.templateId,
      'workoutType': _$WorkoutTypeEnumMap[instance.workoutType],
      'duration': instance.duration,
      'distance': instance.distance,
      'notes': instance.notes,
      'isRestDay': instance.isRestDay,
    };

WorkoutRoutine _$WorkoutRoutineFromJson(Map<String, dynamic> json) =>
    WorkoutRoutine(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      days: (json['days'] as List<dynamic>)
          .map((e) => RoutineDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      durationWeeks: (json['durationWeeks'] as num).toInt(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      currentWeek: (json['currentWeek'] as num).toInt(),
      currentDay: (json['currentDay'] as num).toInt(),
      completedWorkouts: (json['completedWorkouts'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$WorkoutRoutineToJson(WorkoutRoutine instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'days': instance.days,
      'durationWeeks': instance.durationWeeks,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'startDate': instance.startDate?.toIso8601String(),
      'currentWeek': instance.currentWeek,
      'currentDay': instance.currentDay,
      'completedWorkouts': instance.completedWorkouts,
      'isActive': instance.isActive,
    };
