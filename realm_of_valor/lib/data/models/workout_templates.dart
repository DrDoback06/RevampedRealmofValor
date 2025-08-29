import 'package:json_annotation/json_annotation.dart';

part 'workout_templates.g.dart';

enum WorkoutType {
  running,
  cycling,
  swimming,
  walking,
  hiking,
  strength,
  yoga,
  pilates,
  crossfit,
  other,
}

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}

enum SegmentType {
  warmup,
  workout,
  cooldown,
  rest,
  interval,
  tempo,
  endurance,
}

@JsonSerializable()
class WorkoutSegment {
  final String id;
  final String name;
  final SegmentType type;
  final int duration; // seconds
  final double? targetDistance; // km
  final double? targetPace; // min/km
  final int? targetHeartRate; // bpm
  final String? instructions;
  final Map<String, dynamic>? parameters;

  WorkoutSegment({
    required this.id,
    required this.name,
    required this.type,
    required this.duration,
    this.targetDistance,
    this.targetPace,
    this.targetHeartRate,
    this.instructions,
    this.parameters,
  });

  factory WorkoutSegment.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSegmentFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutSegmentToJson(this);

  WorkoutSegment copyWith({
    String? id,
    String? name,
    SegmentType? type,
    int? duration,
    double? targetDistance,
    double? targetPace,
    int? targetHeartRate,
    String? instructions,
    Map<String, dynamic>? parameters,
  }) {
    return WorkoutSegment(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      targetDistance: targetDistance ?? this.targetDistance,
      targetPace: targetPace ?? this.targetPace,
      targetHeartRate: targetHeartRate ?? this.targetHeartRate,
      instructions: instructions ?? this.instructions,
      parameters: parameters ?? this.parameters,
    );
  }
}

@JsonSerializable()
class WorkoutTemplate {
  final String id;
  final String name;
  final String description;
  final WorkoutType type;
  final int targetDuration; // seconds
  final double targetDistance; // km
  final int targetCalories;
  final List<WorkoutSegment> segments;
  final DifficultyLevel difficulty;
  final String? notes;
  final DateTime createdAt;
  final int usageCount;
  final double averageRating;
  final List<TemplateRating> ratings;
  final bool isFavorite;
  final String? creatorId;
  final bool isPublic;

  WorkoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.targetDuration,
    required this.targetDistance,
    required this.targetCalories,
    required this.segments,
    required this.difficulty,
    this.notes,
    required this.createdAt,
    required this.usageCount,
    required this.averageRating,
    required this.ratings,
    this.isFavorite = false,
    this.creatorId,
    this.isPublic = true,
  });

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) =>
      _$WorkoutTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutTemplateToJson(this);

  WorkoutTemplate copyWith({
    String? id,
    String? name,
    String? description,
    WorkoutType? type,
    int? targetDuration,
    double? targetDistance,
    int? targetCalories,
    List<WorkoutSegment>? segments,
    DifficultyLevel? difficulty,
    String? notes,
    DateTime? createdAt,
    int? usageCount,
    double? averageRating,
    List<TemplateRating>? ratings,
    bool? isFavorite,
    String? creatorId,
    bool? isPublic,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      targetDuration: targetDuration ?? this.targetDuration,
      targetDistance: targetDistance ?? this.targetDistance,
      targetCalories: targetCalories ?? this.targetCalories,
      segments: segments ?? this.segments,
      difficulty: difficulty ?? this.difficulty,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      usageCount: usageCount ?? this.usageCount,
      averageRating: averageRating ?? this.averageRating,
      ratings: ratings ?? this.ratings,
      isFavorite: isFavorite ?? this.isFavorite,
      creatorId: creatorId ?? this.creatorId,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}

@JsonSerializable()
class TemplateRating {
  final String id;
  final String userId;
  final double rating; // 1-5 stars
  final String? review;
  final DateTime createdAt;

  TemplateRating({
    required this.id,
    required this.userId,
    required this.rating,
    this.review,
    required this.createdAt,
  });

  factory TemplateRating.fromJson(Map<String, dynamic> json) =>
      _$TemplateRatingFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateRatingToJson(this);
}

@JsonSerializable()
class RoutineDay {
  final int dayOfWeek; // 1-7
  final String? templateId;
  final WorkoutType? workoutType;
  final int? duration; // seconds
  final double? distance; // km
  final String? notes;
  final bool isRestDay;

  RoutineDay({
    required this.dayOfWeek,
    this.templateId,
    this.workoutType,
    this.duration,
    this.distance,
    this.notes,
    this.isRestDay = false,
  });

  factory RoutineDay.fromJson(Map<String, dynamic> json) =>
      _$RoutineDayFromJson(json);

  Map<String, dynamic> toJson() => _$RoutineDayToJson(this);
}

@JsonSerializable()
class WorkoutRoutine {
  final String id;
  final String name;
  final String description;
  final List<RoutineDay> days;
  final int durationWeeks;
  final String? notes;
  final DateTime createdAt;
  final DateTime? startDate;
  final int currentWeek;
  final int currentDay;
  final List<String> completedWorkouts;
  final bool isActive;

  WorkoutRoutine({
    required this.id,
    required this.name,
    required this.description,
    required this.days,
    required this.durationWeeks,
    this.notes,
    required this.createdAt,
    this.startDate,
    required this.currentWeek,
    required this.currentDay,
    required this.completedWorkouts,
    required this.isActive,
  });

  factory WorkoutRoutine.fromJson(Map<String, dynamic> json) =>
      _$WorkoutRoutineFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutRoutineToJson(this);

  WorkoutRoutine copyWith({
    String? id,
    String? name,
    String? description,
    List<RoutineDay>? days,
    int? durationWeeks,
    String? notes,
    DateTime? createdAt,
    DateTime? startDate,
    int? currentWeek,
    int? currentDay,
    List<String>? completedWorkouts,
    bool? isActive,
  }) {
    return WorkoutRoutine(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      days: days ?? this.days,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      currentWeek: currentWeek ?? this.currentWeek,
      currentDay: currentDay ?? this.currentDay,
      completedWorkouts: completedWorkouts ?? this.completedWorkouts,
      isActive: isActive ?? this.isActive,
    );
  }
}
