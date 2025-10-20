# 🗺️ Map Integration Guide - All New Features

## Overview

This guide explains how to integrate all the enhanced features (trails, segments, Strava, fitness rewards, quests) with the existing map system.

---

## ✅ What's Been Added

### New Components

1. **TrailDetailPanel** (`lib/features/map/components/trail_detail_panel.dart`)
   - Full trail information display
   - 4 tabs: Info, Leaderboard, Elevation, Social
   - Real-time reward estimation
   - Weather and safety information
   - Friend activity tracking

2. **EnhancedMapMarkers** (`lib/features/map/components/enhanced_map_markers.dart`)
   - Difficulty-based color coding
   - Trail route polylines
   - Segment start/finish markers
   - Quest markers with animation
   - Geofence circles

3. **TrailEnhanced Model** (`lib/data/models/trail_model_enhanced.dart`)
   - 8+ enhancements beyond original spec
   - Strava segment integration
   - Dynamic difficulty calculation
   - Completion tracking
   - Weather data
   - Safety information
   - Social features

---

## 🔧 Integration Steps

### Step 1: Import New Components

Add to `map_screen.dart`:

```dart
import 'components/trail_detail_panel.dart';
import 'components/enhanced_map_markers.dart';
import '../../data/models/trail_model_enhanced.dart';
import '../../integration/strava_service.dart';
import '../../utils/fitness_rewards.dart';
```

### Step 2: Add State Variables

```dart
class _MapScreenState extends ConsumerState<MapScreen> {
  // ... existing code ...
  
  // New: Trail and segment tracking
  final List<TrailEnhanced> _enhancedTrails = [];
  final Map<String, dynamic> _stravaSegments = {};
  TrailEnhanced? _selectedTrail;
  
  // New: Strava service
  StravaService? _stravaService;
}
```

### Step 3: Load Trails with Enhanced Data

```dart
Future<void> _loadEnhancedTrails() async {
  _logDebug('Loading enhanced trails');
  
  setState(() {
    _isLoadingTrails = true;
  });
  
  try {
    // Load trails from service
    final trails = await TrailService.getAllTrails();
    
    // Enhance with Strava data if connected
    if (_stravaService?.isAuthenticated == true) {
      for (final trail in trails) {
        // Check if trail has Strava segment
        if (trail.stravaSegmentId != null) {
          final segment = await _stravaService!.getSegmentAchievements(
            int.parse(trail.stravaSegmentId!),
          );
          
          // Create enhanced trail with segment data
          final enhanced = TrailEnhanced(
            id: trail.id,
            name: trail.name,
            description: trail.description,
            startLocation: trail.startLocation,
            endLocation: trail.endLocation,
            waypoints: trail.waypoints,
            distance: trail.distance,
            elevationGain: trail.elevationGain,
            difficulty: trail.difficulty,
            type: trail.type,
            tags: trail.tags,
            region: trail.region,
            country: trail.country,
            rating: trail.rating,
            reviewCount: trail.reviewCount,
            imageUrl: trail.imageUrl,
            stravaSegmentId: trail.stravaSegmentId,
            segmentLeaderboard: segment.isNotEmpty ? {'entries': segment} : null,
            technicalRating: _calculateTechnicalRating(trail),
            exposureRating: _calculateExposureRating(trail),
            surfaceType: _inferSurfaceType(trail.tags),
            completionCount: trail.metadata['completions'] ?? 0,
            currentWeather: await _fetchWeather(trail.startLocation),
            recommendedTimeOfDay: _getRecommendedTime(trail),
            bestSeason: _determineBestSeason(trail),
            requiresPermit: trail.tags.contains('permit_required'),
            hasCellService: !trail.tags.contains('no_cell_service'),
            hazards: trail.tags.where((t) => t.startsWith('hazard:')).toList(),
            completedByFriends: await _getFriendsWhoCompleted(trail.id),
            allowedActivities: {
              TrailType.hiking: true,
              TrailType.running: trail.tags.contains('runnable'),
              TrailType.cycling: trail.tags.contains('bikeable'),
            },
          );
          
          _enhancedTrails.add(enhanced);
        }
      }
    }
    
    setState(() {
      _isLoadingTrails = false;
    });
    
    // Update map markers
    _updateEnhancedTrailMarkers();
    
  } catch (e) {
    _logDebug('Error loading enhanced trails: $e');
    setState(() {
      _isLoadingTrails = false;
    });
  }
}
```

