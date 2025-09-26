import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../widgets/wallpaper_background.dart';
import 'manage_servers_screen.dart';
import 'server_avatar_settings_screen.dart';
import 'server_dashboard_screen.dart';
import 'backup_manager_screen.dart';
import 'server_performance_screen.dart';
import 'server_nps_screen.dart';
import 'station_analytics_screen.dart';
import 'smart_scheduling_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _unlocked = false; // Require PIN entry
  final _pinCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Access'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: WallpaperBackground(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withOpacity(0.9),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Admin Access Required',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pinCtrl,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Enter PIN',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _tryUnlock(app),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Unlock Admin Tools', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Tools'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: WallpaperBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionCard(
              'Management Tools',
              Icons.settings,
              [
                _buildAdminTile(
                  icon: Icons.manage_accounts,
                  title: 'Manage Servers',
                  subtitle: 'Add, rename, or remove servers (PIN required)',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageServersScreen()),
                    );
                  },
                ),
                _buildAdminTile(
                  icon: Icons.table_restaurant,
                  title: 'Manage Stations',
                  subtitle: 'Create, edit, or remove station types',
                  onTap: () => Navigator.pushNamed(context, '/stations'),
                ),
                _buildAdminTile(
                  icon: Icons.image,
                  title: 'Server Avatar Audit',
                  subtitle: 'View photos taken by Team Members',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ServerAvatarSettingsScreen()),
                    );
                  },
                ),
                _buildAdminTile(
                  icon: Icons.monitor_heart,
                  title: 'Server Monitoring',
                  subtitle: 'Monitor server activity and performance',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ServerDashboardScreen()),
                    );
                  },
                ),
                _buildAdminTile(
                  icon: Icons.analytics,
                  title: 'Server Performance',
                  subtitle: 'Analyze server performance metrics and trends',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ServerPerformanceScreen()),
                    );
                  },
                ),
                _buildAdminTile(
                  icon: Icons.location_on,
                  title: 'Station Analytics',
                  subtitle: 'Monitor station performance and efficiency metrics',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StationAnalyticsScreen()),
                    );
                  },
                ),
                _buildAdminTile(
                  icon: Icons.auto_awesome,
                  title: 'Smart Scheduling',
                  subtitle: 'AI-powered predictive scheduling and optimization',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SmartSchedulingScreen()),
                    );
                  },
                ),
                _buildAdminTile(
                  icon: Icons.sentiment_satisfied,
                  title: 'Server NPS',
                  subtitle: 'Manage server Net Promoter Score tracking',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ServerNPSScreen()),
                    );
                  },
                ),
                _buildAdminTile(
                  icon: Icons.backup,
                  title: 'Data Backup & Restore',
                  subtitle: 'Backup and restore all app data',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BackupManagerScreen()),
                    );
                  },
                ),
                _buildAdminTile(
                  icon: Icons.lock,
                  title: 'Change Admin PIN',
                  subtitle: 'Update the administrator access PIN',
                  onTap: () => _showChangePinDialog(app),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              'In Development',
              Icons.construction,
              [
                // Empty - ready for you to add features as needed
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _tryUnlock(AppState app) async {
    final isValid = await app.isValidAdminPin(_pinCtrl.text);
    if (isValid) {
      setState(() => _unlocked = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wrong PIN')),
      );
    }
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade50,
          child: Icon(icon, color: Colors.red.shade600),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showChangePinDialog(AppState app) async {
    final currentPin = await app.adminPin;
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Admin PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current PIN: ${'•' * currentPin.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: currentPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Current PIN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'New PIN (4 digits)',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Confirm New PIN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveNewPin(
              app,
              currentPinController.text,
              newPinController.text,
              confirmPinController.text,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _saveNewPin(AppState app, String currentPin, String newPin, String confirmPin) async {
    // Validate current PIN
    final isCurrentValid = await app.isValidAdminPin(currentPin);
    if (!isCurrentValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current PIN is incorrect')),
      );
      return;
    }

    // Validate new PIN format
    if (newPin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(newPin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New PIN must be exactly 4 digits')),
      );
      return;
    }

    // Validate PIN confirmation
    if (newPin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN confirmation does not match')),
      );
      return;
    }

    // Save new PIN
    try {
      await app.setAdminPin(newPin);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin PIN updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving PIN: $e')),
      );
    }
  }
}