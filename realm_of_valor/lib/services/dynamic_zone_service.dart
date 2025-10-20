import 'dart:async';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

/// Dynamic Zone System - Random Encounter Areas
/// 
/// ENHANCEMENTS:
/// 1. Time-based zone rotation (changes every 2-4 hours)
/// 2. Weather-influenced zones (rain = water enemies)
/// 3. Zone rarity tiers (common, rare, legendary zones)
/// 4. Multiple zone effects can stack
/// 5. Player notification when entering zone
/// 6. Zone heatmap visualization
/// 7. Seasonal zone variations
/// 8. Player-influenced zones (high activity = better zones)
/// 9. Zone achievements and tracking
/// 10. PvP zones with opt-in combat

enum ZoneEffect {
  enemySpawn,        // Increased enemy encounter rate (+50%)
  eliteSpawn,        // Elite enemies only
  bossSpawn,         // Rare boss spawn chance
  magicFind,         // +25% better loot drops
  doubleXP,          // +100% XP from all sources
  doubleGold,        // +100% gold from all sources
  treasureHunt,      // Treasure chests spawn
  skillDrop,         // Skill cards can drop from enemies
  fitnessBoost,      // +50% fitness rewards
  socialHub,         // Higher chance to meet other players
  merchantSpawn,     // Rare merchant NPCs appear
  pvpEnabled,        // Opt-in PvP combat
  arcaneNexus,       // Magic-based enemies with spell cards
  wildernessHazard,  // Environmental damage but +rewards
}

enum ZoneRarity {
  common,      // Appears frequently, standard bonuses
  uncommon,    // 30% spawn rate, +25% bonuses
  rare,        // 10% spawn rate, +50% bonuses
  epic,        // 5% spawn rate, +100% bonuses
  legendary,   // 1% spawn rate, +200% bonuses
}

class DynamicZone {
  final String id;
  final String name;
  final String description;
  final LatLng center;
  final double radius; // meters
  final List<ZoneEffect> effects;
  final ZoneRarity rarity;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int playerCount; // Number of players currently in zone
  final Map<String, dynamic> metadata;
  
  const DynamicZone({
    required this.id,
    required this.name,
    required this.description,
    required this.center,
    required this.radius,
    required this.effects,
    required this.rarity,
    required this.createdAt,
    required this.expiresAt,
    this.playerCount = 0,
    this.metadata = const {},
  });

  /// Get zone color based on primary effect
  Color get zoneColor {
    if (effects.contains(ZoneEffect.bossSpawn)) {
      return const Color(0xFFE91E63); // Red for boss zones
    } else if (effects.contains(ZoneEffect.magicFind)) {
      return const Color(0xFFFFD700); // Gold for loot zones
    } else if (effects.contains(ZoneEffect.doubleXP)) {
      return const Color(0xFF2196F3); // Blue for XP zones
    } else if (effects.contains(ZoneEffect.pvpEnabled)) {
      return const Color(0xFFFF5722); // Orange for PvP zones
    } else if (effects.contains(ZoneEffect.merchantSpawn)) {
      return const Color(0xFF9C27B0); // Purple for merchant zones
    } else {
      return const Color(0xFF4CAF50); // Green for general zones
    }
  }

  /// Get zone icon
  String get icon {
    if (effects.contains(ZoneEffect.bossSpawn)) return '💀';
    if (effects.contains(ZoneEffect.magicFind)) return '💎';
    if (effects.contains(ZoneEffect.doubleXP)) return '⭐';
    if (effects.contains(ZoneEffect.merchantSpawn)) return '🧙';
    if (effects.contains(ZoneEffect.treasureHunt)) return '🏆';
    if (effects.contains(ZoneEffect.pvpEnabled)) return '⚔️';
    return '✨';
  }

  /// Get zone opacity based on rarity
  double get opacity {
    switch (rarity) {
      case ZoneRarity.common:
        return 0.15;
      case ZoneRarity.uncommon:
        return 0.20;
      case ZoneRarity.rare:
        return 0.25;
      case ZoneRarity.epic:
        return 0.30;
      case ZoneRarity.legendary:
        return 0.40;
    }
  }

  /// Check if location is within zone
  bool containsLocation(LatLng location) {
    final distance = Geolocator.distanceBetween(
      center.latitude,
      center.longitude,
      location.latitude,
      location.longitude,
    );
    return distance <= radius;
  }

