import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../messages.dart';

class EncouragementOptionsScreen extends StatefulWidget {
  const EncouragementOptionsScreen({super.key});

  @override
  State<EncouragementOptionsScreen> createState() => _EncouragementOptionsScreenState();
}

class _EncouragementOptionsScreenState extends State<EncouragementOptionsScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Encouragement Options')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    value: app.settings.encouragementFlashEnabled,
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.celebration, size: 36, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customize Encouragements',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Set the encouragement text shown to servers',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Consumer<AppState>(
              builder: (context, app, _) => Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: 'Add a new encouragement',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) async {
                        if (value.trim().isEmpty) return;
                        final newList = List<String>.from(app.settings.customEncouragements ?? encouragements);
                        newList.add(value.trim());
                        app.settings.customEncouragements = newList;
                        await app.saveSettings(app.settings);
                        setState(() {
                          _controller.clear();
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () async {
                      final value = _controller.text.trim();
                      if (value.isEmpty) return;
                      final app = Provider.of<AppState>(context, listen: false);
                      final newList = List<String>.from(app.settings.customEncouragements ?? encouragements);
                      newList.add(value);
                      app.settings.customEncouragements = newList;
                      await app.saveSettings(app.settings);
                      setState(() {
                        _controller.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Current Encouragements:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Consumer<AppState>(
              builder: (context, app, _) {
                final list = app.settings.customEncouragements ?? encouragements;
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (context, index) => Container(
                    width: double.infinity,
                    height: 2,
                    color: Colors.grey[700],
                  ),
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(list[index]),
                      trailing: IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          final newList = List<String>.from(list);
                          newList.removeAt(index);
                          app.settings.customEncouragements = newList;
                          await app.saveSettings(app.settings);
                          setState(() {});
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
