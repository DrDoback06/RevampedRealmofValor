import 'dart:math';
import '../data/models/quest_model.dart';
import '../data/models/weather_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WeatherQuestService {
  static final WeatherQuestService _instance = WeatherQuestService._internal();
  factory WeatherQuestService() => _instance;
  WeatherQuestService._internal();

  final Random _random = Random();

  /// Generate weather-appropriate quests
  Future<List<Quest>> generateWeatherQuests(
    WeatherData weather,
    LatLng location,
    int count,
  ) async {
    final quests = <Quest>[];
    
    for (int i = 0; i < count; i++) {
      final quest = _generateWeatherQuest(weather, location, i);
      if (quest != null) {
        quests.add(quest);
      }
    }
    
    return quests;
  }

  Quest? _generateWeatherQuest(WeatherData weather, LatLng location, int index) {
    final weatherType = weather.condition.toLowerCase();
    final temperature = weather.temperature;
    final isRaining = weatherType.contains('rain') || weatherType.contains('drizzle');
    final isSnowing = weatherType.contains('snow') || weatherType.contains('sleet');
    final isStormy = weatherType.contains('storm') || weatherType.contains('thunder');
    final isSunny = weatherType.contains('clear') || weatherType.contains('sunny');
    final isCloudy = weatherType.contains('cloud') || weatherType.contains('overcast');

    // Determine quest type based on weather
    QuestType questType;
    String title;
    String description;
    List<String> tags = [];
    int xpReward;
    int goldReward;

    if (isRaining) {
      questType = QuestType.location;
      title = _getRainQuestTitle(index);
      description = _getRainQuestDescription(index);
      tags = ['weather:rain', 'indoor_friendly', 'shelter_quest'];
      xpReward = 25;
      goldReward = 15;
    } else if (isSnowing) {
      questType = QuestType.fitness;
      title = _getSnowQuestTitle(index);
      description = _getSnowQuestDescription(index);
      tags = ['weather:snow', 'winter_activity', 'cold_resistance'];
      xpReward = 35;
      goldReward = 20;
    } else if (isStormy) {
      questType = QuestType.battle;
      title = _getStormQuestTitle(index);
      description = _getStormQuestDescription(index);
      tags = ['weather:storm', 'elemental_battle', 'lightning_magic'];
      xpReward = 50;
      goldReward = 30;
    } else if (isSunny) {
      questType = QuestType.treasure;
      title = _getSunnyQuestTitle(index);
      description = _getSunnyQuestDescription(index);
      tags = ['weather:sunny', 'outdoor_activity', 'solar_power'];
      xpReward = 30;
      goldReward = 25;
    } else if (isCloudy) {
              questType = QuestType.location;
      title = _getCloudyQuestTitle(index);
      description = _getCloudyQuestDescription(index);
      tags = ['weather:cloudy', 'mystery_quest', 'shadow_magic'];
      xpReward = 20;
      goldReward = 15;
    } else {
      // Default quest
      questType = QuestType.location;
      title = 'Weather Watch Quest';
      description = 'Observe the current weather conditions and report back.';
      tags = ['weather:unknown', 'observation'];
      xpReward = 15;
      goldReward = 10;
    }

    // Add temperature-based modifiers
    if (temperature > 30) {
      tags.add('hot_weather');
      xpReward += 5;
      description += ' The heat makes this quest more challenging!';
    } else if (temperature < 0) {
      tags.add('cold_weather');
      xpReward += 5;
      description += ' The cold adds an extra challenge!';
    }

    // Generate location near the given coordinates
    final questLocation = _generateNearbyLocation(location);

    return Quest(
      id: 'weather_quest_${weatherType}_${DateTime.now().millisecondsSinceEpoch}_$index',
      title: title,
      type: questType,
      category: QuestCategory.adventure,
      status: QuestStatus.notStarted,
      description: description,
      objectives: [
        QuestObjective(
          id: 'complete_weather_quest',
          description: 'Complete the weather-based challenge',
          target: 1,
          progress: 0,
          type: 'weather',
        ),
      ],
      rewards: QuestRewards(
        xp: xpReward,
        gold: goldReward,
        gems: _random.nextInt(3),
        items: _getWeatherRewardItems(weatherType),
        skillPoints: _random.nextInt(2),
      ),
      location: QuestLocation(
        latitude: questLocation.latitude,
        longitude: questLocation.longitude,
        radius: 100.0,
        name: 'Weather Quest Location',
      ),
      tags: tags,
      timeLimit: _getWeatherQuestTimeLimit(weatherType),
    );
  }

  String _getRainQuestTitle(int index) {
    final titles = [
      'Shelter Seeker',
      'Rain Dance Ritual',
      'Puddle Jumper',
      'Storm Watcher',
      'Umbrella Guardian',
    ];
    return titles[index % titles.length];
  }

  String _getRainQuestDescription(int index) {
    final descriptions = [
      'Find shelter from the rain and help others stay dry.',
      'Perform a mystical rain dance to control the weather.',
      'Navigate through puddles without getting wet.',
      'Observe the storm patterns and predict its path.',
      'Protect your umbrella from the wind and rain.',
    ];
    return descriptions[index % descriptions.length];
  }

  String _getSnowQuestTitle(int index) {
    final titles = [
      'Snow Angel Creator',
      'Ice Sculptor',
      'Winter Warrior',
      'Frost Walker',
      'Snowball Master',
    ];
    return titles[index % titles.length];
  }

  String _getSnowQuestDescription(int index) {
    final descriptions = [
      'Create beautiful snow angels in the fresh snow.',
      'Sculpt an ice masterpiece using your magical powers.',
      'Train in the harsh winter conditions.',
      'Walk across frozen surfaces with perfect balance.',
      'Master the art of snowball combat.',
    ];
    return descriptions[index % descriptions.length];
  }

  String _getStormQuestTitle(int index) {
    final titles = [
      'Lightning Caller',
      'Storm Chaser',
      'Thunder Master',
      'Wind Rider',
      'Tempest Tamer',
    ];
    return titles[index % titles.length];
  }

  String _getStormQuestDescription(int index) {
    final descriptions = [
      'Harness the power of lightning in battle.',
      'Chase the storm and study its patterns.',
      'Control thunder to defeat your enemies.',
      'Ride the wind currents to reach new heights.',
      'Tame the tempest and bring calm to the area.',
    ];
    return descriptions[index % descriptions.length];
  }

  String _getSunnyQuestTitle(int index) {
    final titles = [
      'Solar Collector',
      'Sun Seeker',
      'Golden Treasure Hunter',
      'Light Walker',
      'Solar Flare Master',
    ];
    return titles[index % titles.length];
  }

  String _getSunnyQuestDescription(int index) {
    final descriptions = [
      'Collect solar energy to power magical devices.',
      'Seek out the sunniest spots in the area.',
      'Hunt for treasures that glow in the sunlight.',
      'Walk in the light and avoid all shadows.',
      'Master the power of solar flares.',
    ];
    return descriptions[index % descriptions.length];
  }

  String _getCloudyQuestTitle(int index) {
    final titles = [
      'Shadow Walker',
      'Mystery Seeker',
      'Cloud Reader',
      'Fog Navigator',
      'Mist Master',
    ];
    return titles[index % titles.length];
  }

  String _getCloudyQuestDescription(int index) {
    final descriptions = [
      'Navigate through shadows and hidden paths.',
      'Seek out mysteries hidden in the cloudy weather.',
      'Read the patterns in the clouds for guidance.',
      'Navigate through fog to find hidden locations.',
      'Master the art of moving through mist.',
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

  List<String> _getWeatherRewardItems(String weatherType) {
    final items = <String>[];
    
    switch (weatherType) {
      case 'rain':
        items.addAll(['rain_boots', 'umbrella', 'water_crystal']);
        break;
      case 'snow':
        items.addAll(['winter_coat', 'ice_crystal', 'snow_shoes']);
        break;
      case 'storm':
        items.addAll(['lightning_rod', 'storm_crystal', 'wind_charm']);
        break;
      case 'sunny':
        items.addAll(['solar_panel', 'sun_crystal', 'sunglasses']);
        break;
      case 'cloudy':
        items.addAll(['shadow_cloak', 'mist_crystal', 'fog_lamp']);
        break;
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

  int? _getWeatherQuestTimeLimit(String weatherType) {
    switch (weatherType) {
      case 'storm':
        return 30; // 30 minutes for storm quests
      case 'rain':
        return 60; // 1 hour for rain quests
      case 'snow':
        return 90; // 1.5 hours for snow quests
      default:
        return 120; // 2 hours for other quests
    }
  }

  /// Get weather-based quest modifiers
  Map<String, dynamic> getWeatherModifiers(WeatherData weather) {
    final modifiers = <String, dynamic>{};
    
    if (weather.temperature > 30) {
      modifiers['heat_resistance'] = 0.8; // 20% damage reduction
      modifiers['stamina_drain'] = 1.2; // 20% faster stamina drain
    } else if (weather.temperature < 0) {
      modifiers['cold_resistance'] = 0.8; // 20% damage reduction
      modifiers['movement_speed'] = 0.9; // 10% slower movement
    }
    
    if (weather.condition.toLowerCase().contains('rain')) {
      modifiers['water_magic_boost'] = 1.3; // 30% boost to water magic
      modifiers['visibility'] = 0.8; // 20% reduced visibility
    }
    
    if (weather.condition.toLowerCase().contains('storm')) {
      modifiers['lightning_magic_boost'] = 1.5; // 50% boost to lightning magic
      modifiers['wind_magic_boost'] = 1.3; // 30% boost to wind magic
    }
    
    return modifiers;
  }
}