### Step 4: Update Trail Markers on Map

```dart
Future<void> _updateEnhancedTrailMarkers() async {
  _logDebug('Updating enhanced trail markers');
  
  // Clear existing trail markers
  _trailMarkers.clear();
  _trailRoutes.clear();
  
  for (final trail in _enhancedTrails) {
    // Create trail marker
    final marker = await EnhancedMapMarkers.createTrailMarker(
      markerId: 'trail_${trail.id}',
      trail: trail,
      onTap: () => _showTrailDetails(trail),
    );
    
    _trailMarkers.add(marker);
    
    // Create trail route polyline
    final route = EnhancedMapMarkers.createTrailRoute(
      polylineId: 'route_${trail.id}',
      trail: trail,
      showElevationShading: true,
    );
    
    _trailRoutes.add(route);
    
    // Add segment markers if available
    if (trail.stravaSegmentId != null) {
      final segmentMarkers = EnhancedMapMarkers.createSegmentMarkers(
        segmentId: trail.stravaSegmentId!,
        start: trail.startLocation,
        finish: trail.endLocation,
        onTapStart: () => _showSegmentInfo(trail, isStart: true),
        onTapFinish: () => _showSegmentInfo(trail, isStart: false),
      );
      
      _trailMarkers.addAll(segmentMarkers);
    }
  }
  
  setState(() {});
}
```

### Step 5: Show Trail Detail Panel

```dart
void _showTrailDetails(TrailEnhanced trail) {
  setState(() {
    _selectedTrail = trail;
  });
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TrailDetailPanel(
      trail: trail,
      associatedQuest: _findQuestForTrail(trail.id),
      onStartTrail: () {
        Navigator.pop(context);
        _startTrailQuest(trail);
      },
      onAddToQuests: () {
        Navigator.pop(context);
        _addTrailToQuests(trail);
      },
      onNavigate: () {
        Navigator.pop(context);
        _navigateToTrail(trail);
      },
    ),
  );
}
```

### Step 6: Start Trail Quest

```dart
void _startTrailQuest(TrailEnhanced trail) {
  _logDebug('Starting trail quest for: ${trail.name}');
  
  // Create quest for trail
  final quest = Quest(
    id: 'trail_quest_${trail.id}',
    title: 'Complete ${trail.name}',
    type: QuestType.fitness,
    category: QuestCategory.adventure,
    status: QuestStatus.inProgress,
    description: trail.description,
    objectives: [
      QuestObjective(
        id: 'complete_trail',
        description: 'Complete the trail',
        target: 1,
        progress: 0,
        type: 'trail',
      ),
    ],
    rewards: QuestRewards(
      xp: _calculateTrailXP(trail),
      gold: _calculateTrailGold(trail),
      items: _getTrailRewardCards(trail),
    ),
    location: QuestLocation(
      latitude: trail.startLocation.latitude,
      longitude: trail.startLocation.longitude,
      radius: 100.0,
    ),
    tags: [
      'trail_id:${trail.id}',
      'trail_difficulty:${trail.difficulty.name}',
      'trail_distance:${trail.distance}',
      'trail_elevation:${trail.elevationGain}',
    ],
  );
  
  // Add to quest system
  final questActions = ref.read(questActionsProvider);
  questActions.addLocationQuest(
    quest.title,
    trail.startLocation.latitude,
    trail.startLocation.longitude,
    'trail',
  );
  
  // Create geofence for start
  final geofence = EnhancedMapMarkers.createQuestGeofence(
    circleId: 'trail_start_${trail.id}',
    center: trail.startLocation,
    radius: 50.0,
    fillColor: trail.difficultyColor,
    strokeColor: trail.difficultyColor,
  );
  
  setState(() {
    _geofences.add(geofence);
  });
  
  // Start tracking
  _startTrailTracking(trail);
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Trail quest started: ${trail.name}'),
      action: SnackBarAction(
        label: 'View',
        onPressed: () => _showTrailDetails(trail),
      ),
    ),
  );
}
```

