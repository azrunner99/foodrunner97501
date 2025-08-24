import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../gamification.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final servers = app.servers;
    final s = app.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Server List')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gamification', style: TextStyle(fontWeight: FontWeight.w700)),
                  SwitchListTile(
                    title: const Text('Enable gamification'),
                    value: s.enableGamification,
                    onChanged: (v) => app.updateSettings(
                      GamificationSettings(
                        enableGamification: v,
                        showTeamTotals: s.showTeamTotals,
                        showGoalProgress: s.showGoalProgress,
                        showMvpConfetti: s.showMvpConfetti,
                        showEncouragement: s.showEncouragement,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Show team totals'),
                    value: s.showTeamTotals,
                    onChanged: (v) => app.updateSettings(
                      GamificationSettings(
                        enableGamification: s.enableGamification,
                        showTeamTotals: v,
                        showGoalProgress: s.showGoalProgress,
                        showMvpConfetti: s.showMvpConfetti,
                        showEncouragement: s.showEncouragement,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Show goal progress bar'),
                    value: s.showGoalProgress,
                    onChanged: (v) => app.updateSettings(
                      GamificationSettings(
                        enableGamification: s.enableGamification,
                        showTeamTotals: s.showTeamTotals,
                        showGoalProgress: v,
                        showMvpConfetti: s.showMvpConfetti,
                        showEncouragement: s.showEncouragement,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('MVP confetti'),
                    value: s.showMvpConfetti,
                    onChanged: (v) => app.updateSettings(
                      GamificationSettings(
                        enableGamification: s.enableGamification,
                        showTeamTotals: s.showTeamTotals,
                        showGoalProgress: s.showGoalProgress,
                        showMvpConfetti: v,
                        showEncouragement: s.showEncouragement,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Encouragement messages'),
                    value: s.showEncouragement,
                    onChanged: (v) => app.updateSettings(
                      GamificationSettings(
                        enableGamification: s.enableGamification,
                        showTeamTotals: s.showTeamTotals,
                        showGoalProgress: s.showGoalProgress,
                        showMvpConfetti: s.showMvpConfetti,
                        showEncouragement: v,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Add server',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _add(context),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: () => _add(context), child: const Text('Add')),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: servers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = servers[i];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(s.name),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'rename') {
                        final newName = await _promptRename(context, s.name);
                        if (newName != null && newName.trim().isNotEmpty) {
                          await context.read<AppState>().renameServer(s.id, newName);
                        }
                      } else if (v == 'delete') {
                        final ok = await _confirmDelete(context, s.name);
                        if (ok == true) {
                          await context.read<AppState>().removeServer(s.id);
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptRename(BuildContext context, String current) async {
    final ctrl = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename server'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Save')),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove server'),
        content: Text('Remove "$name"? This also deletes their totals.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
  }

  void _add(BuildContext context) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await context.read<AppState>().addServer(name);
    _nameCtrl.clear();
  }
}
