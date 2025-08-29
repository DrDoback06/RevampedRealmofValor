// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performance_tracking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PerformanceMetrics _$PerformanceMetricsFromJson(Map<String, dynamic> json) =>
    PerformanceMetrics(
      totalDistance: (json['totalDistance'] as num).toDouble(),
      totalDuration: (json['totalDuration'] as num).toInt(),
      totalCalories: (json['totalCalories'] as num).toInt(),
      totalElevation: (json['totalElevation'] as num).toDouble(),
      totalWorkouts: (json['totalWorkouts'] as num).toInt(),
      averageDistance: (json['averageDistance'] as num).toDouble(),
      averageDuration: (json['averageDuration'] as num).toDouble(),
      averageSpeed: (json['averageSpeed'] as num).toDouble(),
      averageHeartRate: (json['averageHeartRate'] as num).toInt(),
      maxSpeed: (json['maxSpeed'] as num).toDouble(),
      maxHeartRate: (json['maxHeartRate'] as num).toInt(),
      distanceTrend: (json['distanceTrend'] as num).toDouble(),
      durationTrend: (json['durationTrend'] as num).toDouble(),
      speedTrend: (json['speedTrend'] as num).toDouble(),
      heartRateTrend: (json['heartRateTrend'] as num).toDouble(),
      personalRecords: PersonalRecords.fromJson(
          json['personalRecords'] as Map<String, dynamic>),
      consistencyScore: (json['consistencyScore'] as num).toDouble(),
      improvementRate: (json['improvementRate'] as num).toDouble(),
      workoutTypes: (json['workoutTypes'] as List<dynamic>)
          .map((e) => $enumDecode(_$WorkoutTypeEnumMap, e))
          .toList(),
      dateRange: DateRange.fromJson(json['dateRange'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PerformanceMetricsToJson(PerformanceMetrics instance) =>
    <String, dynamic>{
      'totalDistance': instance.totalDistance,
      'totalDuration': instance.totalDuration,
      'totalCalories': instance.totalCalories,
      'totalElevation': instance.totalElevation,
      'totalWorkouts': instance.totalWorkouts,
      'averageDistance': instance.averageDistance,
      'averageDuration': instance.averageDuration,
      'averageSpeed': instance.averageSpeed,
      'averageHeartRate': instance.averageHeartRate,
      'maxSpeed': instance.maxSpeed,
      'maxHeartRate': instance.maxHeartRate,
      'distanceTrend': instance.distanceTrend,
      'durationTrend': instance.durationTrend,
      'speedTrend': instance.speedTrend,
      'heartRateTrend': instance.heartRateTrend,
      'personalRecords': instance.personalRecords,
      'consistencyScore': instance.consistencyScore,
      'improvementRate': instance.improvementRate,
      'workoutTypes':
          instance.workoutTypes.map((e) => _$WorkoutTypeEnumMap[e]!).toList(),
      'dateRange': instance.dateRange,
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

PersonalRecords _$PersonalRecordsFromJson(Map<String, dynamic> json) =>
    PersonalRecords(
      longestDistance: (json['longestDistance'] as num).toDouble(),
      longestDuration: (json['longestDuration'] as num).toInt(),
      fastestPace: (json['fastestPace'] as num).toDouble(),
      highestElevation: (json['highestElevation'] as num).toDouble(),
      maxHeartRate: (json['maxHeartRate'] as num).toInt(),
    );

Map<String, dynamic> _$PersonalRecordsToJson(PersonalRecords instance) =>
    <String, dynamic>{
      'longestDistance': instance.longestDistance,
      'longestDuration': instance.longestDuration,
      'fastestPace': instance.fastestPace,
      'highestElevation': instance.highestElevation,
      'maxHeartRate': instance.maxHeartRate,
    };

DateRange _$DateRangeFromJson(Map<String, dynamic> json) => DateRange(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );

Map<String, dynamic> _$DateRangeToJson(DateRange instance) => <String, dynamic>{
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
    };

PerformanceInsight _$PerformanceInsightFromJson(Map<String, dynamic> json) =>
    PerformanceInsight(
      id: json['id'] as String,
      type: $enumDecode(_$InsightTypeEnumMap, json['type']),
      title: json['title'] as String,
      message: json['message'] as String,
      metric: json['metric'] as String,
      value: (json['value'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );

Map<String, dynamic> _$PerformanceInsightToJson(PerformanceInsight instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$InsightTypeEnumMap[instance.type]!,
      'title': instance.title,
      'message': instance.message,
      'metric': instance.metric,
      'value': instance.value,
      'createdAt': instance.createdAt.toIso8601String(),
      'isRead': instance.isRead,
    };

const _$InsightTypeEnumMap = {
  InsightType.improvement: 'improvement',
  InsightType.decline: 'decline',
  InsightType.achievement: 'achievement',
  InsightType.warning: 'warning',
  InsightType.milestone: 'milestone',
};

PerformanceGoal _$PerformanceGoalFromJson(Map<String, dynamic> json) =>
    PerformanceGoal(
      id: json['id'] as String,
      metric: json['metric'] as String,
      target: (json['target'] as num).toDouble(),
      current: (json['current'] as num).toDouble(),
      deadline: DateTime.parse(json['deadline'] as String),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isCompleted: json['isCompleted'] as bool,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$PerformanceGoalToJson(PerformanceGoal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'metric': instance.metric,
      'target': instance.target,
      'current': instance.current,
      'deadline': instance.deadline.toIso8601String(),
      'description': instance.description,
      'createdAt': instance.createdAt.toIso8601String(),
      'isCompleted': instance.isCompleted,
      'completedAt': instance.completedAt?.toIso8601String(),
    };