### Step 7: Calculate Trail Rewards

```dart
int _calculateTrailXP(TrailEnhanced trail) {
  // Base XP from distance
  final distanceXP = (trail.distance / 1000 * 10).toInt();
  
  // Elevation bonus
  final elevationXP = (trail.elevationGain / 10).toInt();
  
  // Difficulty multiplier
  final multiplier = trail.rewardMultiplier;
  
  return ((distanceXP + elevationXP) * multiplier).toInt();
}

int _calculateTrailGold(TrailEnhanced trail) {
  // Base gold from distance
  final distanceGold = (trail.distance / 500).toInt();
  
  // Elevation bonus
  final elevationGold = (trail.elevationGain / 100).toInt();
  
  // Difficulty multiplier
  final multiplier = trail.rewardMultiplier;
  
  return ((distanceGold + elevationGold) * multiplier).toInt().clamp(10, 200);
}

List<String> _getTrailRewardCards(TrailEnhanced trail) {
  // Reward cards based on difficulty and completion
  final cards = <String>[];
  
  switch (trail.difficulty) {
    case TrailDifficulty.easy:
      cards.add('common_fitness_card');
      break;
    case TrailDifficulty.moderate:
      cards.add('uncommon_fitness_card');
      break;
    case TrailDifficulty.hard:
      cards.add('rare_fitness_card');
      break;
    case TrailDifficulty.expert:
      cards.addAll(['epic_fitness_card', 'trail_master_badge']);
      break;
  }
  
  // Bonus for first completion
  if (trail.lastCompletedAt == null) {
    cards.add('first_time_completion_badge');
  }
  
  return cards;
}
```

### Step 8: Track Trail Progress

```dart
void _startTrailTracking(TrailEnhanced trail) {
  _logDebug('Starting trail tracking');
  
  // Start location tracking if not already active
  if (!_isTracking) {
    _startLocationTracking();
  }
  
  // Subscribe to location updates to check trail progress
  _locationSubscription = Geolocator.getPositionStream().listen((position) {
    _checkTrailProgress(trail, position);
  });
}

void _checkTrailProgress(TrailEnhanced trail, Position position) {
  // Check if user is on the trail
  for (int i = 0; i < trail.waypoints.length; i++) {
    final waypoint = trail.waypoints[i];
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      waypoint.latitude,
      waypoint.longitude,
    );
    
    if (distance < 50) { // Within 50m of waypoint
      _logDebug('Reached waypoint $i on trail ${trail.name}');
      
      // Update quest progress
      final progress = (i + 1) / trail.waypoints.length;
      _updateQuestProgress('trail_quest_${trail.id}', progress);
      
      // Check if trail completed
      if (i == trail.waypoints.length - 1) {
        _completeTrailQuest(trail);
      }
    }
  }
}
```

### Step 9: Complete Trail Quest

