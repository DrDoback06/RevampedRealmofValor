import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EpicMapData {
  EpicMapData({
    required this.initialCamera,
    required this.mapStyle,
    required this.markers,
    required this.polylines,
    required this.polygons,
    required this.regions,
  });
  
  final CameraPosition initialCamera;
  final String mapStyle;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  final Map<String, MapRegion> regions;
}

class MapRegion {
  MapRegion({
    required this.name,
    required this.category,
    required this.polygon,
    required this.style,
  });
  
  final String name;
  final String category;
  final Polygon polygon;
  final Map<String, dynamic> style;
}

class EpicMapLoader {
  static final EpicMapLoader _instance = EpicMapLoader._internal();
  factory EpicMapLoader() => _instance;
  EpicMapLoader._internal();

  Map<String, BitmapDescriptor>? _iconCache;
  Map<String, dynamic>? _config;

  /// Load the epic fantasy map configuration
  Future<EpicMapData> loadEpicMap() async {
    try {
      // Load the JSON configuration
      final raw = await rootBundle.loadString('assets/epic_fantasy_map.json');
      _config = json.decode(raw);

      // Initialize icon cache
      await _initializeIconCache();

      // Parse features
      final Set<Marker> markers = {};
      final Set<Polyline> polylines = {};
      final Set<Polygon> polygons = {};
      final Map<String, MapRegion> regions = {};

      final features = _config!['data']['features'] as List<dynamic>;
      
      for (final feature in features) {
        final props = feature['properties'] as Map<String, dynamic>;
        final geom = feature['geometry'] as Map<String, dynamic>;
        final type = geom['type'] as String;

        if (type == 'Point') {
          final marker = await _createMarker(feature);
          if (marker != null) markers.add(marker);
        } else if (type == 'LineString') {
          final polyline = _createPolyline(feature);
          if (polyline != null) polylines.add(polyline);
        } else if (type == 'Polygon') {
          final polygon = _createPolygon(feature);
          if (polygon != null) {
            polygons.add(polygon);
            
            // Store regions for quest generation
            final category = props['category'] as String?;
            if (category != null && category.startsWith('region-')) {
              regions[props['name'] as String] = MapRegion(
                name: props['name'] as String,
                category: category,
                polygon: polygon,
                style: props['style'] as Map<String, dynamic>? ?? {},
              );
            }
          }
        }
      }

      // Create camera position
      final mapOptions = _config!['mapOptions'] as Map<String, dynamic>;
      final center = mapOptions['center'] as Map<String, dynamic>;
      final initialCamera = CameraPosition(
        target: LatLng(
          (center['lat'] as num).toDouble(),
          (center['lng'] as num).toDouble(),
        ),
        zoom: (mapOptions['zoom'] as num).toDouble(),
      );

      // Get map style
      final mapStyle = json.encode(_config!['mapStyle']);

      return EpicMapData(
        initialCamera: initialCamera,
        mapStyle: mapStyle,
        markers: markers,
        polylines: polylines,
        polygons: polygons,
        regions: regions,
      );
    } catch (e) {
      print('Error loading epic map: $e');
      // Return default map data
      return _getDefaultMapData();
    }
  }

