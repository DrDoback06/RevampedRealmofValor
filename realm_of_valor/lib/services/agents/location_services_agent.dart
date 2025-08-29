import 'dart:async';
import 'dart:math';

import '../base_agent.dart';
import '../event_bus.dart';

class _Geofence {
  _Geofence(this.id, this.lat, this.lon, this.radiusM);
  final String id;
  final double lat;
  final double lon;
  final double radiusM;
  bool inside = false;
}

class LocationServicesAgent extends BaseAgent {
  LocationServicesAgent(super.bus, {this.updateInterval = const Duration(seconds: 10)});

  final Duration updateInterval;
  Timer? _timer;

  double? _lat;
  double? _lon;
  final Map<String, _Geofence> _fences = <String, _Geofence>{};

  @override
  String get name => 'LocationServices';

  @override
  Future<void> onInitialize() async {
    bus.subscribe('location.mock', (evt, b) => _applyMock(evt));
    bus.subscribe('location.add_geofence', (evt, b) => _addGeofence(evt));
    _timer = Timer.periodic(updateInterval, (_) => _tick());
  }

  @override
  Future<void> onDispose() async {
    _timer?.cancel();
  }

  void _applyMock(Event evt) {
    _lat = (evt.data?['lat'] as num).toDouble();
    _lon = (evt.data?['lon'] as num).toDouble();
    bus.publish(Event(type: 'location.update', data: {'lat': _lat, 'lon': _lon}));
    _checkFences();
  }

  void _addGeofence(Event evt) {
    final id = evt.data?['id'] as String;
    final lat = (evt.data?['lat'] as num).toDouble();
    final lon = (evt.data?['lon'] as num).toDouble();
    final radius = (evt.data?['radius_m'] as num).toDouble();
    _fences[id] = _Geofence(id, lat, lon, radius);
  }

  void _tick() {
    if (_lat == null || _lon == null) return;
    bus.publish(Event(type: 'location.update', data: {'lat': _lat, 'lon': _lon}));
    _checkFences();
  }

  void _checkFences() {
    for (final fence in _fences.values) {
      final d = _haversine(_lat!, _lon!, fence.lat, fence.lon) * 1000.0;
      final nowInside = d <= fence.radiusM;
      if (nowInside != fence.inside) {
        fence.inside = nowInside;
        bus.publish(Event(type: nowInside ? 'geofence.entered' : 'geofence.exited', data: {'id': fence.id}));
        if (nowInside) {
          bus.publish(Event(type: 'quest.location_reached', data: {'geofenceId': fence.id}));
        }
      }
    }
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);
}
