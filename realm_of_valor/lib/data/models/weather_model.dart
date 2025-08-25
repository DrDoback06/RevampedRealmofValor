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
class WeatherData {
  final double temperature;
  final double humidity;
  final double windSpeed;
  final WeatherCondition condition;
  final WeatherSeverity severity;
  final String location;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.severity,
    required this.location,
    required this.timestamp,
    this.additionalData,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) => _$WeatherDataFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherDataToJson(this);

  WeatherData copyWith({
    double? temperature,
    double? humidity,
    double? windSpeed,
    WeatherCondition? condition,
    WeatherSeverity? severity,
    String? location,
    DateTime? timestamp,
    Map<String, dynamic>? additionalData,
  }) {
    return WeatherData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      condition: condition ?? this.condition,
      severity: severity ?? this.severity,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  String get conditionIcon {
    switch (condition) {
      case WeatherCondition.clear:
        return '☀️';
      case WeatherCondition.cloudy:
        return '☁️';
      case WeatherCondition.rain:
        return '🌧️';
      case WeatherCondition.snow:
        return '❄️';
      case WeatherCondition.storm:
        return '⛈️';
      case WeatherCondition.fog:
        return '🌫️';
      case WeatherCondition.wind:
        return '💨';
      case WeatherCondition.heat:
        return '🔥';
      case WeatherCondition.cold:
        return '🥶';
    }
  }

  String get severityColor {
    switch (severity) {
      case WeatherSeverity.mild:
        return '#4CAF50';
      case WeatherSeverity.moderate:
        return '#FF9800';
      case WeatherSeverity.severe:
        return '#F44336';
      case WeatherSeverity.extreme:
        return '#9C27B0';
    }
  }

  bool get affectsGameplay {
    return severity == WeatherSeverity.severe || severity == WeatherSeverity.extreme;
  }
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
    return weather.condition == requiredCondition && 
           weather.severity.index >= minimumSeverity.index;
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
