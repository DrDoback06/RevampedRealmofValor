import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config.dart';
import '../data/models/fitness_workout.dart';
import 'event_bus.dart';

class FitnessService {
  static final FitnessService _instance = FitnessService._internal();
  factory FitnessService() => _instance;
  FitnessService._internal();

  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  // Strava API endpoints
  static const String _baseUrl = 'https://www.strava.com/api/v3';
  static const String _authUrl = 'https://www.strava.com/oauth/token';

  /// Initialize the fitness service with Strava credentials
  Future<bool> initialize() async {
    try {
      // Check if we have valid tokens
      if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
        return true;
      }

      // Try to refresh token if we have a refresh token
      if (_refreshToken != null) {
        return await _refreshAccessToken();
      }

      return false;
    } catch (e) {
      print('FitnessService: Error initializing: $e');
      return false;
    }
  }

  /// Authenticate with Strava using authorization code
  Future<bool> authenticate(String authorizationCode) async {
    try {
      final response = await http.post(
        Uri.parse(_authUrl),
        body: {
          'client_id': AppConfig.stravaClientId,
          'client_secret': AppConfig.stravaClientSecret,
          'code': authorizationCode,
          'grant_type': 'authorization_code',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
        
        print('FitnessService: Successfully authenticated with Strava');
        return true;
      } else {
        print('FitnessService: Authentication failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('FitnessService: Error during authentication: $e');
      return false;
    }
  }

  /// Refresh the access token
  Future<bool> _refreshAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse(_authUrl),
        body: {
          'client_id': AppConfig.stravaClientId,
          'client_secret': AppConfig.stravaClientSecret,
          'refresh_token': _refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
        
        print('FitnessService: Successfully refreshed access token');
        return true;
      } else {
        print('FitnessService: Token refresh failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('FitnessService: Error refreshing token: $e');
      return false;
    }
  }

  /// Get recent activities from Strava
  Future<List<FitnessWorkout>> getRecentActivities({int perPage = 10}) async {
    if (!await initialize()) {
      throw Exception('Fitness service not initialized');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/athlete/activities?per_page=$perPage'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> activities = json.decode(response.body);
        return activities.map((activity) => FitnessWorkout.fromStrava(activity)).toList();
      } else {
        print('FitnessService: Failed to fetch activities: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('FitnessService: Error fetching activities: $e');
      return [];
    }
  }

  /// Get today's activities
  Future<List<FitnessWorkout>> getTodayActivities() async {
    final activities = await getRecentActivities(perPage: 50);
    final today = DateTime.now();
    
    return activities.where((activity) {
      final activityDate = DateTime.fromMillisecondsSinceEpoch(activity.startTime * 1000);
      return activityDate.year == today.year &&
             activityDate.month == today.month &&
             activityDate.day == today.day;
    }).toList();
  }

  /// Get weekly summary
  Future<FitnessSummary> getWeeklySummary() async {
    final activities = await getRecentActivities(perPage: 100);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    final weeklyActivities = activities.where((activity) {
      final activityDate = DateTime.fromMillisecondsSinceEpoch(activity.startTime * 1000);
      return activityDate.isAfter(weekStart.subtract(const Duration(days: 1)));
    }).toList();

    double totalDistance = 0;
    int totalTime = 0;
    int totalCalories = 0;
    int workoutCount = 0;

    for (final activity in weeklyActivities) {
      totalDistance += activity.distance;
      totalTime += activity.duration;
      totalCalories += activity.calories;
      workoutCount++;
    }

    return FitnessSummary(
      totalDistance: totalDistance,
      totalTime: totalTime,
      totalCalories: totalCalories,
      workoutCount: workoutCount,
      activities: weeklyActivities,
    );
  }

  /// Calculate fitness-based buffs
  FitnessBuffs calculateFitnessBuffs(List<FitnessWorkout> recentActivities) {
    double totalDistance = 0;
    int totalTime = 0;
    int workoutCount = 0;

    for (final activity in recentActivities) {
      totalDistance += activity.distance;
      totalTime += activity.duration;
      workoutCount++;
    }

    // Calculate buffs based on recent activity
    double strengthBuff = 0;
    double agilityBuff = 0;
    double vitalityBuff = 0;
    int xpBonus = 0;

    // Distance-based buffs
    if (totalDistance > 50) { // 50km in a week
      strengthBuff += 0.1;
      xpBonus += 100;
    }
    if (totalDistance > 100) { // 100km in a week
      strengthBuff += 0.2;
      agilityBuff += 0.1;
      xpBonus += 200;
    }

    // Time-based buffs
    if (totalTime > 3600) { // 1 hour of activity
      vitalityBuff += 0.1;
      xpBonus += 50;
    }
    if (totalTime > 7200) { // 2 hours of activity
      vitalityBuff += 0.2;
      xpBonus += 100;
    }

    // Frequency-based buffs
    if (workoutCount >= 3) { // 3+ workouts
      agilityBuff += 0.1;
      xpBonus += 75;
    }
    if (workoutCount >= 5) { // 5+ workouts
      agilityBuff += 0.2;
      xpBonus += 150;
    }

    return FitnessBuffs(
      strength: strengthBuff,
      agility: agilityBuff,
      vitality: vitalityBuff,
      xpBonus: xpBonus,
      duration: const Duration(hours: 24), // Buffs last 24 hours
    );
  }

  /// Trigger fitness goal events
  void checkFitnessGoals(List<FitnessWorkout> activities) {
    final todayActivities = activities.where((activity) {
      final activityDate = DateTime.fromMillisecondsSinceEpoch(activity.startTime * 1000);
      final today = DateTime.now();
      return activityDate.year == today.year &&
             activityDate.month == today.month &&
             activityDate.day == today.day;
    }).toList();

    // Check for daily goals
    double totalDistance = 0;
    int totalTime = 0;

    for (final activity in todayActivities) {
      totalDistance += activity.distance;
      totalTime += activity.duration;
    }

    // Emit events for completed goals
    if (totalDistance >= 5) { // 5km daily goal
      EventBus().emit('fitness_goal_reached', {
        'goal': 'daily_distance',
        'value': totalDistance,
        'target': 5,
      });
    }

    if (totalTime >= 1800) { // 30 minutes daily goal
      EventBus().emit('fitness_goal_reached', {
        'goal': 'daily_time',
        'value': totalTime,
        'target': 1800,
      });
    }

    if (todayActivities.length >= 1) { // 1 workout daily goal
      EventBus().emit('fitness_goal_reached', {
        'goal': 'daily_workouts',
        'value': todayActivities.length,
        'target': 1,
      });
    }
  }

  /// Get authorization URL for Strava
  String getAuthorizationUrl() {
    return 'https://www.strava.com/oauth/authorize?'
           'client_id=${AppConfig.stravaClientId}'
           '&response_type=code'
           '&redirect_uri=realmofvalor://oauth/callback'
           '&scope=read,activity:read_all'
           '&approval_prompt=force';
  }
}

class FitnessBuffs {
  final double strength;
  final double agility;
  final double vitality;
  final int xpBonus;
  final Duration duration;

  FitnessBuffs({
    required this.strength,
    required this.agility,
    required this.vitality,
    required this.xpBonus,
    required this.duration,
  });

  bool get hasBuffs => strength > 0 || agility > 0 || vitality > 0 || xpBonus > 0;
}

class FitnessSummary {
  final double totalDistance;
  final int totalTime;
  final int totalCalories;
  final int workoutCount;
  final List<FitnessWorkout> activities;

  FitnessSummary({
    required this.totalDistance,
    required this.totalTime,
    required this.totalCalories,
    required this.workoutCount,
    required this.activities,
  });
}

// Provider for FitnessService
final fitnessServiceProvider = Provider<FitnessService>((ref) {
  return FitnessService();
});

// Provider for fitness data
final fitnessDataProvider = FutureProvider<FitnessSummary>((ref) async {
  final fitnessService = ref.read(fitnessServiceProvider);
  return await fitnessService.getWeeklySummary();
});

// Provider for fitness buffs
final fitnessBuffsProvider = FutureProvider<FitnessBuffs>((ref) async {
  final fitnessService = ref.read(fitnessServiceProvider);
  final activities = await fitnessService.getRecentActivities(perPage: 20);
  return fitnessService.calculateFitnessBuffs(activities);
});