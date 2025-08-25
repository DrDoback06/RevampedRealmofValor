import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/event_system.dart';
import '../../../data/models/event_model.dart';

// All Events Provider
final allEventsProvider = Provider<List<GameEvent>>((ref) {
  return EventSystem.allEvents;
});

// Active Events Provider
final activeEventsProvider = Provider<List<GameEvent>>((ref) {
  return EventSystem.getActiveEvents();
});

// Upcoming Events Provider
final upcomingEventsProvider = Provider<List<GameEvent>>((ref) {
  return EventSystem.getUpcomingEvents();
});

// Events by Type Provider
final eventsByTypeProvider = Provider.family<List<GameEvent>, EventType>((ref, type) {
  return EventSystem.getEventsByType(type);
});

// Events by Difficulty Provider
final eventsByDifficultyProvider = Provider.family<List<GameEvent>, EventDifficulty>((ref, difficulty) {
  return EventSystem.getEventsByDifficulty(difficulty);
});

// Location-based Events Provider
final locationBasedEventsProvider = Provider.family<List<GameEvent>, Map<String, dynamic>>((ref, locationData) {
  final latitude = locationData['latitude'] as double;
  final longitude = locationData['longitude'] as double;
  final radius = locationData['radius'] as int? ?? 5000;
  
  return EventSystem.getLocationBasedEvents(latitude, longitude, radius);
});

// Event by ID Provider
final eventByIdProvider = Provider.family<GameEvent?, String>((ref, id) {
  return EventSystem.getEventById(id);
});

// Dynamic Events Provider
final dynamicEventsProvider = Provider<List<GameEvent>>((ref) {
  return EventSystem.generateDynamicEvents();
});

// Combined Events Provider (Static + Dynamic)
final combinedEventsProvider = Provider<List<GameEvent>>((ref) {
  final staticEvents = ref.watch(allEventsProvider);
  final dynamicEvents = ref.watch(dynamicEventsProvider);
  
  return [...staticEvents, ...dynamicEvents];
});

// Events for Current User Provider
final userEventsProvider = Provider<List<GameEvent>>((ref) {
  // Mock user stats - in real app, this would come from user profile
  final userStats = {
    'level': 15,
    'battles_won': 10,
    'fitness_level': 3,
    'guild_member': true,
    'achievement_points': 75,
    'legendary_items': 2,
  };
  
  return EventSystem.getEventsForUser(userStats);
});

// Available Events for User Provider
final availableEventsProvider = Provider<List<GameEvent>>((ref) {
  final userEvents = ref.watch(userEventsProvider);
  return userEvents.where((event) => event.hasSpace && !event.isFull).toList();
});

// Event Leaderboard Provider
final eventLeaderboardProvider = Provider.family<EventLeaderboard, String>((ref, eventId) {
  return EventSystem.generateLeaderboard(eventId);
});

// User Participation Provider
final userParticipationProvider = Provider<List<EventParticipation>>((ref) {
  // Mock user participations - in real app, this would come from database
  return [
    EventParticipation(
      eventId: 'weekly_battle_tournament',
      userId: 'current_user',
      joinedAt: DateTime.now().subtract(const Duration(hours: 1)),
      progress: {'battles_won': 3, 'total_battles': 5},
      isCompleted: false,
    ),
    EventParticipation(
      eventId: 'fitness_challenge_week',
      userId: 'current_user',
      joinedAt: DateTime.now().subtract(const Duration(days: 1)),
      progress: {'steps_today': 8000, 'goal': 10000},
      isCompleted: false,
    ),
  ];
});

// User's Active Participations Provider
final userActiveParticipationsProvider = Provider<List<EventParticipation>>((ref) {
  final participations = ref.watch(userParticipationProvider);
  return participations.where((participation) => !participation.isCompleted).toList();
});

// User's Completed Participations Provider
final userCompletedParticipationsProvider = Provider<List<EventParticipation>>((ref) {
  final participations = ref.watch(userParticipationProvider);
  return participations.where((participation) => participation.isCompleted).toList();
});

// Event Statistics Provider
final eventStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final allEvents = ref.watch(allEventsProvider);
  final userParticipations = ref.watch(userParticipationProvider);
  
  final totalEvents = allEvents.length;
  final activeEvents = allEvents.where((e) => e.isActive).length;
  final upcomingEvents = allEvents.where((e) => e.isUpcoming).length;
  final userParticipated = userParticipations.length;
  final userCompleted = userParticipations.where((p) => p.isCompleted).length;
  
  return {
    'total_events': totalEvents,
    'active_events': activeEvents,
    'upcoming_events': upcomingEvents,
    'user_participated': userParticipated,
    'user_completed': userCompleted,
    'completion_rate': totalEvents > 0 ? (userCompleted / totalEvents) * 100 : 0,
  };
});

// Event Filter Provider
final eventFilterProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'type': null,
    'difficulty': null,
    'status': null,
    'location_based': false,
    'user_eligible': false,
  };
});

// Filtered Events Provider
final filteredEventsProvider = Provider<List<GameEvent>>((ref) {
  final allEvents = ref.watch(combinedEventsProvider);
  final filter = ref.watch(eventFilterProvider);
  
  return allEvents.where((event) {
    // Type filter
    if (filter['type'] != null && event.type != filter['type']) {
      return false;
    }
    
    // Difficulty filter
    if (filter['difficulty'] != null && event.difficulty != filter['difficulty']) {
      return false;
    }
    
    // Status filter
    if (filter['status'] != null) {
      switch (filter['status']) {
        case 'active':
          if (!event.isActive) return false;
          break;
        case 'upcoming':
          if (!event.isUpcoming) return false;
          break;
        case 'completed':
          if (!event.isCompleted) return false;
          break;
      }
    }
    
    // Location-based filter
    if (filter['location_based'] == true && !event.isLocationBased) {
      return false;
    }
    
    // User eligible filter
    if (filter['user_eligible'] == true) {
      final userEvents = ref.read(userEventsProvider);
      if (!userEvents.contains(event)) {
        return false;
      }
    }
    
    return true;
  }).toList();
});

// Event Refresh Provider
final eventRefreshProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Event Refresh Action
final eventRefreshActionProvider = Provider((ref) {
  return () {
    ref.read(eventRefreshProvider.notifier).state = DateTime.now();
  };
});

// Event Search Provider
final eventSearchProvider = StateProvider<String>((ref) => '');

// Searched Events Provider
final searchedEventsProvider = Provider<List<GameEvent>>((ref) {
  final allEvents = ref.watch(combinedEventsProvider);
  final searchQuery = ref.watch(eventSearchProvider);
  
  if (searchQuery.isEmpty) {
    return allEvents;
  }
  
  final query = searchQuery.toLowerCase();
  return allEvents.where((event) {
    return event.name.toLowerCase().contains(query) ||
           event.description.toLowerCase().contains(query) ||
           event.location?.toLowerCase().contains(query) == true;
  }).toList();
});
