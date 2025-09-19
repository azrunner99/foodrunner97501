import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';

enum SortOption {
  allTimeRuns('All Time Runs'),
  pizookieRuns('Pizookie Runs'),
  currentXp('Current XP'),
  mvpAwards('MVP Awards');

  const SortOption(this.displayName);
  final String displayName;
}

enum DateRangeOption {
  allTime('All Time'),
  lastWeek('Last Week'),
  lastTwoWeeks('Last 2 Weeks'),
  lastMonth('Last Month'),
  customRange('Custom Range');

  const DateRangeOption(this.displayName);
  final String displayName;
}

class MvpScreen extends StatefulWidget {
  const MvpScreen({super.key});

  @override
  State<MvpScreen> createState() => _MvpScreenState();
}

class _MvpScreenState extends State<MvpScreen> {
  SortOption _currentSort = SortOption.currentXp;
  DateRangeOption _currentDateRange = DateRangeOption.allTime;
  DateTimeRange? _customDateRange;

  // Helper method to get date range
  DateTimeRange? _getDateRange() {
    final now = DateTime.now();
    switch (_currentDateRange) {
      case DateRangeOption.allTime:
        return null; // No filtering
      case DateRangeOption.lastWeek:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case DateRangeOption.lastTwoWeeks:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 14)),
          end: now,
        );
      case DateRangeOption.lastMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 1, now.day),
          end: now,
        );
      case DateRangeOption.customRange:
        return _customDateRange;
    }
  }

  // Helper method to show date range picker (two-step process)
  Future<void> _showDateRangePicker() async {
    // Step 1: Select start date
    final DateTime? startDate = await showDatePicker(
      context: context,
      initialDate: _customDateRange?.start ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Start Date',
      confirmText: 'NEXT',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (startDate == null) return;
    
    // Step 2: Select end date
    final DateTime? endDate = await showDatePicker(
      context: context,
      initialDate: _customDateRange?.end ?? DateTime.now(),
      firstDate: startDate, // End date must be after start date
      lastDate: DateTime.now(),
      helpText: 'Select End Date',
      confirmText: 'DONE',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.green,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (endDate == null) return;
    
    // Set the custom date range
    setState(() {
      _customDateRange = DateTimeRange(start: startDate, end: endDate);
      _currentDateRange = DateRangeOption.customRange;
    });
  }

  // Calculate runs for a server within a date range from shift history
  int _calculateRunsInDateRange(AppState app, String serverId, DateTimeRange dateRange) {
    int totalRuns = 0;
    for (final shift in app.history) {
      if (shift.start.isAfter(dateRange.start) && shift.start.isBefore(dateRange.end.add(const Duration(days: 1)))) {
        totalRuns += shift.counts[serverId] ?? 0;
      }
    }
    return totalRuns;
  }

  // Calculate pizookie runs for a server within a date range from shift history
  int _calculatePizookieRunsInDateRange(AppState app, String serverId, DateTimeRange dateRange) {
    int totalPizookieRuns = 0;
    for (final shift in app.history) {
      if (shift.start.isAfter(dateRange.start) && shift.start.isBefore(dateRange.end.add(const Duration(days: 1)))) {
        totalPizookieRuns += shift.pizookieCounts[serverId] ?? 0;
      }
    }
    return totalPizookieRuns;
  }

  // Show sort options popup
  void _showSortPopup(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    
    showMenu<SortOption>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + 50,
        offset.dx + 200,
        offset.dy + 200,
      ),
      items: SortOption.values.map((option) {
        return PopupMenuItem<SortOption>(
          value: option,
          child: Row(
            children: [
              Icon(
                _currentSort == option ? Icons.check : Icons.sort,
                size: 16,
                color: _currentSort == option ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(option.displayName),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        setState(() {
          _currentSort = value;
        });
      }
    });
  }

  // Show date range options popup
  void _showDateRangePopup(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    
    showMenu<DateRangeOption>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + 50,
        offset.dx + 200,
        offset.dy + 300,
      ),
      items: DateRangeOption.values.map((option) {
        return PopupMenuItem<DateRangeOption>(
          value: option,
          child: Row(
            children: [
              Icon(
                _currentDateRange == option ? Icons.check : Icons.date_range,
                size: 16,
                color: _currentDateRange == option ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(option.displayName),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        if (value == DateRangeOption.customRange) {
          _showDateRangePicker();
        } else {
          setState(() {
            _currentDateRange = value;
          });
        }
      }
    });
  }

  // Get display text for date range bubble
  String _getDateRangeDisplayText() {
    if (_currentDateRange == DateRangeOption.customRange && _customDateRange != null) {
      return '${_customDateRange!.start.month}/${_customDateRange!.start.day} - ${_customDateRange!.end.month}/${_customDateRange!.end.day}';
    }
    return _currentDateRange.displayName;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final servers = app.servers;
    final dateRange = _getDateRange();

    return FutureBuilder<Map<String, Map<String, String?>>>(
      future: _loadAllAvatarsAndBanners(servers),
      builder: (context, snapshot) {
        final entries = servers.map((s) {
          // Calculate runs based on date range
          int runs;
          int pizookieRuns;
          double pct;
          double pizookieShare;

          if (dateRange == null) {
            // All time - use profile allTimeRuns which includes current shift
            runs = app.profiles[s.id]?.allTimeRuns ?? 0;
            pizookieRuns = app.profiles[s.id]?.pizookieRuns ?? 0;
            final totalAllTime = app.profiles.values.fold<int>(0, (a, b) => a + b.allTimeRuns);
            final totalPizookie = app.profiles.values.fold<int>(0, (a, b) => a + b.pizookieRuns);
            pct = totalAllTime > 0 ? (runs * 100.0 / totalAllTime) : 0.0;
            pizookieShare = totalPizookie > 0 ? (pizookieRuns * 100.0 / totalPizookie) : 0.0;
          } else {
            // Date range filtering - calculate from shift history
            runs = _calculateRunsInDateRange(app, s.id, dateRange);
            pizookieRuns = _calculatePizookieRunsInDateRange(app, s.id, dateRange);
            
            // Calculate percentages for filtered period
            final totalRunsInRange = servers.fold<int>(0, (sum, server) => 
              sum + _calculateRunsInDateRange(app, server.id, dateRange));
            final totalPizookieInRange = servers.fold<int>(0, (sum, server) => 
              sum + _calculatePizookieRunsInDateRange(app, server.id, dateRange));
            
            pct = totalRunsInRange > 0 ? (runs * 100.0 / totalRunsInRange) : 0.0;
            pizookieShare = totalPizookieInRange > 0 ? (pizookieRuns * 100.0 / totalPizookieInRange) : 0.0;
          }

          final shiftsAsMvp = app.profiles[s.id]?.shiftsAsMvp ?? 0;
          final avatarPath = app.profiles[s.id]?.avatarPath;
          final bannerPath = app.profiles[s.id]?.bannerPath;
          final currentXp = app.profiles[s.id]?.points ?? 0;
          final level = app.profiles[s.id]?.level ?? 1;
          
          return _Entry(
            name: s.name,
            runs: runs,
            pct: pct,
            id: s.id,
            pizookieRuns: pizookieRuns,
            pizookieShare: pizookieShare,
            shiftsAsMvp: shiftsAsMvp,
            avatarPath: avatarPath,
            bannerPath: bannerPath,
            currentXp: currentXp,
            level: level,
          );
        }).toList();

        // Sort based on current selection
        entries.sort((a, b) {
          switch (_currentSort) {
            case SortOption.allTimeRuns:
              final c = b.runs.compareTo(a.runs);
              if (c != 0) return c;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            case SortOption.pizookieRuns:
              final c = b.pizookieRuns.compareTo(a.pizookieRuns);
              if (c != 0) return c;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            case SortOption.currentXp:
              final c = b.currentXp.compareTo(a.currentXp);
              if (c != 0) return c;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            case SortOption.mvpAwards:
              final c = b.shiftsAsMvp.compareTo(a.shiftsAsMvp);
              if (c != 0) return c;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Leaderboard'),
          ),
          body: entries.isEmpty
              ? const Center(child: Text('No data yet.'))
              : Column(
                  children: [
                    // Compact filter bubbles with labels
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Sort by section
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sort by',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _showSortPopup(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    border: Border.all(color: Colors.blue),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.sort, size: 16, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text(
                                        _currentSort.displayName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.arrow_drop_down, size: 16, color: Colors.blue),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(width: 20),
                          
                          // Date range section
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Date Range',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _showDateRangePopup(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    border: Border.all(color: Colors.green),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.date_range, size: 16, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getDateRangeDisplayText(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.arrow_drop_down, size: 16, color: Colors.green),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Leaderboard list
                    Expanded(
                      child: ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final e = entries[i];
                          final rank = i + 1;
                          final leading = rank <= 3
                              ? Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.emoji_events,
                                      color: rank == 1
                                          ? Colors.amber[700]
                                          : rank == 2
                                              ? Colors.grey[300]
                                              : Colors.brown[400],
                                      size: 28,
                                  ),
                              )
                              : Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    rank.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20, // Increased from 16
                                    ),
                                  ),
                                );

                          return _buildLeaderboardItem(e, rank, leading);
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildLeaderboardItem(_Entry e, int rank, Widget leading) {
    // Determine if we have a banner
    ImageProvider? bannerImage;
    if (e.bannerPath != null && e.bannerPath!.isNotEmpty) {
      if (e.bannerPath!.startsWith('/') || e.bannerPath!.contains(':')) {
        bannerImage = FileImage(File(e.bannerPath!));
      } else {
        bannerImage = AssetImage(e.bannerPath!);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0), // Increased vertical padding
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6), // Darker overlay for better text readability
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          // Content
          Container(
            padding: const EdgeInsets.all(12.0), // Increased from 8.0
            decoration: BoxDecoration(
              color: bannerImage == null ? null : null, // No background color if banner exists
              borderRadius: BorderRadius.circular(8),
            ),
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
                        style: TextStyle(
                          fontSize: 28, // Increased from 22
                          fontWeight: FontWeight.bold,
                          color: bannerImage != null ? Colors.white : null,
                          shadows: bannerImage != null ? [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black,
                              offset: Offset(2, 2),
                            ),
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black.withOpacity(0.8),
                              offset: Offset(0, 0),
                            ),
                          ] : null,
                        ),
                      ),
                      Text(
                        'All-time Runs: ${e.runs}', 
                        style: TextStyle(
                          fontSize: 16, // Increased from 12
                          color: bannerImage != null ? Colors.white : null,
                          shadows: bannerImage != null ? [
                            Shadow(
                              blurRadius: 3,
                              color: Colors.black,
                              offset: Offset(1, 1),
                            ),
                            Shadow(
                              blurRadius: 6,
                              color: Colors.black.withOpacity(0.7),
                              offset: Offset(0, 0),
                            ),
                          ] : null,
                        ),
                      ),
                      Text(
                        'Share: ${e.pct.toStringAsFixed(0)}%', 
                        style: TextStyle(
                          fontSize: 16, // Increased from 12
                          color: bannerImage != null ? Colors.white : null,
                          shadows: bannerImage != null ? [
                            Shadow(
                              blurRadius: 3,
                              color: Colors.black,
                              offset: Offset(1, 1),
                            ),
                            Shadow(
                              blurRadius: 6,
                              color: Colors.black.withOpacity(0.7),
                              offset: Offset(0, 0),
                            ),
                          ] : null,
                        ),
                      ),
                      const SizedBox(height: 12), // Increased from 8
                      Text(
                        'Pizookie Runs: ${e.pizookieRuns}', 
                        style: TextStyle(
                          fontSize: 16, // Increased from 12
                          color: bannerImage != null ? Colors.white : null,
                          shadows: bannerImage != null ? [
                            Shadow(
                              blurRadius: 3,
                              color: Colors.black,
                              offset: Offset(1, 1),
                            ),
                            Shadow(
                              blurRadius: 6,
                              color: Colors.black.withOpacity(0.7),
                              offset: Offset(0, 0),
                            ),
                          ] : null,
                        ),
                      ),
                      Text(
                        'Pizookie Share: ${e.pizookieShare.toStringAsFixed(0)}%', 
                        style: TextStyle(
                          fontSize: 16, // Increased from 12
                          color: bannerImage != null ? Colors.white : null,
                          shadows: bannerImage != null ? [
                            Shadow(
                              blurRadius: 3,
                              color: Colors.black,
                              offset: Offset(1, 1),
                            ),
                            Shadow(
                              blurRadius: 6,
                              color: Colors.black.withOpacity(0.7),
                              offset: Offset(0, 0),
                            ),
                          ] : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'MVP Awards: ${e.shiftsAsMvp}', 
                        style: TextStyle(
                          fontSize: 16, // Increased from 12
                          color: bannerImage != null ? Colors.white : null,
                          shadows: bannerImage != null ? [
                            Shadow(
                              blurRadius: 3,
                              color: Colors.black,
                              offset: Offset(1, 1),
                            ),
                            Shadow(
                              blurRadius: 6,
                              color: Colors.black.withOpacity(0.7),
                              offset: Offset(0, 0),
                            ),
                          ] : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    _buildAvatar(e.avatarPath, e.level),
                    const SizedBox(height: 4),
                    Text(
                      '${e.currentXp} XP',
                      style: TextStyle(
                        fontSize: 16, // Increased from 12
                        fontWeight: FontWeight.bold,
                        color: bannerImage != null ? Colors.white : Colors.black,
                        shadows: bannerImage != null ? [
                          Shadow(
                            blurRadius: 2,
                            color: Colors.black,
                            offset: Offset(1, 1),
                          ),
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.7),
                            offset: Offset(0, 0),
                          ),
                        ] : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, Map<String, String?>>> _loadAllAvatarsAndBanners(List servers) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String?> avatarMap = {};
    final Map<String, String?> bannerMap = {};
    for (var s in servers) {
      avatarMap[s.id] = prefs.getString('avatar_${s.id}');
      bannerMap[s.id] = prefs.getString('banner_${s.id}');
    }
    return {
      'avatars': avatarMap,
      'banners': bannerMap,
    };
  }

  Widget _buildAvatar(String? avatarPath, int level) {
    Widget avatarWidget;
    
    if (avatarPath != null && avatarPath.isNotEmpty) {
      // Check if it's an asset path or a file path
      if (avatarPath.startsWith('assets/')) {
        avatarWidget = CircleAvatar(
          radius: 60, // Increased from 36 to make nearly as tall as card
          backgroundImage: AssetImage(avatarPath),
        );
      } else {
        // It's a file path
        final file = File(avatarPath);
        if (file.existsSync()) {
          avatarWidget = CircleAvatar(
            radius: 60, // Increased from 36 to make nearly as tall as card
            backgroundImage: FileImage(file),
          );
        } else {
          avatarWidget = CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[300],
          );
        }
      }
    } else {
      avatarWidget = CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey[300],
      );
    }

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          avatarWidget,
          // Level bubble at bottom right
          Positioned(
            bottom: 6,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: AppTheme.getLevelBubbleGradient(level),
                borderRadius: BorderRadius.circular(10),
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
                'Lvl$level',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
  final String? bannerPath;
  final int currentXp;
  final int level;
  _Entry({
    required this.id,
    required this.name,
    required this.runs,
    required this.pct,
    this.pizookieRuns = 0,
    this.pizookieShare = 0.0,
    this.shiftsAsMvp = 0,
    this.avatarPath,
    this.bannerPath,
    required this.currentXp,
    required this.level,
  });
}
