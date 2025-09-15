import '../services/nps_notification_service.dart';
import '../models/nps_score_feedback.dart';
import '../models/server.dart';

/// Service for testing and demonstrating notification functionality
class NPSNotificationTester {
  static final NPSNotificationService _notificationService = NPSNotificationService();

  /// Generate sample notifications for demonstration
  static void generateSampleNotifications() {
    final sampleServers = _createSampleServers();
    final sampleFeedback = _createSampleFeedback();

    // Generate low NPS notifications
    _notificationService.notifyLowNPSScore(sampleServers[0], 25.5, 8);
    _notificationService.notifyLowNPSScore(sampleServers[1], 8.2, 15); // Critical

    // Generate new feedback notifications
    for (int i = 0; i < 3; i++) {
      _notificationService.notifyNewFeedback(sampleFeedback[i], sampleServers[i % 2]);
    }

    // Generate volume notifications
    _notificationService.notifyHighResponseVolume(sampleServers[0], 75, 'this week');
    _notificationService.notifyLowResponseVolume(sampleServers[1], 3, 'this week');

    // Generate trend notifications
    _notificationService.notifyPerformanceTrend(sampleServers[0], 'improved', 12.5, '30 days');
    _notificationService.notifyPerformanceTrend(sampleServers[1], 'declined', -8.3, '30 days');

    // Generate system health notification
    _notificationService.notifySystemHealth(
      'Database Sync',
      'Last sync completed successfully',
      NotificationPriority.low,
    );
  }

  /// Generate a critical notification
  static void generateCriticalNotification() {
    final server = NPSServer(
      id: 999,
      name: 'Test Server',
      hireDate: DateTime.now().subtract(const Duration(days: 30)),
    );

    _notificationService.notifyLowNPSScore(server, 5.0, 20);
  }

  /// Generate trend alert
  static void generateTrendAlert() {
    final server = NPSServer(
      id: 998,
      name: 'Performance Server',
      hireDate: DateTime.now().subtract(const Duration(days: 60)),
    );

    _notificationService.notifyPerformanceTrend(server, 'declined significantly', -15.2, '7 days');
  }

  /// Generate high volume notification
  static void generateHighVolumeNotification() {
    final server = NPSServer(
      id: 997,
      name: 'Popular Server',
      hireDate: DateTime.now().subtract(const Duration(days: 45)),
    );

    _notificationService.notifyHighResponseVolume(server, 128, 'today');
  }

  /// Clear all notifications
  static void clearAllNotifications() {
    _notificationService.markAllAsRead();
  }

  static List<NPSServer> _createSampleServers() {
    return [
      NPSServer(
        id: 1,
        name: 'Alice Johnson',
        hireDate: DateTime.now().subtract(const Duration(days: 90)),
      ),
      NPSServer(
        id: 2,
        name: 'Bob Wilson',
        hireDate: DateTime.now().subtract(const Duration(days: 120)),
      ),
      NPSServer(
        id: 3,
        name: 'Carol Davis',
        hireDate: DateTime.now().subtract(const Duration(days: 60)),
      ),
    ];
  }

  static List<NPSScoreFeedback> _createSampleFeedback() {
    return [
      NPSScoreFeedback(
        id: 1,
        serverId: 1,
        score: 3, // Detractor
        comment: 'Service was slow and food was cold',
        submissionDate: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      NPSScoreFeedback(
        id: 2,
        serverId: 2,
        score: 9, // Promoter
        comment: 'Excellent service, very attentive!',
        submissionDate: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NPSScoreFeedback(
        id: 3,
        serverId: 1,
        score: 7, // Passive
        comment: 'Good service, nothing special',
        submissionDate: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ];
  }
}