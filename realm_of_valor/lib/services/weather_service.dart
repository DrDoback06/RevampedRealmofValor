import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/weather_model.dart';

abstract class WeatherService {
  Future<WeatherData> getCurrentWeather(double latitude, double longitude);
  Future<WeatherForecast> getWeatherForecast(double latitude, double longitude);
  Future<List<WeatherEffect>> getWeatherEffects();
}

class OpenWeatherMapService implements WeatherService {
  final String apiKey;
  final http.Client _client;

  OpenWeatherMapService({required this.apiKey}) : _client = http.Client();

  @override
  Future<WeatherData> getCurrentWeather(double latitude, double longitude) async {
    try {
      final response = await _client.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?'
          'lat=$latitude&lon=$longitude&appid=$apiKey&units=metric',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseWeatherData(data);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for development
      return _getMockWeatherData();
    }
  }

  @override
  Future<WeatherForecast> getWeatherForecast(double latitude, double longitude) async {
    try {
      final response = await _client.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?'
          'lat=$latitude&lon=$longitude&appid=$apiKey&units=metric',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseWeatherForecast(data);
      } else {
        throw Exception('Failed to load weather forecast: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for development
      return _getMockWeatherForecast();
    }
  }

  @override
  Future<List<WeatherEffect>> getWeatherEffects() async {
    // Return predefined weather effects
    return [
      WeatherEffect(
        id: 'storm_power',
        name: 'Storm Power',
        description: 'Lightning strikes enhance your magical abilities',
        requiredCondition: WeatherCondition.storm,
        minimumSeverity: WeatherSeverity.moderate,
        statModifiers: {'magic_power': 1.5, 'mana_regen': 2.0},
        specialEffects: ['Lightning strikes deal bonus damage'],
        isPositive: true,
      ),
      WeatherEffect(
        id: 'rain_healing',
        name: 'Rain Healing',
        description: 'The rain provides natural healing properties',
        requiredCondition: WeatherCondition.rain,
        minimumSeverity: WeatherSeverity.mild,
        statModifiers: {'health_regen': 1.3, 'healing_power': 1.2},
        specialEffects: ['Natural healing is enhanced'],
        isPositive: true,
      ),
      WeatherEffect(
        id: 'heat_exhaustion',
        name: 'Heat Exhaustion',
        description: 'Extreme heat weakens your physical abilities',
        requiredCondition: WeatherCondition.heat,
        minimumSeverity: WeatherSeverity.severe,
        statModifiers: {'strength': 0.7, 'stamina': 0.8},
        specialEffects: ['Physical attacks are weakened'],
        isPositive: false,
      ),
      WeatherEffect(
        id: 'cold_resistance',
        name: 'Cold Resistance',
        description: 'You have adapted to the cold weather',
        requiredCondition: WeatherCondition.cold,
        minimumSeverity: WeatherSeverity.moderate,
        statModifiers: {'defense': 1.2, 'ice_resistance': 1.5},
        specialEffects: ['Ice damage is reduced'],
        isPositive: true,
      ),
      WeatherEffect(
        id: 'wind_agility',
        name: 'Wind Agility',
        description: 'The wind enhances your movement and agility',
        requiredCondition: WeatherCondition.wind,
        minimumSeverity: WeatherSeverity.mild,
        statModifiers: {'agility': 1.3, 'movement_speed': 1.2},
        specialEffects: ['Dodge chance increased'],
        isPositive: true,
      ),
      WeatherEffect(
        id: 'fog_stealth',
        name: 'Fog Stealth',
        description: 'The fog provides natural stealth advantages',
        requiredCondition: WeatherCondition.fog,
        minimumSeverity: WeatherSeverity.moderate,
        statModifiers: {'stealth': 1.4, 'critical_chance': 1.2},
        specialEffects: ['Stealth abilities enhanced'],
        isPositive: true,
      ),
    ];
  }

  WeatherData _parseWeatherData(Map<String, dynamic> data) {
    final main = data['main'];
    final weather = data['weather'][0];
    final wind = data['wind'];

    final condition = _mapWeatherCondition(weather['main']);

    return WeatherData(
      temperature: main['temp'].toDouble(),
      humidity: main['humidity'].toDouble(),
      windSpeed: wind['speed'].toDouble(),
      windDirection: wind['deg']?.toString() ?? 'N',
      pressure: main['pressure']?.toDouble() ?? 1013.25,
      visibility: data['visibility']?.toDouble() ?? 10000.0,
      condition: condition.name,
      timestamp: DateTime.now(),
      icon: weather['icon'] ?? '01d',
    );
  }

  WeatherForecast _parseWeatherForecast(Map<String, dynamic> data) {
    final location = data['city']['name'];
    final list = data['list'] as List;

    final hourlyForecast = list.take(24).map((item) {
      final main = item['main'];
      final weather = item['weather'][0];
      final wind = item['wind'];

      final condition = _mapWeatherCondition(weather['main']);

      return WeatherData(
        temperature: main['temp'].toDouble(),
        humidity: main['humidity'].toDouble(),
        windSpeed: wind['speed'].toDouble(),
        windDirection: wind['deg']?.toString() ?? 'N',
        pressure: main['pressure']?.toDouble() ?? 1013.25,
        visibility: item['visibility']?.toDouble() ?? 10000.0,
        condition: condition.name,
        timestamp: DateTime.parse(item['dt_txt']),
        icon: weather['icon'] ?? '01d',
      );
    }).toList();

    return WeatherForecast(
      location: location,
      hourlyForecast: hourlyForecast,
      dailyForecast: hourlyForecast.asMap().entries.where((entry) => entry.key % 8 == 0).map((entry) => entry.value).toList(),
      lastUpdated: DateTime.now(),
    );
  }

  WeatherCondition _mapWeatherCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return WeatherCondition.clear;
      case 'clouds':
        return WeatherCondition.cloudy;
      case 'rain':
      case 'drizzle':
        return WeatherCondition.rain;
      case 'snow':
        return WeatherCondition.snow;
      case 'thunderstorm':
        return WeatherCondition.storm;
      case 'mist':
      case 'fog':
        return WeatherCondition.fog;
      default:
        return WeatherCondition.clear;
    }
  }

  WeatherData _getMockWeatherData() {
    return WeatherData(
      temperature: 18.5,
      humidity: 65.0,
      windSpeed: 8.2,
      windDirection: 'N',
      pressure: 1013.25,
      visibility: 10000.0,
      condition: WeatherCondition.cloudy.name,
      timestamp: DateTime.now(),
      icon: '02d',
    );
  }

  WeatherForecast _getMockWeatherForecast() {
    final mockHourly = List.generate(24, (index) {
      return WeatherData(
        temperature: 15 + (index % 10),
        humidity: 60 + (index % 20),
        windSpeed: 5 + (index % 8),
        windDirection: 'N',
        pressure: 1013.25,
        visibility: 10000.0,
        condition: WeatherCondition.values[index % WeatherCondition.values.length].name,
        timestamp: DateTime.now().add(Duration(hours: index)),
        icon: '01d',
      );
    });

    return WeatherForecast(
      location: 'Wootton, Northampton',
      hourlyForecast: mockHourly,
      dailyForecast: mockHourly.asMap().entries.where((entry) => entry.key % 8 == 0).map((entry) => entry.value).toList(),
      lastUpdated: DateTime.now(),
    );
  }
}

