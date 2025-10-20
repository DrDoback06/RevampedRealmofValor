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
    
    // ENHANCEMENT: Waterfall Trails
    Trail(
      id: 'sgwd_yr_eira_waterfall',
      name: 'Sgwd yr Eira Waterfall Walk',
      description: 'Walk behind the stunning waterfall in the Brecon Beacons. One of the most spectacular waterfalls in Wales.',
      startLocation: const LatLng(51.7583, -3.5833),
      endLocation: const LatLng(51.7650, -3.5900),
      waypoints: [
        const LatLng(51.7583, -3.5833),
        const LatLng(51.7617, -3.5867),
        const LatLng(51.7650, -3.5900),
      ],
      distance: 2800, // 2.8km
      elevationGain: 120, // meters
      difficulty: TrailDifficulty.moderate,
      type: TrailType.hiking,
      tags: ['waterfall', 'scenic', 'photography', 'brecon_beacons', 'wales'],
      region: 'Brecon Beacons',
      country: 'Wales',
      rating: 4.9,
      reviewCount: 892,
      metadata: {
        'estimatedTime': '1.5-2 hours',
        'bestTime': 'Spring and Autumn (best water flow)',
        'parking': 'Porth yr Ogof car park',
        'facilities': ['toilets'],
        'highlight': 'Walk behind the waterfall',
      },
    ),
    
    Trail(
      id: 'pistyll_rhaeadr_waterfall',
      name: 'Pistyll Rhaeadr Waterfall',
      description: 'Visit one of the Seven Wonders of Wales - a stunning 240ft waterfall cascading down rocky cliffs.',
      startLocation: const LatLng(52.8833, -3.3333),
      endLocation: const LatLng(52.8850, -3.3350),
      waypoints: [
        const LatLng(52.8833, -3.3333),
        const LatLng(52.8842, -3.3342),
        const LatLng(52.8850, -3.3350),
      ],
      distance: 1500, // 1.5km
      elevationGain: 80, // meters
      difficulty: TrailDifficulty.easy,
      type: TrailType.walking,
      tags: ['waterfall', 'seven_wonders', 'scenic', 'photography', 'short'],
      region: 'Powys',
      country: 'Wales',
      rating: 4.7,
      reviewCount: 534,
      metadata: {
        'estimatedTime': '45-60 minutes',
        'bestTime': 'Year round',
        'parking': 'On-site car park',
        'facilities': ['cafe', 'toilets'],
        'highlight': 'Tallest single-drop waterfall in Wales',
      },
    ),
    
    // ENHANCEMENT: Lake Trails
    Trail(
      id: 'llyn_idwal_lake_circuit',
      name: 'Llyn Idwal Lake Circuit',
      description: 'A stunning circular walk around a glacial lake with dramatic mountain scenery. Perfect for all abilities.',
      startLocation: const LatLng(53.1108, -3.9994),
      endLocation: const LatLng(53.1108, -3.9994),
      waypoints: [
        const LatLng(53.1108, -3.9994),
        const LatLng(53.1125, -4.0025),
        const LatLng(53.1142, -4.0042),
        const LatLng(53.1125, -4.0008),
        const LatLng(53.1108, -3.9994),
      ],
      distance: 4200, // 4.2km circuit
      elevationGain: 180, // meters
      difficulty: TrailDifficulty.moderate,
      type: TrailType.hiking,
      tags: ['lake', 'circuit', 'glacial', 'mountains', 'scenic', 'snowdonia'],
      region: 'Snowdonia',
      country: 'Wales',
      rating: 4.8,
      reviewCount: 1456,
      metadata: {
        'estimatedTime': '2-3 hours',
        'bestTime': 'May to October',
        'parking': 'Ogwen Cottage car park',
        'facilities': ['toilets', 'visitor_center'],
        'highlight': 'Glacial lake with Tryfan mountain backdrop',
      },
    ),
    
    Trail(
      id: 'loch_an_eilein_castle',
      name: 'Loch an Eilein Castle Walk',
      description: 'Enchanting walk around a beautiful loch with a 13th-century island castle. Forest and water views throughout.',
      startLocation: const LatLng(57.1417, -3.8333),
      endLocation: const LatLng(57.1417, -3.8333),
      waypoints: [
        const LatLng(57.1417, -3.8333),
        const LatLng(57.1450, -3.8367),
        const LatLng(57.1483, -3.8333),
        const LatLng(57.1450, -3.8300),
        const LatLng(57.1417, -3.8333),
      ],
      distance: 6500, // 6.5km circuit
      elevationGain: 50, // meters (mostly flat)
      difficulty: TrailDifficulty.easy,
      type: TrailType.walking,
      tags: ['lake', 'castle', 'forest', 'flat', 'family_friendly', 'scotland'],
      region: 'Cairngorms',
      country: 'Scotland',
      rating: 4.6,
      reviewCount: 728,
      metadata: {
        'estimatedTime': '2-2.5 hours',
        'bestTime': 'Year round',
        'parking': 'Loch an Eilein car park',
        'facilities': ['toilets', 'cafe'],
        'highlight': 'Island castle and ancient pine forest',
      },
    ),
    
    Trail(
      id: 'ullswater_way_aira_force',
      name: 'Ullswater Way to Aira Force',
      description: 'Walk along England\'s most beautiful lake to visit the impressive Aira Force waterfall. Lake and forest scenery.',
      startLocation: const LatLng(54.5833, -2.9167),
      endLocation: const LatLng(54.6000, -2.9083),
      waypoints: [
        const LatLng(54.5833, -2.9167),
        const LatLng(54.5917, -2.9125),
        const LatLng(54.6000, -2.9083),
      ],
      distance: 5400, // 5.4km
      elevationGain: 210, // meters
      difficulty: TrailDifficulty.moderate,
      type: TrailType.hiking,
      tags: ['lake', 'waterfall', 'lake_district', 'scenic', 'england'],
      region: 'Lake District',
      country: 'England',
      rating: 4.7,
      reviewCount: 967,
      metadata: {
        'estimatedTime': '2.5-3 hours',
        'bestTime': 'April to October',
        'parking': 'Aira Force National Trust car park',
        'facilities': ['toilets', 'cafe', 'shop'],
        'highlight': 'Ullswater lake views + 70ft waterfall',
      },
    ),
    
    // ENHANCEMENT: Mountain Summit Trails
    Trail(
      id: 'pen_y_fan_south',
      name: 'Pen y Fan via Southern Ridge',
      description: 'Climb the highest peak in Southern Britain. Stunning 360° views from the summit on clear days.',
      startLocation: const LatLng(51.8833, -3.4333),
      endLocation: const LatLng(51.8839, -3.4364),
      waypoints: [
        const LatLng(51.8833, -3.4333),
        const LatLng(51.8836, -3.4350),
        const LatLng(51.8839, -3.4364),
      ],
      distance: 6800, // 6.8km
      elevationGain: 520, // meters
      difficulty: TrailDifficulty.hard,
      type: TrailType.hiking,
      tags: ['mountain', 'summit', 'brecon_beacons', 'challenging', 'panoramic'],
      region: 'Brecon Beacons',
      country: 'Wales',
      rating: 4.9,
      reviewCount: 2134,
      metadata: {
        'estimatedTime': '3-4 hours',
        'bestTime': 'May to September',
        'parking': 'Pont ar Daf car park',
        'facilities': ['toilets'],
        'highlight': 'Highest peak in Southern Britain (886m)',
      },
    ),
    
    Trail(
      id: 'scafell_pike_corridor',
      name: 'Scafell Pike via Corridor Route',
      description: 'Ascend England\'s highest peak via the scenic Corridor Route. Challenging but rewarding with incredible views.',
      startLocation: const LatLng(54.4542, -3.2117),
      endLocation: const LatLng(54.4542, -3.2117),
      waypoints: [
        const LatLng(54.4542, -3.2117),
        const LatLng(54.4575, -3.2150),
        const LatLng(54.4608, -3.2117),
        const LatLng(54.4575, -3.2083),
        const LatLng(54.4542, -3.2117),
      ],
      distance: 15200, // 15.2km
      elevationGain: 989, // meters
      difficulty: TrailDifficulty.expert,
      type: TrailType.hiking,
      tags: ['mountain', 'summit', 'highest_england', 'challenging', 'lake_district'],
      region: 'Lake District',
      country: 'England',
      rating: 4.8,
      reviewCount: 1523,
      metadata: {
        'estimatedTime': '6-8 hours',
        'bestTime': 'June to September',
        'parking': 'Seathwaite Farm',
        'facilities': ['toilets'],
        'highlight': 'Highest peak in England (978m)',
      },
    ),
    
    // ENHANCEMENT: Coastal & Scenic Trails
    Trail(
      id: 'pembrokeshire_coastal_path_st_davids',
      name: 'Pembrokeshire Coast Path - St Davids Head',
      description: 'Dramatic coastal clifftop walk with stunning sea views, hidden coves, and wildlife spotting opportunities.',
      startLocation: const LatLng(51.9167, -5.2667),
      endLocation: const LatLng(51.9333, -5.3000),
      waypoints: [
        const LatLng(51.9167, -5.2667),
        const LatLng(51.9250, -5.2833),
        const LatLng(51.9333, -5.3000),
      ],
      distance: 8200, // 8.2km
      elevationGain: 320, // meters
      difficulty: TrailDifficulty.moderate,
      type: TrailType.hiking,
      tags: ['coastal', 'cliffs', 'sea_views', 'wildlife', 'scenic', 'pembrokeshire'],
      region: 'Pembrokeshire',
      country: 'Wales',
      rating: 4.9,
      reviewCount: 1789,
      metadata: {
        'estimatedTime': '3-4 hours',
        'bestTime': 'April to October',
        'parking': 'Whitesands Bay car park',
        'facilities': ['toilets', 'cafe'],
        'highlight': 'Dramatic clifftops and seal watching',
      },
    ),
    
    Trail(
      id: 'fairy_glen_betws_y_coed',
      name: 'Fairy Glen Nature Reserve',
      description: 'Magical woodland walk through ancient forest with river gorge and cascading waterfalls. Perfect for families.',
      startLocation: const LatLng(53.0833, -3.8000),
      endLocation: const LatLng(53.0850, -3.8033),
      waypoints: [
        const LatLng(53.0833, -3.8000),
        const LatLng(53.0842, -3.8017),
        const LatLng(53.0850, -3.8033),
      ],
      distance: 2200, // 2.2km
      elevationGain: 65, // meters
      difficulty: TrailDifficulty.easy,
      type: TrailType.walking,
      tags: ['forest', 'waterfall', 'gorge', 'family_friendly', 'magical', 'short'],
      region: 'Snowdonia',
      country: 'Wales',
      rating: 4.5,
      reviewCount: 643,
      metadata: {
        'estimatedTime': '45-75 minutes',
        'bestTime': 'Year round',
        'parking': 'Roadside parking',
        'facilities': [],
        'highlight': 'Enchanting woodland gorge',
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
