import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di.dart';
import '../../data/models/quest_model.dart';
import '../../services/event_bus.dart';
import '../auth/providers.dart';

/// Provides active quests with proper persistence
final questsStreamProvider = StreamProvider<List<Quest>>((ref) async* {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) {
    yield [];
    return;
  }

  final bus = ref.watch(eventBusProvider);
  final questRepo = ref.watch(questRepositoryProvider);
  
  // Track active quests
  final activeQuests = <String, Quest>{};

  // Load existing quests from repository
  try {
    final existingQuests = await questRepo.getActiveQuests(authState.uid);
    for (final quest in existingQuests) {
      activeQuests[quest.id] = quest;
    }
    yield activeQuests.values.toList();
  } catch (e) {
    // If repository fails, start with empty list
    yield [];
  }

  // Listen for quest events
  await for (final event in bus.stream) {
    switch (event.type) {
      case 'quest.add':
        if (event.data?['quest'] != null) {
          final questData = event.data!['quest'] as Map<String, dynamic>;
          final quest = _createQuestFromData(questData);
          activeQuests[quest.id] = quest;
          
          // Persist to repository
          try {
            await questRepo.addQuest(authState.uid, quest);
          } catch (e) {
            // Log error but continue
            print('Failed to persist quest: $e');
          }
          
          // Automatically create geofence for location-based quests
          if (quest.location != null) {
            bus.publish(Event(
              type: 'location.add_geofence',
              data: {
                'id': 'quest_${quest.id}',
                'lat': quest.location!.latitude,
                'lon': quest.location!.longitude,
                'radius_m': quest.location!.radius,
              },
            ));
          }
          
          yield activeQuests.values.toList();
        }
        break;
      case 'quest.progress':
        if (event.data?['quest_id'] != null && event.data?['objective_id'] != null) {
          final questId = event.data!['quest_id'] as String;
          final objectiveId = event.data!['objective_id'] as String;
          final newValue = event.data!['new_value'] as int;
          
          final quest = activeQuests[questId];
          if (quest != null) {
            final updatedObjectives = quest.objectives.map((obj) {
              if (obj.id == objectiveId) {
                return QuestObjective(
                  id: obj.id,
                  description: obj.description,
                  target: obj.target,
                  progress: newValue,
                  type: obj.type,
                );
              }
              return obj;
            }).toList();
            
            final updatedQuest = Quest(
              id: quest.id,
              title: quest.title,
              type: quest.type,
              category: quest.category,
              status: quest.status,
              description: quest.description,
              objectives: updatedObjectives,
              rewards: quest.rewards,
              location: quest.location,
              timeLimit: quest.timeLimit,
              prerequisites: quest.prerequisites,
              tags: quest.tags,
              createdAt: quest.createdAt,
              completedAt: quest.completedAt,
            );
            
            activeQuests[questId] = updatedQuest;
            
            // Persist to repository
            try {
              await questRepo.updateQuest(authState.uid, updatedQuest);
            } catch (e) {
              print('Failed to persist quest update: $e');
            }
            
            yield activeQuests.values.toList();
          }
        }
        break;
      case 'quest.completed':
        if (event.data?['quest_id'] != null) {
          final questId = event.data!['quest_id'] as String;
          final quest = activeQuests[questId];
          if (quest != null) {
            // Mark as completed
            final completedQuest = Quest(
              id: quest.id,
              title: quest.title,
              type: quest.type,
              category: quest.category,
              status: QuestStatus.completed,
              description: quest.description,
              objectives: quest.objectives,
              rewards: quest.rewards,
              location: quest.location,
              timeLimit: quest.timeLimit,
              prerequisites: quest.prerequisites,
              tags: quest.tags,
              createdAt: quest.createdAt,
              completedAt: DateTime.now(),
            );
            
            // Persist completion
            try {
              await questRepo.completeQuest(authState.uid, completedQuest);
            } catch (e) {
              print('Failed to persist quest completion: $e');
            }
            
            activeQuests.remove(questId);
            yield activeQuests.values.toList();
          }
        }
        break;
      case 'quest.abandon':
        if (event.data?['quest_id'] != null) {
          final questId = event.data!['quest_id'] as String;
          final quest = activeQuests[questId];
          if (quest != null) {
            // Mark as abandoned
            final abandonedQuest = Quest(
              id: quest.id,
              title: quest.title,
              type: quest.type,
              category: quest.category,
              status: QuestStatus.abandoned,
              description: quest.description,
              objectives: quest.objectives,
              rewards: quest.rewards,
              location: quest.location,
              timeLimit: quest.timeLimit,
              prerequisites: quest.prerequisites,
              tags: quest.tags,
              createdAt: quest.createdAt,
              completedAt: DateTime.now(),
            );
            
            // Persist abandonment
            try {
              await questRepo.abandonQuest(authState.uid, abandonedQuest);
            } catch (e) {
              print('Failed to persist quest abandonment: $e');
            }
            
            activeQuests.remove(questId);
            yield activeQuests.values.toList();
          }
        }
        break;
    }
  }
});

