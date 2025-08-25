import 'package:json_annotation/json_annotation.dart';

part 'event_model.g.dart';

enum EventType {
  battle,
  quest,
  social,
  fitness,
  achievement,
  weather,
  seasonal,
  special,
}

enum EventStatus {
  upcoming,
  active,
  completed,
  cancelled,
}

enum EventDifficulty {
  easy,
  medium,
  hard,
  extreme,
}

@JsonSerializable()
class GameEvent {
  final String id;
  final String name;
  final String description;
  final EventType type;
  final EventStatus status;
  final EventDifficulty difficulty;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final double? latitude;
  final double? longitude;
  final int? radius;
  final Map<String, dynamic>? requirements;
  final Map<String, dynamic>? rewards;
  final List<String>? participants;
  final int maxParticipants;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final bool isRepeatable;
  final int? cooldownHours;

  GameEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.difficulty,
    required this.startTime,
    required this.endTime,
    this.location,
    this.latitude,
    this.longitude,
    this.radius,
    this.requirements,
    this.rewards,
    this.participants,
    this.maxParticipants = 100,
    this.imageUrl,
    this.metadata,
    this.isRepeatable = false,
    this.cooldownHours,
  });

  factory GameEvent.fromJson(Map<String, dynamic> json) => _$GameEventFromJson(json);
  Map<String, dynamic> toJson() => _$GameEventToJson(this);

  GameEvent copyWith({
    String? id,
    String? name,
    String? description,
    EventType? type,
    EventStatus? status,
    EventDifficulty? difficulty,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    double? latitude,
    double? longitude,
    int? radius,
    Map<String, dynamic>? requirements,
    Map<String, dynamic>? rewards,
    List<String>? participants,
    int? maxParticipants,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    bool? isRepeatable,
    int? cooldownHours,
  }) {
    return GameEvent(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      requirements: requirements ?? this.requirements,
      rewards: rewards ?? this.rewards,
      participants: participants ?? this.participants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
      isRepeatable: isRepeatable ?? this.isRepeatable,
      cooldownHours: cooldownHours ?? this.cooldownHours,
    );
  }

  bool get isActive => status == EventStatus.active;
  bool get isUpcoming => status == EventStatus.upcoming;
  bool get isCompleted => status == EventStatus.completed;
  bool get isCancelled => status == EventStatus.cancelled;
  bool get isLocationBased => latitude != null && longitude != null;
  bool get hasSpace => participants == null || participants!.length < maxParticipants;
  bool get isFull => participants != null && participants!.length >= maxParticipants;

  Duration get duration => endTime.difference(startTime);
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  String get difficultyColor {
    switch (difficulty) {
      case EventDifficulty.easy:
        return '#4CAF50';
      case EventDifficulty.medium:
        return '#FF9800';
      case EventDifficulty.hard:
        return '#F44336';
      case EventDifficulty.extreme:
        return '#9C27B0';
    }
  }

  String get typeIcon {
    switch (type) {
      case EventType.battle:
        return '⚔️';
      case EventType.quest:
        return '📜';
      case EventType.social:
        return '👥';
      case EventType.fitness:
        return '💪';
      case EventType.achievement:
        return '🏆';
      case EventType.weather:
        return '🌤️';
      case EventType.seasonal:
        return '🎄';
      case EventType.special:
        return '⭐';
    }
  }
}

@JsonSerializable()
class EventParticipation {
  final String eventId;
  final String userId;
  final DateTime joinedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? progress;
  final Map<String, dynamic>? rewards;
  final bool isCompleted;

  EventParticipation({
    required this.eventId,
    required this.userId,
    required this.joinedAt,
    this.completedAt,
    this.progress,
    this.rewards,
    this.isCompleted = false,
  });

  factory EventParticipation.fromJson(Map<String, dynamic> json) => _$EventParticipationFromJson(json);
  Map<String, dynamic> toJson() => _$EventParticipationToJson(this);

  EventParticipation copyWith({
    String? eventId,
    String? userId,
    DateTime? joinedAt,
    DateTime? completedAt,
    Map<String, dynamic>? progress,
    Map<String, dynamic>? rewards,
    bool? isCompleted,
  }) {
    return EventParticipation(
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      joinedAt: joinedAt ?? this.joinedAt,
      completedAt: completedAt ?? this.completedAt,
      progress: progress ?? this.progress,
      rewards: rewards ?? this.rewards,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

@JsonSerializable()
class EventLeaderboard {
  final String eventId;
  final List<EventLeaderboardEntry> entries;
  final DateTime lastUpdated;

  EventLeaderboard({
    required this.eventId,
    required this.entries,
    required this.lastUpdated,
  });

  factory EventLeaderboard.fromJson(Map<String, dynamic> json) => _$EventLeaderboardFromJson(json);
  Map<String, dynamic> toJson() => _$EventLeaderboardToJson(this);

  List<EventLeaderboardEntry> get topEntries => entries.take(10).toList();
}

@JsonSerializable()
class EventLeaderboardEntry {
  final String userId;
  final String username;
  final int score;
  final int rank;
  final Map<String, dynamic>? metadata;

  EventLeaderboardEntry({
    required this.userId,
    required this.username,
    required this.score,
    required this.rank,
    this.metadata,
  });

  factory EventLeaderboardEntry.fromJson(Map<String, dynamic> json) => _$EventLeaderboardEntryFromJson(json);
  Map<String, dynamic> toJson() => _$EventLeaderboardEntryToJson(this);
}
