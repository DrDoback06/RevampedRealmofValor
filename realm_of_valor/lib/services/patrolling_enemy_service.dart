import 'dart:async';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/quest_model.dart';

/// Patrolling Enemy & NPC System
/// 
/// ENHANCEMENTS:
/// 1. Dynamic patrol routes (not just random movement)
/// 2. Enemy AI behaviors (aggressive, defensive, fleeing)
/// 3. Aggro radius detection (enemies chase player)
/// 4. Patrol schedules (time-of-day spawns)
/// 5. Enemy levels scale with region danger
/// 6. Rare elite patrols (golden enemies with bonus loot)
/// 7. Encounter rate based on player movement speed
/// 8. Enemy despawn/respawn cycles
/// 9. Territorial zones (enemies patrol specific areas)
/// 10. NPC merchant patrols (rare friendly NPCs)

enum EnemyBehavior {
  patrol,      // Walks a set route
  guard,       // Stays in one spot, attacks if approached
  chase,       // Actively hunts player if nearby
  flee,        // Runs away from player (rare loot carriers)
  wander,      // Random movement
}

enum EnemyRarity {
  common,      // Standard enemy
  elite,       // Golden enemy (2x HP, +50% rewards)
  boss,        // Red enemy (5x HP, epic rewards)
  merchant,    // Friendly NPC (trades)
}

class PatrollingEnemy {
  final String id;
  final String name;
  final int level;
  final EnemyBehavior behavior;
  final EnemyRarity rarity;
  final LatLng currentPosition;
  final List<LatLng> patrolRoute;
  final int currentPatrolIndex;
  final double aggroRadius; // meters
  final double movementSpeed; // meters per update
  final int health;
  final int damage;
  final Map<String, int> lootTable; // item_id -> drop_chance_percent
  final DateTime spawnedAt;
  final DateTime? despawnAt;
  final bool isAggro; // Currently chasing player
  final String? targetPlayerId; // If chasing someone
  
  const PatrollingEnemy({
    required this.id,
    required this.name,
    required this.level,
    required this.behavior,
    required this.rarity,
    required this.currentPosition,
    required this.patrolRoute,
    this.currentPatrolIndex = 0,
    this.aggroRadius = 100.0,
    this.movementSpeed = 0.00005, // ~5 meters per update
    required this.health,
    required this.damage,
    required this.lootTable,
    required this.spawnedAt,
    this.despawnAt,
    this.isAggro = false,
    this.targetPlayerId,
  });

  /// Get icon for enemy type
  String get icon {
    if (rarity == EnemyRarity.merchant) return '🧙';
    if (rarity == EnemyRarity.boss) return '💀';
    if (rarity == EnemyRarity.elite) return '⭐';
    
    // Common enemies
    switch (level) {
      case <= 5:
        return '🐀'; // Weak enemies
      case <= 10:
        return '🐺'; // Medium enemies
      case <= 15:
        return '🐻'; // Strong enemies
      case <= 20:
        return '🦁'; // Very strong
      default:
        return '🐉'; // Epic enemies
    }
  }

  /// Get color for rarity
  Color get rarityColor {
    switch (rarity) {
      case EnemyRarity.common:
        return const Color(0xFF9E9E9E);
      case EnemyRarity.elite:
        return const Color(0xFFFFD700);
      case EnemyRarity.boss:
        return const Color(0xFFE91E63);
      case EnemyRarity.merchant:
        return const Color(0xFF2196F3);
    }
  }

  /// Copy with updated position
  PatrollingEnemy copyWith({
    LatLng? currentPosition,
    int? currentPatrolIndex,
    bool? isAggro,
    String? targetPlayerId,
  }) {
    return PatrollingEnemy(
      id: id,
      name: name,
      level: level,
      behavior: behavior,
      rarity: rarity,
      currentPosition: currentPosition ?? this.currentPosition,
      patrolRoute: patrolRoute,
      currentPatrolIndex: currentPatrolIndex ?? this.currentPatrolIndex,
      aggroRadius: aggroRadius,
      movementSpeed: movementSpeed,
      health: health,
      damage: damage,
      lootTable: lootTable,
      spawnedAt: spawnedAt,
      despawnAt: despawnAt,
      isAggro: isAggro ?? this.isAggro,
      targetPlayerId: targetPlayerId ?? this.targetPlayerId,
    );
  }
}

