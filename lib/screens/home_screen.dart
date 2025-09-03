
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../app_state.dart';
import '../models.dart';
import '../gamification.dart';
import '../section_assignments.dart';

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


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _runnerTapCount = 0;
  DateTime? _lastTapTime;
  bool _isLongPress = false;

  void _handleRunnerTap(BuildContext context) {
    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _runnerTapCount = 1;
    } else {
      _runnerTapCount++;
    }
    _lastTapTime = now;
    if (_runnerTapCount >= 5) {
      _runnerTapCount = 0;
      _showFeatureBubble(context);
    }
  }

  void _showFeatureBubble(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('App Features', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('• Shift Tracking: Track server runs for each shift (Lunch/Dinner) with real-time updates.'),
                SizedBox(height: 4),
                Text('• Roster Management: Assign servers to lunch and dinner rosters, with a toggle to switch between them.'),
                SizedBox(height: 4),
                Text('• Visual Leaderboards: Popup and main grid show sorted server stats, including runs, percentages, and Pizookie runs.'),
                SizedBox(height: 4),
                Text('• Pizookie Runs: Special long-press action to log Pizookie runs, which count as shift runs and are tracked separately.'),
                SizedBox(height: 4),
                Text('• Leveling System: Each server has a visible level badge, XP, and progress to next level.'),
                SizedBox(height: 4),
                Text('• Team Competition: Pie chart and details for team-based run competition (Blue, Purple, Silver).'),
                SizedBox(height: 4),
                Text('• Leaderboards: Dedicated screen for top performers.'),
                SizedBox(height: 4),
                Text('• History & Profiles: Access to shift history and individual server profiles.'),
                SizedBox(height: 4),
                Text('• Admin & Settings: Admin screen for management and settings for app configuration.'),
                SizedBox(height: 4),
                Text('• Visual Feedback: Snackbars, achievement flashes, and encouragements for actions.'),
                SizedBox(height: 4),
                Text('• Responsive UI: Grid adapts to screen size, with clear, modern design and color-coded elements.'),
                SizedBox(height: 4),
                Text('• Persistent Data: All stats and settings are saved and restored across sessions.'),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 8),
              child: Text('Version: 1.3.0+130', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('HomeScreen.build called');
    final app = Provider.of<AppState>(context);
      return Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onTap: () => _handleRunnerTap(context),
            child: const Text(
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
                    title: Text('Leaderboards'),
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
        body: Stack(
          children: [
            Builder(
              builder: (context) {
                // Recreate ids logic from _Body
                final now = DateTime.now();
                final m = now.hour * 60 + now.minute;
                final start = app.todayPlan?.transitionStartMinutes ?? app.settings.transitionStartMinutes;
                final end = app.todayPlan?.transitionEndMinutes ?? app.settings.transitionEndMinutes;
                final lunchIds = app.todayPlan?.lunchRoster ?? [];
                final dinnerIds = app.todayPlan?.dinnerRoster ?? [];
                List<String> ids = [];
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
                bool isDinner = (m >= end || (app.activeRosterView == 'dinner' && showToggle));
                if (ids.isEmpty) {
                  return Padding(
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
                  );
                }
                // Show main UI when there are assigned servers
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hide "Who's working today" if roster is loaded (ids not empty)
                    // TeamPieChart and rest of UI remain
                    TeamPieChart(teamCounts: teamCounts, teamColors: teamColors),
                    if (!app.shiftActive)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ShiftStartNotice(app: app),
                      ),
                    Expanded(
                      child: _ActiveGrid(ids: ids, shiftActive: app.shiftActive, app: app),
                    ),
                  ],
                );
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Stack(
                children: [
                  // Server name now inside the grey area, top right
                  // Grey area and avatar row
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey[200],
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                      child: Consumer<AppState>(
                        builder: (context, app, _) {
                          final lastId = app.lastRunServerId;
                          final profile = lastId != null ? app.profiles[lastId] : null;
                          final avatarPath = profile?.avatarPath;
                          ImageProvider? avatarImage;
                          if (avatarPath != null && avatarPath.isNotEmpty) {
                            if (avatarPath.startsWith('/') || avatarPath.contains(':')) {
                              avatarImage = FileImage(File(avatarPath));
                            } else {
                              avatarImage = AssetImage(avatarPath);
                            }
                          }
                          final serverName = lastId != null ? app.serverById(lastId)?.name ?? '' : '';
                          return Stack(
                            children: [
                              // Server name at top right inside grey area
                              if (serverName.isNotEmpty)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.only(top: 4, right: 10),
                                    child: Text(
                                      serverName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                              // Avatar row
                              Row(
                                children: [
                                  if (avatarImage != null && profile != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 0, right: 12.0),
                                      child: SizedBox(
                                        width: 96,
                                        height: 96,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            AspectRatio(
                                              aspectRatio: 1,
                                              child: ClipOval(
                                                child: Image(
                                                  image: avatarImage,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.8),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'Lvl${profile.level}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  // Stats column next to avatar
                                  Padding(
                                    padding: const EdgeInsets.only(left: 0, right: 0, top: 8, bottom: 8),
                                    child: Builder(
                                      builder: (context) {
                                        final runCount = lastId != null ? app.currentCounts[lastId] ?? 0 : 0;
                                        final pizookieCount = lastId != null ? app.currentPizookieCounts[lastId] ?? 0 : 0;
                                        final workingIds = app.workingServerIds.toList();
                                        // Rank for runs
                                        final runRanks = List<String>.from(workingIds);
                                        runRanks.sort((a, b) => (app.currentCounts[b] ?? 0).compareTo(app.currentCounts[a] ?? 0));
                                        final runRank = lastId != null ? (runRanks.indexOf(lastId) + 1) : 0;
                                        // Rank for pizookie runs
                                        final pizookieRanks = List<String>.from(workingIds);
                                        pizookieRanks.sort((a, b) => (app.currentPizookieCounts[b] ?? 0).compareTo(app.currentPizookieCounts[a] ?? 0));
                                        final pizookieRank = lastId != null ? (pizookieRanks.indexOf(lastId) + 1) : 0;
                                        final totalServers = workingIds.length;
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Runs: $runCount',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Rank: $runRank/$totalServers',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                if (runRank == 1)
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 4),
                                                    child: Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 20), // Gold
                                                  )
                                                else if (runRank == 2)
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 4),
                                                    child: Icon(Icons.emoji_events, color: Color(0xFFC0C0C0), size: 20), // Silver
                                                  )
                                                else if (runRank == 3)
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 4),
                                                    child: Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 20), // Bronze
                                                  ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Pizookies: $pizookieCount',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Rank: $pizookieRank/$totalServers',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                if (pizookieRank == 1)
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 4),
                                                    child: Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 20), // Gold
                                                  )
                                                else if (pizookieRank == 2)
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 4),
                                                    child: Icon(Icons.emoji_events, color: Color(0xFFC0C0C0), size: 20), // Silver
                                                  )
                                                else if (pizookieRank == 3)
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 4),
                                                    child: Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 20), // Bronze
                                                  ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // ...existing code...
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
    List<String> ids = [];
    final showToggle = m >= start && m < end;
    if (m < start) {
      ids = lunchIds;
    } else if (m >= end) {
      ids = dinnerIds;
    } else {
      // During transition: show toggle, and show correct ids for each view
      if (app.activeRosterView == 'dinner') {
        // Show only dinner-only servers (not on lunch) during transition
        ids = dinnerIds.where((id) => !lunchIds.contains(id)).toList();
      } else {
        // Show all lunch servers (including those who work both)
        ids = lunchIds;
      }
    }
    ids = ids.toSet().toList();
    bool isDinner = (m >= end || (app.activeRosterView == 'dinner' && showToggle));

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
        if (showToggle)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Lunch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Switch(
                  value: app.activeRosterView == 'dinner',
                  onChanged: (val) => app.toggleRosterView(),
                  activeColor: Colors.deepOrange,
                  inactiveThumbColor: Colors.blue,
                  inactiveTrackColor: Colors.blueGrey.shade200,
                ),
                const Text('Dinner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) {
                    return _RosterPopup(app: app, rosterLabel: isDinner ? 'DINNER ROSTER DISPLAYED' : 'LUNCH ROSTER DISPLAYED');
                  },
                );
              },
              child: Center(
                child: Text(
                  isDinner ? 'DINNER ROSTER DISPLAYED' : 'LUNCH ROSTER DISPLAYED',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey, decoration: TextDecoration.underline),
                ),
              ),
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
  bool _isLongPress = false;
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

  void _showFlash(String text, String subText, {bool forAchievement = false}) {
    final app = widget.app;
    // If this is for an achievement, only show if gamification is enabled
    if (forAchievement && !app.settings.gamificationEnabled) return;
    setState(() {
      _flashText = text;
      _flashSubText = subText;
    });
    _xpController?.forward(from: 0);
    _subController?.forward(from: 0);
  }

  void _showAchievement(String text) {
    final app = widget.app;
    if (!app.settings.gamificationEnabled) return;
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
          padding: const EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('🍪', style: TextStyle(fontSize: 28, shadows: [Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(1,1))])),
              Expanded(
                child: Text(
                  'Long Press When Running a Pizookie!',
                  style: TextStyle(
                    color: Colors.brown.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 1.0,
                    shadows: const [Shadow(blurRadius: 2, color: Colors.black12, offset: Offset(1,1))],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                    childAspectRatio: 1.25, // slightly taller
                  ),
                  itemBuilder: (ctx, i) {
                    final id = ids[i];
                    final s = app.serverById(id);
                    if (s == null) return const SizedBox.shrink();

                    final my = app.currentCounts[id] ?? 0;
                    final pct = total == 0 ? 0 : ((my / total) * 100).round();
                    final color = _tierColor(my, maxCount);
                    final level = app.profiles[id]?.level ?? 1;
                    final borderColor = _teamColor(s.teamColor) ?? Colors.transparent;
                    final points = app.profiles[id]?.points ?? 0;
                    final nextLevelAt = app.profiles[id]?.nextLevelAt ?? 0;
                    final pointsToNext = (nextLevelAt - points).clamp(0, 999999);

                    // Calculate progress for XP bar using xpTable and levelForPoints
                    final profile = app.profiles[id];
                    int prevLevelXp = 0;
                    int nextLevelXp = nextLevelAt;
                    if (profile != null) {
                      final lvl = levelForPoints(profile.points);
                      prevLevelXp = xpTable[lvl];
                      nextLevelXp = xpTable[lvl + 1];
                    }

                    // Section assignment display
                    // Determine if lunch or dinner based on time (same logic as roster)
                    final now = DateTime.now();
                    final m = now.hour * 60 + now.minute;
                    final plan = app.todayPlan;
                    final isLunch = m < (plan?.transitionEndMinutes ?? app.settings.transitionEndMinutes);
                    // Load section assignments (async)
                    return FutureBuilder<Map<String, String?>> (
                      future: loadSectionAssignments(isLunch),
                      builder: (context, snapshot) {
                        String? section;
                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                          section = snapshot.data![id];
                        }
                        // Calculate progress for XP bar
                        double progress = 1.0;
                        if (nextLevelXp > prevLevelXp) {
                          progress = ((points - prevLevelXp) / (nextLevelXp - prevLevelXp)).clamp(0.0, 1.0);
                        }
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
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: () {
                            // Only increment normal run on tap, not on long press
                            if (!this._isLongPress) {
                              final achievement = app.increment(id);
                              int xpEarned = 10;
                              if (achievement == 'full_hands') {
                                xpEarned = 35;
                                _showAchievement('Full Hands!');
                              } else if (achievement == 'five_streak') {
                                xpEarned = 30;
                              } else if (achievement == 'ten_in_shift') {
                                xpEarned = 20;
                              } else if (achievement == 'twenty_in_shift') {
                                xpEarned = 30;
                              }
                              _showFlash(
                                '+$xpEarned XP',
                                'Next level: $pointsToNext XP',
                              );
                              if (app.settings.encouragementFlashEnabled) {
                                final msg = encouragements[Random().nextInt(encouragements.length)];
                                ScaffoldMessenger.of(ctx).clearSnackBars();
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
                                );
                              }

                              final bubble = app.recentBadgeBubble;
                              if (bubble != null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(bubble), duration: const Duration(seconds: 3)),
                                );
                                app.clearRecentBadgeBubble();
                              }

                              // Set lastRunServerId so avatar appears in bottom grey area
                              app.lastRunServerId = id;
                            }
                          },
                          onLongPress: () {
                            this._isLongPress = true;
                            app.incrementPizookie(id);
                            int xpEarned = 25;
                            _showFlash(
                              '+$xpEarned XP\nPizookie!',
                              'Sweet!  Ran a Pizookie',
                            );
                            final msg = 'Pizookie run!';
                            ScaffoldMessenger.of(ctx).clearSnackBars();
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
                            );
                            Future.delayed(const Duration(milliseconds: 100), () {
                              this._isLongPress = false;
                            });
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Progress bar row
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2.0, top: 10, left: 4, right: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Current level (left) - big, bold, with background, wider for double digits
                                    GestureDetector(
                                      onLongPress: () {
                                        Future.delayed(const Duration(seconds: 2), () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => Dialog(
                                              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                                              backgroundColor: Colors.transparent,
                                              child: SizedBox(
                                                width: 340,
                                                height: 520,
                                                child: ProfileDetailScreen(serverId: id),
                                              ),
                                            ),
                                          );
                                        });
                                      },
                                      child: Container(
                                        width: 44,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.18),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.18),
                                              blurRadius: 4,
                                              offset: Offset(1, 2),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'lvl$level',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                            shadows: [
                                              Shadow(blurRadius: 2, color: Colors.black54, offset: Offset(1,1)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Progress bar
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            minHeight: 10,
                                            backgroundColor: Colors.white24,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Next level (right) - smaller, bold, with subtle background
                                    Container(
                                      width: 28,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${level + 1}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(blurRadius: 1, color: Colors.black38, offset: Offset(1,1)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        s.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.1,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(blurRadius: 6, color: Colors.black45, offset: Offset(0, 2)),
                                          ],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (section != null && section.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Flexible(
                                          child: Text(
                                            section,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(blurRadius: 2, color: Colors.black45, offset: Offset(0, 1)),
                                              ],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 2),
                                      Text(
                                        'Shift: $my  •  $pct%',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'Pizookies: '
                                        + (app.shiftActive
                                            ? (app.currentPizookieCounts[id]?.toString() ?? '0')
                                            : '0'),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                    final progress = (nextLevelXp > prevLevelXp)
                        ? ((points - prevLevelXp) / (nextLevelXp - prevLevelXp)).clamp(0.0, 1.0)
                        : 1.0;

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
                        padding: const EdgeInsets.all(8),
                      ),
                      onPressed: () {
                        final achievement = app.increment(id);
                        int xpEarned = 10;
                        bool isAchievement = false;
                        if (achievement == 'full_hands') {
                          xpEarned = 35;
                          isAchievement = true;
                          _showAchievement('Full Hands!');
                        } else if (achievement == 'five_streak') {
                          xpEarned = 30;
                          isAchievement = true;
                        } else if (achievement == 'ten_in_shift') {
                          xpEarned = 20;
                          isAchievement = true;
                        } else if (achievement == 'twenty_in_shift') {
                          xpEarned = 30;
                          isAchievement = true;
                        }
                        // Only show XP flash for achievements if gamification is enabled
                        if (!isAchievement || app.settings.gamificationEnabled) {
                          _showFlash(
                            '+$xpEarned XP',
                            'Next level: $pointsToNext XP',
                            forAchievement: isAchievement,
                          );
                        }
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
                        app.incrementPizookie(id);
                        int xpEarned = 25;
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Progress bar row
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0, top: 10, left: 4, right: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Current level (left) - big, bold, with background, wider for double digits
                                GestureDetector(
                                  onLongPress: () {
                                    Future.delayed(const Duration(seconds: 2), () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => Dialog(
                                          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                                          backgroundColor: Colors.transparent,
                                          child: SizedBox(
                                            width: 340,
                                            height: 520,
                                            child: ProfileDetailScreen(serverId: id),
                                          ),
                                        ),
                                      );
                                    });
                                  },
                                  child: Container(
                                    width: 44,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.18),
                                          blurRadius: 4,
                                          offset: Offset(1, 2),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'lvl$level',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                        shadows: [
                                          Shadow(blurRadius: 2, color: Colors.black54, offset: Offset(1,1)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Progress bar
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 10,
                                        backgroundColor: Colors.white24,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Next level (right) - smaller, bold, with subtle background
                                Container(
                                  width: 28,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${level + 1}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(blurRadius: 1, color: Colors.black38, offset: Offset(1,1)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    s.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(blurRadius: 6, color: Colors.black45, offset: Offset(0, 2)),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Shift: $my  •  $pct%',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Pizookies: ${app.profiles[id]?.pizookieRuns ?? 0}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                  // ...removed 'All Time Runs' display...
                                ],
                              ),
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

  // Calculate total runs for this roster (matching grid logic)
  final counts = sortedIds.map((id) => widget.app.currentCounts[id] ?? 0).toList();
  final totalRuns = counts.fold<int>(0, (a, b) => a + b);
  // No team percent widgets needed
  List<Widget> teamPercentWidgets = [];

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
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowHeight: 38,
                        dataRowHeight: 32,
                        columnSpacing: 18,
                        horizontalMargin: 8,
                        columns: const [
                          DataColumn(label: Text('Servers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          DataColumn(label: Text('Runs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          DataColumn(label: Text('Pizookie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          DataColumn(label: Text('% Food', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                        ],
                        rows: List.generate(sortedIds.length, (i) {
                          final id = sortedIds[i];
                          final server = widget.app.servers.firstWhere((s) => s.id == id, orElse: () => Server(id: id, name: 'Unknown'));
                          final count = widget.app.currentCounts[id] ?? 0;
                          final pct = totalRuns > 0 ? ((count / totalRuns) * 100).round() : 0;
                          final pizookieRuns = widget.app.profiles[id]?.pizookieRuns ?? 0;
                          Color? nameColor;
                          FontWeight nameWeight = FontWeight.bold;
                          if (i == 0) nameColor = Color(0xFFFFD700); // Gold
                          else if (i == 1) nameColor = Color(0xFFC0C0C0); // Silver
                          else if (i == 2) nameColor = Color(0xFFCD7F32); // Bronze
                          String? trophy;
                          if (i == 0) trophy = '🥇';
                          else if (i == 1) trophy = '🥈';
                          else if (i == 2) trophy = '🥉';
                          return DataRow(
                            cells: [
                              DataCell(
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      if (trophy != null)
                                        WidgetSpan(
                                          alignment: PlaceholderAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 4),
                                            child: Text(trophy, style: const TextStyle(fontSize: 18)),
                                          ),
                                        ),
                                      TextSpan(
                                        text: server.name,
                                        style: TextStyle(
                                          fontWeight: nameWeight,
                                          color: nameColor,
                                          fontSize: 15,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              DataCell(Text('$count', style: const TextStyle(fontSize: 14))),
                              DataCell(Text('$pizookieRuns', style: const TextStyle(fontSize: 14))),
                              DataCell(Text('$pct%', style: const TextStyle(fontSize: 14))),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
