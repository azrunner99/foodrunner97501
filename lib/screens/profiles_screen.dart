import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../app_state.dart';
import '../storage.dart';
import '../gamification.dart';
import '../widgets/resilient_avatar.dart';
import '../theme/app_theme.dart';
import '../widgets/month_day_picker.dart';
import 'preset_avatar_gallery_screen.dart';
import 'profile_banner_screen.dart';
// import removed: achievementsCatalog no longer used

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final servers = app.servers;

    return Scaffold(
      appBar: AppBar(title: const Text('Server Profiles')),
      body: servers.isEmpty
          ? const Center(
              child: Text('No servers yet. Add from Assign or Manage.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: servers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) {
                final s = servers[i];
                final prof = app.profiles[s.id];
                final bannerPath = prof?.bannerPath;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProfileDetailScreen(serverId: s.id)),
                    );
                  },
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Banner background
                          Positioned.fill(
                            child: bannerPath != null && bannerPath.isNotEmpty
                                ? Image.asset(
                                    bannerPath,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.shade400,
                                            Colors.purple.shade400
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey.shade300,
                                          Colors.grey.shade500
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                          ),
                          // Gradient overlay for text readability
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.0),
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Content
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Avatar section
                                  SizedBox(
                                    width:
                                        100, // Increased width to accommodate level bubble
                                    height: 80,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          child: Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 3),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              radius: 37,
                                              backgroundImage: getResilientImageProvider(
                                                  prof?.avatarPath, 
                                                  isAvatar: true
                                              ),
                                              backgroundColor:
                                                  Colors.grey.shade300,
                                              child: prof?.avatarPath == null ||
                                                      prof!.avatarPath!.isEmpty
                                                  ? Icon(Icons.person,
                                                      size: 40,
                                                      color:
                                                          Colors.grey.shade600)
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        // Level bubble
                                        Positioned(
                                          bottom: 0,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              gradient: AppTheme
                                                  .getLevelBubbleGradient(
                                                      prof?.level ?? 1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 2),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              'Lvl${prof?.level ?? 1}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Server info
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.name,
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black
                                                    .withOpacity(0.7),
                                                offset: const Offset(1, 1),
                                                blurRadius: 3,
                                              ),
                                              Shadow(
                                                color: Colors.black
                                                    .withOpacity(0.5),
                                                offset: const Offset(2, 2),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 6),
                                        // XP Progress bar
                                        Container(
                                          height: 10,
                                          width: double.infinity,
                                          margin:
                                              const EdgeInsets.only(right: 20),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.4),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                                width: 1),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.6),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: prof != null
                                                ? () {
                                                    // Calculate progress same as home_screen.dart
                                                    final points = prof.points;
                                                    final lvl =
                                                        levelForPoints(points);
                                                    final prevLevelXp =
                                                        xpTable[lvl];
                                                    final nextLevelXp =
                                                        xpTable[lvl + 1];

                                                    if (nextLevelXp >
                                                        prevLevelXp) {
                                                      return ((points -
                                                                  prevLevelXp) /
                                                              (nextLevelXp -
                                                                  prevLevelXp))
                                                          .clamp(0.0, 1.0);
                                                    }
                                                    return 1.0;
                                                  }()
                                                : 0.0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white,
                                                    Colors.white
                                                        .withOpacity(0.9),
                                                  ],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.white
                                                        .withOpacity(0.6),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 0),
                                                  ),
                                                  BoxShadow(
                                                    color: Colors.white
                                                        .withOpacity(0.3),
                                                    blurRadius: 16,
                                                    offset: const Offset(0, 0),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        // XP Metrics
                                        prof != null
                                            ? () {
                                                final points = prof.points;
                                                final lvl =
                                                    levelForPoints(points);
                                                final nextLevelXp =
                                                    xpTable[lvl + 1];
                                                return Text(
                                                  '$points / $nextLevelXp XP',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.black
                                                            .withOpacity(0.8),
                                                        offset:
                                                            const Offset(1, 1),
                                                        blurRadius: 3,
                                                      ),
                                                      Shadow(
                                                        color: Colors.black
                                                            .withOpacity(0.6),
                                                        offset:
                                                            const Offset(2, 2),
                                                        blurRadius: 6,
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }()
                                            : const SizedBox.shrink(),
                                      ],
                                    ),
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
              },
            ),
    );
  }
}

class ProfileDetailScreen extends StatefulWidget {
  final String serverId;
  const ProfileDetailScreen({super.key, required this.serverId});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  @override
  void initState() {
    super.initState();
  }