```dart
void _completeTrailQuest(TrailEnhanced trail) {
  _logDebug('Trail completed: ${trail.name}');
  
  // Calculate actual rewards based on completion time
  final completionTime = DateTime.now().difference(trail.lastCompletedAt ?? DateTime.now());
  
  // Create fitness activity for rewards
  final activity = FitnessActivity(
    distanceKm: trail.distance / 1000,
    elevationMeters: trail.elevationGain,
    durationSeconds: completionTime.inSeconds,
    averageHeartRate: 140, // Would come from fitness tracker
    maxHeartRate: 170,
    activityType: trail.type == TrailType.running ? 'running' : 'hiking',
    timestamp: DateTime.now(),
  );
  
  // Calculate rewards using fitness reward system
  final rewards = FitnessRewardCalculator.calculateRewards(
    activity: activity,
    streak: _currentFitnessStreak,
    goldEarnedToday: _goldEarnedToday,
    xpEarnedToday: _xpEarnedToday,
  );
  
  // Apply rewards
  final eventBus = ref.read(eventBusProvider);
  eventBus.publish(Event(
    type: 'fitness.submit_activity',
    data: {
      'distanceKm': activity.distanceKm,
      'elevationMeters': activity.elevationMeters,
      'durationSeconds': activity.durationSeconds,
      'averageHeartRate': activity.averageHeartRate,
      'maxHeartRate': activity.maxHeartRate,
      'activityType': activity.activityType,
      'timestamp': activity.timestamp.toIso8601String(),
    },
  ));
  
  // Show completion dialog
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('🎉 Trail Completed!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('You completed ${trail.name}!'),
          const SizedBox(height: 16),
          Text('Rewards:'),
          Text('💰 Gold: ${rewards.goldEarned}'),
          Text('⭐ XP: ${rewards.xpEarned}'),
          if (rewards.buff != null)
            Text('💪 Buff: +${rewards.buff!.attackBonus} ATK for ${rewards.buff!.remainingMinutes}min'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Awesome!'),
        ),
      ],
    ),
  );
}
```

---

## 🎨 UI Enhancements

### Difficulty Color Scheme

```dart
Colors for trail markers:
- Easy: Green (#4CAF50)
- Moderate: Blue (#2196F3)
- Hard: Orange (#FF9800)
- Expert: Red (#F44336)
```

### Map Legend

Add to map UI:

```dart
Widget _buildMapLegend() {
  return Positioned(
    bottom: 100,
    left: 16,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trail Difficulty', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildLegendItem(Colors.green, 'Easy'),
          _buildLegendItem(Colors.blue, 'Moderate'),
          _buildLegendItem(Colors.orange, 'Hard'),
          _buildLegendItem(Colors.red, 'Expert'),
        ],
      ),
    ),
  );
}

Widget _buildLegendItem(Color color, String label) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    ),
  );
}
```

---

## 📊 Data Flow

```
User Taps Trail Marker
    ↓
TrailDetailPanel Opens
    ↓
Shows: Info, Leaderboard, Elevation, Social tabs
    ↓
User Taps "Start Trail"
    ↓
Quest Created with Trail Data
    ↓
Geofences Created at Start/End
    ↓
Location Tracking Begins
    ↓
Progress Tracked via Waypoints
    ↓
Completion Detected
    ↓
Fitness Activity Submitted
    ↓
Rewards Calculated & Applied
    ↓
XP, Gold, Buffs Added to Character
```

---

## 🔗 Key Integrations

### 1. Strava Integration
- Trails can have `stravaSegmentId`
- Leaderboard data pulled from Strava API
- Personal best times tracked
- Auto-sync after trail completion

### 2. Fitness Rewards
- Distance → Gold (1 per 0.5km)
- Elevation → Gold (1 per 100m)
- Heart rate → Temporary buffs
- Streak bonuses applied

### 3. Quest System
- Trails auto-generate quests
- Difficulty affects rewards
- Completion tracked via geofences
- Progress saved to character

### 4. Social Features
- See which friends completed trail
- Recent completions shown
- Leaderboard integration
- Share trail recommendations

---

## 🚀 Testing Checklist

- [ ] Trails load on map with correct colors
- [ ] Trail detail panel opens on tap
- [ ] Rewards calculation is accurate
- [ ] Geofences trigger correctly
- [ ] Quest progress updates properly
- [ ] Fitness rewards apply after completion
- [ ] Strava segments display (if connected)
- [ ] Friend data shows correctly
- [ ] Weather info displays
- [ ] Safety warnings appear

---

## 📝 Notes

- All existing map features preserved (motto: "Don't remove, only improve!")
- Trail data can come from multiple sources (Strava, AllTrails, custom DB)
- Difficulty can be calculated dynamically or set manually
- Rewards scale with difficulty multiplier (1x, 1.5x, 2x, 3x)
- UI is fully responsive and works on all screen sizes

---

Ready to integrate! 🎉
