import 'dart:math';
import '../../../data/models/quest_model.dart';
import '../../../data/models/character_model.dart';

class QuestDifficultyService {
  static final QuestDifficultyService _instance = QuestDifficultyService._internal();
  factory QuestDifficultyService() => _instance;
  QuestDifficultyService._internal();

  final Random _random = Random();

  /// Calculate quest difficulty based on various factors
  QuestDifficulty calculateQuestDifficulty({
    required Quest quest,
    required Character character,
    required LatLng playerLocation,
    required DateTime currentTime,
    Map<String, dynamic>? weatherModifiers,
    Map<String, dynamic>? timeModifiers,
  }) {
    double baseDifficulty = 1.0;
    
    // Player level factor
    final levelFactor = _calculateLevelFactor(character.level, quest);
    baseDifficulty *= levelFactor;
    
    // Distance factor
    final distanceFactor = _calculateDistanceFactor(quest, playerLocation);
    baseDifficulty *= distanceFactor;
    
    // Time factor
    final timeFactor = _calculateTimeFactor(currentTime, quest);
    baseDifficulty *= timeFactor;
    
    // Weather factor
    final weatherFactor = _calculateWeatherFactor(weatherModifiers, quest);
    baseDifficulty *= weatherFactor;
    
    // Quest type factor
    final typeFactor = _calculateTypeFactor(quest.type);
    baseDifficulty *= typeFactor;
    
    // Location factor
    final locationFactor = _calculateLocationFactor(quest);
    baseDifficulty *= locationFactor;
    
    // Random variation (±10%)
    final randomVariation = 0.9 + (_random.nextDouble() * 0.2);
    baseDifficulty *= randomVariation;
    
    return QuestDifficulty(
      value: baseDifficulty,
      level: _getDifficultyLevel(baseDifficulty),
      modifiers: _getDifficultyModifiers(baseDifficulty),
      rewards: _calculateScaledRewards(quest, baseDifficulty),
    );
  }

  double _calculateLevelFactor(int playerLevel, Quest quest) {
    // Base difficulty increases with player level
    double factor = 1.0 + (playerLevel * 0.1);
    
    // Adjust based on quest category
    switch (quest.category) {
      case QuestCategory.main:
        factor *= 1.2; // Main quests are harder
        break;
      case QuestCategory.adventure:
        factor *= 1.0; // Adventure quests are standard
        break;
      case QuestCategory.side:
        factor *= 0.8; // Side quests are easier
        break;
    }
    
    return factor;
  }

  double _calculateDistanceFactor(Quest quest, LatLng playerLocation) {
    if (quest.location == null) return 1.0;
    
    final distance = _calculateDistance(
      playerLocation,
      LatLng(quest.location!.latitude, quest.location!.longitude),
    );
    
    // Distance in kilometers
    final distanceKm = distance / 1000;
    
    if (distanceKm < 1) {
      return 0.8; // Very close - easier
    } else if (distanceKm < 5) {
      return 1.0; // Close - standard
    } else if (distanceKm < 10) {
      return 1.2; // Medium distance - harder
    } else {
      return 1.5; // Far - much harder
    }
  }

  double _calculateTimeFactor(DateTime currentTime, Quest quest) {
    // Check if quest has time limit
    if (quest.timeLimit != null) {
      final timeRemaining = quest.timeLimit! - _getMinutesSinceCreation(quest);
      
      if (timeRemaining < 30) {
        return 1.3; // Urgent - harder
      } else if (timeRemaining < 60) {
        return 1.1; // Soon - slightly harder
      }
    }
    
    // Time of day factors
    final hour = currentTime.hour;
    
    // Night quests are harder
    if (hour >= 22 || hour < 6) {
      return 1.2;
    }
    
    return 1.0;
  }

  double _calculateWeatherFactor(Map<String, dynamic>? weatherModifiers, Quest quest) {
    if (weatherModifiers == null) return 1.0;
    
    double factor = 1.0;
    
    // Check quest tags for weather sensitivity
    if (quest.tags.contains('weather:rain')) {
      factor *= weatherModifiers['visibility'] ?? 1.0;
    }
    
    if (quest.tags.contains('weather:storm')) {
      factor *= 1.3; // Storms make quests harder
    }
    
    if (quest.tags.contains('hot_weather')) {
      factor *= weatherModifiers['stamina_drain'] ?? 1.0;
    }
    
    if (quest.tags.contains('cold_weather')) {
      factor *= weatherModifiers['movement_speed'] ?? 1.0;
    }
    
    return factor;
  }

  double _calculateTypeFactor(QuestType questType) {
    switch (questType) {
      case QuestType.battle:
        return 1.3; // Battle quests are harder
      case QuestType.treasure:
        return 1.1; // Treasure quests are slightly harder
      case QuestType.location:
        return 1.0; // Location quests are standard
      case QuestType.fitness:
        return 0.9; // Fitness quests are easier
      case QuestType.social:
        return 0.8; // Social quests are easiest
      case QuestType.story:
        return 1.2; // Story quests are harder
      case QuestType.daily:
        return 0.7; // Daily quests are easiest
      case QuestType.weekly:
        return 1.1; // Weekly quests are slightly harder
    }
  }