  // Helper method to extract month name from birthday
  String _getBirthdayMonth(String birthday) {
    if (birthday.isEmpty) return '';

    try {
      final parts = birthday.split('/');
      if (parts.isNotEmpty) {
        final monthNum = int.parse(parts[0]);
        const months = [
          '',
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
        if (monthNum >= 1 && monthNum <= 12) {
          return months[monthNum];
        }
      }
    } catch (e) {
      // Invalid format, return empty
    }
    return '';
  }

  // Helper method to calculate tenure from hire date
  String _calculateTenure(String hireDate) {
    if (hireDate.isEmpty) return 'Not specified';

    try {
      final parts = hireDate.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final hireDateObj = DateTime(year, month, day);
        final now = DateTime.now();

        if (hireDateObj.isAfter(now)) {
          return 'Future hire date';
        }

        final difference = now.difference(hireDateObj);
        final totalDays = difference.inDays;

        // Calculate years, months, and remaining days
        final years = (totalDays / 365.25).floor();
        final remainingDaysAfterYears = totalDays - (years * 365.25).floor();
        final months = (remainingDaysAfterYears / 30.44).floor();
        final days = remainingDaysAfterYears - (months * 30.44).floor();

        List<String> tenureParts = [];

        if (years > 0) {
          tenureParts.add('$years year${years == 1 ? '' : 's'}');
        }
        if (months > 0) {
          tenureParts.add('$months month${months == 1 ? '' : 's'}');
        }
        if (days > 0) {
          tenureParts.add('$days day${days == 1 ? '' : 's'}');
        }

        if (tenureParts.isEmpty) {
          return 'Less than 1 day';
        }

        // Join parts with commas and "and" for the last item
        if (tenureParts.length == 1) {
          return tenureParts[0];
        } else if (tenureParts.length == 2) {
          return '${tenureParts[0]}, ${tenureParts[1]}';
        } else {
          return '${tenureParts[0]}, ${tenureParts[1]}, ${tenureParts[2]}';
        }
      }
    } catch (e) {
      // Invalid format
    }
    return 'Invalid hire date';
  }

  // Helper method to calculate average runs per shift from history
  double _calculateAvgRunsPerShift(AppState app, String serverId) {
    int totalRuns = 0;
    int totalShifts = 0;

    for (final shift in app.history) {
      final runs = shift.counts[serverId] ?? 0;
      if (runs > 0) {
        totalRuns += runs;
        totalShifts += 1;
      }
    }

    return totalShifts > 0 ? totalRuns / totalShifts : 0.0;
  }

  // Helper method to calculate average pizookie runs per shift from history
  double _calculateAvgPizookiePerShift(AppState app, String serverId) {
    int totalPizookieRuns = 0;
    int totalShifts = 0;

    for (final shift in app.history) {
      final pizookieRuns = shift.pizookieCounts[serverId] ?? 0;
      if (pizookieRuns > 0) {
        totalPizookieRuns += pizookieRuns;
        totalShifts += 1;
      }
    }

    return totalShifts > 0 ? totalPizookieRuns / totalShifts : 0.0;
  }

