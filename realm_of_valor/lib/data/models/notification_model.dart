import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'notification_model.g.dart';

enum NotificationType {
  quest,
  battle,
  achievement,
  event,
  social,
  fitness,
  weather,
  system,
  reward,
  reminder,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

enum NotificationStatus {
  unread,
  read,
  dismissed,
  actioned,
}

@JsonSerializable()
class GameNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? dismissedAt;
  final DateTime? actionedAt;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final String? imageUrl;
  final bool isPersistent;
  final int? expiresAt;

  GameNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.status = NotificationStatus.unread,
    required this.createdAt,
    this.readAt,
    this.dismissedAt,
    this.actionedAt,
    this.data,
    this.actionUrl,
    this.imageUrl,
    this.isPersistent = false,
    this.expiresAt,
  });

  factory GameNotification.fromJson(Map<String, dynamic> json) => _$GameNotificationFromJson(json);
  Map<String, dynamic> toJson() => _$GameNotificationToJson(this);

  GameNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    NotificationStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? dismissedAt,
    DateTime? actionedAt,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
    bool? isPersistent,
    int? expiresAt,
  }) {
    return GameNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      actionedAt: actionedAt ?? this.actionedAt,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      isPersistent: isPersistent ?? this.isPersistent,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isUnread => status == NotificationStatus.unread;
  bool get isRead => status == NotificationStatus.read;
  bool get isDismissed => status == NotificationStatus.dismissed;
  bool get isActioned => status == NotificationStatus.actioned;
  bool get isExpired => expiresAt != null && DateTime.now().millisecondsSinceEpoch > expiresAt!;

  String get typeIcon {
    switch (type) {
      case NotificationType.quest:
        return '📜';
      case NotificationType.battle:
        return '⚔️';
      case NotificationType.achievement:
        return '🏆';
      case NotificationType.event:
        return '🎉';
      case NotificationType.social:
        return '👥';
      case NotificationType.fitness:
        return '💪';
      case NotificationType.weather:
        return '🌤️';
      case NotificationType.system:
        return '⚙️';
      case NotificationType.reward:
        return '💰';
      case NotificationType.reminder:
        return '⏰';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }

  GameNotification markAsRead() {
    return copyWith(
      status: NotificationStatus.read,
      readAt: DateTime.now(),
    );
  }

  GameNotification dismiss() {
    return copyWith(
      status: NotificationStatus.dismissed,
      dismissedAt: DateTime.now(),
    );
  }

  GameNotification action() {
    return copyWith(
      status: NotificationStatus.actioned,
      actionedAt: DateTime.now(),
    );
  }
}

@JsonSerializable()
class NotificationSettings {
  final bool questNotifications;
  final bool battleNotifications;
  final bool achievementNotifications;
  final bool eventNotifications;
  final bool socialNotifications;
  final bool fitnessNotifications;
  final bool weatherNotifications;
  final bool systemNotifications;
  final bool rewardNotifications;
  final bool reminderNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool pushNotificationsEnabled;
  final List<String> mutedUsers;
  final Map<NotificationType, bool> typeSettings;

  NotificationSettings({
    this.questNotifications = true,
    this.battleNotifications = true,
    this.achievementNotifications = true,
    this.eventNotifications = true,
    this.socialNotifications = true,
    this.fitnessNotifications = true,
    this.weatherNotifications = true,
    this.systemNotifications = true,
    this.rewardNotifications = true,
    this.reminderNotifications = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.pushNotificationsEnabled = true,
    this.mutedUsers = const [],
    this.typeSettings = const {},
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) => _$NotificationSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationSettingsToJson(this);

  NotificationSettings copyWith({
    bool? questNotifications,
    bool? battleNotifications,
    bool? achievementNotifications,
    bool? eventNotifications,
    bool? socialNotifications,
    bool? fitnessNotifications,
    bool? weatherNotifications,
    bool? systemNotifications,
    bool? rewardNotifications,
    bool? reminderNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? pushNotificationsEnabled,
    List<String>? mutedUsers,
    Map<NotificationType, bool>? typeSettings,
  }) {
    return NotificationSettings(
      questNotifications: questNotifications ?? this.questNotifications,
      battleNotifications: battleNotifications ?? this.battleNotifications,
      achievementNotifications: achievementNotifications ?? this.achievementNotifications,
      eventNotifications: eventNotifications ?? this.eventNotifications,
      socialNotifications: socialNotifications ?? this.socialNotifications,
      fitnessNotifications: fitnessNotifications ?? this.fitnessNotifications,
      weatherNotifications: weatherNotifications ?? this.weatherNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      rewardNotifications: rewardNotifications ?? this.rewardNotifications,
      reminderNotifications: reminderNotifications ?? this.reminderNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      mutedUsers: mutedUsers ?? this.mutedUsers,
      typeSettings: typeSettings ?? this.typeSettings,
    );
  }

  bool isNotificationTypeEnabled(NotificationType type) {
    return typeSettings[type] ?? _getDefaultSettingForType(type);
  }

  bool _getDefaultSettingForType(NotificationType type) {
    switch (type) {
      case NotificationType.quest:
        return questNotifications;
      case NotificationType.battle:
        return battleNotifications;
      case NotificationType.achievement:
        return achievementNotifications;
      case NotificationType.event:
        return eventNotifications;
      case NotificationType.social:
        return socialNotifications;
      case NotificationType.fitness:
        return fitnessNotifications;
      case NotificationType.weather:
        return weatherNotifications;
      case NotificationType.system:
        return systemNotifications;
      case NotificationType.reward:
        return rewardNotifications;
      case NotificationType.reminder:
        return reminderNotifications;
    }
  }
}

@JsonSerializable()
class NotificationTemplate {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final Map<String, dynamic>? defaultData;
  final String? defaultActionUrl;
  final String? defaultImageUrl;
  final bool isPersistent;
  final int? defaultExpiresAt;

  NotificationTemplate({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.defaultData,
    this.defaultActionUrl,
    this.defaultImageUrl,
    this.isPersistent = false,
    this.defaultExpiresAt,
  });

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) => _$NotificationTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationTemplateToJson(this);

  GameNotification createNotification({
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
    int? expiresAt,
  }) {
    return GameNotification(
      id: '${id}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: type,
      priority: priority,
      createdAt: DateTime.now(),
      data: data ?? defaultData,
      actionUrl: actionUrl ?? defaultActionUrl,
      imageUrl: imageUrl ?? defaultImageUrl,
      isPersistent: isPersistent,
      expiresAt: expiresAt ?? defaultExpiresAt,
    );
  }
}
