import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_of_valor/integration/weather_service.dart';
import 'package:realm_of_valor/services/agents/weather_integration_agent.dart';
import 'package:realm_of_valor/services/event_bus.dart';

class FakeWeather implements WeatherService {
  @override
  Future<Map<String, dynamic>> currentWeather({required double lat, required double lon}) async {
    return {'condition': 'Rain', 'temp_c': 12.3};
  }
}

void main() {
  test('Emits weather_changed on location_update', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);
    final agent = WeatherIntegrationAgent(bus, service: FakeWeather());
    await agent.initialize();

    final changed = Completer<Event>();
    bus.subscribe('weather_changed', (e, b) => changed.complete(e));

    bus.publish(Event(type: 'location_update', data: {'lat': 10.0, 'lon': 20.0}));

    final evt = await changed.future.timeout(const Duration(seconds: 2));
    expect(evt.data?['condition'], 'Rain');
  });
}
