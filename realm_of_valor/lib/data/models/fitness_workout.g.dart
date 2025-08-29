// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fitness_workout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FitnessWorkout _$FitnessWorkoutFromJson(Map<String, dynamic> json) =>
    FitnessWorkout(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$WorkoutTypeEnumMap, json['type']),
      startTime: (json['startTime'] as num).toInt(),
      duration: (json['duration'] as num).toInt(),
      distance: (json['distance'] as num).toDouble(),
      calories: (json['calories'] as num).toInt(),
      averageSpeed: (json['averageSpeed'] as num?)?.toDouble(),
      maxSpeed: (json['maxSpeed'] as num?)?.toDouble(),
      averageHeartRate: (json['averageHeartRate'] as num?)?.toDouble(),
      maxHeartRate: (json['maxHeartRate'] as num?)?.toDouble(),
      elevationGain: (json['elevationGain'] as num?)?.toDouble(),
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$FitnessWorkoutToJson(FitnessWorkout instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$WorkoutTypeEnumMap[instance.type]!,
      'startTime': instance.startTime,
      'duration': instance.duration,
      'distance': instance.distance,
      'calories': instance.calories,
      'averageSpeed': instance.averageSpeed,
      'maxSpeed': instance.maxSpeed,
      'averageHeartRate': instance.averageHeartRate,
      'maxHeartRate': instance.maxHeartRate,
      'elevationGain': instance.elevationGain,
      'description': instance.description,
      'metadata': instance.metadata,
    };

const _$WorkoutTypeEnumMap = {
  WorkoutType.run: 'run',
  WorkoutType.walk: 'walk',
  WorkoutType.hike: 'hike',
  WorkoutType.bike: 'bike',
  WorkoutType.swim: 'swim',
  WorkoutType.gym: 'gym',
  WorkoutType.yoga: 'yoga',
  WorkoutType.other: 'other',
};
