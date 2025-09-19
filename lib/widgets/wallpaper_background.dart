import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class WallpaperBackground extends StatelessWidget {
  final Widget child;

  const WallpaperBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    if (app.selectedWallpaper == 'none') {
      return child;
    }

    return Stack(
      children: [
        // Background wallpaper
        Positioned.fill(
          child: _buildWallpaperImage(app.selectedWallpaper),
        ),
        // Content on top
        child,
      ],
    );
  }

  Widget _buildWallpaperImage(String wallpaperId) {
    // Handle the new image001-image073 format
    if (wallpaperId.startsWith('image')) {
      final assetPath = 'assets/wallpapers/$wallpaperId.webp';
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        opacity: const AlwaysStoppedAnimation(0.8), // More visible background
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox.shrink();
        },
      );
    }

    // Legacy wallpaper support (if any old ones exist)
    final wallpaperAssets = {
      'flowing_waves': 'assets/wallpapers/flowing_waves.png',
      'geometric_blue': 'assets/wallpapers/geometric_blue.png',
      'food_pattern': 'assets/wallpapers/food_pattern.png',
      'kitchen_utensils': 'assets/wallpapers/kitchen_utensils.png',
    };

    final assetPath = wallpaperAssets[wallpaperId];

    if (assetPath == null) {
      // Fallback to no wallpaper if asset not found
      return const SizedBox.shrink();
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      opacity: const AlwaysStoppedAnimation(0.8), // More visible background
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox.shrink();
      },
    );
  }
}
