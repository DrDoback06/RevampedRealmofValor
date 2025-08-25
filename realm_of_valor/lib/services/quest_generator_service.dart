import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/models/quest_model.dart';
import '../data/models/trail_model.dart';
import 'trail_service.dart';

class QuestGeneratorService {
  static final Random _random = Random();

  /// Generate random enemy quests at random locations
  static List<Quest> generateRandomEnemyQuests({
    required LatLng centerLocation,
    int count = 5,
    double radius = 0.01, // ~1km radius
  }) {
    final quests = <Quest>[];
    
    for (int i = 0; i < count; i++) {
      final enemyType = _getRandomEnemyType();
      final position = _getRandomPosition(centerLocation, radius);
      final isPatrolling = _random.nextBool();
      final questVariant = _getEnemyQuestVariant(enemyType);
      
      quests.add(Quest(
        id: 'enemy_quest_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: questVariant['title'],
        type: QuestType.battle,
        category: QuestCategory.side,
        status: QuestStatus.notStarted,
        description: questVariant['description'],
        objectives: questVariant['objectives'],
        rewards: QuestRewards(
          xp: _getEnemyXP(enemyType),
          gold: _getEnemyGold(enemyType),
          items: [_getEnemyLoot(enemyType)],
        ),
        location: QuestLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          radius: 50.0,
        ),
        tags: [
          'enemy_type:$enemyType',
          'is_patrolling:$isPatrolling',
          'patrol_speed:${_getEnemyPatrolSpeed(enemyType)}',
          'quest_type:random_enemy',
          'quest_variant:${questVariant['variant']}',
        ],
      ));
    }
    
