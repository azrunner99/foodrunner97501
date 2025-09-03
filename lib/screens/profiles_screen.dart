import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../app_state.dart';
import 'preset_avatar_gallery_screen.dart';
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
              itemCount: servers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = servers[i];
                final prof = app.profiles[s.id];
                final level = prof?.level ?? 1;
                final runs = prof?.allTimeRuns ?? 0;
                final pizookies = prof?.pizookieRuns ?? 0;
                return ListTile(
                  title: Text(s.name),
                  subtitle: Text('Level $level • All-time runs: $runs (includes $pizookies Pizookies)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProfileDetailScreen(serverId: s.id)),
                    );
                  },
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
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _avatarPath = prefs.getString('avatar_${widget.serverId}');
    });
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
      setState(() {
        _avatarPath = newPath;
      });
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
        setState(() {}); // Force rebuild to refresh avatar
      }
    } else if (result == 'remove') {
      final app = Provider.of<AppState>(context, listen: false);
      app.updateAvatar(widget.serverId, '');
      setState(() {
        _avatarPath = null;
      });
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: _onAvatarTap,
          child: CircleAvatar(
          radius: 80,
          backgroundColor: Colors.deepPurple.shade100,
          child: (p.avatarPath == null || p.avatarPath!.isEmpty)
            ? null
            : (p.avatarPath!.startsWith('assets/')
              ? ClipOval(child: Image.asset(p.avatarPath!, width: 160, height: 160, fit: BoxFit.cover))
              : null),
          backgroundImage: (p.avatarPath != null && p.avatarPath!.isNotEmpty && !p.avatarPath!.startsWith('assets/'))
            ? FileImage(File(p.avatarPath!))
            : null,
          ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Lvl${p.level}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              s.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 32),
            ),
          ),
          const SizedBox(height: 8),
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
