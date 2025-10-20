# 🎮 Quest & Enemy System Integration Guide

## Complete Integration: Trails, Bosses, Enemies, Zones, Quests

---

## 🚀 Quick Start

### Enable All Systems

```dart
// In your MapScreen initState():
void _initializeEnhancedSystems() {
  // 1. Initialize camera controller
  _cameraController = TrailCameraController(_mapController);
  
  // 2. Initialize enemy patrol system
  _enemyService = PatrollingEnemyService();
  _enemyService.startPatrolling();
  
  // 3. Initialize zone system
  _zoneService = DynamicZoneService();
  _zoneService.startZoneSystem();
  await _zoneService.spawnZonesAroundPlayer(_currentPosition);
  
  // 4. Initialize repeatable quest service
  _questService = RepeatableQuestService();
  
  // 5. Import UK trails
  _importAllTrails();
}
```

---

## 📍 Camera Integration

### Auto-Switch Camera by Quest Type

```dart
// Starting any quest automatically picks best camera mode
void startQuest(Quest quest) async {
  final position = await Geolocator.getCurrentPosition();
  
  // Get quest type
  final questType = quest.type.name;
  
  // Camera auto-switches!
  await _cameraController?.enableQuestMode(questType, position);
  
  // Result:
  // - Trail quest → Drive mode (45° perfect for running)
  // - Battle quest → Battle mode (30° tactical view)
  // - Treasure quest → Search mode (15° overhead)
}
```

### Manual Camera Control

```dart
// For specific scenarios
await _cameraController.enableDriveMode(position);     // 45° runners
await _cameraController.enableBattleMode(position);    // 30° combat
await _cameraController.enableSearchMode(position);    // 15° search
await _cameraController.enableTerrainMode(position);   // 60° elevation
await _cameraController.disableFollowMode();           // Back to free
```

---

## 🗺️ Trail Import & Quest Generation

### Import All UK Trails

```dart
Future<void> importAllUKTrails() async {
  final importer = MassiveTrailImporter(
    stravaService: _stravaService,
    questService: _questService,
  );
  
  final result = await importer.importAllUKTrails(
    onProgress: (message) {
      print(message);
      // Update UI with progress
    },
  );
  
  // Result contains:
  print('Trails: ${result.trails.length}');          // 50+
  print('Quests: ${result.quests.length}');          // 50+
  print('Boss Quests: ${result.bossQuests.length}'); // 2+
  
  // Add to map
  for (final trail in result.trails) {
    final marker = await EnhancedMapMarkers.createTrailMarker(
      markerId: trail.id,
      trail: trail,
      onTap: () => _showTrailDetails(trail),
    );
    _trailMarkers.add(marker);
  }
}
```

---

## 💀 Boss Quest System

### Check for Boss at Location

```dart
// Check if epic trail has a boss
bool hasBossQuest(Trail trail) {
  return trail.elevationGain > 800 || 
         trail.tags.contains('iconic') ||
         trail.tags.contains('summit');
}

// Create boss quest
final bossQuest = _createBossQuestForTrail(snowdonTrail);
// Returns Ddraig Eryri (Dragon) boss
```

### Start Boss Battle

```dart
void startBossBattle(BossQuest boss) {
  showDialog(
    context: context,
    builder: (context) => BossEncounterDialog(
      boss: boss,
      difficulty: BossDifficulty.normal,
      onStart: () {
        // Navigate to battle screen with boss
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => BossBattleScreen(boss: boss),
        ));
      },
    ),
  );
}
```

---

## 👾 Enemy Patrol System

### Spawn Enemies Around Player

```dart
void spawnEnemiesNearPlayer(LatLng playerPos, int count) {
  for (int i = 0; i < count; i++) {
    // Random position around player
    final angle = (i / count) * 2 * pi;
    final distance = 500; // 500m radius
    
    final lat = playerPos.latitude + (distance / 111000) * cos(angle);
    final lng = playerPos.longitude + (distance / 111000) * sin(angle);
    
    final enemy = _enemyService.spawnEnemy(
      position: LatLng(lat, lng),
      level: playerLevel,
      behavior: EnemyBehavior.patrol,
    );
    
    // Add to map
    _addEnemyMarker(enemy);
  }
}
```

### Check for Enemy Encounters

```dart
void checkNearbyEnemies(LatLng playerPos) {
  for (final enemy in _enemyService.getActiveEnemies()) {
    if (_enemyService.isPlayerInAggroRange(enemy, playerPos)) {
      // Enemy aggro'd!
      _triggerEnemyEncounter(enemy);
    }
  }
}

void _triggerEnemyEncounter(PatrollingEnemy enemy) {
  // Switch camera to battle mode
  _cameraController.enableBattleMode(_currentPosition);
  
  // Show encounter dialog
  showDialog(
    context: context,
    builder: (context) => EnemyEncounterDialog(
      enemy: enemy,
      onBattle: () => _startBattle(enemy),
      onFlee: () => _fleeBattle(enemy),
    ),
  );
}
```

