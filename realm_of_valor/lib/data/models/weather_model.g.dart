// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeatherData _$WeatherDataFromJson(Map<String, dynamic> json) => WeatherData(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      condition: $enumDecode(_$WeatherConditionEnumMap, json['condition']),
      severity: $enumDecode(_$WeatherSeverityEnumMap, json['severity']),
      location: json['location'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$WeatherDataToJson(WeatherData instance) =>
    <String, dynamic>{
      'temperature': instance.temperature,
      'humidity': instance.humidity,
      'windSpeed': instance.windSpeed,
      'condition': _$WeatherConditionEnumMap[instance.condition]!,
      'severity': _$WeatherSeverityEnumMap[instance.severity]!,
      'location': instance.location,
      'timestamp': instance.timestamp.toIso8601String(),
      'additionalData': instance.additionalData,
    };

const _$WeatherConditionEnumMap = {
  WeatherCondition.clear: 'clear',
  WeatherCondition.cloudy: 'cloudy',
  WeatherCondition.rain: 'rain',
  WeatherCondition.snow: 'snow',
  WeatherCondition.storm: 'storm',
  WeatherCondition.fog: 'fog',
  WeatherCondition.wind: 'wind',
  WeatherCondition.heat: 'heat',
  WeatherCondition.cold: 'cold',
};

const _$WeatherSeverityEnumMap = {
  WeatherSeverity.mild: 'mild',
  WeatherSeverity.moderate: 'moderate',
  WeatherSeverity.severe: 'severe',
  WeatherSeverity.extreme: 'extreme',
};

WeatherEffect _$WeatherEffectFromJson(Map<String, dynamic> json) =>
    WeatherEffect(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      requiredCondition:
          $enumDecode(_$WeatherConditionEnumMap, json['requiredCondition']),
      minimumSeverity:
          $enumDecode(_$WeatherSeverityEnumMap, json['minimumSeverity']),
      statModifiers: (json['statModifiers'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      specialEffects: (json['specialEffects'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isPositive: json['isPositive'] as bool,
    );

Map<String, dynamic> _$WeatherEffectToJson(WeatherEffect instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'requiredCondition':
          _$WeatherConditionEnumMap[instance.requiredCondition]!,
      'minimumSeverity': _$WeatherSeverityEnumMap[instance.minimumSeverity]!,
      'statModifiers': instance.statModifiers,
      'specialEffects': instance.specialEffects,
      'isPositive': instance.isPositive,
    };

WeatherForecast _$WeatherForecastFromJson(Map<String, dynamic> json) =>
    WeatherForecast(
      location: json['location'] as String,
      hourlyForecast: (json['hourlyForecast'] as List<dynamic>)
          .map((e) => WeatherData.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyForecast: (json['dailyForecast'] as List<dynamic>)
          .map((e) => WeatherData.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$WeatherForecastToJson(WeatherForecast instance) =>
    <String, dynamic>{
      'location': instance.location,
      'hourlyForecast': instance.hourlyForecast,
      'dailyForecast': instance.dailyForecast,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };
