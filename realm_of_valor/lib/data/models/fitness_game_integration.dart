import 'package:json_annotation/json_annotation.dart';
import 'fitness_notifications.dart';
import 'performance_tracking.dart';

part 'fitness_game_integration.g.dart';

enum BuffType {
  strength,
  agility,
  vitality,
  intelligence,
  xpBonus,
}

enum QuestType {
  distance,
  duration,
  calories,
  streak,
  variety,
  personalRecord,
}

@JsonSerializable()
class FitnessGameRewards {
  final int xp;
  final int gold;
  final int cards;
  final List<String> unlockedAchievements;
  final List<FitnessBuff> activeBuffs;
  final DateRange period;

  FitnessGameRewards({
    required this.xp,
    required this.gold,
    required this.cards,
    required this.unlockedAchievements,
    required this.activeBuffs,
    required this.period,
  });

  factory FitnessGameRewards.fromJson(Map<String, dynamic> json) =>
      _$FitnessGameRewardsFromJson(json);

  Map<String, dynamic> toJson() => _$FitnessGameRewardsToJson(this);

  factory FitnessGameRewards.empty() {
    return FitnessGameRewards(
      xp: 0,
      gold: 0,
      cards: 0,
      unlockedAchievements: [],
      activeBuffs: [],
      period: DateRange(
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      ),
    );
  }
}

@JsonSerializable()
class FitnessBuff {
  final String id;
  final BuffType type;
  final double value; // Percentage or flat value
  final Duration duration;
  final String description;
  final DateTime appliedAt;
  final DateTime? expiresAt;

  FitnessBuff({
    required this.id,
    required this.type,
    required this.value,
    required this.duration,
    required this.description,
    required this.appliedAt,
    this.expiresAt,
  });

  factory FitnessBuff.fromJson(Map<String, dynamic> json) =>
      _$FitnessBuffFromJson(json);

  Map<String, dynamic> toJson() => _$FitnessBuffToJson(this);

  FitnessBuff copyWith({
    String? id,
    BuffType? type,
    double? value,
    Duration? duration,
    String? description,
    DateTime? appliedAt,
    DateTime? expiresAt,
  }) {
    return FitnessBuff(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      appliedAt: appliedAt ?? this.appliedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isActive => expiresAt == null || DateTime.now().isBefore(expiresAt!);
  Duration get timeRemaining => expiresAt != null 
      ? expiresAt!.difference(DateTime.now())
      : const Duration(seconds: 0);
}

@JsonSerializable()
class FitnessAchievement {
  final String id;
  final String name;
  final String description;
  final AchievementType type;
  final int rewardXP;
  final int rewardGold;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String? iconPath;

  FitnessAchievement({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rewardXP,
    required this.rewardGold,
    required this.isUnlocked,
    this.unlockedAt,
    this.iconPath,
  });

  factory FitnessAchievement.fromJson(Map<String, dynamic> json) =>
      _$FitnessAchievementFromJson(json);

  Map<String, dynamic> toJson() => _$FitnessAchievementToJson(this);

  FitnessAchievement copyWith({
    String? id,
    String? name,
    String? description,
    AchievementType? type,
    int? rewardXP,
    int? rewardGold,
    bool? isUnlocked,
    DateTime? unlockedAt,
    String? iconPath,
  }) {
    return FitnessAchievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      rewardXP: rewardXP ?? this.rewardXP,
      rewardGold: rewardGold ?? this.rewardGold,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      iconPath: iconPath ?? this.iconPath,
    );
  }
}

@JsonSerializable()
class FitnessQuest {
  final String id;
  final String name;
  final String description;
  final QuestType type;
  final double target;
  final double current;
  final int rewardXP;
  final int rewardGold;
  final DateTime deadline;
  final bool isCompleted;
  final DateTime? completedAt;

  FitnessQuest({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.target,
    required this.current,
    required this.rewardXP,
    required this.rewardGold,
    required this.deadline,
    required this.isCompleted,
    this.completedAt,
  });

  factory FitnessQuest.fromJson(Map<String, dynamic> json) =>
      _$FitnessQuestFromJson(json);

  Map<String, dynamic> toJson() => _$FitnessQuestToJson(this);

  FitnessQuest copyWith({
    String? id,
    String? name,
    String? description,
    QuestType? type,
    double? target,
    double? current,
    int? rewardXP,
    int? rewardGold,
    DateTime? deadline,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return FitnessQuest(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      target: target ?? this.target,
      current: current ?? this.current,
      rewardXP: rewardXP ?? this.rewardXP,
      rewardGold: rewardGold ?? this.rewardGold,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  double get progressPercentage => (current / target) * 100;
  bool get isExpired => DateTime.now().isAfter(deadline);
  int get daysRemaining => deadline.difference(DateTime.now()).inDays;
  bool get isOnTrack => progressPercentage >= (daysRemaining / deadline.difference(DateTime.now().subtract(const Duration(days: 30))).inDays) * 100;
}

@JsonSerializable()
class GameStats {
  final int strength;
  final int agility;
  final int vitality;
  final int intelligence;
  final int xpBonus;
  final int level;
  final int experience;

  GameStats({
    required this.strength,
    required this.agility,
    required this.vitality,
    required this.intelligence,
    required this.xpBonus,
    required this.level,
    required this.experience,
  });

  factory GameStats.fromJson(Map<String, dynamic> json) =>
      _$GameStatsFromJson(json);

  Map<String, dynamic> toJson() => _$GameStatsToJson(this);

  GameStats copyWith({
    int? strength,
    int? agility,
    int? vitality,
    int? intelligence,
    int? xpBonus,
    int? level,
    int? experience,
  }) {
    return GameStats(
      strength: strength ?? this.strength,
      agility: agility ?? this.agility,
      vitality: vitality ?? this.vitality,
      intelligence: intelligence ?? this.intelligence,
      xpBonus: xpBonus ?? this.xpBonus,
      level: level ?? this.level,
      experience: experience ?? this.experience,
    );
  }

  int get totalStats => strength + agility + vitality + intelligence;
  double get averageStats => totalStats / 4.0;
}