  double _calculateLocationFactor(Quest quest) {
    if (quest.location?.name == null) return 1.0;
    
    final locationName = quest.location!.name!.toLowerCase();
    
    // Dangerous locations
    if (locationName.contains('dungeon') || 
        locationName.contains('cave') || 
        locationName.contains('ruins')) {
      return 1.4;
    }
    
    // Safe locations
    if (locationName.contains('town') || 
        locationName.contains('village') || 
        locationName.contains('market')) {
      return 0.8;
    }
    
    // Wilderness locations
    if (locationName.contains('forest') || 
        locationName.contains('mountain') || 
        locationName.contains('swamp')) {
      return 1.2;
    }
    
    return 1.0;
  }

  DifficultyLevel _getDifficultyLevel(double difficulty) {
    if (difficulty < 0.5) {
      return DifficultyLevel.veryEasy;
    } else if (difficulty < 0.8) {
      return DifficultyLevel.easy;
    } else if (difficulty < 1.2) {
      return DifficultyLevel.normal;
    } else if (difficulty < 1.5) {
      return DifficultyLevel.hard;
    } else if (difficulty < 2.0) {
      return DifficultyLevel.veryHard;
    } else {
      return DifficultyLevel.extreme;
    }
  }

  Map<String, dynamic> _getDifficultyModifiers(double difficulty) {
    final modifiers = <String, dynamic>{};
    
    if (difficulty > 1.5) {
      modifiers['damage_multiplier'] = 1.5;
      modifiers['health_multiplier'] = 1.5;
      modifiers['xp_multiplier'] = 2.0;
      modifiers['gold_multiplier'] = 2.0;
    } else if (difficulty > 1.2) {
      modifiers['damage_multiplier'] = 1.3;
      modifiers['health_multiplier'] = 1.3;
      modifiers['xp_multiplier'] = 1.5;
      modifiers['gold_multiplier'] = 1.5;
    } else if (difficulty < 0.8) {
      modifiers['damage_multiplier'] = 0.8;
      modifiers['health_multiplier'] = 0.8;
      modifiers['xp_multiplier'] = 0.7;
      modifiers['gold_multiplier'] = 0.7;
    }
    
    return modifiers;
  }

  QuestRewards _calculateScaledRewards(Quest quest, double difficulty) {
    final baseRewards = quest.rewards;
    
    return QuestRewards(
      xp: (baseRewards.xp * difficulty).round(),
      gold: (baseRewards.gold * difficulty).round(),
      gems: (baseRewards.gems * difficulty).round(),
      items: baseRewards.items, // Items don't scale
      skillPoints: baseRewards.skillPoints, // Skill points don't scale
    );
  }

  double _calculateDistance(LatLng pos1, LatLng pos2) {
    const double earthRadius = 6371000; // meters
    
    final lat1 = pos1.latitude * pi / 180;
    final lat2 = pos2.latitude * pi / 180;
    final dLat = (pos2.latitude - pos1.latitude) * pi / 180;
    final dLng = (pos2.longitude - pos1.longitude) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  int _getMinutesSinceCreation(Quest quest) {
    if (quest.createdAt == null) return 0;
    
    final now = DateTime.now();
    final difference = now.difference(quest.createdAt!);
    return difference.inMinutes;
  }

  /// Get recommended quests for player level
  List<Quest> getRecommendedQuests(List<Quest> availableQuests, int playerLevel) {
    final recommended = <Quest>[];
    
    for (final quest in availableQuests) {
      final difficulty = calculateQuestDifficulty(
        quest: quest,
        character: Character(
          uid: '',
          id: '',
          name: '',
          level: playerLevel,
        ),
        playerLocation: const LatLng(0, 0),
        currentTime: DateTime.now(),
      );
      
      // Recommend quests with difficulty 0.8-1.5
      if (difficulty.value >= 0.8 && difficulty.value <= 1.5) {
        recommended.add(quest);
      }
    }
    
    // Sort by difficulty
    recommended.sort((a, b) {
      final diffA = calculateQuestDifficulty(
        quest: a,
        character: Character(uid: '', id: '', name: '', level: playerLevel),
        playerLocation: const LatLng(0, 0),
        currentTime: DateTime.now(),
      );
      final diffB = calculateQuestDifficulty(
        quest: b,
        character: Character(uid: '', id: '', name: '', level: playerLevel),
        playerLocation: const LatLng(0, 0),
        currentTime: DateTime.now(),
      );
      return diffA.value.compareTo(diffB.value);
    });
    
    return recommended;
  }
}

class QuestDifficulty {
  final double value;
  final DifficultyLevel level;
  final Map<String, dynamic> modifiers;
  final QuestRewards rewards;

  QuestDifficulty({
    required this.value,
    required this.level,
    required this.modifiers,
    required this.rewards,
  });
}

enum DifficultyLevel {
  veryEasy,
  easy,
  normal,
  hard,
  veryHard,
  extreme,
}

extension DifficultyLevelExtension on DifficultyLevel {
  String get displayName {
    switch (this) {
      case DifficultyLevel.veryEasy:
        return 'Very Easy';
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.normal:
        return 'Normal';
      case DifficultyLevel.hard:
        return 'Hard';
      case DifficultyLevel.veryHard:
        return 'Very Hard';
      case DifficultyLevel.extreme:
        return 'Extreme';
    }
  }

  Color get color {
    switch (this) {
      case DifficultyLevel.veryEasy:
        return Colors.green;
      case DifficultyLevel.easy:
        return Colors.lightGreen;
      case DifficultyLevel.normal:
        return Colors.yellow;
      case DifficultyLevel.hard:
        return Colors.orange;
      case DifficultyLevel.veryHard:
        return Colors.red;
      case DifficultyLevel.extreme:
        return Colors.purple;
    }
  }
}