  /// Initialize icon cache for better performance
  Future<void> _initializeIconCache() async {
    if (_iconCache != null) return;

    _iconCache = {};
    final categoryIcons = _config!['ui']['categoryIcons'] as Map<String, dynamic>;

    for (final entry in categoryIcons.entries) {
      try {
        final iconPath = entry.value as String;
        final descriptor = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(32, 32)),
          iconPath,
        );
        _iconCache![entry.key] = descriptor;
      } catch (e) {
        print('Failed to load icon ${entry.key}: $e');
        // Use default marker
        _iconCache![entry.key] = BitmapDescriptor.defaultMarker;
      }
    }
  }

  /// Create a marker from a feature
  Future<Marker?> _createMarker(Map<String, dynamic> feature) async {
    final props = feature['properties'] as Map<String, dynamic>;
    final geom = feature['geometry'] as Map<String, dynamic>;
    final coords = (geom['coordinates'] as List).cast<num>();
    
    final position = LatLng(coords[1].toDouble(), coords[0].toDouble());
    final name = props['name'] as String? ?? '';
    final label = props['label'] as String? ?? name;
    final description = props['description'] as String? ?? '';
    final category = props['category'] as String? ?? 'default';
    final iconKey = props['icon'] as String? ?? category;
    final zIndex = props['zIndex'] as int? ?? 10;

    // Get icon
    BitmapDescriptor icon;
    if (_iconCache != null && _iconCache!.containsKey(iconKey)) {
      icon = _iconCache![iconKey]!;
    } else {
      icon = BitmapDescriptor.defaultMarker;
    }

    return Marker(
      markerId: MarkerId(name),
      position: position,
      icon: icon,
      infoWindow: InfoWindow(
        title: label,
        snippet: description,
      ),
      zIndex: zIndex.toDouble(),
    );
  }

  /// Create a polyline from a feature
  Polyline? _createPolyline(Map<String, dynamic> feature) {
    final props = feature['properties'] as Map<String, dynamic>;
    final geom = feature['geometry'] as Map<String, dynamic>;
    final coords = (geom['coordinates'] as List)
        .map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();

    if (coords.length < 2) return null;

    final name = props['name'] as String? ?? '';
    final style = props['style'] as Map<String, dynamic>? ?? {};
    final strokeColor = style['strokeColor'] as String? ?? '#ff77e9';
    final strokeWeight = style['strokeWeight'] as int? ?? 3;
    final strokeOpacity = style['strokeOpacity'] as num? ?? 0.8;
    final lineDash = style['lineDash'] as List<dynamic>?;

    List<PatternItem>? patterns;
    if (lineDash != null && lineDash.length >= 2) {
      patterns = [
        PatternItem.dash((lineDash[0] as num).toDouble()),
        PatternItem.gap((lineDash[1] as num).toDouble()),
      ];
    }

    return Polyline(
      polylineId: PolylineId(name),
      points: coords,
      width: strokeWeight,
      color: _parseColor(strokeColor),
      patterns: patterns ?? [],
      zIndex: (style['zIndex'] as int? ?? 6),
    );
  }

  /// Create a polygon from a feature
  Polygon? _createPolygon(Map<String, dynamic> feature) {
    final props = feature['properties'] as Map<String, dynamic>;
    final geom = feature['geometry'] as Map<String, dynamic>;
    final rings = (geom['coordinates'] as List).first as List<dynamic>;
    
    final points = rings
        .map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();

    if (points.length < 3) return null;

    final name = props['name'] as String? ?? '';
    final style = props['style'] as Map<String, dynamic>? ?? {};
    final strokeColor = style['strokeColor'] as String? ?? '#272c36';
    final strokeWeight = style['strokeWeight'] as int? ?? 1;
    final fillColor = style['fillColor'] as String? ?? '#000000';
    final fillOpacity = style['fillOpacity'] as num? ?? 0.5;

    return Polygon(
      polygonId: PolygonId(name),
      points: points,
      strokeWidth: strokeWeight,
      strokeColor: _parseColor(strokeColor),
      fillColor: _parseColor(fillColor).withOpacity(fillOpacity.toDouble()),
      zIndex: (style['zIndex'] as int? ?? 1),
    );
  }

  /// Parse hex color string to Color
  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'ff$hex'; // Add alpha channel
    }
    return Color(int.parse(hex, radix: 16));
  }

  /// Get default map data if loading fails
  EpicMapData _getDefaultMapData() {
    return EpicMapData(
      initialCamera: const CameraPosition(
        target: LatLng(52.232192, -0.8912896),
        zoom: 12,
      ),
      mapStyle: '[]',
      markers: {},
      polylines: {},
      polygons: {},
      regions: {},
    );
  }

  /// Get a random location within a region
  LatLng? getRandomLocationInRegion(String regionName) {
    final region = _config?['data']['features']
        .firstWhere((f) => f['properties']['name'] == regionName, orElse: () => null);
    
    if (region == null) return null;

    final coords = region['geometry']['coordinates'][0] as List<dynamic>;
    if (coords.isEmpty) return null;

    // Simple random point within polygon (for better accuracy, use proper polygon point-in-polygon algorithm)
    final random = Random();
    final randomCoord = coords[random.nextInt(coords.length)];
    return LatLng(
      (randomCoord[1] as num).toDouble(),
      (randomCoord[0] as num).toDouble(),
    );
  }

  /// Get all region names
  List<String> getRegionNames() {
    if (_config == null) return [];
    
    return _config!['data']['features']
        .where((f) => f['properties']['category']?.toString().startsWith('region-') == true)
        .map((f) => f['properties']['name'] as String)
        .toList();
  }

  /// Get map configuration
  Map<String, dynamic>? getConfig() => _config;

  /// Get category colors
  Map<String, String> getCategoryColors() {
    if (_config == null) return {};
    
    final colors = _config!['ui']['categoryColors'] as Map<String, dynamic>;
    return colors.map((key, value) => MapEntry(key, value as String));
  }
}
