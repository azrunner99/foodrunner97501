import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class StartShiftScreen extends StatefulWidget {
  const StartShiftScreen({super.key});

  @override
  State<StartShiftScreen> createState() => _StartShiftScreenState();
}

class _StartShiftScreenState extends State<StartShiftScreen> {
  late final TextEditingController _labelCtrl;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: _defaultLabelForNow());
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  String _defaultLabelForNow() {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    if (minutes >= 15 * 60 + 30) return 'Dinner'; // >= 3:30 PM
    if (minutes >= 11 * 60) return 'Lunch';       // >= 11:00 AM
    return 'Other';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final servers = app.servers;

    return Scaffold(
      appBar: AppBar(title: const Text('Start New Shift')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Shift label',
                      hintText: 'Lunch, Dinner, Other…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select who is working',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: servers.length,
              itemBuilder: (context, i) {
                final s = servers[i];
                final checked = _selected.contains(s.id);
                return CheckboxListTile(
                  title: Text(s.name),
                  value: checked,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selected.add(s.id);
                      } else {
                        _selected.remove(s.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Shift'),
            onPressed: () async {
              if (_selected.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pick at least one server.')),
                );
                return;
              }
              await context.read<AppState>().startNewShift(
                    label: _labelCtrl.text,
                    workingIds: _selected.toList(),
                  );
              if (mounted) Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}
