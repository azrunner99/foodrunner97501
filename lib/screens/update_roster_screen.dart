import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class UpdateRosterScreen extends StatefulWidget {
  const UpdateRosterScreen({super.key});

  @override
  State<UpdateRosterScreen> createState() => _UpdateRosterScreenState();
}

class _UpdateRosterScreenState extends State<UpdateRosterScreen> {
  final Set<String> lunch = {};
  final Set<String> dinner = {};

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final plan = app.todayPlan;
    if (plan != null) {
      lunch.addAll(plan.lunchRoster);
      dinner.addAll(plan.dinnerRoster);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final servers = app.servers;

    return Scaffold(
      appBar: AppBar(title: const Text('Active Roster (Lunch & Dinner)')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save & Apply'),
            onPressed: () {
              app.updateBothRosters(lunch: lunch.toList(), dinner: dinner.toList());
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: _column(context, 'Lunch', servers, lunch)),
            const SizedBox(width: 12),
            Expanded(child: _column(context, 'Dinner', servers, dinner)),
          ],
        ),
      ),
    );
  }

  Widget _column(BuildContext context, String title, List<Server> servers, Set<String> set) {
    return Card(
      child: Column(
        children: [
          ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: servers.length,
              itemBuilder: (_, i) {
                final s = servers[i];
                final checked = set.contains(s.id);
                return CheckboxListTile(
                  title: Text(s.name),
                  value: checked,
                  onChanged: (v) {
                    setState(() {
                      if (v ?? false) {
                        set.add(s.id);
                      } else {
                        set.remove(s.id);
                      }
                    });
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
