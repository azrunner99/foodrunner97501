import 'package:fl_chart/fl_chart.dart';
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
          IconButton(
            tooltip: 'Active Roster',
            icon: const Icon(Icons.group),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UpdateRosterScreen()),
              );
            },
          ),
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

class TeamPieChart extends StatelessWidget {
  final Map<String, int> teamCounts;
  final Map<String, Color> teamColors;
  const TeamPieChart({required this.teamCounts, required this.teamColors, super.key});

  @override
  Widget build(BuildContext context) {
    final total = teamCounts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No runs yet')),
      );
    }
    final sections = teamCounts.entries.map((entry) {
      final percent = entry.value / total * 100;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: teamColors[entry.key],
        title: '${entry.key}\n${percent.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        radius: 48,
      );
    }).toList();

    return SizedBox(
      height: 180,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TeamCompetitionDetailsScreen(teamColors: teamColors),
            ),
          );
        },
        child: PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: 24,
            sectionsSpace: 2,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final AppState app;
  const _Body({required this.app});

  @override
  Widget build(BuildContext context) {
    // Calculate team run counts
    final ids = app.currentRoster;
    final teamCounts = <String, int>{};
    final teamColors = <String, Color>{
      'Blue': Colors.blue,
      'Purple': Colors.purple,
      'Silver': Colors.grey,
    };

    for (final id in ids) {
      final s = app.serverById(id);
      if (s == null || s.teamColor == null) continue;
      teamCounts[s.teamColor!] = (teamCounts[s.teamColor!] ?? 0) + (app.currentCounts[id] ?? 0);
    }

    if (!app.shiftActive && !app.shiftPaused) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TeamPieChart(teamCounts: teamCounts, teamColors: teamColors),
              const SizedBox(height: 20),
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
                    MaterialPageRoute(builder: (_) => UpdateRosterScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    // --- Toggle button logic ---
    final now = DateTime.now();
    final m = now.hour * 60 + now.minute;
    final showToggle = m >= 15 * 60 + 30; // Show after 3:30 PM
    String toggleLabel;
    if (app.activeRosterView == 'lunch' ||
        (app.activeRosterView == 'auto' && m < 16 * 60)) {
      toggleLabel = "I work tonight.";
    } else {
      toggleLabel = "I worked this morning.";
    }

    // Active-shift grid UI
    return Column(
      children: [
        if (showToggle)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => app.toggleRosterView(),
              child: Text(toggleLabel),
            ),
          ),
        TeamPieChart(teamCounts: teamCounts, teamColors: teamColors),
        const Expanded(child: _ActiveGrid()),
      ],
    );
  }
}

class _ActiveGrid extends StatelessWidget {
  const _ActiveGrid();

  Color _tierColor(int my, int max) {
    if (max <= 0) return Colors.grey.shade400;
    final ratio = my / max;
    if (ratio >= 1.0) return const Color(0xFF145A32); // deep green
    if (ratio >= 0.75) return const Color(0xFF2ECC71); // green
    if (ratio >= 0.50) return const Color(0xFFF1C40F); // yellow
    if (ratio >= 0.25) return const Color(0xFFE67E22); // orange-red
    return const Color(0xFFC0392B); // red
  }

  Color? _teamColor(String? team) {
    switch (team) {
      case 'Blue':
        return Colors.blue;
      case 'Purple':
        return Colors.purple;
      case 'Silver':
        return Colors.grey;
      default:
        return null;
    }
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
    final ids = app.currentRoster;
    final counts = ids.map((id) => app.currentCounts[id] ?? 0).toList();
    final maxCount = counts.isEmpty ? 0 : counts.reduce(max);
    final total = counts.fold<int>(0, (a, b) => a + b);

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
          final borderColor = _teamColor(s.teamColor) ?? Colors.transparent;

          return GestureDetector(
            onLongPress: () => app.decrement(id),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: borderColor,
                  width: borderColor == Colors.transparent ? 0 : 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
              ),
              onPressed: () {
                app.increment(id);

                final msg = encouragements[Random().nextInt(encouragements.length)];
                ScaffoldMessenger.of(ctx).clearSnackBars();
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
                );

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
                  // Level chip (top-right)
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

// --- Team Competition Details Screen ---
class TeamCompetitionDetailsScreen extends StatelessWidget {
  final Map<String, Color> teamColors;
  const TeamCompetitionDetailsScreen({required this.teamColors, super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    // Group servers by team
    final Map<String, List<Server>> teams = {};
    final Map<String, int> teamTotals = {};
    for (final s in app.servers) {
      if (s.teamColor == null) continue;
      teams.putIfAbsent(s.teamColor!, () => []).add(s);
      teamTotals[s.teamColor!] = (teamTotals[s.teamColor!] ?? 0) + (app.currentCounts[s.id] ?? 0);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Team Competition Details')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final teamCount = teamColors.length;
          if (teamCount <= 3) {
            // Fit columns to screen width
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: teamColors.keys.map((team) {
                final members = teams[team] ?? [];
                // Sort members by shift count, descending
                final sortedMembers = [...members]
                  ..sort((a, b) => (app.currentCounts[b.id] ?? 0).compareTo(app.currentCounts[a.id] ?? 0));
                final teamTotal = teamTotals[team] ?? 0;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: teamColors[team]!, width: 3),
                      borderRadius: BorderRadius.circular(12),
                      color: teamColors[team]!.withOpacity(0.07),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              Text(
                                team,
                                style: TextStyle(
                                  color: teamColors[team],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total: $teamTotal',
                                style: TextStyle(
                                  color: teamColors[team],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        ...sortedMembers.map((s) {
                          final count = app.currentCounts[s.id] ?? 0;
                          return ListTile(
                            dense: true,
                            title: Text(s.name),
                            trailing: Text('$count'),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          } else {
            // Scroll if more than 3 teams
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: teamColors.keys.map((team) {
                  final members = teams[team] ?? [];
                  // Sort members by shift count, descending
                  final sortedMembers = [...members]
                    ..sort((a, b) => (app.currentCounts[b.id] ?? 0).compareTo(app.currentCounts[a.id] ?? 0));
                  final teamTotal = teamTotals[team] ?? 0;
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: teamColors[team]!, width: 3),
                      borderRadius: BorderRadius.circular(12),
                      color: teamColors[team]!.withOpacity(0.07),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              Text(
                                team,
                                style: TextStyle(
                                  color: teamColors[team],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total: $teamTotal',
                                style: TextStyle(
                                  color: teamColors[team],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        ...sortedMembers.map((s) {
                          final count = app.currentCounts[s.id] ?? 0;
                          return ListTile(
                            dense: true,
                            title: Text(s.name),
                            trailing: Text('$count'),
                          );
                        }),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          }
        },
      ),
    );
  }
}