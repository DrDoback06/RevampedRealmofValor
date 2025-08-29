// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fitness_reporting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FitnessReport _$FitnessReportFromJson(Map<String, dynamic> json) =>
    FitnessReport(
      period: DateRange.fromJson(json['period'] as Map<String, dynamic>),
      type: $enumDecode(_$ReportTypeEnumMap, json['type']),
      totalActivities: (json['totalActivities'] as num).toInt(),
      totalDistance: (json['totalDistance'] as num).toDouble(),
      totalDuration: (json['totalDuration'] as num).toInt(),
      totalCalories: (json['totalCalories'] as num).toInt(),
      totalElevation: (json['totalElevation'] as num).toDouble(),
      averageDistance: (json['averageDistance'] as num).toDouble(),
      averageDuration: (json['averageDuration'] as num).toDouble(),
      averageSpeed: (json['averageSpeed'] as num).toDouble(),
      averageHeartRate: (json['averageHeartRate'] as num).toInt(),
      trends: (json['trends'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      insights: (json['insights'] as List<dynamic>)
          .map((e) => PerformanceInsight.fromJson(e as Map<String, dynamic>))
          .toList(),
      achievements: (json['achievements'] as List<dynamic>)
          .map((e) => FitnessAchievement.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((e) => FitnessRecommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
      workoutTypeDistribution:
          (json['workoutTypeDistribution'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      dailyActivityChart: (json['dailyActivityChart'] as List<dynamic>)
          .map((e) => DailyActivityData.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );

Map<String, dynamic> _$FitnessReportToJson(FitnessReport instance) =>
    <String, dynamic>{
      'period': instance.period,
      'type': _$ReportTypeEnumMap[instance.type]!,
      'totalActivities': instance.totalActivities,
      'totalDistance': instance.totalDistance,
      'totalDuration': instance.totalDuration,
      'totalCalories': instance.totalCalories,
      'totalElevation': instance.totalElevation,
      'averageDistance': instance.averageDistance,
      'averageDuration': instance.averageDuration,
      'averageSpeed': instance.averageSpeed,
      'averageHeartRate': instance.averageHeartRate,
      'trends': instance.trends,
      'insights': instance.insights,
      'achievements': instance.achievements,
      'recommendations': instance.recommendations,
      'workoutTypeDistribution': instance.workoutTypeDistribution,
      'dailyActivityChart': instance.dailyActivityChart,
      'generatedAt': instance.generatedAt.toIso8601String(),
    };

const _$ReportTypeEnumMap = {
  ReportType.daily: 'daily',
  ReportType.weekly: 'weekly',
  ReportType.monthly: 'monthly',
  ReportType.yearly: 'yearly',
  ReportType.custom: 'custom',
};

FitnessRecommendation _$FitnessRecommendationFromJson(
        Map<String, dynamic> json) =>
    FitnessRecommendation(
      id: json['id'] as String,
      type: $enumDecode(_$RecommendationTypeEnumMap, json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      priority: $enumDecode(_$RecommendationPriorityEnumMap, json['priority']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isImplemented: json['isImplemented'] as bool? ?? false,
      implementedAt: json['implementedAt'] == null
          ? null
          : DateTime.parse(json['implementedAt'] as String),
    );

Map<String, dynamic> _$FitnessRecommendationToJson(
        FitnessRecommendation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$RecommendationTypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'priority': _$RecommendationPriorityEnumMap[instance.priority]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'isImplemented': instance.isImplemented,
      'implementedAt': instance.implementedAt?.toIso8601String(),
    };

const _$RecommendationTypeEnumMap = {
  RecommendationType.increaseDistance: 'increaseDistance',
  RecommendationType.increaseFrequency: 'increaseFrequency',
  RecommendationType.addVariety: 'addVariety',
  RecommendationType.maintainProgress: 'maintainProgress',
  RecommendationType.improveSpeed: 'improveSpeed',
  RecommendationType.addStrengthTraining: 'addStrengthTraining',
  RecommendationType.restAndRecovery: 'restAndRecovery',
};

const _$RecommendationPriorityEnumMap = {
  RecommendationPriority.low: 'low',
  RecommendationPriority.medium: 'medium',
  RecommendationPriority.high: 'high',
  RecommendationPriority.critical: 'critical',
};

DailyActivityData _$DailyActivityDataFromJson(Map<String, dynamic> json) =>
    DailyActivityData(
      date: DateTime.parse(json['date'] as String),
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toInt(),
      calories: (json['calories'] as num).toInt(),
      activities: (json['activities'] as num).toInt(),
    );

Map<String, dynamic> _$DailyActivityDataToJson(DailyActivityData instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'distance': instance.distance,
      'duration': instance.duration,
      'calories': instance.calories,
      'activities': instance.activities,
    };

ChartDataPoint _$ChartDataPointFromJson(Map<String, dynamic> json) =>
    ChartDataPoint(
      label: json['label'] as String,
      value: (json['value'] as num).toDouble(),
      color: json['color'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ChartDataPointToJson(ChartDataPoint instance) =>
    <String, dynamic>{
      'label': instance.label,
      'value': instance.value,
      'color': instance.color,
      'metadata': instance.metadata,
    };

FitnessChart _$FitnessChartFromJson(Map<String, dynamic> json) => FitnessChart(
      title: json['title'] as String,
      type: json['type'] as String,
      dataPoints: (json['dataPoints'] as List<dynamic>)
          .map((e) => ChartDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      options: json['options'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$FitnessChartToJson(FitnessChart instance) =>
    <String, dynamic>{
      'title': instance.title,
      'type': instance.type,
      'dataPoints': instance.dataPoints,
      'options': instance.options,
      'createdAt': instance.createdAt.toIso8601String(),
    };

FitnessDashboard _$FitnessDashboardFromJson(Map<String, dynamic> json) =>
    FitnessDashboard(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      charts: (json['charts'] as List<dynamic>)
          .map((e) => FitnessChart.fromJson(e as Map<String, dynamic>))
          .toList(),
      reports: (json['reports'] as List<dynamic>)
          .map((e) => FitnessReport.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      isPublic: json['isPublic'] as bool? ?? false,
      ownerId: json['ownerId'] as String?,
    );

Map<String, dynamic> _$FitnessDashboardToJson(FitnessDashboard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'charts': instance.charts,
      'reports': instance.reports,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'isPublic': instance.isPublic,
      'ownerId': instance.ownerId,
    };
