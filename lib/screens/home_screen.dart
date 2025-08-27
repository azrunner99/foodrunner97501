
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
import '_shift_start_notice.dart';

// Helper for roster popup: display a server row
Widget _rosterServerRow(AppState app, String id) {
  final server = app.servers.firstWhere((s) => s.id == id, orElse: () => Server(id: id, name: 'Unknown'));
  final count = app.currentCounts[id] ?? 0;
  return ListTile(
    title: Text(server.name),
    trailing: Text('$count'),
    dense: true,
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
  print('HomeScreen.build called');
  final app = Provider.of<AppState>(context);
  // Get AppState from Provider if needed, or pass as parameter
  // final app = AppState();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RUNNER!',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            fontSize: 28,
            letterSpacing: 2,
            color: Color(0xFF1565C0), // A strong blue
            shadows: [
              Shadow(
                blurRadius: 6,
                color: Colors.black26,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
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
              if (a == _MoreAction.profiles) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilesScreen()),
                );
              } else if (a == _MoreAction.settings) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              } else if (a == _MoreAction.mvp) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MvpScreen()),
                );
              } else if (a == _MoreAction.history) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: _MoreAction.profiles,
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profiles'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: _MoreAction.mvp,
                child: ListTile(
                  leading: Icon(Icons.emoji_events),
                  title: Text('MVP Board'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: _MoreAction.history,
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Shift History'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
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
    if (teamCounts.isEmpty) {
      return const SizedBox.shrink();
    }
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
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 24,
          sectionsSpace: 2,
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
    final now = DateTime.now();
    final m = now.hour * 60 + now.minute;


    // Use settings for transition times
    final start = app.todayPlan?.transitionStartMinutes ?? app.settings.transitionStartMinutes;
    final end = app.todayPlan?.transitionEndMinutes ?? app.settings.transitionEndMinutes;
    final lunchIds = app.todayPlan?.lunchRoster ?? [];
    final dinnerIds = app.todayPlan?.dinnerRoster ?? [];
    List<String> ids;
    final showToggle = m >= start && m < end;
    if (m < start) {
      ids = lunchIds;
    } else if (m >= end) {
      ids = dinnerIds;
    } else {
      if (app.activeRosterView == 'dinner') {
        ids = dinnerIds.where((id) => !lunchIds.contains(id)).toList();
      } else {
        ids = lunchIds;
      }
    }
    ids = ids.toSet().toList();
    String rosterLabel = (m >= end || (app.activeRosterView == 'dinner' && showToggle))
        ? 'DINNER ROSTER DISPLAYED'
        : 'LUNCH ROSTER DISPLAYED';

    // Calculate team run counts
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
    String toggleLabel = (app.activeRosterView == 'lunch' || !showToggle)
        ? "Switch to Dinner"
        : "Switch to Lunch";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) {
                  return _RosterPopup(app: app, rosterLabel: rosterLabel);
                },
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Center(
                child: Text(
                  rosterLabel,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey, decoration: TextDecoration.underline),
                ),
              ),
            ),
          ),
        ),
        if (showToggle)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => app.toggleRosterView(),
              child: Text(toggleLabel),
            ),
          ),
        TeamPieChart(teamCounts: teamCounts, teamColors: teamColors),
        if (ids.isNotEmpty)
          ...[
            if (!app.shiftActive)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ShiftStartNotice(app: app),
              ),
            Expanded(
              child: _ActiveGrid(ids: ids, shiftActive: app.shiftActive, app: app),
            ),
          ],
        if (ids.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
      ],
    );
  }
}


class _ActiveGrid extends StatefulWidget {
  final List<String> ids;
  final bool shiftActive;
  final AppState app;
  const _ActiveGrid({required this.ids, required this.shiftActive, required this.app});

  @override
  State<_ActiveGrid> createState() => _ActiveGridState();
}

class _ActiveGridState extends State<_ActiveGrid> with TickerProviderStateMixin {
  String? _achievementText;
  AnimationController? _achievementController;
  String? _flashText;
  String? _flashSubText;
  AnimationController? _xpController;
  AnimationController? _subController;

