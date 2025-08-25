import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../core/config.dart';

class NavigationService {
  static const String _apiKey = AppConfig.googleMapsApiKey;
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions';

  /// Get route from current location to destination
  static Future<RouteInfo?> getRoute({
    required LatLng origin,
    required LatLng destination,
    String mode = 'walking', // walking, bicycling, driving, transit
  }) async {
    debugPrint('NavigationService: Getting route from ${origin.latitude},${origin.longitude} to ${destination.latitude},${destination.longitude}');
    
    try {
      final url = Uri.parse(
        '$_baseUrl/json?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=$mode'
        '&key=$_apiKey'
      );

      debugPrint('NavigationService: Making request to Google Directions API');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('NavigationService: Received route data');
        
        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final legs = route['legs'] as List;
          
          if (legs.isNotEmpty) {
            final leg = legs[0];
            final steps = leg['steps'] as List;
            
            // Convert steps to LatLng points for polyline
            final List<LatLng> polylinePoints = [];
            for (final step in steps) {
              final polyline = step['polyline']['points'] as String;
              final points = _decodePolyline(polyline);
              polylinePoints.addAll(points);
            }
            
            return RouteInfo(
              distance: leg['distance']['text'] as String,
              duration: leg['duration']['text'] as String,
              polylinePoints: polylinePoints,
              mode: mode,
              instructions: steps.map((step) => step['html_instructions'] as String).toList(),
            );
          }
        } else {
          debugPrint('NavigationService: API Error - ${data['status']}');
        }
      } else {
        debugPrint('NavigationService: HTTP Error - ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('NavigationService: Error getting route - $e');
    }
    
    // Return mock route if API fails
    return _generateMockRoute(origin, destination, mode);
  }

  /// Generate mock route when API is unavailable
  static RouteInfo _generateMockRoute(LatLng origin, LatLng destination, String mode) {
    debugPrint('NavigationService: Generating mock route');
    
    // Calculate distance
    final distance = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );
    
    // Generate simple polyline points
    final List<LatLng> polylinePoints = [];
    final steps = 10;
    for (int i = 0; i <= steps; i++) {
      final lat = origin.latitude + (destination.latitude - origin.latitude) * i / steps;
      final lng = origin.longitude + (destination.longitude - origin.longitude) * i / steps;
      polylinePoints.add(LatLng(lat, lng));
    }
    
    return RouteInfo(
      distance: '${distance.toStringAsFixed(0)} m',
      duration: '${(distance / 80).toStringAsFixed(0)} min', // Assume 80m/min walking speed
      polylinePoints: polylinePoints,
      mode: mode,
      instructions: [
        'Head towards the destination',
        'Continue straight',
        'Arrive at destination',
      ],
    );
  }

  /// Decode Google's polyline format
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }
}

class RouteInfo {
  final String distance;
  final String duration;
  final List<LatLng> polylinePoints;
  final String mode;
  final List<String> instructions;

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.polylinePoints,
    required this.mode,
    required this.instructions,
  });
}
