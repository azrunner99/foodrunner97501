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
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _tryUnlock(AppState app) {
    if (_pinCtrl.text == AppState.adminPin) {
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
}