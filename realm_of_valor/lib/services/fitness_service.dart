import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config.dart';
import '../data/models/fitness_workout.dart';
import '../data/models/workout_analytics.dart';
import '../data/models/fitness_goals.dart';
import '../data/models/fitness_social.dart';
import '../data/models/fitness_notifications.dart';
import '../data/models/workout_templates.dart';
import '../data/models/performance_tracking.dart';
import '../data/models/fitness_game_integration.dart';
import '../data/models/fitness_reporting.dart';
import 'event_bus.dart';

enum FitnessPlatform {
  strava,
  fitbit,
  garmin,
  appleHealth,
  googleFit,
  manual,
}

class FitnessService {
  static final FitnessService _instance = FitnessService._internal();
  factory FitnessService() => _instance;
  FitnessService._internal();

  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  
  // Multi-platform support
  FitnessPlatform _currentPlatform = FitnessPlatform.strava;
  Map<FitnessPlatform, Map<String, dynamic>> _platformTokens = {};
  Map<FitnessPlatform, bool> _platformConnected = {};
  
  // Fitness goals and challenges
  List<FitnessGoal> _activeGoals = [];
  List<FitnessChallenge> _activeChallenges = [];
  Map<String, GoalProgress> _goalProgress = {};

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
  
  /// Get detailed workout analytics
  Future<WorkoutAnalytics> getWorkoutAnalytics({int days = 30}) async {
    final workouts = await getRecentActivities(perPage: 100);
    final recentWorkouts = workouts.where((w) => 
      DateTime.fromMillisecondsSinceEpoch(w.startTime * 1000)
          .isAfter(DateTime.now().subtract(Duration(days: days)))
    ).toList();
    
    if (recentWorkouts.isEmpty) {
      return WorkoutAnalytics.empty();
    }
    
    // Calculate analytics
    final totalDistance = recentWorkouts.fold<double>(0, (sum, w) => sum + w.distance);
    final totalTime = recentWorkouts.fold<int>(0, (sum, w) => sum + w.duration);
    final totalCalories = recentWorkouts.fold<int>(0, (sum, w) => sum + w.calories);
    final avgHeartRate = recentWorkouts.where((w) => w.avgHeartRate > 0)
        .fold<double>(0, (sum, w) => sum + w.avgHeartRate) / 
        recentWorkouts.where((w) => w.avgHeartRate > 0).length;
    
    // Calculate trends
    final weeklyDistance = _calculateWeeklyTrend(recentWorkouts, (w) => w.distance);
    final weeklyDuration = _calculateWeeklyTrend(recentWorkouts, (w) => w.duration.toDouble());
    final weeklyCalories = _calculateWeeklyTrend(recentWorkouts, (w) => w.calories.toDouble());
    
    // Calculate personal records
    final personalRecords = _calculatePersonalRecords(recentWorkouts);
    
    // Calculate fitness score
    final fitnessScore = _calculateFitnessScore(recentWorkouts);
    
    return WorkoutAnalytics(
      totalWorkouts: recentWorkouts.length,
      totalDistance: totalDistance,
      totalDuration: Duration(seconds: totalTime),
      totalCalories: totalCalories,
      avgHeartRate: avgHeartRate,
      weeklyDistance: weeklyDistance,
      weeklyDuration: weeklyDuration,
      weeklyCalories: weeklyCalories,
      personalRecords: personalRecords,
      fitnessScore: fitnessScore,
      workoutTypes: _getWorkoutTypeDistribution(recentWorkouts),
      bestWorkouts: _getBestWorkouts(recentWorkouts),
    );
  }
  
  List<double> _calculateWeeklyTrend(List<FitnessWorkout> workouts, double Function(FitnessWorkout) metric) {
    final weeks = <double>[];
    final now = DateTime.now();
    
    for (int i = 3; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: 7 * i));
      final weekEnd = weekStart.add(const Duration(days: 7));
      
      final weekWorkouts = workouts.where((w) {
        final workoutDate = DateTime.fromMillisecondsSinceEpoch(w.startTime * 1000);
        return workoutDate.isAfter(weekStart) && workoutDate.isBefore(weekEnd);
      }).toList();
      
