import 'package:json_annotation/json_annotation.dart';
import 'performance_tracking.dart';
import 'fitness_game_integration.dart';

part 'fitness_reporting.g.dart';

enum ReportType {
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

enum RecommendationType {
  increaseDistance,
  increaseFrequency,
  addVariety,
  maintainProgress,
  improveSpeed,
  addStrengthTraining,
  restAndRecovery,
}

enum RecommendationPriority {
  low,
  medium,
  high,
  critical,
}

@JsonSerializable()
class FitnessReport {
  final DateRange period;
  final ReportType type;
  final int totalActivities;
  final double totalDistance;
  final int totalDuration;
  final int totalCalories;
  final double totalElevation;
  final double averageDistance;
  final double averageDuration;
  final double averageSpeed;
  final int averageHeartRate;
  final Map<String, double> trends;
  final List<PerformanceInsight> insights;
  final List<FitnessAchievement> achievements;
  final List<FitnessRecommendation> recommendations;
  final Map<String, double> workoutTypeDistribution;
  final List<DailyActivityData> dailyActivityChart;
  final DateTime generatedAt;

  FitnessReport({
    required this.period,
    required this.type,
    required this.totalActivities,
    required this.totalDistance,
    required this.totalDuration,
    required this.totalCalories,
    required this.totalElevation,
    required this.averageDistance,
    required this.averageDuration,
    required this.averageSpeed,
    required this.averageHeartRate,
    required this.trends,
    required this.insights,
    required this.achievements,
    required this.recommendations,
    required this.workoutTypeDistribution,
    required this.dailyActivityChart,
    required this.generatedAt,
  });

  factory FitnessReport.fromJson(Map<String, dynamic> json) =>
      _$FitnessReportFromJson(json);

  Map<String, dynamic> toJson() => _$FitnessReportToJson(this);

  factory FitnessReport.empty() {
    return FitnessReport(
      period: DateRange(
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      ),
      type: ReportType.weekly,
      totalActivities: 0,
      totalDistance: 0.0,
      totalDuration: 0,
      totalCalories: 0,
      totalElevation: 0.0,
      averageDistance: 0.0,
      averageDuration: 0.0,
      averageSpeed: 0.0,
      averageHeartRate: 0,
      trends: {},
      insights: [],
      achievements: [],
      recommendations: [],
      workoutTypeDistribution: {},
      dailyActivityChart: [],
      generatedAt: DateTime.now(),
    );
  }
}

@JsonSerializable()
class FitnessRecommendation {
  final String id;
  final RecommendationType type;
  final String title;
  final String description;
  final RecommendationPriority priority;
  final DateTime createdAt;
  final bool isImplemented;
  final DateTime? implementedAt;

  FitnessRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.createdAt,
    this.isImplemented = false,
    this.implementedAt,
  });

  factory FitnessRecommendation.fromJson(Map<String, dynamic> json) =>
      _$FitnessRecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$FitnessRecommendationToJson(this);

  FitnessRecommendation copyWith({
    String? id,
    RecommendationType? type,
    String? title,
    String? description,
    RecommendationPriority? priority,
    DateTime? createdAt,
    bool? isImplemented,
    DateTime? implementedAt,
  }) {
    return FitnessRecommendation(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      isImplemented: isImplemented ?? this.isImplemented,
      implementedAt: implementedAt ?? this.implementedAt,
    );
  }
}

@JsonSerializable()
class DailyActivityData {
  final DateTime date;
  final double distance;
  final int duration;
  final int calories;
  final int activities;

  DailyActivityData({
    required this.date,
    required this.distance,
    required this.duration,
    required this.calories,
    required this.activities,
  });

  factory DailyActivityData.fromJson(Map<String, dynamic> json) =>
      _$DailyActivityDataFromJson(json);

  Map<String, dynamic> toJson() => _$DailyActivityDataToJson(this);

  DailyActivityData copyWith({
    DateTime? date,
    double? distance,
    int? duration,
    int? calories,
    int? activities,
  }) {
    return DailyActivityData(
      date: date ?? this.date,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      calories: calories ?? this.calories,
      activities: activities ?? this.activities,
    );
  }
}

@JsonSerializable()
class ChartDataPoint {
  final String label;
  final double value;
  final String? color;
  final Map<String, dynamic>? metadata;

  ChartDataPoint({
    required this.label,
    required this.value,
    this.color,
    this.metadata,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) =>
      _$ChartDataPointFromJson(json);

  Map<String, dynamic> toJson() => _$ChartDataPointToJson(this);
}

@JsonSerializable()
class FitnessChart {
  final String title;
  final String type; // 'line', 'bar', 'pie', 'area'
  final List<ChartDataPoint> dataPoints;
  final Map<String, dynamic>? options;
  final DateTime createdAt;

  FitnessChart({
    required this.title,
    required this.type,
    required this.dataPoints,
    this.options,
    required this.createdAt,
  });

  factory FitnessChart.fromJson(Map<String, dynamic> json) =>
      _$FitnessChartFromJson(json);

  Map<String, dynamic> toJson() => _$FitnessChartToJson(this);
}

@JsonSerializable()
class FitnessDashboard {
  final String id;
  final String name;
  final String description;
  final List<FitnessChart> charts;
  final List<FitnessReport> reports;
  final DateTime lastUpdated;
  final bool isPublic;
  final String? ownerId;

  FitnessDashboard({
    required this.id,
    required this.name,
    required this.description,
    required this.charts,
    required this.reports,
    required this.lastUpdated,
    this.isPublic = false,
    this.ownerId,
  });

  factory FitnessDashboard.fromJson(Map<String, dynamic> json) =>
      _$FitnessDashboardFromJson(json);

  Map<String, dynamic> toJson() => _$FitnessDashboardToJson(this);

  FitnessDashboard copyWith({
    String? id,
    String? name,
    String? description,
    List<FitnessChart>? charts,
    List<FitnessReport>? reports,
    DateTime? lastUpdated,
    bool? isPublic,
    String? ownerId,
  }) {
    return FitnessDashboard(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      charts: charts ?? this.charts,
      reports: reports ?? this.reports,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isPublic: isPublic ?? this.isPublic,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}