  /// Get time remaining
  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  /// Get effect multiplier based on rarity
  double get effectMultiplier {
    switch (rarity) {
      case ZoneRarity.common:
        return 1.0;
      case ZoneRarity.uncommon:
        return 1.25;
      case ZoneRarity.rare:
        return 1.5;
      case ZoneRarity.epic:
        return 2.0;
      case ZoneRarity.legendary:
        return 3.0;
    }
  }
}

class DynamicZoneService {
  final Map<String, DynamicZone> _activeZones = {};
  final Random _random = Random();
  Timer? _zoneRotationTimer;
  Timer? _zoneUpdateTimer;
  
  // Zone configuration
  static const int maxZonesPerRegion = 10;
  static const Duration zoneRotationInterval = Duration(hours: 3);
  static const Duration zoneUpdateInterval = Duration(minutes: 30);
  static const double zoneSpawnRadius = 5000.0; // 5km around player
  
  void startZoneSystem() {
    // Rotation timer (spawn new zones)
    _zoneRotationTimer?.cancel();
    _zoneRotationTimer = Timer.periodic(zoneRotationInterval, (timer) {
      _rotateZones();
    });
    
    // Update timer (refresh existing zones)
    _zoneUpdateTimer?.cancel();
    _zoneUpdateTimer = Timer.periodic(zoneUpdateInterval, (timer) {
      _updateZones();
    });
  }

  void stopZoneSystem() {
    _zoneRotationTimer?.cancel();
    _zoneUpdateTimer?.cancel();
  }

  /// Create zones around player location
  Future<void> spawnZonesAroundPlayer(LatLng playerLocation) async {
    final zonesToCreate = _random.nextInt(3) + 3; // 3-5 zones
    
    for (int i = 0; i < zonesToCreate; i++) {
      final zone = _createRandomZone(playerLocation);
      _activeZones[zone.id] = zone;
    }
  }

  /// Create a random zone
  DynamicZone _createRandomZone(LatLng nearLocation) {
    // Random position within spawn radius
    final angle = _random.nextDouble() * 2 * pi;
    final distance = _random.nextDouble() * zoneSpawnRadius;
    
    final lat = nearLocation.latitude + (distance / 111000) * cos(angle);
    final lng = nearLocation.longitude + (distance / (111000 * cos(nearLocation.latitude * pi / 180))) * sin(angle);
    
    final center = LatLng(lat, lng);
    
    // Determine rarity
    final rarity = _rollZoneRarity();
    
    // Select effects based on rarity
    final effects = _selectZoneEffects(rarity);
    
    // Zone duration based on rarity
    final duration = _getZoneDuration(rarity);
    
    return DynamicZone(
      id: 'zone_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      name: _generateZoneName(effects),
      description: _generateZoneDescription(effects),
      center: center,
      radius: _getZoneRadius(rarity),
      effects: effects,
      rarity: rarity,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(duration),
    );
  }

  /// Roll for zone rarity
  ZoneRarity _rollZoneRarity() {
    final roll = _random.nextDouble();
    if (roll < 0.01) return ZoneRarity.legendary;  // 1%
    if (roll < 0.06) return ZoneRarity.epic;       // 5%
    if (roll < 0.16) return ZoneRarity.rare;       // 10%
    if (roll < 0.46) return ZoneRarity.uncommon;   // 30%
    return ZoneRarity.common;                       // 54%
  }

  /// Select zone effects based on rarity
  List<ZoneEffect> _selectZoneEffects(ZoneRarity rarity) {
    final effectCount = _getEffectCount(rarity);
    final availableEffects = ZoneEffect.values.toList()..shuffle(_random);
    return availableEffects.take(effectCount).toList();
  }

  int _getEffectCount(ZoneRarity rarity) {
    switch (rarity) {
      case ZoneRarity.common:
        return 1;
      case ZoneRarity.uncommon:
        return 1;
      case ZoneRarity.rare:
        return 2;
      case ZoneRarity.epic:
        return 2;
      case ZoneRarity.legendary:
        return 3;
    }
  }

  double _getZoneRadius(ZoneRarity rarity) {
    switch (rarity) {
      case ZoneRarity.common:
        return 200.0;
      case ZoneRarity.uncommon:
        return 300.0;
      case ZoneRarity.rare:
        return 400.0;
      case ZoneRarity.epic:
        return 500.0;
      case ZoneRarity.legendary:
        return 750.0;
    }
  }