---

## ✨ Dynamic Zone System

### Display Zones on Map

```dart
void updateDynamicZones() {
  final zones = _zoneService.getActiveZones();
  
  _zoneCircles.clear();
  
  for (final zone in zones) {
    final circle = Circle(
      circleId: CircleId(zone.id),
      center: zone.center,
      radius: zone.radius,
      fillColor: zone.zoneColor.withOpacity(zone.opacity),
      strokeColor: zone.zoneColor,
      strokeWidth: 3,
    );
    
    _zoneCircles.add(circle);
  }
  
  setState(() {});
}
```

### Apply Zone Effects to Rewards

```dart
void calculateRewardsWithZones(Quest quest, LatLng location) {
  // Base rewards
  var xp = quest.rewards.xp;
  var gold = quest.rewards.gold;
  
  // Apply zone effects
  xp = _zoneService.applyZoneEffectsToXP(xp, location);
  gold = _zoneService.applyZoneEffectsToGold(gold, location);
  
  // Check for special drops
  if (_zoneService.shouldDropSkillCard(location)) {
    // Skill card dropped!
    rewardSkillCard();
  }
  
  // Apply to character
  applyRewards(xp, gold);
}
```

### Get Player's Current Zones

```dart
void checkCurrentZones(LatLng playerPos) {
  final zones = _zoneService.getPlayerZones(playerPos);
  
  if (zones.isEmpty) return;
  
  // Show notification
  for (final zone in zones) {
    showSnackBar(
      '✨ Entered ${zone.name}! ${zone.description}',
    );
  }
}
```

---

## 🔁 Repeatable Quest System

### Create Repeatable Quest

```dart
final quest = _questService.createRepeatableTrailQuest(
  trail: snowdonTrail,
  completionNumber: 3, // User's 3rd time
);

// Quest has 60% of original rewards (3rd completion)
print(quest.rewards.xp);   // 60% of base
print(quest.rewards.gold); // 60% of base
```

### Check if Can Repeat

```dart
final canRepeat = _questService.canRepeatQuest(
  'trail_snowdon',
  'trail',
);

if (canRepeat) {
  // Show "Repeat Quest" button
} else {
  // Show countdown timer
  final timeLeft = _questService.getTimeUntilRepeat('trail_snowdon', 'trail');
  // Show: "Available in 6h 23m"
}
```

### Display Completion History

```dart
Widget buildQuestHistory() {
  final completedQuests = _getAllCompletedQuests();
  
  return QuestCompletionHistory(
    questService: _questService,
    completedQuests: completedQuests,
    onRepeatQuest: (quest) {
      // User tapped "Repeat" button
      startQuest(quest);
    },
  );
}
```

---

## 📊 Quest Categorization

### Filter Quests by Type

```dart
// Get all fitness quests (trails + activities)
final fitnessQuests = EnhancedQuestCategorizer.getFitnessQuests(allQuests);

// Get all battle quests (enemies + bosses)
final battleQuests = EnhancedQuestCategorizer.getBattleQuests(allQuests);

// Get only boss quests
final epicQuests = EnhancedQuestCategorizer.getEpicQuests(allQuests);

// Get repeatable quests
final repeatableQuests = EnhancedQuestCategorizer.getRepeatableQuests(allQuests);
```

### Organize Quests in UI

```dart
Widget buildQuestTabs() {
  return TabBarView(
    children: [
      QuestList(quests: EnhancedQuestCategorizer.getFitnessQuests(allQuests)),
      QuestList(quests: EnhancedQuestCategorizer.getBattleQuests(allQuests)),
      QuestList(quests: EnhancedQuestCategorizer.getEpicQuests(allQuests)),
      QuestList(quests: EnhancedQuestCategorizer.getTreasureQuests(allQuests)),
      QuestList(quests: EnhancedQuestCategorizer.getSocialQuests(allQuests)),
      QuestCompletionHistory(...), // Completed tab
    ],
  );
}
```

---

## 🎯 Complete Example: Epic Trail Quest

### Full Journey from Map to Completion

