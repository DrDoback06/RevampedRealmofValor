import 'fitness_workout.dart';

class WorkoutAnalytics {
  final int totalWorkouts;
  final double totalDistance;
  final Duration totalDuration;
  final int totalCalories;
  final double avgHeartRate;
  final List<double> weeklyDistance;
  final List<double> weeklyDuration;
  final List<double> weeklyCalories;
  final Map<String, dynamic> personalRecords;
  final double fitnessScore;
  final Map<String, int> workoutTypes;
  final List<FitnessWorkout> bestWorkouts;

  const WorkoutAnalytics({
    required this.totalWorkouts,
    required this.totalDistance,
    required this.totalDuration,
    required this.totalCalories,
    required this.avgHeartRate,
    required this.weeklyDistance,
    required this.weeklyDuration,
    required this.weeklyCalories,
    required this.personalRecords,
    required this.fitnessScore,
    required this.workoutTypes,
    required this.bestWorkouts,
  });

  factory WorkoutAnalytics.empty() {
    return const WorkoutAnalytics(
      totalWorkouts: 0,
      totalDistance: 0.0,
      totalDuration: Duration.zero,
      totalCalories: 0,
      avgHeartRate: 0.0,
      weeklyDistance: [],
      weeklyDuration: [],
      weeklyCalories: [],
      personalRecords: {},
      fitnessScore: 0.0,
      workoutTypes: {},
      bestWorkouts: [],
    );
  }

  double get avgDistancePerWorkout => totalWorkouts > 0 ? totalDistance / totalWorkouts : 0.0;
  double get avgDurationPerWorkout => totalWorkouts > 0 ? totalDuration.inMinutes / totalWorkouts : 0.0;
  double get avgCaloriesPerWorkout => totalWorkouts > 0 ? totalCalories / totalWorkouts : 0.0;
  
  bool get hasTrendData => weeklyDistance.isNotEmpty && weeklyDuration.isNotEmpty;
  bool get isImproving => hasTrendData && weeklyDistance.last > weeklyDistance.first;
  
  String get fitnessLevel {
    if (fitnessScore >= 80) return 'Elite';
    if (fitnessScore >= 60) return 'Advanced';
    if (fitnessScore >= 40) return 'Intermediate';
    if (fitnessScore >= 20) return 'Beginner';
    return 'Novice';
  }
  
  String get mostCommonWorkoutType {
    if (workoutTypes.isEmpty) return 'None';
    final sorted = workoutTypes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'total_workouts': totalWorkouts,
      'total_distance': totalDistance,
      'total_duration': totalDuration.inSeconds,
      'total_calories': totalCalories,
      'avg_heart_rate': avgHeartRate,
      'weekly_distance': weeklyDistance,
      'weekly_duration': weeklyDuration,
      'weekly_calories': weeklyCalories,
      'personal_records': personalRecords,
      'fitness_score': fitnessScore,
      'workout_types': workoutTypes,
      'best_workouts': bestWorkouts.map((w) => w.toJson()).toList(),
    };
  }
  
  factory WorkoutAnalytics.fromJson(Map<String, dynamic> json) {
    return WorkoutAnalytics(
      totalWorkouts: json['total_workouts'] as int,
      totalDistance: json['total_distance'] as double,
      totalDuration: Duration(seconds: json['total_duration'] as int),
      totalCalories: json['total_calories'] as int,
      avgHeartRate: json['avg_heart_rate'] as double,
      weeklyDistance: List<double>.from(json['weekly_distance']),
      weeklyDuration: List<double>.from(json['weekly_duration']),
      weeklyCalories: List<double>.from(json['weekly_calories']),
      personalRecords: Map<String, dynamic>.from(json['personal_records']),
      fitnessScore: json['fitness_score'] as double,
      workoutTypes: Map<String, int>.from(json['workout_types']),
      bestWorkouts: (json['best_workouts'] as List)
          .map((w) => FitnessWorkout.fromJson(w))
          .toList(),
    );
  }
}