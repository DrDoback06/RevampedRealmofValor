// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fitness_notifications.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FitnessReminder _$FitnessReminderFromJson(Map<String, dynamic> json) =>
    FitnessReminder(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      type: $enumDecode(_$ReminderTypeEnumMap, json['type']),
      isRepeating: json['isRepeating'] as bool,
      repeatDays: (json['repeatDays'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$FitnessReminderToJson(FitnessReminder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'message': instance.message,
      'scheduledTime': instance.scheduledTime.toIso8601String(),
      'type': _$ReminderTypeEnumMap[instance.type]!,
      'isRepeating': instance.isRepeating,
      'repeatDays': instance.repeatDays,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$ReminderTypeEnumMap = {
  ReminderType.workout: 'workout',
  ReminderType.goal: 'goal',
  ReminderType.challenge: 'challenge',
  ReminderType.social: 'social',
  ReminderType.achievement: 'achievement',
};

FitnessNotification _$FitnessNotificationFromJson(Map<String, dynamic> json) =>
    FitnessNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool,
    );

Map<String, dynamic> _$FitnessNotificationToJson(
        FitnessNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'message': instance.message,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'data': instance.data,
      'timestamp': instance.timestamp.toIso8601String(),
      'isRead': instance.isRead,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.achievement: 'achievement',
  NotificationType.goal: 'goal',
  NotificationType.challenge: 'challenge',
  NotificationType.social: 'social',
  NotificationType.reminder: 'reminder',
  NotificationType.system: 'system',
};