  Duration _getZoneDuration(ZoneRarity rarity) {
    switch (rarity) {
      case ZoneRarity.common:
        return const Duration(hours: 2);
      case ZoneRarity.uncommon:
        return const Duration(hours: 3);
      case ZoneRarity.rare:
        return const Duration(hours: 4);
      case ZoneRarity.epic:
        return const Duration(hours: 6);
      case ZoneRarity.legendary:
        return const Duration(hours: 12);
    }
  }

  String _generateZoneName(List<ZoneEffect> effects) {
    if (effects.contains(ZoneEffect.bossSpawn)) return 'Lair of Legends';
    if (effects.contains(ZoneEffect.magicFind)) return 'Treasure Trove';
    if (effects.contains(ZoneEffect.doubleXP)) return 'Experience Surge';
    if (effects.contains(ZoneEffect.merchantSpawn)) return 'Wandering Market';
    if (effects.contains(ZoneEffect.arcaneNexus)) return 'Arcane Nexus';
    if (effects.contains(ZoneEffect.pvpEnabled)) return 'Contested Territory';
    return 'Mystery Zone';
  }

  String _generateZoneDescription(List<ZoneEffect> effects) {
    final descriptions = effects.map((effect) {
      switch (effect) {
        case ZoneEffect.enemySpawn:
          return 'Higher enemy encounter rate';
        case ZoneEffect.magicFind:
          return 'Enhanced loot drops';
        case ZoneEffect.doubleXP:
          return '2x Experience';
        case ZoneEffect.doubleGold:
          return '2x Gold';
        case ZoneEffect.bossSpawn:
          return 'Boss may appear';
        case ZoneEffect.treasureHunt:
          return 'Treasure chests scattered';
        case ZoneEffect.skillDrop:
          return 'Skill cards drop from enemies';
        case ZoneEffect.merchantSpawn:
          return 'Rare merchants present';
        case ZoneEffect.pvpEnabled:
          return 'PvP combat enabled';
        default:
          return effect.toString().split('.').last;
      }
    }).toList();
    
    return descriptions.join(', ');
  }

  /// Rotate zones (remove expired, spawn new)
  void _rotateZones() {
    // Remove expired zones
    _activeZones.removeWhere((id, zone) => 
      DateTime.now().isAfter(zone.expiresAt)
    );
  }

  /// Update existing zones
  void _updateZones() {
    // Could update zone effects, player counts, etc.
  }

  /// Get active zones
  List<DynamicZone> getActiveZones() {
    return _activeZones.values.toList();
  }

  /// Get zones player is currently in
  List<DynamicZone> getPlayerZones(LatLng playerLocation) {
    return _activeZones.values
        .where((zone) => zone.containsLocation(playerLocation))
        .toList();
  }

  /// Apply zone effects to rewards
  int applyZoneEffectsToGold(int baseGold, LatLng location) {
    final zones = getPlayerZones(location);
    var multiplier = 1.0;
    
    for (final zone in zones) {
      if (zone.effects.contains(ZoneEffect.doubleGold)) {
        multiplier += 1.0 * zone.effectMultiplier;
      }
      if (zone.effects.contains(ZoneEffect.magicFind)) {
        multiplier += 0.25 * zone.effectMultiplier;
      }
    }
    
    return (baseGold * multiplier).round();
  }

  int applyZoneEffectsToXP(int baseXP, LatLng location) {
    final zones = getPlayerZones(location);
    var multiplier = 1.0;
    
    for (final zone in zones) {
      if (zone.effects.contains(ZoneEffect.doubleXP)) {
        multiplier += 1.0 * zone.effectMultiplier;
      }
    }
    
    return (baseXP * multiplier).round();
  }

  /// Check for special drops in zone
  bool shouldDropSkillCard(LatLng location) {
    final zones = getPlayerZones(location);
    return zones.any((zone) => zone.effects.contains(ZoneEffect.skillDrop));
  }

  /// Get enhanced enemy spawn rate
  double getEnemySpawnRate(LatLng location) {
    final zones = getPlayerZones(location);
    var rate = 1.0;
    
    for (final zone in zones) {
      if (zone.effects.contains(ZoneEffect.enemySpawn)) {
        rate += 0.5 * zone.effectMultiplier;
      }
      if (zone.effects.contains(ZoneEffect.eliteSpawn)) {
        rate += 0.3 * zone.effectMultiplier;
      }
      if (zone.effects.contains(ZoneEffect.bossSpawn)) {
        rate += 0.1 * zone.effectMultiplier;
      }
    }
    
    return rate;
  }
}
