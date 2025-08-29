import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/weather_service.dart';
import '../../../core/config.dart';
import '../../../data/models/weather_model.dart';

// Weather Service Provider
final weatherServiceProvider = Provider<WeatherService>((ref) {
  final key = AppConfig.openWeatherApiKey;
  if (key.isNotEmpty) {
    return OpenWeatherMapService(apiKey: key);
  }
  return MockWeatherService();
});

// Current Weather Provider
final currentWeatherProvider = FutureProvider<WeatherData>((ref) async {
  final weatherService = ref.watch(weatherServiceProvider);
  // Use Wootton, Northampton coordinates
  return await weatherService.getCurrentWeather(52.2053, -0.9069);
});

// Weather Forecast Provider
final weatherForecastProvider = FutureProvider<WeatherForecast>((ref) async {
  final weatherService = ref.watch(weatherServiceProvider);
  // Use Wootton, Northampton coordinates
  return await weatherService.getWeatherForecast(52.2053, -0.9069);
});

// Weather Effects Provider
final weatherEffectsProvider = FutureProvider<List<WeatherEffect>>((ref) async {
  final weatherService = ref.watch(weatherServiceProvider);
  return await weatherService.getWeatherEffects();
});

// Active Weather Effects Provider
final activeWeatherEffectsProvider = Provider<List<WeatherEffect>>((ref) {
  final currentWeatherAsync = ref.watch(currentWeatherProvider);
  final weatherEffectsAsync = ref.watch(weatherEffectsProvider);

  return currentWeatherAsync.when(
    data: (currentWeather) {
      return weatherEffectsAsync.when(
        data: (effects) {
          return effects.where((effect) => effect.isActive(currentWeather)).toList();
        },
        loading: () => [],
        error: (_, __) => [],
      );
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Weather Impact on Character Stats Provider
final weatherImpactProvider = Provider<Map<String, double>>((ref) {
  final activeEffects = ref.watch(activeWeatherEffectsProvider);
  final impact = <String, double>{};

  for (final effect in activeEffects) {
    for (final modifier in effect.statModifiers.entries) {
      final currentValue = impact[modifier.key] ?? 1.0;
      impact[modifier.key] = currentValue * modifier.value;
    }
  }

  return impact;
});

// Weather Status Provider
final weatherStatusProvider = Provider<WeatherStatus>((ref) {
  final currentWeatherAsync = ref.watch(currentWeatherProvider);
  final activeEffects = ref.watch(activeWeatherEffectsProvider);

  return currentWeatherAsync.when(
    data: (weather) {
      final positiveEffects = activeEffects.where((e) => e.isPositive).length;
      final negativeEffects = activeEffects.where((e) => !e.isPositive).length;

      return WeatherStatus(
        weather: weather,
        activeEffects: activeEffects,
        positiveEffects: positiveEffects,
        negativeEffects: negativeEffects,
        affectsGameplay: true, // Weather always affects gameplay in this app
      );
    },
    loading: () => WeatherStatus.loading(),
    error: (_, __) => WeatherStatus.error(),
  );
});

// Weather Refresh Provider
final weatherRefreshProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Weather Refresh Action
final weatherRefreshActionProvider = Provider((ref) {
  return () {
    ref.read(weatherRefreshProvider.notifier).state = DateTime.now();
  };
});

class WeatherStatus {
  final WeatherData? weather;
  final List<WeatherEffect> activeEffects;
  final int positiveEffects;
  final int negativeEffects;
  final bool affectsGameplay;
  final bool isLoading;
  final bool hasError;

  WeatherStatus({
    this.weather,
    required this.activeEffects,
    required this.positiveEffects,
    required this.negativeEffects,
    required this.affectsGameplay,
    this.isLoading = false,
    this.hasError = false,
  });

  factory WeatherStatus.loading() {
    return WeatherStatus(
      activeEffects: [],
      positiveEffects: 0,
      negativeEffects: 0,
      affectsGameplay: false,
      isLoading: true,
    );
  }

  factory WeatherStatus.error() {
    return WeatherStatus(
      activeEffects: [],
      positiveEffects: 0,
      negativeEffects: 0,
      affectsGameplay: false,
      hasError: true,
    );
  }

  bool get hasActiveEffects => activeEffects.isNotEmpty;
  bool get hasPositiveEffects => positiveEffects > 0;
  bool get hasNegativeEffects => negativeEffects > 0;
}
