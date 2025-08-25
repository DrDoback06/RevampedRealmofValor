import 'dart:math';
import '../../../data/models/quest_model.dart';

class TimeQuestService {
  static final TimeQuestService _instance = TimeQuestService._internal();
  factory TimeQuestService() => _instance;
  TimeQuestService._internal();

  final Random _random = Random();

  /// Generate time-appropriate quests
  Future<List<Quest>> generateTimeQuests(
    DateTime currentTime,
    LatLng location,
    int count,
  ) async {
    final quests = <Quest>[];
    
    for (int i = 0; i < count; i++) {
      final quest = _generateTimeQuest(currentTime, location, i);
      if (quest != null) {
        quests.add(quest);
      }
    }
    
    return quests;
  }

  Quest? _generateTimeQuest(DateTime currentTime, LatLng location, int index) {
    final hour = currentTime.hour;
    final dayOfWeek = currentTime.weekday;
    final isWeekend = dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday;
    final isHoliday = _isHoliday(currentTime);
    final isSpecialEvent = _isSpecialEvent(currentTime);

    // Determine quest type based on time
    QuestType questType;
    String title;
    String description;
    List<String> tags = [];
    int xpReward;
    int goldReward;

    if (hour >= 6 && hour < 12) {
      // Morning quests
      questType = QuestType.fitness;
      title = _getMorningQuestTitle(index);
      description = _getMorningQuestDescription(index);
      tags = ['time:morning', 'energy_boost', 'sunrise_power'];
      xpReward = 30;
      goldReward = 20;
    } else if (hour >= 12 && hour < 18) {
      // Afternoon quests
      questType = QuestType.location;
      title = _getAfternoonQuestTitle(index);
      description = _getAfternoonQuestDescription(index);
      tags = ['time:afternoon', 'peak_activity', 'social_quest'];
      xpReward = 25;
      goldReward = 15;
    } else if (hour >= 18 && hour < 22) {
      // Evening quests
      questType = QuestType.treasure;
      title = _getEveningQuestTitle(index);
      description = _getEveningQuestDescription(index);
      tags = ['time:evening', 'golden_hour', 'treasure_hunt'];
      xpReward = 35;
      goldReward = 25;
    } else {
      // Night quests
      questType = QuestType.battle;
      title = _getNightQuestTitle(index);
      description = _getNightQuestDescription(index);
      tags = ['time:night', 'nocturnal_creatures', 'moonlight_power'];
      xpReward = 40;
      goldReward = 30;
    }

    // Add weekend modifiers
    if (isWeekend) {
      tags.add('weekend_bonus');
      xpReward += 10;
      goldReward += 5;
      description += ' Weekend bonus active!';
    }

    // Add holiday modifiers
    if (isHoliday) {
      tags.add('holiday_event');
      xpReward += 20;
      goldReward += 15;
      description += ' Special holiday rewards available!';
    }

    // Add special event modifiers
    if (isSpecialEvent) {
      tags.add('special_event');
      xpReward += 25;
      goldReward += 20;
      description += ' Limited time event quest!';
    }

    // Generate location near the given coordinates
    final questLocation = _generateNearbyLocation(location);

    return Quest(
      id: 'time_quest_${hour}_${dayOfWeek}_${DateTime.now().millisecondsSinceEpoch}_$index',
      title: title,
      type: questType,
      category: QuestCategory.adventure,
      status: QuestStatus.notStarted,
      description: description,
      objectives: [
        QuestObjective(
          id: 'complete_time_quest',
          description: 'Complete the time-based challenge',
          target: 1,
          progress: 0,
          type: 'time',
        ),
      ],
      rewards: QuestRewards(
        xp: xpReward,
        gold: goldReward,
        gems: _random.nextInt(3),
        items: _getTimeRewardItems(hour, dayOfWeek),
        skillPoints: _random.nextInt(2),
      ),
      location: QuestLocation(
        latitude: questLocation.latitude,
        longitude: questLocation.longitude,
        radius: 100.0,
        name: 'Time Quest Location',
      ),
      tags: tags,
      timeLimit: _getTimeQuestTimeLimit(hour),
    );
  }

  String _getMorningQuestTitle(int index) {
    final titles = [
      'Dawn Runner',
      'Sunrise Meditation',
      'Morning Energy Collector',
      'Early Bird Catcher',
      'Breakfast Quest',
    ];
    return titles[index % titles.length];
  }

  String _getMorningQuestDescription(int index) {
    final descriptions = [
      'Start your day with an energizing morning run.',
      'Meditate during sunrise to gain spiritual power.',
      'Collect morning energy from the rising sun.',
      'Catch the early bird and earn extra rewards.',
      'Complete a quest while enjoying breakfast.',
    ];
    return descriptions[index % descriptions.length];
  }

  String _getAfternoonQuestTitle(int index) {
    final titles = [
      'Lunch Break Adventure',
      'Afternoon Explorer',
      'Peak Performance',
      'Social Butterfly',
      'Midday Challenge',
    ];
    return titles[index % titles.length];
  }

  String _getAfternoonQuestDescription(int index) {
    final descriptions = [
      'Embark on an adventure during your lunch break.',
      'Explore the area during peak daylight hours.',
      'Test your skills at peak performance time.',
      'Meet new people and make social connections.',
      'Take on a challenging midday quest.',
    ];
    return descriptions[index % descriptions.length];
  }

  String _getEveningQuestTitle(int index) {
    final titles = [
      'Golden Hour Hunter',
      'Sunset Treasure',
      'Evening Stroll',
      'Dinner Quest',
      'Twilight Explorer',
    ];
    return titles[index % titles.length];
  }

