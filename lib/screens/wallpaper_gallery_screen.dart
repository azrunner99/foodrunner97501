import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class WallpaperGalleryScreen extends StatelessWidget {
  const WallpaperGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    
    // List of available wallpapers - generated from image001.webp to image073.webp
    final wallpapers = <WallpaperOption>[];
    
    // Generate wallpaper options from image001.webp to image073.webp
    for (int i = 1; i <= 73; i++) {
      final imageNumber = i.toString().padLeft(3, '0'); // 001, 002, etc.
      wallpapers.add(
        WallpaperOption(
          id: 'image$imageNumber',
          name: 'Wallpaper $i',
          description: 'Background pattern $i',
          assetPath: 'assets/wallpapers/image$imageNumber.webp',
          preview: _buildPreviewFromAsset('assets/wallpapers/image$imageNumber.webp'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Wallpaper'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: wallpapers.length,
          itemBuilder: (context, index) {
            final wallpaper = wallpapers[index];
            final isSelected = app.selectedWallpaper == wallpaper.id;
            
            return GestureDetector(
              onTap: () {
                _showWallpaperPreview(context, wallpaper, app);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Preview area
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: wallpaper.preview,
                      ),
                    ),
                    // Selected indicator
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: const Icon(
                          Icons.check, 
                          color: Colors.white, 
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showWallpaperPreview(BuildContext context, WallpaperOption wallpaper, AppState app) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Preview Wallpaper',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Wallpaper preview
                Container(
                  height: 300,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: wallpaper.preview,
                  ),
                ),
                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Use wallpaper button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            app.setWallpaper(wallpaper.id);
                            Navigator.of(context).pop(); // Close dialog
                            Navigator.of(context).pop(); // Close gallery
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Use Wallpaper',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to build preview from asset path
  static Widget _buildPreviewFromAsset(String assetPath) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      },
    );
  }
}

class WallpaperOption {
  final String id;
  final String name;
  final String description;
  final String? assetPath;
  final Widget preview;

  WallpaperOption({
    required this.id,
    required this.name,
    required this.description,
    required this.assetPath,
    required this.preview,
  });
}
