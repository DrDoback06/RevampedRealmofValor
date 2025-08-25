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
import '../../../core/di.dart';
import '../quests/providers.dart';
import '../quests/quest_list_screen.dart';
import '../quests/quest_detail_screen.dart';
import 'fantasy_map_style.dart';
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
    
    // Add enemy markers with custom icons
    for (final quest in _randomQuests.where((q) => q.type == QuestType.battle)) {
      final enemyType = quest.tags.firstWhere((tag) => tag.startsWith('enemy_type:'), orElse: () => 'enemy_type:goblin').split(':')[1];
      final isPatrolling = quest.tags.any((tag) => tag == 'is_patrolling:true');
      
      _enemyMarkers.add(
        Marker(
          markerId: MarkerId(quest.id),
          position: LatLng(quest.location!.latitude, quest.location!.longitude),
          icon: _getCustomQuestIcon('enemy'),
          infoWindow: InfoWindow(
            title: quest.title,
            snippet: isPatrolling ? 'Patrolling $enemyType' : 'Stationary $enemyType',
            onTap: () => _startQuest(quest),
          ),
          onTap: () => _startQuest(quest),
        ),
      );
    }
    
    // Add item markers with custom icons
    for (final quest in _randomQuests.where((q) => q.type == QuestType.treasure)) {
      final itemType = quest.tags.firstWhere((tag) => tag.startsWith('item_type:'), orElse: () => 'item_type:treasure').split(':')[1];
      
      _itemMarkers.add(
        Marker(
          markerId: MarkerId(quest.id),
          position: LatLng(quest.location!.latitude, quest.location!.longitude),
          icon: _getCustomQuestIcon('item'),
          infoWindow: InfoWindow(
            title: quest.title,
            snippet: 'Find the $itemType',
            onTap: () => _startQuest(quest),
          ),
          onTap: () => _startQuest(quest),
        ),
      );
    }
    
    // Add POI markers with custom icons
    for (final quest in _poiQuests) {
      final poiName = quest.tags.firstWhere((tag) => tag.startsWith('poi_name:'), orElse: () => 'poi_name:Unknown').split(':')[1];
      final poiCategory = quest.tags.firstWhere((tag) => tag.startsWith('poi_category:'), orElse: () => 'poi_category:exploration').split(':')[1];
      
      _poiMarkers.add(
        Marker(
          markerId: MarkerId(quest.id),
          position: LatLng(quest.location!.latitude, quest.location!.longitude),
          icon: _getCustomQuestIcon(_getQuestTypeFromCategory(poiCategory)),
          infoWindow: InfoWindow(
            title: quest.title,
            snippet: '$poiName - ${_getQuestTypeFromCategory(poiCategory)} quest',
            onTap: () => _startQuest(quest),
          ),
          onTap: () => _startQuest(quest),
        ),
      );
    }
    
    // Add trail quest markers with custom icons
    for (final quest in _trailQuests) {
      _trailMarkers.add(
        Marker(
          markerId: MarkerId(quest.id),
          position: LatLng(quest.location!.latitude, quest.location!.longitude),
          icon: _getCustomQuestIcon('trail'),
          infoWindow: InfoWindow(
            title: quest.title,
            snippet: 'Trail quest',
            onTap: () => _startTrailQuest(quest),
          ),
          onTap: () => _startTrailQuest(quest),
        ),
      );
    }
    
    // Add storyline markers with custom icons
    for (final quest in _storylineQuests) {
      _storylineMarkers.add(
        Marker(
          markerId: MarkerId(quest.id),
          position: LatLng(quest.location!.latitude, quest.location!.longitude),
          icon: _getCustomQuestIcon('story'),
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

  BitmapDescriptor _getCustomQuestIcon(String questType) {
    switch (questType) {
      case 'enemy':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'item':
      case 'treasure':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'exploration':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'trail':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'story':
      case 'storyline':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.huePurple);
      case 'fitness':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case 'social':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
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
    
    // Navigate to quest detail screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuestDetailScreen(quest: quest),
      ),
    );
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

  void _startTrailQuest(Quest trailQuest) {
    _logDebug('Starting trail quest: ${trailQuest.title}');
    _startQuest(trailQuest);
  }

  void _navigateToQuestList() {
    // Navigate to quest list using MaterialPageRoute instead of named route
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QuestListScreen(),
      ),
    );
  }

  void _showQuestPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuestPanel(),
    );
  }

  Widget _buildQuestPanel() {
    final allQuests = [
      ..._randomQuests,
      ..._poiQuests,
      ..._trailQuests,
      ..._storylineQuests,
    ];

    // Sort quests by distance
    allQuests.sort((a, b) {
      if (a.location == null) return 1;
      if (b.location == null) return -1;
      
      final distanceA = _calculateDistanceToQuest(a);
      final distanceB = _calculateDistanceToQuest(b);
      return distanceA.compareTo(distanceB);
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.quest, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Nearby Quests (${allQuests.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Quest filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      _buildFilterChip('Enemy', QuestType.battle),
                      _buildFilterChip('Treasure', QuestType.treasure),
                      _buildFilterChip('Exploration', QuestType.location),
                      _buildFilterChip('Trail', null, isTrail: true),
                      _buildFilterChip('Story', QuestType.story),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Quest list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: allQuests.length,
                  itemBuilder: (context, index) {
                    final quest = allQuests[index];
                    return _buildQuestCard(quest);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, QuestType? type, {bool isTrail = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: false,
        onSelected: (selected) {
          // TODO: Implement filtering
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.orange[200],
      ),
    );
  }

  Widget _buildQuestCard(Quest quest) {
    final distance = _calculateDistanceToQuest(quest);
    final questType = _getQuestTypeString(quest.type);
    final questColor = _getQuestTypeColor(quest.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: questColor,
          child: Icon(
            _getQuestTypeIcon(quest.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          quest.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quest.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${distance.toStringAsFixed(0)}m'),
                const SizedBox(width: 16),
                Icon(Icons.star, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text('${quest.rewards.xp} XP'),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            setState(() {
              _selectedQuestId = quest.id;
            });
            _startQuest(quest);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: questColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Start'),
        ),
        onTap: () {
          Navigator.of(context).pop();
          setState(() {
            _selectedQuestId = quest.id;
          });
          _startQuest(quest);
        },
      ),
    );
  }

  String _getQuestTypeString(QuestType type) {
    switch (type) {
      case QuestType.battle:
        return 'Enemy';
      case QuestType.treasure:
        return 'Treasure';
      case QuestType.location:
        return 'Exploration';
      case QuestType.story:
        return 'Story';
      case QuestType.fitness:
        return 'Fitness';
      case QuestType.social:
        return 'Social';
      case QuestType.daily:
        return 'Daily';
      case QuestType.weekly:
        return 'Weekly';
    }
  }

  Color _getQuestTypeColor(QuestType type) {
    switch (type) {
      case QuestType.battle:
        return Colors.red;
      case QuestType.treasure:
        return Colors.blue;
      case QuestType.location:
        return Colors.green;
      case QuestType.story:
        return Colors.purple;
      case QuestType.fitness:
        return Colors.orange;
      case QuestType.social:
        return Colors.cyan;
      case QuestType.daily:
        return Colors.yellow;
      case QuestType.weekly:
        return Colors.indigo;
    }
  }

  IconData _getQuestTypeIcon(QuestType type) {
    switch (type) {
      case QuestType.battle:
        return Icons.sword;
      case QuestType.treasure:
        return Icons.chest;
      case QuestType.location:
        return Icons.explore;
      case QuestType.story:
        return Icons.book;
      case QuestType.fitness:
        return Icons.fitness_center;
      case QuestType.social:
        return Icons.people;
      case QuestType.daily:
        return Icons.today;
      case QuestType.weekly:
        return Icons.calendar_view_week;
    }
  }

  void _toggleLocationTracking() {
    setState(() {
      _isTracking = !_isTracking;
    });

    if (_isTracking) {
      _startLocationTracking();
    } else {
      _stopLocationTracking();
    }
  }

  void _startLocationTracking() {
    _logDebug('Starting location tracking');
    _locationSubscription?.cancel();
    
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(
      (Position position) {
        if (!_disposed) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
          _onLocationChanged();
        }
      },
      onError: (error) {
        _logDebug('Location tracking error: $error');
      },
    );
  }

  void _stopLocationTracking() {
    _logDebug('Stopping location tracking');
    _locationSubscription?.cancel();
  }

  void _navigateToSelectedQuest() {
    if (_selectedQuestId == null) return;

    final allQuests = [
      ..._randomQuests,
      ..._poiQuests,
      ..._trailQuests,
      ..._storylineQuests,
    ];

    final selectedQuest = allQuests.firstWhere(
      (quest) => quest.id == _selectedQuestId,
      orElse: () => throw Exception('Selected quest not found'),
    );

    if (selectedQuest.location == null) {
      _logDebug('Selected quest has no location');
      return;
    }

    _logDebug('Navigating to quest: ${selectedQuest.title}');
    _getRouteToQuest(selectedQuest);
  }

  Future<void> _getRouteToQuest(Quest quest) async {
    try {
      final route = await NavigationService.getRoute(
        origin: _currentPosition,
        destination: LatLng(quest.location!.latitude, quest.location!.longitude),
      );

      if (route != null) {
        setState(() {
          _currentRoute = route;
          _navigationRoutes.clear();
          _navigationRoutes.add(
            Polyline(
              polylineId: const PolylineId('quest_route'),
              points: route.points,
              color: Colors.purple,
              width: 4,
            ),
          );
        });

        // Animate camera to show the route
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            _getBoundsForRoute(route.points),
            50.0,
          ),
        );

        _logDebug('Route drawn to quest');
      } else {
        _logDebug('Failed to get route to quest');
      }
    } catch (e) {
      _logDebug('Error getting route: $e');
    }
  }

  LatLngBounds _getBoundsForRoute(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        southwest: _currentPosition,
        northeast: _currentPosition,
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
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
        
        _checkNearbyQuests();
        _updateQuestMarkers();
      }
    });
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
            onPressed: _showQuestPanel,
            tooltip: 'View nearby quests',
          ),
        ],
      ),
      body: Stack(
        children: [
                     GoogleMap(
             onMapCreated: (GoogleMapController controller) {
               _mapController = controller;
               _logDebug('Map created');
               
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
            heroTag: 'tracking',
            onPressed: _toggleLocationTracking,
            backgroundColor: _isTracking ? Colors.red : Colors.green,
            child: Icon(
              _isTracking ? Icons.stop : Icons.play_arrow,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'quests',
            onPressed: _showQuestPanel,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.list, color: Colors.white),
          ),
          if (_selectedQuestId != null) ...[
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'navigate',
              onPressed: _navigateToSelectedQuest,
              backgroundColor: Colors.purple,
              child: const Icon(Icons.navigation, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

