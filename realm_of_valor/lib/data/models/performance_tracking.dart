import 'package:json_annotation/json_annotation.dart';
import 'workout_templates.dart';

part 'performance_tracking.g.dart';

enum InsightType {
  improvement,
  decline,
  achievement,
  warning,
  milestone,
}

@JsonSerializable()
class PerformanceMetrics {
  final double totalDistance;
  final int totalDuration;
  final int totalCalories;
  final double totalElevation;
  final int totalWorkouts;
  final double averageDistance;
  final double averageDuration;
  final double averageSpeed;
  final int averageHeartRate;
  final double maxSpeed;
  final int maxHeartRate;
  final double distanceTrend;
  final double durationTrend;
  final double speedTrend;
  final double heartRateTrend;
  final PersonalRecords personalRecords;
  final double consistencyScore;
  final double improvementRate;
  final List<WorkoutType> workoutTypes;
  final DateRange dateRange;

  PerformanceMetrics({
    required this.totalDistance,
    required this.totalDuration,
    required this.totalCalories,
    required this.totalElevation,
    required this.totalWorkouts,
    required this.averageDistance,
    required this.averageDuration,
    required this.averageSpeed,
    required this.averageHeartRate,
    required this.maxSpeed,
    required this.maxHeartRate,
    required this.distanceTrend,
    required this.durationTrend,
    required this.speedTrend,
    required this.heartRateTrend,
    required this.personalRecords,
    required this.consistencyScore,
    required this.improvementRate,
    required this.workoutTypes,
    required this.dateRange,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) =>
      _$PerformanceMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$PerformanceMetricsToJson(this);

  factory PerformanceMetrics.empty() {
    return PerformanceMetrics(
      totalDistance: 0.0,
      totalDuration: 0,
      totalCalories: 0,
      totalElevation: 0.0,
      totalWorkouts: 0,
      averageDistance: 0.0,
      averageDuration: 0.0,
      averageSpeed: 0.0,
      averageHeartRate: 0,
      maxSpeed: 0.0,
      maxHeartRate: 0,
      distanceTrend: 0.0,
      durationTrend: 0.0,
      speedTrend: 0.0,
      heartRateTrend: 0.0,
      personalRecords: PersonalRecords.empty(),
      consistencyScore: 0.0,
      improvementRate: 0.0,
      workoutTypes: [],
      dateRange: DateRange(
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      ),
    );
  }
}

@JsonSerializable()
class PersonalRecords {
  final double longestDistance;
  final int longestDuration;
  final double fastestPace;
  final double highestElevation;
  final int maxHeartRate;

  PersonalRecords({
    required this.longestDistance,
    required this.longestDuration,
    required this.fastestPace,
    required this.highestElevation,
    required this.maxHeartRate,
  });

  factory PersonalRecords.fromJson(Map<String, dynamic> json) =>
      _$PersonalRecordsFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalRecordsToJson(this);

  factory PersonalRecords.empty() {
    return PersonalRecords(
      longestDistance: 0.0,
      longestDuration: 0,
      fastestPace: 0.0,
      highestElevation: 0.0,
      maxHeartRate: 0,
    );
  }
}

@JsonSerializable()
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange({
    required this.startDate,
    required this.endDate,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) =>
      _$DateRangeFromJson(json);

  Map<String, dynamic> toJson() => _$DateRangeToJson(this);

  int get days => endDate.difference(startDate).inDays;
}

@JsonSerializable()
class PerformanceInsight {
  final String id;
  final InsightType type;
  final String title;
  final String message;
  final String metric;
  final double value;
  final DateTime createdAt;
  final bool isRead;

  PerformanceInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.metric,
    required this.value,
    required this.createdAt,
    this.isRead = false,
  });

  factory PerformanceInsight.fromJson(Map<String, dynamic> json) =>
      _$PerformanceInsightFromJson(json);

  Map<String, dynamic> toJson() => _$PerformanceInsightToJson(this);

  PerformanceInsight copyWith({
    String? id,
    InsightType? type,
    String? title,
    String? message,
    String? metric,
    double? value,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return PerformanceInsight(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      metric: metric ?? this.metric,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

@JsonSerializable()
class PerformanceGoal {
  final String id;
  final String metric;
  final double target;
  final double current;
  final DateTime deadline;
  final String? description;
  final DateTime createdAt;
  final bool isCompleted;
  final DateTime? completedAt;

  PerformanceGoal({
    required this.id,
    required this.metric,
    required this.target,
    required this.current,
    required this.deadline,
    this.description,
    required this.createdAt,
    required this.isCompleted,
    this.completedAt,
  });

  factory PerformanceGoal.fromJson(Map<String, dynamic> json) =>
      _$PerformanceGoalFromJson(json);

  Map<String, dynamic> toJson() => _$PerformanceGoalToJson(this);

  PerformanceGoal copyWith({
    String? id,
    String? metric,
    double? target,
    double? current,
    DateTime? deadline,
    String? description,
    DateTime? createdAt,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return PerformanceGoal(
      id: id ?? this.id,
      metric: metric ?? this.metric,
      target: target ?? this.target,
      current: current ?? this.current,
      deadline: deadline ?? this.deadline,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  double get progressPercentage => (current / target) * 100;
  bool get isExpired => DateTime.now().isAfter(deadline);
  int get daysRemaining => deadline.difference(DateTime.now()).inDays;
  bool get isOnTrack => progressPercentage >= (daysRemaining / deadline.difference(createdAt).inDays) * 100;
}
