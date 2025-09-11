import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';
import '../gamification.dart';
import 'server_level_detail_screen.dart';

class LevelColorDemoScreen extends StatefulWidget {
  const LevelColorDemoScreen({super.key});

  @override
  State<LevelColorDemoScreen> createState() => _LevelColorDemoScreenState();
}

class _LevelColorDemoScreenState extends State<LevelColorDemoScreen> {
  // Track which tiers are expanded
  final Set<String> _expandedTiers = {};

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final serverCounts = _getServerCountsByLevel(appState);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade100,
              Colors.grey.shade200,
              Colors.grey.shade300,
              Colors.grey.shade400,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced app bar section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.8),
                      Colors.white.withOpacity(0.6),
                    ],
                  ),
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.grey.shade700, Colors.grey.shade600],
                        ).createShader(bounds),
                        child: const Text(
                          'Level Progression',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 2,
                                color: Colors.black26,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Stunning title section
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                      Colors.grey.shade50.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.grey.shade600, size: 24),
                        Icon(Icons.emoji_events, color: Colors.amber.shade600, size: 28),
                        Icon(Icons.auto_awesome, color: Colors.grey.shade600, size: 24),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.grey.shade700,
                          Colors.grey.shade600,
                          Colors.grey.shade700,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ).createShader(bounds),
                      child: const Text(
                        'XP LEVEL TIERS',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3.0,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black26,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.grey.shade500,
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(Icons.star_border, color: Colors.grey.shade500, size: 20),
                        Icon(Icons.diamond, color: Colors.grey.shade600, size: 20),
                        Icon(Icons.star_border, color: Colors.grey.shade500, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Scrollable content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
            
            // Beginner Tier (1-5) - 5 levels
            _buildTierDemo('Beginner', [1, 2, 3, 4, 5], '1-5', Colors.green.shade100, serverCounts),
            
            // Developing Tier (6-15) - 10 levels
            _buildTierDemo('Developing', [6, 7, 8, 9, 10, 11, 12, 13, 14, 15], '6-15', Colors.blue.shade100, serverCounts),
            
            // Intermediate Tier (16-30) - 15 levels
            _buildTierDemo('Intermediate', [16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30], '16-30', Colors.purple.shade100, serverCounts),
            
            // Advanced Tier (31-50) - 20 levels
            _buildTierDemo('Advanced', [31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50], '31-50', Colors.orange.shade100, serverCounts),
            
            // Expert Tier (51-75) - 25 levels
            _buildTierDemo('Expert', [51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75], '51-75', Colors.red.shade100, serverCounts),
            
            // Master Tier (76-100) - 25 levels
            _buildTierDemo('Master', [76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100], '76-100', Colors.deepPurple.shade100, serverCounts),
            
            // Legendary Tier (101-125) - 25 levels
            _buildTierDemo('Legendary', [101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125], '101-125', Colors.amber.shade100, serverCounts),
            
            // Mythical Tier (126-150) - 25 levels
            _buildTierDemo('Mythical', [126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150], '126-150', Colors.cyan.shade100, serverCounts),
            
            const SizedBox(height: 20), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Count how many servers are at each level
  Map<int, int> _getServerCountsByLevel(AppState appState) {
    final counts = <int, int>{};
    
    // Initialize all levels to 0
    for (int level = 1; level <= 150; level++) {
      counts[level] = 0;
    }
    
    // Count servers at each level
    for (final server in appState.servers) {
      final profile = appState.profiles[server.id];
      if (profile != null) {
        final level = profile.level;
        counts[level] = (counts[level] ?? 0) + 1;
      }
    }
    
    return counts;
  }

  // Count total servers in a tier
  int _getServerCountInTier(List<int> levels, Map<int, int> serverCounts) {
    int total = 0;
    for (int level in levels) {
      total += serverCounts[level] ?? 0;
    }
    return total;
  }

  LinearGradient _getTierGradient(List<int> levels) {
    if (levels.isEmpty) return const LinearGradient(colors: [Colors.grey, Colors.grey]);
    
    // Get the lightest and darkest colors for this tier
    final firstLevel = levels.first;
    final lastLevel = levels.last;
    
    final lightColor = AppTheme.getLevelBubbleColor(firstLevel);
    final darkColor = AppTheme.getLevelBubbleColor(lastLevel);
    
    return LinearGradient(
      colors: [lightColor, darkColor],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  Widget _buildTierDemo(String tierName, List<int> levels, String range, Color backgroundColor, Map<int, int> serverCounts) {
    final isExpanded = _expandedTiers.contains(tierName);
    final tierServerCount = _getServerCountInTier(levels, serverCounts);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            decoration: BoxDecoration(
              gradient: _getTierGradient(levels),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedTiers.remove(tierName);
                  } else {
                    _expandedTiers.add(tierName);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '$tierName Tier',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Levels $range',
                              style: const TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Server count display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$tierServerCount ${tierServerCount == 1 ? 'server' : 'servers'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 24,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expanded content with original background
          if (isExpanded) ...[
            const Divider(height: 1, thickness: 1),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [backgroundColor, backgroundColor.withOpacity(0.3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: _buildLevelBubblesGrid(levels, serverCounts),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelBubblesGrid(List<int> levels, Map<int, int> serverCounts) {
    List<Widget> rows = [];
    
    for (int i = 0; i < levels.length; i += 5) {
      List<int> rowLevels = levels.sublist(i, (i + 5 > levels.length) ? levels.length : i + 5);
      
      rows.add(
        Row(
          children: rowLevels.map((level) => 
            Expanded(child: _buildLevelBubble(level, levels.indexOf(level), levels.length, serverCounts))
          ).toList(),
        )
      );
      
      if (i + 5 < levels.length) {
        rows.add(const SizedBox(height: 8));
      }
    }
    
    return Column(children: rows);
  }

  Widget _buildLevelBubble(int level, int index, int totalInTier, Map<int, int> serverCounts) {
    final color = AppTheme.getLevelBubbleColor(level);
    final gradient = AppTheme.getLevelBubbleGradient(level);
    final serverCount = serverCounts[level] ?? 0;
    
    // Calculate XP required for this level using the XP table from gamification.dart
    final xpRequired = _getXpForLevel(level);
    final xpLabel = xpRequired >= 1000 ? '${(xpRequired / 1000).toStringAsFixed(1)}k' : '$xpRequired';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          serverCount > 0 
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22), // Half of the larger size
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServerLevelDetailScreen(level: level),
                      ),
                    );
                  },
                  child: Container(
                    width: 44,  // Larger when clickable
                    height: 44, // Larger when clickable
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: gradient,
                      border: Border.all(color: Colors.white, width: 1),
                      boxShadow: [
                        // Enhanced shadow for clickable bubbles
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$serverCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: gradient,
                  border: Border.all(color: Colors.white, width: 1),
                  boxShadow: [
                    // Original subtle shadow for empty bubbles
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 4),
          Text(
            xpLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get XP required for a specific level
  int _getXpForLevel(int level) {
    if (level <= 1) return 0;
    if (level >= xpTable.length) return xpTable.last;
    return xpTable[level];
  }
}
