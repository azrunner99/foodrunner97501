import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../gamification.dart'; // achievementsCatalog

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
  String _mode = 'earned'; // 'earned' or 'available'

  AchievementDef? _findDef(String id) {
    for (final d in achievementsCatalog) {
      if (d.id == id) return d;
    }
    return null;
  }

  String _descFor(String id) {
    switch (id) {
      case 'first_run':
        return 'Your first food run ever.';
      case 'first_run_today':
        return 'First food run of the day.';
      case 'three_streak':
        return '3 runs in a row without a decrement.';
      case 'five_streak':
        return '5 runs in a row without a decrement.';
      case 'ten_in_shift':
        return '10 runs in a single shift.';
      case 'twenty_in_shift':
        return '20 runs in a single shift.';
      case 'night_owl':
        return 'Run food after 11:00 PM.';
      case 'fifty_all_time':
        return '50 total runs across all time.';
      case 'hundred_all_time':
        return '100 total runs across all time.';
      case 'mvp':
        return 'Most runs on a completed shift.';
      case 'team_goal':
        return 'Team hit the shift goal.';
      case 'lunch_peak_10':
        return '10 runs during lunch peak (12:30–2:00).';
      case 'dinner_peak_10':
        return '10 runs during dinner peak (6:30–8:00).';
      case 'lunch_closer_8':
        return '8 runs in lunch close (2:30–3:30).';
      case 'dinner_closer_8':
        return '8 runs in dinner close (9:00–close).';
      default:
        return 'Earn this badge by hitting its target during service.';
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

    final avg = p.avgSecondsBetweenRuns;
    final avgStr = avg <= 0 ? '—' : '${avg.toStringAsFixed(1)} sec/run';

    final repeatCounts = <String, int>{};
    for (final key in p.repeatEarnedDates) {
      final id = key.split('_').first;
      repeatCounts[id] = (repeatCounts[id] ?? 0) + 1;
    }

    // Build "available" with POSitional records: (AchievementDef, bool earned, int times)
    final earnedSet = p.achievements.toSet();
    final List<(AchievementDef, bool, int)> available = achievementsCatalog
        .map<(AchievementDef, bool, int)>((def) {
          final times = repeatCounts[def.id] ?? 0;
          final earnedOnce = earnedSet.contains(def.id) || times > 0;
          return (def, earnedOnce, times);
        })
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(p.level.toString())),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level ${p.level}', style: Theme.of(context).textTheme.titleLarge),
                    Text('Points: ${p.points}  •  Next at: ${p.nextLevelAt}'),
                    Text('All-time runs: ${p.allTimeRuns}  •  Best shift: ${p.bestShiftRuns}'),
                    Text('Avg frequency: $avgStr'),
                    Text('MVP awards: ${p.shiftsAsMvp}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'earned', label: Text('Earned')),
              ButtonSegment(value: 'available', label: Text('Available')),
            ],
            selected: <String>{_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 12),
          if (_mode == 'earned')
            ..._earnedBadgesList(p, repeatCounts)
          else
            ..._availableList(available),
        ],
      ),
    );
  }

  List<Widget> _earnedBadgesList(ServerProfile p, Map<String, int> repeatCounts) {
    final tiles = <Widget>[];

    for (final id in p.achievements) {
      final def = _findDef(id);
      tiles.add(ListTile(
        leading: const Icon(Icons.verified, color: Colors.amber),
        title: Text(def?.title ?? 'Unknown'),
        subtitle: Text('${def?.points ?? 0} pts • ${_descFor(id)}'),
      ));
    }

    repeatCounts.forEach((id, times) {
      final def = _findDef(id);
      tiles.add(ListTile(
        leading: const Icon(Icons.auto_awesome, color: Colors.lightBlue),
        title: Text(def?.title ?? 'Unknown'),
        subtitle: Text('${def?.points ?? 0} pts • x$times • ${_descFor(id)}'),
      ));
    });

    if (tiles.isEmpty) {
      tiles.add(const ListTile(title: Text('No badges yet.')));
    }
    return tiles;
  }

  // Accept positional-record list
  List<Widget> _availableList(List<(AchievementDef, bool, int)> items) {
    return items.map((t) {
      final def = t.$1;
      final earned = t.$2;
      final times = t.$3;
      final trailing = earned
          ? Text(times > 0 ? 'x$times' : 'Earned', style: const TextStyle(color: Colors.green))
          : Text('${def.points} pts', style: const TextStyle(color: Colors.blueGrey));
      return ListTile(
        leading: Icon(earned ? Icons.emoji_events : Icons.emoji_events_outlined,
            color: earned ? Colors.green : null),
        title: Text(def.title),
        subtitle: Text(_descFor(def.id)),
        trailing: trailing,
      );
    }).toList();
  }
}
