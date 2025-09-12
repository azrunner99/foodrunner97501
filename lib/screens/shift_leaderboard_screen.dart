import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../utils/integrity_analyzer.dart';
import 'server_integrity_profile_screen.dart';

class ShiftLeaderboardScreen extends StatefulWidget {
  final AppState app;
  final String shiftType; // 'Lunch' or 'Dinner'

  const ShiftLeaderboardScreen({
    Key? key,
    required this.app,
    required this.shiftType,
  }) : super(key: key);

  @override
  State<ShiftLeaderboardScreen> createState() => _ShiftLeaderboardScreenState();
}

class _ShiftLeaderboardScreenState extends State<ShiftLeaderboardScreen>
    with TickerProviderStateMixin {
  String _sortBy = 'xp'; // 'runs', 'pizookies', 'xp'
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final now = DateTime.now();
        final m = now.hour * 60 + now.minute;
        final plan = appState.todayPlan;
        final lunchIds = plan?.lunchRoster ?? [];
        final dinnerIds = plan?.dinnerRoster ?? [];
        final isLunch = widget.shiftType.toLowerCase() == 'lunch';
        final isAfterTransition = m >= (plan?.transitionEndMinutes ?? appState.settings.transitionEndMinutes);

        // Get roster based on shift type
        final ids = isLunch ? lunchIds : dinnerIds;
        final sortedIds = [...ids];

        // Sort by selected metric
        if (_sortBy == 'runs') {
          sortedIds.sort((a, b) => (appState.currentCounts[b] ?? 0).compareTo(appState.currentCounts[a] ?? 0));
        } else if (_sortBy == 'pizookies') {
          sortedIds.sort((a, b) => (appState.currentPizookieCounts[b] ?? 0).compareTo(appState.currentPizookieCounts[a] ?? 0));
        } else if (_sortBy == 'xp') {
          sortedIds.sort((a, b) {
            final runsA = appState.currentCounts[a] ?? 0;
            final pizookiesA = appState.currentPizookieCounts[a] ?? 0;
            final runsB = appState.currentCounts[b] ?? 0;
            final pizookiesB = appState.currentPizookieCounts[b] ?? 0;
            
            // Apply boost multiplier if active - Pizookies are 25 XP total, not 10+25
            final boost = appState.boostActive ? appState.boostMultiplier : 1.0;
            final regularRunsA = runsA - pizookiesA;
            final regularRunsB = runsB - pizookiesB;
            final xpA = ((regularRunsA * 10) + (pizookiesA * 25)) * boost;
            final xpB = ((regularRunsB * 10) + (pizookiesB * 25)) * boost;
            return xpB.compareTo(xpA);
          });
        }

        // Calculate enhanced metrics
        final counts = sortedIds.map((id) => appState.currentCounts[id] ?? 0).toList();
        final totalRuns = counts.fold<int>(0, (a, b) => a + b);
        final avgRuns = totalRuns > 0 ? totalRuns / sortedIds.length : 0.0;
        final maxRuns = counts.isNotEmpty ? counts.reduce((a, b) => a > b ? a : b) : 0;
        final activeServers = counts.where((c) => c > 0).length;
        final totalPizookies = sortedIds.map((id) => appState.currentPizookieCounts[id] ?? 0).fold<int>(0, (a, b) => a + b);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                  Colors.white,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Enhanced Header
                    _buildHeader(isLunch, isAfterTransition, appState),
                    
                    // Stats Dashboard
                    _buildStatsDashboard(totalRuns, avgRuns, maxRuns, activeServers, sortedIds.length, totalPizookies),
                    
                    // Sort Controls
                    _buildSortControls(),
                    
                    // Leaderboard List
                    Expanded(
                      child: _buildLeaderboardList(sortedIds, maxRuns, appState),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isLunch, bool isAfterTransition, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
              Text(
                '🏆 ${widget.shiftType} Leaderboard',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              IconButton(
                onPressed: () {
                  print('[DEBUG] Manual reconstruction triggered');
                  appState.manuallyReconstructAllTimeRuns();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reconstruction triggered - check console')),
                  );
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Debug: Reconstruct All-Time Runs',
              ),
            ],
          ),
          if (isLunch && isAfterTransition)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange[300]!, width: 2),
              ),
              child: const Text(
                '✅ SHIFT FINALIZED',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsDashboard(int totalRuns, double avgRuns, int maxRuns, int activeServers, int totalServers, int totalPizookies) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total Runs', '$totalRuns', Colors.blue),
              _buildStatCard('Pizookies', '$totalPizookies', Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 8,
                color: Colors.black.withOpacity(0.8),
                offset: const Offset(3, 3),
              ),
              Shadow(
                blurRadius: 16,
                color: color.withOpacity(0.9),
                offset: const Offset(0, 0),
              ),
              Shadow(
                blurRadius: 24,
                color: Colors.black.withOpacity(0.4),
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(
                blurRadius: 3,
                color: Colors.black.withOpacity(0.6),
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _sortBy = 'xp'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _sortBy == 'xp' ? Theme.of(context).primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'XP',
                      style: TextStyle(
                        color: _sortBy == 'xp' ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 30,
            width: 2,
            color: Colors.grey[500],
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _sortBy = 'runs'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _sortBy == 'runs' ? Theme.of(context).primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Runs',
                      style: TextStyle(
                        color: _sortBy == 'runs' ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 30,
            width: 2,
            color: Colors.grey[500],
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _sortBy = 'pizookies'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _sortBy == 'pizookies' ? Theme.of(context).primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pizookies',
                      style: TextStyle(
                        color: _sortBy == 'pizookies' ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<String> sortedIds, int maxRuns, AppState appState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sortedIds.length,
        separatorBuilder: (context, index) => const Divider(height: 20),
        itemBuilder: (context, index) {
          final id = sortedIds[index];
          final server = appState.servers.firstWhere(
            (s) => s.id == id,
            orElse: () => Server(id: id, name: 'Unknown'),
          );
          final runs = appState.currentCounts[id] ?? 0;
          final pizookies = appState.profiles[id]?.pizookieRuns ?? 0;
          final totalRuns = sortedIds.map((id) => appState.currentCounts[id] ?? 0).fold<int>(0, (a, b) => a + b);
          final percentage = totalRuns > 0 ? (runs / totalRuns) * 100 : 0.0;

          return _buildEnhancedServerCard(
            server: server,
            rank: index + 1,
            runs: runs,
            pizookies: pizookies,
            percentage: percentage,
            maxRuns: maxRuns,
          );
        },
      ),
    );
  }

  Widget _buildEnhancedServerCard({
    required Server server,
    required int rank,
    required int runs,
    required int pizookies,
    required double percentage,
    required int maxRuns,
  }) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        // Get profile information
        final profile = appState.profiles[server.id];
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
        
        // Calculate shift XP with boost applied - Pizookies are 25 XP total, not 10+25
        final runCount = appState.currentCounts[server.id] ?? 0;
        final pizookieCount = appState.currentPizookieCounts[server.id] ?? 0;
        final boost = appState.boostActive ? appState.boostMultiplier : 1.0;
        final regularRuns = runCount - pizookieCount;
        final shiftXp = (((regularRuns * 10) + (pizookieCount * 25)) * boost).round();
        
        // Get all working servers for rankings
        final workingServers = appState.servers.where((s) => appState.workingServerIds.contains(s.id)).toList();
        
        // Rank for runs
        final runRanks = List<String>.from(workingServers.map((s) => s.id));
        runRanks.sort((a, b) => (appState.currentCounts[b] ?? 0).compareTo(appState.currentCounts[a] ?? 0));
        final runRank = runRanks.indexOf(server.id) + 1;
        
        // Rank for pizookies
        final pizookieRanks = List<String>.from(workingServers.map((s) => s.id));
        pizookieRanks.sort((a, b) => (appState.currentPizookieCounts[b] ?? 0).compareTo(appState.currentPizookieCounts[a] ?? 0));
        final pizookieRank = pizookieRanks.indexOf(server.id) + 1;
        final totalServers = workingServers.length;
        
        // Check if this is a top 3 position
        final isTopThree = rank <= 3;

        return Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isTopThree ? Border.all(
              color: rank == 1 ? Color(0xFFFFD700) : 
                     rank == 2 ? Color(0xFFC0C0C0) : 
                     Color(0xFFCD7F32),
              width: 3,
            ) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main card content
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 120,
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
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                      // Default background if no banner
                      if (bannerImage == null)
                        Positioned.fill(
                          child: Container(
                            color: Colors.grey[200],
                          ),
                        ),
                      
                      // Server name at top right
                      Positioned(
                        top: 8,
                        right: 12,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                server.name,
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
                              // Line under name - moved up and made shorter
                              Container(
                                margin: const EdgeInsets.only(top: 6, bottom: 8),
                                height: 2,
                                width: 120, // Made shorter so it doesn't interfere with stats
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
                            ],
                          ),
                        ),
                      ),
                      
                      // XP info positioned separately to avoid line overlap
                      Positioned(
                        top: 50,
                        right: 12,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Shift XP Earned
                              Text(
                                'Shift XP Earned: $shiftXp',
                                style: TextStyle(
                                  fontSize: 12,
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
                              ),
                              // Current XP / Next at XP
                              if (profile != null)
                                Text(
                                  '${profile.points} / Next at ${profile.nextLevelAt}',
                                  style: TextStyle(
                                    fontSize: 12,
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
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Avatar and stats row
                      Positioned(
                        bottom: 8,
                        left: 16,
                        right: 8,
                        child: Row(
                          children: [
                            // Avatar with level badge
                            SizedBox(
                              width: 80,
                              height: 80,
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
                                      bottom: 6,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.getLevelBubbleGradient(profile.level),
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
                                          'Lvl${profile.level}',
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
                            ),
                            SizedBox(width: 12),
                            
                            // Stats column
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Runs: $runCount',
                                  style: const TextStyle(
                                    fontSize: 15,
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
                                        fontSize: 11,
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
                                        child: Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 14),
                                      )
                                    else if (runRank == 2)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(Icons.emoji_events, color: Color(0xFFC0C0C0), size: 14),
                                      )
                                    else if (runRank == 3)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 14),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Pizookies: $pizookieCount',
                                  style: const TextStyle(
                                    fontSize: 15,
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
                                        fontSize: 11,
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
                                        child: Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 14),
                                      )
                                    else if (pizookieRank == 2)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(Icons.emoji_events, color: Color(0xFFC0C0C0), size: 14),
                                      )
                                    else if (pizookieRank == 3)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 14),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Rank badge positioned at top-left corner, slightly outside
              Positioned(
                top: -12,
                left: -12,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isTopThree ? 
                        (rank == 1 ? [Color(0xFFFFD700), Color(0xFFFFA500)] : 
                         rank == 2 ? [Color(0xFFC0C0C0), Color(0xFF8C8C8C)] : 
                         [Color(0xFFCD7F32), Color(0xFF8B4513)]) : 
                        [Color(0xFF6B7280), Color(0xFF4B5563)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white, 
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: isTopThree ? 
                          (rank == 1 ? Color(0xFFFFD700).withOpacity(0.4) : 
                           rank == 2 ? Color(0xFFC0C0C0).withOpacity(0.4) : 
                           Color(0xFFCD7F32).withOpacity(0.4)) : 
                          Colors.grey.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 0),
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 3,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Easter egg: Hidden admin access in bottom-right corner
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showAdminPinDialog(context, server),
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Container(
                      margin: EdgeInsets.all(2),
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 16,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdminPinDialog(BuildContext context, Server server) {
    final TextEditingController pinController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.orange),
            SizedBox(width: 8),
            Text('Admin Access'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter admin PIN to access ${server.name}\'s integrity profile:'),
            SizedBox(height: 16),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'Admin PIN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              onSubmitted: (value) => _handlePinSubmission(context, server, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _handlePinSubmission(context, server, pinController.text),
            child: Text('Access'),
          ),
        ],
      ),
    );
  }

  void _handlePinSubmission(BuildContext context, Server server, String pin) {
    if (pin == AppState.adminPin) {
      Navigator.of(context).pop(); // Close dialog
      _navigateToServerIntegrityProfile(context, server);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Incorrect PIN'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToServerIntegrityProfile(BuildContext context, Server server) {
    final app = Provider.of<AppState>(context, listen: false);
    
    // Generate current assessment for the server
    final bins = app.integrityBinsForDateRange(server.id, todayOnly: true);
    final runCount = app.currentCounts[server.id] ?? 0;
    final allServerCounts = <String, int>{};
    for (final s in app.servers) {
      allServerCounts[s.id] = app.currentCounts[s.id] ?? 0;
    }
    
    try {
      final assessment = IntegrityAnalyzer.analyzeServerAdvanced(
        serverId: server.id,
        serverName: server.name,
        clickBins: bins,
        totalRuns: runCount,
        allServers: app.servers,
        allServerCounts: allServerCounts,
        analysisTime: DateTime.now(),
      ).toBasicAssessment();
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ServerIntegrityProfileScreen(
            server: server,
            assessment: assessment,
          ),
        ),
      );
    } catch (e) {
      // Fallback to basic assessment if enhanced fails
      final basicAssessment = IntegrityAnalyzer.analyzeServer(
        serverId: server.id,
        serverName: server.name,
        clickBins: bins,
        totalRuns: runCount,
        allServers: app.servers,
        allServerCounts: allServerCounts,
        analysisTime: DateTime.now(),
      );
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ServerIntegrityProfileScreen(
            server: server,
            assessment: basicAssessment,
          ),
        ),
      );
    }
  }
}
