import 'package:google_maps_flutter/google_maps_flutter.dart';

enum TrailDifficulty { easy, moderate, hard, expert }
enum TrailType { hiking, running, cycling, walking, mountainBiking }

/// Complete enhanced Trail model with all 8+ improvements
class TrailEnhanced {
  final String id;
  final String name;
  final String description;
  final LatLng startLocation;
  final LatLng endLocation;
  final List<LatLng> waypoints;
  final double distance;
  final double elevationGain;
  final TrailDifficulty difficulty;
  final TrailType type;
  final List<String> tags;
  final String region;
  final String country;
  final double rating;
  final int reviewCount;
  final String? imageUrl;
  final Map<String, dynamic> metadata;
  
  // Strava integration
  final String? stravaSegmentId;
  final Map<String, dynamic>? segmentLeaderboard;
  final Map<String, dynamic>? personalBest;
  
  // Dynamic difficulty
  final double technicalRating;
  final double exposureRating;
  final String surfaceType;
  
  // Completion tracking
  final int completionCount;
  final DateTime? lastCompletedAt;
  final List<DateTime> completionHistory;
  
  // Environmental
  final String? currentWeather;
  final double? currentTemp;
  final String recommendedTimeOfDay;
  
  // Seasonal
  final String bestSeason;
  final Map<String, String> seasonalConditions;
  
  // Safety
  final bool requiresPermit;
  final bool hasCellService;
  final List<String> hazards;
  final String? emergencyContact;
  
  // Social
  final List<String> completedByFriends;
  final List<Map<String, dynamic>> recentActivities;
  
  // Multi-sport
  final Map<TrailType, bool> allowedActivities;
  final Map<TrailType, TrailDifficulty> difficultyByType;

  const TrailEnhanced({
    required this.id,
    required this.name,
    required this.description,
    required this.startLocation,
    required this.endLocation,
    required this.waypoints,
    required this.distance,
    required this.elevationGain,
    required this.difficulty,
    required this.type,
    required this.tags,
    required this.region,
    required this.country,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.imageUrl,
    this.metadata = const {},
    this.stravaSegmentId,
    this.segmentLeaderboard,
    this.personalBest,
    this.technicalRating = 3.0,
    this.exposureRating = 2.0,
    this.surfaceType = 'dirt',
    this.completionCount = 0,
    this.lastCompletedAt,
    this.completionHistory = const [],
    this.currentWeather,
    this.currentTemp,
    this.recommendedTimeOfDay = 'morning',
    this.bestSeason = 'spring',
    this.seasonalConditions = const {},
    this.requiresPermit = false,
    this.hasCellService = true,
    this.hazards = const [],
    this.emergencyContact,
    this.completedByFriends = const [],
    this.recentActivities = const [],
    this.allowedActivities = const {},
    this.difficultyByType = const {},
  });

  /// Get difficulty color for map markers
  Color get difficultyColor {
    switch (difficulty) {
      case TrailDifficulty.easy:
        return const Color(0xFF4CAF50);
      case TrailDifficulty.moderate:
        return const Color(0xFF2196F3);
      case TrailDifficulty.hard:
        return const Color(0xFFFF9800);
      case TrailDifficulty.expert:
        return const Color(0xFFF44336);
    }
  }

  /// Get polyline color for trail route
  Color get routeColor => difficultyColor.withOpacity(0.8);

  /// Calculate estimated completion time
  Duration get estimatedDuration {
    final baseTime = (distance / 1000) / 5 * 3600; // 5 km/h
    final elevationTime = (elevationGain / 100) * 600; // 10min per 100m
    final difficultyMultiplier = _getDifficultyMultiplier();
    return Duration(seconds: ((baseTime + elevationTime) * difficultyMultiplier).toInt());
  }

  double _getDifficultyMultiplier() {
    switch (difficulty) {
      case TrailDifficulty.easy:
        return 0.9;
      case TrailDifficulty.moderate:
        return 1.0;
      case TrailDifficulty.hard:
        return 1.2;
      case TrailDifficulty.expert:
        return 1.5;
    }
  }

  /// Get reward multiplier based on difficulty
  double get rewardMultiplier {
    switch (difficulty) {
      case TrailDifficulty.easy:
        return 1.0;
      case TrailDifficulty.moderate:
        return 1.5;
      case TrailDifficulty.hard:
        return 2.0;
      case TrailDifficulty.expert:
        return 3.0;
    }
  }
}
