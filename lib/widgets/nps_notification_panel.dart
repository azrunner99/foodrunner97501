import 'package:flutter/material.dart';
import '../services/nps_notification_service.dart';

/// Widget that displays and manages NPS notifications
class NPSNotificationPanel extends StatefulWidget {
  const NPSNotificationPanel({super.key});

  @override
  State<NPSNotificationPanel> createState() => _NPSNotificationPanelState();
}

class _NPSNotificationPanelState extends State<NPSNotificationPanel> {
  final NPSNotificationService _notificationService = NPSNotificationService();
  NotificationType? _filterType;
  bool _showOnlyUnread = false;

  @override
  void initState() {
    super.initState();
    _notificationService.addListener(_onNotificationUpdate);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationUpdate);
    super.dispose();
  }

  void _onNotificationUpdate(NPSNotification notification) {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _getFilteredNotifications();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1),
          _buildFilters(),
          const Divider(height: 1),
          _buildNotificationsList(notifications),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final unreadCount = _notificationService.unreadCount;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.notifications,
            color: Colors.blue.shade600,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const Spacer(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'mark_all_read':
                  _notificationService.markAllAsRead();
                  setState(() {});
                  break;
                case 'clear_old':
                  _notificationService.clearOldNotifications();
                  setState(() {});
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
                    Text('Mark All Read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_old',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Old'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filterType == null,
                  onSelected: (selected) {
                    setState(() {
                      _filterType = null;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Critical'),
                  selected: _filterType == NotificationType.criticalNPSScore,
                  onSelected: (selected) {
                    setState(() {
                      _filterType =
                          selected ? NotificationType.criticalNPSScore : null;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Low NPS'),
                  selected: _filterType == NotificationType.lowNPSScore,
                  onSelected: (selected) {
                    setState(() {
                      _filterType =
                          selected ? NotificationType.lowNPSScore : null;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Feedback'),
                  selected:
                      _filterType == NotificationType.newFeedbackSubmission,
                  onSelected: (selected) {
                    setState(() {
                      _filterType = selected
                          ? NotificationType.newFeedbackSubmission
                          : null;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Unread Only'),
            selected: _showOnlyUnread,
            onSelected: (selected) {
              setState(() {
                _showOnlyUnread = selected;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<NPSNotification> notifications) {
    if (notifications.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _showOnlyUnread
                    ? 'No unread notifications'
                    : 'No notifications',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 400,
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationTile(notification);
        },
      ),
    );
  }

  Widget _buildNotificationTile(NPSNotification notification) {
    return Container(
      decoration: BoxDecoration(
        color: notification.isRead ? null : Colors.blue.shade50,
        border: Border(
          left: BorderSide(
            color: notification.color,
            width: 4,
          ),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: notification.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            notification.icon,
            color: notification.color,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight:
                      notification.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ),
            Text(
              _formatTime(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        subtitle: Text(
          notification.message,
          style: TextStyle(
            color: notification.isRead
                ? Colors.grey.shade600
                : Colors.grey.shade800,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPriorityIndicator(notification.priority),
            const SizedBox(width: 8),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: () {
          if (!notification.isRead) {
            _notificationService.markAsRead(notification.id);
            setState(() {});
          }
          _handleNotificationTap(notification);
        },
      ),
    );
  }

  Widget _buildPriorityIndicator(NotificationPriority priority) {
    IconData icon;
    Color color;

    switch (priority) {
      case NotificationPriority.low:
        icon = Icons.flag;
        color = Colors.grey.shade400;
        break;
      case NotificationPriority.medium:
        icon = Icons.flag;
        color = Colors.blue.shade400;
        break;
      case NotificationPriority.high:
        icon = Icons.flag;
        color = Colors.orange.shade600;
        break;
      case NotificationPriority.critical:
        icon = Icons.flag;
        color = Colors.red.shade700;
        break;
    }

    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }

  List<NPSNotification> _getFilteredNotifications() {
    var notifications = _notificationService.notifications;

    if (_filterType != null) {
      notifications =
          notifications.where((n) => n.type == _filterType).toList();
    }

    if (_showOnlyUnread) {
      notifications = notifications.where((n) => !n.isRead).toList();
    }

    return notifications;
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  void _handleNotificationTap(NPSNotification notification) {
    // Navigate to relevant screen based on notification type
    switch (notification.type) {
      case NotificationType.lowNPSScore:
      case NotificationType.criticalNPSScore:
      case NotificationType.trendAlert:
        Navigator.pushNamed(context, '/server_nps');
        break;
      case NotificationType.newFeedbackSubmission:
        Navigator.pushNamed(context, '/server_nps');
        break;
      case NotificationType.highResponseVolume:
      case NotificationType.lowResponseVolume:
        Navigator.pushNamed(context, '/server_nps');
        break;
      case NotificationType.systemHealth:
        Navigator.pushNamed(context, '/settings');
        break;
      default:
        Navigator.pushNamed(context, '/server_nps');
    }
  }
}
