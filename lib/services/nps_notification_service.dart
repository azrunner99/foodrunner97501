import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/nps_score_feedback.dart';
import '../models/server.dart';

/// Notification types for NPS system
enum NotificationType {
  lowNPSScore,
  criticalNPSScore,
  newFeedbackSubmission,
  highResponseVolume,
  lowResponseVolume,
  serverPerformanceAlert,
  trendAlert,
  systemHealth,
}

/// Notification priority levels
enum NotificationPriority { low, medium, high, critical }

/// Individual notification data model
class NPSNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final Color color;
  final IconData icon;
  final bool isRead;
  final NotificationPriority priority;

  NPSNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.data = const {},
    required this.color,
    required this.icon,
    this.isRead = false,
    required this.priority,
  });

  NPSNotification copyWith({bool? isRead}) {
    return NPSNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      data: data,
      color: color,
      icon: icon,
      isRead: isRead ?? this.isRead,
      priority: priority,
    );
  }
}

/// Comprehensive notification system for NPS events
/// Handles push notifications, alerts, and real-time updates
class NPSNotificationService {
  static final NPSNotificationService _instance = NPSNotificationService._internal();
  factory NPSNotificationService() => _instance;
  NPSNotificationService._internal();

  // Notification thresholds
  static const double LOW_NPS_THRESHOLD = 30.0;
  static const double CRITICAL_NPS_THRESHOLD = 10.0;
  static const int HIGH_RESPONSE_COUNT = 50;
  static const int LOW_RESPONSE_COUNT = 5;

  // Notification storage
  final List<NPSNotification> _notifications = [];
  final List<Function(NPSNotification)> _listeners = [];

  /// Get all notifications
  List<NPSNotification> get notifications => List.unmodifiable(_notifications);

  /// Get unread notifications count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Add notification listener
  void addListener(Function(NPSNotification) listener) {
    _listeners.add(listener);
  }

  /// Remove notification listener
  void removeListener(Function(NPSNotification) listener) {
    _listeners.remove(listener);
  }

  /// Create notification for low NPS score
  void notifyLowNPSScore(NPSServer server, double npsScore, int responseCount) {
    final isCritical = npsScore <= CRITICAL_NPS_THRESHOLD;
    final notification = NPSNotification(
      id: _generateId(),
      type: isCritical ? NotificationType.criticalNPSScore : NotificationType.lowNPSScore,
      title: isCritical ? 'CRITICAL: Very Low NPS' : 'Low NPS Alert',
      message: '${server.name} has ${isCritical ? 'critical' : 'low'} NPS of ${npsScore.toStringAsFixed(1)}% (${responseCount} responses)',
      timestamp: DateTime.now(),
      data: {
        'serverId': server.id,
        'serverName': server.name,
        'npsScore': npsScore,
        'responseCount': responseCount,
      },
      color: isCritical ? Colors.red.shade800 : Colors.orange.shade600,
      icon: isCritical ? Icons.warning : Icons.trending_down,
      priority: isCritical ? NotificationPriority.critical : NotificationPriority.high,
    );

    _addNotification(notification);
  }

  /// Create notification for new feedback submission
  void notifyNewFeedback(NPSScoreFeedback feedback, NPSServer server) {
    final notification = NPSNotification(
      id: _generateId(),
      type: NotificationType.newFeedbackSubmission,
      title: 'New Feedback Received',
      message: 'New ${_getScoreCategory(feedback.score)} feedback for ${server.name} (Score: ${feedback.score}/10)',
      timestamp: DateTime.now(),
      data: {
        'feedbackId': feedback.id,
        'serverId': server.id,
        'serverName': server.name,
        'score': feedback.score,
        'category': _getScoreCategory(feedback.score),
      },
      color: _getScoreColor(feedback.score),
      icon: Icons.feedback,
      priority: feedback.score <= 6 ? NotificationPriority.high : NotificationPriority.medium,
    );

    _addNotification(notification);
  }

  /// Create notification for high response volume
  void notifyHighResponseVolume(NPSServer server, int responseCount, String period) {
    final notification = NPSNotification(
      id: _generateId(),
      type: NotificationType.highResponseVolume,
      title: 'High Response Volume',
      message: '${server.name} received ${responseCount} responses in ${period} - Great engagement!',
      timestamp: DateTime.now(),
      data: {
        'serverId': server.id,
        'serverName': server.name,
        'responseCount': responseCount,
        'period': period,
      },
      color: Colors.green.shade600,
      icon: Icons.trending_up,
      priority: NotificationPriority.medium,
    );

    _addNotification(notification);
  }