  // Enhanced metric card widget with modern design
  Widget metricCard(
      {required String label,
      required String value,
      required Color color,
      Widget? extra}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Color accent bar
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color,
                    color.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 22, // Increased from 18
                              color: color.withOpacity(0.9),
                              letterSpacing: 0.5,
                            )),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconForLabel(label),
                          size: 16,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(value,
                      style: const TextStyle(
                        fontSize: 28, // Increased from 24
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.2,
                      )),
                  if (extra != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: color.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: extra,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get appropriate icons for each metric
  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'tenure':
        return Icons.work_history;
      case 'current xp':
        return Icons.star;
      case 'all-time runs':
        return Icons.directions_run;
      case 'average runs per shift':
        return Icons.trending_up;
      case 'pizookie runs':
        return Icons.cookie;
      default:
        return Icons.analytics;
    }
  }

  // Small info card for basic stats
  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13, // Increased from 11
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16, // Increased from 14
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper method to build detail rows in metric cards
  Widget _buildDetailRow(List<Widget> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items,
    );
  }

  // Helper method to build individual detail items
  Widget _buildDetailItem(String label, String value,
      {bool highlight = false}) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              highlight ? Colors.black.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14, // Increased from 12
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 17, // Increased from 15
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                color: highlight ? Colors.black87 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatarPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      // Save photo to a unique file path
      final appDir = await getApplicationDocumentsDirectory();
      final uuid = Uuid().v4();
      final ext = pickedFile.path.split('.').last;
      final newPath = '${appDir.path}/avatar_${widget.serverId}_$uuid.$ext';
      await File(pickedFile.path).copy(newPath);
      await Storage.setAvatarPath(widget.serverId, newPath);
      // Save avatar path to ServerProfile for global access
      final app = Provider.of<AppState>(context, listen: false);
      app.updateAvatar(widget.serverId, newPath);
      // Removed 'Show on Server Button?' dialog
    }
  }

  Future<void> _onAvatarTap() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        // No title
        backgroundColor: Colors.grey[100],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  minimumSize: const Size(120, 40),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, 'replace'),
                child: const Text('Take Photo'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  minimumSize: const Size(180, 40),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, 'presets'),
                child: const Text('Select From Presets'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  minimumSize: const Size(120, 40),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, 'remove'),
                child: const Text('Remove'),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Colors.grey),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (result == 'replace') {
      await _pickAvatarPhoto();
    } else if (result == 'presets') {
      // Navigate to preset avatar gallery screen
      final selected = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => PresetAvatarGalleryScreen(
            currentServerId: widget.serverId,
            onAvatarSelected: (path) async {
              final app = Provider.of<AppState>(context, listen: false);
              app.updateAvatar(widget.serverId, path);
              await Storage.setAvatarPath(widget.serverId, path);
              Navigator.pop(context, path);
            },
          ),
        ),
      );
      if (selected != null && selected.isNotEmpty) {
        // Avatar updated through AppState - no local state needed
      }
    } else if (result == 'remove') {
      final app = Provider.of<AppState>(context, listen: false);
      app.updateAvatar(widget.serverId, '');
    }
  }

  Future<void> _editBirthday(BuildContext context, String serverId) async {
    final date = await showMonthDayPicker(
      context: context,
      initialDate: DateTime(DateTime.now().year, 1, 1),
      helpText: 'Select Birthday',
      cancelText: 'Cancel',
      confirmText: 'Save',
    );

    if (date != null) {
      final birthday =
          '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

      // Update the profile with the new birthday
      final app = Provider.of<AppState>(context, listen: false);
      final currentProfile = app.profiles[serverId] ?? ServerProfile();
      final updatedProfile = currentProfile.copyWith(birthday: birthday);
      await app.updateServerProfile(serverId, updatedProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.serverById(widget.serverId);
    final p = app.profiles[widget.serverId];

    if (s == null || p == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Server not found.')),
      );
    }

    final repeatCounts = <String, int>{};
    for (final key in p.repeatEarnedDates) {
      final id = key.split('_').first;
      repeatCounts[id] = (repeatCounts[id] ?? 0) + 1;
    }

    // Calculate team totals for all-time and pizookie runs
    final teamAllTimeRuns =
        app.profiles.values.fold<int>(0, (sum, prof) => sum + prof.allTimeRuns);
    final teamPizookieRuns = app.profiles.values
        .fold<int>(0, (sum, prof) => sum + prof.pizookieRuns);
    final allTimePct = teamAllTimeRuns > 0
        ? ((p.allTimeRuns / teamAllTimeRuns) * 100).toStringAsFixed(1)
        : '0';
    final pizookiePct = teamPizookieRuns > 0
        ? ((p.pizookieRuns / teamPizookieRuns) * 100).toStringAsFixed(1)
        : '0';

    // Calculate ranks for all-time runs and pizookie runs
    List<ServerProfile> sortedAllTime = app.profiles.values.toList()
      ..sort((a, b) => b.allTimeRuns.compareTo(a.allTimeRuns));
    List<ServerProfile> sortedPizookie = app.profiles.values.toList()
      ..sort((a, b) => b.pizookieRuns.compareTo(a.pizookieRuns));
    int allTimeRank = sortedAllTime.indexWhere((prof) => prof == p) + 1;
    int pizookieRank = sortedPizookie.indexWhere((prof) => prof == p) + 1;

    // Badge logic removed
    final totalServers = app.profiles.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                // Add Profile Banner text
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProfileBannerScreen(serverId: widget.serverId),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      p.bannerPath != null
                          ? 'Change Profile Banner'
                          : 'Add Profile Banner',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Banner section with avatar and name overlay - full width
          SizedBox(
            width: double.infinity,
            height: 240, // Height to accommodate avatar + name + spacing
            child: Stack(
              children: [
                // Banner background - full width, no rounded corners
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: p.bannerPath != null
                      ? Image.asset(
                          p.bannerPath!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to gradient if banner fails to load
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.deepPurple.shade300,
                                    Colors.blue.shade400,
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.deepPurple.shade300,
                                Colors.blue.shade400,
                              ],
                            ),
                          ),
                        ),
                ),
                // Semi-transparent overlay for better text readability
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
                // Avatar and name overlay
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar with level badge
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            onTap: _onAvatarTap,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.deepPurple.shade100,
                                backgroundImage: getResilientImageProvider(
                                    p.avatarPath, 
                                    isAvatar: true
                                ),
                                child: (p.avatarPath == null ||
                                        p.avatarPath!.isEmpty)
                                    ? null
                                    : (p.avatarPath!.startsWith('assets/')
                                        ? ClipOval(
                                            child: Image.asset(p.avatarPath!,
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover))
                                        : null),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                gradient:
                                    AppTheme.getLevelBubbleGradient(p.level),
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Lvl${p.level}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Server name with enhanced contrast styling - no bubble background
                      Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                            Shadow(
                              color: Colors.black,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                            // Additional shadow for extra contrast
                            Shadow(
                              color: Colors.black,
                              blurRadius: 20,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Enhanced info section with cards
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _infoCard(
                        icon: Icons.star,
                        label: 'Points',
                        value: '${p.points}',
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoCard(
                        icon: Icons.trending_up,
                        label: 'Next Level',
                        value: '${p.nextLevelAt}',
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _infoCard(
                        icon: Icons.emoji_events,
                        label: 'MVP Awards',
                        value: '${p.shiftsAsMvp}',
                        color: Colors.orange,
                      ),
                    ),
                    if (p.hireDate.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoCard(
                          icon: Icons.calendar_today,
                          label: 'Hired',
                          value: p.hireDate,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
                if (p.birthday.isNotEmpty || p.birthday.isEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.pink.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.cake,
                              color: Colors.pink.shade400, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Birthday',
                                style: TextStyle(
                                  fontSize: 14, // Increased from 12
                                  fontWeight: FontWeight.w600,
                                  color: Colors.pink.shade400,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.birthday.isNotEmpty
                                    ? _getBirthdayMonth(p.birthday)
                                    : 'Not set',
                                style: const TextStyle(
                                  fontSize: 16, // Increased from 14
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _editBirthday(context, widget.serverId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.pink.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              p.birthday.isNotEmpty ? 'Edit' : 'Add',
                              style: TextStyle(
                                fontSize: 14, // Increased from 12
                                fontWeight: FontWeight.w600,
                                color: Colors.pink.shade600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Tenure card - show employment length
          if (p.hireDate.isNotEmpty)
            metricCard(
              label: 'Tenure',
              value: _calculateTenure(p.hireDate),
              color: Colors.orange,
            ),
          // XP card
          metricCard(
            label: 'Current XP',
            value: '${p.points} points',
            color: Colors.purple,
            extra: _buildDetailRow([
              _buildDetailItem('Level ${p.level}', 'Current'),
              _buildDetailItem('Next level', '${p.nextLevelAt} XP',
                  highlight: true),
            ]),
          ),
          // Remove the metricCard for 'Points'
          metricCard(
            label: 'All-time Runs',
            value: '${p.allTimeRuns}',
            color: Colors.blue,
            extra: Column(
              children: [
                _buildDetailRow([
                  _buildDetailItem('Best shift', '${p.bestShiftRuns}'),
                  _buildDetailItem('Team share', '$allTimePct%'),
                ]),
                const SizedBox(height: 8),
                _buildDetailRow([
                  _buildDetailItem('Rank', '$allTimeRank/$totalServers',
                      highlight: true),
                ]),
              ],
            ),
          ),
          metricCard(
            label: 'Average Runs Per Shift',
            value:
                '${_calculateAvgRunsPerShift(app, widget.serverId).toStringAsFixed(1)} runs',
            color: Colors.green,
            extra: _buildDetailRow([
              _buildDetailItem('Shifts worked',
                  '${app.history.where((shift) => (shift.counts[widget.serverId] ?? 0) > 0).length}'),
              if (p.bestShiftRuns > 0)
                _buildDetailItem('Personal best', '${p.bestShiftRuns}',
                    highlight: true),
            ]),
          ),
          metricCard(
            label: 'Pizookie Runs',
            value: '${p.pizookieRuns}',
            color: Colors.pink,
            extra: Column(
              children: [
                _buildDetailRow([
                  _buildDetailItem('Team share', '$pizookiePct%'),
                  _buildDetailItem('Rank', '$pizookieRank/$totalServers',
                      highlight: true),
                ]),
                const SizedBox(height: 8),
                _buildDetailRow([
                  _buildDetailItem('Avg per shift',
                      '${_calculateAvgPizookiePerShift(app, widget.serverId).round()}'),
                ]),
              ],
            ),
          ),
          // Remove the metricCard for 'MVP Awards'
          // metricCard(
          //   icon: Icons.military_tech,
          //   label: 'MVP Awards',
          //   value: '${p.shiftsAsMvp}',
          //   color: Colors.orange,
          // ),
        ],
      ),
    );
  }

  // Badge list methods removed
}
