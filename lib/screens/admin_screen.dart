import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import 'active_roster_screen.dart';
import 'manage_servers_screen.dart';
import 'server_avatar_settings_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _unlocked = false;
  bool _todayRosterOnly = true;
  final _pinCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _pinCtrl,
                decoration: const InputDecoration(labelText: 'Enter PIN'),
                obscureText: true,
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _tryUnlock(app),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => _tryUnlock(app), child: const Text('Unlock')),
            ],
          ),
        ),
      );
    }

    final servers = _todayRosterOnly
        ? app.workingServerIds.map((id) => app.serverById(id)).whereType<Server>().toList()
        : app.servers;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin • Tools')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shift Controls', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text('Resume Paused Shift (PIN)'),
                  subtitle: Text(app.shiftPaused ? 'Tap to resume ${app.shiftType}.' : 'No paused shift.'),
                  onTap: app.shiftPaused
                      ? () async {
                          final ok = await context.read<AppState>().resumePausedShiftWithPin(AppState.adminPin);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ok ? 'Shift resumed.' : 'Wrong PIN')),
                          );
                        }
                      : null,
                ),
                ListTile(
                  leading: const Icon(Icons.pause_circle_outline),
                  title: const Text('Pause Current Shift (PIN)'),
                  subtitle: Text(app.shiftActive ? 'Temporarily stop counting.' : 'No active shift.'),
                  onTap: app.shiftActive
                      ? () async {
                          final ok = await context.read<AppState>().pauseCurrentShiftWithPin(AppState.adminPin);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ok ? 'Shift paused.' : 'Wrong PIN')),
                          );
                        }
                      : null,
                ),
                ListTile(
                  leading: const Icon(Icons.stop_circle_outlined),
                  title: const Text('End Current Shift (Finalize, PIN)'),
                  subtitle: Text(app.shiftActive
                      ? 'Finalize ${app.shiftType} and award badges.'
                      : 'No active shift to finalize.'),
                  onTap: app.shiftActive
                      ? () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('End current shift?'),
                              content: Text(
                                  'This will finalize ${app.shiftType} and award badges/points. Continue?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel')),
                                FilledButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('End Now')),
                              ],
                            ),
                          );
                          if (confirmed != true) return;
                          final ok = await context.read<AppState>().endCurrentShiftWithPin(AppState.adminPin);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ok ? 'Shift finalized.' : 'Wrong PIN')),
                          );
                        }
                      : null,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.group),
                  label: const Text('Modify Active Roster'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ActiveRosterScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.manage_accounts),
                  label: const Text('Manage Servers (Add / Rename / Remove)'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageServersScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('Server Avatar Settings'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ServerAvatarSettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text("Today's roster only"),
            value: _todayRosterOnly,
            onChanged: (v) => setState(() => _todayRosterOnly = v),
          ),
          const _HeaderRow(),
          ...servers.map((s) {
            final bins = app.integrityBinsFor(s.id, todayOnly: _todayRosterOnly);
            return _DataRow(name: s.name, bins: bins);
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _tryUnlock(AppState app) {
    if (_pinCtrl.text == AppState.adminPin) {
      setState(() => _unlocked = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong PIN')));
    }
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: const [
            Expanded(flex: 4, child: Text('Server', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: Text('Singles/min')),
            Expanded(child: Text('Doubles/min')),
            Expanded(child: Text('Triples/min')),
            Expanded(child: Text('4+/min')),
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String name;
  final Map<String, int> bins;
  const _DataRow({required this.name, required this.bins});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(name)),
          Expanded(child: Text('${bins['1']}')),
          Expanded(child: Text('${bins['2']}')),
          Expanded(child: Text('${bins['3']}')),
          Expanded(child: Text('${bins['4+']}')),
        ],
      ),
    );
  }
}