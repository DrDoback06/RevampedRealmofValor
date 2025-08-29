import 'package:flutter/foundation.dart';
import 'dart:math';
import '../core/config.dart';

class POIService {
  static const String _apiKey = AppConfig.googleMapsApiKey;
  
  // Wootton, Northampton, UK coordinates
  static const double _woottonLat = 52.2583;
  static const double _woottonLng = -0.8901;

  static Future<List<POI>> getNearbyPOIs({
    required double latitude,
    required double longitude,
    int radius = 1000, // 1km radius
  }) async {
    debugPrint('POIService: Getting nearby POIs for $latitude, $longitude');
    
    // Force real API calls if configured
    if (AppConfig.forceRealApiCalls) {
      debugPrint('POIService: Forcing real API calls');
    }
    
    try {
      // For web, we need to use the Google Maps JavaScript API
      // This will be handled by the map widget itself
      debugPrint('POIService: Using Google Maps JavaScript API for web');
      
      // For now, return mock data since the JavaScript API integration
      // requires more complex setup with the map widget
      if (!AppConfig.forceRealApiCalls) {
        return _getMockPOIs(latitude, longitude, radius);
      } else {
        // In a real implementation, this would integrate with the map widget
        // to get POIs from the JavaScript API
        debugPrint('POIService: Real API calls requested but not yet implemented for web');
        return _getMockPOIs(latitude, longitude, radius);
      }
    } catch (e) {
      debugPrint('POIService: Error getting POIs - $e');
      
      if (!AppConfig.forceRealApiCalls) {
        return _getMockPOIs(latitude, longitude, radius);
      } else {
        rethrow;
      }
    }
  }

  /// Get mock POIs when API is unavailable
  static List<POI> _getMockPOIs(double latitude, double longitude, int radius) {
    debugPrint('POIService: Returning mock POIs');
    
    return [
      POI(
        placeId: 'mock_pub_1',
        name: 'The Dragon\'s Den Pub',
        latitude: latitude + 0.001,
        longitude: longitude + 0.001,
        types: ['bar', 'establishment'],
        rating: 4.2,
        distance: 150,
      ),
      POI(
        placeId: 'mock_gym_1',
        name: 'Valor Fitness Center',
        latitude: latitude - 0.001,
        longitude: longitude + 0.002,
        types: ['gym', 'health'],
        rating: 4.5,
        distance: 300,
      ),
      POI(
        placeId: 'mock_park_1',
        name: 'Adventure Park',
        latitude: latitude + 0.002,
        longitude: longitude - 0.001,
        types: ['park', 'establishment'],
        rating: 4.0,
        distance: 450,
      ),
      POI(
        placeId: 'mock_shop_1',
        name: 'Magic Item Shop',
        latitude: latitude - 0.002,
        longitude: longitude - 0.002,
        types: ['store', 'establishment'],
        rating: 4.3,
        distance: 600,
      ),
      POI(
        placeId: 'mock_museum_1',
        name: 'Ancient History Museum',
        latitude: latitude + 0.003,
        longitude: longitude + 0.003,
        types: ['museum', 'establishment'],
        rating: 4.7,
        distance: 750,
      ),
    ];
  }

  static String categorizePOI(POI poi) {
    final types = poi.types.map((t) => t.toLowerCase()).toList();
    final name = poi.name.toLowerCase();
    
    // Pubs and bars
    if (types.contains('bar') || types.contains('night_club') ||
        name.contains('pub') || name.contains('bar') || name.contains('tavern')) {
      return 'pub';
    }
    
    // Gyms and fitness
    if (types.contains('gym') || types.contains('health') ||
        name.contains('gym') || name.contains('fitness') || name.contains('health')) {
      return 'gym';
    }
    
    // Parks and recreation
    if (types.contains('park') || types.contains('natural_feature') ||
        name.contains('park') || name.contains('garden') || name.contains('recreation')) {
      return 'park';
    }
    
    // Museums and cultural
    if (types.contains('museum') || types.contains('art_gallery') ||
        name.contains('museum') || name.contains('gallery') || name.contains('art')) {
      return 'museum';
    }
    
    // Libraries and education
    if (types.contains('library') || types.contains('school') || types.contains('university') ||
        name.contains('library') || name.contains('school') || name.contains('college')) {
      return 'education';
    }
    
    // Shops and retail
    if (types.contains('store') || types.contains('shopping_mall') ||
        name.contains('shop') || name.contains('store') || name.contains('market')) {
      return 'shop';
    }
    
    // Community centers
    if (types.contains('local_government_office') || types.contains('establishment') ||
        name.contains('community') || name.contains('centre') || name.contains('center')) {
      return 'community';
    }
    
    // Default
    return 'other';
  }
}

class POI {
  final String placeId;
  final String name;
  final double latitude;
  final double longitude;
  final List<String> types;
  final double rating;
  final int userRatingsTotal;
  final String vicinity;
  final double distance;

  POI({
    required this.placeId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.types,
    this.rating = 0.0,
    this.userRatingsTotal = 0,
    this.vicinity = '',
    this.distance = 0.0,
  });

  factory POI.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'];
    final lat = location['lat'] as double;
    final lng = location['lng'] as double;
    
    // Calculate distance from Wootton center
    final distance = _calculateDistance(
      POIService._woottonLat,
      POIService._woottonLng,
      lat,
      lng,
    );

    return POI(
      placeId: json['place_id'] as String,
      name: json['name'] as String,
      latitude: lat,
      longitude: lng,
      types: List<String>.from(json['types'] ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      userRatingsTotal: json['user_ratings_total'] as int? ?? 0,
      vicinity: json['vicinity'] as String? ?? '',
      distance: distance,
    );
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        sin(_degreesToRadians(lat1)) * sin(_degreesToRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan(sqrt(a) / sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  String get category => POIService.categorizePOI(this);

  @override
  String toString() {
    return 'POI(name: $name, category: $category, distance: ${distance.toStringAsFixed(0)}m)';
  }
}
