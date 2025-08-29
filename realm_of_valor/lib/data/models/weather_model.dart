import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'weather_model.g.dart';

enum WeatherCondition {
  clear,
  cloudy,
  rain,
  snow,
  storm,
  fog,
  wind,
  heat,
  cold,
}

enum WeatherSeverity {
  mild,
  moderate,
  severe,
  extreme,
}

@JsonSerializable()
class WeatherData extends Equatable {
  final String condition;
  final double temperature;
  final double humidity;
  final double windSpeed;
  final String windDirection;
  final double pressure;
  final double visibility;
  final DateTime timestamp;
  final String icon;

  const WeatherData({
    required this.condition,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.visibility,
    required this.timestamp,
    required this.icon,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) => _$WeatherDataFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherDataToJson(this);

  @override
  List<Object?> get props => [
    condition,
    temperature,
    humidity,
    windSpeed,
    windDirection,
    pressure,
    visibility,
    timestamp,
    icon,
  ];
}

@JsonSerializable()
class WeatherEffect {
  final String id;
  final String name;
  final String description;
  final WeatherCondition requiredCondition;
  final WeatherSeverity minimumSeverity;
  final Map<String, double> statModifiers;
  final List<String> specialEffects;
  final bool isPositive;

  WeatherEffect({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredCondition,
    required this.minimumSeverity,
    required this.statModifiers,
    required this.specialEffects,
    required this.isPositive,
  });

  factory WeatherEffect.fromJson(Map<String, dynamic> json) => _$WeatherEffectFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherEffectToJson(this);

  bool isActive(WeatherData weather) {
    return weather.condition == requiredCondition.name && 
           false; // severity comparison removed since WeatherData doesn't have severity
  }
}

@JsonSerializable()
class WeatherForecast {
  final String location;
  final List<WeatherData> hourlyForecast;
  final List<WeatherData> dailyForecast;
  final DateTime lastUpdated;

  WeatherForecast({
    required this.location,
    required this.hourlyForecast,
    required this.dailyForecast,
    required this.lastUpdated,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) => _$WeatherForecastFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherForecastToJson(this);

  WeatherData get currentWeather {
    return hourlyForecast.first;
  }

  List<WeatherEffect> getActiveEffects(List<WeatherEffect> availableEffects) {
    return availableEffects.where((effect) => effect.isActive(currentWeather)).toList();
  }
}
