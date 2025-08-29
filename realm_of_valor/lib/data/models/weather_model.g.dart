// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeatherData _$WeatherDataFromJson(Map<String, dynamic> json) => WeatherData(
      condition: json['condition'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      windDirection: json['windDirection'] as String,
      pressure: (json['pressure'] as num).toDouble(),
      visibility: (json['visibility'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      icon: json['icon'] as String,
    );

Map<String, dynamic> _$WeatherDataToJson(WeatherData instance) =>
    <String, dynamic>{
      'condition': instance.condition,
      'temperature': instance.temperature,
      'humidity': instance.humidity,
      'windSpeed': instance.windSpeed,
      'windDirection': instance.windDirection,
      'pressure': instance.pressure,
      'visibility': instance.visibility,
      'timestamp': instance.timestamp.toIso8601String(),
      'icon': instance.icon,
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
