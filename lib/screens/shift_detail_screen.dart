import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class ShiftDetailScreen extends StatefulWidget {
  final ShiftRecord shift;

  const ShiftDetailScreen({super.key, required this.shift});

  @override
  State<ShiftDetailScreen> createState() => _ShiftDetailScreenState();
}

class _ShiftDetailScreenState extends State<ShiftDetailScreen>
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
      builder: (context, appState, child) {
        // Get server IDs from the shift data
        final serverIds = widget.shift.counts.keys.toList();
        final sortedIds = [...serverIds];

        // Sort by selected metric
        if (_sortBy == 'runs') {
          sortedIds.sort((a, b) => (widget.shift.counts[b] ?? 0).compareTo(widget.shift.counts[a] ?? 0));
        } else if (_sortBy == 'pizookies') {
          sortedIds.sort((a, b) {
            final pizookiesA = appState.profiles[a]?.pizookieRuns ?? 0;
            final pizookiesB = appState.profiles[b]?.pizookieRuns ?? 0;
            return pizookiesB.compareTo(pizookiesA);
          });
        } else if (_sortBy == 'xp') {
          sortedIds.sort((a, b) {
            final runsA = widget.shift.counts[a] ?? 0;
            final runsB = widget.shift.counts[b] ?? 0;
            final pizookiesA = appState.profiles[a]?.pizookieRuns ?? 0;
            final pizookiesB = appState.profiles[b]?.pizookieRuns ?? 0;
            final xpA = (runsA * 10) + (pizookiesA * 15);
            final xpB = (runsB * 10) + (pizookiesB * 15);
            return xpB.compareTo(xpA);
          });
        }

        // Calculate metrics
        final totalRuns = widget.shift.counts.values.fold<int>(0, (a, b) => a + b);
        final totalPizookies = serverIds.map((id) => appState.profiles[id]?.pizookieRuns ?? 0).fold<int>(0, (a, b) => a + b);
        final maxRuns = widget.shift.counts.values.isNotEmpty ? widget.shift.counts.values.reduce((a, b) => a > b ? a : b) : 0;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _getShiftTypeColor(widget.shift.shiftType),
                  _getShiftTypeColor(widget.shift.shiftType).withOpacity(0.8),
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
                    _buildHeader(),
                    
                    // Stats Dashboard
                    _buildStatsDashboard(totalRuns, totalPizookies),
                    
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

  Widget _buildHeader() {
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
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getShiftTypeIcon(widget.shift.shiftType),
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.shift.shiftType} Shift',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _weekday(widget.shift.start),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${_hm(widget.shift.start)} - ${_hm(widget.shift.start.add(const Duration(hours: 8)))}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _confirmDelete(context, widget.shift),
                icon: const Icon(Icons.delete, color: Colors.white, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsDashboard(int totalRuns, int totalPizookies) {
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
                  color: _sortBy == 'xp' ? _getShiftTypeColor(widget.shift.shiftType) : Colors.transparent,
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
                  color: _sortBy == 'runs' ? _getShiftTypeColor(widget.shift.shiftType) : Colors.transparent,
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
                  color: _sortBy == 'pizookies' ? _getShiftTypeColor(widget.shift.shiftType) : Colors.transparent,
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
    // Calculate MVP (highest XP earned during shift)
    String? mvpServerId;
    int highestXP = 0;
    
    for (final id in sortedIds) {
      final runs = widget.shift.counts[id] ?? 0;
      final pizookies = appState.profiles[id]?.pizookieRuns ?? 0;
      final xp = (runs * 10) + (pizookies * 15);
      
      if (xp > highestXP) {
        highestXP = xp;
        mvpServerId = id;
      }
    }
    
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
          final runs = widget.shift.counts[id] ?? 0;
          final pizookies = appState.profiles[id]?.pizookieRuns ?? 0;
          final isMVP = id == mvpServerId && highestXP > 0; // Only show MVP if someone earned XP

          return _buildEnhancedServerCard(
            server: server,
            rank: index + 1,
            runs: runs,
            pizookies: pizookies,
            maxRuns: maxRuns,
            appState: appState,
            isMVP: isMVP,
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
    required int maxRuns,
    required AppState appState,
    required bool isMVP,
  }) {
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
    
    // Calculate shift XP
    final shiftXp = (runs * 10) + (pizookies * 15);
    
    // Get all servers for rankings
    final allServerIds = widget.shift.counts.keys.toList();
    
    // Rank for runs
    final runRanks = List<String>.from(allServerIds);
    runRanks.sort((a, b) => (widget.shift.counts[b] ?? 0).compareTo(widget.shift.counts[a] ?? 0));
    final runRank = runRanks.indexOf(server.id) + 1;
    
    // Rank for pizookies
    final pizookieRanks = List<String>.from(allServerIds);
    pizookieRanks.sort((a, b) => (appState.profiles[b]?.pizookieRuns ?? 0).compareTo(appState.profiles[a]?.pizookieRuns ?? 0));
    final pizookieRank = pizookieRanks.indexOf(server.id) + 1;
    final totalServers = allServerIds.length;
    
    // Check if this is a top 3 position
    final isTopThree = rank <= 3;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isTopThree ? Border.all(
          color: rank == 1 ? const Color(0xFFFFD700) : 
                 rank == 2 ? const Color(0xFFC0C0C0) : 
                 const Color(0xFFCD7F32),
          width: 3,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
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
                          // Line under name
                          Container(
                            margin: const EdgeInsets.only(top: 6, bottom: 8),
                            height: 2,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
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
                            style: const TextStyle(
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
                              style: const TextStyle(
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
                                      color: Colors.black.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(10),
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
                        const SizedBox(width: 12),
                        
                        // Stats column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Runs: $runs',
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
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 14),
                                  )
                                else if (runRank == 2)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.emoji_events, color: Color(0xFFC0C0C0), size: 14),
                                  )
                                else if (runRank == 3)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 14),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pizookies: $pizookies',
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
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 14),
                                  )
                                else if (pizookieRank == 2)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.emoji_events, color: Color(0xFFC0C0C0), size: 14),
                                  )
                                else if (pizookieRank == 3)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
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
                    (rank == 1 ? [const Color(0xFFFFD700), const Color(0xFFFFA500)] : 
                     rank == 2 ? [const Color(0xFFC0C0C0), const Color(0xFF8C8C8C)] : 
                     [const Color(0xFFCD7F32), const Color(0xFF8B4513)]) : 
                    [const Color(0xFF6B7280), const Color(0xFF4B5563)],
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
                    offset: const Offset(0, 4),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: isTopThree ? 
                      (rank == 1 ? const Color(0xFFFFD700).withOpacity(0.4) : 
                       rank == 2 ? const Color(0xFFC0C0C0).withOpacity(0.4) : 
                       const Color(0xFFCD7F32).withOpacity(0.4)) : 
                      Colors.grey.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 0),
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 3,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // MVP badge positioned at bottom-right corner
          if (isMVP)
            Positioned(
              bottom: -8,
              right: -8,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 0),
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'MVP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 3,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getShiftTypeColor(String shiftType) {
    switch (shiftType.toLowerCase()) {
      case 'lunch':
        return Colors.teal;
      case 'dinner':
        return Colors.deepPurple;
      default:
        return Colors.blue;
    }
  }

  IconData _getShiftTypeIcon(String shiftType) {
    switch (shiftType.toLowerCase()) {
      case 'lunch':
        return Icons.wb_sunny;
      case 'dinner':
        return Icons.nightlight_round;
      default:
        return Icons.restaurant;
    }
  }

  String _weekday(DateTime date) {
    const days = [
      'Monday',
      'Tuesday', 
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[date.weekday - 1];
  }

  String _hm(DateTime date) {
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'am' : 'pm';
    return '$hour:$minute$period';
  }

  void _confirmDelete(BuildContext context, ShiftRecord shift) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Shift'),
          content: Text('Are you sure you want to delete this ${shift.shiftType} shift?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<AppState>(context, listen: false).deleteShift(shift);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to history screen
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
