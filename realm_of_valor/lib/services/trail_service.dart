import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/trail_model.dart';
import '../core/config.dart';

class TrailService {
  static const String _overpassApiUrl = 'https://overpass-api.de/api/interpreter';
  
  // Local trail database - in production this would be in a database
  static final List<Trail> _localTrails = [
    // Snowdon Trail
    Trail(
      id: 'snowdon_llanberis_path',
      name: 'Snowdon via Llanberis Path',
      description: 'The most popular route to the summit of Snowdon, offering stunning views of the Welsh mountains.',
      startLocation: const LatLng(53.0581, -4.1133), // Llanberis
      endLocation: const LatLng(53.0685, -4.0764),   // Snowdon Summit
      waypoints: [
        const LatLng(53.0581, -4.1133),
        const LatLng(53.0612, -4.1023),
        const LatLng(53.0645, -4.0892),
        const LatLng(53.0685, -4.0764),
      ],
      distance: 7500, // 7.5km
      elevationGain: 975, // meters
      difficulty: TrailDifficulty.hard,
      type: TrailType.hiking,
      tags: ['mountain', 'scenic', 'summit', 'wales'],
      region: 'Snowdonia',
      country: 'Wales',
      rating: 4.8,
      reviewCount: 1250,
      metadata: {
        'estimatedTime': '4-6 hours',
        'bestTime': 'May to September',
        'parking': 'Llanberis car park',
        'facilities': ['toilets', 'cafe', 'visitor_center'],
      },
    ),
    
    // Ben Nevis Trail
    Trail(
      id: 'ben_nevis_mountain_track',
      name: 'Ben Nevis via Mountain Track',
      description: 'The classic route to the highest peak in the British Isles.',
      startLocation: const LatLng(56.7969, -5.0037), // Glen Nevis
      endLocation: const LatLng(56.7965, -5.0037),   // Ben Nevis Summit
      waypoints: [
        const LatLng(56.7969, -5.0037),
        const LatLng(56.7965, -5.0037),
      ],
      distance: 13500, // 13.5km
      elevationGain: 1344, // meters
      difficulty: TrailDifficulty.expert,
      type: TrailType.hiking,
      tags: ['mountain', 'highest_peak', 'scotland', 'challenging'],
      region: 'Highlands',
      country: 'Scotland',
      rating: 4.9,
      reviewCount: 890,
      metadata: {
        'estimatedTime': '7-9 hours',
        'bestTime': 'June to September',
        'parking': 'Glen Nevis car park',
        'facilities': ['toilets', 'visitor_center'],
      },
    ),
    
    // Local Northampton Trails
    Trail(
      id: 'northampton_riverside_walk',
      name: 'Northampton Riverside Walk',
      description: 'A peaceful walk along the River Nene through Northampton.',
      startLocation: const LatLng(52.2322, -0.8913), // Northampton center
      endLocation: const LatLng(52.2456, -0.8765),   // Riverside park
      waypoints: [
        const LatLng(52.2322, -0.8913),
        const LatLng(52.2389, -0.8839),
        const LatLng(52.2456, -0.8765),
      ],
      distance: 3200, // 3.2km
      elevationGain: 45, // meters
      difficulty: TrailDifficulty.easy,
      type: TrailType.walking,
      tags: ['riverside', 'urban', 'family_friendly', 'flat'],
      region: 'Northamptonshire',
      country: 'England',
      rating: 4.2,
      reviewCount: 156,
      metadata: {
        'estimatedTime': '45-60 minutes',
        'bestTime': 'Year round',
        'parking': 'Town center car parks',
        'facilities': ['benches', 'playground', 'cafe'],
      },
    ),
  ];

  /// Get trails near a location
  static Future<List<Trail>> getTrailsNearLocation({
    required LatLng location,
    double radiusKm = 50.0,
    TrailType? type,
    TrailDifficulty? difficulty,
  }) async {
    // Filter local trails by distance
    final nearbyTrails = _localTrails.where((trail) {
      final distance = Geolocator.distanceBetween(
        location.latitude,
        location.longitude,
        trail.startLocation.latitude,
        trail.startLocation.longitude,
      );
      return distance <= radiusKm * 1000; // Convert km to meters
    }).toList();

    // Apply filters
    if (type != null) {
      nearbyTrails.removeWhere((trail) => trail.type != type);
    }
    if (difficulty != null) {
      nearbyTrails.removeWhere((trail) => trail.difficulty != difficulty);
    }

    // Try to fetch additional trails from OpenStreetMap
    try {
      final osmTrails = await _fetchTrailsFromOSM(location, radiusKm);
      nearbyTrails.addAll(osmTrails);
    } catch (e) {
      print('Failed to fetch OSM trails: $e');
    }

    return nearbyTrails;
  }

  /// Fetch trails from OpenStreetMap using Overpass API
  static Future<List<Trail>> _fetchTrailsFromOSM(LatLng location, double radiusKm) async {
    final query = '''
      [out:json][timeout:25];
      (
        way["highway"="path"]["name"](around:$radiusKm,${location.latitude},${location.longitude});
        way["highway"="footway"]["name"](around:$radiusKm,${location.latitude},${location.longitude});
        way["highway"="bridleway"]["name"](around:$radiusKm,${location.latitude},${location.longitude});
        way["route"="hiking"]["name"](around:$radiusKm,${location.latitude},${location.longitude});
      );
      out body;
      >;
      out skel qt;
    ''';

    final response = await http.post(
      Uri.parse(_overpassApiUrl),
      body: query,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch OSM data: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return _parseOSMData(data, location);
  }

  /// Parse OSM data into Trail objects
  static List<Trail> _parseOSMData(Map<String, dynamic> data, LatLng centerLocation) {
    final trails = <Trail>[];
    final random = Random();

    // This is a simplified parser - in production you'd want more sophisticated parsing
    if (data['elements'] != null) {
      for (final element in data['elements']) {
        if (element['type'] == 'way' && element['tags'] != null) {
          final tags = element['tags'];
          final name = tags['name'] ?? 'Unnamed Trail';
          
          // Create a simple trail from OSM data
          final trail = Trail(
            id: 'osm_${element['id']}',
            name: name,
            description: 'Trail discovered from OpenStreetMap data.',
            startLocation: centerLocation, // Simplified - would need proper parsing
            endLocation: centerLocation,   // Simplified - would need proper parsing
            waypoints: [centerLocation],   // Simplified
            distance: 1000.0 + random.nextDouble() * 5000, // Random distance
            elevationGain: random.nextDouble() * 200,    // Random elevation
            difficulty: TrailDifficulty.values[random.nextInt(TrailDifficulty.values.length)],
            type: TrailType.hiking,
            tags: ['osm', 'discovered'],
            region: 'Unknown',
            country: 'Unknown',
            rating: 3.5 + random.nextDouble() * 1.5,
            reviewCount: random.nextInt(50),
          );
          
          trails.add(trail);
        }
      }
    }

    return trails;
  }

  /// Get a specific trail by ID
  static Trail? getTrailById(String id) {
    try {
      return _localTrails.firstWhere((trail) => trail.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Add a new trail to the local database
  static void addTrail(Trail trail) {
    _localTrails.add(trail);
  }

  /// Get all trails
  static List<Trail> getAllTrails() {
    return List.unmodifiable(_localTrails);
  }

  /// Search trails by name or tags
  static List<Trail> searchTrails(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _localTrails.where((trail) {
      return trail.name.toLowerCase().contains(lowercaseQuery) ||
             trail.description.toLowerCase().contains(lowercaseQuery) ||
             trail.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }
}
