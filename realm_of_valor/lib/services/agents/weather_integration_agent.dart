import '../../integration/weather_service.dart';
import '../base_agent.dart';
import '../event_bus.dart';

class WeatherIntegrationAgent extends BaseAgent {
  WeatherIntegrationAgent(super.bus, {required this.service});

  final WeatherService service;
  double? _lastLat;
  double? _lastLon;

  @override
  String get name => 'WeatherIntegration';

  @override
  Future<void> onInitialize() async {
    bus.subscribe('location_update', (evt, b) async {
      final lat = (evt.data?['lat'] as num?)?.toDouble();
      final lon = (evt.data?['lon'] as num?)?.toDouble();
      if (lat == null || lon == null) return;
      final movedFar = _lastLat == null || _distanceKm(_lastLat!, _lastLon!, lat, lon) > 1.0;
      _lastLat = lat;
      _lastLon = lon;
      if (movedFar) {
        final w = await service.currentWeather(lat: lat, lon: lon);
        b.publish(Event(type: 'weather_changed', data: w));
      }
    });
  }

  @override
  Future<void> onDispose() async {}

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    final dx = lat2 - lat1;
    final dy = lon2 - lon1;
    return (dx.abs() + dy.abs()) * 111.0; // rough estimate for small deltas
  }
}
