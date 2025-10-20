import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quest_model.g.dart';

/// ENHANCED Quest Types with more granular categories
enum QuestType { 
  story,      // Main storyline
  daily,      // Daily quests
  weekly,     // Weekly quests
  location,   // Visit a location
  fitness,    // Complete fitness activity
  battle,     // Defeat enemies
  social,     // Interact with other players
  treasure,   // Find items
  boss,       // Boss encounters (NEW)
  trail,      // Complete trail routes (NEW)
  patrol,     // Defeat patrolling enemy (NEW)
  zone,       // Enter dynamic zone (NEW)
  achievement,// Long-term goals (NEW)
}

/// ENHANCED Quest Categories with boss/raid support
enum QuestCategory { 
  main,       // Main storyline
  adventure,  // Adventure quests
  side,       // Side quests
  epic,       // Epic/boss quests (NEW)
  repeatable, // Can be done multiple times (NEW)
  event,      // Time-limited events (NEW)
  pvp,        // Player vs player (NEW)
}

enum QuestStatus { notStarted, inProgress, completed, claimed, abandoned }

@JsonSerializable()
class QuestObjective extends Equatable {
  const QuestObjective({
    required this.id,
    required this.description,
    this.target = 1,
    this.progress = 0,
    this.type = 'general',
  });

  final String id;
  final String description;
  final int target;
  final int progress;
  final String type; // 'general', 'distance', 'steps', 'battle', 'location'

  factory QuestObjective.fromJson(Map<String, dynamic> json) => _$QuestObjectiveFromJson(json);
  Map<String, dynamic> toJson() => _$QuestObjectiveToJson(this);

  @override
  List<Object?> get props => [id, description, target, progress, type];
}

@JsonSerializable()
class QuestLocation extends Equatable {
  const QuestLocation({
    required this.latitude,
    required this.longitude,
    this.radius = 50, // meters
    this.name,
    this.address,
  });

  final double latitude;
  final double longitude;
  final double radius;
  final String? name;
  final String? address;

  factory QuestLocation.fromJson(Map<String, dynamic> json) => _$QuestLocationFromJson(json);
  Map<String, dynamic> toJson() => _$QuestLocationToJson(this);

  @override
  List<Object?> get props => [latitude, longitude, radius, name, address];
}

@JsonSerializable()
class QuestRewards extends Equatable {
  const QuestRewards({
    this.xp = 0,
    this.gold = 0,
    this.gems = 0,
    this.items = const <String>[],
    this.skillPoints = 0,
  });

  final int xp;
  final int gold;
  final int gems;
  final List<String> items;
  final int skillPoints;

  factory QuestRewards.fromJson(Map<String, dynamic> json) => _$QuestRewardsFromJson(json);
  Map<String, dynamic> toJson() => _$QuestRewardsToJson(this);

  @override
  List<Object?> get props => [xp, gold, gems, items, skillPoints];
}

@JsonSerializable()
class Quest extends Equatable {
  const Quest({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.status,
    this.description = '',
    this.objectives = const <QuestObjective>[],
    this.rewards = const QuestRewards(),
    this.location,
    this.timeLimit, // Duration in minutes
    this.prerequisites = const <String>[],
    this.tags = const <String>[],
    this.createdAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final QuestType type;
  final QuestCategory category;
  final QuestStatus status;
  final String description;
  final List<QuestObjective> objectives;
  final QuestRewards rewards;
  final QuestLocation? location;
  final int? timeLimit;
  final List<String> prerequisites;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? completedAt;

  factory Quest.fromJson(Map<String, dynamic> json) => _$QuestFromJson(json);
  Map<String, dynamic> toJson() => _$QuestToJson(this);

  @override
  List<Object?> get props => [
    id, title, type, category, status, description, objectives, 
    rewards, location, timeLimit, prerequisites, tags, createdAt, completedAt
  ];

  // Helper methods
  bool get isLocationBased => location != null;
  bool get isTimeLimited => timeLimit != null;
  bool get isCompleted => status == QuestStatus.completed;
  bool get isInProgress => status == QuestStatus.inProgress;
  
  double get progressPercentage {
    if (objectives.isEmpty) return 0.0;
    final totalProgress = objectives.fold<int>(0, (sum, obj) => sum + obj.progress);
    final totalTarget = objectives.fold<int>(0, (sum, obj) => sum + obj.target);
    return totalTarget > 0 ? totalProgress / totalTarget : 0.0;
  }
}
