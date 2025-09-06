import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class ProfileBannerScreen extends StatefulWidget {
  final String serverId;
  
  const ProfileBannerScreen({super.key, required this.serverId});

  @override
  State<ProfileBannerScreen> createState() => _ProfileBannerScreenState();
}

class _ProfileBannerScreenState ext                      },
                    );
                  },
                ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );<ProfileBannerScreen> {
  String? selectedBannerPath;

  @override
  void initState() {
    super.initState();
    // Initialize with the current banner selection from app state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppState>();
      final profile = app.profiles[widget.serverId];
      if (profile?.bannerPath != null) {
        setState(() {
          selectedBannerPath = profile!.bannerPath;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final server = app.serverById(widget.serverId);
    final profile = app.profiles[widget.serverId]; // Get the profile for avatar access
    
    if (server == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile Banner')),
        body: const Center(child: Text('Server not found.')),
      );
    }

    // Calculate ranks for this server
    final allProfiles = app.profiles.entries.toList();
    
    // Rank by all-time runs (descending)
    allProfiles.sort((a, b) => (b.value.allTimeRuns).compareTo(a.value.allTimeRuns));
    final runsRank = allProfiles.indexWhere((entry) => entry.key == widget.serverId) + 1;
    
    // Rank by pizookie runs (descending)
    allProfiles.sort((a, b) => (b.value.pizookieRuns).compareTo(a.value.pizookieRuns));
    final pizookieRank = allProfiles.indexWhere((entry) => entry.key == widget.serverId) + 1;
    
    // Rank by XP/points (descending)
    allProfiles.sort((a, b) => (b.value.points).compareTo(a.value.points));
    final xpRank = allProfiles.indexWhere((entry) => entry.key == widget.serverId) + 1;
    
    final totalServers = allProfiles.length;

    // Calculate available banners for app bar
    final List<String> allPresetBanners = List.generate(174, (i) => 'assets/banners/image${(i+1).toString().padLeft(3, '0')}.webp');
    final Set<String> usedBanners = {};
    for (var profile in app.profiles.values) {
      if (profile.bannerPath != null && 
          profile.bannerPath!.startsWith('assets/banners/') &&
          app.profiles.keys.firstWhere((id) => app.profiles[id] == profile, orElse: () => '') != widget.serverId) {
        usedBanners.add(profile.bannerPath!);
      }
    }
    final availableBannerCount = allPresetBanners.length - usedBanners.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${server.name}\'s Banner',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color(0xFF1A202C),
              ),
            ),
            if (availableBannerCount < allPresetBanners.length)
              Text(
                '$availableBannerCount of ${allPresetBanners.length} available',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4A5568),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: Column(
        children: [
          // Fixed preview section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  const Color(0xFFF8FAFC),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Enhanced stats preview card with banner background
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF64748B).withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 0,
                          offset: const Offset(0, 0),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background banner or gradient
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: selectedBannerPath != null
                              ? Image.asset(
                                  selectedBannerPath!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.white, Color(0xFFFAFBFC)],
                                    ),
                                  ),
                                ),
                        ),
                        // Stats overlay
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // Enhanced avatar with the server's chosen avatar (larger size)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                  ),
                                  borderRadius: BorderRadius.circular(72),
                                ),
                                child: CircleAvatar(
                                  radius: 66,
                                  backgroundColor: Colors.white,
                                  backgroundImage: profile?.avatarPath != null && profile!.avatarPath!.isNotEmpty
                                      ? (profile.avatarPath!.startsWith('/') || profile.avatarPath!.contains(':')
                                          ? FileImage(File(profile.avatarPath!)) as ImageProvider
                                          : AssetImage(profile.avatarPath!))
                                      : null,
                                  child: profile?.avatarPath == null || profile!.avatarPath!.isEmpty
                                      ? Text(
                                          server.name.isNotEmpty ? server.name[0].toUpperCase() : 'S',
                                          style: const TextStyle(
                                            fontSize: 42,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF667EEA),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Enhanced stats with consistent dark background for readability
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.65),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildStatRow('All-time runs: ${profile?.allTimeRuns ?? 0}', const Color(0xFF10B981)),
                                      const SizedBox(height: 2),
                                      _buildStatRow('Rank: $runsRank/$totalServers', const Color(0xFF10B981)),
                                      const SizedBox(height: 8),
                                      _buildStatRow('All-time pizookies: ${profile?.pizookieRuns ?? 0}', const Color(0xFFF59E0B)),
                                      const SizedBox(height: 2),
                                      _buildStatRow('Rank: $pizookieRank/$totalServers', const Color(0xFFF59E0B)),
                                      const SizedBox(height: 8),
                                      _buildStatRow('Current XP: ${profile?.points ?? 0}', const Color(0xFF8B5CF6)),
                                      const SizedBox(height: 2),
                                      _buildStatRow('Rank: $xpRank/$totalServers', const Color(0xFF8B5CF6)),
                                      const SizedBox(height: 8),
                                      _buildStatRow('XP to level up: ${(profile?.nextLevelAt ?? 0) - (profile?.points ?? 0)}', const Color(0xFF6366F1)),
                                    ],
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
          ),
          
          // Fixed "Choose Your Style" header section
          Container(
            width: double.infinity,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.palette,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Choose Your Style',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a banner to personalize your profile',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Scrollable banner list
          Expanded(
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Builder(
                  builder: (context) {
                    // Get all preset banners
                    final List<String> allPresetBanners = List.generate(174, (i) => 'assets/banners/image${(i+1).toString().padLeft(3, '0')}.webp');
                    
                    // Get currently used preset banners (excluding the current server's banner)
                    final Set<String> usedBanners = {};
                    for (var profile in app.profiles.values) {
                      if (profile.bannerPath != null && 
                          profile.bannerPath!.startsWith('assets/banners/') &&
                          app.profiles.keys.firstWhere((id) => app.profiles[id] == profile, orElse: () => '') != widget.serverId) {
                        usedBanners.add(profile.bannerPath!);
                      }
                    }
                    
                    // Filter out used banners
                    final List<String> availableBanners = allPresetBanners.where((banner) => !usedBanners.contains(banner)).toList();
                    
                    if (availableBanners.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'All preset banners are currently in use!',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try again when other servers change their banners.',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: availableBanners.length,
                      itemBuilder: (context, index) {
                        final bannerPath = availableBanners[index];
                        final bannerId = bannerPath.split('/').last.split('.').first; // Extract image001, image002, etc.
                        
                        return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () => _selectBanner(context, bannerPath, bannerId),
                        child: Container(
                          height: 120, // Good height for 800x320 aspect ratio
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedBannerPath == bannerPath 
                                  ? const Color(0xFF667EEA)
                                  : const Color(0xFFE2E8F0),
                              width: selectedBannerPath == bannerPath ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: selectedBannerPath == bannerPath
                                    ? const Color(0xFF667EEA).withOpacity(0.2)
                                    : const Color(0xFF64748B).withOpacity(0.1),
                                blurRadius: selectedBannerPath == bannerPath ? 12 : 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              bannerPath,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFFF1F5F9),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      color: Color(0xFF94A3B8),
                                      size: 32,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
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
    );
  }

  void _selectBanner(BuildContext context, String bannerPath, String bannerId) {
    setState(() {
      selectedBannerPath = bannerPath;
    });
    
    // Save banner selection to app state
    final app = Provider.of<AppState>(context, listen: false);
    app.updateBanner(widget.serverId, bannerPath);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected banner for ${context.read<AppState>().serverById(widget.serverId)?.name ?? "server"}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildStatRow(String text, Color accentColor) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
