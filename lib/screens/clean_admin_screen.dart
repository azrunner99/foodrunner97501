import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../storage.dart';
import '../widgets/wallpaper_background.dart';
import '../services/nps_security_service.dart';
import 'manage_servers_screen.dart';
import 'server_avatar_settings_screen.dart';
import 'server_dashboard_screen.dart';
import 'backup_manager_screen.dart';
import 'server_performance_screen.dart';
import 'server_nps_screen.dart';
import 'station_analytics_screen.dart';
import 'smart_scheduling_screen.dart';
// import 'comprehensive_analytics_dashboard.dart'; // Commented out - file removed
import '../utils/log.dart';

class CleanAdminScreen extends StatefulWidget {
  const CleanAdminScreen({super.key});

  @override
  State<CleanAdminScreen> createState() => _CleanAdminScreenState();
}

class _CleanAdminScreenState extends State<CleanAdminScreen> {
  bool _unlocked = false; // Require PIN entry
  final _pinCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
  d("🚨 DEBUG: CleanAdminScreen.build() called - NEW VERSION ACTIVE!");

    final app = context.watch<AppState>();
    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Access'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.red.shade600.withOpacity(0.8),
                  Colors.red.shade400.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),
        body: WallpaperBackground(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 48,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Admin Access Required',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your PIN to access admin tools',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _pinCtrl,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        readOnly: true,
                        style: const TextStyle(
                          fontSize: 20,
                          letterSpacing: 4,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter PIN',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.red.shade400, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildKeypad(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _tryUnlock(app),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Unlock Admin Tools',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Tools'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            d("🚨 DEBUG: Back button pressed, navigating to home");
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red.shade600.withOpacity(0.8),
                Colors.red.shade400.withOpacity(0.6),
              ],
            ),
          ),
        ),
      ),
      body: WallpaperBackground(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
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
                    enabled: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ManageServersScreen()),
                      );
                    },
                  ),
                  _buildAdminTile(
                    icon: Icons.table_restaurant,
                    title: 'Manage Stations',
                    subtitle: 'Create, edit, or remove station types',
                    enabled: true,
                    onTap: () {
                      Navigator.pushNamed(context, '/stations');
                    },
                  ),
                  _buildAdminTile(
                    icon: Icons.image,
                    title: 'Server Avatar Audit',
                    subtitle: 'View photos taken by Team Members',
                    enabled: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ServerAvatarSettingsScreen()),
                      );
                    },
                  ),
                  _buildAdminTile(
                    icon: Icons.monitor_heart,
                    title: 'Server Monitoring',
                    subtitle: 'Monitor server activity and performance',
                    enabled: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ServerDashboardScreen()),
                      );
                    },
                  ),
                  _buildAdminTile(
                    icon: Icons.analytics,
                    title: 'Server Performance',
                    subtitle: 'Analyze server performance metrics and trends',
                    enabled: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ServerPerformanceScreen()),
                      );
                    },
                  ),
                  _buildAdminTile(
                    icon: Icons.sentiment_satisfied,
                    title: 'Server NPS',
                    subtitle: 'Manage server Net Promoter Score tracking',
                    enabled: true,
                    onTap: () {
                      d("🚨 DEBUG: Navigating to Server NPS screen!");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ServerNPSScreen()),
                      );
                    },
                  ),
                  _buildAdminTile(
                    icon: Icons.backup,
                    title: 'Data Backup & Restore',
                    subtitle: 'Backup and restore all app data',
                    enabled: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BackupManagerScreen()),
                      );
                    },
                  ),
                  _buildAdminTile(
                    icon: Icons.lock,
                    title: 'Change Admin PIN',
                    subtitle: 'Update the administrator PIN',
                    enabled: true,
                    onTap: () => _showChangePinDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildExpandableSectionCard(
                'In Development',
                Icons.construction,
                [
                  _buildAdminTile(
                    icon: Icons.location_on,
                    title: 'Station Analytics',
                    subtitle: 'Monitor station performance and efficiency metrics (In Development)',
                    enabled: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StationAnalyticsScreen()),
                      );
                    },
                  ),
                  _buildAdminTile(
                    icon: Icons.dashboard,
                    title: 'Comprehensive Analytics',
                    subtitle: 'Advanced analytics, reporting, and backup management (In Development)',
                    enabled: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        // MaterialPageRoute(builder: (_) => const ComprehensiveAnalyticsDashboard()), // Commented out - file removed
                        MaterialPageRoute(builder: (_) => const Text('Analytics Dashboard temporarily disabled')),
                      );
                    },
                  ),
                  _buildAdminTile(
                    icon: Icons.auto_awesome,
                    title: 'Smart Scheduling',
                    subtitle: 'AI-powered predictive scheduling and optimization (In Development)',
                    enabled: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SmartSchedulingScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _tryUnlock(AppState app) async {
    final isValid = await app.isValidAdminPin(_pinCtrl.text);
    if (isValid) {
      // Authenticate with security service as admin
      final securityService = context.read<NPSSecurityService>();
      final success =
          await securityService.authenticateUser('admin', 'admin123');

      if (success) {
        setState(() => _unlocked = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin access granted'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security authentication failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Wrong PIN')));
    }
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('Clear', isSpecial: true),
              _buildKeypadButton('0'),
              _buildKeypadButton('⌫', isSpecial: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String text, {bool isSpecial = false}) {
    return SizedBox(
      width: 70,
      height: 60,
      child: ElevatedButton(
        onPressed: () => _onKeypadPressed(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSpecial ? Colors.grey.shade200 : Colors.white,
          foregroundColor: isSpecial ? Colors.grey.shade700 : Colors.black87,
          elevation: 2,
          shadowColor: Colors.red.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.red.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: isSpecial ? 16 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _onKeypadPressed(String value) {
    setState(() {
      if (value == 'Clear') {
        _pinCtrl.clear();
      } else if (value == '⌫') {
        if (_pinCtrl.text.isNotEmpty) {
          _pinCtrl.text = _pinCtrl.text.substring(0, _pinCtrl.text.length - 1);
        }
      } else if (_pinCtrl.text.length < 6) {
        // Limit PIN length
        _pinCtrl.text += value;
      }
    });

    // Auto-unlock if PIN is complete
    if (_pinCtrl.text.length >= 4) {
      _tryUnlock(context.read<AppState>());
    }
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 8,
      shadowColor: Colors.red.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
            ],
          ),
          border: Border.all(
            color: Colors.red.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.red.shade600,
                          Colors.red.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 8,
      shadowColor: Colors.orange.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade50.withOpacity(0.9),
              Colors.orange.shade100.withOpacity(0.7),
            ],
          ),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.shade600,
                  Colors.orange.shade400,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            '${children.length} features in development',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: enabled
                  ? Colors.red.shade50.withOpacity(0.5)
                  : Colors.grey.shade100.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: enabled
                    ? Colors.red.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: enabled ? Colors.red.shade600 : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              enabled ? Colors.black87 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              enabled ? Colors.black54 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.red.shade400,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePinDialog() {
    final TextEditingController currentPinController = TextEditingController();
    final TextEditingController newPinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Admin PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPinController,
              decoration: const InputDecoration(
                labelText: 'Current PIN',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPinController,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPinController,
              decoration: const InputDecoration(
                labelText: 'Confirm New PIN',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveNewPin(
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

  void _saveNewPin(String currentPin, String newPin, String confirmPin) async {
    final app = context.read<AppState>();
    
    // Validate current PIN
    if (!(await app.isValidAdminPin(currentPin))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current PIN is incorrect')),
        );
      }
      return;
    }
    
    // Validate new PIN format
    if (newPin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(newPin)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New PIN must be exactly 4 digits')),
        );
      }
      return;
    }
    
    // Validate PIN confirmation
    if (newPin != confirmPin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN confirmation does not match')),
        );
      }
      return;
    }
    
    // Save new PIN
    try {
      await app.setAdminPin(newPin);
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin PIN updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating PIN: $e')),
        );
      }
    }
  }
}
