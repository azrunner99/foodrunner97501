import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class GamificationOptionsScreen extends StatelessWidget {
  const GamificationOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Gamification Options')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Achievements & Streaks'),
            subtitle: const Text('Turn off to disable all achievement and streak bonuses'),
            value: app.settings.gamificationEnabled,
            onChanged: (v) async {
              final newSettings = app.settings..gamificationEnabled = v;
              await app.saveSettings(newSettings);
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'When disabled, only standard runs (10 points) and Pizookie runs (25 points) will award points. No other bonuses or achievements will be given.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
