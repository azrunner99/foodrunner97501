import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:outlined_text/outlined_text.dart';
import 'dart:io';

import '../app_state.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/resilient_avatar.dart';
import '../services/instant_feedback_service.dart';
import 'shift_leaderboard_screen.dart';
import '../gamification.dart';
import '../section_assignments.dart';
import '../widgets/wallpaper_background.dart';
import '../widgets/birthday_anniversary_banner.dart';
import '../widgets/live_countdown_timer.dart';
import 'app_features_screen.dart';
import 'level_color_demo_screen.dart';
import 'server_nps_scorecard_screen.dart';
import '../utils/log.dart';

// Screens
import 'update_roster_screen.dart';
import 'profiles_screen.dart';
import 'settings_screen.dart';
import 'mvp_screen.dart';
import 'history_screen.dart';
import '_shift_start_notice.dart';

// Helper for roster popup: display a server row
Widget _rosterServerRow(AppState app, String id) {
  final server = app.servers.firstWhere((s) => s.id == id,
      orElse: () => Server(id: id, name: 'Unknown'));
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
  bool _hasCheckedForBackups = false;

  @override
  void initState() {
    super.initState();
    // Check for existing backups after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForExistingBackupsOnFreshInstall();
    });
  }

  Future<void> _checkForExistingBackupsOnFreshInstall() async {
    if (_hasCheckedForBackups) return;
    _hasCheckedForBackups = true;

    final app = Provider.of<AppState>(context, listen: false);
    final backupInfo = await app.getExistingBackupInfo();

    if (backupInfo['hasBackups'] == true && mounted) {
      final count = backupInfo['count'] as int;
      _showBackupRestoreDialog(count);
    }
  }

  void _showBackupRestoreDialog(int backupCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup, color: Colors.blue),
            SizedBox(width: 8),
            Text('Existing Backups Found'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Found $backupCount existing backup${backupCount > 1 ? 's' : ''} on this device.'),
            const SizedBox(height: 16),
            const Text(
                'This appears to be a fresh app installation. Would you like to:'),
            const SizedBox(height: 12),
            const Text('• Restore from existing backup, or'),
            const Text('• Start fresh with a new setup'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // User wants to start fresh - no action needed
            },
            child: const Text('Start Fresh'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin').then((_) {
                // After returning from admin, show backup screen
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Navigate to "Data Backup & Restore" to restore your data'),
                        duration: Duration(seconds: 4),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                });
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restore Data'),
          ),
        ],
      ),
    );
  }

  void _showCurrentShiftTotalsDialog(
      BuildContext context, AppState app, bool isDinner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShiftLeaderboardScreen(
          app: app,
          shiftType: isDinner ? 'Dinner' : 'Lunch',
        ),
      ),
    );
  }

  // Used to persist sort selection in dialog
  final String _shiftSortBy = 'runs';
  int _runnerTapCount = 0;
  DateTime? _lastTapTime;
  final bool _isLongPress = false;

  void _showBoostDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BoostModeDialog();
      },
    );
  }

  void _handleRunnerTap(BuildContext context) {
    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _runnerTapCount = 1;
    } else {
      _runnerTapCount++;
    }
    _lastTapTime = now;
    if (_runnerTapCount >= 5) {
      _runnerTapCount = 0;
      _navigateToFeaturesScreen(context);
    }
  }

  void _navigateToFeaturesScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AppFeaturesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
  d('HomeScreen.build called');
    final app = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _handleRunnerTap(context),
          child: Image.asset(
            'assets/runner.png',
            height: 120,
            fit: BoxFit.contain,
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
            tooltip: 'Shift History',
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'NPS Scorecard',
            icon: const Icon(Icons.leaderboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ServerNPSScorecardScreen()),
              );
            },
          ),
          // Boost Mode Icon Button (for managers)
          IconButton(
            tooltip: 'Boost Mode',
            icon: Stack(
              children: [
                Icon(
                  Icons.rocket_launch,
                  color: app.boostActive ? Colors.orange : Colors.black,
                  size: 28,
                ),
                if (app.boostActive)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showBoostDialog,
          ),
          PopupMenuButton<_MoreAction>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert, color: Colors.black, size: 28),
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 12,
            offset: const Offset(0, 55),
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
              } else if (a == _MoreAction.colorDemo) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LevelColorDemoScreen()),
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: _MoreAction.profiles,
                child: ListTile(
                  leading: Icon(Icons.person, color: Colors.blue[700]),
                  title: const Text('Profiles',
                      style: TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.w500)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _MoreAction.mvp,
                child: ListTile(
                  leading: Icon(Icons.emoji_events, color: Colors.amber[600]),
                  title: const Text('Leaderboards',
                      style: TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.w500)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _MoreAction.colorDemo,
                child: ListTile(
                  leading: Icon(Icons.palette, color: Colors.purple[400]),
                  title: const Text('Server Levels',
                      style: TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.w500)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _MoreAction.settings,
                child: ListTile(
                  leading: Icon(Icons.settings, color: Colors.blue[400]),
                  title: const Text('Settings',
                      style: TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.w500)),
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
              final start = app.todayPlan?.transitionStartMinutes ??
                  app.settings.transitionStartMinutes;
              final end = app.todayPlan?.transitionEndMinutes ??
                  app.settings.transitionEndMinutes;
              final lunchIds = app.todayPlan?.lunchRoster ?? [];
        final dinnerIds = app.todayPlan?.dinnerRoster ?? [];
        d('[DEBUG] HomeScreen: m=$m, start=$start, end=$end');
        d('[DEBUG] HomeScreen: lunchIds=$lunchIds, dinnerIds=$dinnerIds');
        d('[DEBUG] HomeScreen: activeRosterView=${app.activeRosterView}');

              // Use AppState's isOpenNow which properly handles overnight hours
              final inBusinessHours = app.isOpenNow;

              d('[DEBUG] HomeScreen: Using app.isOpenNow=$inBusinessHours');
              
              // Also get business interval for display purposes
              final businessDate = AppState.businessDate(now);
              final businessWeekday = businessDate.weekday;
              final businessInterval =
                  app.businessDayInterval(businessDate, businessWeekday);

        d('[DEBUG] HomeScreen: businessDate=$businessDate, businessWeekday=$businessWeekday');
        d('[DEBUG] HomeScreen: businessInterval=${businessInterval.start} to ${businessInterval.end}');

              List<String> ids = [];
              final showToggle = m >= start && m < end;
        d('[DEBUG] HomeScreen: showToggle=$showToggle (transition period)');

              // Determine which roster to show based on business day logic
              bool shouldShowDinner = false;
              if (m < start) {
                shouldShowDinner = false;
        d('[DEBUG] HomeScreen: Before transition, using lunch roster');
              } else if (m >= end) {
                shouldShowDinner = true;
        d('[DEBUG] HomeScreen: After transition, using dinner roster');
              } else {
                // During transition: show correct servers for each view
                shouldShowDinner = (app.activeRosterView == 'dinner');
        d('[DEBUG] HomeScreen: During transition, activeRosterView=${app.activeRosterView}');
              }

              if (shouldShowDinner) {
                if (m >= start && m < end && app.activeRosterView == 'dinner') {
                  // Dinner view during transition: show only dinner-only servers
                  final lunchSet = lunchIds.toSet();
                  final dinnerSet = dinnerIds.toSet();
                  final dinnerOnly = dinnerSet.difference(lunchSet);
                  ids = dinnerOnly.toList();
          d('[DEBUG] HomeScreen: During transition, dinner view selected - showing dinner-only servers: $ids');
                } else {
                  ids = dinnerIds;
                  d('[DEBUG] HomeScreen: Showing dinner roster: $ids');
                }
              } else {
                ids = lunchIds;
                d('[DEBUG] HomeScreen: Showing lunch roster: $ids');
              }
              ids = ids.toSet().toList();
              d('[DEBUG] HomeScreen: Final ids to display: $ids');

              // Sort servers alphabetically by name
              ids.sort((a, b) {
                final serverA = app.serverById(a);
                final serverB = app.serverById(b);
                if (serverA == null && serverB == null) return 0;
                if (serverA == null) return 1;
                if (serverB == null) return -1;
                return serverA.name
                    .toLowerCase()
                    .compareTo(serverB.name.toLowerCase());
              });

              // ROSTER AND BUSINESS HOURS LOGIC:
              // 1. If no roster is set up → Show "Who's working today" screen
              // 2. If roster is set up but restaurant is closed → Show greyed servers with opening time
              // 3. If restaurant is open → Show normal interactive servers

              bool isDinner = (m >= end ||
                  (app.activeRosterView == 'dinner' && showToggle));
              if (ids.isEmpty) {
                // STATE 1: No roster set up → Show "Who's working today" screen
                return Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          "Who’s Working Today?",
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ) ??
                              const TextStyle(
                                  fontSize: 36, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        // Boost Mode Indicator
                        if (app.boostActive)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.withOpacity(0.15),
                                  Colors.deepOrange.withOpacity(0.1)
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              border:
                                  Border.all(color: Colors.orange, width: 3),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange,
                                        Colors.deepOrange
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.6),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(Icons.rocket_launch,
                                      color: Colors.white, size: 24),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'BOOST MODE: ',
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange,
                                        Colors.deepOrange
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.6),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${app.boostMultiplier}x XP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      letterSpacing: 0.5,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 3,
                                          color: Colors.black.withOpacity(0.4),
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                if (app.boostEndTime != null)
                                  LiveCountdownTimer(
                                    endTime: app.boostEndTime!,
                                    textStyle: TextStyle(
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                    prefix: '',
                                    onExpired: () => app.checkBoostExpiry(),
                                  ),
                              ],
                            ),
                          ),
                        if (app.boostActive) const SizedBox(height: 12),
                        Text(
                          "Manager: assign servers to Lunch and Dinner to begin.",
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
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
                              MaterialPageRoute(
                                  builder: (_) => UpdateRosterScreen()),
                            );
                          },
                        ),
                      ],
                    ),
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
                teamCounts[s.teamColor!] = (teamCounts[s.teamColor!] ?? 0) +
                    (app.currentCounts[id] ?? 0);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Business Hours Status Notification
                  if (!inBusinessHours)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.15),
                            Colors.blueAccent.withOpacity(0.1)
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue, Colors.blueAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.schedule, color: Colors.white, size: 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Restaurant Currently Closed',
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Opens at ${businessInterval.start.hour.toString().padLeft(2, '0')}:${businessInterval.start.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  TeamPieChart(teamCounts: teamCounts, teamColors: teamColors),
                  // Boost Mode Indicator (when servers are active)
                  if (app.boostActive)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.15),
                            Colors.deepOrange.withOpacity(0.1)
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        border: Border.all(color: Colors.orange, width: 2.5),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange, Colors.deepOrange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.rocket_launch,
                                color: Colors.white, size: 20),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BOOST MODE ACTIVE!',
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 0.6,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 1,
                                        color: Colors.black.withOpacity(0.2),
                                        offset: Offset(0.5, 0.5),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${app.boostMultiplier.toInt()}x XP • ',
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (app.boostEndTime != null)
                                      LiveCountdownTimer(
                                        endTime: app.boostEndTime!,
                                        textStyle: TextStyle(
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                        prefix: '',
                                        onExpired: () => app.checkBoostExpiry(),
                                      ),
                                  ],
                                ),
                                if (app.boostDescription.isNotEmpty) ...[
                                  SizedBox(height: 1),
                                  Text(
                                    app.boostDescription,
                                    style: TextStyle(
                                      color: Colors.orange[600],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          // Large central countdown display
                          if (app.boostEndTime != null)
                            LiveCountdownTimer(
                              endTime: app.boostEndTime!,
                              showLargeDisplay: true,
                              onExpired: () {
                                // Ensure boost is deactivated when timer expires
                                app.checkBoostExpiry();
                              },
                            ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange, Colors.deepOrange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              '${app.boostMultiplier.toInt()}X',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black.withOpacity(0.5),
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Birthday and Anniversary Banner
                  BirthdayAnniversaryBanner(appState: app),
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 8.0, bottom: 4.0, left: 24.0, right: 24.0),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      color: Colors.white,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          _showCurrentShiftTotalsDialog(context, app, isDinner);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  isDinner ? Icons.nights_stay : Icons.wb_sunny,
                                  color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              Text(
                                isDinner
                                    ? 'Dinner Shift Leaderboard'
                                    : 'Lunch Shift Leaderboard',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (showToggle)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Lunch'),
                            selected: app.activeRosterView != 'dinner',
                            onSelected: (selected) {
                              if (selected &&
                                  app.activeRosterView == 'dinner') {
                                setState(() {
                                  app.toggleRosterView();
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text('Dinner'),
                            selected: app.activeRosterView == 'dinner',
                            onSelected: (selected) {
                              if (selected &&
                                  app.activeRosterView != 'dinner') {
                                setState(() {
                                  app.toggleRosterView();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  if (!app.shiftActive)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ShiftStartNotice(app: app),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          bottom:
                              140.0), // Add bottom padding to prevent overlap with "last run" area
                      child: _ActiveGrid(
                          ids: ids, shiftActive: app.shiftActive, app: app, inBusinessHours: inBusinessHours),
                    ),
                  ),
                ],
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Stack(
              children: [
                // Dynamic Achievement Notification Box
                Consumer<AppState>(
                  builder: (context, app, _) {
                    final lastId = app.lastRunServerId;
                    if (lastId == null) return SizedBox.shrink();

                    final serverName = app.serverById(lastId)?.name ?? 'Server';
                    final currentRuns = app.currentCounts[lastId] ?? 0;
                    final currentPizookies =
                        app.currentPizookieCounts[lastId] ?? 0;
                    final totalEarnedXp = app.currentEarnedXP[lastId] ?? 0;
                    final lastFlashMessage = app.lastFlashMessages[lastId];
                    final lastActionXp = app.lastActionXP[lastId] ?? 0;
                    final milestoneDetails = app.lastMilestoneDetails[lastId];

                    // Use the actual last flash message if available, otherwise generate based on stats
                    String notificationTitle = '';
                    String notificationMessage = '';
                    String bonusExplanation = '';
                    String emoji = '';
                    FeedbackPriority priority = FeedbackPriority.low;

                    if (lastFlashMessage != null &&
                        lastFlashMessage.isNotEmpty) {
                      // Parse the flash message to extract meaningful content and always show XP
                      final lines = lastFlashMessage.split('\n');
                      if (lines.isNotEmpty) {
                        // Clean up the title from flash message
                        notificationTitle = lines.first
                            .replaceAll(RegExp(r'[🔥⚡🎉🍪🚀💪🏆👑⭐🎯🎊💫]'), '')
                            .replaceAll(RegExp(r'\+\d+\s*XP'),
                                '') // Remove XP from title
                            .trim();

                        // Always show a clear, consistent message format with XP prominently displayed
                        if (currentRuns > 0 || currentPizookies > 0) {
                          if (lastActionXp > 0) {
                            notificationMessage =
                                '$serverName: $currentRuns runs, $currentPizookies pizookies\n+$lastActionXp XP earned from this action!';
                          } else {
                            notificationMessage =
                                '$serverName: $currentRuns runs, $currentPizookies pizookies\nKeep up the great work!';
                          }
                        } else {
                          if (lastActionXp > 0) {
                            notificationMessage =
                                '$serverName earned +$lastActionXp XP!';
                          } else {
                            notificationMessage =
                                '$serverName is ready to earn XP!';
                          }
                        }
                      }

                      // Generate bonus explanation from milestone details
                      if (milestoneDetails != null) {
                        final type = milestoneDetails['type'] as String?;
                        final xpReward = milestoneDetails['xpReward'] as int?;
                        final context = milestoneDetails['context']
                            as Map<String, dynamic>?;

                        if (type != null && xpReward != null) {
                          switch (type) {
                            case 'everyFifthRun':
                              final runCount =
                                  context?['runCount'] as int? ?? 0;
                              bonusExplanation =
                                  'Milestone Bonus:\n• Reached $runCount runs\n• Every 5th run earns bonus XP\n• Base reward: +$xpReward XP';
                              break;
                            case 'everySecondPizookie':
                              final pizookieCount =
                                  context?['pizookieCount'] as int? ?? 0;
                              bonusExplanation =
                                  'Pizookie Milestone:\n• Reached $pizookieCount pizookies\n• Every 2nd pizookie earns bonus\n• Sweet reward: +$xpReward XP';
                              break;
                            case 'hotStreak':
                              bonusExplanation =
                                  'Hot Streak Achievement:\n• 5+ runs in 5 minutes\n• Excellent busy period handling\n• Pace bonus: +$xpReward XP';
                              break;
                            case 'steadyPace':
                              bonusExplanation =
                                  'Steady Pace Achievement:\n• 3+ runs in 5 minutes\n• Consistent performance\n• Pace bonus: +$xpReward XP';
                              break;
                            case 'takingTheLead':
                              bonusExplanation =
                                  'Leadership Bonus:\n• Moved to 1st place\n• Competitive excellence\n• Leader reward: +$xpReward XP';
                              break;
                            case 'firstRunOfShift':
                              bonusExplanation =
                                  'Daily First Bonus:\n• First run of the shift\n• Great way to start\n• Early bird: +$xpReward XP';
                              break;
                            case 'firstPizookieOfDay':
                              bonusExplanation =
                                  'Pizookie First:\n• First pizookie of day\n• Sweet beginning\n• Daily bonus: +$xpReward XP';
                              break;
                            case 'traditional_achievement':
                              final title =
                                  milestoneDetails['title'] as String? ??
                                      'Achievement';
                              final description =
                                  milestoneDetails['description'] as String? ??
                                      '';
                              bonusExplanation =
                                  'Achievement Unlocked:\n• $title\n• $description\n• Badge bonus: +$xpReward XP';
                              break;
                            case 'pizookieMaster':
                              bonusExplanation =
                                  'Pizookie Master:\n• 5 pizookies in one shift\n• Dessert expertise achieved\n• Mastery bonus: +$xpReward XP';
                              break;
                            case 'sweetTooth':
                              bonusExplanation =
                                  'Sweet Tooth Legend:\n• 8 pizookies in one shift\n• Dessert domination complete\n• Sweet bonus: +$xpReward XP';
                              break;
                            case 'dessertDominator':
                              bonusExplanation =
                                  'Dessert Dominator:\n• 12 pizookies in one shift\n• Absolute pizookie supremacy\n• Legendary bonus: +$xpReward XP';
                              break;
                            default:
                              bonusExplanation =
                                  'Bonus Earned:\n• $type achieved\n• Special performance\n• Bonus reward: +$xpReward XP';
                          }
                        }
                      }

                      // If no milestone details but we have bonus XP, show generic explanation
                      if (bonusExplanation.isEmpty && lastActionXp > 10) {
                        final actionType =
                            milestoneDetails?['actionType'] as String? ??
                                'regular';
                        final baseXp = actionType == 'pizookie'
                            ? 35
                            : 10; // Updated base pizookie XP
                        final bonusXp = lastActionXp - baseXp;
                        if (bonusXp > 0) {
                          bonusExplanation =
                              'Bonus Breakdown:\n• Base action: +$baseXp XP\n• Performance bonus: +$bonusXp XP\n• Total earned: +$lastActionXp XP';
                        }
                      }

                      // Determine priority and emoji from flash content
                      if (lastFlashMessage.contains('LEGEND') ||
                          lastFlashMessage.contains('HALL OF FAME')) {
                        priority = FeedbackPriority.epic;
                        emoji = '👑';
                      } else if (lastFlashMessage.contains('MILESTONE') ||
                          lastFlashMessage.contains('ACHIEVEMENT')) {
                        priority = FeedbackPriority.high;
                        emoji = '🎯';
                      } else if (lastFlashMessage.contains('PIZOOKIE')) {
                        priority = FeedbackPriority.medium;
                        emoji = '🍪';
                      } else if (lastFlashMessage.contains('BOOST') ||
                          lastFlashMessage.contains('🚀')) {
                        priority = FeedbackPriority.medium;
                        emoji = '🚀';
                      } else {
                        priority = FeedbackPriority.low;
                        emoji = '⚡';
                      }
                    } else {
                      // Fallback to generating message based on current stats (original logic)
                      if (currentRuns >= 25) {
                        priority = FeedbackPriority.epic;
                        emoji = '👑';
                        notificationTitle = 'LEGEND STATUS!';
                        notificationMessage =
                            '$serverName: $currentRuns runs - HALL OF FAME!\n$totalEarnedXp XP earned this shift!';
                      } else if (currentRuns >= 20) {
                        priority = FeedbackPriority.epic;
                        emoji = '🔥';
                        notificationTitle = 'ON FIRE!';
                        notificationMessage =
                            '$serverName: $currentRuns runs - BLAZING HOT!\n$totalEarnedXp XP earned this shift!';
                      } else if (currentRuns >= 10) {
                        priority = FeedbackPriority.high;
                        emoji = '💪';
                        notificationTitle = 'DOUBLE DIGITS!';
                        notificationMessage =
                            '$serverName: $currentRuns runs - POWER MOVE!\n$totalEarnedXp XP earned this shift!';
                      } else if (currentRuns > 0) {
                        priority = FeedbackPriority.medium;
                        emoji = '⚡';
                        notificationTitle = 'GREAT WORK!';
                        notificationMessage =
                            '$serverName: $currentRuns runs, $currentPizookies pizookies\n$totalEarnedXp XP earned this shift!';
                      } else {
                        priority = FeedbackPriority.low;
                        emoji = '💫';
                        notificationTitle = 'READY TO ROCK!';
                        notificationMessage =
                            '$serverName is geared up\nfor an amazing shift!';
                      }
                    }

                    // Dynamic styling based on priority level
                    Color backgroundColor;
                    Color borderColor;
                    Color textColor;
                    List<BoxShadow> shadows;
                    double titleSize;
                    double messageSize;

                    switch (priority) {
                      case FeedbackPriority.epic:
                        backgroundColor =
                            Colors.purple.shade900.withOpacity(0.95);
                        borderColor = Colors.purple.shade200;
                        textColor = Colors.white;
                        titleSize = 22;
                        messageSize = 16;
                        shadows = [
                          BoxShadow(
                              color: Colors.purple.shade300,
                              blurRadius: 15,
                              spreadRadius: 2),
                          BoxShadow(
                              color: Colors.black87,
                              blurRadius: 10,
                              offset: Offset(0, 6)),
                          BoxShadow(
                              color: Colors.purple.shade600,
                              blurRadius: 25,
                              spreadRadius: -5),
                        ];
                        break;
                      case FeedbackPriority.high:
                        backgroundColor = Colors.red.shade800.withOpacity(0.92);
                        borderColor = Colors.red.shade200;
                        textColor = Colors.white;
                        titleSize = 20;
                        messageSize = 15;
                        shadows = [
                          BoxShadow(
                              color: Colors.red.shade400,
                              blurRadius: 12,
                              spreadRadius: 1),
                          BoxShadow(
                              color: Colors.black87,
                              blurRadius: 8,
                              offset: Offset(0, 4)),
                        ];
                        break;
                      case FeedbackPriority.medium:
                        backgroundColor =
                            Colors.orange.shade800.withOpacity(0.90);
                        borderColor = Colors.orange.shade200;
                        textColor = Colors.white;
                        titleSize = 18;
                        messageSize = 14;
                        shadows = [
                          BoxShadow(
                              color: Colors.orange.shade400,
                              blurRadius: 10,
                              spreadRadius: 1),
                          BoxShadow(
                              color: Colors.black54,
                              blurRadius: 6,
                              offset: Offset(0, 3)),
                        ];
                        break;
                      case FeedbackPriority.low:
                        backgroundColor =
                            Colors.blue.shade800.withOpacity(0.88);
                        borderColor = Colors.blue.shade300;
                        textColor = Colors.white;
                        titleSize = 16;
                        messageSize = 13;
                        shadows = [
                          BoxShadow(color: Colors.blue.shade400, blurRadius: 8),
                          BoxShadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 2)),
                        ];
                        break;
                    }

                    return Positioned(
                      bottom: 110,
                      left: 8,
                      right: 8,
                      child: Container(
                        height: priority == FeedbackPriority.epic ? 140 : 120,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: borderColor,
                              width: priority == FeedbackPriority.epic ? 3 : 2),
                          boxShadow: shadows,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left side - Title and main message
                            Expanded(
                              flex: 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    textAlign: TextAlign.left,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$emoji ',
                                          style: TextStyle(
                                              fontSize: titleSize + 4),
                                        ),
                                        TextSpan(
                                          text: notificationTitle,
                                          style: TextStyle(
                                            fontSize: titleSize,
                                            color: textColor,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: priority ==
                                                    FeedbackPriority.epic
                                                ? 1.2
                                                : 0.8,
                                            shadows: [
                                              Shadow(
                                                  blurRadius: 0,
                                                  color: Colors.black,
                                                  offset: Offset(1, 1)),
                                              Shadow(
                                                  blurRadius: 0,
                                                  color: Colors.black,
                                                  offset: Offset(-1, -1)),
                                              Shadow(
                                                  blurRadius: 0,
                                                  color: Colors.black,
                                                  offset: Offset(1, -1)),
                                              Shadow(
                                                  blurRadius: 0,
                                                  color: Colors.black,
                                                  offset: Offset(-1, 1)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    notificationMessage,
                                    style: TextStyle(
                                      fontSize: messageSize,
                                      color: textColor.withOpacity(0.95),
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                      shadows: [
                                        Shadow(
                                            blurRadius: 0,
                                            color: Colors.black54,
                                            offset: Offset(1, 1)),
                                      ],
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
                            ),
                            // Vertical divider
                            if (bonusExplanation.isNotEmpty)
                              Container(
                                width: 2,
                                margin: EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: textColor.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            // Right side - Bonus explanation
                            if (bonusExplanation.isNotEmpty)
                              Expanded(
                                flex: 2,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bonusExplanation,
                                      style: TextStyle(
                                        fontSize: messageSize - 1,
                                        color: textColor.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                        height: 1.25,
                                        shadows: [
                                          Shadow(
                                              blurRadius: 0,
                                              color: Colors.black54,
                                              offset: Offset(1, 1)),
                                        ],
                                      ),
                                      textAlign: TextAlign.left,
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
                // Server name now inside the grey area, top right
                // Grey area and avatar row
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    child: Consumer<AppState>(
                      builder: (context, app, _) {
                        final lastId = app.lastRunServerId;
                        final profile =
                            lastId != null ? app.profiles[lastId] : null;
                        final avatarPath = profile?.avatarPath;
                        final bannerPath = profile?.bannerPath;
                        final avatarImage = getResilientImageProvider(
                          avatarPath, 
                          isAvatar: true
                        );
                        final bannerImage = getResilientImageProvider(
                          bannerPath, 
                          isAvatar: false
                        );
                        final serverName = lastId != null
                            ? app.serverById(lastId)?.name ?? ''
                            : '';
                        return Container(
                          decoration: BoxDecoration(
                            color: (bannerPath == null || bannerPath.isEmpty) 
                                ? Colors.grey[200] : null,
                          ),
                          child: Stack(
                            children: [
                              // Banner background (if available)
                              if (bannerPath != null && bannerPath.isNotEmpty)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: bannerImage,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(
                                            0.3), // Light dark overlay for text readability
                                      ),
                                    ),
                                  ),
                                ),
                              // Server name at top right inside grey area
                              if (serverName.isNotEmpty)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.only(
                                        top: 4, right: 10),
                                    constraints: const BoxConstraints(
                                      maxWidth: 200,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        OutlinedText(
                                          text: Text(
                                            serverName,
                                            style: const TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 28,
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 4,
                                                  color: Colors.black,
                                                  offset: Offset(2, 2),
                                                ),
                                                Shadow(
                                                  blurRadius: 8,
                                                  color: Colors.black54,
                                                  offset: Offset(0, 0),
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.right,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          strokes: [
                                            OutlinedTextStroke(
                                                color: Colors.black, width: 2),
                                          ],
                                        ),
                                        // Full-width line under the name
                                        Container(
                                          margin: const EdgeInsets.only(
                                              top: 4, bottom: 2),
                                          height: 3,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.grey,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 2,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Shift XP Earned
                                        Builder(
                                          builder: (context) {
                                            if (lastId == null)
                                              return SizedBox.shrink();
                                            final appState =
                                                Provider.of<AppState>(context,
                                                    listen: false);
                                            final runCount = appState
                                                    .currentCounts[lastId] ??
                                                0;
                                            final pizookieCount =
                                                appState.currentPizookieCounts[
                                                        lastId] ??
                                                    0;
                                            final bonusXp = appState
                                                    .currentBonusXP[lastId] ??
                                                0;
                                            final totalShiftXp = appState
                                                    .currentEarnedXP[lastId] ??
                                                0;

                                            d(
                                                '[DEBUG] HOME DISPLAY FIXED: server=$lastId, runs=$runCount, pizookies=$pizookieCount, bonusXp=$bonusXp, actualEarnedXp=$totalShiftXp');
                                            return RichText(
                                              textAlign: TextAlign.right,
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: 'Shift XP Earned: ',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.white70,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 0.3,
                                                      shadows: [
                                                        Shadow(
                                                          blurRadius: 3,
                                                          color: Colors.black87,
                                                          offset: Offset(1, 1),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: '$totalShiftXp',
                                                    style: TextStyle(
                                                      fontSize: 32,
                                                      color: Colors.red[600],
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      letterSpacing: 1.5,
                                                      shadows: [
                                                        Shadow(
                                                          blurRadius: 0,
                                                          color: Colors.white,
                                                          offset: Offset(1, 1),
                                                        ),
                                                        Shadow(
                                                          blurRadius: 0,
                                                          color: Colors.white,
                                                          offset:
                                                              Offset(-1, -1),
                                                        ),
                                                        Shadow(
                                                          blurRadius: 0,
                                                          color: Colors.white,
                                                          offset: Offset(1, -1),
                                                        ),
                                                        Shadow(
                                                          blurRadius: 0,
                                                          color: Colors.white,
                                                          offset: Offset(-1, 1),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        // Current XP / Next at XP
                                        Builder(
                                          builder: (context) {
                                            if (profile == null)
                                              return SizedBox.shrink();
                                            final int xp = profile.points;
                                            final int next =
                                                profile.nextLevelAt;
                                            return Text(
                                              '$xp / Next at $next',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 3,
                                                    color: Colors.black,
                                                    offset: Offset(1, 1),
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.right,
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              // Avatar row
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 0, right: 12.0),
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
                                          if (profile != null)
                                            Positioned(
                                              bottom: 8,
                                              right: 0,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: profile.level >=
                                                            100
                                                        ? 10
                                                        : (profile.level >= 10
                                                            ? 9
                                                            : 7),
                                                    vertical: 2),
                                                decoration: BoxDecoration(
                                                  gradient: AppTheme
                                                      .getLevelBubbleGradient(
                                                          profile.level),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color: Colors.white,
                                                      width: 1.5),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.3),
                                                      blurRadius: 3,
                                                      offset:
                                                          const Offset(0, 1),
                                                    ),
                                                  ],
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
                                    padding: const EdgeInsets.only(
                                        left: 0, right: 0, top: 8, bottom: 8),
                                    child: Builder(
                                      builder: (context) {
                                        final runCount = lastId != null
                                            ? app.currentCounts[lastId] ?? 0
                                            : 0;
                                        final pizookieCount = lastId != null
                                            ? app.currentPizookieCounts[
                                                    lastId] ??
                                                0
                                            : 0;
                                        final workingIds =
                                            app.workingServerIds.toList();
                                        // Rank for runs
                                        final runRanks =
                                            List<String>.from(workingIds);
                                        runRanks.sort((a, b) =>
                                            (app.currentCounts[b] ?? 0)
                                                .compareTo(
                                                    app.currentCounts[a] ?? 0));
                                        final runRank = lastId != null
                                            ? (runRanks.indexOf(lastId) + 1)
                                            : 0;
                                        // Rank for pizookie runs
                                        final pizookieRanks =
                                            List<String>.from(workingIds);
                                        pizookieRanks.sort((a, b) => (app
                                                    .currentPizookieCounts[b] ??
                                                0)
                                            .compareTo(
                                                app.currentPizookieCounts[a] ??
                                                    0));
                                        final pizookieRank = lastId != null
                                            ? (pizookieRanks.indexOf(lastId) +
                                                1)
                                            : 0;
                                        final totalServers = workingIds.length;
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Runs: $runCount',
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 3,
                                                    color: Colors.black,
                                                    offset: Offset(1, 1),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Rank: $runRank/$totalServers',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                    shadows: [
                                                      Shadow(
                                                        blurRadius: 2,
                                                        color: Colors.black,
                                                        offset: Offset(1, 1),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (runRank == 1)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 4),
                                                    child: Icon(
                                                        Icons.emoji_events,
                                                        color:
                                                            Color(0xFFFFD700),
                                                        size: 20), // Gold
                                                  )
                                                else if (runRank == 2)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 4),
                                                    child: Icon(
                                                        Icons.emoji_events,
                                                        color:
                                                            Color(0xFFC0C0C0),
                                                        size: 20), // Silver
                                                  )
                                                else if (runRank == 3)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 4),
                                                    child: Icon(
                                                        Icons.emoji_events,
                                                        color:
                                                            Color(0xFFCD7F32),
                                                        size: 20), // Bronze
                                                  ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Pizookies: $pizookieCount',
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 3,
                                                    color: Colors.black,
                                                    offset: Offset(1, 1),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Rank: $pizookieRank/$totalServers',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                    shadows: [
                                                      Shadow(
                                                        blurRadius: 2,
                                                        color: Colors.black,
                                                        offset: Offset(1, 1),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (pizookieRank == 1)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 4),
                                                    child: Icon(
                                                        Icons.emoji_events,
                                                        color:
                                                            Color(0xFFFFD700),
                                                        size: 20), // Gold
                                                  )
                                                else if (pizookieRank == 2)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 4),
                                                    child: Icon(
                                                        Icons.emoji_events,
                                                        color:
                                                            Color(0xFFC0C0C0),
                                                        size: 20), // Silver
                                                  )
                                                else if (pizookieRank == 3)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 4),
                                                    child: Icon(
                                                        Icons.emoji_events,
                                                        color:
                                                            Color(0xFFCD7F32),
                                                        size: 20), // Bronze
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
                          ),
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

enum _MoreAction { profiles, settings, mvp, colorDemo }

class TeamPieChart extends StatelessWidget {
  final Map<String, int> teamCounts;
  final Map<String, Color> teamColors;
  const TeamPieChart(
      {required this.teamCounts, required this.teamColors, super.key});

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
        titleStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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

    // Check business hours for this context
    final inBusinessHours = app.isOpenNow;

    // Use settings for transition times
    final start = app.todayPlan?.transitionStartMinutes ??
        app.settings.transitionStartMinutes;
    final end = app.todayPlan?.transitionEndMinutes ??
        app.settings.transitionEndMinutes;
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
        // During transition, dinner view shows only dinner-only servers
        final lunchSet = lunchIds.toSet();
        final dinnerSet = dinnerIds.toSet();
        final dinnerOnly = dinnerSet.difference(lunchSet);
        ids = dinnerOnly.toList();
      } else {
        // During transition, lunch view shows all lunch servers
        ids = lunchIds;
      }
    }
    ids = ids.toSet().toList();

    // Sort servers alphabetically by name
    ids.sort((a, b) {
      final serverA = app.serverById(a);
      final serverB = app.serverById(b);
      if (serverA == null && serverB == null) return 0;
      if (serverA == null) return 1;
      if (serverB == null) return -1;
      return serverA.name.toLowerCase().compareTo(serverB.name.toLowerCase());
    });

    bool isDinner =
        (m >= end || (app.activeRosterView == 'dinner' && showToggle));

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
      teamCounts[s.teamColor!] =
          (teamCounts[s.teamColor!] ?? 0) + (app.currentCounts[id] ?? 0);
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
                const Text('Lunch',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Switch(
                  value: app.activeRosterView == 'dinner',
                  onChanged: (val) => app.toggleRosterView(),
                  activeThumbColor: Colors.deepOrange,
                  inactiveThumbColor: Colors.blue,
                  inactiveTrackColor: Colors.blueGrey.shade200,
                ),
                const Text('Dinner',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShiftLeaderboardScreen(
                      app: app,
                      shiftType: isDinner ? 'Dinner' : 'Lunch',
                    ),
                  ),
                );
              },
              child: Center(
                child: Text(
                  isDinner
                      ? 'DINNER ROSTER DISPLAYED'
                      : 'LUNCH ROSTER DISPLAYED',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey,
                      decoration: TextDecoration.underline),
                ),
              ),
            ),
          ),
        TeamPieChart(teamCounts: teamCounts, teamColors: teamColors),
        if (ids.isNotEmpty) ...[
          if (!app.shiftActive)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ShiftStartNotice(app: app),
            ),
          Expanded(
            child:
                _ActiveGrid(ids: ids, shiftActive: app.shiftActive, app: app, inBusinessHours: inBusinessHours),
          ),
        ],
        if (ids.isEmpty)
          Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Who’s Working Today?",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ) ??
                        const TextStyle(
                            fontSize: 36, fontWeight: FontWeight.w800),
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
          ),
      ],
    );
  }
}

class _ActiveGrid extends StatefulWidget {
  final List<String> ids;
  final bool shiftActive;
  final AppState app;
  final bool inBusinessHours;
  const _ActiveGrid(
      {required this.ids, required this.shiftActive, required this.app, required this.inBusinessHours});

  @override
  State<_ActiveGrid> createState() => _ActiveGridState();
}

class _ActiveGridState extends State<_ActiveGrid>
    with TickerProviderStateMixin {
  bool _isLongPress = false;
  String? _achievementText;
  AnimationController? _achievementController;
  String? _flashText;
  String? _flashSubText;
  FeedbackPriority _flashPriority = FeedbackPriority.low;
  AnimationController? _xpController;
  AnimationController? _subController;

  // Speed tracking for instant gratification
  final Map<String, DateTime> _lastTapTime = {};
  final Map<String, int> _consecutiveTaps = {};
  final Map<String, int> _previousRanks = {};

  @override
  void initState() {
    super.initState();
    _achievementController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5500));
    _xpController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _subController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
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

  /// Track consecutive rapid taps for speed feedback
  void _trackSpeedMomentum(String serverId) {
    final now = DateTime.now();
    final lastTap = _lastTapTime[serverId];

    if (lastTap != null &&
        now.difference(lastTap) < const Duration(seconds: 3)) {
      _consecutiveTaps[serverId] = (_consecutiveTaps[serverId] ?? 0) + 1;
    } else {
      _consecutiveTaps[serverId] = 1;
    }

    _lastTapTime[serverId] = now;
  }

  /// Determine appropriate feedback type based on context
  FeedbackType _determineFeedbackType(String serverId, int runCount) {
    // Priority 1: Milestones (every 5 runs)
    if (runCount % 5 == 0) return FeedbackType.milestone;

    // Priority 2: Speed moments (2+ rapid taps)
    if ((_consecutiveTaps[serverId] ?? 0) >= 2) return FeedbackType.speed;

    // Priority 3: Rank changes (implement later)
    // if (_rankChanged(serverId)) return FeedbackType.competitive;

    // Default: Basic encouragement
    return FeedbackType.basic;
  }

  /// Get SnackBar color based on feedback priority
  Color _getSnackBarColor(FeedbackPriority priority) {
    switch (priority) {
      case FeedbackPriority.low:
        return Colors.amber.shade600;
      case FeedbackPriority.medium:
        return Colors.orange.shade600;
      case FeedbackPriority.high:
        return Colors.red.shade600;
      case FeedbackPriority.epic:
        return Colors.purple.shade600;
    }
  }

  void _showFlash(String text, String subText,
      {bool forAchievement = false, FeedbackPriority? priority}) {
    final app = widget.app;
    // If this is for an achievement, only show if gamification is enabled
    if (forAchievement && !app.settings.gamificationEnabled) return;
    setState(() {
      _flashText = text;
      _flashSubText = subText;
      _flashPriority = priority ?? FeedbackPriority.low;
    });

    // Track this flash message in AppState for the last run server
    final lastServerId = app.lastRunServerId;
    if (lastServerId != null) {
      app.setLastFlashMessage(lastServerId, text);
    }

    _xpController?.forward(from: 0);
    _subController?.forward(from: 0);
  }

  void _showEnhancedFlash(String message, FeedbackPriority priority,
      {String? subText}) {
    setState(() {
      _flashText = message;
      _flashSubText = subText ?? '';
      _flashPriority = priority;
    });

    // Track this flash message in AppState for the last run server
    final app = Provider.of<AppState>(context, listen: false);
    final lastServerId = app.lastRunServerId;
    if (lastServerId != null) {
      app.setLastFlashMessage(lastServerId, message);
    }

    // Use priority-based animation duration
    final duration = InstantFeedbackService.getAnimationDuration(priority);
    _xpController?.reset();
    _xpController?.forward();
    _subController?.reset();
    _subController?.forward();
  }

  void _showAchievement(String text) {
    final app = widget.app;
    if (!app.settings.gamificationEnabled) return;
  d('[_showAchievement] called with: $text');
    if (!mounted) return;
    setState(() {
      _achievementText = text;
    });
    _achievementController?.reset();
    _achievementController?.forward();
  }

  Color _tierColor(int myRuns, int maxRuns, int myPizookies, int maxPizookies) {
    // Calculate XP for current shift (10 XP per run + 25 XP per pizookie)
    final myXP = (myRuns * 10) + (myPizookies * 25);
    final maxXP = (maxRuns * 10) + (maxPizookies * 25);

    if (maxXP <= 0) return Colors.grey.shade400;

    final ratio = myXP / maxXP;
    if (ratio >= 0.80) return const Color(0xFF1B5E20); // deep green
    if (ratio >= 0.60) return const Color(0xFF43A047); // green
    if (ratio >= 0.30) return const Color(0xFFFBC02D); // yellow
    if (ratio >= 0.10) return const Color(0xFFEF5350); // light red
    return const Color(0xFFB71C1C); // deep red
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
    final pizookieCounts =
        ids.map((id) => app.currentPizookieCounts[id] ?? 0).toList();
    final maxCount =
        counts.isEmpty ? 0 : counts.reduce((a, b) => a > b ? a : b);
    final maxPizookieCount = pizookieCounts.isEmpty
        ? 0
        : pizookieCounts.reduce((a, b) => a > b ? a : b);
    final total = counts.fold<int>(0, (a, b) => a + b);
    final columns = MediaQuery.of(context).size.width > 800 ? 4 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Long Press When Running a Pizookie!',
                  style: TextStyle(
                    color: Colors.brown.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 1.0,
                    shadows: const [
                      Shadow(
                          blurRadius: 2,
                          color: Colors.black12,
                          offset: Offset(1, 1))
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: WallpaperBackground(
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

                      // Capture business hours state for this server tile
                      final isRestaurantOpen = widget.inBusinessHours;

                      final my = app.currentCounts[id] ?? 0;
                      final myPizookies = app.currentPizookieCounts[id] ?? 0;
                      final pct = total == 0 ? 0 : ((my / total) * 100).round();
                      final color = _tierColor(
                          my, maxCount, myPizookies, maxPizookieCount);
                      final level = app.profiles[id]?.level ?? 1;
                      final borderColor =
                          _teamColor(s.teamColor) ?? Colors.transparent;
                      final points = app.profiles[id]?.points ?? 0;
                      final nextLevelAt = app.profiles[id]?.nextLevelAt ?? 0;
                      final pointsToNext =
                          (nextLevelAt - points).clamp(0, 999999);

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
                      final isLunch = m <
                          (plan?.transitionEndMinutes ??
                              app.settings.transitionEndMinutes);
                      // Load section assignments (async)
                      return FutureBuilder<Map<String, String?>>(
                        future: loadSectionAssignments(isLunch),
                        builder: (context, snapshot) {
                          String? section;
                          if (snapshot.connectionState ==
                                  ConnectionState.done &&
                              snapshot.hasData) {
                            section = snapshot.data![id];
                          }
                          // Calculate progress for XP bar
                          double progress = 1.0;
                          if (nextLevelXp > prevLevelXp) {
                            progress = ((points - prevLevelXp) /
                                    (nextLevelXp - prevLevelXp))
                                .clamp(0.0, 1.0);
                          }
                          return OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: widget.inBusinessHours ? color : Colors.grey[300],
                              foregroundColor: widget.inBusinessHours ? Colors.white : Colors.grey[600],
                              side: BorderSide(
                                color: widget.inBusinessHours ? borderColor : Colors.grey[400]!,
                                width:
                                    borderColor == Colors.transparent ? 0 : 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(8),
                            ),
                            onPressed: !widget.inBusinessHours ? null : () {
                              d('[DEBUG] Server ${s.name} (id: $id) clicked');
                              d('[DEBUG] isOpenNow: ${app.isOpenNow}');
                              d('[DEBUG] shiftActive: ${app.shiftActive}');
                              d('[DEBUG] workingServerIds: ${app.workingServerIds}');
                              d('[DEBUG] workingServerIds.contains($id): ${app.workingServerIds.contains(id)}');

                              // Only increment normal run on tap, not on long press
                              if (!_isLongPress) {
                                // Check if shift is active and server is working
                                if (app.shiftActive &&
                                    app.workingServerIds.contains(id)) {
                                  final milestone = app.increment(id);

                                  // Calculate base XP and apply boost if active
                                  int baseXP = 10;
                                  int xpEarned = baseXP;
                                  bool isBoostActive = app.boostActive;

                                  // Apply boost for base XP
                                  if (isBoostActive) {
                                    xpEarned =
                                        (baseXP * app.boostMultiplier).round();
                                  }

                                  // For boost display notification (but variety messages already include XP)
                                  String boostDisplayText = '';
                                  if (isBoostActive) {
                                    boostDisplayText =
                                        '\n🚀 BOOST ${app.boostMultiplier}x!';
                                  }

                                  // ✨ REAL MILESTONE SYSTEM ✨
                                  if (milestone != null) {
                                    // Show the real milestone achievement
                                    _showEnhancedFlash(
                                      milestone.message,
                                      milestone.priority,
                                      subText: milestone.subMessage,
                                    );

                                    // Enhanced SnackBar for milestone
                                    if (app
                                        .settings.encouragementFlashEnabled) {
                                      ScaffoldMessenger.of(ctx)
                                          .clearSnackBars();
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${milestone.message}\n${milestone.subMessage}'),
                                          duration: InstantFeedbackService
                                              .getAnimationDuration(
                                                  milestone.priority),
                                          backgroundColor: _getSnackBarColor(
                                              milestone.priority),
                                        ),
                                      );
                                    }
                                  } else {
                                    // Regular run - use instant gratification for variety
                                    _trackSpeedMomentum(id);
                                    final newRunCount =
                                        app.currentCounts[id] ?? 0;
                                    final feedbackType =
                                        _determineFeedbackType(id, newRunCount);
                                    final feedbackPriority =
                                        InstantFeedbackService.getPriority(
                                            feedbackType,
                                            runCount: newRunCount);

                                    // Get smart contextual message for regular runs with XP (already includes XP display)
                                    final contextMessage =
                                        InstantFeedbackService
                                            .getInstantMessage(feedbackType,
                                                runCount: newRunCount,
                                                xpAmount: xpEarned);
                                    final smartMessage = contextMessage +
                                        boostDisplayText; // Add boost indicator if active

                                    _showEnhancedFlash(
                                      smartMessage,
                                      feedbackPriority,
                                      subText: 'Next level: $pointsToNext XP',
                                    );

                                    // Enhanced SnackBar with contextual message including XP
                                    if (app
                                        .settings.encouragementFlashEnabled) {
                                      final contextualMsg =
                                          InstantFeedbackService
                                              .getInstantMessage(feedbackType,
                                                  runCount: newRunCount,
                                                  xpAmount: xpEarned);
                                      ScaffoldMessenger.of(ctx)
                                          .clearSnackBars();
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text(contextualMsg),
                                          duration: InstantFeedbackService
                                              .getAnimationDuration(
                                                  feedbackPriority),
                                          backgroundColor: _getSnackBarColor(
                                              feedbackPriority),
                                        ),
                                      );
                                    }
                                  }

                                  final bubble = app.recentBadgeBubble;
                                  if (bubble != null) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                          content: Text(bubble),
                                          duration: const Duration(seconds: 3)),
                                    );
                                    app.clearRecentBadgeBubble();
                                  }

                                  // Set lastRunServerId so avatar appears in bottom grey area
                                  app.lastRunServerId = id;
                                } else {
                                  // Shift not active or server not working - show message
                                  d(
                                      '[DEBUG] Click blocked: Shift not active or server not scheduled');
                                  ScaffoldMessenger.of(ctx).clearSnackBars();
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Shift not active or server not scheduled!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                            onLongPress: () {
                              _isLongPress = true;
                              final milestone = app.incrementPizookie(id);

                              // Calculate boosted Pizookie XP
                              const basePizookieXP =
                                  35; // Increased from 25 to promote pizookie running
                              final isBoostActive = app.boostActive;
                              final xpEarned = isBoostActive
                                  ? (basePizookieXP * app.boostMultiplier)
                                      .round()
                                  : basePizookieXP;

                              // ✨ REAL PIZOOKIE MILESTONE SYSTEM ✨
                              if (milestone != null) {
                                // Show the real pizookie milestone achievement
                                _showEnhancedFlash(
                                  milestone.message,
                                  milestone.priority,
                                  subText: milestone.subMessage,
                                );
                              } else {
                                // Regular pizookie - use instant gratification with XP (already includes XP display)
                                final pizookieMessage =
                                    InstantFeedbackService.getInstantMessage(
                                        FeedbackType.pizookie,
                                        xpAmount: xpEarned);
                                final pizookiePriority =
                                    InstantFeedbackService.getPriority(
                                        FeedbackType.pizookie);

                                String flashText =
                                    pizookieMessage; // Message already includes XP
                                String subText = 'Sweet! Ran a Pizookie';

                                if (isBoostActive) {
                                  flashText =
                                      '$pizookieMessage\n🚀 BOOST ${app.boostMultiplier}x!';
                                  subText =
                                      'BOOST ${app.boostMultiplier}x • Sweet!';
                                }

                                _showEnhancedFlash(
                                  flashText,
                                  pizookiePriority,
                                  subText: subText,
                                );
                              }

                              Future.delayed(const Duration(milliseconds: 100),
                                  () {
                                _isLongPress = false;
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Progress bar row
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 2.0, top: 10, left: 4, right: 2),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Current level (left) - big, bold, with background, wider for double digits
                                      GestureDetector(
                                        onLongPress: () {
                                          Future.delayed(
                                              const Duration(seconds: 2), () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => Dialog(
                                                insetPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 24,
                                                        vertical: 60),
                                                backgroundColor:
                                                    Colors.transparent,
                                                child: SizedBox(
                                                  width: 340,
                                                  height: 520,
                                                  child: ProfileDetailScreen(
                                                      serverId: id),
                                                ),
                                              ),
                                            );
                                          });
                                        },
                                        child: Container(
                                          width: level >= 100
                                              ? 56
                                              : (level >= 10 ? 50 : 44),
                                          height: 32,
                                          decoration: BoxDecoration(
                                            gradient:
                                                AppTheme.getLevelBubbleGradient(
                                                    level),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color: Colors.white,
                                                width: 1.5),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.3),
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
                                                Shadow(
                                                    blurRadius: 2,
                                                    color: Colors.black54,
                                                    offset: Offset(1, 1)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Progress bar
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 2.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              minHeight: 10,
                                              backgroundColor: Colors.white24,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
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
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${level + 1}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                  blurRadius: 1,
                                                  color: Colors.black38,
                                                  offset: Offset(1, 1)),
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
                                              Shadow(
                                                  blurRadius: 6,
                                                  color: Colors.black45,
                                                  offset: Offset(0, 2)),
                                            ],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (section != null &&
                                            section.isNotEmpty) ...[
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
                                                  Shadow(
                                                      blurRadius: 2,
                                                      color: Colors.black45,
                                                      offset: Offset(0, 1)),
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
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'Pizookies: ${app.shiftActive ? (app.currentPizookieCounts[id]?.toString() ?? '0') : '0'}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500),
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
                          ? ((points - prevLevelXp) /
                                  (nextLevelXp - prevLevelXp))
                              .clamp(0.0, 1.0)
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
                          final milestone = app.increment(id);

                          // Calculate base XP and apply boost if active
                          int baseXP = 10;
                          int xpEarned = baseXP;
                          bool isBoostActive = app.boostActive;

                          // Apply boost for base XP
                          if (isBoostActive) {
                            xpEarned = (baseXP * app.boostMultiplier).round();
                          }

                          // ✨ REAL MILESTONE SYSTEM ✨
                          if (milestone != null) {
                            // Show the real milestone achievement
                            if (app.settings.gamificationEnabled) {
                              _showFlash(
                                milestone.message,
                                milestone.subMessage,
                                forAchievement: true,
                                priority: milestone.priority,
                              );
                            }
                          } else {
                            // Regular run - show boost if enabled
                            if (app.settings.gamificationEnabled) {
                              String flashText = '+$xpEarned XP';
                              if (isBoostActive) {
                                flashText =
                                    '🚀 +$xpEarned XP\nBOOST ${app.boostMultiplier}x!';
                              }
                              _showFlash(
                                flashText,
                                'Great job!',
                              );
                            }
                          }

                          final msg = encouragements[
                              Random().nextInt(encouragements.length)];
                          ScaffoldMessenger.of(ctx).clearSnackBars();
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                                content: Text(msg),
                                duration: const Duration(seconds: 3)),
                          );

                          final bubble = app.recentBadgeBubble;
                          if (bubble != null) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                  content: Text(bubble),
                                  duration: const Duration(seconds: 3)),
                            );
                            app.clearRecentBadgeBubble();
                          }
                        },
                        onLongPress: () {
                          final milestone = app.incrementPizookie(id);

                          // Calculate boosted Pizookie XP
                          const basePizookieXP =
                              35; // Increased from 25 to promote pizookie running
                          final isBoostActive = app.boostActive;
                          final xpEarned = isBoostActive
                              ? (basePizookieXP * app.boostMultiplier).round()
                              : basePizookieXP;

                          // ✨ REAL PIZOOKIE MILESTONE SYSTEM ✨
                          if (milestone != null) {
                            // Show the real pizookie milestone achievement
                            _showFlash(
                              milestone.message,
                              milestone.subMessage,
                              forAchievement: true,
                              priority: milestone.priority,
                            );
                          } else {
                            // Regular pizookie
                            String flashText = '+$xpEarned XP\nPizookie!';
                            String subText = 'Sweet!  Ran a Pizookie';

                            if (isBoostActive) {
                              flashText = '🚀 +$xpEarned XP\nBOOST Pizookie!';
                              subText =
                                  'BOOST ${app.boostMultiplier}x • Sweet!';
                            }

                            _showFlash(
                              flashText,
                              subText,
                            );
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Progress bar row
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 10.0, top: 10, left: 4, right: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Current level (left) - big, bold, with background, wider for double digits
                                  GestureDetector(
                                    onLongPress: () {
                                      Future.delayed(const Duration(seconds: 2),
                                          () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => Dialog(
                                            insetPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 60),
                                            backgroundColor: Colors.transparent,
                                            child: SizedBox(
                                              width: 340,
                                              height: 520,
                                              child: ProfileDetailScreen(
                                                  serverId: id),
                                            ),
                                          ),
                                        );
                                      });
                                    },
                                    child: Container(
                                      width: level >= 100
                                          ? 56
                                          : (level >= 10 ? 50 : 44),
                                      height: 32,
                                      decoration: BoxDecoration(
                                        gradient:
                                            AppTheme.getLevelBubbleGradient(
                                                level),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: Colors.white, width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
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
                                            Shadow(
                                                blurRadius: 2,
                                                color: Colors.black54,
                                                offset: Offset(1, 1)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Progress bar
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 2.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 10,
                                          backgroundColor: Colors.white24,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
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
                                          Shadow(
                                              blurRadius: 1,
                                              color: Colors.black38,
                                              offset: Offset(1, 1)),
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
                                          Shadow(
                                              blurRadius: 6,
                                              color: Colors.black45,
                                              offset: Offset(0, 2)),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Shift: $my  •  $pct%',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'Pizookies: ${app.profiles[id]?.pizookieRuns ?? 0}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500),
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
                                  final scale =
                                      1.0 + 0.5 * (1.0 - _xpController!.value);
                                  return Opacity(
                                    opacity: opacity,
                                    child: Transform.scale(
                                      scale: scale,
                                      child: SizedBox(
                                        width: MediaQuery.of(context)
                                                .size
                                                .width -
                                            32, // Screen width minus padding
                                        child: Text(
                                          _flashText ?? '',
                                          style: InstantFeedbackService
                                              .getTextStyle(_flashPriority),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
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
                                    final fadeProgress =
                                        ((subValue - fadeStart) /
                                                (1.0 - fadeStart))
                                            .clamp(0.0, 1.0);
                                    final opacity = 1.0 - fadeProgress;
                                    return Opacity(
                                      opacity: opacity,
                                      child: Center(
                                        child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width -
                                              32, // Screen width minus padding
                                          child: Text(
                                            _flashSubText!,
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 1.2,
                                              shadows: [
                                                Shadow(
                                                    blurRadius: 10,
                                                    color: Colors.black,
                                                    offset: Offset(0, 0)),
                                                Shadow(
                                                    blurRadius: 16,
                                                    color: Colors.black87,
                                                    offset: Offset(2, 2)),
                                                Shadow(
                                                    blurRadius: 24,
                                                    color: Colors.black54,
                                                    offset: Offset(-2, -2)),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
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
                            d(
                                '[AchievementOverlay] builder: _achievementText=$_achievementText, controller.value=${_achievementController!.value}');
                            final opacity = 1.0 - _achievementController!.value;
                            final scale = 1.0 +
                                0.2 * (1.0 - _achievementController!.value);
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
                                        Shadow(
                                            blurRadius: 24,
                                            color: Colors.black54,
                                            offset: Offset(0, 6)),
                                        Shadow(
                                            blurRadius: 32,
                                            color: Colors.amberAccent,
                                            offset: Offset(0, 0)),
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
                                          Shadow(
                                              blurRadius: 12,
                                              color: Colors.black,
                                              offset: Offset(0, 0)),
                                          Shadow(
                                              blurRadius: 24,
                                              color: Colors.black54,
                                              offset: Offset(2, 2)),
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
        ),
      ],
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
  bool _sortByRuns = true; // true = runs, false = pizookies

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
    final isAfterTransition = m >=
        (plan?.transitionEndMinutes ??
            widget.app.settings.transitionEndMinutes);
    final header = showLunch ? 'Lunch' : 'Dinner';

    // --- Get the correct roster and sort by selected metric ---
    final ids = showLunch ? lunchIds : dinnerIds;
    final sortedIds = [...ids];

    if (_sortByRuns) {
      sortedIds.sort((a, b) => (widget.app.currentCounts[b] ?? 0)
          .compareTo(widget.app.currentCounts[a] ?? 0));
    } else {
      sortedIds.sort((a, b) => (widget.app.profiles[b]?.pizookieRuns ?? 0)
          .compareTo(widget.app.profiles[a]?.pizookieRuns ?? 0));
    }

    // Calculate enhanced metrics
    final counts =
        sortedIds.map((id) => widget.app.currentCounts[id] ?? 0).toList();
    final totalRuns = counts.fold<int>(0, (a, b) => a + b);
    final avgRuns = totalRuns > 0 ? totalRuns / sortedIds.length : 0.0;
    final maxRuns =
        counts.isNotEmpty ? counts.reduce((a, b) => a > b ? a : b) : 0;
    final activeServers = counts.where((c) => c > 0).length;

    return AlertDialog(
      backgroundColor: Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '🍴 $header Leaderboard',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2),
              textAlign: TextAlign.center,
            ),
          ),
          if (showLunch && isAfterTransition)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange[300]!, width: 1),
              ),
              child: const Text('✅ FINALIZED',
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold)),
            ),
          // Fun statistics row
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('🎯', 'Total', '$totalRuns'),
                _buildStatItem('📊', 'Average', avgRuns.toStringAsFixed(1)),
                _buildStatItem('🔥', 'Top Score', '$maxRuns'),
                _buildStatItem(
                    '⚡', 'Active', '$activeServers/${sortedIds.length}'),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Enhanced toggle buttons with sort options
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ToggleButtons(
                    isSelected: [showLunch, !showLunch],
                    onPressed: (idx) => setState(() => showLunch = idx == 0),
                    borderRadius: BorderRadius.circular(25),
                    constraints:
                        const BoxConstraints(minWidth: 80, minHeight: 36),
                    selectedColor: Colors.white,
                    fillColor: Theme.of(context).primaryColor,
                    children: const [Text('🍽️ Lunch'), Text('🌙 Dinner')],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: ToggleButtons(
                  isSelected: [_sortByRuns, !_sortByRuns],
                  onPressed: (idx) => setState(() => _sortByRuns = idx == 0),
                  borderRadius: BorderRadius.circular(25),
                  constraints:
                      const BoxConstraints(minWidth: 60, minHeight: 36),
                  selectedColor: Colors.white,
                  fillColor: Colors.orange,
                  children: const [
                    Text('🏃', style: TextStyle(fontSize: 18)),
                    Text('🍪', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Enhanced server list with progress bars
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: sortedIds.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, i) {
                final id = sortedIds[i];
                final server = widget.app.servers.firstWhere((s) => s.id == id,
                    orElse: () => Server(id: id, name: 'Unknown'));
                final count = widget.app.currentCounts[id] ?? 0;
                final pizookieRuns = widget.app.profiles[id]?.pizookieRuns ?? 0;
                final pct = totalRuns > 0 ? ((count / totalRuns) * 100) : 0.0;
                final isTop3 = i < 3;

                return _buildEnhancedServerRow(
                  server: server,
                  rank: i + 1,
                  runs: count,
                  pizookies: pizookieRuns,
                  percentage: pct,
                  maxRuns: maxRuns,
                  isTop3: isTop3,
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[400]!, Colors.grey[500]!],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String emoji, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedServerRow({
    required Server server,
    required int rank,
    required int runs,
    required int pizookies,
    required double percentage,
    required int maxRuns,
    required bool isTop3,
  }) {
    // Determine rank styling
    String rankEmoji = '';
    Color? rankColor;
    Color backgroundColor = Colors.transparent;

    if (rank == 1) {
      rankEmoji = '🥇';
      rankColor = const Color(0xFFFFD700);
      backgroundColor = const Color(0xFFFFF8DC);
    } else if (rank == 2) {
      rankEmoji = '🥈';
      rankColor = const Color(0xFFC0C0C0);
      backgroundColor = const Color(0xFFF5F5F5);
    } else if (rank == 3) {
      rankEmoji = '🥉';
      rankColor = const Color(0xFFCD7F32);
      backgroundColor = const Color(0xFFFFF0E6);
    } else {
      rankEmoji = '#$rank';
    }

    // Determine activity indicators
    String activityIndicator = '';
    if (runs == 0) {
      activityIndicator = '😴';
    } else if (runs >= maxRuns * 0.8) {
      activityIndicator = '🔥';
    } else if (runs >= maxRuns * 0.5) {
      activityIndicator = '⚡';
    } else {
      activityIndicator = '👍';
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: isTop3
            ? Border.all(color: rankColor!.withOpacity(0.3), width: 1)
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: rankColor?.withOpacity(0.2) ?? Colors.grey[200],
          child: Text(
            rankEmoji,
            style: TextStyle(
              fontSize: isTop3 ? 16 : 12,
              fontWeight: FontWeight.bold,
              color: rankColor ?? Colors.grey[600],
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                server.name,
                style: TextStyle(
                  fontWeight: isTop3 ? FontWeight.bold : FontWeight.w600,
                  fontSize: isTop3 ? 15 : 14,
                  color: rankColor ?? Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              activityIndicator,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Progress bar
            LinearProgressIndicator(
              value: maxRuns > 0 ? (runs / maxRuns) : 0.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isTop3
                    ? (rankColor ?? Theme.of(context).primaryColor)
                    : Theme.of(context).primaryColor,
              ),
              minHeight: 6,
            ),
            const SizedBox(height: 6),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🏃 $runs runs',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  '🍪 $pizookies',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color:
                        percentage > 0 ? Colors.green[700] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BoostModeDialog extends StatefulWidget {
  const BoostModeDialog({super.key});

  @override
  _BoostModeDialogState createState() => _BoostModeDialogState();
}

class _BoostModeDialogState extends State<BoostModeDialog> {
  double _multiplier = 2.0;
  int _duration = 60; // minutes (1 hour default)
  String _description = '';
  bool _isAuthenticated = false;
  String _enteredPin = '';

  void _onPinNumberPressed(String number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += number;
        if (_enteredPin.length == 4) {
          _authenticatePin();
        }
      });
    }
  }

  void _onPinBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _onPinClear() {
    setState(() {
      _enteredPin = '';
    });
  }

  void _authenticatePin() {
    if (_enteredPin == '5520') {
      setState(() {
        _isAuthenticated = true;
      });
    } else {
      setState(() {
        _enteredPin = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Incorrect PIN'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _activateBoost() {
    final appState = Provider.of<AppState>(context, listen: false);

    if (appState.boostActive) {
      // Deactivate current boost
      appState.deactivateBoost();
    } else {
      // Activate new boost
      appState.activateBoost(
          _multiplier,
          _duration,
          _description.isEmpty ? 'Manager Boost' : _description,
          _enteredPin);
    }

    Navigator.of(context).pop();
  }

  Widget _buildPinButton(String number) {
    return SizedBox(
      width: 60,
      height: 60,
      child: ElevatedButton(
        onPressed: () => _onPinNumberPressed(number),
        style: ElevatedButton.styleFrom(
          shape: CircleBorder(),
          padding: EdgeInsets.all(0),
          backgroundColor: Colors.blue[50],
          foregroundColor: Colors.blue[800],
        ),
        child: Text(
          number,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPinActionButton(
      IconData icon, String tooltip, VoidCallback onPressed) {
    return SizedBox(
      width: 60,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: CircleBorder(),
          padding: EdgeInsets.all(0),
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.grey[700],
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }

  Widget _buildMultiplierButton(double multiplier) {
    final isSelected = _multiplier == multiplier;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _multiplier = multiplier;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.orange : Colors.grey[200],
            foregroundColor: isSelected ? Colors.white : Colors.grey[700],
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(
            '${multiplier.toInt()}x',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationButton(String label, int minutes) {
    final isSelected = _duration == minutes;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _duration = minutes;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
            foregroundColor: isSelected ? Colors.white : Colors.grey[700],
            padding: EdgeInsets.symmetric(vertical: 10),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.rocket_launch, color: Colors.orange),
          SizedBox(width: 8),
          Text('Boost Mode'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isAuthenticated) ...[
              Text(
                'Enter Manager PIN to access Boost Mode:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              // PIN Display
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < 4; i++)
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _enteredPin.length
                              ? Colors.blue
                              : Colors.grey[300],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // PIN Pad
              SizedBox(
                width: 250,
                child: Column(
                  children: [
                    // Row 1: 1, 2, 3
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPinButton('1'),
                        _buildPinButton('2'),
                        _buildPinButton('3'),
                      ],
                    ),
                    SizedBox(height: 12),
                    // Row 2: 4, 5, 6
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPinButton('4'),
                        _buildPinButton('5'),
                        _buildPinButton('6'),
                      ],
                    ),
                    SizedBox(height: 12),
                    // Row 3: 7, 8, 9
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPinButton('7'),
                        _buildPinButton('8'),
                        _buildPinButton('9'),
                      ],
                    ),
                    SizedBox(height: 12),
                    // Row 4: Clear, 0, Backspace
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPinActionButton(
                            Icons.clear, 'Clear', _onPinClear),
                        _buildPinButton('0'),
                        _buildPinActionButton(
                            Icons.backspace, 'Back', _onPinBackspace),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (appState.boostActive) ...[
              Text(
                'Boost is currently ACTIVE!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange),
              ),
              SizedBox(height: 16),
              Text('Multiplier: ${appState.boostMultiplier}x'),
              Text('Time Remaining: ${appState.boostTimeRemaining}'),
              Text('Description: ${appState.boostDescription}'),
            ] else ...[
              Text(
                'Configure Boost Settings:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('XP Multiplier:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMultiplierButton(2.0),
                  _buildMultiplierButton(3.0),
                  _buildMultiplierButton(4.0),
                ],
              ),
              SizedBox(height: 20),
              Text('Duration:', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDurationButton('1 Hour', 60),
                      _buildDurationButton('2 Hours', 120),
                      _buildDurationButton('4 Hours', 240),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDurationButton('Lunch Shift', 300), // 5 hours
                      _buildDurationButton('Dinner Shift', 360), // 6 hours
                      _buildDurationButton('All Day', 720), // 12 hours
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'e.g., Friday Night Rush',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _description = value;
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        if (_isAuthenticated)
          ElevatedButton(
            onPressed: _activateBoost,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  appState.boostActive ? Colors.red : Colors.orange,
            ),
            child: Text(
                appState.boostActive ? 'Deactivate Boost' : 'Activate Boost'),
          ),
      ],
    );
  }
}
