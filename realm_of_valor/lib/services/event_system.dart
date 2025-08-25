import 'dart:math';
import 'dart:async';
import '../data/models/event_model.dart';

class EventSystem {
  static final List<GameEvent> _events = [
    // Battle Events
    GameEvent(
      id: 'weekly_battle_tournament',
      name: 'Weekly Battle Tournament',
      description: 'Compete against other players in an epic tournament!',
      type: EventType.battle,
      status: EventStatus.active,
      difficulty: EventDifficulty.medium,
      startTime: DateTime.now().subtract(const Duration(hours: 2)),
      endTime: DateTime.now().add(const Duration(days: 5)),
      location: 'Wootton Arena',
      latitude: 52.2053,
      longitude: -0.9069,
      radius: 5000,
      requirements: {'level': 10, 'battles_won': 5},
      rewards: {'xp': 1000, 'gold': 500, 'rare_card': 1},
      maxParticipants: 50,
      isRepeatable: true,
      cooldownHours: 168, // 1 week
    ),
    
    // Fitness Events
    GameEvent(
      id: 'fitness_challenge_week',
      name: 'Fitness Challenge Week',
      description: 'Complete fitness goals to earn special rewards!',
      type: EventType.fitness,
      status: EventStatus.active,
      difficulty: EventDifficulty.easy,
      startTime: DateTime.now().subtract(const Duration(days: 1)),
      endTime: DateTime.now().add(const Duration(days: 6)),
      requirements: {'fitness_level': 1},
      rewards: {'xp': 500, 'gold': 200, 'fitness_boost': 1.5},
      maxParticipants: 100,
      isRepeatable: true,
      cooldownHours: 168,
    ),
    
    // Social Events
    GameEvent(
      id: 'guild_gathering',
      name: 'Guild Gathering',
      description: 'Meet with your guild members for special activities!',
      type: EventType.social,
      status: EventStatus.upcoming,
      difficulty: EventDifficulty.easy,
      startTime: DateTime.now().add(const Duration(hours: 3)),
      endTime: DateTime.now().add(const Duration(hours: 6)),
      location: 'Wootton Community Center',
      latitude: 52.2053,
      longitude: -0.9069,
      radius: 2000,
      requirements: {'guild_member': true},
      rewards: {'xp': 300, 'guild_points': 100, 'social_boost': 1.2},
      maxParticipants: 30,
      isRepeatable: true,
      cooldownHours: 72,
    ),
    
    // Weather Events
    GameEvent(
      id: 'storm_chaser',
      name: 'Storm Chaser',
      description: 'Special event during stormy weather conditions!',
      type: EventType.weather,
      status: EventStatus.upcoming,
      difficulty: EventDifficulty.hard,
      startTime: DateTime.now().add(const Duration(hours: 12)),
      endTime: DateTime.now().add(const Duration(hours: 18)),
      requirements: {'weather_condition': 'storm', 'level': 15},
      rewards: {'xp': 800, 'gold': 400, 'storm_mastery': 1},
      maxParticipants: 25,
      isRepeatable: false,
    ),
    
    // Seasonal Events
    GameEvent(
      id: 'winter_festival',
      name: 'Winter Festival',
      description: 'Celebrate the winter season with special activities!',
      type: EventType.seasonal,
      status: EventStatus.upcoming,
      difficulty: EventDifficulty.medium,
      startTime: DateTime.now().add(const Duration(days: 7)),
      endTime: DateTime.now().add(const Duration(days: 14)),
      location: 'Wootton Winter Wonderland',
      latitude: 52.2053,
      longitude: -0.9069,
      radius: 3000,
      requirements: {'level': 5},
      rewards: {'xp': 600, 'gold': 300, 'winter_items': 3},
      maxParticipants: 75,
      isRepeatable: true,
      cooldownHours: 8760, // 1 year
    ),
    
    // Achievement Events
    GameEvent(
      id: 'achievement_hunt',
      name: 'Achievement Hunt',
      description: 'Unlock achievements to earn bonus rewards!',
      type: EventType.achievement,
      status: EventStatus.active,
      difficulty: EventDifficulty.medium,
      startTime: DateTime.now().subtract(const Duration(hours: 6)),
      endTime: DateTime.now().add(const Duration(days: 2)),
      requirements: {'achievement_points': 50},
      rewards: {'xp': 400, 'gold': 150, 'achievement_boost': 1.3},
      maxParticipants: 200,
      isRepeatable: true,
      cooldownHours: 168,
    ),
    
    // Special Events
    GameEvent(
      id: 'legendary_encounter',
      name: 'Legendary Encounter',
      description: 'Face off against a legendary boss!',
      type: EventType.special,
      status: EventStatus.upcoming,
      difficulty: EventDifficulty.extreme,
      startTime: DateTime.now().add(const Duration(days: 3)),
      endTime: DateTime.now().add(const Duration(days: 3, hours: 2)),
      location: 'Ancient Ruins',
      latitude: 52.2053,
      longitude: -0.9069,
      radius: 1000,
      requirements: {'level': 20, 'legendary_items': 1},
      rewards: {'xp': 2000, 'gold': 1000, 'legendary_card': 1},
      maxParticipants: 10,
      isRepeatable: false,
    ),
  ];

