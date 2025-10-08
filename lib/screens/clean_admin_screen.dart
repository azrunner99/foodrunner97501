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
import 'unified_backup_screen.dart';
import 'server_performance_screen.dart';
import 'id_migration_screen.dart';
import 'server_nps_screen.dart';
import 'station_analytics_screen.dart';
import 'smart_scheduling_screen.dart';
// import 'comprehensive_analytics_dashboard.dart'; // Commented out - file removed
import '../utils/log.dart';
import 'phase4_runner.dart';
import 'phase6_runner.dart';
import '../debug/nps_database_inspector.dart';
import '../debug/nps_database_schema_repair.dart';
import '../services/database_sync_service.dart';
import '../services/server_data_service.dart';
import '../services/server_id_resolver.dart';
import '../storage/database_factory.dart';
import '../storage/nps_database_adapter.dart';

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
                    title: 'Backup & Restore',
                    subtitle: 'All backup options: Quick, USB-C, and Local backup methods',
                    enabled: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UnifiedBackupScreen()),
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
              // ⭐ Phase 1.5: Database Sync Tools Section
              _buildSectionCard(
                'Database Synchronization',
                Icons.sync,
                [
                  _buildAdminTile(
                    icon: Icons.sync_alt,
                    title: 'Sync Status',
                    subtitle: 'View synchronization status between storage systems',
                    enabled: true,
                    onTap: () => _showSyncStatusDialog(),
                  ),
                  _buildAdminTile(
                    icon: Icons.refresh,
                    title: 'Manual Sync',
                    subtitle: 'Force synchronization of all servers',
                    enabled: true,
                    onTap: () => _performManualSync(),
                  ),
                  _buildAdminTile(
                    icon: Icons.bug_report,
                    title: 'Server Data Report',
                    subtitle: 'View detailed server data from all sources',
                    enabled: true,
                    onTap: () => _showServerDataReport(),
                  ),
                  _buildAdminTile(
                    icon: Icons.healing,
                    title: 'Auto-Fix Issues',
                    subtitle: 'Automatically fix common sync problems',
                    enabled: true,
                    onTap: () => _autoFixSyncIssues(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildExpandableSectionCard(
                'Developer Tools',
                Icons.developer_mode,
                [
                  _buildAdminTile(
                    icon: Icons.check_circle_outline,
                    title: 'System Validation',
                    subtitle: 'Comprehensive testing and validation of server ID systems',
                    enabled: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const Phase4Runner()),
                      );
                    },
                  ),
                  _buildAdminTile(
                    icon: Icons.analytics,
                    title: 'Widget Analysis',
                    subtitle: 'Audit NPS widget calculations and data integrity',
                    enabled: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const Phase6Runner()),
                      );
                    },
                  ),
                  _buildAdminTile(
                    icon: Icons.transform,
                    title: 'ID Migration',
                    subtitle: 'Migrate server IDs from integer to string format',
                    enabled: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const IDMigrationScreen()),
                      );
                    },
                  ),
                  _buildAdminTile(
                    icon: Icons.search,
                    title: 'Check NPS Database',
                    subtitle: 'Inspect NPS database content and structure',
                    enabled: true,
                    onTap: () async {
                      // Show loading dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const AlertDialog(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text('Inspecting NPS database...'),
                            ],
                          ),
                        ),
                      );
                      
                      // Run inspection
                      await NPSDatabaseInspector.inspectDatabase();
                      
                      // Close loading dialog
                      if (context.mounted) {
                        Navigator.pop(context);
                        
                        // Show completion message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Database inspection complete - check debug logs'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                  _buildAdminTile(
                    icon: Icons.build,
                    title: 'Fix NPS Database Schema',
                    subtitle: 'Repair database schema if NPS data cannot save',
                    enabled: true,
                    onTap: () async {
                      // Show loading dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const AlertDialog(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text('Repairing database schema...'),
                            ],
                          ),
                        ),
                      );
                      
                      try {
                        // Run schema repair
                        await NPSDatabaseSchemaRepair.repairDatabase();
                        
                        // Close loading dialog
                        if (context.mounted) {
                          Navigator.pop(context);
                          
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('DATABASE REPAIRED! Restart app to sync servers, then NPS data will save properly!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 5),
                            ),
                          );
                        }
                      } catch (e) {
                        // Close loading dialog
                        if (context.mounted) {
                          Navigator.pop(context);
                          
                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Database repair failed: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                    },
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

  // ⭐ Phase 1.5: Database Sync Tool Methods

  /// Show sync status dialog with detailed information
  Future<void> _showSyncStatusDialog() async {
    final app = context.read<AppState>();
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking sync status...'),
          ],
        ),
      ),
    );
    
    try {
      final syncStatus = await DatabaseSyncService.instance.verifySyncStatus(app);
      final serverCounts = await ServerDataService.instance.getServerCountBySource();
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      
      // Show status dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                syncStatus['isSynced'] ? Icons.check_circle : Icons.warning,
                color: syncStatus['isSynced'] ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(syncStatus['isSynced'] ? 'All Synced' : 'Sync Issues'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusRow('AppState Servers', '${serverCounts['appState']}'),
                _buildStatusRow('NPS Database Servers', '${serverCounts['npsDatabase']}'),
                _buildStatusRow('Total Unified', '${serverCounts['total']}'),
                const Divider(),
                _buildStatusRow('Servers In Sync', '${syncStatus['serversInSync']}/${syncStatus['appServerCount']}'),
                _buildStatusRow('Sync Percentage', '${(syncStatus['syncPercentage'] as double).toStringAsFixed(1)}%'),
                if (syncStatus['missingFromNPS'].isNotEmpty) ...[
                  const Divider(),
                  const Text('Missing from NPS:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ...((syncStatus['missingFromNPS'] as List).map((id) => Text('  • $id'))),
                ],
                if (syncStatus['orphanedInNPS'].isNotEmpty) ...[
                  const Divider(),
                  const Text('Orphaned in NPS:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ...((syncStatus['orphanedInNPS'] as List).map((id) => Text('  • $id'))),
                ],
              ],
            ),
          ),
          actions: [
            if (!syncStatus['isSynced'])
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _autoFixSyncIssues();
                },
                icon: const Icon(Icons.healing),
                label: const Text('Auto-Fix'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking sync status: $e')),
      );
    }
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Perform manual sync of all servers
  Future<void> _performManualSync() async {
    final app = context.read<AppState>();
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Syncing servers...'),
          ],
        ),
      ),
    );
    
    try {
      final result = await DatabaseSyncService.instance.syncAllServersToNPS(app);
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      
      // Show result dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                result['success'] ? Icons.check_circle : Icons.warning,
                color: result['success'] ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text('Sync ${result['success'] ? 'Complete' : 'Completed with Errors'}'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusRow('Total Servers', '${result['total']}'),
              _buildStatusRow('Successfully Synced', '${result['synced']}'),
              _buildStatusRow('Inserted New', '${result['inserted']}'),
              _buildStatusRow('Updated Existing', '${result['updated']}'),
              _buildStatusRow('Errors', '${result['errors']}'),
              if (result['errors'] > 0) ...[
                const Divider(),
                const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ...((result['errorDetails'] as List).map((error) => Text('  • $error', style: const TextStyle(fontSize: 12)))),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    }
  }

  /// Show server data report from all sources
  Future<void> _showServerDataReport() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating report...'),
          ],
        ),
      ),
    );
    
    try {
      final report = await ServerDataService.instance.generateServerReport();
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      
      // Show report dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Server Data Report'),
          content: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                report,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  /// Auto-fix common sync issues
  Future<void> _autoFixSyncIssues() async {
    final app = context.read<AppState>();
    
    // Confirm action
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.healing, color: Colors.blue),
            SizedBox(width: 8),
            Text('Auto-Fix Sync Issues'),
          ],
        ),
        content: const Text(
          'This will automatically fix common synchronization problems:\n\n'
          '• Sync missing servers to NPS database\n'
          '• Update server ID mappings\n'
          '• Refresh data cache\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Fix Issues'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fixing issues...'),
          ],
        ),
      ),
    );
    
    try {
      final fixResult = await DatabaseSyncService.instance.autoFixSyncIssues(app);
      
      // Refresh ServerIdResolver
      final npsAdapter = NPSDatabaseAdapter(DatabaseFactory.instance);
      await ServerIdResolver.instance.initialize(app, npsAdapter);
      
      // Invalidate cache
      ServerDataService.instance.invalidateCache();
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      
      // Show result dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                fixResult['success'] ? Icons.check_circle : Icons.warning,
                color: fixResult['success'] ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              const Text('Auto-Fix Complete'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusRow('Fixes Applied', '${fixResult['fixCount']}'),
              const SizedBox(height: 12),
              if ((fixResult['fixesApplied'] as List).isNotEmpty) ...[
                const Text('Actions Taken:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...((fixResult['fixesApplied'] as List).map((fix) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text('✓ $fix', style: const TextStyle(fontSize: 12)),
                ))),
              ],
              const Divider(),
              _buildStatusRow('Before Sync', '${fixResult['beforeSync']['serversInSync']}/${fixResult['beforeSync']['appServerCount']}'),
              _buildStatusRow('After Sync', '${fixResult['afterSync']['serversInSync']}/${fixResult['afterSync']['appServerCount']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auto-fix failed: $e')),
      );
    }
  }
}
