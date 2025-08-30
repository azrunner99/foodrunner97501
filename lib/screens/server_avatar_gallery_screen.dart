import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';

class ServerAvatarGalleryScreen extends StatelessWidget {
  final String serverId;
  final String serverName;
  final List<Map<String, dynamic>> avatarHistory;
  const ServerAvatarGalleryScreen({
    required this.serverId,
    required this.serverName,
    required this.avatarHistory,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Avatars for $serverName')),
      body: avatarHistory.isEmpty
          ? const Center(child: Text('No avatar photos found.'))
          : ListView.separated(
              itemCount: avatarHistory.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final entry = avatarHistory[i];
                final path = entry['path'] as String;
                final timestamp = entry['timestamp'] as String?;
                String formatted = 'Unknown date';
                if (timestamp != null) {
                  final dt = DateTime.tryParse(timestamp);
                  if (dt != null) {
                    final daySuffix = (dt.day == 1 || dt.day == 21 || dt.day == 31)
                        ? 'st'
                        : (dt.day == 2 || dt.day == 22) ? 'nd'
                        : (dt.day == 3 || dt.day == 23) ? 'rd' : 'th';
                    final month = DateFormat('MMMM').format(dt);
                    final year = dt.year;
                    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
                    final minute = dt.minute.toString().padLeft(2, '0');
                    final ampm = dt.hour >= 12 ? 'pm' : 'am';
                    formatted = '$month ${dt.day}$daySuffix, $year - $hour:$minute$ampm';
                  }
                }
                return ListTile(
                  leading: CircleAvatar(backgroundImage: FileImage(File(path))),
                  title: Text(formatted),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.file(File(path)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