  // Dynamic events that spawn automatically
  static final List<GameEvent> _dynamicEvents = <GameEvent>[];
  static Timer? _dynamicEventTimer;
  static final Random _random = Random();

  // Event templates for dynamic generation
  static const List<Map<String, dynamic>> _eventTemplates = [
    {
      'name': 'Mysterious Encounter',
      'description': 'A mysterious figure has appeared in the area!',
      'type': EventType.special,
      'difficulty': EventDifficulty.medium,
      'duration': Duration(hours: 2),
      'requirements': {'level': 5},
      'rewards': {'xp': 300, 'gold': 150, 'mystery_item': 1},
    },
    {
      'name': 'Training Grounds',
      'description': 'A temporary training area has opened up!',
      'type': EventType.fitness,
      'difficulty': EventDifficulty.easy,
      'duration': Duration(hours: 4),
      'requirements': {'fitness_level': 1},
      'rewards': {'xp': 200, 'gold': 100, 'fitness_boost': 1.2},
    },
    {
      'name': 'Treasure Hunt',
      'description': 'Rumors of hidden treasure in the area!',
      'type': EventType.quest,
      'difficulty': EventDifficulty.medium,
      'duration': Duration(hours: 3),
      'requirements': {'level': 8},
      'rewards': {'xp': 400, 'gold': 200, 'treasure_map': 1},
    },
    {
      'name': 'Night Raid',
      'description': 'Enemy forces are attacking under cover of darkness!',
      'type': EventType.battle,
      'difficulty': EventDifficulty.hard,
      'duration': Duration(hours: 1),
      'requirements': {'level': 12},
      'rewards': {'xp': 600, 'gold': 300, 'night_vision': 1},
    },
    {
      'name': 'Community Challenge',
      'description': 'Work together with other players to complete this challenge!',
      'type': EventType.social,
      'difficulty': EventDifficulty.easy,
      'duration': Duration(hours: 6),
      'requirements': {'guild_member': true},
      'rewards': {'xp': 250, 'gold': 125, 'community_points': 50},
    },
  ];

  static List<GameEvent> get allEvents => [..._events, ..._dynamicEvents];
  
  static List<GameEvent> getActiveEvents() {
    return allEvents.where((event) => event.isActive).toList();
  }
  
  static List<GameEvent> getUpcomingEvents() {
    return allEvents.where((event) => event.isUpcoming).toList();
  }
  
  static List<GameEvent> getEventsByType(EventType type) {
    return allEvents.where((event) => event.type == type).toList();
  }
  
  static List<GameEvent> getEventsByDifficulty(EventDifficulty difficulty) {
    return allEvents.where((event) => event.difficulty == difficulty).toList();
  }
  
  static List<GameEvent> getLocationBasedEvents(double latitude, double longitude, int radius) {
    return allEvents.where((event) {
      if (!event.isLocationBased) return false;
      
      final distance = _calculateDistance(
        latitude, longitude,
        event.latitude!, event.longitude!,
      );
      
      return distance <= (event.radius ?? radius);
    }).toList();
  }
  
  static GameEvent? getEventById(String id) {
    try {
      return allEvents.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }
  
  static List<GameEvent> getEventsForUser(Map<String, dynamic> userStats) {
    return allEvents.where((event) {
      // Check if user meets requirements
      if (event.requirements != null) {
        for (final requirement in event.requirements!.entries) {
          final userValue = userStats[requirement.key] ?? 0;
          if (userValue < requirement.value) {
            return false;
          }
        }
      }
      return true;
    }).toList();
  }

  // Initialize dynamic event spawning
  static void initializeDynamicEvents() {
    _dynamicEventTimer?.cancel();
    _dynamicEventTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _spawnRandomEvent();
    });
    