  @override
  void initState() {
    super.initState();
    _achievementController = AnimationController(vsync: this, duration: const Duration(milliseconds: 5500));
    _xpController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _subController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _xpController?.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _flashText = null;
          // Do not clear _flashSubText here; let subController finish
        });
      }
    });
    _subController?.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _flashSubText = null;
        });
      }
    });
    _achievementController?.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _achievementText = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
  _achievementController?.dispose();
    _xpController?.dispose();
    _subController?.dispose();
    super.dispose();
  }

  void _showFlash(String text, String subText) {
    setState(() {
      _flashText = text;
      _flashSubText = subText;
    });
    _xpController?.forward(from: 0);
    _subController?.forward(from: 0);
  }

  void _showAchievement(String text) {
    print('[_showAchievement] called with: ' + text);
    if (!mounted) return;
    setState(() {
      _achievementText = text;
    });
    _achievementController?.reset();
    _achievementController?.forward();
  }

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
    final ids = widget.ids;
    final app = widget.app;
    final counts = ids.map((id) => app.currentCounts[id] ?? 0).toList();
    final maxCount = counts.isEmpty ? 0 : counts.reduce((a, b) => a > b ? a : b);
    final total = counts.fold<int>(0, (a, b) => a + b);
    final columns = MediaQuery.of(context).size.width > 800 ? 4 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('🍪', style: TextStyle(fontSize: 28, shadows: [Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(1,1))])),
              Expanded(
                child: Text(
                  'Long press when running a Pizookie!',
                  style: TextStyle(
                    color: Colors.brown.shade700,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 1.1,
                    shadows: const [Shadow(blurRadius: 4, color: Colors.black12, offset: Offset(1,1))],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Text('🍪', style: TextStyle(fontSize: 28, shadows: [Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(1,1))])),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Padding(
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
                    final points = app.profiles[id]?.points ?? 0;
                    final nextLevelAt = app.profiles[id]?.nextLevelAt ?? 0;
                    final pointsToNext = (nextLevelAt - points).clamp(0, 999999);

                    return OutlinedButton(
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
                        final achievement = app.increment(id);
                        int xpEarned = 1;
                        if (achievement == 'full_hands') {
                          xpEarned = 4;
                          _showAchievement('Full Hands!');
                        }
                        _showFlash(
                          '+$xpEarned XP',
                          'Next level: $pointsToNext XP',
                        );
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
                      onLongPress: () {
                        int xpEarned = 2;
                        _showFlash(
                          '+$xpEarned XP\nPizookie!',
                          'Sweet!  Ran a Pizookie',
                        );
                        final msg = 'Pizookie run!';
                        ScaffoldMessenger.of(ctx).clearSnackBars();
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
                        );
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
                    );
                  },
                ),
              ),
              if (_flashText != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_xpController != null)
                            AnimatedBuilder(
                              animation: _xpController!,
                              builder: (context, child) {
                                final opacity = 1.0 - _xpController!.value;
                                final scale = 1.0 + 0.5 * (1.0 - _xpController!.value);
                                return Opacity(
                                  opacity: opacity,
                                  child: Transform.scale(
                                    scale: scale,
                                    child: Text(
                                      _flashText ?? '',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                        shadows: [
                                          Shadow(blurRadius: 8, color: Colors.black45, offset: Offset(2, 2)),
                                          Shadow(blurRadius: 12, color: Colors.black, offset: Offset(0, 0)),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          if (_flashSubText != null && _subController != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: AnimatedBuilder(
                                animation: _subController!,
                                builder: (context, child) {
                                  // Subtext fades out only after XP flash is gone
                                  final fadeStart = 0.3;
                                  final subValue = _subController!.value;
                                  final fadeProgress = ((subValue - fadeStart) / (1.0 - fadeStart)).clamp(0.0, 1.0);
                                  final opacity = 1.0 - fadeProgress;
                                  return Opacity(
                                    opacity: opacity,
                                    child: Center(
                                      child: Text(
                                        _flashSubText!,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                          shadows: [
                                            Shadow(blurRadius: 10, color: Colors.black, offset: Offset(0, 0)),
                                            Shadow(blurRadius: 16, color: Colors.black87, offset: Offset(2, 2)),
                                            Shadow(blurRadius: 24, color: Colors.black54, offset: Offset(-2, -2)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Achievement flash overlay (separate, longer lasting)
              if (_achievementText != null && _achievementController != null)
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _achievementController!,
                        builder: (context, child) {
                          print('[AchievementOverlay] builder: _achievementText=$_achievementText, controller.value=${_achievementController!.value}');
                          final opacity = 1.0 - _achievementController!.value;
                          final scale = 1.0 + 0.2 * (1.0 - _achievementController!.value);
                          return Opacity(
                            opacity: opacity,
                            child: Transform.scale(
                              scale: scale,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    size: 80,
                                    color: Colors.amber.shade700,
                                    shadows: [
                                      Shadow(blurRadius: 24, color: Colors.black54, offset: Offset(0, 6)),
                                      Shadow(blurRadius: 32, color: Colors.amberAccent, offset: Offset(0, 0)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _achievementText ?? '',
                                    style: TextStyle(
                                      fontSize: 54,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.amber.shade700,
                                      letterSpacing: 1.5,
                                      shadows: const [
                                        Shadow(blurRadius: 12, color: Colors.black, offset: Offset(0, 0)),
                                        Shadow(blurRadius: 24, color: Colors.black54, offset: Offset(2, 2)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Team Competition Details Screen ---
class TeamCompetitionDetailsScreen extends StatelessWidget {
  final Map<String, Color> teamColors;
  const TeamCompetitionDetailsScreen({required this.teamColors, super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    // Group servers by team
    final Map<String, List<Server>> teams = {};
    final Map<String, double> teamTotals = {};
    for (final s in app.servers) {
      if (s.teamColor != null) {
        teams.putIfAbsent(s.teamColor!, () => []).add(s);
        teamTotals[s.teamColor!] = (teamTotals[s.teamColor!] ?? 0) + ((app.currentCounts[s.id] ?? 0).toDouble());
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Competition Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: teamColors.keys.map((team) {
            final members = teams[team] ?? [];
            final sortedMembers = [...members]
              ..sort((a, b) => (app.currentCounts[b.id] ?? 0).compareTo(app.currentCounts[a.id] ?? 0));
            final teamTotal = teamTotals[team] ?? 0;
            return Container(
              width: 180,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: teamColors[team]!, width: 3),
                borderRadius: BorderRadius.circular(12),
                color: teamColors[team]!.withAlpha((0.07 * 255).toInt()),
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
                          'Total: ${teamTotal.toInt()}',
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
                      title: Text(s.name),
                      trailing: Text('$count'),
                    );
                  }),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}


class _RosterPopup extends StatefulWidget {
  final AppState app;
  final String rosterLabel;
  const _RosterPopup({required this.app, required this.rosterLabel});

  @override
  State<_RosterPopup> createState() => _RosterPopupState();
}

class _RosterPopupState extends State<_RosterPopup> {
  bool showLunch = true;

  @override
  void initState() {
    super.initState();
    showLunch = widget.rosterLabel.toLowerCase().contains('lunch');
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final m = now.hour * 60 + now.minute;
    final plan = widget.app.todayPlan;
    final lunchIds = plan?.lunchRoster ?? [];
    final dinnerIds = plan?.dinnerRoster ?? [];
    final isAfterTransition = m >= (plan?.transitionEndMinutes ?? widget.app.settings.transitionEndMinutes);
    final header = showLunch ? 'Lunch' : 'Dinner';

    // --- Get the correct roster and sort by runs descending ---
    final ids = showLunch ? lunchIds : dinnerIds;
    final sortedIds = [...ids];
    sortedIds.sort((a, b) => (widget.app.currentCounts[b] ?? 0).compareTo(widget.app.currentCounts[a] ?? 0));

    // --- Calculate team totals and percentages ---
    final teamColors = <String, Color>{
      'Blue': Colors.blue,
      'Purple': Colors.purple,
      'Silver': Colors.grey,
    };
    final teamCounts = <String, int>{};
    int totalRuns = 0;
    for (final id in sortedIds) {
      final s = widget.app.servers.firstWhere(
        (srv) => srv.id == id,
        orElse: () => Server(id: id, name: 'Unknown'),
      );
      if (s.teamColor == null) continue;
      final team = s.teamColor!;
      final count = widget.app.currentCounts[id] ?? 0;
      teamCounts[team] = (teamCounts[team] ?? 0) + count;
      totalRuns += count;
    }
    // Build team percentage widgets
    List<Widget> teamPercentWidgets = [];
    if (totalRuns > 0) {
      teamPercentWidgets = teamColors.keys.map((team) {
        final runs = teamCounts[team] ?? 0;
        final pct = (runs / totalRuns * 100).toStringAsFixed(1);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: teamColors[team], shape: BoxShape.circle)),
            Text('$team: $pct%', style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 12),
          ],
        );
      }).toList();
    }

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              header,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              textAlign: TextAlign.center,
            ),
          ),
          if (showLunch && isAfterTransition)
            const Padding(
              padding: EdgeInsets.only(top: 2.0),
              child: Text('finalized', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.grey)),
            ),
          if (teamPercentWidgets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
              child: Wrap(children: teamPercentWidgets),
            ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ToggleButtons(
                isSelected: [showLunch, !showLunch],
                onPressed: (idx) => setState(() => showLunch = idx == 0),
                borderRadius: BorderRadius.circular(20),
                constraints: const BoxConstraints(minWidth: 80, minHeight: 36),
                selectedColor: Colors.white,
                fillColor: Theme.of(context).primaryColor,
                children: const [Text('Lunch'), Text('Dinner')],
              ),
            ),
          ),
          // Column headers
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Row(
              children: const [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Servers',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    textAlign: TextAlign.left,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Number\nof Runs',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Percentage\nof Food Ran',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 8),
          ...List.generate(sortedIds.length, (i) {
            final id = sortedIds[i];
            final server = widget.app.servers.firstWhere((s) => s.id == id, orElse: () => Server(id: id, name: 'Unknown'));
            final count = widget.app.currentCounts[id] ?? 0;
            final pct = totalRuns > 0 ? (count / totalRuns * 100).toStringAsFixed(1) : '0.0';
            Color? nameColor;
            FontWeight nameWeight = FontWeight.bold;
            if (i == 0) nameColor = Color(0xFFFFD700); // Gold
            else if (i == 1) nameColor = Color(0xFFC0C0C0); // Silver
            else if (i == 2) nameColor = Color(0xFFCD7F32); // Bronze
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      server.name,
                      style: TextStyle(
                        fontWeight: nameWeight,
                        color: nameColor,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '$count',
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      '$pct%',
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
