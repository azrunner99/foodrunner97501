import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_state.dart';

class MvpScreen extends StatelessWidget {
  const MvpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final servers = app.servers;
    final totalAllTime = app.totals.values.fold<int>(0, (a, b) => a + b);

    return FutureBuilder<Map<String, String?>> (
      future: _loadAllAvatars(servers),
      builder: (context, snapshot) {
        final avatarMap = snapshot.data ?? {};
        final entries = servers.map((s) {
          final runs = app.totals[s.id] ?? 0;
          final pct = totalAllTime > 0 ? (runs * 100.0 / totalAllTime) : 0.0;
          final pizookieRuns = app.profiles[s.id]?.pizookieRuns ?? 0;
          final totalPizookie = app.profiles.values.fold<int>(0, (a, b) => a + b.pizookieRuns);
          final pizookieShare = totalPizookie > 0 ? (pizookieRuns * 100.0 / totalPizookie) : 0.0;
          final shiftsAsMvp = app.profiles[s.id]?.shiftsAsMvp ?? 0;
          final avatarPath = avatarMap[s.id];
          return _Entry(
            name: s.name,
            runs: runs,
            pct: pct,
            id: s.id,
            pizookieRuns: pizookieRuns,
            pizookieShare: pizookieShare,
            shiftsAsMvp: shiftsAsMvp,
            avatarPath: avatarPath,
          );
        }).toList()
          ..sort((a, b) {
            final c = b.pct.compareTo(a.pct);
            if (c != 0) return c;
            final d = b.runs.compareTo(a.runs);
            if (d != 0) return d;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

        return Scaffold(
          appBar: AppBar(title: const Text('Leaderboard')),
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

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      child: Row(
                        children: [
                          leading,
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.name,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                Text('All-time Runs: ${e.runs}', style: const TextStyle(fontSize: 12)),
                                Text('Share: ${e.pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 8),
                                Text('Pizookie Runs: ${e.pizookieRuns}', style: const TextStyle(fontSize: 12)),
                                Text('Pizookie Share: ${e.pizookieShare.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 8),
                                Text('MVP Awards: ${e.shiftsAsMvp}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildAvatar(e.avatarPath),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Future<Map<String, String?>> _loadAllAvatars(List servers) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String?> avatarMap = {};
    for (var s in servers) {
      avatarMap[s.id] = prefs.getString('avatar_${s.id}');
    }
    return avatarMap;
  }

  Widget _buildAvatar(String? avatarPath) {
    if (avatarPath != null && avatarPath.isNotEmpty) {
      return CircleAvatar(
        radius: 36, // Increased from 24 to 36 for larger avatar
        backgroundImage: FileImage(File(avatarPath)),
      );
    }
    return const SizedBox(width: 72); // Increased width for alignment
  }
}

class _Entry {
  final String id;
  final String name;
  final int runs;
  final double pct;
  final int pizookieRuns;
  final double pizookieShare;
  final int shiftsAsMvp;
  final String? avatarPath;
  _Entry({
    required this.id,
    required this.name,
    required this.runs,
    required this.pct,
    this.pizookieRuns = 0,
    this.pizookieShare = 0.0,
    this.shiftsAsMvp = 0,
    this.avatarPath,
  });
}