class MockWeatherService implements WeatherService {
  @override
  Future<WeatherData> getCurrentWeather(double latitude, double longitude) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    return WeatherData(
      temperature: 18.5,
      humidity: 65.0,
      windSpeed: 8.2,
      windDirection: 'N',
      pressure: 1013.25,
      visibility: 10000.0,
      condition: WeatherCondition.cloudy.name,
      timestamp: DateTime.now(),
      icon: '02d',
    );
  }

  @override
  Future<WeatherForecast> getWeatherForecast(double latitude, double longitude) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    final mockHourly = List.generate(24, (index) {
      return WeatherData(
        temperature: 15 + (index % 10),
        humidity: 60 + (index % 20),
        windSpeed: 5 + (index % 8),
        windDirection: 'N',
        pressure: 1013.25,
        visibility: 10000.0,
        condition: WeatherCondition.values[index % WeatherCondition.values.length].name,
        timestamp: DateTime.now().add(Duration(hours: index)),
        icon: '01d',
      );
    });

    return WeatherForecast(
      location: 'Wootton, Northampton',
      hourlyForecast: mockHourly,
      dailyForecast: mockHourly.asMap().entries.where((entry) => entry.key % 8 == 0).map((entry) => entry.value).toList(),
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<List<WeatherEffect>> getWeatherEffects() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    return [
      WeatherEffect(
        id: 'storm_power',
        name: 'Storm Power',
        description: 'Lightning strikes enhance your magical abilities',
        requiredCondition: WeatherCondition.storm,
        minimumSeverity: WeatherSeverity.moderate,
        statModifiers: {'magic_power': 1.5, 'mana_regen': 2.0},
        specialEffects: ['Lightning strikes deal bonus damage'],
        isPositive: true,
      ),
      WeatherEffect(
        id: 'rain_healing',
        name: 'Rain Healing',
        description: 'The rain provides natural healing properties',
        requiredCondition: WeatherCondition.rain,
        minimumSeverity: WeatherSeverity.mild,
        statModifiers: {'health_regen': 1.3, 'healing_power': 1.2},
        specialEffects: ['Natural healing is enhanced'],
        isPositive: true,
      ),
    ];
  }
}