/// Provider for available quests (not yet accepted)
final availableQuestsProvider = FutureProvider<List<Quest>>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) return [];

  final questRepo = ref.watch(questRepositoryProvider);
  return await questRepo.getAvailableQuests(authState.uid);
});

Quest _createQuestFromData(Map<String, dynamic> data) {
  final id = data['id'] as String;
  final title = data['title'] as String;
  final description = data['description'] as String? ?? '';
  final typeStr = (data['type'] as String).toLowerCase();
  final categoryStr = (data['category'] as String).toLowerCase();
  
  final type = _parseQuestType(typeStr);
  final category = _parseQuestCategory(categoryStr);
  
  final objectivesRaw = List<Map<String, dynamic>>.from(data['objectives'] as List);
  final objectives = objectivesRaw.map((o) => QuestObjective(
    id: o['id'] as String,
    description: o['description'] as String,
    target: (o['target'] as num?)?.toInt() ?? 1,
    progress: (o['progress'] as num?)?.toInt() ?? 0,
    type: o['type'] as String? ?? 'general',
  )).toList();
  
  final rewardsData = data['rewards'] as Map<String, dynamic>? ?? {};
  final rewards = QuestRewards(
    xp: (rewardsData['xp'] as num?)?.toInt() ?? 0,
    gold: (rewardsData['gold'] as num?)?.toInt() ?? 0,
    gems: (rewardsData['gems'] as num?)?.toInt() ?? 0,
    items: List<String>.from(rewardsData['items'] as List? ?? []),
    skillPoints: (rewardsData['skillPoints'] as num?)?.toInt() ?? 0,
  );
  
  final locationData = data['location'] as Map<String, dynamic>?;
  final location = locationData != null ? QuestLocation(
    latitude: locationData['latitude'] as double,
    longitude: locationData['longitude'] as double,
    radius: (locationData['radius'] as num?)?.toDouble() ?? 50,
    name: locationData['name'] as String?,
    address: locationData['address'] as String?,
  ) : null;
  
  return Quest(
    id: id,
    title: title,
    type: type,
    category: category,
    status: QuestStatus.inProgress,
    description: description,
    objectives: objectives,
    rewards: rewards,
    location: location,
    timeLimit: data['timeLimit'] as int?,
    prerequisites: List<String>.from(data['prerequisites'] as List? ?? []),
    tags: List<String>.from(data['tags'] as List? ?? []),
    createdAt: DateTime.now(),
  );
}

QuestType _parseQuestType(String typeStr) {
  switch (typeStr) {
    case 'story': return QuestType.story;
    case 'daily': return QuestType.daily;
    case 'weekly': return QuestType.weekly;
    case 'location': return QuestType.location;
    case 'fitness': return QuestType.fitness;
    case 'battle': return QuestType.battle;
    case 'social': return QuestType.social;
    case 'treasure': return QuestType.treasure;
    default: return QuestType.story;
  }
}

QuestCategory _parseQuestCategory(String categoryStr) {
  switch (categoryStr) {
    case 'main': return QuestCategory.main;
    case 'adventure': return QuestCategory.adventure;
    case 'side': return QuestCategory.side;
    default: return QuestCategory.side;
  }
}

/// Quest actions
final questActionsProvider = Provider((ref) {
  final bus = ref.watch(eventBusProvider);
  return QuestActions(bus);
});

class QuestActions {
  final EventBus _bus;
  
  QuestActions(this._bus);
  
  void addMainQuest() {
    _bus.publish(Event(
      type: 'quest.add',
      data: {
        'quest': {
          'id': 'main_quest_${DateTime.now().millisecondsSinceEpoch}',
          'title': 'The Beginning of Adventure',
          'description': 'Your first main story quest. Complete this to unlock new areas.',
          'type': 'story',
          'category': 'main',
          'objectives': [
            {
              'id': 'obj1',
              'description': 'Complete your first battle',
              'target': 1,
              'progress': 0,
              'type': 'battle',
            }
          ],
          'rewards': {
            'xp': 200,
            'gold': 100,
            'gems': 5,
            'items': ['sword_basic'],
            'skillPoints': 1,
          },
        }
      },
    ));
  }
  
