abstract class WeatherService {
  Future<Map<String, dynamic>> currentWeather({required double lat, required double lon});
}

class StubWeatherService implements WeatherService {
  @override
  Future<Map<String, dynamic>> currentWeather({required double lat, required double lon}) async {
    return {'condition': 'Clear', 'temp_c': 20.0};
  }
}