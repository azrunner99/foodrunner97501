
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:outlined_text/outlined_text.dart';
import 'dart:io';

import '../app_state.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import 'shift_leaderboard_screen.dart';
import '../gamification.dart';
import '../section_assignments.dart';
import '../widgets/wallpaper_background.dart';
import '../widgets/birthday_anniversary_banner.dart';
import '../widgets/live_countdown_timer.dart';
import 'app_features_screen.dart';
import 'level_color_demo_screen.dart';

// Screens
import 'update_roster_screen.dart';
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
            Text('Found $backupCount existing backup${backupCount > 1 ? 's' : ''} on this device.'),
            const SizedBox(height: 16),
            const Text('This appears to be a fresh app installation. Would you like to:'),
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
                        content: Text('Navigate to "Data Backup & Restore" to restore your data'),
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
  void _showCurrentShiftTotalsDialog(BuildContext context, AppState app, bool isDinner) {
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
  String _shiftSortBy = 'runs';
  int _runnerTapCount = 0;
  DateTime? _lastTapTime;
  bool _isLongPress = false;

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
    if (_lastTapTime == null || now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
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
    print('HomeScreen.build called');
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
                    MaterialPageRoute(builder: (_) => const LevelColorDemoScreen()),
                  );
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: _MoreAction.profiles,
                  child: ListTile(
                    leading: Icon(Icons.person, color: Colors.blue[700]),
                    title: const Text('Profiles', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: _MoreAction.mvp,
                  child: ListTile(
                    leading: Icon(Icons.emoji_events, color: Colors.amber[600]),
                    title: const Text('Leaderboards', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: _MoreAction.colorDemo,
                  child: ListTile(
                    leading: Icon(Icons.palette, color: Colors.purple[400]),
                    title: const Text('Server Levels', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: _MoreAction.settings,
                  child: ListTile(
                    leading: Icon(Icons.settings, color: Colors.blue[400]),
                    title: const Text('Settings', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
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
                print('[DEBUG] HomeScreen: m=$m, start=$start, end=$end');
                print('[DEBUG] HomeScreen: lunchIds=$lunchIds, dinnerIds=$dinnerIds');
                print('[DEBUG] HomeScreen: activeRosterView=${app.activeRosterView}');
                
                // Check if we're in an overnight period
                final todayWeekday = now.weekday;
                final yesterdayWeekday = todayWeekday == 1 ? 7 : todayWeekday - 1;
                final closeTime = app.hours.closeMinutes[todayWeekday] ?? 23 * 60;
                final yesterdayCloseTime = app.hours.closeMinutes[yesterdayWeekday] ?? 23 * 60;
                
                // Check if we're in yesterday's overnight period
                final isYesterdayOvernight = yesterdayCloseTime >= 1440;
                final effectiveYesterdayClose = isYesterdayOvernight ? yesterdayCloseTime - 1440 : yesterdayCloseTime;
                final inYesterdayOvernight = isYesterdayOvernight && m < effectiveYesterdayClose;
                
                // Check today's overnight status
                final isOvernight = closeTime >= 1440;
                final effectiveCloseTime = isOvernight ? closeTime - 1440 : closeTime;
                
                print('[DEBUG] HomeScreen: todayWeekday=$todayWeekday, yesterdayWeekday=$yesterdayWeekday');
                print('[DEBUG] HomeScreen: closeTime=$closeTime, yesterdayCloseTime=$yesterdayCloseTime');
                print('[DEBUG] HomeScreen: isOvernight=$isOvernight, isYesterdayOvernight=$isYesterdayOvernight');
                print('[DEBUG] HomeScreen: effectiveCloseTime=$effectiveCloseTime, effectiveYesterdayClose=$effectiveYesterdayClose');
                print('[DEBUG] HomeScreen: inYesterdayOvernight=$inYesterdayOvernight');
                
                List<String> ids = [];
                final showToggle = m >= start && m < end;
                print('[DEBUG] HomeScreen: showToggle=$showToggle (transition period)');
                
                // Handle overnight operations properly
                bool shouldShowDinner = false;
                if (inYesterdayOvernight) {
                  // We're past midnight during yesterday's overnight shift
                  shouldShowDinner = true;
                  print('[DEBUG] HomeScreen: In yesterday\'s overnight period - showing dinner roster');
                } else if (isOvernight && m < effectiveCloseTime) {
                  // We're past midnight during today's overnight shift
                  shouldShowDinner = true;
                  print('[DEBUG] HomeScreen: In today\'s overnight period - showing dinner roster');
                } else if (m < start) {
                  shouldShowDinner = false;
                  print('[DEBUG] HomeScreen: Before transition, using lunch roster');
                } else if (m >= end) {
                  shouldShowDinner = true;
                  print('[DEBUG] HomeScreen: After transition, using dinner roster');
                } else {
                  // During transition: show correct servers for each view
                  shouldShowDinner = (app.activeRosterView == 'dinner');
                  print('[DEBUG] HomeScreen: During transition, activeRosterView=${app.activeRosterView}');
                }
                
                if (shouldShowDinner) {
                  if (m >= start && m < end && app.activeRosterView == 'dinner') {
                    // Dinner view during transition: show only dinner-only servers
                    final lunchSet = lunchIds.toSet();
                    final dinnerSet = dinnerIds.toSet();
                    final dinnerOnly = dinnerSet.difference(lunchSet);
                    ids = dinnerOnly.toList();
                    print('[DEBUG] HomeScreen: During transition, dinner view selected - showing dinner-only servers: $ids');
                  } else {
                    ids = dinnerIds;
                    print('[DEBUG] HomeScreen: Showing dinner roster: $ids');
                  }
                } else {
                  ids = lunchIds;
                  print('[DEBUG] HomeScreen: Showing lunch roster: $ids');
                }
                ids = ids.toSet().toList();
                print('[DEBUG] HomeScreen: Final ids to display: $ids');
                
                // Sort servers alphabetically by name
                ids.sort((a, b) {
                  final serverA = app.serverById(a);
                  final serverB = app.serverById(b);
                  if (serverA == null && serverB == null) return 0;
                  if (serverA == null) return 1;
                  if (serverB == null) return -1;
                  return serverA.name.toLowerCase().compareTo(serverB.name.toLowerCase());
                });
                
                bool isDinner = (m >= end || (app.activeRosterView == 'dinner' && showToggle));
                if (ids.isEmpty) {
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
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ) ??
                              const TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        // Boost Mode Indicator
                        if (app.boostActive)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.withOpacity(0.15), 
                                  Colors.deepOrange.withOpacity(0.1)
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              border: Border.all(color: Colors.orange, width: 3),
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
                                      colors: [Colors.orange, Colors.deepOrange],
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
                                  child: Icon(
                                    Icons.rocket_launch, 
                                    color: Colors.white, 
                                    size: 24
                                  ),
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
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.orange, Colors.deepOrange],
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
                              child: Icon(
                                Icons.rocket_launch, 
                                color: Colors.white, 
                                size: 20
                              ),
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
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0, left: 24.0, right: 24.0),
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
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(isDinner ? Icons.nights_stay : Icons.wb_sunny, color: Colors.grey[700]),
                                const SizedBox(width: 8),
                                Text(
                                  isDinner ? 'Dinner Shift Leaderboard' : 'Lunch Shift Leaderboard',
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
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ChoiceChip(
                              label: const Text('Lunch'),
                              selected: app.activeRosterView != 'dinner',
                              onSelected: (selected) {
                                if (selected && app.activeRosterView == 'dinner') {
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
                                if (selected && app.activeRosterView != 'dinner') {
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
                        padding: const EdgeInsets.only(bottom: 120.0), // Add bottom padding to prevent overlap with "last run" area
                        child: _ActiveGrid(ids: ids, shiftActive: app.shiftActive, app: app),
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
                  // Server name now inside the grey area, top right
                  // Grey area and avatar row
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                      child: Consumer<AppState>(
                        builder: (context, app, _) {
                          final lastId = app.lastRunServerId;
                          final profile = lastId != null ? app.profiles[lastId] : null;
                          final avatarPath = profile?.avatarPath;
                          final bannerPath = profile?.bannerPath;
                          ImageProvider? avatarImage;
                          if (avatarPath != null && avatarPath.isNotEmpty) {
                            if (avatarPath.startsWith('/') || avatarPath.contains(':')) {
                              avatarImage = FileImage(File(avatarPath));
                            } else {
                              avatarImage = AssetImage(avatarPath);
                            }
                          }
                          ImageProvider? bannerImage;
                          if (bannerPath != null && bannerPath.isNotEmpty) {
                            if (bannerPath.startsWith('/') || bannerPath.contains(':')) {
                              bannerImage = FileImage(File(bannerPath));
                            } else {
                              bannerImage = AssetImage(bannerPath);
                            }
                          }
                          final serverName = lastId != null ? app.serverById(lastId)?.name ?? '' : '';
                          return Container(
                            decoration: BoxDecoration(
                              color: bannerImage == null ? Colors.grey[200] : null,
                            ),
                            child: Stack(
                              children: [
                                // Banner background (if available)
                                if (bannerImage != null)
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
                                          color: Colors.black.withOpacity(0.3), // Light dark overlay for text readability
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
                                      padding: const EdgeInsets.only(top: 4, right: 10),
                                      constraints: const BoxConstraints(
                                        maxWidth: 200,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
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
                                              OutlinedTextStroke(color: Colors.black, width: 2),
                                            ],
                                          ),
                                        // Full-width line under the name
                                        Container(
                                          margin: const EdgeInsets.only(top: 4, bottom: 2),
                                          height: 3,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.grey,
                                            borderRadius: BorderRadius.circular(2),
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
                                            if (lastId == null) return SizedBox.shrink();
                                            final appState = Provider.of<AppState>(context, listen: false);
                                            final runCount = appState.currentCounts[lastId] ?? 0;
                                            final pizookieCount = appState.currentPizookieCounts[lastId] ?? 0;
                                            final boost = appState.boostActive ? appState.boostMultiplier : 1.0;
                                            // Correct calculation: Pizookies are 25 XP total, not 10+25
                                            final regularRuns = runCount - pizookieCount;
                                            final shiftXp = (((regularRuns * 10) + (pizookieCount * 25)) * boost).round();
                                            print('[DEBUG] HOME DISPLAY: server=$lastId, runs=$runCount, pizookies=$pizookieCount, regularRuns=$regularRuns, boost=${appState.boostActive ? "${appState.boostMultiplier}x" : "none"}, shiftXp=$shiftXp');
                                            return Text(
                                              'Shift XP Earned: $shiftXp',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
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
                                        // Current XP / Next at XP
                                        Builder(
                                          builder: (context) {
                                            if (profile == null) return SizedBox.shrink();
                                            final int xp = profile.points;
                                            final int next = profile.nextLevelAt;
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
                                              child: avatarImage != null
                                                  ? Image(
                                                      image: avatarImage,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      color: Colors.grey[300],
                                                    ),
                                            ),
                                          ),
                                          if (profile != null)
                                            Positioned(
                                              bottom: 8,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  gradient: AppTheme.getLevelBubbleGradient(profile.level),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.white, width: 1.5),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.3),
                                                      blurRadius: 3,
                                                      offset: const Offset(0, 1),
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
    final pizookieCounts = ids.map((id) => app.currentPizookieCounts[id] ?? 0).toList();
    final maxCount = counts.isEmpty ? 0 : counts.reduce((a, b) => a > b ? a : b);
    final maxPizookieCount = pizookieCounts.isEmpty ? 0 : pizookieCounts.reduce((a, b) => a > b ? a : b);
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
                    shadows: const [Shadow(blurRadius: 2, color: Colors.black12, offset: Offset(1,1))],
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

                    final my = app.currentCounts[id] ?? 0;
                    final myPizookies = app.currentPizookieCounts[id] ?? 0;
                    final pct = total == 0 ? 0 : ((my / total) * 100).round();
                    final color = _tierColor(my, maxCount, myPizookies, maxPizookieCount);
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
                            print('[DEBUG] Server ${s.name} (id: $id) clicked');
                            print('[DEBUG] isOpenNow: ${app.isOpenNow}');
                            print('[DEBUG] shiftActive: ${app.shiftActive}');
                            print('[DEBUG] workingServerIds: ${app.workingServerIds}');
                            print('[DEBUG] workingServerIds.contains($id): ${app.workingServerIds.contains(id)}');
                            
                            // Only increment normal run on tap, not on long press
                            if (!this._isLongPress) {
                              // Check if restaurant is open before allowing increments
                              if (app.isOpenNow) {
                                final achievement = app.increment(id);
                                
                                // Calculate base XP and apply boost if active
                                int baseXP = 10;
                                int xpEarned = baseXP;
                                bool isAchievement = false;
                                bool isBoostActive = app.boostActive;
                                
                                if (achievement == 'full_hands') {
                                  isAchievement = true;
                                  _showAchievement('Full Hands!');
                                  // Full Hands = base boosted XP + 25 bonus
                                  if (isBoostActive) {
                                    xpEarned = (baseXP * app.boostMultiplier).round() + 25;
                                  } else {
                                    xpEarned = 35; // 10 base + 25 bonus
                                  }
                                } else if (achievement == 'five_streak') {
                                  xpEarned = 30;
                                  isAchievement = true;
                                } else if (achievement == 'ten_in_shift') {
                                  xpEarned = 20;
                                  isAchievement = true;
                                } else if (achievement == 'twenty_in_shift') {
                                  xpEarned = 30;
                                  isAchievement = true;
                                } else {
                                  // Regular run - apply boost if active
                                  if (isBoostActive) {
                                    xpEarned = (baseXP * app.boostMultiplier).round();
                                  }
                                }
                                
                                String flashText = '+$xpEarned XP';
                                if (isBoostActive && !isAchievement) {
                                  flashText = '🚀 +$xpEarned XP\nBOOST ${app.boostMultiplier}x!';
                                }
                                
                                _showFlash(
                                  flashText,
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
                              } else {
                                // Restaurant is closed - show message
                                print('[DEBUG] Click blocked: Restaurant is closed');
                                ScaffoldMessenger.of(ctx).clearSnackBars();
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Restaurant is closed!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          onLongPress: () {
                            this._isLongPress = true;
                            app.incrementPizookie(id);
                            
                            // Calculate boosted Pizookie XP
                            const basePizookieXP = 25;
                            final isBoostActive = app.boostActive;
                            final xpEarned = isBoostActive 
                                ? (basePizookieXP * app.boostMultiplier).round()
                                : basePizookieXP;
                            
                            String flashText = '+$xpEarned XP\nPizookie!';
                            String subText = 'Sweet!  Ran a Pizookie';
                            
                            if (isBoostActive) {
                              flashText = '🚀 +$xpEarned XP\nBOOST Pizookie!';
                              subText = 'BOOST ${app.boostMultiplier}x • Sweet!';
                            }
                            
                            _showFlash(
                              flashText,
                              subText,
                            );
                            // Removed Pizookie run SnackBar
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
                                          gradient: AppTheme.getLevelBubbleGradient(level),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.white, width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
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
                        
                        // Calculate base XP and apply boost if active
                        int baseXP = 10;
                        int xpEarned = baseXP;
                        bool isAchievement = false;
                        bool isBoostActive = app.boostActive;
                        
                        if (achievement == 'full_hands') {
                          isAchievement = true;
                          _showAchievement('Full Hands!');
                          // Full Hands = base boosted XP + 25 bonus
                          if (isBoostActive) {
                            xpEarned = (baseXP * app.boostMultiplier).round() + 25;
                          } else {
                            xpEarned = 35; // 10 base + 25 bonus
                          }
                        } else if (achievement == 'five_streak') {
                          xpEarned = 30;
                          isAchievement = true;
                        } else if (achievement == 'ten_in_shift') {
                          xpEarned = 20;
                          isAchievement = true;
                        } else if (achievement == 'twenty_in_shift') {
                          xpEarned = 30;
                          isAchievement = true;
                        } else {
                          // Regular run - apply boost if active
                          if (isBoostActive) {
                            xpEarned = (baseXP * app.boostMultiplier).round();
                          }
                        }
                        
                        // Only show XP flash for achievements if gamification is enabled
                        if (!isAchievement || app.settings.gamificationEnabled) {
                          String flashText = '+$xpEarned XP';
                          if (isBoostActive && !isAchievement) {
                            flashText = '🚀 +$xpEarned XP\nBOOST ${app.boostMultiplier}x!';
                          }
                          _showFlash(
                            flashText,
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
                        
                        // Calculate boosted Pizookie XP
                        const basePizookieXP = 25;
                        final isBoostActive = app.boostActive;
                        final xpEarned = isBoostActive 
                            ? (basePizookieXP * app.boostMultiplier).round()
                            : basePizookieXP;
                        
                        String flashText = '+$xpEarned XP\nPizookie!';
                        String subText = 'Sweet!  Ran a Pizookie';
                        
                        if (isBoostActive) {
                          flashText = '🚀 +$xpEarned XP\nBOOST Pizookie!';
                          subText = 'BOOST ${app.boostMultiplier}x • Sweet!';
                        }
                        
                        _showFlash(
                          flashText,
                          subText,
                        );
                        // Removed Pizookie run SnackBar
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
                                      gradient: AppTheme.getLevelBubbleGradient(level),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
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
    final isAfterTransition = m >= (plan?.transitionEndMinutes ?? widget.app.settings.transitionEndMinutes);
    final header = showLunch ? 'Lunch' : 'Dinner';

    // --- Get the correct roster and sort by selected metric ---
    final ids = showLunch ? lunchIds : dinnerIds;
    final sortedIds = [...ids];
    
    if (_sortByRuns) {
      sortedIds.sort((a, b) => (widget.app.currentCounts[b] ?? 0).compareTo(widget.app.currentCounts[a] ?? 0));
    } else {
      sortedIds.sort((a, b) => (widget.app.profiles[b]?.pizookieRuns ?? 0).compareTo(widget.app.profiles[a]?.pizookieRuns ?? 0));
    }

    // Calculate enhanced metrics
    final counts = sortedIds.map((id) => widget.app.currentCounts[id] ?? 0).toList();
    final totalRuns = counts.fold<int>(0, (a, b) => a + b);
    final avgRuns = totalRuns > 0 ? totalRuns / sortedIds.length : 0.0;
    final maxRuns = counts.isNotEmpty ? counts.reduce((a, b) => a > b ? a : b) : 0;
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
                colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
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
                letterSpacing: 1.2
              ),
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
              child: const Text(
                '✅ FINALIZED', 
                style: TextStyle(
                  fontStyle: FontStyle.italic, 
                  fontSize: 12, 
                  color: Colors.orange,
                  fontWeight: FontWeight.bold
                )
              ),
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
                _buildStatItem('📊', 'Average', '${avgRuns.toStringAsFixed(1)}'),
                _buildStatItem('🔥', 'Top Score', '$maxRuns'),
                _buildStatItem('⚡', 'Active', '$activeServers/${sortedIds.length}'),
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
                    constraints: const BoxConstraints(minWidth: 80, minHeight: 36),
                    selectedColor: Colors.white,
                    fillColor: Theme.of(context).primaryColor,
                    children: const [
                      Text('🍽️ Lunch'), 
                      Text('🌙 Dinner')
                    ],
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
                  constraints: const BoxConstraints(minWidth: 60, minHeight: 36),
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
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, i) {
                final id = sortedIds[i];
                final server = widget.app.servers.firstWhere((s) => s.id == id, orElse: () => Server(id: id, name: 'Unknown'));
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
            child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        border: isTop3 ? Border.all(color: rankColor!.withOpacity(0.3), width: 1) : null,
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
                isTop3 ? (rankColor ?? Theme.of(context).primaryColor) : Theme.of(context).primaryColor,
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
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                    color: percentage > 0 ? Colors.green[700] : Colors.grey[500],
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
      appState.activateBoost(_multiplier, _duration, _description.isEmpty ? 'Manager Boost' : _description);
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

  Widget _buildPinActionButton(IconData icon, String tooltip, VoidCallback onPressed) {
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
      content: Container(
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
                          color: i < _enteredPin.length ? Colors.blue : Colors.grey[300],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // PIN Pad
              Container(
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
                        _buildPinActionButton(Icons.clear, 'Clear', _onPinClear),
                        _buildPinButton('0'),
                        _buildPinActionButton(Icons.backspace, 'Back', _onPinBackspace),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (appState.boostActive) ...[
              Text(
                'Boost is currently ACTIVE!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
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
              Text('XP Multiplier:', style: TextStyle(fontWeight: FontWeight.w600)),
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
              backgroundColor: appState.boostActive ? Colors.red : Colors.orange,
            ),
            child: Text(appState.boostActive ? 'Deactivate Boost' : 'Activate Boost'),
          ),
      ],
    );
  }
}
