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
  final _pinCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = app.servers;

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
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = list[i];
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
                          if (!mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(ok ? 'Renamed.' : 'Wrong PIN')));
                        },
                      ),
                      IconButton(
                        tooltip: 'Remove (PIN)',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final pin = await _prompt(context, 'Enter PIN to remove ${s.name}', 'PIN', pin: true);
                          if (pin == null) return;
                          final ok = await context.read<AppState>().removeServer(s.id, pin: pin);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(ok ? 'Removed.' : 'Wrong PIN')));
                        },
                      ),
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
