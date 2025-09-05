import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../app_state.dart';
import '../gamification.dart';
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
          ? const Center(child: Text('No servers yet. Add from Assign or Manage.'))
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
                      MaterialPageRoute(builder: (_) => ProfileDetailScreen(serverId: s.id)),
                    );
                  },
                  child: Container(
                    height: 120,
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
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.blue.shade400, Colors.purple.shade400],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                        ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.grey.shade300, Colors.grey.shade500],
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
                                  Container(
                                    width: 100, // Increased width to accommodate level bubble
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
                                              border: Border.all(color: Colors.white, width: 3),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              radius: 37,
                                              backgroundImage: prof?.avatarPath != null && prof!.avatarPath!.isNotEmpty
                                                  ? (prof.avatarPath!.startsWith('assets/')
                                                      ? AssetImage(prof.avatarPath!)
                                                      : FileImage(File(prof.avatarPath!))) as ImageProvider
                                                  : null,
                                              backgroundColor: Colors.grey.shade300,
                                              child: prof?.avatarPath == null || prof!.avatarPath!.isEmpty
                                                  ? Icon(Icons.person, size: 40, color: Colors.grey.shade600)
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        // Level bubble
                                        Positioned(
                                          bottom: 0,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade600,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.white, width: 2),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.3),
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
                                                fontSize: 12
                                              ),
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.name,
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.7),
                                                offset: const Offset(1, 1),
                                                blurRadius: 3,
                                              ),
                                              Shadow(
                                                color: Colors.black.withOpacity(0.5),
                                                offset: const Offset(2, 2),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // XP Progress bar
                                        Container(
                                          height: 10,
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(right: 20),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.4),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.6),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
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
                                                    final lvl = levelForPoints(points);
                                                    final prevLevelXp = xpTable[lvl];
                                                    final nextLevelXp = xpTable[lvl + 1];
                                                    
                                                    if (nextLevelXp > prevLevelXp) {
                                                      return ((points - prevLevelXp) / (nextLevelXp - prevLevelXp)).clamp(0.0, 1.0);
                                                    }
                                                    return 1.0;
                                                  }()
                                                : 0.0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white,
                                                    Colors.white.withOpacity(0.9),
                                                  ],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                ),
                                                borderRadius: BorderRadius.circular(4),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.white.withOpacity(0.6),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 0),
                                                  ),
                                                  BoxShadow(
                                                    color: Colors.white.withOpacity(0.3),
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
                                                final lvl = levelForPoints(points);
                                                final nextLevelXp = xpTable[lvl + 1];
                                                return Text(
                                                  '$points / $nextLevelXp XP',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.black.withOpacity(0.8),
                                                        offset: const Offset(1, 1),
                                                        blurRadius: 3,
                                                      ),
                                                      Shadow(
                                                        color: Colors.black.withOpacity(0.6),
                                                        offset: const Offset(2, 2),
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

  // Badge mode removed
  // Metric card widget for visual separation
  Widget metricCard({required String label, required String value, required Color color, Widget? extra}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 14, color: Colors.black)),
                if (extra != null) ...[
                  const SizedBox(height: 2),
                  extra,
                ],
              ],
            ),
          ),
        ],
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('avatar_${widget.serverId}', newPath);
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
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  minimumSize: const Size(120, 40),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  minimumSize: const Size(180, 40),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  minimumSize: const Size(120, 40),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
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
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('avatar_${widget.serverId}', path);
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

    String _formatMinSec(double seconds) {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      return '${mins}:${secs.toStringAsFixed(0).padLeft(2, '0')} min:sec';
    }

    final avg = p.avgSecondsBetweenRuns;
    final avgStr = avg <= 0 ? '—' : _formatMinSec(avg);

    final repeatCounts = <String, int>{};
    for (final key in p.repeatEarnedDates) {
      final id = key.split('_').first;
      repeatCounts[id] = (repeatCounts[id] ?? 0) + 1;
    }

    // Calculate team totals for all-time and pizookie runs
    final teamAllTimeRuns = app.profiles.values.fold<int>(0, (sum, prof) => sum + prof.allTimeRuns);
    final teamPizookieRuns = app.profiles.values.fold<int>(0, (sum, prof) => sum + prof.pizookieRuns);
    final allTimePct = teamAllTimeRuns > 0 ? ((p.allTimeRuns / teamAllTimeRuns) * 100).toStringAsFixed(1) : '0';
    final pizookiePct = teamPizookieRuns > 0 ? ((p.pizookieRuns / teamPizookieRuns) * 100).toStringAsFixed(1) : '0';

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
                        builder: (_) => ProfileBannerScreen(serverId: widget.serverId),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      p.bannerPath != null ? 'Change Profile Banner' : 'Add Profile Banner',
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
          Container(
            width: double.infinity,
            height: 240, // Height to accommodate avatar + name + spacing
            child: Stack(
              children: [
                // Banner background - full width, no rounded corners
                Container(
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
                                child: (p.avatarPath == null || p.avatarPath!.isEmpty)
                                  ? null
                                  : (p.avatarPath!.startsWith('assets/')
                                    ? ClipOval(child: Image.asset(p.avatarPath!, width: 120, height: 120, fit: BoxFit.cover))
                                    : null),
                                backgroundImage: (p.avatarPath != null && p.avatarPath!.isNotEmpty && !p.avatarPath!.startsWith('assets/'))
                                  ? FileImage(File(p.avatarPath!))
                                  : null,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white, width: 2),
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
                                  fontSize: 14
                                ),
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
          const SizedBox(height: 20),
          Center(
            child: Text(
              '${p.points} points • Next level at: ${p.nextLevelAt}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'MVP: ${p.shiftsAsMvp}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
          ),
          const SizedBox(height: 24),
          // Remove the metricCard for 'Points'
          metricCard(
            label: 'All-time Runs',
            value: '${p.allTimeRuns} • Best shift: ${p.bestShiftRuns}',
            color: Colors.blue,
            extra: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$allTimePct% of team', style: const TextStyle(fontSize: 16)),
                Text('Rank: $allTimeRank/$totalServers', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          metricCard(
            label: 'Pizookie Runs',
            value: '${p.pizookieRuns}',
            color: Colors.pink,
            extra: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$pizookiePct% of team', style: const TextStyle(fontSize: 16)),
                Text('Rank: $pizookieRank/$totalServers', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          metricCard(
            label: 'Average Time Between Runs',
            value: avgStr,
            color: Colors.green,
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
