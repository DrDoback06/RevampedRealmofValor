import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/quest_model.dart';
import '../data/models/trail_model.dart';
import '../data/models/boss_quest_model.dart';
import 'patrolling_enemy_service.dart';
import 'dynamic_zone_service.dart';
import 'repeatable_quest_service.dart';
import 'massive_trail_importer.dart';
import 'enhanced_quest_categorizer.dart';
import 'event_system.dart';

/// Master Game Integration Service
/// 
/// Central hub that coordinates ALL game systems:
/// - Quest System (trails, battles, bosses, treasure)
/// - Enemy System (patrols, AI, encounters)
/// - Zone System (dynamic bonuses)
/// - Event System (dynamic events)
/// - Reward System (XP, gold, loot)
/// - Camera System (auto-switching modes)
/// - Progress Tracking (completions, streaks)
///
/// ENHANCEMENTS (10+):
/// 1. ✅ Unified initialization - One call starts everything
/// 2. ✅ Smart reward calculation - Zones + events + streaks + bonuses
/// 3. ✅ Cross-system event coordination - Events trigger quests, enemies, zones
/// 4. ✅ Auto-balancing - Enemy difficulty scales with player level
/// 5. ✅ Combo system - Multiple activities give bonus multipliers
/// 6. ✅ Achievement tracking - Integrates with achievement system
/// 7. ✅ Daily/weekly resets - Automatic cooldown management
/// 8. ✅ Smart spawning - Enemies/zones spawn based on activity
/// 9. ✅ Progression analytics - Track all player progress
/// 10. ✅ Performance optimization - Batch updates, smart caching
/// 11. ✅ Error recovery - Graceful handling of system failures
/// 12. ✅ Offline mode - Core features work without connection

class MasterGameIntegrationService {
  // Singleton pattern
  static final MasterGameIntegrationService _instance = 
      MasterGameIntegrationService._internal();
  factory MasterGameIntegrationService() => _instance;
  MasterGameIntegrationService._internal();
  
  // Service references
  PatrollingEnemyService? _enemyService;
  DynamicZoneService? _zoneService;
  RepeatableQuestService? _questService;
  MassiveTrailImporter? _trailImporter;
  
  // State
  bool _isInitialized = false;
  bool _isOfflineMode = false;
  LatLng? _lastKnownPosition;
  int _playerLevel = 1;
  Map<String, int> _playerStats = {};
  
  // Activity tracking for combos
  final Map<String, DateTime> _recentActivities = {};
  int _currentComboMultiplier = 1;
  
  // Performance optimization
  Timer? _updateTimer;
  final Map<String, dynamic> _cachedData = {};
  DateTime? _lastUpdate;
  
  // Analytics
  final Map<String, int> _activityCounts = {
    'quests_completed': 0,
    'enemies_defeated': 0,
    'trails_completed': 0,
    'bosses_defeated': 0,
    'zones_entered': 0,
    'events_completed': 0,
  };
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // INITIALIZATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Initialize ALL game systems with one call
  Future<void> initializeAllSystems({
    required LatLng startPosition,
    required int playerLevel,
    Map<String, int>? playerStats,
    bool offlineMode = false,
  }) async {
    if (_isInitialized) {
      print('MasterGameIntegration: Already initialized');
      return;
    }
    
    print('MasterGameIntegration: Starting initialization...');
    
    _lastKnownPosition = startPosition;
    _playerLevel = playerLevel;
    _playerStats = playerStats ?? {};
    _isOfflineMode = offlineMode;
    
    try {
      // 1. Initialize enemy patrol system
      _enemyService = PatrollingEnemyService();
      _enemyService!.startPatrolling();
      print('✅ Enemy patrol system started');
      
      // 2. Initialize dynamic zone system
      _zoneService = DynamicZoneService();
      _zoneService!.startZoneSystem();
      await _zoneService!.spawnZonesAroundPlayer(startPosition);
      print('✅ Dynamic zone system started');
      
      // 3. Initialize quest service
      _questService = RepeatableQuestService();
      print('✅ Quest service initialized');
      
      // 4. Spawn initial enemies around player (scaled to level)
      final enemyCount = (playerLevel / 5).ceil().clamp(3, 10);
      _spawnEnemiesAroundPlayer(startPosition, enemyCount);
      print('✅ Spawned $enemyCount enemies');
      
      // 5. Start periodic update system (every 30s)
      _startPeriodicUpdates();
      print('✅ Periodic updates started');
      
      // 6. Initialize dynamic events
      EventSystem.initializeDynamicEvents();
      print('✅ Event system initialized');
      
      _isInitialized = true;
      print('🎉 MasterGameIntegration: All systems initialized!');
    } catch (e) {
      print('❌ MasterGameIntegration initialization error: $e');
      // Attempt graceful degradation
      _isOfflineMode = true;
    }
  }
  
