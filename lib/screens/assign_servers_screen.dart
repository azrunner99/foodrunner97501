import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class AssignServersScreen extends StatefulWidget {
  const AssignServersScreen({super.key});

  @override
  State<AssignServersScreen> createState() => _AssignServersScreenState();
}

class _AssignServersScreenState extends State<AssignServersScreen> {
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
      appBar: AppBar(title: const Text('Assign Servers')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    app.setTodayPlan(lunch.toList(), dinner.toList());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Roster saved for today.')),
                    );
                  },
                  child: const Text('Save Roster'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run Food!'),
                  onPressed: () {
                    app.setTodayPlan(lunch.toList(), dinner.toList());
                    // force-start so we show the grid immediately
                    final ok = app.forceStartCurrentShift();
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select at least one server for the current shift.')),
                      );
                      return;
                    }
                    Navigator.pop(context); // back to Home -> grid visible
                  },
                ),
              ),
            ],
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
