import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/notification_service.dart';
import '../../../data/models/notification_model.dart';

// Notification Service Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// All Notifications Provider
final allNotificationsProvider = Provider<List<GameNotification>>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.notifications;
});

// Unread Count Provider
final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(allNotificationsProvider);
  return notifications.where((n) => n.isUnread).length;
});

// Unread Notifications Provider
final unreadNotificationsProvider = Provider<List<GameNotification>>((ref) {
  final notifications = ref.watch(allNotificationsProvider);
  return notifications.where((n) => n.isUnread).toList();
});

// High Priority Notifications Provider
final highPriorityNotificationsProvider = Provider<List<GameNotification>>((ref) {
  final notifications = ref.watch(allNotificationsProvider);
  return notifications.where((n) => 
    n.priority == NotificationPriority.high || 
    n.priority == NotificationPriority.urgent
  ).toList();
});

// Recent Notifications Provider (last 24 hours)
final recentNotificationsProvider = Provider<List<GameNotification>>((ref) {
  final notifications = ref.watch(allNotificationsProvider);
  final now = DateTime.now();
  final yesterday = now.subtract(const Duration(hours: 24));
  
  return notifications.where((n) => n.createdAt.isAfter(yesterday)).toList();
});

// Notification Settings Provider
final notificationSettingsProvider = Provider<NotificationSettings>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.settings;
});

// Notification Statistics Provider
final notificationStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final notifications = ref.watch(allNotificationsProvider);
  
  final total = notifications.length;
  final unread = notifications.where((n) => n.isUnread).length;
  final read = notifications.where((n) => n.isRead).length;
  final dismissed = notifications.where((n) => n.isDismissed).length;
  final actioned = notifications.where((n) => n.isActioned).length;
  final expired = notifications.where((n) => n.isExpired).length;
  
  // Type breakdown
  final typeBreakdown = <NotificationType, int>{};
  for (final type in NotificationType.values) {
    typeBreakdown[type] = notifications.where((n) => n.type == type).length;
  }
  
  // Priority breakdown
  final priorityBreakdown = <String, int>{
    'low': notifications.where((n) => n.priority == NotificationPriority.low).length,
    'normal': notifications.where((n) => n.priority == NotificationPriority.normal).length,
    'high': notifications.where((n) => n.priority == NotificationPriority.high).length,
    'urgent': notifications.where((n) => n.priority == NotificationPriority.urgent).length,
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
});

// Notification Filter Provider
final notificationFilterProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'type': null,
    'priority': null,
    'status': null,
    'show_read': true,
    'show_dismissed': false,
  };
});

// Filtered Notifications Provider
final filteredNotificationsProvider = Provider<List<GameNotification>>((ref) {
  final allNotifications = ref.watch(allNotificationsProvider);
  final filter = ref.watch(notificationFilterProvider);
  
  return allNotifications.where((notification) {
    // Type filter
    if (filter['type'] != null && notification.type != filter['type']) {
      return false;
    }
    
    // Priority filter
    if (filter['priority'] != null && notification.priority != filter['priority']) {
      return false;
    }
    
    // Status filter
    if (filter['status'] != null) {
      switch (filter['status']) {
        case 'unread':
          if (!notification.isUnread) return false;
          break;
        case 'read':
          if (!notification.isRead) return false;
          break;
        case 'dismissed':
          if (!notification.isDismissed) return false;
          break;
        case 'actioned':
          if (!notification.isActioned) return false;
          break;
      }
    }
    
    // Show read filter
    if (filter['show_read'] == false && notification.isRead) {
      return false;
    }
    
    // Show dismissed filter
    if (filter['show_dismissed'] == false && notification.isDismissed) {
      return false;
    }
    
    return true;
  }).toList();
});

// Notification Search Provider
final notificationSearchProvider = StateProvider<String>((ref) => '');

// Searched Notifications Provider
final searchedNotificationsProvider = Provider<List<GameNotification>>((ref) {
  final allNotifications = ref.watch(filteredNotificationsProvider);
  final searchQuery = ref.watch(notificationSearchProvider);
  
  if (searchQuery.isEmpty) {
    return allNotifications;
  }
  
  final query = searchQuery.toLowerCase();
  return allNotifications.where((notification) {
    return notification.title.toLowerCase().contains(query) ||
           notification.message.toLowerCase().contains(query) ||
           notification.type.name.toLowerCase().contains(query);
  }).toList();
});

// Notification Refresh Provider
final notificationRefreshProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Notification Actions Provider
final notificationActionsProvider = Provider<Map<String, Function>>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  
  return {
    'markAsRead': (String id) {
      notificationService.markAsRead(id);
      ref.read(notificationRefreshProvider.notifier).state = DateTime.now();
    },
    'markAllAsRead': () {
      notificationService.markAllAsRead();
      ref.read(notificationRefreshProvider.notifier).state = DateTime.now();
    },
    'dismiss': (String id) {
      notificationService.dismissNotification(id);
      ref.read(notificationRefreshProvider.notifier).state = DateTime.now();
    },
    'action': (String id) {
      notificationService.actionNotification(id);
      ref.read(notificationRefreshProvider.notifier).state = DateTime.now();
    },
    'clearAll': () {
      notificationService.clearAllNotifications();
      ref.read(notificationRefreshProvider.notifier).state = DateTime.now();
    },
  };
});

// Notification Templates Provider
final notificationTemplatesProvider = Provider<Map<String, NotificationTemplate>>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.templates;
});

// Notification Stream Provider
final notificationStreamProvider = StreamProvider<GameNotification>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.notificationStream;
});

// Notification by Type Provider
final notificationsByTypeProvider = Provider.family<List<GameNotification>, NotificationType>((ref, type) {
  final notifications = ref.watch(allNotificationsProvider);
  return notifications.where((n) => n.type == type).toList();
});

// Notification by Priority Provider
final notificationsByPriorityProvider = Provider.family<List<GameNotification>, NotificationPriority>((ref, priority) {
  final notifications = ref.watch(allNotificationsProvider);
  return notifications.where((n) => n.priority == priority).toList();
});

// Notification by Status Provider
final notificationsByStatusProvider = Provider.family<List<GameNotification>, NotificationStatus>((ref, status) {
  final notifications = ref.watch(allNotificationsProvider);
  return notifications.where((n) => n.status == status).toList();
});

// Notification by ID Provider
final notificationByIdProvider = Provider.family<GameNotification?, String>((ref, id) {
  final notifications = ref.watch(allNotificationsProvider);
  try {
    return notifications.firstWhere((n) => n.id == id);
  } catch (e) {
    return null;
  }
});

// Notification Summary Provider
final notificationSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final notifications = ref.watch(allNotificationsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final thisWeek = today.subtract(Duration(days: today.weekday - 1));
  
  final todayNotifications = notifications.where((n) => 
    n.createdAt.isAfter(today)
  ).length;
  
  final yesterdayNotifications = notifications.where((n) => 
    n.createdAt.isAfter(yesterday) && n.createdAt.isBefore(today)
  ).length;
  
  final thisWeekNotifications = notifications.where((n) => 
    n.createdAt.isAfter(thisWeek)
  ).length;
  
  final urgentNotifications = notifications.where((n) => 
    n.priority == NotificationPriority.urgent && n.isUnread
  ).length;
  
  return {
    'today': todayNotifications,
    'yesterday': yesterdayNotifications,
    'this_week': thisWeekNotifications,
    'urgent': urgentNotifications,
  };
});
