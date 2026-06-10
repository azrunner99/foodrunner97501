import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class ManageServersScreen extends StatefulWidget {
  const ManageServersScreen({super.key});

  @override
  State<ManageServersScreen> createState() => _ManageServersScreenState();
}

class _ManageServersScreenState extends State<ManageServersScreen> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final active = app.allServers.where((s) => !s.archived).toList();
    final archived = app.allServers.where((s) => s.archived).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Servers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'New server name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    if (_nameCtrl.text.trim().isEmpty) return;
                    await context.read<AppState>().addServer(_nameCtrl.text.trim());
                    _nameCtrl.clear();
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: [
                for (final s in active) _activeTile(context, s),
                if (archived.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      'ARCHIVED',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  for (final s in archived) _archivedTile(context, s),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeTile(BuildContext context, Server s) {
    return ListTile(
      title: Text(s.name),
      subtitle: Text('ID: ${s.id}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Rename (PIN)',
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final newName = await _prompt(context, 'Rename ${s.name}', 'New name');
              if (newName == null || newName.trim().isEmpty) return;
              final pin = await _prompt(context, 'Enter PIN', 'PIN', pin: true);
              if (pin == null) return;
              final ok = await context.read<AppState>().renameServer(s.id, newName.trim(), pin: pin);
              _toast(ok ? 'Renamed.' : 'Wrong PIN');
            },
          ),
          IconButton(
            tooltip: 'Archive (PIN)',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () async {
              final confirmed = await _confirm(
                context,
                'Archive ${s.name}?',
                "They'll be hidden from rosters, leaderboards, and reports. "
                    'Their history is kept and you can restore them later.',
                'Archive',
              );
              if (!confirmed) return;
              final pin = await _prompt(context, 'Enter PIN', 'PIN', pin: true);
              if (pin == null) return;
              final ok = await context.read<AppState>().archiveServer(s.id, pin: pin);
              _toast(ok ? '${s.name} archived.' : 'Wrong PIN');
            },
          ),
          IconButton(
            tooltip: 'Delete permanently (PIN)',
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: () => _deleteFlow(context, s),
          ),
        ],
      ),
    );
  }

  Widget _archivedTile(BuildContext context, Server s) {
    return ListTile(
      leading: const Icon(Icons.person_off_outlined, color: Colors.black38),
      title: Text(s.name, style: const TextStyle(color: Colors.black54)),
      subtitle: const Text('Archived'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Restore (PIN)',
            icon: const Icon(Icons.unarchive_outlined, color: Colors.green),
            onPressed: () async {
              final pin = await _prompt(context, 'Enter PIN to restore ${s.name}', 'PIN', pin: true);
              if (pin == null) return;
              final ok = await context.read<AppState>().restoreServer(s.id, pin: pin);
              _toast(ok ? '${s.name} restored.' : 'Wrong PIN');
            },
          ),
          IconButton(
            tooltip: 'Delete permanently (PIN)',
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: () => _deleteFlow(context, s),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFlow(BuildContext context, Server s) async {
    final confirmed = await _confirm(
      context,
      'Permanently delete ${s.name}?',
      'This erases their stats and removes them from all past records. '
          'This cannot be undone. Consider archiving instead.',
      'Delete forever',
      destructive: true,
    );
    if (!confirmed) return;
    final pin = await _prompt(context, 'Enter PIN to DELETE ${s.name}', 'PIN', pin: true);
    if (pin == null) return;
    final ok = await context.read<AppState>().removeServer(s.id, pin: pin);
    _toast(ok ? '${s.name} deleted.' : 'Wrong PIN');
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String body,
    String confirmLabel, {
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: destructive ? FilledButton.styleFrom(backgroundColor: Colors.red) : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<String?> _prompt(BuildContext context, String title, String label, {bool pin = false}) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(labelText: label),
          obscureText: pin,
          keyboardType: pin ? TextInputType.number : TextInputType.text,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('OK')),
        ],
      ),
    );
  }
}
