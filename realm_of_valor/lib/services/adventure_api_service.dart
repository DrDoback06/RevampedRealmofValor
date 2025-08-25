import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdventureApiService {
  // OpenWeatherMap API for weather-based quests
  static const String _weatherApiKey = 'YOUR_OPENWEATHER_API_KEY';
  static const String _weatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
  
  // National Trust API for heritage quests
  static const String _nationalTrustApiKey = 'YOUR_NATIONAL_TRUST_API_KEY';
  
  // Historic England API for historical quests
  static const String _historicEnglandApiKey = 'YOUR_HISTORIC_ENGLAND_API_KEY';
  
  // Geocaching API for treasure hunt quests
  static const String _geocachingApiKey = 'YOUR_GEOCACHING_API_KEY';

  /// Get weather-based quests (rain, snow, sunny day challenges)
  static Future<List<AdventureQuest>> getWeatherQuests({
    required LatLng location,
  }) async {
    debugPrint('AdventureApiService: Getting weather-based quests');
    
    // Get current weather
    final weather = await _getCurrentWeather(location);
    
    final quests = <AdventureQuest>[];
    
    if (weather != null) {
      final condition = weather['weather'][0]['main'].toString().toLowerCase();
      final temp = weather['main']['temp'] as double;
      
      switch (condition) {
        case 'rain':
          quests.add(AdventureQuest(
            id: 'rainy_day_challenge',
            name: 'Rainy Day Adventure',
            description: 'Embrace the rain! Complete this quest during wet weather for bonus rewards.',
            type: AdventureQuestType.weather,
            location: location,
            requirements: ['rain_gear', 'waterproof_clothing'],
            rewards: AdventureQuestRewards(
              xp: 150,
              gold: 75,
              gems: 10,
              items: ['rain_master_badge'],
              bonus: 'Double XP in rain!',
            ),
            conditions: {'weather': 'rain'},
          ));
          break;
        case 'snow':
          quests.add(AdventureQuest(
            id: 'snow_adventure',
            name: 'Snow Day Quest',
            description: 'Build a snowman, have a snowball fight, or go sledding!',
            type: AdventureQuestType.weather,
            location: location,
            requirements: ['warm_clothing'],
            rewards: AdventureQuestRewards(
              xp: 200,
              gold: 100,
              gems: 15,
              items: ['snow_warrior_badge'],
              bonus: 'Triple XP in snow!',
            ),
            conditions: {'weather': 'snow'},
          ));
          break;
        case 'clear':
          if (temp > 20) {
            quests.add(AdventureQuest(
              id: 'sunny_day_quest',
              name: 'Perfect Day Adventure',
              description: 'Enjoy the beautiful weather! Go for a picnic or outdoor activity.',
              type: AdventureQuestType.weather,
              location: location,
              requirements: ['sunscreen', 'picnic_gear'],
              rewards: AdventureQuestRewards(
                xp: 100,
                gold: 50,
                gems: 5,
                items: ['sunshine_badge'],
                bonus: 'Bonus XP for outdoor activities!',
              ),
              conditions: {'weather': 'clear', 'temp_min': 20},
            ));
          }
          break;
      }
    }
    
    return quests;
  }

  /// Get heritage and historical quests
  static Future<List<AdventureQuest>> getHeritageQuests({
    required LatLng location,
    double radius = 50000, // 50km radius
  }) async {
    debugPrint('AdventureApiService: Getting heritage quests');
    
    return [
      AdventureQuest(
        id: 'castle_explorer',
        name: 'Castle Explorer',
        description: 'Visit a historic castle and learn about its fascinating history!',
        type: AdventureQuestType.heritage,
        location: const LatLng(52.2583, -0.8901), // Example castle location
        requirements: ['camera', 'guidebook'],
        rewards: AdventureQuestRewards(
          xp: 300,
          gold: 150,
          gems: 20,
          items: ['castle_explorer_badge', 'medieval_medal'],
          bonus: 'Learn about local history!',
        ),
        conditions: {'type': 'castle'},
      ),
      AdventureQuest(
        id: 'church_visit',
        name: 'Historic Church Visit',
        description: 'Explore a historic church and discover its architectural beauty.',
        type: AdventureQuestType.heritage,
        location: const LatLng(52.2583, -0.8901), // Example church location
        requirements: ['respectful_attire'],
        rewards: AdventureQuestRewards(
          xp: 200,
          gold: 100,
          gems: 15,
          items: ['church_explorer_badge'],
          bonus: 'Discover local heritage!',
        ),
        conditions: {'type': 'church'},
      ),
    ];
  }

  /// Get geocaching treasure hunt quests
  static Future<List<AdventureQuest>> getGeocachingQuests({
    required LatLng location,
    double radius = 10000, // 10km radius
  }) async {
    debugPrint('AdventureApiService: Getting geocaching quests');
    
    return [
      AdventureQuest(
        id: 'treasure_hunt_1',
        name: 'Hidden Treasure Hunt',
        description: 'Find the hidden geocache! Use your GPS skills to locate the treasure.',
        type: AdventureQuestType.geocaching,
        location: LatLng(location.latitude + 0.01, location.longitude + 0.01),
        requirements: ['gps_device', 'treasure_map'],
        rewards: AdventureQuestRewards(
          xp: 250,
          gold: 125,
          gems: 18,
          items: ['treasure_hunter_badge', 'golden_compass'],
          bonus: 'Discover hidden treasures!',
        ),
        conditions: {'difficulty': 'easy'},
      ),
    ];
  }

  /// Get seasonal and event-based quests
  static Future<List<AdventureQuest>> getSeasonalQuests({
    required LatLng location,
  }) async {
    debugPrint('AdventureApiService: Getting seasonal quests');
    
    final now = DateTime.now();
    final month = now.month;
    
    final quests = <AdventureQuest>[];
    
    // Spring quests (March-May)
    if (month >= 3 && month <= 5) {
      quests.add(AdventureQuest(
        id: 'spring_bloom',
        name: 'Spring Bloom Adventure',
        description: 'Find and photograph spring flowers in bloom!',
        type: AdventureQuestType.seasonal,
        location: location,
        requirements: ['camera', 'flower_guide'],
        rewards: AdventureQuestRewards(
          xp: 150,
          gold: 75,
          gems: 10,
          items: ['spring_photographer_badge'],
          bonus: 'Capture nature\'s beauty!',
        ),
        conditions: {'season': 'spring'},
      ));
    }
    
    // Summer quests (June-August)
    if (month >= 6 && month <= 8) {
      quests.add(AdventureQuest(
        id: 'summer_festival',
        name: 'Summer Festival Quest',
        description: 'Attend a local summer festival or fair!',
        type: AdventureQuestType.seasonal,
        location: location,
        requirements: ['festival_ticket'],
        rewards: AdventureQuestRewards(
          xp: 200,
          gold: 100,
          gems: 15,
          items: ['festival_goer_badge'],
          bonus: 'Experience local culture!',
        ),
        conditions: {'season': 'summer'},
      ));
    }
    
    // Autumn quests (September-November)
    if (month >= 9 && month <= 11) {
      quests.add(AdventureQuest(
        id: 'autumn_colors',
        name: 'Autumn Colors Quest',
        description: 'Find the most beautiful autumn leaves and create art!',
        type: AdventureQuestType.seasonal,
        location: location,
        requirements: ['art_supplies'],
        rewards: AdventureQuestRewards(
          xp: 180,
          gold: 90,
          gems: 12,
          items: ['autumn_artist_badge'],
          bonus: 'Create seasonal art!',
        ),
        conditions: {'season': 'autumn'},
      ));
    }
    
    // Winter quests (December-February)
    if (month == 12 || month <= 2) {
      quests.add(AdventureQuest(
        id: 'winter_wonderland',
        name: 'Winter Wonderland Quest',
        description: 'Explore the magical winter landscape!',
        type: AdventureQuestType.seasonal,
        location: location,
        requirements: ['warm_clothing'],
        rewards: AdventureQuestRewards(
          xp: 220,
          gold: 110,
          gems: 16,
          items: ['winter_explorer_badge'],
          bonus: 'Embrace the winter magic!',
        ),
        conditions: {'season': 'winter'},
      ));
    }
    
    return quests;
  }

  /// Get current weather for location
  static Future<Map<String, dynamic>?> _getCurrentWeather(LatLng location) async {
    try {
      final url = Uri.parse(
        '$_weatherBaseUrl/weather?'
        'lat=${location.latitude}'
        '&lon=${location.longitude}'
        '&appid=$_weatherApiKey'
        '&units=metric'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('AdventureApiService: Error getting weather - $e');
    }
    
    return null;
  }
}

class AdventureQuest {
  final String id;
  final String name;
  final String description;
  final AdventureQuestType type;
  final LatLng location;
  final List<String> requirements;
  final AdventureQuestRewards rewards;
  final Map<String, dynamic> conditions;

  AdventureQuest({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.location,
    required this.requirements,
    required this.rewards,
    required this.conditions,
  });
}

class AdventureQuestRewards {
  final int xp;
  final int gold;
  final int gems;
  final List<String> items;
  final String? bonus;

  AdventureQuestRewards({
    required this.xp,
    required this.gold,
    required this.gems,
    required this.items,
    this.bonus,
  });
}

enum AdventureQuestType {
  weather,
  heritage,
  geocaching,
  seasonal,
  cultural,
}
