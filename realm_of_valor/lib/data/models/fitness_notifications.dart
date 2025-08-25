import 'package:json_annotation/json_annotation.dart';

part 'fitness_notifications.g.dart';

enum ReminderType {
  workout,
  goal,
  challenge,
  social,
  achievement,
}

enum NotificationType {
  achievement,
  goal,
  challenge,
  social,
  reminder,
  system,
}

enum AchievementType {
  goalProgress,
  streak,
  personalRecord,
  challenge,
  social,
  milestone,
}

@JsonSerializable()
class FitnessReminder {
  final String id;
  final String title;
  final String message;
  final DateTime scheduledTime;
  final ReminderType type;
  final bool isRepeating;
  final List<int> repeatDays; // 1-7 for days of week
  final bool isActive;
  final DateTime createdAt;

  FitnessReminder({
    required this.id,
    required this.title,
    required this.message,
    required this.scheduledTime,
    required this.type,
    required this.isRepeating,
    required this.repeatDays,
    required this.isActive,
    required this.createdAt,
  });

  factory FitnessReminder.fromJson(Map<String, dynamic> json) =>
      _$FitnessReminderFromJson(json);

  Map<String, dynamic> toJson() => _$FitnessReminderToJson(this);

  FitnessReminder copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? scheduledTime,
    ReminderType? type,
    bool? isRepeating,
    List<int>? repeatDays,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return FitnessReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      type: type ?? this.type,
      isRepeating: isRepeating ?? this.isRepeating,
      repeatDays: repeatDays ?? this.repeatDays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

@JsonSerializable()
class FitnessNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;

  FitnessNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.data,
    required this.timestamp,
    required this.isRead,
  });

  factory FitnessNotification.fromJson(Map<String, dynamic> json) =>
      _$FitnessNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$FitnessNotificationToJson(this);

  FitnessNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return FitnessNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}