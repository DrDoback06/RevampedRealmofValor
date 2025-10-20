import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

/// Enhanced camera controller for trail following mode
/// 
/// ENHANCEMENTS:
/// 1. Drive/follow mode with tilted camera (perfect for runners)
/// 2. Automatic bearing calculation based on movement direction
/// 3. Smooth camera transitions
/// 4. Zoom level adaptation based on speed
/// 5. Pitch adjustment for terrain visualization
/// 6. Auto-rotation to face movement direction
/// 7. Speed-based camera settings
/// 8. Battery-efficient update throttling

enum CameraMode {
  free,       // User controls camera
  follow,     // Follow player, flat view
  drive,      // Follow player, tilted view (45°)
  terrain,    // Follow player, steep tilt (60°) for terrain
}

class TrailCameraController {
  GoogleMapController? _mapController;
  CameraMode _currentMode = CameraMode.free;
  
  // Camera settings by mode
  static const Map<CameraMode, CameraSettings> _modeSettings = {
    CameraMode.free: CameraSettings(
      zoom: 15.0,
      tilt: 0.0,
      bearing: 0.0,
    ),
    CameraMode.follow: CameraSettings(
      zoom: 17.0,
      tilt: 0.0,
      bearing: 0.0,
    ),
    CameraMode.drive: CameraSettings(
      zoom: 18.0,
      tilt: 45.0,  // 45° tilt - perfect for viewing trail ahead
      bearing: 0.0, // Will be calculated from movement
    ),
    CameraMode.terrain: CameraSettings(
      zoom: 19.0,
      tilt: 60.0,  // Steeper tilt for terrain visualization
      bearing: 0.0,
    ),
  };
  
  // Last known position for bearing calculation
  Position? _lastPosition;
  double _currentBearing = 0.0;
  
  // Throttling
  DateTime? _lastCameraUpdate;
  static const _minUpdateInterval = Duration(milliseconds: 500);

  TrailCameraController(this._mapController);

  /// Update map controller
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Get current camera mode
  CameraMode get currentMode => _currentMode;

  /// Switch camera mode
  Future<void> setCameraMode(CameraMode mode, {Position? currentPosition}) async {
    _currentMode = mode;
    
    if (currentPosition != null && _mapController != null) {
      await _updateCamera(currentPosition);
    }
  }

  /// Enable drive mode (perfect for runners/hikers)
  Future<void> enableDriveMode(Position currentPosition) async {
    await setCameraMode(CameraMode.drive, currentPosition: currentPosition);
  }

  /// Enable terrain mode (steeper angle for elevation visualization)
  Future<void> enableTerrainMode(Position currentPosition) async {
    await setCameraMode(CameraMode.terrain, currentPosition: currentPosition);
  }

  /// Disable follow modes (return to free mode)
  Future<void> disableFollowMode() async {
    await setCameraMode(CameraMode.free);
  }

  /// Update camera position based on player movement
  Future<void> updatePosition(Position newPosition) async {
    if (_mapController == null) return;
    if (_currentMode == CameraMode.free) return;
    
    // Throttle updates for battery efficiency
    final now = DateTime.now();
    if (_lastCameraUpdate != null &&
        now.difference(_lastCameraUpdate!) < _minUpdateInterval) {
      return;
    }
    _lastCameraUpdate = now;
    
    // Calculate bearing if we have previous position
    if (_lastPosition != null) {
      _currentBearing = _calculateBearing(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );
    }
    
    _lastPosition = newPosition;
    
    // Update camera
    await _updateCamera(newPosition);
  }

  /// Update camera with current settings
  Future<void> _updateCamera(Position position) async {
    if (_mapController == null) return;
    
    final settings = _modeSettings[_currentMode]!;
    
    // Adjust zoom based on speed for drive mode
    var zoom = settings.zoom;
    if (_currentMode == CameraMode.drive || _currentMode == CameraMode.terrain) {
      zoom = _calculateSpeedBasedZoom(position.speed, settings.zoom);
    }
    
    final cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: zoom,
      tilt: settings.tilt,
      bearing: _currentMode == CameraMode.free ? 0.0 : _currentBearing,
    );
    
    // Smooth animation
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );
  }

  /// Calculate bearing between two points (in degrees)
  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _degreesToRadians(lon2 - lon1);
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);
    
    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
              math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);
    
    var bearing = math.atan2(y, x);
    bearing = _radiansToDegrees(bearing);
    bearing = (bearing + 360) % 360; // Normalize to 0-360
    
    return bearing;
  }

  /// Calculate zoom level based on speed
  double _calculateSpeedBasedZoom(double speedMps, double baseZoom) {
    // Speed in m/s
    // Walking: 1.4 m/s → zoom 19
    // Running: 3.5 m/s → zoom 18
    // Cycling: 5.5 m/s → zoom 17
    
    if (speedMps < 1.5) {
      // Walking speed
      return baseZoom;
    } else if (speedMps < 4.0) {
      // Running speed
      return baseZoom - 0.5;
    } else if (speedMps < 6.0) {
      // Fast running / slow cycling
      return baseZoom - 1.0;
    } else {
      // Cycling speed
      return baseZoom - 1.5;
    }
  }

  /// Smoothly transition between camera modes
  Future<void> transitionToMode(CameraMode newMode, Position currentPosition) async {
    if (newMode == _currentMode) return;
    
    // First zoom out slightly
    await _mapController?.animateCamera(
      CameraUpdate.zoomTo(_modeSettings[_currentMode]!.zoom - 1),
    );
    
    // Wait a bit
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Switch mode
    _currentMode = newMode;
    
    // Update to new mode settings
    await _updateCamera(currentPosition);
  }

  /// Get camera settings for current mode
  CameraSettings getCurrentSettings() {
    return _modeSettings[_currentMode]!;
  }

  /// Check if in any follow mode
  bool get isInFollowMode =>
      _currentMode == CameraMode.follow ||
      _currentMode == CameraMode.drive ||
      _currentMode == CameraMode.terrain;

  // Helper methods
  double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;
  double _radiansToDegrees(double radians) => radians * 180.0 / math.pi;
}

/// Camera settings for each mode
class CameraSettings {
  final double zoom;
  final double tilt;
  final double bearing;
  
  const CameraSettings({
    required this.zoom,
    required this.tilt,
    required this.bearing,
  });
}