  void addAdventureQuest() {
    _bus.publish(Event(
      type: 'quest.add',
      data: {
        'quest': {
          'id': 'adventure_quest_${DateTime.now().millisecondsSinceEpoch}',
          'title': 'Explorer\'s Challenge',
          'description': 'Discover a new location on the adventure map.',
          'type': 'location',
          'category': 'adventure',
          'objectives': [
            {
              'id': 'obj1',
              'description': 'Visit a new location',
              'target': 1,
              'progress': 0,
              'type': 'location',
            }
          ],
          'rewards': {
            'xp': 150,
            'gold': 75,
            'gems': 3,
            'items': [],
            'skillPoints': 0,
          },
          'location': {
            'latitude': 37.7749,
            'longitude': -122.4194,
            'radius': 100,
            'name': 'Adventure Point',
          },
        }
      },
    ));
  }
  
  void addSideQuest() {
    _bus.publish(Event(
      type: 'quest.add',
      data: {
        'quest': {
          'id': 'side_quest_${DateTime.now().millisecondsSinceEpoch}',
          'title': 'Daily Fitness Challenge',
          'description': 'Complete a quick fitness activity to stay healthy.',
          'type': 'fitness',
          'category': 'side',
          'objectives': [
            {
              'id': 'obj1',
              'description': 'Walk 1000 steps',
              'target': 1000,
              'progress': 0,
              'type': 'steps',
            }
          ],
          'rewards': {
            'xp': 50,
            'gold': 25,
            'gems': 1,
            'items': [],
            'skillPoints': 0,
          },
          'timeLimit': 1440, // 24 hours
        }
      },
    ));
  }
  
  void addLocationQuest(String locationName, double latitude, double longitude, String category) {
    final questId = 'location_quest_${DateTime.now().millisecondsSinceEpoch}';
    
    _bus.publish(Event(
      type: 'quest.add',
      data: {
        'quest': {
          'id': questId,
          'title': 'Visit $locationName',
          'description': 'Visit $locationName to complete this quest.',
          'type': 'location',
          'category': 'side',
          'objectives': [
            {
              'id': 'obj1',
              'description': 'Visit $locationName',
              'target': 1,
              'progress': 0,
              'type': 'location',
            }
          ],
          'rewards': {
            'xp': 75,
            'gold': 35,
            'gems': 2,
            'items': [],
            'skillPoints': 0,
          },
          'location': {
            'latitude': latitude,
            'longitude': longitude,
            'radius': 50,
            'name': locationName,
          },
          'tags': [category],
        }
      },
    ));
    
    // Automatically create geofence for the quest
    _bus.publish(Event(
      type: 'location.add_geofence',
      data: {
        'id': 'quest_$questId',
        'lat': latitude,
        'lon': longitude,
        'radius_m': 50.0,
      },
    ));
  }
  
  void generateFitnessQuest() {
    _bus.publish(Event(
      type: 'quest.add',
      data: {
        'quest': {
          'id': 'fitness_quest_${DateTime.now().millisecondsSinceEpoch}',
          'title': 'Heart Rate Challenge',
          'description': 'Raise your heart rate to 120+ BPM for 10 minutes.',
          'type': 'fitness',
          'category': 'side',
          'objectives': [
            {
              'id': 'obj1',
              'description': 'Maintain elevated heart rate',
              'target': 10,
              'progress': 0,
              'type': 'fitness',
            }
          ],
          'rewards': {
            'xp': 100,
            'gold': 50,
            'gems': 2,
            'items': [],
            'skillPoints': 0,
          },
          'timeLimit': 60, // 1 hour
        }
      },
    ));
  }
  
  void completeQuest(String questId) {
    _bus.publish(Event(
      type: 'quest.completed',
      data: {'quest_id': questId},
    ));
  }
  
  void abandonQuest(String questId) {
    _bus.publish(Event(
      type: 'quest.abandon',
      data: {'quest_id': questId},
    ));
  }
  
  void updateQuestProgress(String questId, String objectiveId, int newValue) {
    _bus.publish(Event(
      type: 'quest.progress',
      data: {
        'quest_id': questId,
        'objective_id': objectiveId,
        'new_value': newValue,
      },
    ));
  }
  
  void startBattle() {
    _bus.publish(Event(
      type: 'battle.start',
      data: {
        'player': {'id': 'player', 'hp': 100, 'atk': 10},
        'enemy': {'id': 'goblin', 'hp': 50, 'atk': 5},
      },
    ));
  }
}