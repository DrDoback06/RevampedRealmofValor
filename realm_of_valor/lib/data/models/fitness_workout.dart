import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'fitness_workout.g.dart';

enum WorkoutType {
  run,
  walk,
  hike,
  bike,
  swim,
  gym,
  yoga,
  other,
}

@JsonSerializable()
class FitnessWorkout extends Equatable {
  final String id;
  final String name;
  final WorkoutType type;
  final int startTime; // Unix timestamp
  final int duration; // Duration in seconds
  final double distance; // Distance in meters
  final int calories;
  final double? averageSpeed;
  final double? maxSpeed;
  final double? averageHeartRate;
  final double? maxHeartRate;
  final double? elevationGain;
  final String? description;
  final Map<String, dynamic>? metadata;

  const FitnessWorkout({
    required this.id,
    required this.name,
    required this.type,
    required this.startTime,
    required this.duration,
    required this.distance,
    required this.calories,
    this.averageSpeed,
    this.maxSpeed,
    this.averageHeartRate,
    this.maxHeartRate,
    this.elevationGain,
    this.description,
    this.metadata,
  });

  factory FitnessWorkout.fromJson(Map<String, dynamic> json) => _$FitnessWorkoutFromJson(json);
  Map<String, dynamic> toJson() => _$FitnessWorkoutToJson(this);

  /// Create a FitnessWorkout from Strava activity data
  factory FitnessWorkout.fromStrava(Map<String, dynamic> activity) {
    WorkoutType workoutType;
    switch (activity['type']) {
      case 'Run':
        workoutType = WorkoutType.run;
        break;
      case 'Walk':
        workoutType = WorkoutType.walk;
        break;
      case 'Hike':
        workoutType = WorkoutType.hike;
        break;
      case 'Ride':
        workoutType = WorkoutType.bike;
        break;
      case 'Swim':
        workoutType = WorkoutType.swim;
        break;
      case 'Workout':
        workoutType = WorkoutType.gym;
        break;
      case 'Yoga':
        workoutType = WorkoutType.yoga;
        break;
      default:
        workoutType = WorkoutType.other;
    }

    return FitnessWorkout(
      id: activity['id'].toString(),
      name: activity['name'] ?? 'Untitled Activity',
      type: workoutType,
      startTime: activity['start_date_unix'] ?? 0,
      duration: activity['moving_time'] ?? 0,
      distance: (activity['distance'] ?? 0).toDouble(),
      calories: activity['calories'] ?? 0,
      averageSpeed: activity['average_speed']?.toDouble(),
      maxSpeed: activity['max_speed']?.toDouble(),
      averageHeartRate: activity['average_heartrate']?.toDouble(),
      maxHeartRate: activity['max_heartrate']?.toDouble(),
      elevationGain: activity['total_elevation_gain']?.toDouble(),
      description: activity['description'],
      metadata: {
        'strava_id': activity['id'],
        'external_id': activity['external_id'],
        'upload_id': activity['upload_id'],
        'athlete_id': activity['athlete']['id'],
        'map': activity['map'],
        'gear_id': activity['gear_id'],
        'trainer': activity['trainer'],
        'commute': activity['commute'],
        'manual': activity['manual'],
        'private': activity['private'],
        'flagged': activity['flagged'],
        'workout_type': activity['workout_type'],
        'average_cadence': activity['average_cadence'],
        'average_temp': activity['average_temp'],
        'average_watts': activity['average_watts'],
        'weighted_average_watts': activity['weighted_average_watts'],
        'kilojoules': activity['kilojoules'],
        'device_watts': activity['device_watts'],
        'has_heartrate': activity['has_heartrate'],
        'elev_high': activity['elev_high'],
        'elev_low': activity['elev_low'],
        'photo_count': activity['photo_count'],
        'has_kudoed': activity['has_kudoed'],
        'suffer_score': activity['suffer_score'],
      },
    );
  }

  /// Get formatted duration string
  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Get formatted distance string
  String get formattedDistance {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    } else {
      return '${distance.toStringAsFixed(0)} m';
    }
  }

  /// Get formatted date string
  String get formattedDate {
    final date = DateTime.fromMillisecondsSinceEpoch(startTime * 1000);
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get formatted time string
  String get formattedTime {
    final date = DateTime.fromMillisecondsSinceEpoch(startTime * 1000);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Get workout type icon
  String get typeIcon {
    switch (type) {
      case WorkoutType.run:
        return '🏃';
      case WorkoutType.walk:
        return '🚶';
      case WorkoutType.hike:
        return '🥾';
      case WorkoutType.bike:
        return '🚴';
      case WorkoutType.swim:
        return '🏊';
      case WorkoutType.gym:
        return '💪';
      case WorkoutType.yoga:
        return '🧘';
      case WorkoutType.other:
        return '🏃';
    }
  }

  /// Get workout type name
  String get typeName {
    switch (type) {
      case WorkoutType.run:
        return 'Run';
      case WorkoutType.walk:
        return 'Walk';
      case WorkoutType.hike:
        return 'Hike';
      case WorkoutType.bike:
        return 'Bike';
      case WorkoutType.swim:
        return 'Swim';
      case WorkoutType.gym:
        return 'Gym';
      case WorkoutType.yoga:
        return 'Yoga';
      case WorkoutType.other:
        return 'Other';
    }
  }

  /// Calculate XP based on workout intensity
  int get calculatedXp {
    int baseXp = 10;
    
    // Distance bonus
    if (distance > 5000) { // 5km
      baseXp += 20;
    }
    if (distance > 10000) { // 10km
      baseXp += 30;
    }
    
    // Duration bonus
    if (duration > 1800) { // 30 minutes
      baseXp += 15;
    }
    if (duration > 3600) { // 1 hour
      baseXp += 25;
    }
    
    // Type bonus
    switch (type) {
      case WorkoutType.run:
        baseXp += 10;
        break;
      case WorkoutType.bike:
        baseXp += 8;
        break;
      case WorkoutType.swim:
        baseXp += 15;
        break;
      case WorkoutType.gym:
        baseXp += 5;
        break;
      default:
        baseXp += 3;
    }
    
    return baseXp;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    startTime,
    duration,
    distance,
    calories,
    averageSpeed,
    maxSpeed,
    averageHeartRate,
    maxHeartRate,
    elevationGain,
    description,
  ];
}
