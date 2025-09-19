import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../gamification.dart';

class ServerLevelDetailScreen extends StatelessWidget {
  final int level;

  const ServerLevelDetailScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    // Get servers at this level
    final serversAtLevel = app.servers.where((server) {
      final profile = app.profiles[server.id];
      return profile?.level == level;
    }).toList();

    // Sort by points (highest first)
    serversAtLevel.sort((a, b) {
      final profileA = app.profiles[a.id];
      final profileB = app.profiles[b.id];
      return (profileB?.points ?? 0).compareTo(profileA?.points ?? 0);
    });

    // Get XP requirements for this level
    final levelXP = _getXpForLevel(level);
    final nextLevelXP = level < 150 ? _getXpForLevel(level + 1) : null;

    // Get the level's gradient colors for theming
    final levelGradient = AppTheme.getLevelBubbleGradient(level);
    final levelColors = levelGradient.colors;
    final primaryColor = levelColors.first;
    final secondaryColor = levelColors.last;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.1),
              secondaryColor.withOpacity(0.05),
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom app bar with level theming
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.2),
                      secondaryColor.withOpacity(0.1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Themed back button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: primaryColor,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Themed title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [primaryColor, secondaryColor],
                            ).createShader(bounds),
                            child: Text(
                              'Level $level Servers',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            '${serversAtLevel.length} ${serversAtLevel.length == 1 ? 'server' : 'servers'} at this level',
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryColor.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Enhanced level bubble with dynamic styling - Full width
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: double.infinity,
                child: Stack(
                  children: [
                    // Background glow effect
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: secondaryColor.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    // Main level bubble
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: levelGradient,
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.4),
                            width: 3,
                          ),
                          left: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                            width: 2,
                          ),
                          right: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                            width: 2,
                          ),
                          bottom: BorderSide(
                            color: Colors.black.withOpacity(0.3),
                            width: 4,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 12),
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Level number with enhanced styling
                          Stack(
                            children: [
                              // Outline effect
                              Text(
                                '$level',
                                style: TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w900,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 4
                                    ..color = Colors.black.withOpacity(0.3),
                                ),
                              ),
                              // Main text
                              Text(
                                '$level',
                                style: const TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 8,
                                      color: Colors.black54,
                                      offset: Offset(3, 3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // XP info with enhanced styling
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'XP Required: ${levelXP.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black38,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                if (nextLevelXP != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Next Level: ${nextLevelXP.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 4,
                                          color: Colors.black38,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Server count with badge styling
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people,
                                  color: primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [primaryColor, secondaryColor],
                                  ).createShader(bounds),
                                  child: Text(
                                    '${serversAtLevel.length} ${serversAtLevel.length == 1 ? 'Server' : 'Servers'}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Server list with enhanced styling
              Expanded(
                child: serversAtLevel.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: primaryColor.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No servers at this level',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Servers will appear here once they reach level $level',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: primaryColor.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              primaryColor.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: serversAtLevel.length,
                          itemBuilder: (context, index) {
                            final server = serversAtLevel[index];
                            final profile = app.profiles[server.id];

                            return _buildServerCard(
                              server: server,
                              profile: profile,
                              rank: index + 1,
                              primaryColor: primaryColor,
                              secondaryColor: secondaryColor,
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerCard({
    required Server server,
    required ServerProfile? profile,
    required int rank,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    // Get profile information
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: rank <= 3
            ? Border.all(
                color: rank == 1
                    ? const Color(0xFFFFD700)
                    : rank == 2
                        ? const Color(0xFFC0C0C0)
                        : const Color(0xFFCD7F32),
                width: 3,
              )
            : Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 2,
              ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 130,
          child: Stack(
            children: [
              // Banner background with overlay gradient
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
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            primaryColor.withOpacity(0.2),
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // Enhanced default background if no banner
              if (bannerImage == null)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.withOpacity(0.1),
                          secondaryColor.withOpacity(0.2),
                          primaryColor.withOpacity(0.15),
                        ],
                      ),
                    ),
                  ),
                ),

              // Rank badge for all servers (top left)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: rank == 1
                          ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                          : rank == 2
                              ? [
                                  const Color(0xFFC0C0C0),
                                  const Color(0xFF9E9E9E)
                                ]
                              : rank == 3
                                  ? [
                                      const Color(0xFFCD7F32),
                                      const Color(0xFF8D5524)
                                    ]
                                  : [primaryColor, secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        rank == 1
                            ? Icons.emoji_events
                            : rank == 2
                                ? Icons.military_tech
                                : rank == 3
                                    ? Icons.workspace_premium
                                    : Icons.tag,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '#$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black54,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Enhanced server name with gradient text
              Positioned(
                top: 12,
                right: 16,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [primaryColor, secondaryColor],
                          ).createShader(bounds),
                          child: Text(
                            server.name,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Level progression bar
              if (profile != null)
                Positioned(
                  top: 60, // Lowered from 55 to 60 for better spacing
                  left: 110, // Start just to the right of avatar
                  right: 16,
                  child: Container(
                    height: 20, // Twice as tall as before
                    decoration: BoxDecoration(
                      color: Colors.black
                          .withOpacity(0.9), // Much darker background
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white
                            .withOpacity(0.8), // Stronger white border
                        width: 2, // Thicker border
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.8),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background track with stronger contrast
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[800], // Solid dark background
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        // Progress fill with enhanced visibility
                        FractionallySizedBox(
                          widthFactor: profile.level < 150
                              ? (profile.points -
                                      _getXpForLevel(profile.level)) /
                                  (_getXpForLevel(profile.level + 1) -
                                      _getXpForLevel(profile.level))
                              : 1.0, // If max level, show full bar
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor, secondaryColor],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.8),
                                  blurRadius: 8,
                                  offset: const Offset(0, 1),
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 2,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Enhanced XP info with themed styling
              if (profile != null)
                Positioned(
                  top:
                      85, // Moved further down to make room for taller progression bar
                  right: 16,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: primaryColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'XP: ${profile.points.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Clean avatar without colored border
              Positioned(
                bottom: 12,
                left: 20,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: avatarImage != null
                              ? Image(
                                  image: avatarImage,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.person,
                                    size: 40,
                                    color: primaryColor.withOpacity(0.7),
                                  ),
                                ),
                        ),
                      ),
                      if (profile != null)
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppTheme.getLevelBubbleGradient(
                                  profile.level),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Lvl${profile.level}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                shadows: [
                                  Shadow(
                                    blurRadius: 2,
                                    color: Colors.black54,
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
              ),

              // Floating accent elements
              Positioned(
                top: 20,
                left: rank <= 3 ? 160 : 20,
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white.withOpacity(0.3),
                  size: 16,
                ),
              ),
              Positioned(
                bottom: 20,
                right: 180,
                child: Icon(
                  Icons.star_border,
                  color: primaryColor.withOpacity(0.4),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
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
