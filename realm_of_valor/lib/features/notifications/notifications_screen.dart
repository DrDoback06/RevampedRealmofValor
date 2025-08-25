import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/notification_model.dart';
import 'providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final notificationStats = ref.watch(notificationStatsProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(notificationRefreshProvider.notifier).state = DateTime.now();
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              final actions = ref.read(notificationActionsProvider);
              switch (value) {
                case 'mark_all_read':
                  actions['markAllAsRead']!();
                  break;
                case 'clear_all':
                  _showClearAllDialog();
                  break;
                case 'settings':
                  _showSettingsDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read),
                    SizedBox(width: 8),
                    Text('Mark All as Read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Notification Stats
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    '${notificationStats['total']}',
                    Icons.notifications,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Unread',
                    '$unreadCount',
                    Icons.mark_email_unread,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'High Priority',
                    '${notificationStats['priority_breakdown']['high'] ?? 0}',
                    Icons.priority_high,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search notifications...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(notificationSearchProvider.notifier).state = value;
              },
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.grey[50],
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('All', 0),
                ),
                Expanded(
                  child: _buildTabButton('Unread', 1),
                ),
                Expanded(
                  child: _buildTabButton('High Priority', 2),
                ),
                Expanded(
                  child: _buildTabButton('Recent', 3),
                ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(notificationRefreshProvider.notifier).state = DateTime.now();
              },
              child: _buildNotificationsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    List<GameNotification> notifications;
    
    switch (_selectedTabIndex) {
      case 0:
        notifications = ref.watch(searchedNotificationsProvider);
        break;
      case 1:
        notifications = ref.watch(unreadNotificationsProvider);
        break;
      case 2:
        notifications = ref.watch(highPriorityNotificationsProvider);
        break;
      case 3:
        notifications = ref.watch(recentNotificationsProvider);
        break;
      default:
        notifications = ref.watch(searchedNotificationsProvider);
    }

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(GameNotification notification) {
    final actions = ref.read(notificationActionsProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: notification.isUnread 
            ? Border.all(color: notification.priorityColor, width: 2)
            : null,
          color: notification.isUnread ? notification.priorityColor.withOpacity(0.05) : null,
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: notification.priorityColor.withOpacity(0.2),
            child: Text(
              notification.typeIcon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (notification.priority == NotificationPriority.urgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimeAgo(notification.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (notification.isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'EXPIRED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'mark_read':
                  if (notification.isUnread) {
                    actions['markAsRead']!(notification.id);
                  }
                  break;
                case 'dismiss':
                  actions['dismiss']!(notification.id);
                  break;
                case 'action':
                  actions['action']!(notification.id);
                  break;
              }
            },
            itemBuilder: (context) => [
              if (notification.isUnread)
                const PopupMenuItem(
                  value: 'mark_read',
                  child: Row(
                    children: [
                      Icon(Icons.mark_email_read),
                      SizedBox(width: 8),
                      Text('Mark as Read'),
                    ],
                  ),
                ),
                             const PopupMenuItem(
                 value: 'dismiss',
                 child: Row(
                   children: [
                     Icon(Icons.close),
                     SizedBox(width: 8),
                     Text('Dismiss'),
                   ],
                 ),
               ),
              if (notification.actionUrl != null)
                const PopupMenuItem(
                  value: 'action',
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new),
                      SizedBox(width: 8),
                      Text('Take Action'),
                    ],
                  ),
                ),
            ],
          ),
          onTap: () {
            if (notification.isUnread) {
              actions['markAsRead']!(notification.id);
            }
            if (notification.actionUrl != null) {
              actions['action']!(notification.id);
            }
          },
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Type Filter
            DropdownButtonFormField<NotificationType?>(
              value: ref.read(notificationFilterProvider)['type'],
              decoration: const InputDecoration(labelText: 'Notification Type'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
                ...NotificationType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                )),
              ],
              onChanged: (value) {
                final currentFilter = ref.read(notificationFilterProvider);
                ref.read(notificationFilterProvider.notifier).state = {
                  ...currentFilter,
                  'type': value,
                };
              },
            ),
            const SizedBox(height: 16),
            // Priority Filter
            DropdownButtonFormField<NotificationPriority?>(
              value: ref.read(notificationFilterProvider)['priority'],
              decoration: const InputDecoration(labelText: 'Priority'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Priorities')),
                ...NotificationPriority.values.map((priority) => DropdownMenuItem(
                  value: priority,
                  child: Text(priority.name),
                )),
              ],
              onChanged: (value) {
                final currentFilter = ref.read(notificationFilterProvider);
                ref.read(notificationFilterProvider.notifier).state = {
                  ...currentFilter,
                  'priority': value,
                };
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationFilterProvider.notifier).state = {
                'type': null,
                'priority': null,
                'status': null,
                'show_read': true,
                'show_dismissed': false,
              };
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
                         onPressed: () {
               final actions = ref.read(notificationActionsProvider);
               actions['clearAll']!();
               Navigator.of(context).pop();
             },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    final settings = ref.read(notificationSettingsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSettingSwitch(
                  'Quest Notifications',
                  settings.questNotifications,
                  (value) => setState(() {}),
                ),
                _buildSettingSwitch(
                  'Battle Notifications',
                  settings.battleNotifications,
                  (value) => setState(() {}),
                ),
                _buildSettingSwitch(
                  'Achievement Notifications',
                  settings.achievementNotifications,
                  (value) => setState(() {}),
                ),
                _buildSettingSwitch(
                  'Event Notifications',
                  settings.eventNotifications,
                  (value) => setState(() {}),
                ),
                _buildSettingSwitch(
                  'Social Notifications',
                  settings.socialNotifications,
                  (value) => setState(() {}),
                ),
                _buildSettingSwitch(
                  'Fitness Notifications',
                  settings.fitnessNotifications,
                  (value) => setState(() {}),
                ),
                _buildSettingSwitch(
                  'Weather Notifications',
                  settings.weatherNotifications,
                  (value) => setState(() {}),
                ),
                _buildSettingSwitch(
                  'System Notifications',
                  settings.systemNotifications,
                  (value) => setState(() {}),
                ),
                _buildSettingSwitch(
                  'Reward Notifications',
                  settings.rewardNotifications,
                  (value) => setState(() {}),
                ),
                _buildSettingSwitch(
                  'Reminder Notifications',
                  settings.reminderNotifications,
                  (value) => setState(() {}),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Update settings logic would go here
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSwitch(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}
