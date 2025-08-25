import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/weather_model.dart';
import 'providers.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  @override
  Widget build(BuildContext context) {
    final weatherStatus = ref.watch(weatherStatusProvider);
    final weatherForecast = ref.watch(weatherForecastProvider);
    final weatherEffects = ref.watch(weatherEffectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(weatherRefreshProvider.notifier).state = DateTime.now();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(weatherRefreshProvider.notifier).state = DateTime.now();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Current Weather Card
              _buildCurrentWeatherCard(weatherStatus),
              
              // Weather Effects Card
              if (weatherStatus.hasActiveEffects)
                _buildWeatherEffectsCard(weatherStatus),
              
              // Hourly Forecast Card
              weatherForecast.when(
                data: (forecast) => _buildHourlyForecastCard(forecast),
                loading: () => _buildLoadingCard('Hourly Forecast'),
                error: (_, __) => _buildErrorCard('Hourly Forecast'),
              ),
              
              // Daily Forecast Card
              weatherForecast.when(
                data: (forecast) => _buildDailyForecastCard(forecast),
                loading: () => _buildLoadingCard('Daily Forecast'),
                error: (_, __) => _buildErrorCard('Daily Forecast'),
              ),
              
              // All Weather Effects Card
              weatherEffects.when(
                data: (effects) => _buildAllEffectsCard(effects),
                loading: () => _buildLoadingCard('Weather Effects'),
                error: (_, __) => _buildErrorCard('Weather Effects'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherCard(WeatherStatus status) {
    if (status.isLoading) {
      return _buildLoadingCard('Current Weather');
    }

    if (status.hasError || status.weather == null) {
      return _buildErrorCard('Current Weather');
    }

    final weather = status.weather!;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getWeatherGradientColor(weather.condition).withOpacity(0.1),
              _getWeatherGradientColor(weather.condition).withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    weather.conditionIcon,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather.location,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          weather.condition.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${weather.temperature.round()}°C',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${weather.humidity.round()}% humidity',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeatherDetail('Wind', '${weather.windSpeed} m/s', Icons.air),
                  _buildWeatherDetail('Severity', weather.severity.name, _getSeverityIcon(weather.severity)),
                  if (status.affectsGameplay)
                    _buildWeatherDetail('Gameplay', 'Affected', Icons.warning, color: Colors.orange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherEffectsCard(WeatherStatus status) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome),
                const SizedBox(width: 8),
                const Text(
                  'Active Weather Effects',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (status.hasPositiveEffects)
                  Icon(Icons.trending_up, color: Colors.green, size: 20),
                if (status.hasNegativeEffects)
                  Icon(Icons.trending_down, color: Colors.red, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            ...status.activeEffects.map((effect) => _buildEffectTile(effect)),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectTile(WeatherEffect effect) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: effect.isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: effect.isPositive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            effect.isPositive ? Icons.trending_up : Icons.trending_down,
            color: effect.isPositive ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  effect.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  effect.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: effect.statModifiers.entries.map((entry) {
                    return Chip(
                      label: Text('${entry.key}: ${entry.value > 1 ? '+' : ''}${((entry.value - 1) * 100).round()}%'),
                      backgroundColor: effect.isPositive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      labelStyle: TextStyle(
                        fontSize: 10,
                        color: effect.isPositive ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecastCard(WeatherForecast forecast) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hourly Forecast',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: forecast.hourlyForecast.length,
                itemBuilder: (context, index) {
                  final weather = forecast.hourlyForecast[index];
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        Text(
                          weather.conditionIcon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        Text(
                          '${weather.temperature.round()}°',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${weather.timestamp.hour}:00',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyForecastCard(WeatherForecast forecast) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Forecast',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...forecast.dailyForecast.map((weather) => _buildDailyForecastTile(weather)),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyForecastTile(WeatherData weather) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            weather.conditionIcon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDayName(weather.timestamp),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  weather.condition.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${weather.temperature.round()}°C',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${weather.humidity.round()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllEffectsCard(List<WeatherEffect> effects) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Weather Effects',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...effects.map((effect) => _buildAllEffectTile(effect)),
          ],
        ),
      ),
    );
  }

  Widget _buildAllEffectTile(WeatherEffect effect) {
    return ListTile(
      leading: Icon(
        effect.isPositive ? Icons.trending_up : Icons.trending_down,
        color: effect.isPositive ? Colors.green : Colors.red,
      ),
      title: Text(effect.name),
      subtitle: Text(effect.description),
      trailing: Chip(
        label: Text('${effect.requiredCondition.name} ${effect.minimumSeverity.name}'),
        backgroundColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(String title) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text('Loading $title...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String title) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 16),
            Text('Error loading $title'),
          ],
        ),
      ),
    );
  }

  Color _getWeatherGradientColor(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.clear:
        return Colors.blue;
      case WeatherCondition.cloudy:
        return Colors.grey;
      case WeatherCondition.rain:
        return Colors.blue.shade700;
      case WeatherCondition.snow:
        return Colors.blue.shade100;
      case WeatherCondition.storm:
        return Colors.purple;
      case WeatherCondition.fog:
        return Colors.grey.shade400;
      case WeatherCondition.wind:
        return Colors.green;
      case WeatherCondition.heat:
        return Colors.orange;
      case WeatherCondition.cold:
        return Colors.blue.shade300;
    }
  }

  IconData _getSeverityIcon(WeatherSeverity severity) {
    switch (severity) {
      case WeatherSeverity.mild:
        return Icons.sentiment_satisfied;
      case WeatherSeverity.moderate:
        return Icons.sentiment_neutral;
      case WeatherSeverity.severe:
        return Icons.sentiment_dissatisfied;
      case WeatherSeverity.extreme:
        return Icons.warning;
    }
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    
    switch (date.weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return 'Unknown';
    }
  }
}
