// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: $enumDecode(_$AchievementCategoryEnumMap, json['category']),
      rarity: $enumDecode(_$AchievementRarityEnumMap, json['rarity']),
      icon: json['icon'] as String,
      points: (json['points'] as num).toInt(),
      requirements: Map<String, int>.from(json['requirements'] as Map),
      unlockedAt: json['unlockedAt'] == null
          ? null
          : DateTime.parse(json['unlockedAt'] as String),
      isUnlocked: json['isUnlocked'] as bool? ?? false,
    );

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': _$AchievementCategoryEnumMap[instance.category]!,
      'rarity': _$AchievementRarityEnumMap[instance.rarity]!,
      'icon': instance.icon,
      'points': instance.points,
      'requirements': instance.requirements,
      'unlockedAt': instance.unlockedAt?.toIso8601String(),
      'isUnlocked': instance.isUnlocked,
    };

const _$AchievementCategoryEnumMap = {
  AchievementCategory.battle: 'battle',
  AchievementCategory.quest: 'quest',
  AchievementCategory.collection: 'collection',
  AchievementCategory.fitness: 'fitness',
  AchievementCategory.social: 'social',
  AchievementCategory.exploration: 'exploration',
  AchievementCategory.special: 'special',
};

const _$AchievementRarityEnumMap = {
  AchievementRarity.common: 'common',
  AchievementRarity.rare: 'rare',
  AchievementRarity.epic: 'epic',
  AchievementRarity.legendary: 'legendary',
  AchievementRarity.mythic: 'mythic',
};

AchievementProgress _$AchievementProgressFromJson(Map<String, dynamic> json) =>
    AchievementProgress(
      achievementId: json['achievementId'] as String,
      currentProgress: Map<String, int>.from(json['currentProgress'] as Map),
      completionPercentage: (json['completionPercentage'] as num).toDouble(),
      isCompleted: json['isCompleted'] as bool,
    );

Map<String, dynamic> _$AchievementProgressToJson(
        AchievementProgress instance) =>
    <String, dynamic>{
      'achievementId': instance.achievementId,
      'currentProgress': instance.currentProgress,
      'completionPercentage': instance.completionPercentage,
      'isCompleted': instance.isCompleted,
    };

AchievementStats _$AchievementStatsFromJson(Map<String, dynamic> json) =>
    AchievementStats(
      totalAchievements: (json['totalAchievements'] as num).toInt(),
      unlockedAchievements: (json['unlockedAchievements'] as num).toInt(),
      totalPoints: (json['totalPoints'] as num).toInt(),
      categoryBreakdown:
          (json['categoryBreakdown'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            $enumDecode(_$AchievementCategoryEnumMap, k), (e as num).toInt()),
      ),
      rarityBreakdown: (json['rarityBreakdown'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            $enumDecode(_$AchievementRarityEnumMap, k), (e as num).toInt()),
      ),
    );

Map<String, dynamic> _$AchievementStatsToJson(AchievementStats instance) =>
    <String, dynamic>{
      'totalAchievements': instance.totalAchievements,
      'unlockedAchievements': instance.unlockedAchievements,
      'totalPoints': instance.totalPoints,
      'categoryBreakdown': instance.categoryBreakdown
          .map((k, e) => MapEntry(_$AchievementCategoryEnumMap[k]!, e)),
      'rarityBreakdown': instance.rarityBreakdown
          .map((k, e) => MapEntry(_$AchievementRarityEnumMap[k]!, e)),
    };