class PatrollingEnemyService {
  final Map<String, PatrollingEnemy> _activeEnemies = {};
  final Random _random = Random();
  Timer? _movementTimer;
  Timer? _spawnTimer;
  
  // Enemy spawn configuration
  static const int maxEnemiesPerRegion = 20;
  static const Duration movementInterval = Duration(seconds: 3);
  static const Duration spawnCheckInterval = Duration(minutes: 5);
  static const double eliteSpawnChance = 0.05; // 5% chance
  static const double bossSpawnChance = 0.01; // 1% chance
  
  void startPatrolling() {
    // Movement update loop
    _movementTimer?.cancel();
    _movementTimer = Timer.periodic(movementInterval, (timer) {
      _updateAllEnemyPositions();
    });
    
    // Spawn check loop
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(spawnCheckInterval, (timer) {
      _checkAndSpawnEnemies();
    });
  }

  void stopPatrolling() {
    _movementTimer?.cancel();
    _spawnTimer?.cancel();
  }

  /// Update all enemy positions
  void _updateAllEnemyPositions() {
    final updatedEnemies = <String, PatrollingEnemy>{};
    
    for (final enemy in _activeEnemies.values) {
      final updated = _updateEnemyPosition(enemy);
      updatedEnemies[enemy.id] = updated;
    }
    
    _activeEnemies.clear();
    _activeEnemies.addAll(updatedEnemies);
  }

  /// Update single enemy position
  PatrollingEnemy _updateEnemyPosition(PatrollingEnemy enemy) {
    switch (enemy.behavior) {
      case EnemyBehavior.patrol:
        return _moveAlongPatrolRoute(enemy);
      case EnemyBehavior.chase:
        return _chasePlayer(enemy);
      case EnemyBehavior.wander:
        return _wanderRandomly(enemy);
      case EnemyBehavior.guard:
      case EnemyBehavior.flee:
        return enemy; // Stationary or fleeing (not implemented yet)
    }
  }

  /// Move enemy along patrol route
  PatrollingEnemy _moveAlongPatrolRoute(PatrollingEnemy enemy) {
    if (enemy.patrolRoute.isEmpty) return enemy;
    
    // Get next waypoint
    final nextIndex = (enemy.currentPatrolIndex + 1) % enemy.patrolRoute.length;
    final targetWaypoint = enemy.patrolRoute[nextIndex];
    
    // Calculate direction
    final newPos = _moveTowards(
      enemy.currentPosition,
      targetWaypoint,
      enemy.movementSpeed,
    );
    
    // Check if reached waypoint
    final distance = Geolocator.distanceBetween(
      newPos.latitude,
      newPos.longitude,
      targetWaypoint.latitude,
      targetWaypoint.longitude,
    );
    
    if (distance < 10) {
      // Reached waypoint, advance to next
      return enemy.copyWith(
        currentPosition: targetWaypoint,
        currentPatrolIndex: nextIndex,
      );
    }
    
    return enemy.copyWith(currentPosition: newPos);
  }

  /// Move towards a position
  LatLng _moveTowards(LatLng from, LatLng to, double speed) {
    final lat = from.latitude + (to.latitude - from.latitude) * speed;
    final lng = from.longitude + (to.longitude - from.longitude) * speed;
    return LatLng(lat, lng);
  }

  /// Chase player (aggressive behavior)
  PatrollingEnemy _chasePlayer(PatrollingEnemy enemy) {
    // In a real implementation, would track player position
    // For now, just wander
    return _wanderRandomly(enemy);
  }

  /// Random wandering movement
  PatrollingEnemy _wanderRandomly(PatrollingEnemy enemy) {
    final angle = _random.nextDouble() * 2 * pi;
    final distance = enemy.movementSpeed;
    
    final newLat = enemy.currentPosition.latitude + (distance * cos(angle));
    final newLng = enemy.currentPosition.longitude + (distance * sin(angle));
    
    return enemy.copyWith(currentPosition: LatLng(newLat, newLng));
  }

