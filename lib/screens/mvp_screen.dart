import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_state.dart';

class MvpScreen extends StatelessWidget {
  const MvpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final servers = app.servers;
    final totalAllTime = app.totals.values.fold<int>(0, (a, b) => a + b);

    return FutureBuilder<Map<String, Map<String, String?>>>(
      future: _loadAllAvatarsAndBanners(servers),
      builder: (context, snapshot) {
        final entries = servers.map((s) {
          final runs = app.totals[s.id] ?? 0;
          final pct = totalAllTime > 0 ? (runs * 100.0 / totalAllTime) : 0.0;
          final pizookieRuns = app.profiles[s.id]?.pizookieRuns ?? 0;
          final totalPizookie = app.profiles.values.fold<int>(0, (a, b) => a + b.pizookieRuns);
          final pizookieShare = totalPizookie > 0 ? (pizookieRuns * 100.0 / totalPizookie) : 0.0;
          final shiftsAsMvp = app.profiles[s.id]?.shiftsAsMvp ?? 0;
          final avatarPath = app.profiles[s.id]?.avatarPath; // Use app.profiles instead of avatarMap
          final bannerPath = app.profiles[s.id]?.bannerPath; // Use app.profiles instead of bannerMap
          final currentXp = app.profiles[s.id]?.points ?? 0; // Get current XP
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
          );
        }).toList()
          ..sort((a, b) {
            final c = b.pct.compareTo(a.pct);
            if (c != 0) return c;
            final d = b.runs.compareTo(a.runs);
            if (d != 0) return d;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

        return Scaffold(
          appBar: AppBar(title: const Text('Leaderboard')),
          body: entries.isEmpty
              ? const Center(child: Text('No data yet.'))
              : ListView.separated(
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
                    _buildAvatar(e.avatarPath),
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

  Widget _buildAvatar(String? avatarPath) {
    if (avatarPath != null && avatarPath.isNotEmpty) {
      // Check if it's an asset path or a file path
      if (avatarPath.startsWith('assets/')) {
        return CircleAvatar(
          radius: 60, // Increased from 36 to make nearly as tall as card
          backgroundImage: AssetImage(avatarPath),
        );
      } else {
        // It's a file path
        final file = File(avatarPath);
        if (file.existsSync()) {
          return CircleAvatar(
            radius: 60, // Increased from 36 to make nearly as tall as card
            backgroundImage: FileImage(file),
          );
        }
      }
    }
    return const SizedBox(width: 120); // Increased width to match larger avatar
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
  });
}
