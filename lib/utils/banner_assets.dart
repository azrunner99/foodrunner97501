import 'dart:convert';
import 'log.dart';
import 'package:flutter/services.dart';

class BannerAssets {
  static List<String>? _cachedBannerPaths;

  /// Get all available banner file paths
  /// Since we have 280 randomly named banners, we'll need to read them dynamically
  static Future<List<String>> getAllBannerPaths() async {
    if (_cachedBannerPaths != null) {
      return _cachedBannerPaths!;
    }

    // For now, we'll use a temporary approach until we can dynamically read the assets
    // This list should be updated when banners are added/renamed
    _cachedBannerPaths = await _loadBannersFromManifest();
    return _cachedBannerPaths!;
  }

  static Future<List<String>> _loadBannersFromManifest() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap =
          json.decode(manifestContent) as Map<String, dynamic>;

      final bannerPaths = manifestMap.keys
          .where((String key) =>
              key.startsWith('assets/banners/') && key.endsWith('.webp'))
          .toList();

      bannerPaths.sort();
      return bannerPaths;
    } catch (e) {
  d('Error loading banner manifest: $e');
      // Return empty list if loading fails
      return [];
    }
  }

  /// Clear the cache (useful for hot reload during development)
  static void clearCache() {
    _cachedBannerPaths = null;
  }

  /// Get available banners excluding those already used by other servers
  static Future<List<String>> getAvailableBanners(
      String currentServerId, Map<String, dynamic> profiles) async {
    final allBanners = await getAllBannerPaths();

    // Get currently used preset banners (excluding the current server's banner)
    final Set<String> usedBanners = {};
    for (var profileEntry in profiles.entries) {
      final profile = profileEntry.value;
      final profileId = profileEntry.key;

      if (profile.bannerPath != null &&
          profile.bannerPath!.startsWith('assets/banners/') &&
          profileId != currentServerId) {
        usedBanners.add(profile.bannerPath!);
      }
    }

    // Filter out used banners
    return allBanners.where((banner) => !usedBanners.contains(banner)).toList();
  }
}
