import 'package:flutter/material.dart';
import 'backup_manager_screen.dart';
import 'usb_backup_screen.dart';
import 'local_backup_screen.dart';
import '../widgets/wallpaper_background.dart';

/// Unified Backup & Restore Screen
/// 
/// Provides access to all backup and restore options in one place
class UnifiedBackupScreen extends StatelessWidget {
  const UnifiedBackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: WallpaperBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.backup,
                            color: Theme.of(context).primaryColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Data Backup & Restore',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Choose your preferred backup method. All options include complete restaurant data including servers, shifts, NPS data, and settings.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Backup Options
              Text(
                'Backup Options',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Traditional Backup Manager
              Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(
                    Icons.cloud_upload,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  title: const Text(
                    'Quick Backup & Restore',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Create timestamped backups and restore from backup list',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BackupManagerScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // USB-C Flash Drive Backup
              Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(
                    Icons.usb,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  title: const Text(
                    'USB-C Flash Drive Backup',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Automatic backup to USB-C flash drive for easy data transfer',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const USBBackupScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Local Backup & Restore
              Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(
                    Icons.folder_open,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  title: const Text(
                    'Local Backup & Restore',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Save to selected folder or restore from selected file',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LocalBackupScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // What's Included
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What\'s Included in Backups',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'All backup methods include complete restaurant data:\n\n'
                        '• Server information and run counts\n'
                        '• Shift history and performance data\n'
                        '• NPS feedback and monthly reports\n'
                        '• Station assignments and analytics\n'
                        '• Gamification data and achievements\n'
                        '• App settings and preferences\n'
                        '• Admin preferences and PIN settings\n'
                        '• Avatar photos and customizations\n'
                        '• Complete SQLite database\n'
                        '• All generated reports and analytics\n\n'
                        'Note: You can cancel file selection at any time using the back button.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Usage Tips
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usage Tips',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• Quick Backup: Best for regular backups and easy restore\n'
                        '• USB-C Backup: Perfect for transferring data between devices\n'
                        '• Local Backup: Great for manual file management and archiving\n\n'
                        'All methods create identical backups - choose what works best for your workflow.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
