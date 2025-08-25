import 'package:json_annotation/json_annotation.dart';

part 'achievement_model.g.dart';

enum AchievementCategory {
  battle,
  quest,
  collection,
  fitness,
  social,
  exploration,
  special,
}

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
  mythic,
}

@JsonSerializable()
class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final String icon;
  final int points;
  final Map<String, int> requirements;
  final DateTime? unlockedAt;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.icon,
    required this.points,
    required this.requirements,
    this.unlockedAt,
    this.isUnlocked = false,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementToJson(this);

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    AchievementCategory? category,
    AchievementRarity? rarity,
    String? icon,
    int? points,
    Map<String, int>? requirements,
    DateTime? unlockedAt,
    bool? isUnlocked,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      icon: icon ?? this.icon,
      points: points ?? this.points,
      requirements: requirements ?? this.requirements,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  Achievement unlock() {
    return copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );
  }

  String get rarityColor {
    switch (rarity) {
      case AchievementRarity.common:
        return '#9D9D9D';
      case AchievementRarity.rare:
        return '#0070DD';
      case AchievementRarity.epic:
        return '#A335EE';
      case AchievementRarity.legendary:
        return '#FF8000';
      case AchievementRarity.mythic:
        return '#E5CC80';
    }
  }

  String get categoryName {
    switch (category) {
      case AchievementCategory.battle:
        return 'Battle';
      case AchievementCategory.quest:
        return 'Quest';
      case AchievementCategory.collection:
        return 'Collection';
      case AchievementCategory.fitness:
        return 'Fitness';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.exploration:
        return 'Exploration';
      case AchievementCategory.special:
        return 'Special';
    }
  }
}

@JsonSerializable()
class AchievementProgress {
  final String achievementId;
  final Map<String, int> currentProgress;
  final double completionPercentage;
  final bool isCompleted;

  AchievementProgress({
    required this.achievementId,
    required this.currentProgress,
    required this.completionPercentage,
    required this.isCompleted,
  });

  factory AchievementProgress.fromJson(Map<String, dynamic> json) => _$AchievementProgressFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementProgressToJson(this);
}

@JsonSerializable()
class AchievementStats {
  final int totalAchievements;
  final int unlockedAchievements;
  final int totalPoints;
  final Map<AchievementCategory, int> categoryBreakdown;
  final Map<AchievementRarity, int> rarityBreakdown;

  AchievementStats({
    required this.totalAchievements,
    required this.unlockedAchievements,
    required this.totalPoints,
    required this.categoryBreakdown,
    required this.rarityBreakdown,
  });

  factory AchievementStats.fromJson(Map<String, dynamic> json) => _$AchievementStatsFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementStatsToJson(this);

  double get completionPercentage => totalAchievements > 0 ? unlockedAchievements / totalAchievements : 0.0;
}
