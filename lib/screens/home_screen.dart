import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';

// Screens
import 'update_roster_screen.dart';
import 'admin_screen.dart';
import 'profiles_screen.dart';
import 'settings_screen.dart';
import 'mvp_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('BJ’s Food Runs'),
        actions: [
          // Single entry point to manage roster (Lunch/Dinner columns, all servers)
          IconButton(
            tooltip: 'Active Roster',
            icon: const Icon(Icons.group),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpdateRosterScreen()),
              );
            },
          ),
          // Admin tools (pause/resume/end day, integrity view, manage servers)
          IconButton(
            tooltip: 'Admin',
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              );
            },
          ),
          // Everything else
          PopupMenuButton<_MoreAction>(
            tooltip: 'More',
            onSelected: (a) {
              switch (a) {
                case _MoreAction.profiles:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilesScreen()),
                  );
                  break;
                case _MoreAction.settings:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  break;
                case _MoreAction.mvp:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MvpScreen()),
                  );
                  break;
                case _MoreAction.history:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: _MoreAction.profiles,
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profiles'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _MoreAction.mvp,
                child: ListTile(
                  leading: Icon(Icons.emoji_events),
                  title: Text('MVP Board'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _MoreAction.history,
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Shift History'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _MoreAction.settings,
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _Body(app: app),
    );
  }
}

enum _MoreAction { profiles, settings, mvp, history }

class _Body extends StatelessWidget {
  final AppState app;
  const _Body({required this.app});

  @override
  Widget build(BuildContext context) {
    // Idle billboard before any shift is running
    if (!app.shiftActive && !app.shiftPaused) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Who’s Working Today?",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ) ??
                    const TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                "Manager: assign servers to Lunch and Dinner to begin.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.group),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('Open Active Roster'),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpdateRosterScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    // Active-shift grid UI
    return const _ActiveGrid();
  }
}

class _ActiveGrid extends StatelessWidget {
  const _ActiveGrid();

  Color _tierColor(int my, int max) {
    if (max <= 0) return Colors.grey.shade400;
    final ratio = my / max;
    // two greens (top), yellow (mid), two reds (low)
    if (ratio >= 1.0) return const Color(0xFF145A32); // deep green
    if (ratio >= 0.75) return const Color(0xFF2ECC71); // green
    if (ratio >= 0.50) return const Color(0xFFF1C40F); // yellow
    if (ratio >= 0.25) return const Color(0xFFE67E22); // orange-red
    return const Color(0xFFC0392B); // red
  }

  static const encouragements = [
    "Fast feet, happy guests.",
    "You just carried joy on a plate.",
    "That run was smoother than nitro.",
    "Guests are smiling because of you.",
    "Service hero move right there.",
    "From expo to table like lightning.",
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final ids = app.workingServerIds.toList();
    final counts = ids.map((id) => app.currentCounts[id] ?? 0).toList();
    final maxCount = counts.isEmpty ? 0 : counts.reduce(max);
    final total = counts.fold<int>(0, (a, b) => a + b);

    // Tablet friendly layout
    final columns = MediaQuery.of(context).size.width > 800 ? 4 : 2;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        itemCount: ids.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemBuilder: (ctx, i) {
          final id = ids[i];
          final s = app.serverById(id);
          if (s == null) return const SizedBox.shrink();

          final my = app.currentCounts[id] ?? 0;
          final all = app.allTimeFor(id);
          final pct = total == 0 ? 0 : ((my / total) * 100).round();
          final color = _tierColor(my, maxCount);
          final level = app.profiles[id]?.level ?? 1;

          return GestureDetector(
            onLongPress: () => app.decrement(id),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(12),
              ),
              onPressed: () {
                app.increment(id);

                // encouragement bubble ~3s
                final msg = encouragements[Random().nextInt(encouragements.length)];
                ScaffoldMessenger.of(ctx).clearSnackBars();
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
                );

                // badge bubble (if any)
                final bubble = app.recentBadgeBubble;
                if (bubble != null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(bubble), duration: const Duration(seconds: 3)),
                  );
                  app.clearRecentBadgeBubble();
                }
              },
              child: Stack(
                children: [
                  // Level chip (no internal IDs shown)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('lvl$level'),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Shift: $my  •  $pct%',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'All-time: $all',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
