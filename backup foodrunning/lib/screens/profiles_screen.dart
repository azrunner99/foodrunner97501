import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../gamification.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final servers = app.servers;
    final allTimeTeamTotal = app.totals.values.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(title: const Text('Profiles')),
      body: ListView.separated(
        itemCount: servers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final s = servers[i];
          final p = app.profiles[s.id];
          final myAllTime = (app.totals[s.id] ?? 0);
          final share = allTimeTeamTotal > 0 ? (myAllTime * 100.0 / allTimeTeamTotal) : 0.0;

          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(s.name),
            subtitle: Text(
              'All-time: ${p?.allTimeRuns ?? myAllTime} • Best shift: ${p?.bestShiftRuns ?? 0} • Best streak: ${p?.streakBest ?? 0} • MVPs: ${p?.shiftsAsMvp ?? 0}\n'
              'All-time % of team runs: ${share.toStringAsFixed(1)}%',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => _ProfileDetail(serverId: s.id, name: s.name),
            )),
          );
        },
      ),
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  final String serverId;
  final String name;
  const _ProfileDetail({required this.serverId, required this.name});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final p = app.profiles[serverId];
    final myAllTime = (app.totals[serverId] ?? 0);
    final allTimeTeamTotal = app.totals.values.fold<int>(0, (a, b) => a + b);
    final share = allTimeTeamTotal > 0 ? (myAllTime * 100.0 / allTimeTeamTotal) : 0.0;

    final got = (p?.achievements ?? <String>{}).toSet();

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _StatRow(label: 'All-time runs', value: myAllTime.toString()),
            _StatRow(label: 'All-time % of team runs', value: '${share.toStringAsFixed(1)}%'),
            _StatRow(label: 'Best shift', value: (p?.bestShiftRuns ?? 0).toString()),
            _StatRow(label: 'Best streak', value: (p?.streakBest ?? 0).toString()),
            _StatRow(label: 'MVP awards', value: (p?.shiftsAsMvp ?? 0).toString()),
            const SizedBox(height: 16),
            Text('Badges & Achievements', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in achievementsCatalog)
                  Chip(
                    label: Text(a.title),
                    avatar: Icon(
                      got.contains(a.id) ? Icons.emoji_events : Icons.lock_outline,
                      color: got.contains(a.id) ? Colors.amber[700] : Colors.grey,
                    ),
                    backgroundColor: got.contains(a.id) ? Colors.amber.withOpacity(0.15) : null,
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
