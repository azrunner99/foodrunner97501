import 'package:flutter/material.dart';
import '../services/nps_notification_service.dart';
import 'nps_notification_panel.dart';

/// Notification badge widget for app bar
class NPSNotificationBadge extends StatefulWidget {
  final VoidCallback? onTap;

  const NPSNotificationBadge({super.key, this.onTap});

  @override
  State<NPSNotificationBadge> createState() => _NPSNotificationBadgeState();
}

class _NPSNotificationBadgeState extends State<NPSNotificationBadge> {
  final NPSNotificationService _notificationService = NPSNotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _updateUnreadCount();
    _notificationService.addListener(_onNotificationUpdate);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationUpdate);
    super.dispose();
  }

  void _onNotificationUpdate(NPSNotification notification) {
    if (mounted) {
      _updateUnreadCount();
    }
  }

  void _updateUnreadCount() {
    setState(() {
      _unreadCount = _notificationService.unreadCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: widget.onTap ?? _showNotificationPanel,
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Notification panel
            const Expanded(
              child: NPSNotificationPanel(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple notification display widget for dashboard
class NPSNotificationSummary extends StatefulWidget {
  const NPSNotificationSummary({super.key});

  @override
  State<NPSNotificationSummary> createState() => _NPSNotificationSummaryState();
}

class _NPSNotificationSummaryState extends State<NPSNotificationSummary> {
  final NPSNotificationService _notificationService = NPSNotificationService();

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
    final recentNotifications = _notificationService.notifications.take(3).toList();
    final unreadCount = _notificationService.unreadCount;
    final criticalCount = _notificationService
        .getNotificationsByPriority(NotificationPriority.critical)
        .where((n) => !n.isRead)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: criticalCount > 0 ? Colors.red.shade600 : Colors.blue.shade600,
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
                const Spacer(),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: criticalCount > 0 ? Colors.red.shade600 : Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentNotifications.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No recent notifications',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              ...recentNotifications.map((notification) => 
                _buildNotificationSummaryTile(notification)
              ),
            if (recentNotifications.isNotEmpty)
              const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/server_nps');
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('View All Notifications'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSummaryTile(NPSNotification notification) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.grey.shade50 : notification.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: notification.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            notification.icon,
            color: notification.color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(notification.timestamp),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}