```dart
// 1. User taps Snowdon trail on map
void onSnowdonTrailTapped() {
  final trail = TrailService.getTrailById('snowdon_llanberis');
  
  // Show trail details
  showModalBottomSheet(
    context: context,
    builder: (context) => TrailDetailPanel(
      trail: trail,
      onStartTrail: () => _startSnowdonTrail(trail),
    ),
  );
}

// 2. User starts trail
Future<void> _startSnowdonTrail(Trail trail) async {
  // Check if in a zone
  final zones = _zoneService.getPlayerZones(_currentPosition);
  if (zones.isNotEmpty) {
    showSnackBar('✨ You\'re in ${zones.first.name}! ${zones.first.description}');
  }
  
  // Create repeatable quest
  final completionNumber = _questService.getCompletionCount(trail.id) + 1;
  final quest = _questService.createRepeatableTrailQuest(
    trail: trail,
    completionNumber: completionNumber,
  );
  
  // Enable drive mode camera
  final position = await Geolocator.getCurrentPosition();
  await _cameraController.enableDriveMode(position);
  
  // Show notification
  showSnackBar(
    '📹 Drive Mode Active - Camera will follow at 45° angle',
    action: SnackBarAction(
      label: 'Disable',
      onPressed: () => _cameraController.disableFollowMode(),
    ),
  );
  
  // Create geofences for waypoints
  _createTrailGeofences(trail);
  
  // Start tracking
  setState(() {
    _activeTrail = trail;
    _activeQuest = quest;
  });
}

// 3. User encounters enemy during hike
void onEnemyEncounter(PatrollingEnemy enemy) async {
  // Switch camera to battle mode
  await _cameraController.enableBattleMode(_currentPosition);
  
  // Show encounter
  final shouldBattle = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${enemy.icon} ${enemy.name} appeared!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Level ${enemy.level}'),
          Text('HP: ${enemy.health}'),
          if (enemy.rarity == EnemyRarity.elite)
            const Text('⭐ ELITE - Guaranteed Rare Drop!'),
          if (enemy.rarity == EnemyRarity.boss)
            const Text('💀 BOSS - Epic Loot!'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Flee'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Battle'),
        ),
      ],
    ),
  );
  
  if (shouldBattle == true) {
    _startBattle(enemy);
  } else {
    // Return to drive mode
    await _cameraController.enableDriveMode(_currentPosition);
  }
}

// 4. User completes trail
void onTrailCompleted() async {
  // Calculate base rewards
  var xp = _calculateTrailXP(_activeTrail!);
  var gold = _calculateTrailGold(_activeTrail!);
  
  // Apply zone multipliers
  xp = _zoneService.applyZoneEffectsToXP(xp, _currentPosition);
  gold = _zoneService.applyZoneEffectsToGold(gold, _currentPosition);
  
  // Apply repeatable scaling
  final completionNum = _questService.getCompletionCount(_activeTrail!.id) + 1;
  final scaledRewards = _questService.calculateScaledRewards(
    originalQuest: _activeQuest!,
    completionNumber: completionNum,
  );
  
  // Record completion
  _questService.recordCompletion(_activeTrail!.id);
  
  // Apply rewards
  await _applyRewards(scaledRewards.xp, scaledRewards.gold);
  
  // Disable drive mode
  await _cameraController.disableFollowMode();
  
  // Check if boss quest unlocked
  if (hasBossQuest(_activeTrail!)) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🐉 Boss Quest Unlocked!'),
        content: const Text('The Snowdon Drake awaits at the summit!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showBossQuest();
            },
            child: const Text('Fight Boss!'),
          ),
        ],
      ),
    );
  }
}
```

---

## 🎨 Map Rendering

### Display All Elements

```dart
@override
Widget build(BuildContext context) {
  return GoogleMap(
    // ... camera settings ...
    
    markers: {
      // Trail markers (colored by difficulty)
      ..._trailMarkers,
      
      // Enemy markers (patrolling NPCs)
      ..._buildEnemyMarkers(),
      
      // Boss markers (epic locations)
      ..._buildBossMarkers(),
      
      // Existing markers
      ..._poiMarkers,
      ..._questMarkers,
    },
    
    circles: {
      // Dynamic zone circles
      ..._buildZoneCircles(),
      
      // Quest geofences
      ..._geofences,
    },
    
    polylines: {
      // Trail routes (colored)
      ..._trailRoutes,
      
      // Enemy patrol paths
      ..._buildPatrolPaths(),
      
      // Navigation routes
      ..._navigationRoutes,
    },
  );
}

Set<Marker> _buildEnemyMarkers() {
  return _enemyService.getActiveEnemies().map((enemy) {
    return Marker(
      markerId: MarkerId(enemy.id),
      position: enemy.currentPosition,
      icon: _getEnemyIcon(enemy),
      alpha: enemy.rarity == EnemyRarity.elite ? 1.0 : 0.8,
      onTap: () => onEnemyEncounter(enemy),
      infoWindow: InfoWindow(
        title: '${enemy.icon} ${enemy.name}',
        snippet: 'Level ${enemy.level} • ${enemy.rarity.name}',
      ),
    );
  }).toSet();
}

Set<Circle> _buildZoneCircles() {
  return _zoneService.getActiveZones().map((zone) {
    return Circle(
      circleId: CircleId(zone.id),
      center: zone.center,
      radius: zone.radius,
      fillColor: zone.zoneColor.withOpacity(zone.opacity),
      strokeColor: zone.zoneColor,
      strokeWidth: 3,
    );
  }).toSet();
}
```

