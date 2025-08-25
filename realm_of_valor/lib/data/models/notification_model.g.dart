// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameNotification _$GameNotificationFromJson(Map<String, dynamic> json) =>
    GameNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      priority: $enumDecodeNullable(
              _$NotificationPriorityEnumMap, json['priority']) ??
          NotificationPriority.normal,
      status:
          $enumDecodeNullable(_$NotificationStatusEnumMap, json['status']) ??
              NotificationStatus.unread,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
      dismissedAt: json['dismissedAt'] == null
          ? null
          : DateTime.parse(json['dismissedAt'] as String),
      actionedAt: json['actionedAt'] == null
          ? null
          : DateTime.parse(json['actionedAt'] as String),
      data: json['data'] as Map<String, dynamic>?,
      actionUrl: json['actionUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isPersistent: json['isPersistent'] as bool? ?? false,
      expiresAt: (json['expiresAt'] as num?)?.toInt(),
    );

Map<String, dynamic> _$GameNotificationToJson(GameNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'message': instance.message,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'priority': _$NotificationPriorityEnumMap[instance.priority]!,
      'status': _$NotificationStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'readAt': instance.readAt?.toIso8601String(),
      'dismissedAt': instance.dismissedAt?.toIso8601String(),
      'actionedAt': instance.actionedAt?.toIso8601String(),
      'data': instance.data,
      'actionUrl': instance.actionUrl,
      'imageUrl': instance.imageUrl,
      'isPersistent': instance.isPersistent,
      'expiresAt': instance.expiresAt,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.quest: 'quest',
  NotificationType.battle: 'battle',
  NotificationType.achievement: 'achievement',
  NotificationType.event: 'event',
  NotificationType.social: 'social',
  NotificationType.fitness: 'fitness',
  NotificationType.weather: 'weather',
  NotificationType.system: 'system',
  NotificationType.reward: 'reward',
  NotificationType.reminder: 'reminder',
};

const _$NotificationPriorityEnumMap = {
  NotificationPriority.low: 'low',
  NotificationPriority.normal: 'normal',
  NotificationPriority.high: 'high',
  NotificationPriority.urgent: 'urgent',
};

const _$NotificationStatusEnumMap = {
  NotificationStatus.unread: 'unread',
  NotificationStatus.read: 'read',
  NotificationStatus.dismissed: 'dismissed',
  NotificationStatus.actioned: 'actioned',
};

NotificationSettings _$NotificationSettingsFromJson(
        Map<String, dynamic> json) =>
    NotificationSettings(
      questNotifications: json['questNotifications'] as bool? ?? true,
      battleNotifications: json['battleNotifications'] as bool? ?? true,
      achievementNotifications:
          json['achievementNotifications'] as bool? ?? true,
      eventNotifications: json['eventNotifications'] as bool? ?? true,
      socialNotifications: json['socialNotifications'] as bool? ?? true,
      fitnessNotifications: json['fitnessNotifications'] as bool? ?? true,
      weatherNotifications: json['weatherNotifications'] as bool? ?? true,
      systemNotifications: json['systemNotifications'] as bool? ?? true,
      rewardNotifications: json['rewardNotifications'] as bool? ?? true,
      reminderNotifications: json['reminderNotifications'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      pushNotificationsEnabled:
          json['pushNotificationsEnabled'] as bool? ?? true,
      mutedUsers: (json['mutedUsers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      typeSettings: (json['typeSettings'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry($enumDecode(_$NotificationTypeEnumMap, k), e as bool),
          ) ??
          const {},
    );

Map<String, dynamic> _$NotificationSettingsToJson(
        NotificationSettings instance) =>
    <String, dynamic>{
      'questNotifications': instance.questNotifications,
      'battleNotifications': instance.battleNotifications,
      'achievementNotifications': instance.achievementNotifications,
      'eventNotifications': instance.eventNotifications,
      'socialNotifications': instance.socialNotifications,
      'fitnessNotifications': instance.fitnessNotifications,
      'weatherNotifications': instance.weatherNotifications,
      'systemNotifications': instance.systemNotifications,
      'rewardNotifications': instance.rewardNotifications,
      'reminderNotifications': instance.reminderNotifications,
      'soundEnabled': instance.soundEnabled,
      'vibrationEnabled': instance.vibrationEnabled,
      'pushNotificationsEnabled': instance.pushNotificationsEnabled,
      'mutedUsers': instance.mutedUsers,
      'typeSettings': instance.typeSettings
          .map((k, e) => MapEntry(_$NotificationTypeEnumMap[k]!, e)),
    };

NotificationTemplate _$NotificationTemplateFromJson(
        Map<String, dynamic> json) =>
    NotificationTemplate(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      priority: $enumDecodeNullable(
              _$NotificationPriorityEnumMap, json['priority']) ??
          NotificationPriority.normal,
      defaultData: json['defaultData'] as Map<String, dynamic>?,
      defaultActionUrl: json['defaultActionUrl'] as String?,
      defaultImageUrl: json['defaultImageUrl'] as String?,
      isPersistent: json['isPersistent'] as bool? ?? false,
      defaultExpiresAt: (json['defaultExpiresAt'] as num?)?.toInt(),
    );

Map<String, dynamic> _$NotificationTemplateToJson(
        NotificationTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'message': instance.message,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'priority': _$NotificationPriorityEnumMap[instance.priority]!,
      'defaultData': instance.defaultData,
      'defaultActionUrl': instance.defaultActionUrl,
      'defaultImageUrl': instance.defaultImageUrl,
      'isPersistent': instance.isPersistent,
      'defaultExpiresAt': instance.defaultExpiresAt,
    };
