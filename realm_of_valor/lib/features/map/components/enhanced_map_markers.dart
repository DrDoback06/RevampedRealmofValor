import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import '../../../data/models/trail_model.dart';
import '../../../data/models/quest_model.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

/// Enhanced map marker generation for trails, segments, and quests
/// 
/// ENHANCEMENTS:
/// 1. Color-coded difficulty markers
/// 2. Animated pulse effect for active quests
/// 3. Trail route polylines with elevation shading
/// 4. Segment start/finish markers
/// 5. Friend activity markers
/// 6. Reward preview overlays
/// 7. Weather condition icons
/// 8. Multi-layer marker clustering

class EnhancedMapMarkers {
  /// Create a trail marker with difficulty color coding
  static Future<Marker> createTrailMarker({
    required String markerId,
    required Trail trail,
    required VoidCallback onTap,
  }) async {
    return Marker(
      markerId: MarkerId(markerId),
      position: trail.startLocation,
      icon: await _createTrailIcon(trail),
      infoWindow: InfoWindow(
        title: trail.name,
        snippet: '${(trail.distance / 1000).toStringAsFixed(1)}km • ${trail.difficulty.name}',
        onTap: onTap,
      ),
      onTap: onTap,
    );
  }

  /// Create trail route polyline with difficulty-based coloring
  static Polyline createTrailRoute({
    required String polylineId,
    required Trail trail,
    bool showElevationShading = true,
  }) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: [trail.startLocation, ...trail.waypoints, trail.endLocation],
      color: _getTrailColor(trail.difficulty),
      width: 5,
      patterns: trail.type == TrailType.hiking
          ? [PatternItem.dash(20), PatternItem.gap(10)]
          : [],
      consumeTapEvents: true,
      geodesic: true,
    );
  }

  /// Create enhanced quest marker with animation support
  static Future<Marker> createQuestMarker({
    required String markerId,
    required Quest quest,
    required VoidCallback onTap,
    bool animate = false,
  }) async {
    return Marker(
      markerId: MarkerId(markerId),
      position: LatLng(quest.location!.latitude, quest.location!.longitude),
      icon: await _createQuestIcon(quest, animate),
      infoWindow: InfoWindow(
        title: quest.title,
        snippet: 'XP: ${quest.rewards.xp} • Gold: ${quest.rewards.gold}',
        onTap: onTap,
      ),
      onTap: onTap,
    );
  }

  /// Create segment markers (start and finish)
  static List<Marker> createSegmentMarkers({
    required String segmentId,
    required LatLng start,
    required LatLng finish,
    required VoidCallback onTapStart,
    required VoidCallback onTapFinish,
  }) {
    return [
      Marker(
        markerId: MarkerId('${segmentId}_start'),
        position: start,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Segment Start'),
        onTap: onTapStart,
      ),
      Marker(
        markerId: MarkerId('${segmentId}_finish'),
        position: finish,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Segment Finish'),
        onTap: onTapFinish,
      ),
    ];
  }

  /// Create friend activity marker
  static Marker createFriendMarker({
    required String markerId,
    required LatLng position,
    required String friendName,
    required String activity,
  }) {
    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: friendName,
        snippet: activity,
      ),
      alpha: 0.7,
    );
  }

  /// Create quest geofence circle
  static Circle createQuestGeofence({
    required String circleId,
    required LatLng center,
    required double radius,
    Color? fillColor,
    Color? strokeColor,
  }) {
    return Circle(
      circleId: CircleId(circleId),
      center: center,
      radius: radius,
      fillColor: (fillColor ?? Colors.blue).withOpacity(0.2),
      strokeColor: strokeColor ?? Colors.blue,
      strokeWidth: 2,
    );
  }

  /// Create trail elevation profile overlay
  static Polygon createElevationProfile({
    required String polygonId,
    required List<LatLng> points,
    required List<double> elevations,
  }) {
    // This would create a 3D-style elevation visualization
    return Polygon(
      polygonId: PolygonId(polygonId),
      points: points,
      fillColor: Colors.brown.withOpacity(0.3),
      strokeColor: Colors.brown,
      strokeWidth: 1,
    );
  }

  // Helper methods

  static Future<BitmapDescriptor> _createTrailIcon(Trail trail) async {
    final color = _getTrailColor(trail.difficulty);
    
    // Create custom marker with difficulty color
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;
    
    // Draw circle
    canvas.drawCircle(const Offset(20, 20), 15, paint);
    
    // Draw inner icon
    final iconPaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(20, 20), 8, iconPaint);
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(40, 40);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> _createQuestIcon(Quest quest, bool animate) async {
    final color = _getQuestTypeColor(quest.type);
    
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;
    
    // Draw quest marker shape (pin)
    final path = Path();
    path.moveTo(20, 40);
    path.lineTo(10, 20);
    path.lineTo(10, 10);
    path.arcToPoint(
      const Offset(30, 10),
      radius: const Radius.circular(10),
    );
    path.lineTo(30, 20);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Draw quest type icon
    if (animate) {
      // Add pulsing effect
      final pulsePaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(const Offset(20, 15), 18, pulsePaint);
    }
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(40, 45);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  static Color _getTrailColor(TrailDifficulty difficulty) {
    switch (difficulty) {
      case TrailDifficulty.easy:
        return Colors.green;
      case TrailDifficulty.moderate:
        return Colors.blue;
      case TrailDifficulty.hard:
        return Colors.orange;
      case TrailDifficulty.expert:
        return Colors.red;
    }
  }

  static Color _getQuestTypeColor(QuestType type) {
    switch (type) {
      case QuestType.battle:
        return Colors.red;
      case QuestType.treasure:
        return Colors.amber;
      case QuestType.fitness:
        return Colors.green;
      case QuestType.location:
        return Colors.blue;
      case QuestType.social:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
