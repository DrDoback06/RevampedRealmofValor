import 'dart:async';
import '../../../data/models/quest_model.dart';
import '../../../data/models/character_model.dart';

class QuestNotificationService {
  static final QuestNotificationService _instance = QuestNotificationService._internal();
  factory QuestNotificationService() => _instance;
  QuestNotificationService._internal();

  final List<QuestNotification> _notifications = [];
  final Map<String, Timer> _reminderTimers = {};
  final List<NotificationListener> _listeners = [];

  /// Schedule a quest reminder
  void scheduleQuestReminder({
    required Quest quest,
    required Character player,
    required Duration delay,
    String? customMessage,
  }) {
    final timer = Timer(delay, () {
      _sendQuestReminder(quest, player, customMessage);
    });
    
    _reminderTimers['${quest.id}_${player.id}'] = timer;
  }

  /// Cancel a quest reminder
  void cancelQuestReminder(String questId, String playerId) {
    final timerKey = '${questId}_${playerId}';
    final timer = _reminderTimers[timerKey];
    timer?.cancel();
    _reminderTimers.remove(timerKey);
  }

  /// Send a quest completion notification
  void sendQuestCompletionNotification({
    required Quest quest,
    required Character player,
    required QuestRewards rewards,
  }) {
    final notification = QuestNotification(
      id: 'completion_${quest.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.questCompleted,
      title: 'Quest Completed!',
      message: 'Congratulations! You completed "${quest.title}" and earned ${rewards.xp} XP and ${rewards.gold} gold!',
      quest: quest,
      player: player,
      timestamp: DateTime.now(),
      isRead: false,
      data: {
        'rewards': rewards,
        'completionTime': DateTime.now().toIso8601String(),
      },
    );
    
    _addNotification(notification);
  }

  /// Send a quest failure notification
  void sendQuestFailureNotification({
    required Quest quest,
    required Character player,
    String? failureReason,
  }) {
    final notification = QuestNotification(
      id: 'failure_${quest.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.questFailed,
      title: 'Quest Failed',
      message: 'Unfortunately, you failed "${quest.title}". ${failureReason ?? 'Better luck next time!'}',
      quest: quest,
      player: player,
      timestamp: DateTime.now(),
      isRead: false,
      data: {
        'failureReason': failureReason,
        'failureTime': DateTime.now().toIso8601String(),
      },
    );
    
    _addNotification(notification);
  }

  /// Send a quest time limit warning
  void sendTimeLimitWarning({
    required Quest quest,
    required Character player,
    required Duration timeRemaining,
  }) {
    final notification = QuestNotification(
      id: 'time_warning_${quest.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.timeLimitWarning,
      title: 'Quest Time Running Out!',
      message: 'Your quest "${quest.title}" expires in ${_formatDuration(timeRemaining)}. Hurry up!',
      quest: quest,
      player: player,
      timestamp: DateTime.now(),
      isRead: false,
      data: {
        'timeRemaining': timeRemaining.inMinutes,
        'warningTime': DateTime.now().toIso8601String(),
      },
    );
    
    _addNotification(notification);
  }

  /// Send a new quest available notification
  void sendNewQuestNotification({
    required Quest quest,
    required Character player,
  }) {
    final notification = QuestNotification(
      id: 'new_quest_${quest.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.newQuestAvailable,
      title: 'New Quest Available!',
      message: 'A new quest "${quest.title}" is available near your location!',
      quest: quest,
      player: player,
      timestamp: DateTime.now(),
      isRead: false,
      data: {
        'questType': quest.type.name,
        'questLevel': quest.level,
        'location': quest.location?.name,
      },
    );
    
    _addNotification(notification);
  }

  /// Send an achievement notification
  void sendAchievementNotification({
    required String achievementId,
    required String achievementName,
    required String description,
    required Character player,
    required int points,
  }) {
    final notification = QuestNotification(
      id: 'achievement_${achievementId}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.achievementUnlocked,
      title: 'Achievement Unlocked!',
      message: 'You unlocked "$achievementName" - $description (+$points points)',
      quest: null,
      player: player,
      timestamp: DateTime.now(),
      isRead: false,
      data: {
        'achievementId': achievementId,
        'achievementName': achievementName,
        'points': points,
      },
    );
    
    _addNotification(notification);
  }

