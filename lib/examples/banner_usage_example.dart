// Example of how to use banner selections globally across the app

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class ExampleBannerUsage extends StatelessWidget {
  final String serverId;
  
  const ExampleBannerUsage({super.key, required this.serverId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final profile = app.profiles[serverId];
    final server = app.serverById(serverId);
    
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // Use the globally stored banner
        image: profile?.bannerPath != null
            ? DecorationImage(
                image: AssetImage(profile!.bannerPath!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: profile?.bannerPath == null
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${server?.name ?? "Server"} - No Banner Selected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${server?.name ?? "Server"} Profile',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
    );
  }
}

/*
HOW TO USE GLOBALLY:

1. In any widget, access the banner:
   final app = context.watch<AppState>();
   final bannerPath = app.profiles[serverId]?.bannerPath;

2. Display the banner:
   if (bannerPath != null) {
     Image.asset(bannerPath, fit: BoxFit.cover)
   }

3. Check if banner is set:
   final hasBanner = app.profiles[serverId]?.bannerPath != null;

4. Use in profile cards, headers, backgrounds, etc.:
   - ProfilesScreen list items
   - HomeScreen server displays  
   - MVP screen backgrounds
   - Statistics screens
   - Any server-related UI
*/