    return quests;
  }

  /// Generate random item quests at random locations
  static List<Quest> generateRandomItemQuests({
    required LatLng centerLocation,
    int count = 3,
    double radius = 0.01,
  }) {
    final quests = <Quest>[];
    
    for (int i = 0; i < count; i++) {
      final itemType = _getRandomItemType();
      final position = _getRandomPosition(centerLocation, radius);
      final questVariant = _getItemQuestVariant(itemType);
      
      quests.add(Quest(
        id: 'item_quest_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: questVariant['title'],
        type: QuestType.treasure,
        category: QuestCategory.side,
        status: QuestStatus.notStarted,
        description: questVariant['description'],
        objectives: questVariant['objectives'],
        rewards: QuestRewards(
          xp: _getItemXP(itemType),
          gold: _getItemGold(itemType),
          items: [itemType],
        ),
        location: QuestLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          radius: 30.0,
        ),
        tags: [
          'item_type:$itemType',
          'quest_type:random_item',
          'quest_variant:${questVariant['variant']}',
        ],
      ));
    }
    
    return quests;
  }

  /// Generate random exploration quests
  static List<Quest> generateRandomExplorationQuests({
    required LatLng centerLocation,
    int count = 2,
    double radius = 0.01,
  }) {
    final quests = <Quest>[];
    
    for (int i = 0; i < count; i++) {
      final position = _getRandomPosition(centerLocation, radius);
      final explorationType = _getRandomExplorationType();
      
      quests.add(Quest(
        id: 'exploration_quest_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: 'Explore the $explorationType',
        type: QuestType.location,
        category: QuestCategory.adventure,
        status: QuestStatus.notStarted,
        description: 'Discover the secrets of the $explorationType in this area.',
        objectives: [
          QuestObjective(
            id: 'explore_area',
            description: 'Explore the $explorationType thoroughly',
            target: 1,
            progress: 0,
            type: 'exploration',
          ),
        ],
        rewards: QuestRewards(
          xp: 150,
          gold: 75,
          items: ['explorer_badge'],
        ),
        location: QuestLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          radius: 100.0,
        ),
        tags: [
          'exploration_type:$explorationType',
          'quest_type:exploration',
        ],
      ));
    }
    
    return quests;
  }

  /// Generate POI-based quests based on location type
  static Quest generatePOIQuest({
    required String poiName,
    required String poiCategory,
    required LatLng location,
  }) {
    final questType = _getPOIQuestType(poiCategory);
    final questData = _getPOIQuestData(poiName, poiCategory, questType);
    
    return Quest(
      id: 'poi_quest_${poiName.replaceAll(' ', '_').toLowerCase()}',
      title: questData['title'],
      type: questData['quest_type'],
      category: QuestCategory.side,
      status: QuestStatus.notStarted,
      description: questData['description'],
      objectives: questData['objectives'],
      rewards: questData['rewards'],
      location: QuestLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        radius: 100.0,
      ),
      tags: [
        'poi_name:$poiName',
        'poi_category:$poiCategory',
        'quest_type:poi',
      ],
    );
  }

  /// Generate storyline quests
  static Quest generateStorylineQuest({
    required int questNumber,
    required LatLng location,
    required String previousQuestId,
  }) {
    final storylineData = _getStorylineQuestData(questNumber);
    
    return Quest(
      id: 'storyline_quest_$questNumber',
      title: storylineData['title'],
      type: QuestType.story,
      category: QuestCategory.main,
      status: QuestStatus.notStarted,
      description: storylineData['description'],
      objectives: storylineData['objectives'],
      rewards: storylineData['rewards'],
      location: QuestLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        radius: 80.0,
      ),
      tags: [
        'quest_number:$questNumber',
        'previous_quest:$previousQuestId',
        'quest_type:storyline',
      ],
    );
  }

  // Helper methods
  static String _getRandomEnemyType() {
    final enemies = [
      'Goblin', 'Orc', 'Troll', 'Zombie', 'Skeleton', 'Dragon', 'Giant Spider', 'Werewolf',
      'Vampire', 'Ghoul', 'Imp', 'Harpy', 'Minotaur', 'Cyclops', 'Gargoyle', 'Wraith',
      'Dark Knight', 'Shadow Assassin', 'Corrupted Mage', 'Undead Warrior',
      'Giant Rat', 'Dire Wolf', 'Basilisk', 'Chimera', 'Griffin', 'Phoenix', 'Kraken',
      'Frost Giant', 'Fire Elemental', 'Shadow Demon', 'Crystal Golem', 'Ancient Dragon'
    ];
    return enemies[_random.nextInt(enemies.length)];
  }

  static String _getRandomItemType() {
    final items = [
      'Ancient Relic', 'Magic Crystal', 'Golden Coin', 'Rare Herb', 'Mysterious Scroll', 'Treasure Chest',
      'Enchanted Sword', 'Dragon Scale', 'Phoenix Feather', 'Moonstone', 'Stardust', 'Ethereal Essence',
      'Crystal Shard', 'Ancient Tome', 'Mystic Orb', 'Shadow Cloak', 'Lightning Rod', 'Frost Gem',
      'Crown of Wisdom', 'Staff of Power', 'Ring of Invisibility', 'Amulet of Protection',
      'Boots of Speed', 'Gloves of Strength', 'Helmet of Knowledge', 'Shield of Valor',
      'Potion of Healing', 'Elixir of Youth', 'Scroll of Teleportation', 'Wand of Fireballs',
      'Dagger of Poison', 'Bow of Accuracy', 'Mace of Justice', 'Axe of Destruction'
    ];
    return items[_random.nextInt(items.length)];
  }

  static LatLng _getRandomPosition(LatLng center, double radius) {
    final angle = _random.nextDouble() * 2 * pi;
    final distance = _random.nextDouble() * radius;
    
    final lat = center.latitude + (distance * cos(angle));
    final lng = center.longitude + (distance * sin(angle));
    
    return LatLng(lat, lng);
  }

  static int _getEnemyXP(String enemyType) {
    switch (enemyType.toLowerCase()) {
      case 'dragon':
        return 500;
      case 'troll':
        return 300;
      case 'orc':
        return 200;
      case 'goblin':
        return 100;
      case 'zombie':
        return 75;
      case 'skeleton':
        return 60;
      default:
        return 150;
    }
  }

  static int _getEnemyGold(String enemyType) {
    switch (enemyType.toLowerCase()) {
      case 'dragon':
        return 250;
      case 'troll':
        return 150;
      case 'orc':
        return 100;
      case 'goblin':
        return 50;
      case 'zombie':
        return 25;
      case 'skeleton':
        return 20;
      default:
        return 75;
    }
  }

  static String _getEnemyLoot(String enemyType) {
    switch (enemyType.toLowerCase()) {
      case 'dragon':
        return 'Dragon Scale';
      case 'troll':
        return 'Troll Hide';
      case 'orc':
        return 'Orc Weapon';
      case 'goblin':
        return 'Goblin Gold';
      case 'zombie':
        return 'Zombie Brain';
      case 'skeleton':
        return 'Bone Fragment';
      default:
        return 'Monster Trophy';
    }
  }

  static double _getEnemyPatrolSpeed(String enemyType) {
    switch (enemyType.toLowerCase()) {
      case 'dragon':
        return 0.0001; // Fast flying
      case 'zombie':
        return 0.00001; // Very slow
      case 'goblin':
        return 0.00005; // Medium speed
      case 'orc':
        return 0.00003; // Slow but steady
      case 'troll':
        return 0.00002; // Very slow
      default:
        return 0.00004; // Default speed
    }
  }

  static Map<String, dynamic> _getEnemyQuestVariant(String enemyType) {
    final variants = [
      {
        'title': 'Defeat the $enemyType',
        'description': 'A $enemyType has been spotted in the area. Defeat it to earn rewards!',
        'objectives': [
          QuestObjective(
            id: 'defeat_enemy',
            description: 'Defeat the $enemyType',
            target: 1,
            progress: 0,
            type: 'battle',
          ),
        ],
        'variant': 'standard',
      },
      {
        'title': 'Hunt the $enemyType',
        'description': 'Track down and eliminate the dangerous $enemyType that has been terrorizing the area.',
        'objectives': [
          QuestObjective(
            id: 'hunt_enemy',
            description: 'Hunt and defeat the $enemyType',
            target: 1,
            progress: 0,
            type: 'battle',
          ),
        ],
        'variant': 'hunt',
      },
      {
        'title': 'Challenge the $enemyType',
        'description': 'Face the $enemyType in honorable combat. Prove your worth as a warrior!',
        'objectives': [
          QuestObjective(
            id: 'challenge_enemy',
            description: 'Challenge and defeat the $enemyType',
            target: 1,
            progress: 0,
            type: 'battle',
          ),
        ],
        'variant': 'challenge',
      },
    ];
    
    return variants[_random.nextInt(variants.length)];
  }

  static Map<String, dynamic> _getItemQuestVariant(String itemType) {
    final variants = [
      {
        'title': 'Find the $itemType',
        'description': 'A valuable $itemType has been hidden in this area. Find it!',
        'objectives': [
          QuestObjective(
            id: 'find_item',
            description: 'Find the $itemType',
            target: 1,
            progress: 0,
            type: 'treasure',
          ),
        ],
        'variant': 'standard',
      },
      {
        'title': 'Recover the $itemType',
        'description': 'The legendary $itemType has been lost. Recover it from its hiding place.',
        'objectives': [
          QuestObjective(
            id: 'recover_item',
            description: 'Recover the $itemType',
            target: 1,
            progress: 0,
            type: 'treasure',
          ),
        ],
        'variant': 'recovery',
      },
      {
        'title': 'Steal the $itemType',
        'description': 'The $itemType is guarded by dangerous creatures. Steal it without being caught!',
        'objectives': [
          QuestObjective(
            id: 'steal_item',
            description: 'Steal the $itemType',
            target: 1,
            progress: 0,
            type: 'stealth',
          ),
        ],
        'variant': 'stealth',
      },
    ];
    
    return variants[_random.nextInt(variants.length)];
  }

  static String _getRandomExplorationType() {
    final types = [
      'Ancient Ruins', 'Hidden Cave', 'Mysterious Grove', 'Abandoned Tower',
      'Sacred Temple', 'Underground Passage', 'Floating Island', 'Crystal Cavern',
      'Shadow Realm', 'Time Portal', 'Dimensional Rift', 'Cosmic Observatory'
    ];
    return types[_random.nextInt(types.length)];
  }

  static int _getItemXP(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'ancient relic':
        return 200;
      case 'magic crystal':
        return 150;
      case 'golden coin':
        return 100;
      case 'rare herb':
        return 75;
      case 'mysterious scroll':
        return 125;
      case 'treasure chest':
        return 300;
      default:
        return 100;
    }
  }

  static int _getItemGold(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'ancient relic':
        return 100;
      case 'magic crystal':
        return 75;
      case 'golden coin':
        return 50;
      case 'rare herb':
        return 25;
      case 'mysterious scroll':
        return 60;
      case 'treasure chest':
        return 150;
      default:
        return 50;
    }
  }

  static QuestType _getPOIQuestType(String poiCategory) {
    switch (poiCategory.toLowerCase()) {
      case 'gym':
      case 'fitness':
        return QuestType.fitness;
      case 'pub':
      case 'bar':
      case 'restaurant':
        return QuestType.social;
      case 'park':
      case 'recreation':
        return QuestType.location;
      case 'museum':
      case 'historic':
      case 'church':
        return QuestType.location;
      case 'shop':
      case 'store':
        return QuestType.treasure;
      default:
        return QuestType.location;
    }
  }

  static Map<String, dynamic> _getPOIQuestData(String poiName, String poiCategory, QuestType questType) {
    switch (questType) {
      case QuestType.fitness:
        return {
          'title': 'Fitness Challenge at $poiName',
          'quest_type': QuestType.fitness,
          'description': 'Complete a fitness challenge at $poiName to earn rewards!',
          'objectives': [
            QuestObjective(
              id: 'complete_workout',
              description: 'Complete a workout session',
              target: 1,
              progress: 0,
              type: 'fitness',
            ),
          ],
          'rewards': QuestRewards(
            xp: 150,
            gold: 75,
            items: ['fitness_badge'],
          ),
        };
      
      case QuestType.social:
        return {
          'title': 'Social Gathering at $poiName',
          'quest_type': QuestType.social,
          'description': 'Meet new people and socialize at $poiName!',
          'objectives': [
            QuestObjective(
              id: 'socialize',
              description: 'Interact with other patrons',
              target: 3,
              progress: 0,
              type: 'social',
            ),
          ],
          'rewards': QuestRewards(
            xp: 100,
            gold: 50,
            items: ['social_badge'],
          ),
        };
      
      case QuestType.location:
        return {
          'title': 'Learn History at $poiName',
          'quest_type': QuestType.location,
          'description': 'Discover the fascinating history of $poiName!',
          'objectives': [
            QuestObjective(
              id: 'learn_history',
              description: 'Learn about the location\'s history',
              target: 1,
              progress: 0,
              type: 'learning',
            ),
          ],
          'rewards': QuestRewards(
            xp: 200,
            gold: 100,
            items: ['historian_badge'],
          ),
        };
      
      default:
        return {
          'title': 'Explore $poiName',
          'quest_type': QuestType.location,
          'description': 'Explore and discover the secrets of $poiName!',
          'objectives': [
            QuestObjective(
              id: 'explore_location',
              description: 'Explore the location thoroughly',
              target: 1,
              progress: 0,
              type: 'exploration',
            ),
          ],
          'rewards': QuestRewards(
            xp: 120,
            gold: 60,
            items: ['explorer_badge'],
          ),
        };
    }
  }

  static Map<String, dynamic> _getStorylineQuestData(int questNumber) {
    final storylines = [
      {
        'title': 'The Beginning',
        'description': 'Your adventure begins! Complete your first quest to unlock the path ahead.',
        'objectives': [
          QuestObjective(
            id: 'first_quest',
            description: 'Complete your first quest',
            target: 1,
            progress: 0,
            type: 'storyline',
          ),
        ],
        'rewards': QuestRewards(
          xp: 100,
          gold: 50,
          items: ['adventurer_badge'],
        ),
      },
      {
        'title': 'The Mystery Deepens',
        'description': 'Strange events are occurring. Investigate the source of the disturbance.',
        'objectives': [
          QuestObjective(
            id: 'investigate',
            description: 'Investigate the mysterious events',
            target: 1,
            progress: 0,
            type: 'storyline',
          ),
        ],
        'rewards': QuestRewards(
          xp: 200,
          gold: 100,
          items: ['detective_badge'],
        ),
      },
      {
        'title': 'The Ancient Power',
        'description': 'An ancient power has awakened. You must find and secure it before it falls into the wrong hands.',
        'objectives': [
          QuestObjective(
            id: 'secure_power',
            description: 'Secure the ancient power',
            target: 1,
            progress: 0,
            type: 'storyline',
          ),
        ],
        'rewards': QuestRewards(
          xp: 500,
          gold: 250,
          items: ['guardian_badge', 'ancient_relic'],
        ),
      },
    ];
    
    return storylines[questNumber % storylines.length];
  }

  /// Generate trail-based quests from real trail data
  static Future<List<Quest>> generateTrailQuests({
    required LatLng centerLocation,
    double radiusKm = 100.0,
  }) async {
    final quests = <Quest>[];
    
    try {
      // Get trails near the location
      final trails = await TrailService.getTrailsNearLocation(
        location: centerLocation,
        radiusKm: radiusKm,
      );
      
      for (final trail in trails) {
        final questVariant = _getTrailQuestVariant(trail);
        
        quests.add(Quest(
          id: 'trail_quest_${trail.id}',
          title: questVariant['title'],
          type: QuestType.fitness,
          category: QuestCategory.main,
          status: QuestStatus.notStarted,
          description: questVariant['description'],
          objectives: questVariant['objectives'],
          rewards: QuestRewards(
            xp: _getTrailXP(trail),
            gold: _getTrailGold(trail),
            items: [_getTrailLoot(trail)],
          ),
          location: QuestLocation(
            latitude: trail.startLocation.latitude,
            longitude: trail.startLocation.longitude,
            radius: 100.0,
          ),
          tags: [
            'trail_id:${trail.id}',
            'trail_type:${trail.type}',
            'trail_difficulty:${trail.difficulty}',
            'quest_type:trail',
            'quest_variant:${questVariant['variant']}',
            ...trail.tags.map((tag) => 'trail_tag:$tag'),
          ],
        ));
      }
    } catch (e) {
      print('Failed to generate trail quests: $e');
    }
    
    return quests;
  }

  // Trail quest helper methods
  static Map<String, dynamic> _getTrailQuestVariant(Trail trail) {
    final variants = [
      {
        'title': 'Conquer ${trail.name}',
        'description': 'Complete the challenging ${trail.name} trail. This ${trail.difficulty.toString().split('.').last} difficulty trail offers ${trail.description}',
        'objectives': [
          QuestObjective(
            id: 'complete_trail',
            description: 'Complete the ${trail.name} trail',
            target: 1,
            progress: 0,
            type: 'fitness',
          ),
        ],
        'variant': 'conquer',
      },
      {
        'title': 'Trail Master: ${trail.name}',
        'description': 'Master the ${trail.name} trail and prove your fitness prowess!',
        'objectives': [
          QuestObjective(
            id: 'master_trail',
            description: 'Complete ${trail.name} with excellence',
            target: 1,
            progress: 0,
            type: 'fitness',
          ),
        ],
        'variant': 'master',
      },
      {
        'title': 'Adventure on ${trail.name}',
        'description': 'Embark on an adventure along the ${trail.name} trail!',
        'objectives': [
          QuestObjective(
            id: 'adventure_trail',
            description: 'Complete the adventure on ${trail.name}',
            target: 1,
            progress: 0,
            type: 'fitness',
          ),
        ],
        'variant': 'adventure',
      },
    ];
    
    return variants[_random.nextInt(variants.length)];
  }

  static int _getTrailXP(Trail trail) {
    switch (trail.difficulty) {
      case TrailDifficulty.easy:
        return 100;
      case TrailDifficulty.moderate:
        return 250;
      case TrailDifficulty.hard:
        return 500;
      case TrailDifficulty.expert:
        return 1000;
    }
  }

  static int _getTrailGold(Trail trail) {
    switch (trail.difficulty) {
      case TrailDifficulty.easy:
        return 50;
      case TrailDifficulty.moderate:
        return 125;
      case TrailDifficulty.hard:
        return 250;
      case TrailDifficulty.expert:
        return 500;
    }
  }

  static String _getTrailLoot(Trail trail) {
    final lootOptions = [
      'trail_badge',
      'fitness_medal',
      'adventure_compass',
      'mountain_crystal',
      'trail_master_certificate',
    ];
    
    return lootOptions[_random.nextInt(lootOptions.length)];
  }
}
