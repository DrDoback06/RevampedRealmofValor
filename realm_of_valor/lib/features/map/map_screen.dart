import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:async';
import '../../../services/poi_service.dart';
import '../../../services/event_bus.dart';
import '../../../services/navigation_service.dart';
import '../../../services/trail_service.dart';
import '../../../services/adventure_api_service.dart';
import '../../../services/quest_generator_service.dart';
import '../../../services/epic_map_loader.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/models/trail_model.dart';
import '../../../core/di.dart';
import '../quests/providers.dart';
import '../quests/quest_list_screen.dart';
import 'fantasy_map_style.dart';
import 'components/trail_camera_controller.dart';
import 'package:realm_of_valor/features/battle/enhanced_battle_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _locationSubscription;
  LatLng _currentPosition = const LatLng(51.5074, -0.1278); // London default
  bool _locationPermissionGranted = false;
  bool _isTracking = false;
  final List<String> _debugLog = [];
  
  // ENHANCEMENT: Trail camera controller for drive mode
  TrailCameraController? _cameraController;
  Trail? _activeTrail;
  int _currentWaypointIndex = 0;
  bool _isDriveMode = false;
  
  // Quest markers by type
  final Set<Marker> _enemyMarkers = {};
  final Set<Marker> _itemMarkers = {};
  final Set<Marker> _poiMarkers = {};
  final Set<Marker> _trailMarkers = {};
  final Set<Marker> _storylineMarkers = {};
  final Set<Marker> _playerMarkers = {};
  
  // Map elements
  final Set<Circle> _geofences = {};
  final Set<Polyline> _navigationRoutes = {};
  final Set<Polyline> _trailRoutes = {};
  
  // Quest data
  final List<Quest> _randomQuests = [];
  final List<Quest> _poiQuests = [];
  final List<Quest> _trailQuests = [];
  final List<Quest> _storylineQuests = [];
  final List<POI> _realPOIs = [];
  
  // Epic fantasy map data
  EpicMapData? _epicMapData;
  bool _isLoadingEpicMap = false;
  
  // State
  bool _isLoadingPOIs = false;
  bool _isLoadingTrails = false;
  bool _disposed = false;
  RouteInfo? _currentRoute;
  String? _selectedQuestId;
  
  // Moving enemies
  final Map<String, LatLng> _movingEnemies = {};
  Timer? _enemyMovementTimer;

  void _logDebug(String message) {
    final timestamp = DateTime.now().toString().split('.')[0];
    final logMessage = '[$timestamp] MapScreen: $message';
    debugPrint(logMessage);
    if (mounted && !_disposed) {
      setState(() {
        _debugLog.add(logMessage);
        if (_debugLog.length > 50) {
          _debugLog.removeAt(0);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _logDebug('initState called');
    _initializeMap();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _disposed = true;
    _logDebug('dispose called');
    _locationSubscription?.cancel();
    _enemyMovementTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeMap() {
    _logDebug('_initializeMap called');
    _loadEpicFantasyMap();
    _generateRandomQuests();
    _generateTrailQuests();
    _loadAdventureQuests();
    _startEnemyMovement();
  }

  void _generateRandomQuests() {
    _logDebug('Generating random quests');
    
    // Generate enemy quests
    final enemyQuests = QuestGeneratorService.generateRandomEnemyQuests(
      centerLocation: _currentPosition,
      count: 8,
      radius: 0.02,
    );
    
    // Generate item quests
    final itemQuests = QuestGeneratorService.generateRandomItemQuests(
      centerLocation: _currentPosition,
      count: 5,
      radius: 0.02,
    );
    
    // Generate exploration quests
    final explorationQuests = QuestGeneratorService.generateRandomExplorationQuests(
      centerLocation: _currentPosition,
      count: 3,
      radius: 0.02,
    );
    
    setState(() {
      _randomQuests.clear();
      _randomQuests.addAll(enemyQuests);
      _randomQuests.addAll(itemQuests);
      _randomQuests.addAll(explorationQuests);
    });
    
    _updateQuestMarkers();
  }

  /// Load epic fantasy map data
  Future<void> _loadEpicFantasyMap() async {
    if (_isLoadingEpicMap) return;
    
    _logDebug('Loading epic fantasy map');
    setState(() {
      _isLoadingEpicMap = true;
    });
    
    try {
      final epicMapData = await EpicMapLoader().loadEpicMap();
      
      setState(() {
        _epicMapData = epicMapData;
        _isLoadingEpicMap = false;
      });
      
      _logDebug('Epic fantasy map loaded successfully');
    } catch (e) {
      _logDebug('Failed to load epic fantasy map: $e');
      setState(() {
        _isLoadingEpicMap = false;
      });
    }
  }

  /// Generate trail-based quests from real trail data
  Future<void> _generateTrailQuests() async {
    _logDebug('Generating trail quests');
    
    try {
      final trailQuests = await QuestGeneratorService.generateTrailQuests(
        centerLocation: _currentPosition,
        radiusKm: 100.0, // Look for trails within 100km
      );
      
      setState(() {
        _trailQuests.clear();
        _trailQuests.addAll(trailQuests);
      });
      
      _updateQuestMarkers();
      _logDebug('Generated ${trailQuests.length} trail quests');
    } catch (e) {
      _logDebug('Failed to generate trail quests: $e');
    }
  }

  void _checkAndGenerateQuestsIfNeeded() {
    // Only generate new quests if we don't have any or if we've moved far enough
    if (_randomQuests.isEmpty) {
      _generateRandomQuests();
      return;
    }
    
    // Check if we've moved far enough from existing quests to generate new ones
    final maxDistance = 0.01; // ~1km
    bool shouldGenerateNewQuests = true;
    
    for (final quest in _randomQuests) {
      if (quest.location == null) continue;
      
      final distance = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        quest.location!.latitude,
        quest.location!.longitude,
      );
      
      if (distance < maxDistance * 111000) { // Convert to meters
        shouldGenerateNewQuests = false;
        break;
      }
    }
    
    if (shouldGenerateNewQuests) {
      _logDebug('Player moved far from existing quests, generating new ones');
      _generateRandomQuests();
    }
  }

  void _updateQuestMarkers() {
    _logDebug('Updating quest markers');
    
    // Clear existing markers
    _enemyMarkers.clear();
    _itemMarkers.clear();
    _poiMarkers.clear();
    _trailMarkers.clear();
    _storylineMarkers.clear();
    _playerMarkers.clear();
    
    // Add player marker
    _playerMarkers.add(
      Marker(
        markerId: const MarkerId('player'),
        position: _currentPosition,
        icon: FantasyMapStyle.getPlayerMarker(),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'You are here',
        ),
      ),
    );
    
    // Add enemy markers
    for (final quest in _randomQuests.where((q) => q.type == QuestType.battle)) {
      final enemyType = quest.tags.firstWhere((tag) => tag.startsWith('enemy_type:')).split(':')[1];
      final isPatrolling = quest.tags.any((tag) => tag == 'is_patrolling:true');
      
      _enemyMarkers.add(
        Marker(
          markerId: MarkerId(quest.id),
          position: LatLng(quest.location!.latitude, quest.location!.longitude),
          icon: FantasyMapStyle.getEnemyMarkerIcon(enemyType),
          infoWindow: InfoWindow(
            title: quest.title,
            snippet: isPatrolling ? 'Patrolling $enemyType' : 'Stationary $enemyType',
            onTap: () => _startQuest(quest),
          ),
          onTap: () => _startQuest(quest),
        ),
      );
    }
    
    // Add item markers
    for (final quest in _randomQuests.where((q) => q.type == QuestType.treasure)) {
      final itemType = quest.tags.firstWhere((tag) => tag.startsWith('item_type:')).split(':')[1];
      
      _itemMarkers.add(
        Marker(
          markerId: MarkerId(quest.id),
          position: LatLng(quest.location!.latitude, quest.location!.longitude),
          icon: FantasyMapStyle.getQuestMarkerIcon('item'),
          infoWindow: InfoWindow(
            title: quest.title,
            snippet: 'Find the $itemType',
            onTap: () => _startQuest(quest),
          ),
          onTap: () => _startQuest(quest),
        ),
      );
    }
    
    // Add POI markers
    for (final quest in _poiQuests) {
      final poiName = quest.tags.firstWhere((tag) => tag.startsWith('poi_name:')).split(':')[1];
      final poiCategory = quest.tags.firstWhere((tag) => tag.startsWith('poi_category:')).split(':')[1];
      
      _poiMarkers.add(
        Marker(
          markerId: MarkerId(quest.id),
          position: LatLng(quest.location!.latitude, quest.location!.longitude),
          icon: FantasyMapStyle.getQuestMarkerIcon(_getQuestTypeFromCategory(poiCategory)),
          infoWindow: InfoWindow(
            title: quest.title,
            snippet: '$poiName - ${_getQuestTypeFromCategory(poiCategory)} quest',
            onTap: () => _startQuest(quest),
          ),
          onTap: () => _startQuest(quest),
        ),
      );
    }
    
    // Add trail quest markers
    for (final quest in _trailQuests) {
      _trailMarkers.add(
        Marker(
          markerId: MarkerId(quest.id),
          position: LatLng(quest.location!.latitude, quest.location!.longitude),
          icon: FantasyMapStyle.getQuestMarkerIcon('trail'),
          infoWindow: InfoWindow(
            title: quest.title,
            snippet: 'Trail quest',
            onTap: () => _startTrailQuest(quest),
          ),
          onTap: () => _startTrailQuest(quest),
        ),
      );
    }
    
    // Add storyline markers
    for (final quest in _storylineQuests) {
      _storylineMarkers.add(
        Marker(
          markerId: MarkerId(quest.id),
          position: LatLng(quest.location!.latitude, quest.location!.longitude),
          icon: FantasyMapStyle.getQuestMarkerIcon('storyline'),
          infoWindow: InfoWindow(
            title: quest.title,
            snippet: 'Main storyline quest',
            onTap: () => _startQuest(quest),
          ),
          onTap: () => _startQuest(quest),
        ),
      );
    }
  }

  String _getQuestTypeFromCategory(String category) {
    switch (category.toLowerCase()) {
      case 'gym':
      case 'fitness':
        return 'fitness';
      case 'pub':
      case 'bar':
      case 'restaurant':
        return 'social';
      case 'museum':
      case 'historic':
      case 'church':
        return 'historical';
      case 'park':
      case 'recreation':
        return 'exploration';
      default:
        return 'exploration';
    }
  }

  void _startQuest(Quest quest) {
    _logDebug('Starting quest: ${quest.title}');
    
    // Show quest details dialog instead of auto-adding
    _showQuestDetailsDialog(quest);
  }

  void _showQuestDetailsDialog(Quest quest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(quest.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quest.description),
            const SizedBox(height: 16),
            Text('Rewards:', style: Theme.of(context).textTheme.titleSmall),
            Text('XP: ${quest.rewards.xp}'),
            Text('Gold: ${quest.rewards.gold}'),
            if (quest.rewards.items.isNotEmpty)
              Text('Items: ${quest.rewards.items.join(', ')}'),
            const SizedBox(height: 16),
            Text('Distance: ${_calculateDistanceToQuest(quest).toStringAsFixed(0)}m'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _acceptQuest(quest);
            },
            child: const Text('Accept Quest'),
          ),
        ],
      ),
    );
  }

  void _acceptQuest(Quest quest) {
    _logDebug('Accepting quest: ${quest.title}');
    
    // Add quest to quest system
    final questActions = ref.read(questActionsProvider);
    questActions.addLocationQuest(quest.title, quest.location!.latitude, quest.location!.longitude, 'quest');
    
    // Create geofence automatically
    _createGeofenceForQuest(quest);
    
    // Show navigation option
    _showNavigationToQuest(quest);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quest accepted: ${quest.title}'),
        action: SnackBarAction(
          label: 'View Quests',
          onPressed: () => _navigateToQuestList(),
        ),
      ),
    );
  }

  double _calculateDistanceToQuest(Quest quest) {
    if (quest.location == null) return 0.0;
    
    return Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      quest.location!.latitude,
      quest.location!.longitude,
    );
  }

  void _createGeofenceForQuest(Quest quest) {
    if (quest.location == null) return;
    
    _logDebug('Creating geofence for quest: ${quest.title}');
    
    final geofenceId = 'geofence_${quest.id}';
    final geofence = Circle(
      circleId: CircleId(geofenceId),
      center: LatLng(quest.location!.latitude, quest.location!.longitude),
      radius: quest.location!.radius,
      fillColor: Colors.blue.withOpacity(0.2),
      strokeColor: Colors.blue,
      strokeWidth: 2,
    );
    
    setState(() {
      _geofences.add(geofence);
    });
  }

  void _showNavigationToQuest(Quest quest) {
    if (quest.location == null) return;
    
    _logDebug('Showing navigation to quest: ${quest.title}');
    
    // Get route to quest
    NavigationService.getRoute(
      origin: _currentPosition,
      destination: LatLng(quest.location!.latitude, quest.location!.longitude),
      mode: 'walking',
    ).then((routeInfo) {
      if (routeInfo != null) {
        setState(() {
          _currentRoute = routeInfo;
          _navigationRoutes.add(
            Polyline(
              polylineId: PolylineId('route_to_${quest.id}'),
              points: routeInfo.polylinePoints,
              color: Colors.blue,
              width: 4,
            ),
          );
        });
        
        // Show route info in a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Route to ${quest.title}: ${routeInfo.distance} (${routeInfo.duration})'),
            action: SnackBarAction(
              label: 'View Quests',
              onPressed: () => _navigateToQuestList(),
            ),
          ),
        );
      }
    });
  }

  void _startTrailQuest(Quest trailQuest) async {
    _logDebug('Starting trail quest: ${trailQuest.title}');
    
    // Extract trail ID from quest tags
    final trailIdTag = trailQuest.tags.firstWhere(
      (tag) => tag.startsWith('trail_id:'),
      orElse: () => '',
    );
    
    if (trailIdTag.isEmpty) {
      _startQuest(trailQuest);
      return;
    }
    
    final trailId = trailIdTag.split(':')[1];
    final trail = TrailService.getTrailById(trailId);
    
    if (trail == null) {
      _startQuest(trailQuest);
      return;
    }
    
    // ENHANCEMENT: Enable drive mode for trail
    await _startTrailWithDriveMode(trail, trailQuest);
  }
  
  /// ENHANCEMENT: Start trail with automatic drive/follow mode
  Future<void> _startTrailWithDriveMode(Trail trail, Quest quest) async {
    _logDebug('Starting trail with drive mode: ${trail.name}');
    
    setState(() {
      _activeTrail = trail;
      _currentWaypointIndex = 0;
      _isDriveMode = true;
    });
    
    // Add quest to quest system
    final questActions = ref.read(questActionsProvider);
    questActions.addLocationQuest(
      quest.title,
      trail.startLocation.latitude,
      trail.startLocation.longitude,
      'trail',
    );
    
    // Create geofences for all waypoints
    _createTrailGeofences(trail);
    
    // Start location tracking
    if (!_isTracking) {
      _startLocationTracking();
    }
    
    // ENHANCEMENT: Enable drive mode camera
    final currentPos = await Geolocator.getCurrentPosition();
    await _cameraController?.enableDriveMode(currentPos);
    
    // Show drive mode UI notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.navigation, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Drive Mode Active',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Camera will follow you at 45° angle',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Disable',
            textColor: Colors.white,
            onPressed: () => _disableDriveMode(),
          ),
        ),
      );
    }
  }
  
  /// Create geofences for trail waypoints
  void _createTrailGeofences(Trail trail) {
    _logDebug('Creating ${trail.waypoints.length} trail geofences');
    
    for (int i = 0; i < trail.waypoints.length; i++) {
      final waypoint = trail.waypoints[i];
      final geofence = Circle(
        circleId: CircleId('trail_waypoint_$i'),
        center: waypoint,
        radius: 30.0, // 30m radius for waypoint detection
        fillColor: Colors.green.withOpacity(0.2),
        strokeColor: Colors.green,
        strokeWidth: 2,
      );
      
      setState(() {
        _geofences.add(geofence);
      });
    }
  }
  
  /// Disable drive mode
  Future<void> _disableDriveMode() async {
    _logDebug('Disabling drive mode');
    
    setState(() {
      _isDriveMode = false;
    });
    
    await _cameraController?.disableFollowMode();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Drive mode disabled'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToQuestList() {
    // Navigate to quest list using MaterialPageRoute instead of named route
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QuestListScreen(),
      ),
    );
  }

  void _startEnemyMovement() {
    _enemyMovementTimer?.cancel();
    _enemyMovementTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      
      _updateMovingEnemies();
    });
  }

  void _updateMovingEnemies() {
    for (final quest in _randomQuests.where((q) => 
      q.type == QuestType.battle && 
      q.tags.any((tag) => tag == 'is_patrolling:true')
    )) {
      final enemyType = quest.tags.firstWhere((tag) => tag.startsWith('enemy_type:')).split(':')[1];
      final patrolSpeed = double.parse(quest.tags.firstWhere((tag) => tag.startsWith('patrol_speed:')).split(':')[1]);
      
      final currentPos = _movingEnemies[quest.id] ?? LatLng(quest.location!.latitude, quest.location!.longitude);
      
      // Move enemy in a random direction
      final random = Random();
      final angle = random.nextDouble() * 2 * pi;
      final distance = patrolSpeed;
      
      final newLat = currentPos.latitude + (distance * cos(angle));
      final newLng = currentPos.longitude + (distance * sin(angle));
      
      _movingEnemies[quest.id] = LatLng(newLat, newLng);
    }
    
    _updateQuestMarkers();
  }

  Future<void> _requestLocationPermission() async {
    _logDebug('Requesting location permission');
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _logDebug('Location services are disabled');
      return;
    }

    PermissionStatus status = await Permission.location.request();
    
    if (status.isGranted) {
      _logDebug('Location permission granted');
      setState(() {
        _locationPermissionGranted = true;
      });
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    _logDebug('Getting current location');
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logDebug('Location services are disabled');
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _logDebug('Location permission denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _logDebug('Location permission denied forever');
        return;
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      
      _logDebug('Current location: ${position.latitude}, ${position.longitude}');
      
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        
        // Move camera to current location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, 15.0),
        );
        
        _logDebug('Camera moved to current location');
        
        // Only load POIs, don't regenerate quests
        _loadPOIsAroundCurrentLocation();
        
        // Check if we need to generate new quests based on distance
        _checkAndGenerateQuestsIfNeeded();
      }
    } catch (e) {
      _logDebug('Error getting location: $e');
      // Fallback to a default location if GPS fails
      setState(() {
        _currentPosition = const LatLng(52.232192, -0.8912896); // Northampton area
      });
    }
  }

  void _startLocationTracking() {
    _logDebug('_startLocationTracking called');
    if (_isTracking) return;
    
    if (!_locationPermissionGranted) {
      _logDebug('Location permission not granted, requesting permission');
      _requestLocationPermission();
      return;
    }
    
    _logDebug('Started real location tracking');
    setState(() {
      _isTracking = true;
    });
    
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      _logDebug('Real location update: ${position.latitude}, ${position.longitude}');
      
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        
        // ENHANCEMENT: Update camera in drive mode
        if (_isDriveMode && _cameraController != null) {
          _cameraController!.updatePosition(position);
        }
        
        // ENHANCEMENT: Check trail waypoint progress
        if (_activeTrail != null) {
          _checkTrailWaypointProgress(position);
        }
        
        _checkNearbyQuests();
        _updateQuestMarkers();
      }
    });
  }

  /// ENHANCEMENT: Check trail waypoint progress with notifications
  void _checkTrailWaypointProgress(Position position) {
    if (_activeTrail == null) return;
    if (_currentWaypointIndex >= _activeTrail!.waypoints.length) return;
    
    final waypoint = _activeTrail!.waypoints[_currentWaypointIndex];
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      waypoint.latitude,
      waypoint.longitude,
    );
    
    // Check if reached waypoint (within 30m)
    if (distance <= 30.0) {
      _onWaypointReached(_currentWaypointIndex);
    }
  }
  
  /// Handle waypoint reached
  void _onWaypointReached(int waypointIndex) {
    _logDebug('Waypoint $waypointIndex reached!');
    
    setState(() {
      _currentWaypointIndex = waypointIndex + 1;
    });
    
    final progress = (_currentWaypointIndex / _activeTrail!.waypoints.length * 100).toStringAsFixed(0);
    
    // Show notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Waypoint ${waypointIndex + 1} Reached!',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Trail Progress: $progress%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    
    // Check if trail completed
    if (_currentWaypointIndex >= _activeTrail!.waypoints.length) {
      _onTrailCompleted();
    }
  }
  
  /// Handle trail completion
  void _onTrailCompleted() {
    _logDebug('Trail completed: ${_activeTrail!.name}');
    
    // Disable drive mode
    _disableDriveMode();
    
    // Show completion dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            const SizedBox(width: 12),
            const Text('Trail Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _activeTrail!.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('Distance: ${(_activeTrail!.distance / 1000).toStringAsFixed(1)} km'),
            Text('Elevation: ${_activeTrail!.elevationGain.toStringAsFixed(0)} m'),
            const SizedBox(height: 16),
            const Text(
              'Calculating rewards...',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _activeTrail = null;
                _currentWaypointIndex = 0;
              });
            },
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }
  
  void _checkNearbyQuests() {
    for (final quest in _randomQuests) {
      if (quest.location == null) continue;
      
      final distance = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        quest.location!.latitude,
        quest.location!.longitude,
      );
      
      if (distance <= quest.location!.radius) {
        _logDebug('Player is within range of quest: ${quest.title}');
        // Quest is available for interaction
      }
    }
  }

  Future<void> _loadPOIsAroundCurrentLocation() async {
    if (_isLoadingPOIs) return;
    
    _logDebug('Loading POIs around current location');
    setState(() {
      _isLoadingPOIs = true;
    });
    
    try {
      final pois = await POIService.getNearbyPOIs(
        latitude: _currentPosition.latitude,
        longitude: _currentPosition.longitude,
        radius: 1000, // 1km radius
      );
      
      _logDebug('Loaded ${pois.length} POIs');
      
      setState(() {
        _realPOIs.clear();
        _realPOIs.addAll(pois);
        _isLoadingPOIs = false;
      });
      
      _generatePOIQuests();
    } catch (e) {
      _logDebug('Error loading POIs: $e');
      setState(() {
        _isLoadingPOIs = false;
      });
    }
  }

  void _generatePOIQuests() {
    _logDebug('Generating POI quests');
    
    final poiQuests = <Quest>[];
    
    for (final poi in _realPOIs.take(10)) { // Limit to first 10 POIs
      final quest = QuestGeneratorService.generatePOIQuest(
        poiName: poi.name,
        poiCategory: poi.category,
        location: LatLng(poi.latitude, poi.longitude),
      );
      poiQuests.add(quest);
    }
    
    setState(() {
      _poiQuests.clear();
      _poiQuests.addAll(poiQuests);
    });
    
    _updateQuestMarkers();
  }

  Future<void> _loadTrailSegments() async {
    if (_isLoadingTrails) return;
    
    _logDebug('Loading trail segments');
    setState(() {
      _isLoadingTrails = true;
    });
    
    try {
      final trails = await TrailService.getAllTrails();
      
      _logDebug('Loaded ${trails.length} trail segments');
      
      setState(() {
        _isLoadingTrails = false;
      });
      
      _updateQuestMarkers();
    } catch (e) {
      _logDebug('Error loading trails: $e');
      setState(() {
        _isLoadingTrails = false;
      });
    }
  }

  Future<void> _loadAdventureQuests() async {
    _logDebug('Loading adventure quests');
    
    try {
      final weatherQuests = await AdventureApiService.getWeatherQuests(
        location: _currentPosition,
      );
      
      final heritageQuests = await AdventureApiService.getHeritageQuests(
        location: _currentPosition,
      );
      
      final seasonalQuests = await AdventureApiService.getSeasonalQuests(
        location: _currentPosition,
      );
      
      // Convert adventure quests to regular quests
      final allAdventureQuests = <Quest>[];
      
      for (final adventureQuest in [...weatherQuests, ...heritageQuests, ...seasonalQuests]) {
        final quest = Quest(
          id: 'adventure_quest_${adventureQuest.id}',
          title: adventureQuest.name,
          type: QuestType.location,
          category: QuestCategory.adventure,
          status: QuestStatus.notStarted,
          description: adventureQuest.description,
          objectives: [
            QuestObjective(
              id: 'complete_adventure',
              description: 'Complete the adventure',
              target: 1,
              progress: 0,
              type: 'adventure',
            ),
          ],
          rewards: QuestRewards(
            xp: adventureQuest.rewards.xp,
            gold: adventureQuest.rewards.gold,
            gems: adventureQuest.rewards.gems,
            items: adventureQuest.rewards.items,
          ),
          location: QuestLocation(
            latitude: adventureQuest.location.latitude,
            longitude: adventureQuest.location.longitude,
            radius: 100.0,
          ),
          tags: [
            'adventure_type:${adventureQuest.type.name}',
            'quest_type:adventure',
          ],
        );
        allAdventureQuests.add(quest);
      }
      
      setState(() {
        _storylineQuests.clear();
        _storylineQuests.addAll(allAdventureQuests);
      });
      
      _updateQuestMarkers();
    } catch (e) {
      _logDebug('Error loading adventure quests: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realm of Valor Map'),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Go to my location',
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _navigateToQuestList,
            tooltip: 'View quests',
          ),
        ],
      ),
      body: Stack(
        children: [
                     GoogleMap(
             onMapCreated: (GoogleMapController controller) {
               _mapController = controller;
               _cameraController = TrailCameraController(controller);
               _logDebug('Map created with camera controller');
               
               // Apply epic fantasy map style
               if (_epicMapData != null) {
                 controller.setMapStyle(_epicMapData!.mapStyle);
               } else {
                 controller.setMapStyle(FantasyMapStyle.getFantasyMapStyle());
               }
               
               if (_locationPermissionGranted) {
                 _getCurrentLocation();
               }
             },
             initialCameraPosition: _epicMapData?.initialCamera ?? CameraPosition(
               target: _currentPosition,
               zoom: 15.0,
             ),
             myLocationEnabled: true,
             myLocationButtonEnabled: false,
             zoomControlsEnabled: false,
             mapToolbarEnabled: false,
             markers: {
               ..._enemyMarkers,
               ..._itemMarkers,
               ..._poiMarkers,
               ..._trailMarkers,
               ..._storylineMarkers,
               ..._playerMarkers,
               ...(_epicMapData?.markers ?? {}),
             },
             circles: _geofences,
             polylines: {
               ..._navigationRoutes,
               ..._trailRoutes,
               ...(_epicMapData?.polylines ?? {}),
             },
             polygons: _epicMapData?.polygons ?? {},
             onTap: (LatLng position) {
               // No popups - just log the tap
               _logDebug('Map tapped at: ${position.latitude}, ${position.longitude}');
             },
           ),
          // Debug panel (only in debug mode)
          if (kDebugMode)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 200,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _debugLog.take(10).map((log) => Text(
                      log,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'location',
            onPressed: _getCurrentLocation,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'quests',
            onPressed: _navigateToQuestList,
            backgroundColor: Colors.green,
            child: const Icon(Icons.list, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

