import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class ServerAvatarSettingsScreen extends StatelessWidget {
  const ServerAvatarSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final profilesWithAvatar = <MapEntry<String, ServerProfile>>[];
    app.profiles.forEach((id, profile) {
      if (profile.avatarPath != null && profile.avatarPath!.isNotEmpty) {
        profilesWithAvatar.add(MapEntry(id, profile));
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Server Avatar Settings')),
      body: Column(
        children: [
          Expanded(
            child: profilesWithAvatar.isEmpty
                ? const Center(child: Text('No server avatars found.'))
                : ListView.separated(
                    itemCount: profilesWithAvatar.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final entry = profilesWithAvatar[i];
                      final server = app.serverById(entry.key);
                      final displayName = server?.name ?? entry.key;
                      return ListTile(
                        leading: CircleAvatar(backgroundImage: FileImage(File(entry.value.avatarPath!))),
                        title: Text(displayName),
                        subtitle: Text('Avatar path: ${entry.value.avatarPath}'),
                        onTap: () {},
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(8),
            child: Text('All profiles (for debug):'),
          ),
          Expanded(
            child: ListView(
              children: app.profiles.entries.map((e) => ListTile(
                title: Text('ID: ${e.key}'),
                subtitle: Text('AvatarPath: ${e.value.avatarPath ?? ""}"'),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