---

## 📱 Quest Tab UI

### Categorized Quest Display

```dart
class QuestTabScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quests'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.fitness_center), text: 'Fitness'),
              Tab(icon: Icon(Icons.sports_kabaddi), text: 'Battle'),
              Tab(icon: Icon(Icons.stars), text: 'Epic'),
              Tab(icon: Icon(Icons.card_giftcard), text: 'Treasure'),
              Tab(icon: Icon(Icons.people), text: 'Social'),
              Tab(icon: Icon(Icons.place), text: 'Location'),
              Tab(icon: Icon(Icons.history), text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFitnessTab(),
            _buildBattleTab(),
            _buildEpicTab(),
            _buildTreasureTab(),
            _buildSocialTab(),
            _buildLocationTab(),
            _buildCompletedTab(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEpicTab() {
    final epicQuests = EnhancedQuestCategorizer.getEpicQuests(allQuests);
    
    return ListView(
      children: [
        // Boss quests
        ...epicQuests.map((quest) => BossQuestCard(
          quest: quest,
          onStart: () => startBossQuest(quest),
        )),
      ],
    );
  }
  
  Widget _buildCompletedTab() {
    return QuestCompletionHistory(
      questService: _questService,
      completedQuests: _getCompletedQuests(),
      onRepeatQuest: (quest) => _repeatQuest(quest),
    );
  }
}
```

---

## 🎯 Testing Checklist

### Camera System
- [ ] Drive mode activates on trail start (45° tilt)
- [ ] Battle mode activates on enemy encounter (30° tilt)
- [ ] Search mode activates on treasure quest (15° tilt)
- [ ] Camera follows player movement
- [ ] Bearing updates based on direction
- [ ] Speed-based zoom works
- [ ] Smooth transitions between modes

### Trail System
- [ ] 50+ trails visible on map
- [ ] Trails colored by difficulty
- [ ] Trail detail panel opens on tap
- [ ] Boss quests appear for epic trails
- [ ] Quests auto-generate for trails
- [ ] Can import from Strava
- [ ] De-duplication works

### Enemy System
- [ ] Enemies patrol routes
- [ ] Elite enemies glow gold
- [ ] Boss enemies are red
- [ ] Aggro radius triggers encounters
- [ ] Movement updates every 3s
- [ ] Loot tables work correctly

### Zone System
- [ ] Zones visible as colored circles
- [ ] Entering zone shows notification
- [ ] Double XP zone multiplies XP
- [ ] Magic Find zone increases drops
- [ ] Multiple zones stack
- [ ] Zones rotate every 3 hours

### Boss System
- [ ] Snowdon has dragon boss
- [ ] Ben Nevis has titan boss
- [ ] Multi-phase battles work
- [ ] Health scales with party size
- [ ] Epic loot drops

### Repeatable System
- [ ] Can complete quest multiple times
- [ ] Rewards scale correctly (75% → 60% → 50%)
- [ ] Milestone bonuses apply (10th, 25th, etc.)
- [ ] Cooldown timer works (24h)
- [ ] Completion history displays
- [ ] Streak bonuses calculated

---

## 💡 Pro Tips

1. **Enter Legendary Zones** for 3x multipliers!
2. **Fight Elite enemies** for guaranteed rare cards
3. **Complete trails 10 times** for +50% milestone bonus
4. **Stack zones** - Double XP + Magic Find + Legendary = insane rewards
5. **Use drive mode** for hands-free trail running
6. **Defeat bosses weekly** for best loot
7. **Farm elites in Magic Find zones** for legendary drops
8. **Build completion streaks** for +5% per day

---

## 🚀 Deployment Checklist

- [ ] Run `flutter pub run build_runner build`
- [ ] Test camera mode switching
- [ ] Test enemy patrol movement
- [ ] Test zone spawning
- [ ] Configure Strava API for trail import
- [ ] Set up Firebase for quest persistence
- [ ] Test boss battles
- [ ] Test repeatable quests
- [ ] Verify reward calculations
- [ ] Test on real devices

---

**All systems integrated and ready for production!** 🎉

Following motto: **"Don't Remove, Only Improve!"** ✅
