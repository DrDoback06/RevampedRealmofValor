enum GoalType {
  distance,
  duration,
  calories,
  workouts,
}

enum ChallengeType {
  distance,
  duration,
  calories,
  workouts,
  elevation,
}

class FitnessGoal {
  final String id;
  final String name;
  final String description;
  final GoalType type;
  final double target;
  double current;
  final Duration duration;
  final DateTime startDate;
  final DateTime endDate;
  final int rewardXP;
  final int rewardGold;
  bool isCompleted;
  DateTime? completionDate;

  FitnessGoal({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.target,
    required this.current,
    required this.duration,
    required this.startDate,
    required this.endDate,
    required this.rewardXP,
    required this.rewardGold,
    required this.isCompleted,
    this.completionDate,
  });

  double get progressPercentage => (current / target * 100).clamp(0, 100);
  bool get isExpired => DateTime.now().isAfter(endDate);
  Duration get timeRemaining => endDate.difference(DateTime.now());
  bool get isActive => !isCompleted && !isExpired;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'target': target,
      'current': current,
      'duration': duration.inSeconds,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'reward_xp': rewardXP,
      'reward_gold': rewardGold,
      'is_completed': isCompleted,
      'completion_date': completionDate?.toIso8601String(),
    };
  }

  factory FitnessGoal.fromJson(Map<String, dynamic> json) {
    return FitnessGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: GoalType.values.firstWhere((e) => e.name == json['type']),
      target: json['target'] as double,
      current: json['current'] as double,
      duration: Duration(seconds: json['duration'] as int),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      rewardXP: json['reward_xp'] as int,
      rewardGold: json['reward_gold'] as int,
      isCompleted: json['is_completed'] as bool,
      completionDate: json['completion_date'] != null 
          ? DateTime.parse(json['completion_date'] as String)
          : null,
    );
  }
}

class GoalProgress {
  final String goalId;
  final double current;
  final double percentage;
  final bool isCompleted;

  const GoalProgress({
    required this.goalId,
    required this.current,
    required this.percentage,
    required this.isCompleted,
  });
}

class FitnessChallenge {
  final String id;
  final String name;
  final String description;
  final ChallengeType type;
  final double target;
  final Duration duration;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> participants;
  final Map<String, double> leaderboard;
  final int rewardXP;
  final int rewardGold;
  bool isCompleted;
  DateTime? completionDate;
  String? winner;

  FitnessChallenge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.target,
    required this.duration,
    required this.startDate,
    required this.endDate,
    required this.participants,
    required this.leaderboard,
    required this.rewardXP,
    required this.rewardGold,
    required this.isCompleted,
    this.completionDate,
    this.winner,
  });

  bool get isExpired => DateTime.now().isAfter(endDate);
  Duration get timeRemaining => endDate.difference(DateTime.now());
  bool get isActive => !isCompleted && !isExpired;
  
  List<MapEntry<String, double>> get sortedLeaderboard {
    final sorted = leaderboard.entries.toList();
    sorted.sort((a, b) => b.value.compareTo(a.value));
    return sorted;
  }
  
  String? get currentLeader {
    if (leaderboard.isEmpty) return null;
    return sortedLeaderboard.first.key;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'target': target,
      'duration': duration.inSeconds,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'participants': participants,
      'leaderboard': leaderboard,
      'reward_xp': rewardXP,
      'reward_gold': rewardGold,
      'is_completed': isCompleted,
      'completion_date': completionDate?.toIso8601String(),
      'winner': winner,
    };
  }

  factory FitnessChallenge.fromJson(Map<String, dynamic> json) {
    return FitnessChallenge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: ChallengeType.values.firstWhere((e) => e.name == json['type']),
      target: json['target'] as double,
      duration: Duration(seconds: json['duration'] as int),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      participants: List<String>.from(json['participants']),
      leaderboard: Map<String, double>.from(json['leaderboard']),
      rewardXP: json['reward_xp'] as int,
      rewardGold: json['reward_gold'] as int,
      isCompleted: json['is_completed'] as bool,
      completionDate: json['completion_date'] != null 
          ? DateTime.parse(json['completion_date'] as String)
          : null,
      winner: json['winner'] as String?,
    );
  }
}
