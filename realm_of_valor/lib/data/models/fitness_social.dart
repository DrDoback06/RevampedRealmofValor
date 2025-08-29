import 'workout_analytics.dart';

class FitnessGroup {
  final String id;
  final String name;
  final String description;
  final String leaderId;
  final List<String> members;
  final int maxMembers;
  final DateTime createdAt;
  final double totalDistance;
  final int totalWorkouts;
  final List<String> challenges;

  const FitnessGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.leaderId,
    required this.members,
    required this.maxMembers,
    required this.createdAt,
    required this.totalDistance,
    required this.totalWorkouts,
    required this.challenges,
  });

  bool get isFull => members.length >= maxMembers;
  bool get canJoin => !isFull;
  int get memberCount => members.length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'leader_id': leaderId,
      'members': members,
      'max_members': maxMembers,
      'created_at': createdAt.toIso8601String(),
      'total_distance': totalDistance,
      'total_workouts': totalWorkouts,
      'challenges': challenges,
    };
  }

  factory FitnessGroup.fromJson(Map<String, dynamic> json) {
    return FitnessGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      leaderId: json['leader_id'] as String,
      members: List<String>.from(json['members']),
      maxMembers: json['max_members'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      totalDistance: json['total_distance'] as double,
      totalWorkouts: json['total_workouts'] as int,
      challenges: List<String>.from(json['challenges']),
    );
  }
}

class GroupMember {
  final String userId;
  final String name;
  final double totalDistance;
  final int totalWorkouts;
  final int rank;
  final DateTime lastActivity;

  const GroupMember({
    required this.userId,
    required this.name,
    required this.totalDistance,
    required this.totalWorkouts,
    required this.rank,
    required this.lastActivity,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'total_distance': totalDistance,
      'total_workouts': totalWorkouts,
      'rank': rank,
      'last_activity': lastActivity.toIso8601String(),
    };
  }

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      totalDistance: json['total_distance'] as double,
      totalWorkouts: json['total_workouts'] as int,
      rank: json['rank'] as int,
      lastActivity: DateTime.parse(json['last_activity'] as String),
    );
  }
}

class FitnessFriend {
  final String id;
  final String name;
  final String avatar;
  final bool isOnline;
  final DateTime lastActivity;
  final double totalDistance;
  final int totalWorkouts;
  final String fitnessLevel;

  const FitnessFriend({
    required this.id,
    required this.name,
    required this.avatar,
    required this.isOnline,
    required this.lastActivity,
    required this.totalDistance,
    required this.totalWorkouts,
    required this.fitnessLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'is_online': isOnline,
      'last_activity': lastActivity.toIso8601String(),
      'total_distance': totalDistance,
      'total_workouts': totalWorkouts,
      'fitness_level': fitnessLevel,
    };
  }

  factory FitnessFriend.fromJson(Map<String, dynamic> json) {
    return FitnessFriend(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      isOnline: json['is_online'] as bool,
      lastActivity: DateTime.parse(json['last_activity'] as String),
      totalDistance: json['total_distance'] as double,
      totalWorkouts: json['total_workouts'] as int,
      fitnessLevel: json['fitness_level'] as String,
    );
  }
}

class FitnessComparison {
  final WorkoutAnalytics myStats;
  final WorkoutAnalytics friendStats;
  final Map<String, dynamic> comparison;

  const FitnessComparison({
    required this.myStats,
    required this.friendStats,
    required this.comparison,
  });

  double get distanceDifference => myStats.totalDistance - friendStats.totalDistance;
  double get durationDifference => myStats.totalDuration.inMinutes - friendStats.totalDuration.inMinutes;
  double get caloriesDifference => myStats.totalCalories - friendStats.totalCalories;
  double get fitnessScoreDifference => myStats.fitnessScore - friendStats.fitnessScore;

  bool get isLeading => fitnessScoreDifference > 0;
  bool get isTied => fitnessScoreDifference == 0;

  Map<String, dynamic> toJson() {
    return {
      'my_stats': myStats.toJson(),
      'friend_stats': friendStats.toJson(),
      'comparison': comparison,
    };
  }

  factory FitnessComparison.fromJson(Map<String, dynamic> json) {
    return FitnessComparison(
      myStats: WorkoutAnalytics.fromJson(json['my_stats']),
      friendStats: WorkoutAnalytics.fromJson(json['friend_stats']),
      comparison: Map<String, dynamic>.from(json['comparison']),
    );
  }
}

class FitnessMessage {
  final String id;
  final String senderId;
  final String recipientId;
  final String message;
  final DateTime timestamp;
  final MessageType type;
  final Map<String, dynamic>? data;

  const FitnessMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.message,
    required this.timestamp,
    required this.type,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'data': data,
    };
  }

  factory FitnessMessage.fromJson(Map<String, dynamic> json) {
    return FitnessMessage(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      recipientId: json['recipient_id'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: MessageType.values.firstWhere((e) => e.name == json['type']),
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

enum MessageType {
  motivation,
  challenge,
  achievement,
  general,
}