  /// Create notification for low response volume
  void notifyLowResponseVolume(NPSServer server, int responseCount, String period) {
    final notification = NPSNotification(
      id: _generateId(),
      type: NotificationType.lowResponseVolume,
      title: 'Low Response Volume',
      message: '${server.name} only received ${responseCount} responses in ${period} - Consider boosting feedback collection',
      timestamp: DateTime.now(),
      data: {
        'serverId': server.id,
        'serverName': server.name,
        'responseCount': responseCount,
        'period': period,
      },
      color: Colors.amber.shade600,
      icon: Icons.trending_down,
      priority: NotificationPriority.medium,
    );

    _addNotification(notification);
  }

  /// Create notification for server performance trend
  void notifyPerformanceTrend(NPSServer server, String trend, double change, String period) {
    final isPositive = change > 0;
    final notification = NPSNotification(
      id: _generateId(),
      type: NotificationType.trendAlert,
      title: '${isPositive ? 'Improving' : 'Declining'} Performance',
      message: '${server.name} performance ${trend} by ${change.abs().toStringAsFixed(1)}% over ${period}',
      timestamp: DateTime.now(),
      data: {
        'serverId': server.id,
        'serverName': server.name,
        'trend': trend,
        'change': change,
        'period': period,
      },
      color: isPositive ? Colors.green.shade600 : Colors.red.shade600,
      icon: isPositive ? Icons.trending_up : Icons.trending_down,
      priority: change.abs() > 10 ? NotificationPriority.high : NotificationPriority.medium,
    );

    _addNotification(notification);
  }

  /// Create notification for system health issues
  void notifySystemHealth(String issue, String details, NotificationPriority priority) {
    final notification = NPSNotification(
      id: _generateId(),
      type: NotificationType.systemHealth,
      title: 'System Health Alert',
      message: '${issue}: ${details}',
      timestamp: DateTime.now(),
      data: {
        'issue': issue,
        'details': details,
      },
      color: _getPriorityColor(priority),
      icon: Icons.health_and_safety,
      priority: priority,
    );

    _addNotification(notification);
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notifyListeners(_notifications[index]);
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    // Notify listeners of bulk update
    if (_notifications.isNotEmpty) {
      _notifyListeners(_notifications.first);
    }
  }

  /// Clear old notifications (older than 30 days)
  void clearOldNotifications() {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    _notifications.removeWhere((n) => n.timestamp.isBefore(cutoff));
  }

  /// Get notifications by type
  List<NPSNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Get notifications by priority
  List<NPSNotification> getNotificationsByPriority(NotificationPriority priority) {
    return _notifications.where((n) => n.priority == priority).toList();
  }

  /// Show visual notification in app
  void showInAppNotification(BuildContext context, NPSNotification notification) {
    // Haptic feedback for high priority notifications
    if (notification.priority == NotificationPriority.high || 
        notification.priority == NotificationPriority.critical) {
      HapticFeedback.mediumImpact();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              notification.icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    notification.message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: notification.color,
        duration: Duration(
          seconds: notification.priority == NotificationPriority.critical ? 8 : 4,
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            markAsRead(notification.id);
            // Navigate to relevant screen based on notification type
            _handleNotificationTap(context, notification);
          },
        ),
      ),
    );
  }

  // Private helper methods

  void _addNotification(NPSNotification notification) {
    _notifications.insert(0, notification); // Add to beginning for recency
    
    // Limit to 100 notifications to prevent memory issues
    if (_notifications.length > 100) {
      _notifications.removeRange(100, _notifications.length);
    }
    
    _notifyListeners(notification);
  }

  void _notifyListeners(NPSNotification notification) {
    for (final listener in _listeners) {
      listener(notification);
    }
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_notifications.length}';
  }

  String _getScoreCategory(int score) {
    if (score >= 9) return 'Promoter';
    if (score >= 7) return 'Passive';
    return 'Detractor';
  }

  Color _getScoreColor(int score) {
    if (score >= 9) return Colors.green.shade600;
    if (score >= 7) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.grey.shade600;
      case NotificationPriority.medium:
        return Colors.blue.shade600;
      case NotificationPriority.high:
        return Colors.orange.shade600;
      case NotificationPriority.critical:
        return Colors.red.shade700;
    }
  }

  void _handleNotificationTap(BuildContext context, NPSNotification notification) {
    // Navigate to appropriate screen based on notification type
    switch (notification.type) {
      case NotificationType.lowNPSScore:
      case NotificationType.criticalNPSScore:
      case NotificationType.trendAlert:
        // Navigate to server-specific analytics
        Navigator.pushNamed(context, '/server_nps');
        break;
      case NotificationType.newFeedbackSubmission:
        // Navigate to feedback details
        Navigator.pushNamed(context, '/server_nps');
        break;
      case NotificationType.highResponseVolume:
      case NotificationType.lowResponseVolume:
        // Navigate to analytics dashboard
        Navigator.pushNamed(context, '/server_nps');
        break;
      case NotificationType.systemHealth:
        // Navigate to system settings or admin
        Navigator.pushNamed(context, '/settings');
        break;
      default:
        Navigator.pushNamed(context, '/server_nps');
    }
  }
}