    // Spawn initial events
    for (int i = 0; i < 3; i++) {
      _spawnRandomEvent();
    }
  }

  // Spawn a random dynamic event
  static void _spawnRandomEvent() {
    if (_dynamicEvents.length >= 10) {
      // Remove oldest event if we have too many
      _dynamicEvents.removeAt(0);
    }

    final template = _eventTemplates[_random.nextInt(_eventTemplates.length)];
    final now = DateTime.now();
    final startTime = now.add(Duration(minutes: _random.nextInt(30)));
    final endTime = startTime.add(template['duration'] as Duration);
    
    // Random location around Wootton
    final baseLat = 52.2053;
    final baseLng = -0.9069;
    final latOffset = (_random.nextDouble() - 0.5) * 0.01; // ±0.005 degrees
    final lngOffset = (_random.nextDouble() - 0.5) * 0.01;

    final event = GameEvent(
      id: 'dynamic_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      name: template['name'] as String,
      description: template['description'] as String,
      type: template['type'] as EventType,
      status: EventStatus.upcoming,
      difficulty: template['difficulty'] as EventDifficulty,
      startTime: startTime,
      endTime: endTime,
      location: 'Dynamic Location',
      latitude: baseLat + latOffset,
      longitude: baseLng + lngOffset,
      radius: 1000 + _random.nextInt(2000),
      requirements: Map<String, dynamic>.from(template['requirements'] as Map),
      rewards: Map<String, dynamic>.from(template['rewards'] as Map),
      maxParticipants: 20 + _random.nextInt(30),
      isRepeatable: false,
    );

    _dynamicEvents.add(event);
    print('EventSystem: Spawned dynamic event: ${event.name} at ${event.startTime}');
  }

  // Weather-triggered events
  static void spawnWeatherEvent(String weatherCondition) {
    final weatherEvents = {
      'storm': {
        'name': 'Lightning Storm Challenge',
        'description': 'Navigate through the storm to find lightning crystals!',
        'type': EventType.weather,
        'difficulty': EventDifficulty.hard,
        'rewards': {'xp': 800, 'gold': 400, 'lightning_crystal': 1},
      },
      'rain': {
        'name': 'Rainy Day Adventure',
        'description': 'Explore the area during the rain for special rewards!',
        'type': EventType.weather,
        'difficulty': EventDifficulty.easy,
        'rewards': {'xp': 300, 'gold': 150, 'rain_boost': 1.3},
      },
      'sunny': {
        'name': 'Sunny Day Training',
        'description': 'Perfect weather for outdoor training activities!',
        'type': EventType.fitness,
        'difficulty': EventDifficulty.medium,
        'rewards': {'xp': 400, 'gold': 200, 'sun_energy': 1},
      },
      'fog': {
        'name': 'Mysterious Fog',
        'description': 'Navigate through the mysterious fog to find hidden treasures!',
        'type': EventType.quest,
        'difficulty': EventDifficulty.medium,
        'rewards': {'xp': 500, 'gold': 250, 'fog_essence': 1},
      },
    };

    final weatherEvent = weatherEvents[weatherCondition];
    if (weatherEvent != null) {
      final now = DateTime.now();
      final event = GameEvent(
        id: 'weather_${weatherCondition}_${now.millisecondsSinceEpoch}',
        name: weatherEvent['name'] as String,
        description: weatherEvent['description'] as String,
        type: weatherEvent['type'] as EventType,
        status: EventStatus.active,
        difficulty: weatherEvent['difficulty'] as EventDifficulty,
        startTime: now,
        endTime: now.add(const Duration(hours: 2)),
        location: 'Weather-Affected Area',
        latitude: 52.2053 + (_random.nextDouble() - 0.5) * 0.01,
        longitude: -0.9069 + (_random.nextDouble() - 0.5) * 0.01,
        radius: 1500,
        requirements: {'weather_condition': weatherCondition},
        rewards: Map<String, dynamic>.from(weatherEvent['rewards'] as Map),
        maxParticipants: 50,
        isRepeatable: false,
      );

      _dynamicEvents.add(event);
      print('EventSystem: Spawned weather event: ${event.name}');
    }
  }

  // Activity-triggered events
  static void spawnActivityEvent(Map<String, dynamic> activityData) {
    final steps = activityData['steps'] as int? ?? 0;
    final distance = activityData['distance'] as double? ?? 0.0;
    final calories = activityData['calories'] as double? ?? 0.0;

    if (steps > 10000) {
      _spawnHighActivityEvent('steps', steps);
    }
    if (distance > 5.0) {
      _spawnHighActivityEvent('distance', distance);
    }
    if (calories > 500) {
      _spawnHighActivityEvent('calories', calories);
    }
  }

  static void _spawnHighActivityEvent(String activityType, dynamic value) {
    final now = DateTime.now();
    final event = GameEvent(
      id: 'activity_${activityType}_${now.millisecondsSinceEpoch}',
      name: 'High Activity Reward',
      description: 'Your high $activityType activity has unlocked a special event!',
      type: EventType.fitness,
      status: EventStatus.active,
      difficulty: EventDifficulty.easy,
      startTime: now,
      endTime: now.add(const Duration(hours: 1)),
      requirements: {'fitness_level': 1},
      rewards: {
        'xp': 200,
        'gold': 100,
        'activity_boost': 1.5,
        'bonus_${activityType}': value,
      },
      maxParticipants: 100,
      isRepeatable: false,
    );

    _dynamicEvents.add(event);
    print('EventSystem: Spawned activity event for $activityType: $value');
  }

  // Time-based events
  static void spawnTimeBasedEvent() {
    final now = DateTime.now();
    final hour = now.hour;
    
    String eventName;
    String description;
    Map<String, dynamic> rewards;

    if (hour >= 6 && hour < 12) {
      eventName = 'Morning Training';
      description = 'Start your day with some morning exercises!';
      rewards = {'xp': 300, 'gold': 150, 'morning_boost': 1.2};
    } else if (hour >= 12 && hour < 18) {
      eventName = 'Afternoon Adventure';
      description = 'Perfect time for an afternoon adventure!';
      rewards = {'xp': 400, 'gold': 200, 'adventure_gear': 1};
    } else if (hour >= 18 && hour < 22) {
      eventName = 'Evening Gathering';
      description = 'Join the evening community gathering!';
      rewards = {'xp': 250, 'gold': 125, 'social_points': 50};
    } else {
      eventName = 'Night Watch';
      description = 'Keep watch during the night hours!';
      rewards = {'xp': 500, 'gold': 250, 'night_vision': 1};
    }

    final event = GameEvent(
      id: 'time_${hour}_${now.millisecondsSinceEpoch}',
      name: eventName,
      description: description,
      type: EventType.special,
      status: EventStatus.active,
      difficulty: EventDifficulty.easy,
      startTime: now,
      endTime: now.add(const Duration(hours: 2)),
      requirements: {'level': 1},
      rewards: rewards,
      maxParticipants: 75,
      isRepeatable: true,
      cooldownHours: 24,
    );

    _dynamicEvents.add(event);
    print('EventSystem: Spawned time-based event: $eventName');
  }

  // Clean up expired events
  static void cleanupExpiredEvents() {
    final now = DateTime.now();
    _dynamicEvents.removeWhere((event) => event.endTime.isBefore(now));
  }
  
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
  
  static List<GameEvent> generateDynamicEvents() {
    cleanupExpiredEvents();
    return _dynamicEvents;
  }
  
  static EventLeaderboard generateLeaderboard(String eventId) {
    final random = Random();
    final entries = <EventLeaderboardEntry>[];
    
    for (int i = 0; i < 20; i++) {
      entries.add(EventLeaderboardEntry(
        userId: 'user_${random.nextInt(1000)}',
        username: 'Player${random.nextInt(1000)}',
        score: random.nextInt(10000) + 100,
        rank: i + 1,
        metadata: {
          'level': random.nextInt(50) + 1,
          'guild': 'Guild${random.nextInt(10) + 1}',
        },
      ));
    }
    
    // Sort by score descending
    entries.sort((a, b) => b.score.compareTo(a.score));
    
    // Update ranks
    for (int i = 0; i < entries.length; i++) {
      entries[i] = EventLeaderboardEntry(
        userId: entries[i].userId,
        username: entries[i].username,
        score: entries[i].score,
        rank: i + 1,
        metadata: entries[i].metadata,
      );
    }
    
    return EventLeaderboard(
      eventId: eventId,
      entries: entries,
      lastUpdated: DateTime.now(),
    );
  }

  // Dispose resources
  static void dispose() {
    _dynamicEventTimer?.cancel();
    _dynamicEvents.clear();
  }
}
