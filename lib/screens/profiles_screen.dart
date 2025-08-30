import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
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
  // Badge mode removed
  // Metric card widget for visual separation
  Widget metricCard({required IconData icon, required String label, required String value, required Color color}) {
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
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 18, color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
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

    final avg = p.avgSecondsBetweenRuns;
    final avgStr = avg <= 0 ? '—' : '${avg.toStringAsFixed(1)} sec/run';

    final repeatCounts = <String, int>{};
    for (final key in p.repeatEarnedDates) {
      final id = key.split('_').first;
      repeatCounts[id] = (repeatCounts[id] ?? 0) + 1;
    }

  // Badge logic removed

    return Scaffold(
      appBar: AppBar(title: Text(s.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: Colors.deepPurple.shade100,
              child: Text(
                p.level.toString(),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
            ),
          ),
          const SizedBox(height: 24),
          metricCard(
            icon: Icons.star,
            label: 'Level',
            value: 'Level ${p.level}',
            color: Colors.deepPurple,
          ),
          metricCard(
            icon: Icons.emoji_events,
            label: 'Points',
            value: '${p.points}  •  Next at: ${p.nextLevelAt}',
            color: Colors.amber.shade700,
          ),
          metricCard(
            icon: Icons.directions_run,
            label: 'All-time Runs',
            value: '${p.allTimeRuns}  •  Best shift: ${p.bestShiftRuns}',
            color: Colors.blue,
          ),
          metricCard(
            icon: Icons.cake,
            label: 'Pizookie Runs',
            value: '${p.pizookieRuns} (Included in All-Time-Runs)',
            color: Colors.pink,
          ),
          metricCard(
            icon: Icons.timer,
            label: 'Avg Frequency',
            value: avgStr,
            color: Colors.green,
          ),
          metricCard(
            icon: Icons.military_tech,
            label: 'MVP Awards',
            value: '${p.shiftsAsMvp}',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  // Badge list methods removed
}
