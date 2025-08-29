// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fitness_game_integration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FitnessGameRewards _$FitnessGameRewardsFromJson(Map<String, dynamic> json) =>
    FitnessGameRewards(
      xp: (json['xp'] as num).toInt(),
      gold: (json['gold'] as num).toInt(),
      cards: (json['cards'] as num).toInt(),
      unlockedAchievements: (json['unlockedAchievements'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      activeBuffs: (json['activeBuffs'] as List<dynamic>)
          .map((e) => FitnessBuff.fromJson(e as Map<String, dynamic>))
          .toList(),
      period: DateRange.fromJson(json['period'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FitnessGameRewardsToJson(FitnessGameRewards instance) =>
    <String, dynamic>{
      'xp': instance.xp,
      'gold': instance.gold,
      'cards': instance.cards,
      'unlockedAchievements': instance.unlockedAchievements,
      'activeBuffs': instance.activeBuffs,
      'period': instance.period,
    };

FitnessBuff _$FitnessBuffFromJson(Map<String, dynamic> json) => FitnessBuff(
      id: json['id'] as String,
      type: $enumDecode(_$BuffTypeEnumMap, json['type']),
      value: (json['value'] as num).toDouble(),
      duration: Duration(microseconds: (json['duration'] as num).toInt()),
      description: json['description'] as String,
      appliedAt: DateTime.parse(json['appliedAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$FitnessBuffToJson(FitnessBuff instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$BuffTypeEnumMap[instance.type]!,
      'value': instance.value,
      'duration': instance.duration.inMicroseconds,
      'description': instance.description,
      'appliedAt': instance.appliedAt.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
    };

const _$BuffTypeEnumMap = {
  BuffType.strength: 'strength',
  BuffType.agility: 'agility',
  BuffType.vitality: 'vitality',
  BuffType.intelligence: 'intelligence',
  BuffType.xpBonus: 'xpBonus',
};

FitnessAchievement _$FitnessAchievementFromJson(Map<String, dynamic> json) =>
    FitnessAchievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$AchievementTypeEnumMap, json['type']),
      rewardXP: (json['rewardXP'] as num).toInt(),
      rewardGold: (json['rewardGold'] as num).toInt(),
      isUnlocked: json['isUnlocked'] as bool,
      unlockedAt: json['unlockedAt'] == null
          ? null
          : DateTime.parse(json['unlockedAt'] as String),
      iconPath: json['iconPath'] as String?,
    );

Map<String, dynamic> _$FitnessAchievementToJson(FitnessAchievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$AchievementTypeEnumMap[instance.type]!,
      'rewardXP': instance.rewardXP,
      'rewardGold': instance.rewardGold,
      'isUnlocked': instance.isUnlocked,
      'unlockedAt': instance.unlockedAt?.toIso8601String(),
      'iconPath': instance.iconPath,
    };

const _$AchievementTypeEnumMap = {
  AchievementType.goalProgress: 'goalProgress',
  AchievementType.streak: 'streak',
  AchievementType.personalRecord: 'personalRecord',
  AchievementType.challenge: 'challenge',
  AchievementType.social: 'social',
  AchievementType.milestone: 'milestone',
};

FitnessQuest _$FitnessQuestFromJson(Map<String, dynamic> json) => FitnessQuest(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$QuestTypeEnumMap, json['type']),
      target: (json['target'] as num).toDouble(),
      current: (json['current'] as num).toDouble(),
      rewardXP: (json['rewardXP'] as num).toInt(),
      rewardGold: (json['rewardGold'] as num).toInt(),
      deadline: DateTime.parse(json['deadline'] as String),
      isCompleted: json['isCompleted'] as bool,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$FitnessQuestToJson(FitnessQuest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$QuestTypeEnumMap[instance.type]!,
      'target': instance.target,
      'current': instance.current,
      'rewardXP': instance.rewardXP,
      'rewardGold': instance.rewardGold,
      'deadline': instance.deadline.toIso8601String(),
      'isCompleted': instance.isCompleted,
      'completedAt': instance.completedAt?.toIso8601String(),
    };

const _$QuestTypeEnumMap = {
  QuestType.distance: 'distance',
  QuestType.duration: 'duration',
  QuestType.calories: 'calories',
  QuestType.streak: 'streak',
  QuestType.variety: 'variety',
  QuestType.personalRecord: 'personalRecord',
};

GameStats _$GameStatsFromJson(Map<String, dynamic> json) => GameStats(
      strength: (json['strength'] as num).toInt(),
      agility: (json['agility'] as num).toInt(),
      vitality: (json['vitality'] as num).toInt(),
      intelligence: (json['intelligence'] as num).toInt(),
      xpBonus: (json['xpBonus'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      experience: (json['experience'] as num).toInt(),
    );

Map<String, dynamic> _$GameStatsToJson(GameStats instance) => <String, dynamic>{
      'strength': instance.strength,
      'agility': instance.agility,
      'vitality': instance.vitality,
      'intelligence': instance.intelligence,
      'xpBonus': instance.xpBonus,
      'level': instance.level,
      'experience': instance.experience,
    };
