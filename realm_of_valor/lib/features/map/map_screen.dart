import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'dart:async';
import '../../../services/poi_service.dart';
import '../../../services/navigation_service.dart';
import '../../../services/trail_service.dart';
import '../../../services/adventure_api_service.dart';
import '../../../services/quest_generator_service.dart';
import '../../../services/epic_map_loader.dart';
import '../../../services/weather_service.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/models/weather_model.dart';
import '../../../integration/fitness_service.dart';
import '../../../services/event_bus.dart';
import '../../../core/di.dart';
import '../character/providers.dart';
import '../quests/providers.dart';
import '../quests/quest_detail_screen.dart';
import '../battle/battle_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> 
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _locationSubscription;
  LatLng _currentPosition = const LatLng(51.5074, -0.1278); // London default
  bool _locationPermissionGranted = false;
  bool _isTracking = false;
  
  // Quest markers
  final Set<Marker> _questMarkers = {};
  final Set<Marker> _playerMarkers = {};
  
  // Map elements
  final Set<Circle> _geofences = {};
  final Set<Polyline> _navigationRoutes = {};
  
  // Quest data
  final List<Quest> _availableQuests = [];
  final List<POI> _realPOIs = [];
  
  // Epic fantasy map data
  EpicMapData? _epicMapData;
  bool _isLoadingEpicMap = false;
  
  // State
  bool _isLoadingPOIs = false;
  bool _disposed = false;
  RouteInfo? _currentRoute;
  
  // Mini-map and compass
  bool _showMiniMap = true;
  bool _showCompass = true;
  double _compassRotation = 0.0;
  
  // Weather integration
  WeatherData? _currentWeather;
  Timer? _weatherUpdateTimer;
  bool _isWeatherEnabled = true;

  // UI State
  Quest? _hoveredQuest;
  Quest? _selectedQuest;
  bool _showQuestDetails = false;
  
  // Active Quest Tracking
  final List<Quest> _activeQuests = [];
  Timer? _questProgressTimer;
  final FitnessService _fitnessService = StubFitnessService();
  
  // GPS Spoofer for testing
  bool _showGpsSpoofer = false;
  double _spoofLatitude = 52.199424;
  double _spoofLongitude = -0.884736;
  double _spoofSpeed = 0.001; // Degrees per step
  
  // Animations
  late AnimationController _overlayAnimationController;
  late AnimationController _questHoverController;
  late Animation<double> _overlaySlideAnimation;
  late Animation<double> _questHoverAnimation;

  void _logDebug(String message) {
    final timestamp = DateTime.now().toString().split('.')[0];
    final logMessage = '[$timestamp] MapScreen: $message';
    debugPrint(logMessage);
  }

  void _initializeActiveQuestTracking() {
    _questProgressTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateActiveQuestProgress();
    });
  }

  void _updateActiveQuestProgress() async {
    if (_activeQuests.isEmpty) return;

    for (int i = 0; i < _activeQuests.length; i++) {
      final quest = _activeQuests[i];
      final updatedQuest = await _checkQuestProgress(quest);
      
      // Don't auto-complete for testing - just update progress
      _activeQuests[i] = updatedQuest;
    }
    
    setState(() {}); // Update UI
  }

  Future<Quest> _checkQuestProgress(Quest quest) async {
    List<QuestObjective> updatedObjectives = [];
    
    for (final objective in quest.objectives) {
      int newProgress = objective.progress;
      
      switch (objective.type) {
        case 'steps':
          final steps = await _fitnessService.stepsToday();
          newProgress = steps;
          break;
        case 'calories':
          final calories = await _fitnessService.caloriesBurnedToday();
          newProgress = calories.round();
          break;
        case 'distance':
          final distance = await _fitnessService.distanceTodayKm();
          newProgress = (distance * 1000).round(); // Convert to meters
          break;
        case 'location':
          if (quest.location != null) {
            final distance = Geolocator.distanceBetween(
              _currentPosition.latitude,
              _currentPosition.longitude,
              quest.location!.latitude,
              quest.location!.longitude,
            );
            newProgress = distance <= quest.location!.radius ? 1 : 0;
          }
          break;
        default:
          // Keep existing progress for other types
          break;
      }
      
      updatedObjectives.add(QuestObjective(
        id: objective.id,
        description: objective.description,
        target: objective.target,
        progress: newProgress,
        type: objective.type,
      ));
    }
    
    return Quest(
      id: quest.id,
      title: quest.title,
      type: quest.type,
      category: quest.category,
      status: updatedObjectives.every((obj) => obj.progress >= obj.target) 
          ? QuestStatus.completed 
          : QuestStatus.inProgress,
      description: quest.description,
      objectives: updatedObjectives,
      rewards: quest.rewards,
      location: quest.location,
      timeLimit: quest.timeLimit,
      prerequisites: quest.prerequisites,
      tags: quest.tags,
      createdAt: quest.createdAt,
      completedAt: updatedObjectives.every((obj) => obj.progress >= obj.target) 
          ? DateTime.now() 
          : quest.completedAt,
    );
  }

  void _completeQuest(Quest quest) {
    _logDebug('Quest completed: ${quest.title}');
    
    // Get character actions to update character
    final characterActions = ref.read(characterActionsProvider);
    final characterAsync = ref.read(characterStreamProvider);
    final character = characterAsync.value;
    
    _logDebug('Character: ${character?.name ?? 'null'}, XP: ${character?.xp ?? 0}');
    
    if (character != null) {
      // Give XP rewards
      if (quest.rewards.xp > 0) {
        _logDebug('Giving ${quest.rewards.xp} XP to character ${character.id}');
        // Update character XP through event bus
        ref.read(eventBusProvider).publish(Event(
          type: 'character.add_xp',
          data: {
            'characterId': character.id,
            'xp': quest.rewards.xp,
          },
        ));
        _logDebug('Published character.add_xp event');
      }
      
      // Give skill points for fitness quests
      if (quest.rewards.skillPoints > 0) {
        _logDebug('Giving ${quest.rewards.skillPoints} skill points to character ${character.id}');
        ref.read(eventBusProvider).publish(Event(
          type: 'character.add_skill_points',
          data: {
            'characterId': character.id,
            'skillPoints': quest.rewards.skillPoints,
          },
        ));
        _logDebug('Published character.add_skill_points event');
      }
      
      // Show completion notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quest completed! +${quest.rewards.xp} XP${quest.rewards.skillPoints > 0 ? ', +${quest.rewards.skillPoints} SP' : ''}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      _logDebug('Character is null, cannot give rewards');
    }
  }

  void _removeCompletedQuest(String questId) {
    _activeQuests.removeWhere((quest) => quest.id == questId);
    setState(() {});
  }

  void _showQuestSummary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quest Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Quests: ${_availableQuests.length}'),
            Text('Active Quests: ${_activeQuests.length}'),
            Text('Completed Today: ${_activeQuests.where((q) => q.status == QuestStatus.completed).length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsSpoofer() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.gps_fixed, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              const Text(
                'GPS Spoofer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showGpsSpoofer = false),
                child: const Icon(Icons.close, color: Colors.grey, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Movement controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDirectionButton('↑', () => _movePlayer(0, -1)),
              _buildDirectionButton('↓', () => _movePlayer(0, 1)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDirectionButton('←', () => _movePlayer(-1, 0)),
              _buildDirectionButton('→', () => _movePlayer(1, 0)),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Speed control
          Row(
            children: [
              const Text(
                'Speed:',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Expanded(
                child: Slider(
                  value: _spoofSpeed,
                  min: 0.0001,
                  max: 0.01,
                  divisions: 100,
                  activeColor: Colors.orange,
                  onChanged: (value) {
                    setState(() {
                      _spoofSpeed = value;
                    });
                  },
                ),
              ),
            ],
          ),
          
          Text(
            'Lat: ${_spoofLatitude.toStringAsFixed(6)}',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          Text(
            'Lng: ${_spoofLongitude.toStringAsFixed(6)}',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionButton(String direction, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.5)),
        ),
        child: Center(
          child: Text(
            direction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _movePlayer(int dx, int dy) {
    setState(() {
      _spoofLatitude += dy * _spoofSpeed;
      _spoofLongitude += dx * _spoofSpeed;
      _currentPosition = LatLng(_spoofLatitude, _spoofLongitude);
    });
    
    // Update player marker
    _updatePlayerMarker();
    
    // Check for nearby quests
    _checkNearbyQuests();
    
    // Generate new quests if needed
    _generateDynamicQuests();
  }

  void _checkNearbyQuests() {
    for (final quest in _availableQuests) {
      if (quest.location != null) {
        final distance = Geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          quest.location!.latitude,
          quest.location!.longitude,
        );
        
        // Dynamic distance based on quest type
        double requiredDistance = _getQuestRequiredDistance(quest.type);
        
        if (distance <= requiredDistance) {
          _logDebug('Near quest: ${quest.title} (${distance.round()}m away, required: ${requiredDistance.round()}m)');
          
          // Auto-start quest if close enough
          if (distance <= requiredDistance && quest.status == QuestStatus.notStarted) {
            _startQuest(quest);
          }
        }
      }
    }
  }

  double _getQuestRequiredDistance(QuestType type) {
    switch (type) {
      case QuestType.battle:
        return 30.0; // Need to be close for combat
      case QuestType.location:
        return 10.0; // Exact location required
      case QuestType.treasure:
        return 20.0; // Close to treasure
      case QuestType.fitness:
        return 100.0; // Can be done anywhere in area
      case QuestType.social:
        return 50.0; // Social interaction range
      case QuestType.story:
        return 25.0; // Story quest range
      case QuestType.daily:
        return 15.0; // Daily quest range
      case QuestType.weekly:
        return 40.0; // Weekly quest range
      default:
        return 50.0;
    }
  }

  void _generateDynamicQuests() {
    // Generate new quests around current position
    if (_availableQuests.length < 20) { // Keep quest count manageable
      final newQuests = <Quest>[];
      
      // Generate static quests at fixed locations
      for (int i = 0; i < 2; i++) {
        final questType = QuestType.values[_random.nextInt(QuestType.values.length)];
        final quest = _createStaticQuest(questType, i);
        newQuests.add(quest);
      }
      
      // Generate patrolling quests that move
      for (int i = 0; i < 2; i++) {
        final questType = QuestType.values[_random.nextInt(QuestType.values.length)];
        final quest = _createPatrollingQuest(questType, i);
        newQuests.add(quest);
      }
      
      // Generate dynamic quests near player
      for (int i = 0; i < 3; i++) {
        final questType = QuestType.values[_random.nextInt(QuestType.values.length)];
        final quest = _createDynamicQuest(questType, i);
        newQuests.add(quest);
      }
      
      _availableQuests.addAll(newQuests);
      _updateQuestMarkers();
      _logDebug('Generated ${newQuests.length} new quests (static, patrolling, dynamic)');
    }
  }

  Quest _createStaticQuest(QuestType type, int index) {
    final questId = 'static_quest_${DateTime.now().millisecondsSinceEpoch}_$index';
    
    // Create quest at a fixed location (not near player)
    final baseLat = 52.199424 + (_random.nextDouble() - 0.5) * 0.01; // Within ~1km
    final baseLng = -0.884736 + (_random.nextDouble() - 0.5) * 0.01;
    
    return Quest(
      id: questId,
      title: 'Static ${type.name} Quest ${index + 1}',
      type: type,
      category: QuestCategory.side,
      status: QuestStatus.notStarted,
      description: 'A quest that remains at a fixed location.',
      location: QuestLocation(
        latitude: baseLat,
        longitude: baseLng,
        name: 'Static Location ${index + 1}',
      ),
      rewards: QuestRewards(xp: 75 + _random.nextInt(100), gold: 50 + _random.nextInt(75)),
      tags: ['static', 'fixed'],
    );
  }

  Quest _createPatrollingQuest(QuestType type, int index) {
    final questId = 'patrol_quest_${DateTime.now().millisecondsSinceEpoch}_$index';
    
    // Create quest that "patrols" around an area
    final centerLat = 52.199424 + (_random.nextDouble() - 0.5) * 0.005;
    final centerLng = -0.884736 + (_random.nextDouble() - 0.5) * 0.005;
    
    return Quest(
      id: questId,
      title: 'Patrolling ${type.name} Quest ${index + 1}',
      type: type,
      category: QuestCategory.adventure,
      status: QuestStatus.notStarted,
      description: 'A quest that patrols around the area.',
      location: QuestLocation(
        latitude: centerLat,
        longitude: centerLng,
        radius: 100, // Larger radius for patrolling
        name: 'Patrol Area ${index + 1}',
      ),
      rewards: QuestRewards(xp: 100 + _random.nextInt(150), gold: 75 + _random.nextInt(100)),
      tags: ['patrolling', 'mobile'],
    );
  }

  Quest _createDynamicQuest(QuestType type, int index) {
    final questId = 'dynamic_quest_${DateTime.now().millisecondsSinceEpoch}_$index';
    
    return Quest(
      id: questId,
      title: 'Dynamic ${type.name} Quest ${index + 1}',
      type: type,
      category: QuestCategory.side,
      status: QuestStatus.notStarted,
      description: 'A dynamically generated quest near your location.',
      location: QuestLocation(
        latitude: _currentPosition.latitude + (_random.nextDouble() - 0.5) * 0.005,
        longitude: _currentPosition.longitude + (_random.nextDouble() - 0.5) * 0.005,
        name: 'Dynamic Location ${index + 1}',
      ),
      rewards: QuestRewards(xp: 50 + _random.nextInt(100), gold: 25 + _random.nextInt(50)),
      tags: ['dynamic', 'generated'],
    );
  }

  void _addActiveQuest(Quest quest) {
    if (!_activeQuests.any((q) => q.id == quest.id)) {
      _activeQuests.add(quest);
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMap();
    _initializeActiveQuestTracking();
  }

  void _initializeAnimations() {
    _overlayAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _questHoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _overlaySlideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _overlayAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _questHoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _questHoverController,
      curve: Curves.easeOutBack,
    ));
  }

  void _initializeMap() {
    _logDebug('initState called');
    _loadEpicFantasyMap();
    _generateQuests();
    _initializeWeatherSystem();
    _requestLocationPermission();
  }

  void _loadEpicFantasyMap() {
    _logDebug('Loading epic fantasy map');
    setState(() {
      _isLoadingEpicMap = true;
    });

    EpicMapLoader().loadEpicMap().then((mapData) {
      if (!_disposed) {
        setState(() {
          _epicMapData = mapData;
          _isLoadingEpicMap = false;
        });
        _logDebug('Epic fantasy map loaded successfully');
      }
    }).catchError((error) {
      _logDebug('Error loading epic map: $error');
      setState(() {
        _isLoadingEpicMap = false;
      });
    });
  }

  void _generateQuests() {
    _logDebug('Generating quests');
    
    // Generate some sample quests
    _availableQuests.clear();
    
    // Battle quests
    for (int i = 0; i < 5; i++) {
      final quest = Quest(
        id: 'battle_quest_$i',
        title: 'Defeat the ${_getEnemyName(i)}',
        type: QuestType.battle,
        category: QuestCategory.adventure,
        status: QuestStatus.notStarted,
        description: 'A dangerous enemy has appeared in the area. Defeat them to earn rewards.',
        location: QuestLocation(
          latitude: _currentPosition.latitude + (_random.nextDouble() - 0.5) * 0.01,
          longitude: _currentPosition.longitude + (_random.nextDouble() - 0.5) * 0.01,
          name: 'Battle Arena ${i + 1}',
        ),
        rewards: QuestRewards(xp: 100 + i * 50, gold: 50 + i * 25),
        tags: ['combat', 'battle'],
      );
      _availableQuests.add(quest);
    }
    
    // Location quests
    for (int i = 0; i < 3; i++) {
      final quest = Quest(
        id: 'location_quest_$i',
        title: 'Explore ${_getLocationName(i)}',
        type: QuestType.location,
        category: QuestCategory.adventure,
        status: QuestStatus.notStarted,
        description: 'Visit this location to discover its secrets.',
        location: QuestLocation(
          latitude: _currentPosition.latitude + (_random.nextDouble() - 0.5) * 0.01,
          longitude: _currentPosition.longitude + (_random.nextDouble() - 0.5) * 0.01,
          name: _getLocationName(i),
        ),
        rewards: QuestRewards(xp: 75 + i * 25, gold: 30 + i * 15),
        tags: ['exploration', 'location'],
      );
      _availableQuests.add(quest);
    }
    
    // Treasure quests
    for (int i = 0; i < 2; i++) {
      final quest = Quest(
        id: 'treasure_quest_$i',
        title: 'Find the ${_getTreasureName(i)}',
        type: QuestType.treasure,
        category: QuestCategory.side,
        status: QuestStatus.notStarted,
        description: 'Search for hidden treasure in this area.',
        location: QuestLocation(
          latitude: _currentPosition.latitude + (_random.nextDouble() - 0.5) * 0.01,
          longitude: _currentPosition.longitude + (_random.nextDouble() - 0.5) * 0.01,
          name: 'Treasure Location ${i + 1}',
        ),
        rewards: QuestRewards(xp: 50 + i * 25, gold: 100 + i * 50, gems: 1),
        tags: ['treasure', 'collection'],
      );
      _availableQuests.add(quest);
    }
    
    // Fitness quests
    for (int i = 0; i < 3; i++) {
      final fitnessObjectives = [
        QuestObjective(
          id: 'steps_$i',
          description: 'Walk ${5000 + i * 2000} steps',
          target: 5000 + i * 2000,
          progress: 0,
          type: 'steps',
        ),
        QuestObjective(
          id: 'calories_$i',
          description: 'Burn ${200 + i * 100} calories',
          target: 200 + i * 100,
          progress: 0,
          type: 'calories',
        ),
        QuestObjective(
          id: 'distance_$i',
          description: 'Walk ${3.0 + i * 1.5} km',
          target: (3000 + i * 1500).round(), // Convert to meters
          progress: 0,
          type: 'distance',
        ),
      ];
      
      final quest = Quest(
        id: 'fitness_quest_$i',
        title: 'Fitness Challenge ${i + 1}',
        type: QuestType.fitness,
        category: QuestCategory.side,
        status: QuestStatus.notStarted,
        description: 'Complete fitness goals to improve your character stats.',
        objectives: [fitnessObjectives[i]], // Use one objective per quest
        rewards: QuestRewards(
          xp: 75 + i * 25, 
          gold: 30 + i * 15,
          skillPoints: 1, // Fitness quests give skill points
        ),
        tags: ['fitness', 'health'],
      );
      _availableQuests.add(quest);
    }
    
    _updateQuestMarkers();
  }

  String _getEnemyName(int index) {
    final enemies = ['Dire Wolf', 'Goblin Scout', 'Orc Warrior', 'Troll', 'Dragon'];
    return enemies[index % enemies.length];
  }

  String _getLocationName(int index) {
    final locations = ['Ancient Ruins', 'Mysterious Cave', 'Hidden Temple'];
    return locations[index % locations.length];
  }

  String _getTreasureName(int index) {
    final treasures = ['Golden Chalice', 'Crystal Sword'];
    return treasures[index % treasures.length];
  }

  void _initializeWeatherSystem() {
    _logDebug('Initializing weather system');
    if (!_isWeatherEnabled) {
      _logDebug('Weather update disabled for now');
      return;
    }

    _weatherUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!_disposed && _isWeatherEnabled) {
        _updateWeather();
      }
    });
  }

  void _updateWeather() {
    // Mock weather update for now
    setState(() {
      _currentWeather = WeatherData(
        temperature: 15.0 + (_random.nextDouble() - 0.5) * 10,
        condition: 'Partly Cloudy',
        humidity: 60.0 + _random.nextDouble() * 20,
        pressure: 1013.0 + (_random.nextDouble() - 0.5) * 10,
        windSpeed: _random.nextDouble() * 20,
        icon: 'cloud',
      );
    });
  }

  void _requestLocationPermission() {
    _logDebug('Requesting location permission');
    Permission.location.request().then((status) {
      if (status.isGranted) {
        setState(() {
          _locationPermissionGranted = true;
        });
        _logDebug('Location permission granted');
        _getCurrentLocation();
        _startLocationTracking();
      } else {
        _logDebug('Location permission denied');
      }
    });
  }

  void _getCurrentLocation() {
    _logDebug('Getting current location');
    Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).then((position) {
      if (!_disposed) {
        final newPosition = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentPosition = newPosition;
        });
        _logDebug('Current location: ${position.latitude}, ${position.longitude}');
        _moveCameraToCurrentLocation();
        _loadPOIsAroundLocation();
      }
    }).catchError((error) {
      _logDebug('Error getting location: $error');
    });
  }

  void _startLocationTracking() {
    _logDebug('Starting location tracking');
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((position) {
      if (!_disposed) {
        final newPosition = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentPosition = newPosition;
        });
        _updatePlayerMarker();
      }
    });
  }

  void _moveCameraToCurrentLocation() {
    _logDebug('Camera moved to current location');
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition, 15.0),
    );
  }

  void _updateCompassRotation() {
    // Update compass based on map bearing
    if (_mapController != null) {
      _mapController!.getVisibleRegion().then((bounds) {
        // Calculate bearing from current position to map center
        final centerLat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
        final centerLng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
        
        final bearing = Geolocator.bearingBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          centerLat,
          centerLng,
        );
        
        setState(() {
          _compassRotation = bearing;
        });
      });
    }
  }

  void _loadPOIsAroundLocation() {
    _logDebug('Loading POIs around current location');
    setState(() {
      _isLoadingPOIs = true;
    });

    // Mock POI loading for now
    Future.delayed(const Duration(seconds: 1), () {
      if (!_disposed) {
        setState(() {
          _realPOIs.clear();
          // Add some mock POIs
          for (int i = 0; i < 5; i++) {
            _realPOIs.add(POI(
              id: 'poi_$i',
              name: _getPOIName(i),
              type: _getPOIType(i),
              latitude: _currentPosition.latitude + (_random.nextDouble() - 0.5) * 0.005,
              longitude: _currentPosition.longitude + (_random.nextDouble() - 0.5) * 0.005,
              rating: 4.0 + _random.nextDouble(),
            ));
          }
          _isLoadingPOIs = false;
        });
        _logDebug('Loaded ${_realPOIs.length} POIs');
      }
    });
  }

  String _getPOIName(int index) {
    final names = ['The Red Lion', 'Central Gym', 'Museum of History', 'City Park', 'Shopping Center'];
    return names[index % names.length];
  }

  String _getPOIType(int index) {
    final types = ['pub', 'gym', 'museum', 'park', 'shopping'];
    return types[index % types.length];
  }

  void _updateQuestMarkers() {
    _logDebug('Updating quest markers');
    
    // Clear existing markers
    _questMarkers.clear();
    
    // Add quest markers
    for (final quest in _availableQuests) {
      if (quest.location != null) {
        _questMarkers.add(
          Marker(
            markerId: MarkerId(quest.id),
            position: LatLng(quest.location!.latitude, quest.location!.longitude),
            icon: _getQuestMarkerIcon(quest.type),
            infoWindow: InfoWindow(
              title: quest.title,
              snippet: quest.description,
            ),
            onTap: () => _onQuestMarkerTapped(quest),
          ),
        );
      }
    }
    
    setState(() {});
  }

  BitmapDescriptor _getQuestMarkerIcon(QuestType type) {
    switch (type) {
      case QuestType.battle:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case QuestType.location:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case QuestType.treasure:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case QuestType.fitness:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case QuestType.social:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case QuestType.story:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case QuestType.daily:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case QuestType.weekly:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
    }
  }

  void _updatePlayerMarker() {
    _playerMarkers.clear();
    _playerMarkers.add(
      Marker(
        markerId: const MarkerId('player'),
        position: _currentPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: 'You',
          snippet: 'Current location',
        ),
      ),
    );
    setState(() {});
  }

  void _onQuestMarkerTapped(Quest quest) {
    _logDebug('Opening quest details: ${quest.title}');
    setState(() {
      _selectedQuest = quest;
      _showQuestDetails = true;
    });
    _overlayAnimationController.forward();
  }

  void _onQuestHover(Quest quest) {
    setState(() {
      _hoveredQuest = quest;
    });
    _questHoverController.forward();
  }

  void _onQuestHoverExit() {
    setState(() {
      _hoveredQuest = null;
    });
    _questHoverController.reverse();
  }

  void _startQuest(Quest quest) {
    _logDebug('Starting quest: ${quest.title}');
    
    // Add to active quests for tracking
    final activeQuest = Quest(
      id: quest.id,
      title: quest.title,
      type: quest.type,
      category: quest.category,
      status: QuestStatus.inProgress,
      description: quest.description,
      objectives: quest.objectives,
      rewards: quest.rewards,
      location: quest.location,
      timeLimit: quest.timeLimit,
      prerequisites: quest.prerequisites,
      tags: quest.tags,
      createdAt: DateTime.now(),
    );
    
    _addActiveQuest(activeQuest);
    
    if (quest.location != null) {
      // Calculate distance to quest
      final distance = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        quest.location!.latitude,
        quest.location!.longitude,
      );
      
      if (distance <= 50) { // Within 50 meters
        // Start the quest
        if (quest.type == QuestType.battle) {
          _startCombatQuest(quest);
        } else {
          _startExplorationQuest(quest);
        }
      } else {
        // Show navigation
        _showNavigationToQuest(quest);
      }
    }
  }

  void _startCombatQuest(Quest quest) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BattleScreen(
          enemyId: quest.id,
          enemyName: quest.title,
          enemyLevel: 1,
          enemyHp: 100,
          enemyAtk: 10,
          enemyDef: 5,
        ),
      ),
    );
  }

  void _startExplorationQuest(Quest quest) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuestDetailScreen(quest: quest),
      ),
    );
  }

  void _showNavigationToQuest(Quest quest) {
    if (quest.location != null) {
      _logDebug('Getting route to ${quest.title}');
      
      // Mock navigation for now
      setState(() {
        _currentRoute = RouteInfo(
          distance: '500 m',
          duration: '6 min',
          polylinePoints: [
            _currentPosition,
            LatLng(quest.location!.latitude, quest.location!.longitude),
          ],
          mode: 'walking',
          instructions: [
            'Head towards ${quest.title}',
            'Continue straight',
            'Arrive at destination',
          ],
        );
      });
      _updateNavigationRoute();
    }
  }

  void _updateNavigationRoute() {
    if (_currentRoute == null) return;
    
    _navigationRoutes.clear();
    _navigationRoutes.add(
      Polyline(
        polylineId: const PolylineId('navigation'),
        points: _currentRoute!.polylinePoints,
        color: Colors.blue,
        width: 5,
      ),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _disposed = true;
    _locationSubscription?.cancel();
    _weatherUpdateTimer?.cancel();
    _questProgressTimer?.cancel();
    _overlayAnimationController.dispose();
    _questHoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main map
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              _logDebug('Map created');
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 15.0,
            ),
            onCameraMove: (position) {
              // Update compass rotation
              setState(() {
                _compassRotation = position.bearing;
              });
            },
            markers: {
              ..._questMarkers,
              ..._playerMarkers,
            },
            circles: _geofences,
            polylines: _navigationRoutes,
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),
          
          // Quest hover overlay
          if (_hoveredQuest != null)
            Positioned(
              left: 20,
              top: 100,
              child: AnimatedBuilder(
                animation: _questHoverAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _questHoverAnimation.value,
                    child: _buildQuestHoverCard(_hoveredQuest!),
                  );
                },
              ),
            ),
          
          // Quest details overlay
          if (_showQuestDetails && _selectedQuest != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  // Close overlay when tapping outside
                  _overlayAnimationController.reverse().then((_) {
                    setState(() {
                      _showQuestDetails = false;
                      _selectedQuest = null;
                    });
                  });
                },
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () {}, // Prevent taps from going through to map
                          onPanUpdate: (details) {
                            // Allow swipe down to close
                            if (details.delta.dy > 10) {
                              _overlayAnimationController.reverse().then((_) {
                                setState(() {
                                  _showQuestDetails = false;
                                  _selectedQuest = null;
                                });
                              });
                            }
                          },
                          child: AnimatedBuilder(
                            animation: _overlaySlideAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, MediaQuery.of(context).size.height * _overlaySlideAnimation.value),
                                child: _buildQuestDetailsOverlay(_selectedQuest!),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Active Quest Overlay
          if (_activeQuests.isNotEmpty)
            Positioned(
              top: 120,
              left: 16,
              child: _buildActiveQuestOverlay(),
            ),
          
          // GPS Spoofer (for testing)
          if (_showGpsSpoofer)
            Positioned(
              bottom: 100,
              left: 16,
              child: _buildGpsSpoofer(),
            ),
          
          // Top UI bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopUI(),
          ),
          
          // Bottom navigation removed - handled by main app navigation
          
          // Compass
          if (_showCompass)
            Positioned(
              top: 120,
              right: 20,
              child: _buildCompass(),
            ),
          
          // Mini-map
          if (_showMiniMap)
            Positioned(
              top: 200,
              right: 20,
              child: _buildMiniMap(),
            ),
        ],
      ),
    );
  }

  Widget _buildTopUI() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.4),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  // If we can't pop, navigate to home
                  context.go('/');
                }
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Realm of Valor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Adventure Map',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Weather indicator
          if (_currentWeather != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getWeatherIcon(_currentWeather!.condition),
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_currentWeather!.temperature.round()}°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          // GPS Spoofer Toggle
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: GestureDetector(
              onTap: () => setState(() => _showGpsSpoofer = !_showGpsSpoofer),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _showGpsSpoofer ? Colors.orange.withOpacity(0.8) : Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      color: _showGpsSpoofer ? Colors.white : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'GPS',
                      style: TextStyle(
                        color: _showGpsSpoofer ? Colors.white : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildCompass() {
    return GestureDetector(
      onTap: () {
        // Center map on current location
        _moveCameraToCurrentLocation();
        _updateCompassRotation();
      },
      onLongPress: () {
        // Toggle compass visibility
        setState(() {
          _showCompass = !_showCompass;
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Transform.rotate(
          angle: -_compassRotation * (3.14159 / 180),
          child: const Icon(
            Icons.navigation,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMap() {
    return GestureDetector(
      onTap: () {
        // Show quest summary
        _showQuestSummary();
      },
      onLongPress: () {
        // Toggle mini-map visibility
        setState(() {
          _showMiniMap = !_showMiniMap;
        });
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Mini map background
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Map background pattern
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          image: const DecorationImage(
                            image: NetworkImage('https://maps.googleapis.com/maps/api/staticmap?center=52.199424,-0.884736&zoom=13&size=120x120&maptype=roadmap&key=AIzaSyCgAWPowBy2-0_KszZVUtu6aOScvUzqVU0'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Fallback if image fails
                      Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(
                            Icons.map,
                            color: Colors.white54,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Player position indicator (always centered)
              Positioned(
                left: 56, // Center of 120px container
                top: 56,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              // Quest markers around player
              ..._questMarkers.take(5).map((marker) {
                final quest = _availableQuests.firstWhere(
                  (q) => q.id == marker.markerId.value,
                  orElse: () => _availableQuests.first,
                );
                
                // Calculate relative position from player
                final latDiff = marker.position.latitude - _currentPosition.latitude;
                final lngDiff = marker.position.longitude - _currentPosition.longitude;
                
                // Convert to mini-map coordinates (simplified)
                final x = 56 + (lngDiff * 10000).clamp(-40.0, 40.0);
                final y = 56 + (latDiff * 10000).clamp(-40.0, 40.0);
                
                return Positioned(
                  left: x,
                  top: y,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _getQuestTypeColor(quest.type),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 0.5),
                    ),
                  ),
                );
              }),
              // Quest count indicator
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_questMarkers.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestHoverCard(Quest quest) {
    double distance = 0;
    if (quest.location != null) {
      distance = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        quest.location!.latitude,
        quest.location!.longitude,
      );
    }
    
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getQuestTypeColor(quest.type)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getQuestTypeIcon(quest.type),
                color: _getQuestTypeColor(quest.type),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quest.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getQuestTypeColor(quest.type),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  quest.type.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            quest.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${distance.round()}m away',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
              Text(
                'Reward: ${quest.rewards.xp} XP',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestDetailsOverlay(Quest quest) {
    double distance = 0;
    if (quest.location != null) {
      distance = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        quest.location!.latitude,
        quest.location!.longitude,
      );
    }
    
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: _getQuestTypeColor(quest.type)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Quest header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getQuestTypeColor(quest.type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getQuestTypeIcon(quest.type),
                    color: _getQuestTypeColor(quest.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        quest.type.name.toUpperCase(),
                        style: TextStyle(
                          color: _getQuestTypeColor(quest.type),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getQuestTypeColor(quest.type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    quest.category.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Quest details
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Description',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      quest.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quest info
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuestInfoCard(
                          'Distance',
                          '${distance.round()}m',
                          Icons.location_on,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuestInfoCard(
                          'Reward',
                          '${quest.rewards.xp} XP',
                          Icons.star,
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuestInfoCard(
                          'Type',
                          quest.type.name.toUpperCase(),
                          Icons.category,
                          _getQuestTypeColor(quest.type),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _overlayAnimationController.reverse().then((_) {
                        setState(() {
                          _showQuestDetails = false;
                          _selectedQuest = null;
                        });
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _overlayAnimationController.reverse().then((_) {
                        setState(() {
                          _showQuestDetails = false;
                          _selectedQuest = null;
                        });
                        _startQuest(quest);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getQuestTypeColor(quest.type),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(distance <= 50 ? 'Start Quest' : 'Navigate'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveQuestOverlay() {
    return Container(
      width: 300,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Active Quests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_activeQuests.length}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Quest list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _activeQuests.length,
              itemBuilder: (context, index) {
                final quest = _activeQuests[index];
                return _buildActiveQuestItem(quest);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveQuestItem(Quest quest) {
    final isCompleted = quest.status == QuestStatus.completed;
    
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted 
              ? Colors.green.withOpacity(0.5) 
              : _getQuestTypeColor(quest.type).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quest header
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : _getQuestTypeIcon(quest.type),
                color: isCompleted ? Colors.green : _getQuestTypeColor(quest.type),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quest.title,
                  style: TextStyle(
                    color: isCompleted ? Colors.green : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCompleted)
                GestureDetector(
                  onTap: () => _removeCompletedQuest(quest.id),
                  child: const Icon(
                    Icons.close,
                    color: Colors.grey,
                    size: 16,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Objectives
          ...quest.objectives.map((objective) => _buildObjectiveProgress(objective)),
          
          const SizedBox(height: 8),
          
          // Rewards preview
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(
                '${quest.rewards.xp} XP',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (quest.rewards.gold > 0) ...[
                const SizedBox(width: 8),
                const Icon(Icons.monetization_on, color: Colors.yellow, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${quest.rewards.gold} Gold',
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (quest.rewards.skillPoints > 0) ...[
                const SizedBox(width: 8),
                const Icon(Icons.psychology, color: Colors.purple, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${quest.rewards.skillPoints} SP',
                  style: const TextStyle(
                    color: Colors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          
          if (isCompleted) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'COMPLETED!',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildObjectiveProgress(QuestObjective objective) {
    final progress = objective.progress.clamp(0, objective.target);
    final percentage = objective.target > 0 ? progress / objective.target : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  objective.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$progress/${objective.target}',
                style: TextStyle(
                  color: percentage >= 1.0 ? Colors.green : Colors.white.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[700],
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 1.0 ? Colors.green : _getQuestTypeColor(QuestType.fitness),
            ),
          ),
        ],
      ),
    );
  }

  Color _getQuestTypeColor(QuestType type) {
    switch (type) {
      case QuestType.battle:
        return Colors.red;
      case QuestType.location:
        return Colors.blue;
      case QuestType.treasure:
        return Colors.amber;
      case QuestType.fitness:
        return Colors.green;
      case QuestType.social:
        return Colors.cyan;
      case QuestType.story:
        return Colors.purple;
      case QuestType.daily:
        return Colors.orange;
      case QuestType.weekly:
        return Colors.pink;
    }
  }

  IconData _getQuestTypeIcon(QuestType type) {
    switch (type) {
      case QuestType.battle:
        return Icons.gps_fixed;
      case QuestType.location:
        return Icons.location_on;
      case QuestType.treasure:
        return Icons.inventory;
      case QuestType.fitness:
        return Icons.fitness_center;
      case QuestType.social:
        return Icons.people;
      case QuestType.story:
        return Icons.book;
      case QuestType.daily:
        return Icons.today;
      case QuestType.weekly:
        return Icons.calendar_view_week;
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Icons.wb_sunny;
      case 'cloudy':
      case 'partly cloudy':
        return Icons.cloud;
      case 'rainy':
      case 'rain':
        return Icons.umbrella;
      case 'snowy':
      case 'snow':
        return Icons.ac_unit;
      case 'stormy':
      case 'thunderstorm':
        return Icons.thunderstorm;
      default:
        return Icons.cloud;
    }
  }
}

// Mock classes for compatibility
class POI {
  final String id;
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final double rating;

  POI({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.rating,
  });
}

class EpicMapData {
  // Mock epic map data
}

class EpicMapLoader {
  Future<EpicMapData> loadEpicMap() async {
    await Future.delayed(const Duration(seconds: 1));
    return EpicMapData();
  }
}

class WeatherData {
  final double temperature;
  final String condition;
  final double humidity;
  final double pressure;
  final double windSpeed;
  final String icon;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.icon,
  });
}

final Random _random = Random();


