import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/server.dart';
import '../providers/nps_provider.dart';

/// Dialog for adding or editing a server
class ServerManagementDialog extends StatefulWidget {
  final NPSServer? server; // null for adding, non-null for editing

  const ServerManagementDialog({super.key, this.server});

  @override
  State<ServerManagementDialog> createState() => _ServerManagementDialogState();
}

class _ServerManagementDialogState extends State<ServerManagementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hireDateController = TextEditingController();

  bool _isActive = true;
  DateTime? _selectedHireDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.server != null) {
      // Editing existing server
      _nameController.text = widget.server!.name;
      _selectedHireDate = widget.server!.hireDate;
      _hireDateController.text = _formatDate(_selectedHireDate!);
      _isActive = widget.server!.active;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hireDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _selectHireDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedHireDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select hire date',
    );

    if (selectedDate != null) {
      setState(() {
        _selectedHireDate = selectedDate;
        _hireDateController.text = _formatDate(selectedDate);
      });
    }
  }

  Future<void> _saveServer() async {
    if (!_formKey.currentState!.validate() || _selectedHireDate == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final npsProvider = Provider.of<NPSProvider>(context, listen: false);

      if (widget.server == null) {
        // Adding new server
        final newServer = NPSServer(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          hireDate: _selectedHireDate!,
          active: _isActive,
        );

        final success = await npsProvider.addServer(newServer);
        if (success) {
          if (mounted) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Server added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(npsProvider.errorMessage ?? 'Failed to add server'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Editing existing server
        final updatedServer = widget.server!.copyWith(
          name: _nameController.text.trim(),
          hireDate: _selectedHireDate!,
          active: _isActive,
          updatedAt: DateTime.now(),
        );

        final success = await npsProvider.updateServer(updatedServer);
        if (success) {
          if (mounted) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Server updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(npsProvider.errorMessage ?? 'Failed to update server'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.server != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Server' : 'Add New Server'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Server Name *',
                hintText: 'Enter server name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Server name is required';
                }
                if (value.trim().length < 2) {
                  return 'Server name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hireDateController,
              decoration: const InputDecoration(
                labelText: 'Hire Date *',
                hintText: 'Select hire date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: _selectHireDate,
              validator: (value) {
                if (_selectedHireDate == null) {
                  return 'Hire date is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value ?? true;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    'Active Server',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            if (!_isActive)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Inactive servers cannot receive new feedback',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveServer,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

/// Widget for managing servers in the admin interface
class ServerManagementWidget extends StatelessWidget {
  const ServerManagementWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NPSProvider>(
      builder: (context, npsProvider, child) {
        if (npsProvider.isLoading && npsProvider.servers.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Server Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => const ServerManagementDialog(),
                    );
                    if (result == true) {
                      // Server was added, refresh the list
                      npsProvider.refreshData();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Server'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (npsProvider.hasError)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        npsProvider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: npsProvider.servers.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No servers found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add your first server to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: npsProvider.servers.length,
                      itemBuilder: (context, index) {
                        final server = npsProvider.servers[index];
                        return ServerListTile(server: server);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// List tile widget for displaying server information
class ServerListTile extends StatelessWidget {
  final NPSServer server;

  const ServerListTile({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: server.active ? Colors.green : Colors.grey,
          child: Text(
            server.name.isNotEmpty ? server.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          server.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: server.active ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hired: ${_formatDate(server.hireDate)}'),
            Text(
              'Status: ${server.active ? "Active" : "Inactive"}',
              style: TextStyle(
                color: server.active ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            final npsProvider =
                Provider.of<NPSProvider>(context, listen: false);

            switch (value) {
              case 'edit':
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => ServerManagementDialog(server: server),
                );
                if (result == true) {
                  npsProvider.refreshData();
                }
                break;
              case 'archive':
                final confirmed = await _showArchiveConfirmation(context);
                if (confirmed == true) {
                  final success = await npsProvider.archiveServer(server.id!);
                  if (context.mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Server archived successfully'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
                break;
              case 'delete':
                final confirmed = await _showDeleteConfirmation(context);
                if (confirmed == true) {
                  final success = await npsProvider.deleteServer(server.id!);
                  if (context.mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Server deleted successfully'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (server.active)
              const PopupMenuItem(
                value: 'archive',
                child: ListTile(
                  leading: Icon(Icons.archive, color: Colors.orange),
                  title: Text('Archive'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<bool?> _showArchiveConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Server'),
        content: Text(
          'Are you sure you want to archive "${server.name}"?\n\n'
          'Archived servers will not be able to receive new feedback, '
          'but existing feedback will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Server'),
        content: Text(
          'Are you sure you want to delete "${server.name}"?\n\n'
          'This action cannot be undone. All feedback data for this server will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
