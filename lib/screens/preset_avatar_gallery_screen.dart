import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class PresetAvatarGalleryScreen extends StatelessWidget {
  final void Function(String path) onAvatarSelected;
  final String currentServerId;
  const PresetAvatarGalleryScreen({super.key, required this.onAvatarSelected, required this.currentServerId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    
    // Get all preset avatars
    final List<String> allPresetAvatars = List.generate(131, (i) => 'assets/avatars/image${(i+1).toString().padLeft(3, '0')}.png');
    
    // Get currently used preset avatars (excluding the current server's avatar)
    final Set<String> usedAvatars = {};
    for (var profile in app.profiles.values) {
      if (profile.avatarPath != null && 
          profile.avatarPath!.startsWith('assets/avatars/') &&
          app.profiles.keys.firstWhere((id) => app.profiles[id] == profile, orElse: () => '') != currentServerId) {
        usedAvatars.add(profile.avatarPath!);
      }
    }
    
    // Filter out used avatars
    final List<String> availableAvatars = allPresetAvatars.where((avatar) => !usedAvatars.contains(avatar)).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Preset Avatar'),
            if (availableAvatars.length < allPresetAvatars.length)
              Text(
                '${availableAvatars.length} of ${allPresetAvatars.length} available',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
          ],
        ),
      ),
      body: availableAvatars.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.face, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'All preset avatars are currently in use!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'You can still take a custom photo instead.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: availableAvatars.length,
            itemBuilder: (context, i) {
              final path = availableAvatars[i];
          return GestureDetector(
            onTap: () async {
              final result = await showDialog<String>(
                context: context,
                builder: (context) {
                  return Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final double maxWidth = MediaQuery.of(context).size.width * 0.8;
                                return Image.asset(
                                  path,
                                  width: maxWidth,
                                  height: maxWidth,
                                  fit: BoxFit.contain,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, path),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  minimumSize: const Size(80, 40),
                                ),
                                child: const Text('Use'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, null),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black,
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  minimumSize: const Size(80, 40),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
              if (result != null) {
                onAvatarSelected(result);
              }
            },
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(path, fit: BoxFit.contain),
              ),
            ),
          );
        }
      ), // end GridView.builder
    ); // end Scaffold
  }
} // end class
