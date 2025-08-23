import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_of_valor/services/agents/location_services_agent.dart';
import 'package:realm_of_valor/services/event_bus.dart';

void main() {
  test('Location mock publishes updates and geofence enter triggers quest event', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);
    final agent = LocationServicesAgent(bus, updateInterval: const Duration(milliseconds: 50));
    await agent.initialize();

    final loc = Completer<Event>();
    bus.subscribe('location_update', (e, b) => loc.complete(e));

    bus.publish(Event(type: 'location.mock', data: {'lat': 37.7749, 'lon': -122.4194}));

    await loc.future.timeout(const Duration(seconds: 2));

    final entered = Completer<Event>();
    bus.subscribe('quest.location_reached', (e, b) => entered.complete(e));

    bus.publish(Event(type: 'location.add_geofence', data: {'id': 'poi1', 'lat': 37.7749, 'lon': -122.4194, 'radius_m': 50.0}));

    // Apply mock again to trigger check
    bus.publish(Event(type: 'location.mock', data: {'lat': 37.7749, 'lon': -122.4194}));

    await entered.future.timeout(const Duration(seconds: 2));
  });
}