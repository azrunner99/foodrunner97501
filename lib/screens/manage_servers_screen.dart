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
  final Map<String, bool> _expandedStates = {};

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = app.servers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Servers'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Add Server Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'New server name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_nameCtrl.text.trim().isEmpty) return;
                    await context.read<AppState>().addServer(_nameCtrl.text.trim());
                    _nameCtrl.clear();
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Server'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Server Count Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Icon(Icons.group, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  '${list.length} Servers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          // Server List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final server = list[i];
                final profile = app.profiles[server.id] ?? ServerProfile();
                final isExpanded = _expandedStates[server.id] ?? false;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Main Server Card
                      InkWell(
                        onTap: () {
                          setState(() {
                            _expandedStates[server.id] = !isExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Server Avatar
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300, width: 2),
                                  image: (profile.avatarPath?.isNotEmpty ?? false)
                                      ? DecorationImage(
                                          image: AssetImage(profile.avatarPath!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: (profile.avatarPath?.isEmpty ?? true)
                                    ? Icon(Icons.person, size: 30, color: Colors.grey.shade500)
                                    : null,
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Server Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      server.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Station: ${server.stationType}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    if (profile.hireDate.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Hired: ${profile.hireDate}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                    if (profile.birthday.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Birthday: ${profile.birthday}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              // Banner Preview (if has banner)
                              if (profile.bannerPath?.isNotEmpty ?? false) ...[
                                Container(
                                  width: 40,
                                  height: 30,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    image: DecorationImage(
                                      image: AssetImage(profile.bannerPath!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                              
                              // Expand Icon
                              Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Expanded Options
                      if (isExpanded) ...[
                        const Divider(height: 1),
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Server Details Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Server Details',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildDetailRow('ID:', server.id),
                                        _buildDetailRow('Total Runs:', '${app.totals[server.id] ?? 0}'),
                                        _buildDetailRow('XP Points:', '${profile.points}'),
                                        if (profile.hireDate.isNotEmpty)
                                          _buildDetailRow('Hire Date:', profile.hireDate),
                                        if (profile.birthday.isNotEmpty)
                                          _buildDetailRow('Birthday:', profile.birthday),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _editServer(context, server, profile),
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _archiveServer(context, server),
                                      icon: const Icon(Icons.archive),
                                      label: const Text('Archive'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange.shade600,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _deleteServer(context, server),
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Delete'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade600,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editServer(BuildContext context, Server server, ServerProfile profile) async {
    final nameController = TextEditingController(text: server.name);
    final hireDateController = TextEditingController(text: profile.hireDate);
    final birthdayController = TextEditingController(text: profile.birthday);
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${server.name}'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Server Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hireDateController,
                decoration: const InputDecoration(
                  labelText: 'Hire Date (MM/DD/YYYY)',
                  border: OutlineInputBorder(),
                  hintText: '01/15/2024',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: birthdayController,
                decoration: const InputDecoration(
                  labelText: 'Birthday (MM/DD)',
                  border: OutlineInputBorder(),
                  hintText: '03/22',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = await _promptForPin(context, 'Enter PIN to save changes');
              if (pin == null) return;
              
              Navigator.pop(context, {
                'name': nameController.text.trim(),
                'hireDate': hireDateController.text.trim(),
                'birthday': birthdayController.text.trim(),
                'pin': pin,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      final app = context.read<AppState>();
      
      // Update server name if changed
      if (result['name']!.isNotEmpty && result['name'] != server.name) {
        final success = await app.renameServer(server.id, result['name']!, pin: result['pin']!);
        if (!success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wrong PIN or rename failed')),
            );
          }
          return;
        }
      }
      
      // Update profile information
      final updatedProfile = profile.copyWith(
        hireDate: result['hireDate']!,
        birthday: result['birthday']!,
      );
      app.profiles[server.id] = updatedProfile;
      await app.save();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server updated successfully')),
        );
      }
    }
  }

  Future<void> _archiveServer(BuildContext context, Server server) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Archive ${server.name}?'),
        content: const Text(
          'Archiving will hide this server from active rosters but preserve their data. '
          'You can restore archived servers later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final pin = await _promptForPin(context, 'Enter PIN to archive server');
      if (pin == null) return;
      
      // For now, we'll implement archive as adding an 'archived' flag to the profile
      final app = context.read<AppState>();
      final profile = app.profiles[server.id] ?? ServerProfile();
      profile.isArchived = true;
      app.profiles[server.id] = profile;
      await app.save();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${server.name} has been archived')),
        );
      }
    }
  }

  Future<void> _deleteServer(BuildContext context, Server server) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${server.name}?'),
        content: const Text(
          'This will permanently delete the server and ALL their data. '
          'This action cannot be undone. Consider archiving instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final pin = await _promptForPin(context, 'Enter PIN to permanently delete server');
      if (pin == null) return;
      
      final app = context.read<AppState>();
      final success = await app.removeServer(server.id, pin: pin);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Server deleted' : 'Wrong PIN')),
        );
      }
    }
  }

  Future<String?> _promptForPin(BuildContext context, String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'PIN',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
