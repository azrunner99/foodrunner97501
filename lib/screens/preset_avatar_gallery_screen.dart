import 'package:flutter/material.dart';

class PresetAvatarGalleryScreen extends StatelessWidget {
  final void Function(String path) onAvatarSelected;
  const PresetAvatarGalleryScreen({super.key, required this.onAvatarSelected});

  @override
  Widget build(BuildContext context) {
    // Example preset avatars. Replace with your actual asset paths.
  // List all avatar image filenames (update if you add/remove files)
  final List<String> presetAvatars = List.generate(131, (i) => 'assets/avatars/image${(i+1).toString().padLeft(3, '0')}.png');
    return Scaffold(
      appBar: AppBar(title: const Text('Select Preset Avatar')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: presetAvatars.length,
        itemBuilder: (context, i) {
          final path = presetAvatars[i];
          return GestureDetector(
            onTap: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(path, width: 180, height: 180, fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                minimumSize: const Size(80, 40),
                              ),
                              child: const Text('Use'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, false),
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
                ),
              );
              if (result == true) {
                onAvatarSelected(path);
              }
            },
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(path, fit: BoxFit.contain),
              ),
            ),
          );
        },
      ),
    );
  }
}
