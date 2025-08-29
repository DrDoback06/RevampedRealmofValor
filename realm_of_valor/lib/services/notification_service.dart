import 'dart:async';
import '../data/models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    _initializeMockData();
  }

  final StreamController<GameNotification> _notificationController = StreamController<GameNotification>.broadcast();
  final List<GameNotification> _notifications = [];
  NotificationSettings _settings = NotificationSettings();

  Stream<GameNotification> get notificationStream => _notificationController.stream;
  List<GameNotification> get notifications => List.unmodifiable(_notifications);
  NotificationSettings get settings => _settings;

  void _initializeMockData() {
    // Add some mock notifications
    _addNotification(GameNotification(
      id: '1',
      title: 'Welcome to Realm of Valor!',
      message: 'Start your adventure by exploring the map and completing quests.',
      type: NotificationType.system,
      priority: NotificationPriority.high,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ));

    _addNotification(GameNotification(
      id: '2',
      title: 'Quest Available',
      message: 'A new quest has appeared near your location!',
      type: NotificationType.quest,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ));

    _addNotification(GameNotification(
      id: '3',
      title: 'Battle Victory!',
      message: 'You have defeated the Goblin Scout and earned 50 XP!',
      type: NotificationType.battle,
      priority: NotificationPriority.high,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ));

    _addNotification(GameNotification(
      id: '4',
      title: 'Achievement Unlocked',
      message: 'First Blood: Win your first battle',
      type: NotificationType.achievement,
      priority: NotificationPriority.high,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ));

    _addNotification(GameNotification(
      id: '5',
      title: 'Event Starting Soon',
      message: 'Weekly Battle Tournament begins in 1 hour!',
      type: NotificationType.event,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ));
  }

  void _addNotification(GameNotification notification) {
    _notifications.add(notification);
    _notificationController.add(notification);
  }

  // Predefined notification templates
  static final Map<String, NotificationTemplate> _templates = {
    'quest.completed': NotificationTemplate(
      id: 'quest.completed',
      title: 'Quest Completed!',
      message: 'You have successfully completed a quest and earned rewards!',
      type: NotificationType.quest,
      priority: NotificationPriority.high,
      defaultData: {'reward_type': 'xp_gold'},
    ),
    'battle_victory': NotificationTemplate(
      id: 'battle_victory',
      title: 'Victory!',
      message: 'You have defeated your opponent in battle!',
      type: NotificationType.battle,
      priority: NotificationPriority.high,
      defaultData: {'battle_type': 'pvp'},
    ),
    'achievement.unlocked': NotificationTemplate(
      id: 'achievement.unlocked',
      title: 'Achievement Unlocked!',
      message: 'Congratulations! You have unlocked a new achievement!',
      type: NotificationType.achievement,
      priority: NotificationPriority.high,
      defaultData: {'achievement_type': 'milestone'},
    ),
    'event_started': NotificationTemplate(
      id: 'event_started',
      title: 'Event Started!',
      message: 'A new event has begun! Join now to participate!',
      type: NotificationType.event,
      priority: NotificationPriority.normal,
      defaultData: {'event_type': 'special'},
    ),
    'fitness_goal': NotificationTemplate(
      id: 'fitness_goal',
      title: 'Fitness Goal Reached!',
      message: 'You have reached your daily fitness goal!',
      type: NotificationType.fitness,
      priority: NotificationPriority.normal,
      defaultData: {'goal_type': 'daily'},
    ),
    'weather_alert': NotificationTemplate(
      id: 'weather_alert',
      title: 'Weather Alert',
      message: 'Current weather conditions may affect your gameplay!',
      type: NotificationType.weather,
      priority: NotificationPriority.normal,
      defaultData: {'weather_type': 'alert'},
    ),
    'social_invite': NotificationTemplate(
      id: 'social_invite',
      title: 'Guild Invitation',
      message: 'You have been invited to join a guild!',
      type: NotificationType.social,
      priority: NotificationPriority.normal,
      defaultData: {'invite_type': 'guild'},
    ),
    'reward_available': NotificationTemplate(
      id: 'reward_available',
      title: 'Reward Available!',
      message: 'You have earned a reward! Claim it now!',
      type: NotificationType.reward,
      priority: NotificationPriority.high,
      defaultData: {'reward_type': 'daily'},
    ),
    'system_maintenance': NotificationTemplate(
      id: 'system_maintenance',
      title: 'System Maintenance',
      message: 'Scheduled maintenance will begin in 30 minutes.',
      type: NotificationType.system,
      priority: NotificationPriority.urgent,
      defaultData: {'maintenance_type': 'scheduled'},
    ),
    'reminder_daily': NotificationTemplate(
      id: 'reminder_daily',
      title: 'Daily Check-in',
      message: 'Don\'t forget to check in for your daily rewards!',
      type: NotificationType.reminder,
      priority: NotificationPriority.low,
      defaultData: {'reminder_type': 'daily'},
    ),
  };

  Map<String, NotificationTemplate> get templates => Map.unmodifiable(_templates);

  void sendNotificationFromTemplate(String templateId, {
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
    int? expiresAt,
  }) {
    final template = _templates[templateId];
    if (template == null) return;

    if (!_settings.isNotificationTypeEnabled(template.type)) return;

    final notification = template.createNotification(
      data: data,
      actionUrl: actionUrl,
      imageUrl: imageUrl,
      expiresAt: expiresAt,
    );

    _addNotification(notification);
  }

  void sendNotification({
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
    bool isPersistent = false,
    int? expiresAt,
  }) {
    if (!_settings.isNotificationTypeEnabled(type)) return;

    final notification = GameNotification(
      id: 'notification_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: type,
      priority: priority,
      createdAt: DateTime.now(),
      data: data,
      actionUrl: actionUrl,
      imageUrl: imageUrl,
      isPersistent: isPersistent,
      expiresAt: expiresAt,
    );

    _addNotification(notification);
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = notification.markAsRead();
      _notificationController.add(_notifications[index]);
    }
  }

  void dismissNotification(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = notification.dismiss();
      _notificationController.add(_notifications[index]);
    }
  }

  void actionNotification(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = notification.action();
      _notificationController.add(_notifications[index]);
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].isUnread) {
        _notifications[i] = _notifications[i].markAsRead();
        _notificationController.add(_notifications[i]);
      }
    }
  }

  void clearAllNotifications() {
    _notifications.clear();
    _notificationController.add(GameNotification(
      id: 'clear_all',
      title: 'Notifications Cleared',
      message: 'All notifications have been cleared.',
      type: NotificationType.system,
      createdAt: DateTime.now(),
    ));
  }

  void updateSettings(NotificationSettings settings) {
    _settings = settings;
  }

  void _cleanupExpiredNotifications() {
    _notifications.removeWhere((notification) => notification.isExpired);
  }

  void scheduleReminder(String title, String message, Duration delay) {
    Timer(delay, () {
      sendNotification(
        title: title,
        message: message,
        type: NotificationType.reminder,
        priority: NotificationPriority.low,
      );
    });
  }

  void sendBatchNotifications(List<GameNotification> notifications) {
    for (final notification in notifications) {
      if (_settings.isNotificationTypeEnabled(notification.type)) {
        _addNotification(notification);
      }
    }
  }

  Map<String, dynamic> getNotificationStats() {
    final total = _notifications.length;
    final unread = _notifications.where((n) => n.isUnread).length;
    final read = _notifications.where((n) => n.isRead).length;
    final dismissed = _notifications.where((n) => n.isDismissed).length;
    final actioned = _notifications.where((n) => n.isActioned).length;
    final expired = _notifications.where((n) => n.isExpired).length;

    // Type breakdown
    final typeBreakdown = <NotificationType, int>{};
    for (final type in NotificationType.values) {
      typeBreakdown[type] = _notifications.where((n) => n.type == type).length;
    }

    // Priority breakdown
    final priorityBreakdown = <String, int>{
      'low': _notifications.where((n) => n.priority == NotificationPriority.low).length,
      'normal': _notifications.where((n) => n.priority == NotificationPriority.normal).length,
      'high': _notifications.where((n) => n.priority == NotificationPriority.high).length,
      'urgent': _notifications.where((n) => n.priority == NotificationPriority.urgent).length,
    };

    return {
      'total': total,
      'unread': unread,
      'read': read,
      'dismissed': dismissed,
      'actioned': actioned,
      'expired': expired,
      'type_breakdown': typeBreakdown,
      'priority_breakdown': priorityBreakdown,
    };
  }

  void dispose() {
    _notificationController.close();
  }
}