  /// Send a daily quest reminder
  void sendDailyQuestReminder(Character player) {
    final notification = QuestNotification(
      id: 'daily_reminder_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.dailyQuestReminder,
      title: 'Daily Quests Available!',
      message: 'New daily quests are available! Complete them to earn bonus rewards.',
      quest: null,
      player: player,
      timestamp: DateTime.now(),
      isRead: false,
      data: {
        'reminderType': 'daily',
        'reminderTime': DateTime.now().toIso8601String(),
      },
    );
    
    _addNotification(notification);
  }

  /// Send a weekly quest reminder
  void sendWeeklyQuestReminder(Character player) {
    final notification = QuestNotification(
      id: 'weekly_reminder_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.weeklyQuestReminder,
      title: 'Weekly Quests Available!',
      message: 'New weekly quests are available! These offer greater rewards.',
      quest: null,
      player: player,
      timestamp: DateTime.now(),
      isRead: false,
      data: {
        'reminderType': 'weekly',
        'reminderTime': DateTime.now().toIso8601String(),
      },
    );
    
    _addNotification(notification);
  }

  /// Send a social quest notification
  void sendSocialQuestNotification({
    required Quest quest,
    required Character player,
    required List<Character> nearbyPlayers,
  }) {
    final notification = QuestNotification(
      id: 'social_${quest.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.socialQuestAvailable,
      title: 'Social Quest Opportunity!',
      message: '${nearbyPlayers.length} players are nearby for "${quest.title}". Team up for bonus rewards!',
      quest: quest,
      player: player,
      timestamp: DateTime.now(),
      isRead: false,
      data: {
        'nearbyPlayers': nearbyPlayers.length,
        'socialBonus': true,
      },
    );
    
    _addNotification(notification);
  }

  /// Send a quest chain progress notification
  void sendQuestChainProgressNotification({
    required String chainId,
    required String chainTitle,
    required int completedQuests,
    required int totalQuests,
    required Character player,
  }) {
    final progress = (completedQuests / totalQuests * 100).round();
    final notification = QuestNotification(
      id: 'chain_progress_${chainId}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.questChainProgress,
      title: 'Quest Chain Progress!',
      message: 'You\'ve completed $completedQuests/$totalQuests quests in "$chainTitle" ($progress% complete)',
      quest: null,
      player: player,
      timestamp: DateTime.now(),
      isRead: false,
      data: {
        'chainId': chainId,
        'chainTitle': chainTitle,
        'completedQuests': completedQuests,
        'totalQuests': totalQuests,
        'progress': progress,
      },
    );
    
    _addNotification(notification);
  }

  /// Get notifications for a player
  List<QuestNotification> getNotificationsForPlayer(String playerId) {
    return _notifications
        .where((notification) => notification.player.id == playerId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Mark notification as read
  void markNotificationAsRead(String notificationId) {
    final notification = _notifications.firstWhere((n) => n.id == notificationId);
    notification.isRead = true;
    _notifyListeners();
  }

  /// Mark all notifications as read for a player
  void markAllNotificationsAsRead(String playerId) {
    for (final notification in _notifications) {
      if (notification.player.id == playerId) {
        notification.isRead = true;
      }
    }
    _notifyListeners();
  }

  /// Delete a notification
  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _notifyListeners();
  }

  /// Get unread notification count for a player
  int getUnreadNotificationCount(String playerId) {
    return _notifications
        .where((notification) => 
            notification.player.id == playerId && !notification.isRead)
        .length;
  }

  /// Add a notification listener
  void addListener(NotificationListener listener) {
    _listeners.add(listener);
  }

  /// Remove a notification listener
  void removeListener(NotificationListener listener) {
    _listeners.remove(listener);
  }

  void _addNotification(QuestNotification notification) {
    _notifications.add(notification);
    _notifyListeners();
    
    // Limit notifications to prevent memory issues
    if (_notifications.length > 1000) {
      _notifications.removeRange(0, 100);
    }
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener.onNotificationUpdate();
    }
  }

