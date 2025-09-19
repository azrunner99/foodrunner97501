import 'package:flutter/material.dart';
import '../services/nps_notification_tester.dart';

/// Widget for testing notification functionality
class NPSNotificationTestPanel extends StatefulWidget {
  const NPSNotificationTestPanel({super.key});

  @override
  State<NPSNotificationTestPanel> createState() =>
      _NPSNotificationTestPanelState();
}

class _NPSNotificationTestPanelState extends State<NPSNotificationTestPanel> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: Colors.purple.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Notification Testing',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Demo Only',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Test notification features with sample data:',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTestButton(
                  'Generate Sample Set',
                  Icons.scatter_plot,
                  Colors.blue,
                  () {
                    NPSNotificationTester.generateSampleNotifications();
                    _showSuccessMessage('Generated sample notifications!');
                  },
                ),
                _buildTestButton(
                  'Critical Alert',
                  Icons.warning,
                  Colors.red,
                  () {
                    NPSNotificationTester.generateCriticalNotification();
                    _showSuccessMessage('Generated critical notification!');
                  },
                ),
                _buildTestButton(
                  'Trend Alert',
                  Icons.trending_down,
                  Colors.orange,
                  () {
                    NPSNotificationTester.generateTrendAlert();
                    _showSuccessMessage('Generated trend alert!');
                  },
                ),
                _buildTestButton(
                  'High Volume',
                  Icons.trending_up,
                  Colors.green,
                  () {
                    NPSNotificationTester.generateHighVolumeNotification();
                    _showSuccessMessage('Generated high volume notification!');
                  },
                ),
                _buildTestButton(
                  'Clear All',
                  Icons.clear_all,
                  Colors.grey,
                  () {
                    NPSNotificationTester.clearAllNotifications();
                    _showSuccessMessage('Cleared all notifications!');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notifications will appear as snackbars and in the notification panel. Check the notification badge in the app bar!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