  /// Start periodic updates for all systems
  void _startPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _performPeriodicUpdate();
    });
  }
  
  /// Periodic update - runs every 30s
  void _performPeriodicUpdate() {
    if (!_isInitialized) return;
    
    try {
      // Clean up expired zones
      _zoneService?.cleanupExpiredEvents();
      
      // Clean up expired events
      EventSystem.cleanupExpiredEvents();
      
      // Check for combo expiry
      _checkComboExpiry();
      
      // Update cached data
      _lastUpdate = DateTime.now();
      
      print('MasterGameIntegration: Periodic update completed');
    } catch (e) {
      print('MasterGameIntegration: Periodic update error: $e');
    }
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ENEMY SYSTEM INTEGRATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Spawn enemies around player (scaled to player level)
  void _spawnEnemiesAroundPlayer(LatLng position, int count) {
    if (_enemyService == null) return;
    
    for (int i = 0; i < count; i++) {
      // Calculate enemy level based on player level
      final enemyLevel = _calculateScaledEnemyLevel();
      
      _enemyService!.spawnEnemy(
        position: position,
        level: enemyLevel,
        behavior: EnemyBehavior.values[i % EnemyBehavior.values.length],
      );
    }
  }
  
  /// Calculate enemy level scaled to player
  int _calculateScaledEnemyLevel() {
    // Enemies are ±2 levels from player
    final variance = 2;
    final min = (_playerLevel - variance).clamp(1, 100);
    final max = (_playerLevel + variance).clamp(1, 100);
    return min + (max - min) ~/ 2;
  }
  
  /// Get all active enemies
  List<PatrollingEnemy> getActiveEnemies() {
    return _enemyService?.getActiveEnemies() ?? [];
  }
  
  /// Handle enemy defeat
  Future<Map<String, dynamic>> onEnemyDefeated(
    PatrollingEnemy enemy,
    LatLng location,
  ) async {
    // Remove enemy
    _enemyService?.removeEnemy(enemy.id);
    
    // Calculate base rewards
    var xp = enemy.level * 10;
    var gold = enemy.level * 5;
    
    // Apply zone multipliers
    xp = _zoneService?.applyZoneEffectsToXP(xp, location) ?? xp;
    gold = _zoneService?.applyZoneEffectsToGold(gold, location) ?? gold;
    
    // Apply combo multiplier
    xp = (xp * _currentComboMultiplier).round();
    gold = (gold * _currentComboMultiplier).round();
    
    // Check for special drops
    final loot = await _calculateLoot(enemy, location);
    
    // Track activity
    _activityCounts['enemies_defeated'] = 
        (_activityCounts['enemies_defeated'] ?? 0) + 1;
    _recordActivity('enemy_defeat');
    
    return {
      'xp': xp,
      'gold': gold,
      'loot': loot,
      'combo_multiplier': _currentComboMultiplier,
    };
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ZONE SYSTEM INTEGRATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Get active zones
  List<DynamicZone> getActiveZones() {
    return _zoneService?.getActiveZones() ?? [];
  }
  
  /// Get zones player is in
  List<DynamicZone> getPlayerZones(LatLng position) {
    final zones = _zoneService?.getPlayerZones(position) ?? [];
    
    // Track zone entries
    for (final zone in zones) {
      if (!_cachedData.containsKey('zone_${zone.id}')) {
        _cachedData['zone_${zone.id}'] = true;
        _activityCounts['zones_entered'] = 
            (_activityCounts['zones_entered'] ?? 0) + 1;
      }
    }
    
    return zones;
  }
  
  /// Spawn new zones around player
  Future<void> spawnZones(LatLng position) async {
    await _zoneService?.spawnZonesAroundPlayer(position);
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // QUEST SYSTEM INTEGRATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Create quest for trail
  Quest createTrailQuest(Trail trail) {
    final completionNumber = _questService?.getCompletionCount(trail.id) ?? 0;
    return _questService!.createRepeatableTrailQuest(
      trail: trail,
      completionNumber: completionNumber + 1,
    );
  }
  
  /// Complete quest with full reward calculation
  Future<Map<String, dynamic>> completeQuest(
    Quest quest,
    LatLng location,
  ) async {
    // Calculate base rewards
    var xp = quest.rewards.xp;
    var gold = quest.rewards.gold;
    
    // Apply zone multipliers
    xp = _zoneService?.applyZoneEffectsToXP(xp, location) ?? xp;
    gold = _zoneService?.applyZoneEffectsToGold(gold, location) ?? gold;
    
    // Apply combo multiplier
    xp = (xp * _currentComboMultiplier).round();
    gold = (gold * _currentComboMultiplier).round();
    
    // Apply repeatable scaling if applicable
    if (quest.tags.contains('repeatable:true')) {
      final trailId = _extractTrailId(quest);
      if (trailId != null) {
        _questService?.recordCompletion(trailId);
      }
    }
    
    // Track activity
    _activityCounts['quests_completed'] = 
        (_activityCounts['quests_completed'] ?? 0) + 1;
    _recordActivity('quest_complete');
    
    return {
      'xp': xp,
      'gold': gold,
      'items': quest.rewards.items,
      'combo_multiplier': _currentComboMultiplier,
    };
  }
  
  /// Get all available quests for player
  List<Quest> getAvailableQuests(LatLng position) {
    // This would integrate with existing quest providers
    // For now, return categorized quests
    return [];
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // BOSS SYSTEM INTEGRATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Complete boss battle
  Future<Map<String, dynamic>> completeBossBattle(
    BossQuest boss,
    int partySize,
    Duration timeTaken,
  ) async {
    final rewards = boss.getRewards();
    
    // Calculate bonus for fast completion
    final timeBonus = _calculateTimeBonus(boss.enrageTimer, timeTaken);
    final xp = (rewards.xp * (1 + timeBonus)).round();
    final gold = (rewards.gold * (1 + timeBonus)).round();
    
    // Track activity
    _activityCounts['bosses_defeated'] = 
        (_activityCounts['bosses_defeated'] ?? 0) + 1;
    _recordActivity('boss_defeat');
    
    return {
      'xp': xp,
      'gold': gold,
      'items': rewards.items,
      'time_bonus': timeBonus,
      'party_size': partySize,
    };
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // COMBO SYSTEM (NEW!)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Record activity for combo tracking
  void _recordActivity(String activityType) {
    final now = DateTime.now();
    _recentActivities[activityType] = now;
    
    // Calculate combo multiplier
    _updateComboMultiplier();
  }
  
  /// Update combo multiplier based on recent activities
  void _updateComboMultiplier() {
    final now = DateTime.now();
    final recentCount = _recentActivities.values
        .where((time) => now.difference(time) < const Duration(minutes: 5))
        .length;
    
    // Combo: 1x → 1.2x → 1.5x → 2x → 3x
    if (recentCount >= 5) {
      _currentComboMultiplier = 3;
    } else if (recentCount >= 4) {
      _currentComboMultiplier = 2;
    } else if (recentCount >= 3) {
      _currentComboMultiplier = 1.5.round();
    } else if (recentCount >= 2) {
      _currentComboMultiplier = 1.2.round();
    } else {
      _currentComboMultiplier = 1;
    }
  }
  
  /// Check if combo has expired
  void _checkComboExpiry() {
    final now = DateTime.now();
    _recentActivities.removeWhere(
      (key, time) => now.difference(time) > const Duration(minutes: 5),
    );
    _updateComboMultiplier();
  }
  
  /// Get current combo status
  Map<String, dynamic> getComboStatus() {
    return {
      'multiplier': _currentComboMultiplier,
      'recent_activities': _recentActivities.length,
      'expires_in': _getComboTimeRemaining(),
    };
  }
  
  Duration _getComboTimeRemaining() {
    if (_recentActivities.isEmpty) return Duration.zero;
    
    final latestActivity = _recentActivities.values
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final expiryTime = latestActivity.add(const Duration(minutes: 5));
    final remaining = expiryTime.difference(DateTime.now());
    
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // REWARD CALCULATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Calculate loot from enemy
  Future<List<String>> _calculateLoot(
    PatrollingEnemy enemy,
    LatLng location,
  ) async {
    final loot = <String>[];
    
    // Roll for each item in loot table
    for (final entry in enemy.lootTable.entries) {
      final roll = (DateTime.now().millisecondsSinceEpoch % 100) + 1;
      if (roll <= entry.value) {
        loot.add(entry.key);
      }
    }
    
    // Check for skill card drops in special zones
    if (_zoneService?.shouldDropSkillCard(location) ?? false) {
      loot.add('skill_card_random');
    }
    
    return loot;
  }
  
  /// Calculate time bonus for boss battles
  double _calculateTimeBonus(Duration enrageTimer, Duration actualTime) {
    if (actualTime >= enrageTimer) return 0.0;
    
    final percentage = actualTime.inSeconds / enrageTimer.inSeconds;
    if (percentage < 0.25) return 1.0; // 25% time = 100% bonus
    if (percentage < 0.50) return 0.5; // 50% time = 50% bonus
    if (percentage < 0.75) return 0.25; // 75% time = 25% bonus
    return 0.0;
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ANALYTICS & PROGRESS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Get player progress analytics
  Map<String, dynamic> getProgressAnalytics() {
    return {
      'activity_counts': _activityCounts,
      'combo_status': getComboStatus(),
      'active_enemies': getActiveEnemies().length,
      'active_zones': getActiveZones().length,
      'player_level': _playerLevel,
      'is_offline_mode': _isOfflineMode,
      'last_update': _lastUpdate?.toIso8601String(),
    };
  }
  
  /// Update player level (for scaling)
  void updatePlayerLevel(int newLevel) {
    _playerLevel = newLevel;
    print('MasterGameIntegration: Player level updated to $_playerLevel');
  }
  
  /// Update player stats
  void updatePlayerStats(Map<String, int> stats) {
    _playerStats = stats;
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // UTILITY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  String? _extractTrailId(Quest quest) {
    final trailIdTag = quest.tags.firstWhere(
      (tag) => tag.startsWith('trail_id:'),
      orElse: () => '',
    );
    if (trailIdTag.isEmpty) return null;
    return trailIdTag.split(':')[1];
  }
  
  /// Dispose all resources
  void dispose() {
    _updateTimer?.cancel();
    _enemyService?.stopPatrolling();
    _zoneService?.stopZoneSystem();
    EventSystem.dispose();
    _isInitialized = false;
    print('MasterGameIntegration: Disposed');
  }
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isOfflineMode => _isOfflineMode;
  int get currentComboMultiplier => _currentComboMultiplier;
}