  void _sendQuestReminder(Quest quest, Character player, String? customMessage) {
    final message = customMessage ?? 
        'Don\'t forget about your quest "${quest.title}"! It\'s waiting for you.';
    
    final notification = QuestNotification(
      id: 'reminder_${quest.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.questReminder,
      title: 'Quest Reminder',
      message: message,
      quest: quest,
      player: player,
      timestamp: DateTime.now(),
      isRead: false,
      data: {
        'reminderType': 'quest',
        'reminderTime': DateTime.now().toIso8601String(),
      },
    );
    
    _addNotification(notification);
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Schedule automatic reminders for active quests
  void scheduleAutomaticReminders(List<Quest> activeQuests, Character player) {
    for (final quest in activeQuests) {
      if (quest.timeLimit != null) {
        // Remind when 50% of time is left
        final halfTime = Duration(minutes: quest.timeLimit! ~/ 2);
        scheduleQuestReminder(
          quest: quest,
          player: player,
          delay: halfTime,
          customMessage: 'Your quest "${quest.title}" is halfway through its time limit!',
        );
        
        // Remind when 10% of time is left
        final warningTime = Duration(minutes: (quest.timeLimit! * 0.1).round());
        scheduleQuestReminder(
          quest: quest,
          player: player,
          delay: Duration(minutes: quest.timeLimit!) - warningTime,
          customMessage: 'Your quest "${quest.title}" is almost out of time!',
        );
      }
    }
  }

  /// Clear all notifications for a player
  void clearAllNotifications(String playerId) {
    _notifications.removeWhere((n) => n.player.id == playerId);
    _notifyListeners();
  }
}

class QuestNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final Quest? quest;
  final Character player;
  final DateTime timestamp;
  bool isRead;
  final Map<String, dynamic> data;

  QuestNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.quest,
    required this.player,
    required this.timestamp,
    required this.isRead,
    required this.data,
  });
}

enum NotificationType {
  questCompleted,
  questFailed,
  questReminder,
  timeLimitWarning,
  newQuestAvailable,
  achievementUnlocked,
  dailyQuestReminder,
  weeklyQuestReminder,
  socialQuestAvailable,
  questChainProgress,
}

extension NotificationTypeExtension on NotificationType {
  String get icon {
    switch (this) {
      case NotificationType.questCompleted:
        return '🎉';
      case NotificationType.questFailed:
        return '❌';
      case NotificationType.questReminder:
        return '⏰';
      case NotificationType.timeLimitWarning:
        return '⚠️';
      case NotificationType.newQuestAvailable:
        return '📋';
      case NotificationType.achievementUnlocked:
        return '🏆';
      case NotificationType.dailyQuestReminder:
        return '📅';
      case NotificationType.weeklyQuestReminder:
        return '📆';
      case NotificationType.socialQuestAvailable:
        return '👥';
      case NotificationType.questChainProgress:
        return '🔗';
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.questCompleted:
        return Colors.green;
      case NotificationType.questFailed:
        return Colors.red;
      case NotificationType.questReminder:
        return Colors.blue;
      case NotificationType.timeLimitWarning:
        return Colors.orange;
      case NotificationType.newQuestAvailable:
        return Colors.purple;
      case NotificationType.achievementUnlocked:
        return Colors.yellow;
      case NotificationType.dailyQuestReminder:
        return Colors.cyan;
      case NotificationType.weeklyQuestReminder:
        return Colors.indigo;
      case NotificationType.socialQuestAvailable:
        return Colors.pink;
      case NotificationType.questChainProgress:
        return Colors.teal;
    }
  }
}

abstract class NotificationListener {
  void onNotificationUpdate();
}