      final weekTotal = weekWorkouts.fold<double>(0, (sum, w) => sum + metric(w));
      weeks.add(weekTotal);
    }
    
    return weeks;
  }
  
  Map<String, dynamic> _calculatePersonalRecords(List<FitnessWorkout> workouts) {
    if (workouts.isEmpty) return {};
    
    return {
      'longest_distance': workouts.map((w) => w.distance).reduce((a, b) => a > b ? a : b),
      'longest_duration': workouts.map((w) => w.duration).reduce((a, b) => a > b ? a : b),
      'highest_calories': workouts.map((w) => w.calories).reduce((a, b) => a > b ? a : b),
      'fastest_pace': workouts.where((w) => w.distance > 0)
          .map((w) => w.duration / (w.distance / 1000))
          .reduce((a, b) => a < b ? a : b),
    };
  }
  
  double _calculateFitnessScore(List<FitnessWorkout> workouts) {
    if (workouts.isEmpty) return 0.0;
    
    // Calculate score based on frequency, intensity, and consistency
    final frequency = workouts.length / 30.0; // workouts per day
    final avgDistance = workouts.fold<double>(0, (sum, w) => sum + w.distance) / workouts.length;
    final avgDuration = workouts.fold<int>(0, (sum, w) => sum + w.duration) / workouts.length;
    final avgHeartRate = workouts.where((w) => w.avgHeartRate > 0)
        .fold<double>(0, (sum, w) => sum + w.avgHeartRate) / 
        workouts.where((w) => w.avgHeartRate > 0).length;
    
    // Normalize and weight the factors
    final frequencyScore = (frequency * 100).clamp(0, 100);
    final distanceScore = (avgDistance / 10).clamp(0, 100); // 10km = 100 points
    final durationScore = (avgDuration / 3600).clamp(0, 100); // 1 hour = 100 points
    final heartRateScore = ((avgHeartRate - 120) / 40).clamp(0, 100); // 120-160 bpm range
    
    return (frequencyScore * 0.3 + distanceScore * 0.25 + durationScore * 0.25 + heartRateScore * 0.2);
  }
  
  Map<String, int> _getWorkoutTypeDistribution(List<FitnessWorkout> workouts) {
    final distribution = <String, int>{};
    for (final workout in workouts) {
      distribution[workout.type] = (distribution[workout.type] ?? 0) + 1;
    }
    return distribution;
  }
  
  List<FitnessWorkout> _getBestWorkouts(List<FitnessWorkout> workouts) {
    // Return top 5 workouts by distance
    final sorted = List<FitnessWorkout>.from(workouts);
    sorted.sort((a, b) => b.distance.compareTo(a.distance));
    return sorted.take(5).toList();
  }
  
  /// Create a new fitness goal
  Future<FitnessGoal> createGoal({
    required String name,
    required String description,
    required GoalType type,
    required double target,
    required Duration duration,
    required int rewardXP,
    required int rewardGold,
  }) async {
    final goal = FitnessGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      type: type,
      target: target,
      current: 0.0,
      duration: duration,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(duration),
      rewardXP: rewardXP,
      rewardGold: rewardGold,
      isCompleted: false,
    );
    
    _activeGoals.add(goal);
    _goalProgress[goal.id] = GoalProgress(
      goalId: goal.id,
      current: 0.0,
      percentage: 0.0,
      isCompleted: false,
    );
    
    return goal;
  }
  
  /// Update goal progress based on recent workouts
  Future<void> updateGoalProgress(List<FitnessWorkout> recentWorkouts) async {
    for (final goal in _activeGoals) {
      if (goal.isCompleted) continue;
      
      double progress = 0.0;
      
      switch (goal.type) {
        case GoalType.distance:
          progress = recentWorkouts
              .where((w) => w.startTime >= goal.startDate.millisecondsSinceEpoch ~/ 1000)
              .fold<double>(0, (sum, w) => sum + w.distance);
          break;
        case GoalType.duration:
          progress = recentWorkouts
              .where((w) => w.startTime >= goal.startDate.millisecondsSinceEpoch ~/ 1000)
              .fold<double>(0, (sum, w) => sum + w.duration);
          break;
        case GoalType.calories:
          progress = recentWorkouts
              .where((w) => w.startTime >= goal.startDate.millisecondsSinceEpoch ~/ 1000)
              .fold<double>(0, (sum, w) => sum + w.calories);
          break;
        case GoalType.workouts:
          progress = recentWorkouts
              .where((w) => w.startTime >= goal.startDate.millisecondsSinceEpoch ~/ 1000)
              .length.toDouble();
          break;
      }
      
      final percentage = (progress / goal.target * 100).clamp(0, 100);
      final isCompleted = progress >= goal.target;
      
      _goalProgress[goal.id] = GoalProgress(
        goalId: goal.id,
        current: progress,
        percentage: percentage,
        isCompleted: isCompleted,
      );
      
      if (isCompleted && !goal.isCompleted) {
        goal.isCompleted = true;
        goal.completionDate = DateTime.now();
        
        // Award rewards
        // TODO: Update character with XP and gold
        print('Goal completed: ${goal.name} - ${goal.rewardXP} XP, ${goal.rewardGold} Gold');
      }
    }
  }
  
  /// Get active goals
  List<FitnessGoal> getActiveGoals() {
    return _activeGoals.where((goal) => !goal.isCompleted).toList();
  }
  
  /// Get completed goals
  List<FitnessGoal> getCompletedGoals() {
    return _activeGoals.where((goal) => goal.isCompleted).toList();
  }
  
  /// Get goal progress
  GoalProgress? getGoalProgress(String goalId) {
    return _goalProgress[goalId];
  }
  
  /// Create a fitness challenge
  Future<FitnessChallenge> createChallenge({
    required String name,
    required String description,
    required ChallengeType type,
    required double target,
    required Duration duration,
    required List<String> participants,
    required int rewardXP,
    required int rewardGold,
  }) async {
    final challenge = FitnessChallenge(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      type: type,
      target: target,
      duration: duration,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(duration),
      participants: participants,
      leaderboard: {},
      rewardXP: rewardXP,
      rewardGold: rewardGold,
      isCompleted: false,
    );
    
    _activeChallenges.add(challenge);
    return challenge;
  }
  
  /// Update challenge progress
  Future<void> updateChallengeProgress(String challengeId, String participantId, double progress) async {
    final challenge = _activeChallenges.firstWhere((c) => c.id == challengeId);
    challenge.leaderboard[participantId] = progress;
    
    // Check if challenge is completed
    final maxProgress = challenge.leaderboard.values.reduce((a, b) => a > b ? a : b);
    if (maxProgress >= challenge.target && !challenge.isCompleted) {
      challenge.isCompleted = true;
      challenge.completionDate = DateTime.now();
      
      // Award rewards to winner
      final winner = challenge.leaderboard.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      print('Challenge completed: ${challenge.name} - Winner: $winner');
    }
  }
  
  /// Get active challenges
  List<FitnessChallenge> getActiveChallenges() {
    return _activeChallenges.where((challenge) => !challenge.isCompleted).toList();
  }
  
  /// Get completed challenges
  List<FitnessChallenge> getCompletedChallenges() {
    return _activeChallenges.where((challenge) => challenge.isCompleted).toList();
  }
  
  /// Share workout achievement
  Future<bool> shareWorkout(FitnessWorkout workout, String message) async {
    try {
      // TODO: Implement social sharing
      // This could integrate with social media platforms or in-game social features
      print('Sharing workout: ${workout.type} - ${workout.distance}km');
      return true;
    } catch (e) {
      print('FitnessService: Error sharing workout: $e');
      return false;
    }
  }
  
  /// Create a fitness group
  Future<FitnessGroup> createGroup({
    required String name,
    required String description,
    required String leaderId,
    required int maxMembers,
  }) async {
    final group = FitnessGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      leaderId: leaderId,
      members: [leaderId],
      maxMembers: maxMembers,
      createdAt: DateTime.now(),
      totalDistance: 0.0,
      totalWorkouts: 0,
      challenges: [],
    );
    
    // TODO: Save group to database
    return group;
  }
  
  /// Join a fitness group
  Future<bool> joinGroup(String groupId, String userId) async {
    // TODO: Implement group joining logic
    return true;
  }
  
  /// Get group leaderboard
  Future<List<GroupMember>> getGroupLeaderboard(String groupId, {int days = 7}) async {
    // TODO: Implement group leaderboard
    return [];
  }
  
  /// Send fitness motivation message
  Future<bool> sendMotivationMessage(String recipientId, String message) async {
    // TODO: Implement messaging system
    return true;
  }
  
  /// Get fitness friends
  Future<List<FitnessFriend>> getFitnessFriends() async {
    // TODO: Implement friends system
    return [];
  }
  
  /// Add fitness friend
  Future<bool> addFitnessFriend(String friendId) async {
    // TODO: Implement friend adding
    return true;
  }
  
  /// Get friend's recent activities
  Future<List<FitnessWorkout>> getFriendActivities(String friendId, {int limit = 10}) async {
    // TODO: Implement friend activity sharing
    return [];
  }
  
  /// Compare fitness stats with friend
  Future<FitnessComparison> compareWithFriend(String friendId, {int days = 30}) async {
    // TODO: Implement comparison logic
    return FitnessComparison(
      myStats: WorkoutAnalytics.empty(),
      friendStats: WorkoutAnalytics.empty(),
      comparison: {},
    );
  }
  
  /// Schedule fitness reminder
  Future<bool> scheduleReminder({
    required String title,
    required String message,
    required DateTime scheduledTime,
    required ReminderType type,
    required bool isRepeating,
    List<int>? repeatDays, // 1-7 for days of week
  }) async {
    try {
      final reminder = FitnessReminder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        scheduledTime: scheduledTime,
        type: type,
        isRepeating: isRepeating,
        repeatDays: repeatDays ?? [],
        isActive: true,
        createdAt: DateTime.now(),
      );
      
      // TODO: Save reminder to database and schedule notification
      print('Scheduled reminder: $title at ${scheduledTime.toString()}');
      return true;
    } catch (e) {
      print('FitnessService: Error scheduling reminder: $e');
      return false;
    }
  }
  
  /// Get active reminders
  Future<List<FitnessReminder>> getActiveReminders() async {
    // TODO: Implement reminder retrieval
    return [];
  }
  
  /// Cancel reminder
  Future<bool> cancelReminder(String reminderId) async {
    // TODO: Implement reminder cancellation
    return true;
  }
  
  /// Send achievement notification
  Future<bool> sendAchievementNotification({
    required String title,
    required String message,
    required AchievementType type,
    required int rewardXP,
    required int rewardGold,
  }) async {
    try {
      final notification = FitnessNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: NotificationType.achievement,
        data: {
          'achievement_type': type.name,
          'reward_xp': rewardXP,
          'reward_gold': rewardGold,
        },
        timestamp: DateTime.now(),
        isRead: false,
      );
      
      // TODO: Save notification and trigger in-app notification
      print('Achievement unlocked: $title');
      return true;
    } catch (e) {
      print('FitnessService: Error sending achievement notification: $e');
      return false;
    }
  }
  
  /// Get unread notifications
  Future<List<FitnessNotification>> getUnreadNotifications() async {
    // TODO: Implement notification retrieval
    return [];
  }
  
  /// Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    // TODO: Implement notification marking
    return true;
  }
  
  /// Send goal progress notification
  Future<bool> sendGoalProgressNotification({
    required String goalName,
    required double progress,
    required double target,
  }) async {
    final percentage = (progress / target * 100).round();
    final message = 'Goal Progress: $goalName - $percentage% complete!';
    
    return await sendAchievementNotification(
      title: 'Goal Progress',
      message: message,
      type: AchievementType.goalProgress,
      rewardXP: 0,
      rewardGold: 0,
    );
  }
  
  /// Send streak notification
  Future<bool> sendStreakNotification({
    required int streakDays,
    required String activityType,
  }) async {
    final message = 'Amazing! You\'ve been $activityType for $streakDays days in a row!';
    
    return await sendAchievementNotification(
      title: 'Streak Achievement',
      message: message,
      type: AchievementType.streak,
      rewardXP: streakDays * 10,
      rewardGold: streakDays * 5,
    );
  }
  
  /// Export fitness data to JSON
  Future<String> exportFitnessData({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? dataTypes, // ['workouts', 'goals', 'challenges', 'analytics']
  }) async {
    try {
      final exportData = <String, dynamic>{};
      final now = DateTime.now();
      
      // Export workouts
      if (dataTypes == null || dataTypes.contains('workouts')) {
        final workouts = await getActivities(
          startDate: startDate ?? now.subtract(const Duration(days: 30)),
          endDate: endDate ?? now,
        );
        exportData['workouts'] = workouts.map((w) => w.toJson()).toList();
      }
      
      // Export goals
      if (dataTypes == null || dataTypes.contains('goals')) {
        final goals = await getActiveGoals();
        final completedGoals = await getCompletedGoals();
        exportData['active_goals'] = goals.map((g) => g.toJson()).toList();
        exportData['completed_goals'] = completedGoals.map((g) => g.toJson()).toList();
      }
      
      // Export challenges
      if (dataTypes == null || dataTypes.contains('challenges')) {
        final challenges = await getActiveChallenges();
        final completedChallenges = await getCompletedChallenges();
        exportData['active_challenges'] = challenges.map((c) => c.toJson()).toList();
        exportData['completed_challenges'] = completedChallenges.map((c) => c.toJson()).toList();
      }
      
      // Export analytics
      if (dataTypes == null || dataTypes.contains('analytics')) {
        final analytics = await getWorkoutAnalytics();
        exportData['analytics'] = analytics.toJson();
      }
      
      // Add metadata
      exportData['export_metadata'] = {
        'export_date': now.toIso8601String(),
        'platform': _currentPlatform?.name,
        'data_types': dataTypes ?? ['workouts', 'goals', 'challenges', 'analytics'],
        'version': '1.0.0',
      };
      
      return jsonEncode(exportData);
    } catch (e) {
      print('FitnessService: Error exporting fitness data: $e');
      rethrow;
    }
  }
  
  /// Import fitness data from JSON
  Future<bool> importFitnessData(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final metadata = data['export_metadata'] as Map<String, dynamic>?;
      
      print('Importing fitness data from ${metadata?['export_date'] ?? 'unknown date'}');
      
      // TODO: Implement data import logic
      // This would involve parsing the JSON and saving to local storage/database
      
      return true;
    } catch (e) {
      print('FitnessService: Error importing fitness data: $e');
      return false;
    }
  }
  
  /// Create backup of fitness data
  Future<String> createBackup() async {
    try {
      final backupData = await exportFitnessData();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFileName = 'fitness_backup_$timestamp.json';
      
      // TODO: Save backup to secure location (cloud storage, local file, etc.)
      print('Created backup: $backupFileName');
      
      return backupFileName;
    } catch (e) {
      print('FitnessService: Error creating backup: $e');
      rethrow;
    }
  }
  
  /// Restore fitness data from backup
  Future<bool> restoreFromBackup(String backupFileName) async {
    try {
      // TODO: Load backup file and restore data
      print('Restoring from backup: $backupFileName');
      
      return true;
    } catch (e) {
      print('FitnessService: Error restoring from backup: $e');
      return false;
    }
  }
  
  /// Sync fitness data with cloud
  Future<bool> syncWithCloud() async {
    try {
      // TODO: Implement cloud sync logic
      print('Syncing fitness data with cloud...');
      
      return true;
    } catch (e) {
      print('FitnessService: Error syncing with cloud: $e');
      return false;
    }
  }
  
  /// Create workout template
  Future<WorkoutTemplate> createWorkoutTemplate({
    required String name,
    required String description,
    required WorkoutType type,
    required int targetDuration,
    required double targetDistance,
    required int targetCalories,
    required List<WorkoutSegment> segments,
    required DifficultyLevel difficulty,
    String? notes,
  }) async {
    try {
      final template = WorkoutTemplate(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        type: type,
        targetDuration: targetDuration,
        targetDistance: targetDistance,
        targetCalories: targetCalories,
        segments: segments,
        difficulty: difficulty,
        notes: notes,
        createdAt: DateTime.now(),
        usageCount: 0,
        averageRating: 0.0,
        ratings: [],
      );
      
      // TODO: Save template to database
      print('Created workout template: $name');
      return template;
    } catch (e) {
      print('FitnessService: Error creating workout template: $e');
      rethrow;
    }
  }
  
  /// Get workout templates
  Future<List<WorkoutTemplate>> getWorkoutTemplates({
    WorkoutType? type,
    DifficultyLevel? difficulty,
    bool? isFavorite,
  }) async {
    // TODO: Implement template retrieval with filtering
    return [];
  }
  
  /// Start workout from template
  Future<FitnessWorkout> startWorkoutFromTemplate(String templateId) async {
    try {
      // TODO: Get template and create workout
      final template = await _getWorkoutTemplate(templateId);
      
      final workout = FitnessWorkout(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: template.type,
        name: template.name,
        distance: 0.0,
        duration: 0,
        calories: 0,
        startTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        endTime: null,
        averageSpeed: 0.0,
        maxSpeed: 0.0,
        averageHeartRate: 0,
        maxHeartRate: 0,
        elevationGain: 0.0,
        route: [],
        segments: template.segments,
        templateId: templateId,
      );
      
      // TODO: Save workout and start tracking
      print('Started workout from template: ${template.name}');
      return workout;
    } catch (e) {
      print('FitnessService: Error starting workout from template: $e');
      rethrow;
    }
  }
  
  /// Create workout routine
  Future<WorkoutRoutine> createWorkoutRoutine({
    required String name,
    required String description,
    required List<RoutineDay> days,
    required int durationWeeks,
    String? notes,
  }) async {
    try {
      final routine = WorkoutRoutine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        days: days,
        durationWeeks: durationWeeks,
        notes: notes,
        createdAt: DateTime.now(),
        startDate: null,
        currentWeek: 0,
        currentDay: 0,
        completedWorkouts: [],
        isActive: false,
      );
      
      // TODO: Save routine to database
      print('Created workout routine: $name');
      return routine;
    } catch (e) {
      print('FitnessService: Error creating workout routine: $e');
      rethrow;
    }
  }
  
  /// Start workout routine
  Future<bool> startWorkoutRoutine(String routineId) async {
    try {
      // TODO: Activate routine and set start date
      print('Started workout routine: $routineId');
      return true;
    } catch (e) {
      print('FitnessService: Error starting workout routine: $e');
      return false;
    }
  }
  
  /// Get active workout routine
  Future<WorkoutRoutine?> getActiveRoutine() async {
    // TODO: Implement active routine retrieval
    return null;
  }
  
  /// Complete routine workout
  Future<bool> completeRoutineWorkout(String routineId, String workoutId) async {
    try {
      // TODO: Mark workout as completed in routine
      print('Completed routine workout: $workoutId');
      return true;
    } catch (e) {
      print('FitnessService: Error completing routine workout: $e');
      return false;
    }
  }
  
  /// Rate workout template
  Future<bool> rateWorkoutTemplate(String templateId, double rating, String? review) async {
    try {
      // TODO: Add rating to template
      print('Rated template $templateId: $rating stars');
      return true;
    } catch (e) {
      print('FitnessService: Error rating workout template: $e');
      return false;
    }
  }
  
  /// Get recommended templates
  Future<List<WorkoutTemplate>> getRecommendedTemplates({
    WorkoutType? preferredType,
    DifficultyLevel? preferredDifficulty,
    int limit = 10,
  }) async {
    // TODO: Implement recommendation algorithm
    return [];
  }
  
  /// Share workout template
  Future<bool> shareWorkoutTemplate(String templateId, String message) async {
    try {
      // TODO: Implement template sharing
      print('Shared workout template: $templateId');
      return true;
    } catch (e) {
      print('FitnessService: Error sharing workout template: $e');
      return false;
    }
  }
  
  /// Get workout template
  Future<WorkoutTemplate> _getWorkoutTemplate(String templateId) async {
    // TODO: Implement template retrieval
    throw UnimplementedError('Template retrieval not implemented');
  }
  
  /// Track performance metrics
  Future<PerformanceMetrics> calculatePerformanceMetrics({
    DateTime? startDate,
    DateTime? endDate,
    List<WorkoutType>? workoutTypes,
  }) async {
    try {
      final now = DateTime.now();
      final activities = await getActivities(
        startDate: startDate ?? now.subtract(const Duration(days: 30)),
        endDate: endDate ?? now,
      );
      
      // Filter by workout types if specified
      final filteredActivities = workoutTypes != null
          ? activities.where((a) => workoutTypes.contains(a.type)).toList()
          : activities;
      
      if (filteredActivities.isEmpty) {
        return PerformanceMetrics.empty();
      }
      
      // Calculate basic metrics
      double totalDistance = 0;
      int totalDuration = 0;
      int totalCalories = 0;
      double totalElevation = 0;
      double maxSpeed = 0;
      int maxHeartRate = 0;
      int totalWorkouts = filteredActivities.length;
      
      // Calculate averages and trends
      final distances = <double>[];
      final durations = <int>[];
      final speeds = <double>[];
      final heartRates = <int>[];
      
      for (final activity in filteredActivities) {
        totalDistance += activity.distance;
        totalDuration += activity.duration;
        totalCalories += activity.calories;
        totalElevation += activity.elevationGain;
        
        if (activity.maxSpeed > maxSpeed) maxSpeed = activity.maxSpeed;
        if (activity.maxHeartRate > maxHeartRate) maxHeartRate = activity.maxHeartRate;
        
        distances.add(activity.distance);
        durations.add(activity.duration);
        speeds.add(activity.averageSpeed);
        if (activity.averageHeartRate > 0) heartRates.add(activity.averageHeartRate);
      }
      
      // Calculate trends
      final distanceTrend = _calculateTrend(distances);
      final durationTrend = _calculateTrend(durations.map((d) => d.toDouble()).toList());
      final speedTrend = _calculateTrend(speeds);
      final heartRateTrend = heartRates.isNotEmpty ? _calculateTrend(heartRates.map((h) => h.toDouble()).toList()) : 0.0;
      
      // Calculate personal records
      final personalRecords = PersonalRecords(
        longestDistance: distances.reduce((a, b) => a > b ? a : b),
        longestDuration: durations.reduce((a, b) => a > b ? a : b),
        fastestPace: speeds.isNotEmpty ? speeds.reduce((a, b) => a > b ? a : b) : 0.0,
        highestElevation: totalElevation,
        maxHeartRate: maxHeartRate,
      );
      
      // Calculate consistency score
      final consistencyScore = _calculateConsistencyScore(filteredActivities);
      
      // Calculate improvement rate
      final improvementRate = _calculateImprovementRate(filteredActivities);
      
      return PerformanceMetrics(
        totalDistance: totalDistance,
        totalDuration: totalDuration,
        totalCalories: totalCalories,
        totalElevation: totalElevation,
        totalWorkouts: totalWorkouts,
        averageDistance: totalDistance / totalWorkouts,
        averageDuration: totalDuration / totalWorkouts,
        averageSpeed: speeds.isNotEmpty ? speeds.reduce((a, b) => a + b) / speeds.length : 0.0,
        averageHeartRate: heartRates.isNotEmpty ? heartRates.reduce((a, b) => a + b) / heartRates.length : 0,
        maxSpeed: maxSpeed,
        maxHeartRate: maxHeartRate,
        distanceTrend: distanceTrend,
        durationTrend: durationTrend,
        speedTrend: speedTrend,
        heartRateTrend: heartRateTrend,
        personalRecords: personalRecords,
        consistencyScore: consistencyScore,
        improvementRate: improvementRate,
        workoutTypes: filteredActivities.map((a) => a.type).toSet().toList(),
        dateRange: DateRange(
          startDate: startDate ?? now.subtract(const Duration(days: 30)),
          endDate: endDate ?? now,
        ),
      );
    } catch (e) {
      print('FitnessService: Error calculating performance metrics: $e');
      return PerformanceMetrics.empty();
    }
  }
  
  /// Calculate trend (positive = improving, negative = declining)
  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0.0;
    
    // Simple linear regression
    final n = values.length;
    final x = List.generate(n, (i) => i.toDouble());
    final y = values;
    
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = x.asMap().entries.map((e) => e.key * y[e.key]).reduce((a, b) => a + b);
    final sumXX = x.map((x) => x * x).reduce((a, b) => a + b);
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    return slope;
  }
  
  /// Calculate consistency score (0-100)
  double _calculateConsistencyScore(List<FitnessWorkout> activities) {
    if (activities.isEmpty) return 0.0;
    
    // Group activities by week
    final weeklyActivities = <int, List<FitnessWorkout>>{};
    for (final activity in activities) {
      final week = DateTime.fromMillisecondsSinceEpoch(activity.startTime * 1000)
          .difference(DateTime(2020, 1, 1))
          .inDays ~/ 7;
      weeklyActivities.putIfAbsent(week, () => []).add(activity);
    }
    
    final weeksWithActivity = weeklyActivities.length;
    final totalWeeks = weeklyActivities.keys.reduce((a, b) => a > b ? a : b) -
        weeklyActivities.keys.reduce((a, b) => a < b ? a : b) + 1;
    
    return (weeksWithActivity / totalWeeks) * 100;
  }
  
  /// Calculate improvement rate (percentage)
  double _calculateImprovementRate(List<FitnessWorkout> activities) {
    if (activities.length < 2) return 0.0;
    
    // Sort by date
    activities.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // Compare first and last activity
    final firstActivity = activities.first;
    final lastActivity = activities.last;
    
    final distanceImprovement = ((lastActivity.distance - firstActivity.distance) / firstActivity.distance) * 100;
    final speedImprovement = ((lastActivity.averageSpeed - firstActivity.averageSpeed) / firstActivity.averageSpeed) * 100;
    
    return (distanceImprovement + speedImprovement) / 2;
  }
  
  /// Get performance insights
  Future<List<PerformanceInsight>> getPerformanceInsights({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final metrics = await calculatePerformanceMetrics(
        startDate: startDate,
        endDate: endDate,
      );
      
      final insights = <PerformanceInsight>[];
      
      // Distance insights
      if (metrics.distanceTrend > 0) {
        insights.add(PerformanceInsight(
          type: InsightType.improvement,
          title: 'Distance Improvement',
          message: 'Your average distance has increased by ${metrics.distanceTrend.toStringAsFixed(1)}km per workout!',
          metric: 'distance',
          value: metrics.distanceTrend,
        ));
      } else if (metrics.distanceTrend < 0) {
        insights.add(PerformanceInsight(
          type: InsightType.decline,
          title: 'Distance Decline',
          message: 'Your average distance has decreased. Consider increasing your workout intensity.',
          metric: 'distance',
          value: metrics.distanceTrend,
        ));
      }
      
      // Speed insights
      if (metrics.speedTrend > 0) {
        insights.add(PerformanceInsight(
          type: InsightType.improvement,
          title: 'Speed Improvement',
          message: 'Your average speed has improved by ${metrics.speedTrend.toStringAsFixed(2)} km/h!',
          metric: 'speed',
          value: metrics.speedTrend,
        ));
      }
      
      // Consistency insights
      if (metrics.consistencyScore > 80) {
        insights.add(PerformanceInsight(
          type: InsightType.achievement,
          title: 'Excellent Consistency',
          message: 'You\'ve been very consistent with your workouts! Keep it up!',
          metric: 'consistency',
          value: metrics.consistencyScore,
        ));
      } else if (metrics.consistencyScore < 50) {
        insights.add(PerformanceInsight(
          type: InsightType.warning,
          title: 'Low Consistency',
          message: 'Try to maintain a more regular workout schedule for better results.',
          metric: 'consistency',
          value: metrics.consistencyScore,
        ));
      }
      
      // Personal record insights
      if (metrics.personalRecords.longestDistance > 0) {
        insights.add(PerformanceInsight(
          type: InsightType.achievement,
          title: 'Personal Record',
          message: 'Your longest distance is ${metrics.personalRecords.longestDistance.toStringAsFixed(1)}km!',
          metric: 'longest_distance',
          value: metrics.personalRecords.longestDistance,
        ));
      }
      
      return insights;
    } catch (e) {
      print('FitnessService: Error getting performance insights: $e');
      return [];
    }
  }
  
  /// Set performance goals
  Future<bool> setPerformanceGoal({
    required String metric,
    required double target,
    required DateTime deadline,
    String? description,
  }) async {
    try {
      final goal = PerformanceGoal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        metric: metric,
        target: target,
        current: 0.0,
        deadline: deadline,
        description: description,
        createdAt: DateTime.now(),
        isCompleted: false,
      );
      
      // TODO: Save performance goal
      print('Set performance goal: $metric - $target by ${deadline.toString()}');
      return true;
    } catch (e) {
      print('FitnessService: Error setting performance goal: $e');
      return false;
    }
  }
  
  /// Get performance goals
  Future<List<PerformanceGoal>> getPerformanceGoals() async {
    // TODO: Implement performance goals retrieval
    return [];
  }
  
  /// Calculate fitness-based game rewards
  Future<FitnessGameRewards> calculateGameRewards({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final activities = await getActivities(
        startDate: startDate ?? now.subtract(const Duration(days: 7)),
        endDate: endDate ?? now,
      );
      
      if (activities.isEmpty) {
        return FitnessGameRewards.empty();
      }
      
      // Calculate rewards based on fitness activities
      int totalXP = 0;
      int totalGold = 0;
      int totalCards = 0;
      List<String> unlockedAchievements = [];
      List<FitnessBuff> activeBuffs = [];
      
      // Distance-based rewards
      double totalDistance = activities.fold(0.0, (sum, activity) => sum + activity.distance);
      totalXP += (totalDistance * 10).round(); // 10 XP per km
      totalGold += (totalDistance * 2).round(); // 2 gold per km
      
      // Duration-based rewards
      int totalDuration = activities.fold(0, (sum, activity) => sum + activity.duration);
      totalXP += (totalDuration / 60 * 5).round(); // 5 XP per minute
      
      // Calorie-based rewards
      int totalCalories = activities.fold(0, (sum, activity) => sum + activity.calories);
      totalGold += (totalCalories / 100).round(); // 1 gold per 100 calories
      
      // Streak rewards
      final streakDays = _calculateCurrentStreak(activities);
      if (streakDays >= 7) {
        totalXP += 100; // Weekly streak bonus
        unlockedAchievements.add('Weekly Warrior');
      }
      if (streakDays >= 30) {
        totalXP += 500; // Monthly streak bonus
        unlockedAchievements.add('Monthly Master');
      }
      
      // Personal record rewards
      final personalRecords = _checkPersonalRecords(activities);
      for (final record in personalRecords) {
        totalXP += 50;
        totalGold += 25;
        unlockedAchievements.add(record);
      }
      
      // Workout type variety rewards
      final workoutTypes = activities.map((a) => a.type).toSet();
      if (workoutTypes.length >= 3) {
        totalXP += 75; // Variety bonus
        unlockedAchievements.add('Fitness Explorer');
      }
      
      // Generate random cards based on workout intensity
      final totalIntensity = activities.fold(0.0, (sum, activity) => 
          sum + (activity.averageSpeed * activity.duration / 3600));
      totalCards = (totalIntensity / 10).round(); // 1 card per 10 intensity units
      
      // Calculate active buffs
      activeBuffs = _calculateActiveBuffs(activities);
      
      return FitnessGameRewards(
        xp: totalXP,
        gold: totalGold,
        cards: totalCards,
        unlockedAchievements: unlockedAchievements,
        activeBuffs: activeBuffs,
        period: DateRange(
          startDate: startDate ?? now.subtract(const Duration(days: 7)),
          endDate: endDate ?? now,
        ),
      );
    } catch (e) {
      print('FitnessService: Error calculating game rewards: $e');
      return FitnessGameRewards.empty();
    }
  }
  
  /// Apply fitness buffs to game stats
  Future<GameStats> applyFitnessBuffs(GameStats baseStats, List<FitnessWorkout> recentActivities) async {
    try {
      final buffs = _calculateActiveBuffs(recentActivities);
      final modifiedStats = baseStats.copyWith();
      
      for (final buff in buffs) {
        switch (buff.type) {
          case BuffType.strength:
            modifiedStats.strength = (modifiedStats.strength * (1 + buff.value)).round();
            break;
          case BuffType.agility:
            modifiedStats.agility = (modifiedStats.agility * (1 + buff.value)).round();
            break;
          case BuffType.vitality:
            modifiedStats.vitality = (modifiedStats.vitality * (1 + buff.value)).round();
            break;
          case BuffType.intelligence:
            modifiedStats.intelligence = (modifiedStats.intelligence * (1 + buff.value)).round();
            break;
          case BuffType.xpBonus:
            modifiedStats.xpBonus = (modifiedStats.xpBonus + buff.value).round();
            break;
        }
      }
      
      return modifiedStats;
    } catch (e) {
      print('FitnessService: Error applying fitness buffs: $e');
      return baseStats;
    }
  }
  
  /// Unlock fitness-based achievements
  Future<List<FitnessAchievement>> checkFitnessAchievements(List<FitnessWorkout> activities) async {
    try {
      final achievements = <FitnessAchievement>[];
      
      // Distance achievements
      final totalDistance = activities.fold(0.0, (sum, activity) => sum + activity.distance);
      if (totalDistance >= 100 && !_hasAchievement('First Century')) {
        achievements.add(FitnessAchievement(
          id: 'first_century',
          name: 'First Century',
          description: 'Complete 100km of activities',
          type: AchievementType.milestone,
          rewardXP: 200,
          rewardGold: 100,
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        ));
      }
      
      // Streak achievements
      final streakDays = _calculateCurrentStreak(activities);
      if (streakDays >= 7 && !_hasAchievement('Weekly Warrior')) {
        achievements.add(FitnessAchievement(
          id: 'weekly_warrior',
          name: 'Weekly Warrior',
          description: 'Maintain a 7-day workout streak',
          type: AchievementType.streak,
          rewardXP: 150,
          rewardGold: 75,
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        ));
      }
      
      // Speed achievements
      final maxSpeed = activities.fold(0.0, (max, activity) => 
          activity.maxSpeed > max ? activity.maxSpeed : max);
      if (maxSpeed >= 20 && !_hasAchievement('Speed Demon')) {
        achievements.add(FitnessAchievement(
          id: 'speed_demon',
          name: 'Speed Demon',
          description: 'Reach a maximum speed of 20 km/h',
          type: AchievementType.personalRecord,
          rewardXP: 100,
          rewardGold: 50,
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        ));
      }
      
      return achievements;
    } catch (e) {
      print('FitnessService: Error checking fitness achievements: $e');
      return [];
    }
  }
  
  /// Generate fitness-based quests
  Future<List<FitnessQuest>> generateFitnessQuests({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final activities = await getActivities(
        startDate: startDate ?? now.subtract(const Duration(days: 30)),
        endDate: endDate ?? now,
      );
      
      final quests = <FitnessQuest>[];
      
      // Distance quest
      final weeklyDistance = activities
          .where((a) => a.startTime >= (now.subtract(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000))
          .fold(0.0, (sum, activity) => sum + activity.distance);
      
      quests.add(FitnessQuest(
        id: 'weekly_distance_${now.millisecondsSinceEpoch}',
        name: 'Weekly Distance Challenge',
        description: 'Complete 50km this week',
        type: QuestType.distance,
        target: 50.0,
        current: weeklyDistance,
        rewardXP: 300,
        rewardGold: 150,
        deadline: now.add(const Duration(days: 7)),
        isCompleted: weeklyDistance >= 50.0,
      ));
      
      // Streak quest
      final currentStreak = _calculateCurrentStreak(activities);
      quests.add(FitnessQuest(
        id: 'streak_challenge_${now.millisecondsSinceEpoch}',
        name: 'Streak Master',
        description: 'Maintain a 10-day workout streak',
        type: QuestType.streak,
        target: 10.0,
        current: currentStreak.toDouble(),
        rewardXP: 500,
        rewardGold: 250,
        deadline: now.add(const Duration(days: 14)),
        isCompleted: currentStreak >= 10,
      ));
      
      // Variety quest
      final workoutTypes = activities.map((a) => a.type).toSet();
      quests.add(FitnessQuest(
        id: 'variety_challenge_${now.millisecondsSinceEpoch}',
        name: 'Fitness Explorer',
        description: 'Try 5 different workout types',
        type: QuestType.variety,
        target: 5.0,
        current: workoutTypes.length.toDouble(),
        rewardXP: 200,
        rewardGold: 100,
        deadline: now.add(const Duration(days: 30)),
        isCompleted: workoutTypes.length >= 5,
      ));
      
      return quests;
    } catch (e) {
      print('FitnessService: Error generating fitness quests: $e');
      return [];
    }
  }
  
  /// Calculate current streak
  int _calculateCurrentStreak(List<FitnessWorkout> activities) {
    if (activities.isEmpty) return 0;
    
    // Sort activities by date
    activities.sort((a, b) => b.startTime.compareTo(a.startTime));
    
    final now = DateTime.now();
    int streak = 0;
    DateTime currentDate = now;
    
    for (int i = 0; i < 365; i++) { // Check up to a year
      final dayStart = DateTime(currentDate.year, currentDate.month, currentDate.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final hasActivity = activities.any((activity) {
        final activityDate = DateTime.fromMillisecondsSinceEpoch(activity.startTime * 1000);
        return activityDate.isAfter(dayStart) && activityDate.isBefore(dayEnd);
      });
      
      if (hasActivity) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }
  
  /// Check for personal records
  List<String> _checkPersonalRecords(List<FitnessWorkout> activities) {
    final records = <String>[];
    
    if (activities.isEmpty) return records;
    
    // Find maximum values
    final maxDistance = activities.fold(0.0, (max, activity) => 
        activity.distance > max ? activity.distance : max);
    final maxSpeed = activities.fold(0.0, (max, activity) => 
        activity.maxSpeed > max ? activity.maxSpeed : max);
    final maxDuration = activities.fold(0, (max, activity) => 
        activity.duration > max ? activity.duration : max);
    
    // Check against thresholds
    if (maxDistance >= 10) records.add('Distance Champion');
    if (maxSpeed >= 15) records.add('Speed Champion');
    if (maxDuration >= 3600) records.add('Endurance Champion');
    
    return records;
  }
  
  /// Calculate active buffs
  List<FitnessBuff> _calculateActiveBuffs(List<FitnessWorkout> activities) {
    final buffs = <FitnessBuff>[];
    
    if (activities.isEmpty) return buffs;
    
    // Recent activity buffs (last 7 days)
    final recentActivities = activities.where((a) => 
        a.startTime >= (DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000)).toList();
    
    if (recentActivities.isNotEmpty) {
      final totalDistance = recentActivities.fold(0.0, (sum, activity) => sum + activity.distance);
      final totalDuration = recentActivities.fold(0, (sum, activity) => sum + activity.duration);
      
      // Distance-based buffs
      if (totalDistance >= 20) {
        buffs.add(FitnessBuff(
          type: BuffType.strength,
          value: 0.1, // 10% strength bonus
          duration: const Duration(hours: 24),
          description: 'Distance Warrior',
        ));
      }
      
      // Duration-based buffs
      if (totalDuration >= 7200) { // 2 hours
        buffs.add(FitnessBuff(
          type: BuffType.vitality,
          value: 0.15, // 15% vitality bonus
          duration: const Duration(hours: 24),
          description: 'Endurance Master',
        ));
      }
      
      // Speed-based buffs
      final avgSpeed = recentActivities.fold(0.0, (sum, activity) => sum + activity.averageSpeed) / recentActivities.length;
      if (avgSpeed >= 10) {
        buffs.add(FitnessBuff(
          type: BuffType.agility,
          value: 0.12, // 12% agility bonus
          duration: const Duration(hours: 24),
          description: 'Speed Demon',
        ));
      }
    }
    
    return buffs;
  }
  
  /// Check if achievement is already unlocked
  bool _hasAchievement(String achievementName) {
    // TODO: Implement achievement tracking
    return false;
  }
  
  /// Generate fitness report
  Future<FitnessReport> generateFitnessReport({
    DateTime? startDate,
    DateTime? endDate,
    ReportType type = ReportType.weekly,
  }) async {
    try {
      final now = DateTime.now();
      final activities = await getActivities(
        startDate: startDate ?? _getReportStartDate(type),
        endDate: endDate ?? now,
      );
      
      if (activities.isEmpty) {
        return FitnessReport.empty();
      }
      
      // Calculate basic statistics
      final totalDistance = activities.fold(0.0, (sum, activity) => sum + activity.distance);
      final totalDuration = activities.fold(0, (sum, activity) => sum + activity.duration);
      final totalCalories = activities.fold(0, (sum, activity) => sum + activity.calories);
      final totalElevation = activities.fold(0.0, (sum, activity) => sum + activity.elevationGain);
      
      // Calculate averages
      final avgDistance = totalDistance / activities.length;
      final avgDuration = totalDuration / activities.length;
      final avgSpeed = activities.fold(0.0, (sum, activity) => sum + activity.averageSpeed) / activities.length;
      final avgHeartRate = activities.where((a) => a.averageHeartRate > 0)
          .fold(0, (sum, activity) => sum + activity.averageHeartRate) / 
          activities.where((a) => a.averageHeartRate > 0).length;
      
      // Calculate trends
      final trends = _calculateTrends(activities);
      
      // Generate insights
      final insights = await getPerformanceInsights(startDate: startDate, endDate: endDate);
      
      // Calculate achievements
      final achievements = await checkFitnessAchievements(activities);
      
      // Generate recommendations
      final recommendations = _generateRecommendations(activities, trends);
      
      return FitnessReport(
        period: DateRange(
          startDate: startDate ?? _getReportStartDate(type),
          endDate: endDate ?? now,
        ),
        type: type,
        totalActivities: activities.length,
        totalDistance: totalDistance,
        totalDuration: totalDuration,
        totalCalories: totalCalories,
        totalElevation: totalElevation,
        averageDistance: avgDistance,
        averageDuration: avgDuration,
        averageSpeed: avgSpeed,
        averageHeartRate: avgHeartRate,
        trends: trends,
        insights: insights,
        achievements: achievements,
        recommendations: recommendations,
        workoutTypeDistribution: _calculateWorkoutTypeDistribution(activities),
        dailyActivityChart: _generateDailyActivityChart(activities),
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      print('FitnessService: Error generating fitness report: $e');
      return FitnessReport.empty();
    }
  }
  
  /// Export fitness report to PDF
  Future<String> exportFitnessReportToPDF(FitnessReport report) async {
    try {
      // TODO: Implement PDF generation
      final fileName = 'fitness_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      print('Exported fitness report to: $fileName');
      return fileName;
    } catch (e) {
      print('FitnessService: Error exporting fitness report: $e');
      rethrow;
    }
  }
  
  /// Share fitness report
  Future<bool> shareFitnessReport(FitnessReport report, String message) async {
    try {
      // TODO: Implement report sharing
      print('Shared fitness report: ${report.type.name}');
      return true;
    } catch (e) {
      print('FitnessService: Error sharing fitness report: $e');
      return false;
    }
  }
  
  /// Get report start date based on type
  DateTime _getReportStartDate(ReportType type) {
    final now = DateTime.now();
    switch (type) {
      case ReportType.daily:
        return DateTime(now.year, now.month, now.day);
      case ReportType.weekly:
        return now.subtract(Duration(days: now.weekday - 1));
      case ReportType.monthly:
        return DateTime(now.year, now.month, 1);
      case ReportType.yearly:
        return DateTime(now.year, 1, 1);
      case ReportType.custom:
        return now.subtract(const Duration(days: 30));
    }
  }
  
  /// Calculate trends for different metrics
  Map<String, double> _calculateTrends(List<FitnessWorkout> activities) {
    final trends = <String, double>{};
    
    if (activities.length < 2) return trends;
    
    // Sort activities by date
    activities.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // Calculate trends for different metrics
    final distances = activities.map((a) => a.distance).toList();
    final durations = activities.map((a) => a.duration.toDouble()).toList();
    final speeds = activities.map((a) => a.averageSpeed).toList();
    final heartRates = activities.where((a) => a.averageHeartRate > 0)
        .map((a) => a.averageHeartRate.toDouble()).toList();
    
    trends['distance'] = _calculateTrend(distances);
    trends['duration'] = _calculateTrend(durations);
    trends['speed'] = _calculateTrend(speeds);
    if (heartRates.isNotEmpty) {
      trends['heart_rate'] = _calculateTrend(heartRates);
    }
    
    return trends;
  }
  
  /// Generate recommendations based on data
  List<FitnessRecommendation> _generateRecommendations(
    List<FitnessWorkout> activities,
    Map<String, double> trends,
  ) {
    final recommendations = <FitnessRecommendation>[];
    
    // Distance recommendations
    final avgDistance = activities.fold(0.0, (sum, activity) => sum + activity.distance) / activities.length;
    if (avgDistance < 5.0) {
      recommendations.add(FitnessRecommendation(
        type: RecommendationType.increaseDistance,
        title: 'Increase Distance',
        description: 'Try to increase your average workout distance to 5km or more.',
        priority: RecommendationPriority.medium,
      ));
    }
    
    // Frequency recommendations
    final weeklyFrequency = activities.where((a) => 
        a.startTime >= (DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000)).length;
    if (weeklyFrequency < 3) {
      recommendations.add(FitnessRecommendation(
        type: RecommendationType.increaseFrequency,
        title: 'Increase Frequency',
        description: 'Aim for at least 3 workouts per week for better results.',
        priority: RecommendationPriority.high,
      ));
    }
    
    // Variety recommendations
    final workoutTypes = activities.map((a) => a.type).toSet();
    if (workoutTypes.length < 2) {
      recommendations.add(FitnessRecommendation(
        type: RecommendationType.addVariety,
        title: 'Add Variety',
        description: 'Try different types of workouts to improve overall fitness.',
        priority: RecommendationPriority.low,
      ));
    }
    
    // Trend-based recommendations
    if (trends['distance'] != null && trends['distance']! < 0) {
      recommendations.add(FitnessRecommendation(
        type: RecommendationType.maintainProgress,
        title: 'Maintain Progress',
        description: 'Your distance has been declining. Consider increasing intensity.',
        priority: RecommendationPriority.high,
      ));
    }
    
    return recommendations;
  }
  
  /// Calculate workout type distribution
  Map<String, double> _calculateWorkoutTypeDistribution(List<FitnessWorkout> activities) {
    final distribution = <String, double>{};
    final total = activities.length;
    
    if (total == 0) return distribution;
    
    for (final activity in activities) {
      final type = activity.type.name;
      distribution[type] = (distribution[type] ?? 0) + 1;
    }
    
    // Convert to percentages
    for (final entry in distribution.entries) {
      distribution[entry.key] = (entry.value / total) * 100;
    }
    
    return distribution;
  }
  
  /// Generate daily activity chart data
  List<DailyActivityData> _generateDailyActivityChart(List<FitnessWorkout> activities) {
    final chartData = <DailyActivityData>[];
    final dailyStats = <String, DailyActivityData>{};
    
    for (final activity in activities) {
      final date = DateTime.fromMillisecondsSinceEpoch(activity.startTime * 1000);
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      if (!dailyStats.containsKey(dateKey)) {
        dailyStats[dateKey] = DailyActivityData(
          date: date,
          distance: 0.0,
          duration: 0,
          calories: 0,
          activities: 0,
        );
      }
      
      final stats = dailyStats[dateKey]!;
      stats.distance += activity.distance;
      stats.duration += activity.duration;
      stats.calories += activity.calories;
      stats.activities += 1;
    }
    
    return dailyStats.values.toList()..sort((a, b) => a.date.compareTo(b.date));
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
