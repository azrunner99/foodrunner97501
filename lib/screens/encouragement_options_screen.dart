import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class EncouragementOptionsScreen extends StatelessWidget {
  const EncouragementOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Encouragement Options')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('Show Encouragement Flash'),
            subtitle: const Text('Enable or disable the encouragement flash'),
          ),
          Consumer<AppState>(
            builder: (context, app, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text('Off', style: TextStyle(fontSize: 16)),
                  Switch(
                    value: app.settings.encouragementFlashEnabled ?? true,
                    onChanged: (val) async {
                      final newSettings = app.settings;
                      newSettings.encouragementFlashEnabled = val;
                      await app.saveSettings(newSettings);
                    },
                  ),
                  const Text('On', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
          const Divider(height: 32, thickness: 1),
          const ListTile(
            leading: Icon(Icons.celebration),
            title: Text('Customize Encouragements'),
            subtitle: Text('Set the encouragement text shown to servers'),
          ),
          // Add more options here as needed
        ],
      ),
    );
  }
}
