import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class MvpScreen extends StatelessWidget {
  const MvpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final servers = app.servers;

    final totalAllTime = app.totals.values.fold<int>(0, (a, b) => a + b);

    // Build list of entries with share; sort by share desc, then by runs desc, then name.
    final entries = servers.map((s) {
      final runs = app.totals[s.id] ?? 0;
      final pct = totalAllTime > 0 ? (runs * 100.0 / totalAllTime) : 0.0;
      return _Entry(name: s.name, runs: runs, pct: pct, id: s.id);
    }).toList()
      ..sort((a, b) {
        final c = b.pct.compareTo(a.pct);
        if (c != 0) return c;
        final d = b.runs.compareTo(a.runs);
        if (d != 0) return d;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return Scaffold(
      appBar: AppBar(title: const Text('MVP Rankings (All-time %)')),
      body: entries.isEmpty
          ? const Center(child: Text('No data yet. Run a shift first.'))
          : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = entries[i];
                final rank = i + 1;
                final leading = rank <= 3
                    ? Icon(Icons.emoji_events,
                        color: rank == 1
                            ? Colors.amber[700]
                            : rank == 2
                                ? Colors.grey[500]
                                : Colors.brown[400])
                    : CircleAvatar(
                        backgroundColor: Colors.black12,
                        child: Text(rank.toString()),
                      );

                return ListTile(
                  leading: leading,
                  title: Text(e.name),
                  subtitle: Text('All-time: ${e.runs} • Share: ${e.pct.toStringAsFixed(1)}%'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Optional: jump to that profile
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _QuickProfileView(name: e.name, runs: e.runs, pct: e.pct),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _Entry {
  final String id;
  final String name;
  final int runs;
  final double pct;
  _Entry({required this.id, required this.name, required this.runs, required this.pct});
}

class _QuickProfileView extends StatelessWidget {
  final String name;
  final int runs;
  final double pct;
  const _QuickProfileView({super.key, required this.name, required this.runs, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('All-time runs: $runs', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('All-time % of team runs: ${pct.toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }
}