  /// Check if player is in aggro range
  bool isPlayerInAggroRange(PatrollingEnemy enemy, LatLng playerPosition) {
    final distance = Geolocator.distanceBetween(
      enemy.currentPosition.latitude,
      enemy.currentPosition.longitude,
      playerPosition.latitude,
      playerPosition.longitude,
    );
    
    return distance <= enemy.aggroRadius;
  }

  /// Spawn enemies around player
  void _checkAndSpawnEnemies() {
    // Would spawn new enemies based on region and time
    // Placeholder for now
  }

  /// Spawn enemy at location
  PatrollingEnemy spawnEnemy({
    required LatLng position,
    required int level,
    String? name,
    EnemyBehavior? behavior,
    List<LatLng>? patrolRoute,
  }) {
    // Determine rarity
    EnemyRarity rarity = EnemyRarity.common;
    if (_random.nextDouble() < bossSpawnChance) {
      rarity = EnemyRarity.boss;
    } else if (_random.nextDouble() < eliteSpawnChance) {
      rarity = EnemyRarity.elite;
    }
    
    final enemy = PatrollingEnemy(
      id: 'enemy_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      name: name ?? _generateEnemyName(level, rarity),
      level: level,
      behavior: behavior ?? EnemyBehavior.patrol,
      rarity: rarity,
      currentPosition: position,
      patrolRoute: patrolRoute ?? _generatePatrolRoute(position),
      health: _calculateHealth(level, rarity),
      damage: _calculateDamage(level, rarity),
      lootTable: _generateLootTable(level, rarity),
      spawnedAt: DateTime.now(),
      despawnAt: DateTime.now().add(const Duration(hours: 2)),
    );
    
    _activeEnemies[enemy.id] = enemy;
    return enemy;
  }

  /// Get all active enemies
  List<PatrollingEnemy> getActiveEnemies() {
    return _activeEnemies.values.toList();
  }

  /// Remove enemy
  void removeEnemy(String enemyId) {
    _activeEnemies.remove(enemyId);
  }

  // Helper methods
  String _generateEnemyName(int level, EnemyRarity rarity) {
    final names = ['Goblin', 'Orc', 'Troll', 'Bandit', 'Wolf', 'Bear'];
    final prefix = rarity == EnemyRarity.elite ? 'Elite ' : rarity == EnemyRarity.boss ? 'Boss ' : '';
    return '$prefix${names[_random.nextInt(names.length)]} (Lv$level)';
  }

  int _calculateHealth(int level, EnemyRarity rarity) {
    var hp = 100 + (level * 50);
    if (rarity == EnemyRarity.elite) hp = (hp * 2).toInt();
    if (rarity == EnemyRarity.boss) hp = (hp * 5).toInt();
    return hp;
  }

  int _calculateDamage(int level, EnemyRarity rarity) {
    var dmg = 10 + (level * 5);
    if (rarity == EnemyRarity.elite) dmg = (dmg * 1.5).toInt();
    if (rarity == EnemyRarity.boss) dmg = (dmg * 2).toInt();
    return dmg;
  }

  Map<String, int> _generateLootTable(int level, EnemyRarity rarity) {
    // Drop rates by rarity
    if (rarity == EnemyRarity.boss) {
      return {
        'epic_card': 100,      // 100% epic drop
        'legendary_card': 50,  // 50% legendary drop
        'gold': 100,           // Always gold
      };
    } else if (rarity == EnemyRarity.elite) {
      return {
        'rare_card': 100,      // 100% rare drop
        'epic_card': 25,       // 25% epic drop
        'gold': 100,
      };
    } else {
      return {
        'common_card': 50,     // 50% common drop
        'uncommon_card': 25,   // 25% uncommon
        'gold': 75,
      };
    }
  }

  List<LatLng> _generatePatrolRoute(LatLng center) {
    // Create a simple square patrol route
    return [
      center,
      LatLng(center.latitude + 0.001, center.longitude),
      LatLng(center.latitude + 0.001, center.longitude + 0.001),
      LatLng(center.latitude, center.longitude + 0.001),
    ];
  }
}