  String _getEveningQuestDescription(int index) {
    final descriptions = [
      'Hunt for treasures during the golden hour.',
      'Find treasures that glow in the sunset light.',
      'Take a peaceful evening stroll.',
      'Complete a quest while having dinner.',
      'Explore the area during twilight hours.',
    ];
    return descriptions[index % descriptions.length];
  }

  String _getNightQuestTitle(int index) {
    final titles = [
      'Night Watch',
      'Moonlight Warrior',
      'Nocturnal Hunter',
      'Midnight Mystery',
      'Starlight Seeker',
    ];
    return titles[index % titles.length];
  }

  String _getNightQuestDescription(int index) {
    final descriptions = [
      'Keep watch during the dark hours.',
      'Fight under the power of moonlight.',
      'Hunt nocturnal creatures.',
      'Solve mysteries that only appear at midnight.',
      'Seek treasures that glow under starlight.',
    ];
    return descriptions[index % descriptions.length];
  }

  LatLng _generateNearbyLocation(LatLng center) {
    // Generate a random location within 1km of the center
    final latOffset = (_random.nextDouble() - 0.5) * 0.01; // ~1km
    final lngOffset = (_random.nextDouble() - 0.5) * 0.01; // ~1km
    
    return LatLng(
      center.latitude + latOffset,
      center.longitude + lngOffset,
    );
  }

  List<String> _getTimeRewardItems(int hour, int dayOfWeek) {
    final items = <String>[];
    
    // Time-based items
    if (hour >= 6 && hour < 12) {
      items.addAll(['morning_tea', 'sunrise_crystal', 'energy_boost']);
    } else if (hour >= 12 && hour < 18) {
      items.addAll(['lunch_box', 'afternoon_charm', 'social_token']);
    } else if (hour >= 18 && hour < 22) {
      items.addAll(['evening_star', 'golden_hour_gem', 'sunset_orb']);
    } else {
      items.addAll(['moonlight_crystal', 'night_vision_potion', 'starlight_dust']);
    }
    
    // Day-based items
    if (dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday) {
      items.add('weekend_token');
    }
    
    // Randomly select 1-2 items
    final selectedItems = <String>[];
    final itemCount = _random.nextInt(2) + 1;
    
    for (int i = 0; i < itemCount && items.isNotEmpty; i++) {
      final randomIndex = _random.nextInt(items.length);
      selectedItems.add(items[randomIndex]);
      items.removeAt(randomIndex);
    }
    
    return selectedItems;
  }

  int? _getTimeQuestTimeLimit(int hour) {
    if (hour >= 6 && hour < 12) {
      return 90; // 1.5 hours for morning quests
    } else if (hour >= 12 && hour < 18) {
      return 120; // 2 hours for afternoon quests
    } else if (hour >= 18 && hour < 22) {
      return 150; // 2.5 hours for evening quests
    } else {
      return 180; // 3 hours for night quests
    }
  }

  bool _isHoliday(DateTime date) {
    // Check for major holidays (simplified)
    final month = date.month;
    final day = date.day;
    
    return (month == 12 && day == 25) || // Christmas
           (month == 12 && day == 31) || // New Year's Eve
           (month == 1 && day == 1) ||   // New Year's Day
           (month == 7 && day == 4) ||   // Independence Day (US)
           (month == 10 && day == 31);   // Halloween
  }

  bool _isSpecialEvent(DateTime date) {
    // Check for special events (simplified)
    final month = date.month;
    final day = date.day;
    
    return (month == 2 && day == 14) || // Valentine's Day
           (month == 3 && day == 17) || // St. Patrick's Day
           (month == 4 && day == 1) ||  // April Fool's Day
           (month == 11 && day == 11);  // Veterans Day
  }

  /// Get time-based quest modifiers
  Map<String, dynamic> getTimeModifiers(DateTime currentTime) {
    final modifiers = <String, dynamic>{};
    final hour = currentTime.hour;
    
    if (hour >= 6 && hour < 12) {
      modifiers['morning_energy'] = 1.2; // 20% energy boost
      modifiers['sunrise_power'] = 1.1; // 10% power boost
    } else if (hour >= 12 && hour < 18) {
      modifiers['peak_performance'] = 1.15; // 15% performance boost
      modifiers['social_bonus'] = 1.1; // 10% social bonus
    } else if (hour >= 18 && hour < 22) {
      modifiers['golden_hour'] = 1.25; // 25% treasure bonus
      modifiers['evening_charm'] = 1.1; // 10% charm bonus
    } else {
      modifiers['nocturnal_power'] = 1.3; // 30% night power
      modifiers['moonlight_boost'] = 1.2; // 20% moonlight boost
    }
    
    return modifiers;
  }

  /// Get daily quest schedule
  Map<String, List<String>> getDailyQuestSchedule() {
    return {
      'morning': [
        'Dawn Runner',
        'Sunrise Meditation',
        'Morning Energy Collector',
        'Early Bird Catcher',
        'Breakfast Quest',
      ],
      'afternoon': [
        'Lunch Break Adventure',
        'Afternoon Explorer',
        'Peak Performance',
        'Social Butterfly',
        'Midday Challenge',
      ],
      'evening': [
        'Golden Hour Hunter',
        'Sunset Treasure',
        'Evening Stroll',
        'Dinner Quest',
        'Twilight Explorer',
      ],
      'night': [
        'Night Watch',
        'Moonlight Warrior',
        'Nocturnal Hunter',
        'Midnight Mystery',
        'Starlight Seeker',
      ],
    };
  }
}