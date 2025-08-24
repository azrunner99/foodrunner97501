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
          ? const Center(child: Text('No data yet.'))
          : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = entries[i];
                final rank = i + 1;
                final leading = rank <= 3
                    ? Icon(Icons.emoji_events,
                        color: rank == 1
                            ? Colors.amber[700]
                            : rank == 2
                                ? Colors.grey[500]
                                : Colors.brown[400])
                    : CircleAvatar(backgroundColor: Colors.black12, child: Text(rank.toString()));

                return ListTile(
                  leading: leading,
                  title: Text(e.name),
                  subtitle: Text('All-time: ${e.runs} • Share: ${e.pct.toStringAsFixed(1)}%'),
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
