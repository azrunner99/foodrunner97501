import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../widgets/month_day_picker.dart';

class ArchivedServersScreen extends StatefulWidget {
  const ArchivedServersScreen({super.key});

  @override
  State<ArchivedServersScreen> createState() => _ArchivedServersScreenState();
}

class _ArchivedServersScreenState extends State<ArchivedServersScreen> {
  // Color constants matching the app's theme
  static const Color primaryColor = Color(0xFF00B4D8);
  static const Color accentColor = Color(0xFFFF6B35);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  final Map<String, bool> _expandedStates = {};

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final allServers = app.servers;

    // Show only archived servers
    final list = allServers.where((server) {
      final profile = app.profiles[server.id] ?? ServerProfile();
      return profile.isArchived;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Servers'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor,
                primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              backgroundColor,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Enhanced Server Count Header
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.1),
                    accentColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.archive, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${list.length} Archived Servers',
                    style: TextStyle(
                      fontSize: 18,
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
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: (profile.bannerPath?.isNotEmpty ?? false)
                          ? null
                          : LinearGradient(
                              colors: isExpanded
                                  ? [
                                      primaryColor.withOpacity(0.08),
                                      Colors.blue.shade50,
                                    ]
                                  : [
                                      Colors.grey.shade100,
                                      Colors.grey.shade50,
                                    ],
                            ),
                      image: (profile.bannerPath?.isNotEmpty ?? false)
                          ? DecorationImage(
                              image: AssetImage(profile.bannerPath!),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.4),
                                BlendMode.darken,
                              ),
                            )
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isExpanded ? primaryColor : warningColor,
                          width: isExpanded ? 3 : 2),
                      boxShadow: [
                        BoxShadow(
                          color: isExpanded
                              ? primaryColor.withOpacity(0.3)
                              : warningColor.withOpacity(0.2),
                          blurRadius: isExpanded ? 12 : 8,
                          offset: const Offset(0, 4),
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
                                    border: Border.all(
                                        color: Colors.grey.shade300, width: 2),
                                    image: (profile.avatarPath?.isNotEmpty ??
                                            false)
                                        ? DecorationImage(
                                            image:
                                                AssetImage(profile.avatarPath!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: (profile.avatarPath?.isEmpty ?? true)
                                      ? Icon(Icons.person,
                                          size: 30, color: Colors.grey.shade500)
                                      : null,
                                ),

                                const SizedBox(width: 16),

                                // Server Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: (profile.bannerPath
                                                          ?.isNotEmpty ??
                                                      false)
                                                  ? const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4)
                                                  : null,
                                              decoration: (profile.bannerPath
                                                          ?.isNotEmpty ??
                                                      false)
                                                  ? BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.3),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    )
                                                  : null,
                                              child: Text(
                                                server.name,
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: (profile.bannerPath
                                                              ?.isNotEmpty ??
                                                          false)
                                                      ? Colors.white
                                                      : Colors.grey.shade600,
                                                  shadows: (profile.bannerPath
                                                              ?.isNotEmpty ??
                                                          false)
                                                      ? [
                                                          Shadow(
                                                            offset:
                                                                const Offset(
                                                                    1, 1),
                                                            blurRadius: 4,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.8),
                                                          ),
                                                          Shadow(
                                                            offset:
                                                                const Offset(
                                                                    0, 0),
                                                            blurRadius: 2,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.5),
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (profile.hireDate.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding:
                                              (profile.bannerPath?.isNotEmpty ??
                                                      false)
                                                  ? const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2)
                                                  : null,
                                          decoration: (profile
                                                      .bannerPath?.isNotEmpty ??
                                                  false)
                                              ? BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                )
                                              : null,
                                          child: Text(
                                            'Hired: ${profile.hireDate}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: (profile.bannerPath
                                                          ?.isNotEmpty ??
                                                      false)
                                                  ? Colors.white
                                                  : Colors.grey.shade500,
                                              shadows: (profile.bannerPath
                                                          ?.isNotEmpty ??
                                                      false)
                                                  ? [
                                                      Shadow(
                                                        offset:
                                                            const Offset(1, 1),
                                                        blurRadius: 3,
                                                        color: Colors.black
                                                            .withOpacity(0.8),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (profile.birthday.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Container(
                                          padding:
                                              (profile.bannerPath?.isNotEmpty ??
                                                      false)
                                                  ? const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2)
                                                  : null,
                                          decoration: (profile
                                                      .bannerPath?.isNotEmpty ??
                                                  false)
                                              ? BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                )
                                              : null,
                                          child: Text(
                                            'Birthday: ${profile.birthday}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: (profile.bannerPath
                                                          ?.isNotEmpty ??
                                                      false)
                                                  ? Colors.white
                                                  : Colors.grey.shade500,
                                              shadows: (profile.bannerPath
                                                          ?.isNotEmpty ??
                                                      false)
                                                  ? [
                                                      Shadow(
                                                        offset:
                                                            const Offset(1, 1),
                                                        blurRadius: 3,
                                                        color: Colors.black
                                                            .withOpacity(0.8),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Expand Icon
                                Container(
                                  padding:
                                      (profile.bannerPath?.isNotEmpty ?? false)
                                          ? const EdgeInsets.all(4)
                                          : null,
                                  decoration: (profile.bannerPath?.isNotEmpty ??
                                          false)
                                      ? BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                        )
                                      : null,
                                  child: Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: (profile.bannerPath?.isNotEmpty ??
                                            false)
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    shadows: (profile.bannerPath?.isNotEmpty ??
                                            false)
                                        ? [
                                            Shadow(
                                              offset: const Offset(1, 1),
                                              blurRadius: 2,
                                              color:
                                                  Colors.black.withOpacity(0.8),
                                            ),
                                          ]
                                        : null,
                                  ),
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
                            decoration:
                                (profile.bannerPath?.isNotEmpty ?? false)
                                    ? BoxDecoration(
                                        color: Colors.white.withOpacity(0.95),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(16),
                                          bottomRight: Radius.circular(16),
                                        ),
                                      )
                                    : null,
                            child: Column(
                              children: [
                                // Server Details Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Server Details',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildDetailRow('ID:', server.id),
                                          _buildDetailRow('Total Runs:',
                                              '${app.totals[server.id] ?? 0}'),
                                          _buildDetailRow('XP Points:',
                                              '${profile.points}'),
                                          if (profile.hireDate.isNotEmpty)
                                            _buildDetailRow(
                                                'Hire Date:', profile.hireDate),
                                          if (profile.birthday.isNotEmpty)
                                            _buildDetailRow(
                                                'Birthday:', profile.birthday),
                                          if (profile
                                              .archiveNotes.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Text(
                                              'Archive Notes:',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: warningColor,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    warningColor
                                                        .withOpacity(0.1),
                                                    warningColor
                                                        .withOpacity(0.05),
                                                  ],
                                                ),
                                                border: Border.all(
                                                    color: warningColor
                                                        .withOpacity(0.3)),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                profile.archiveNotes,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: warningColor
                                                      .withOpacity(0.8),
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Enhanced Action Buttons
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: backgroundColor.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _editServer(
                                              context, server, profile),
                                          icon: const Icon(Icons.edit_outlined),
                                          label: const Text('Edit'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            elevation: 2,
                                            shadowColor: Colors.black26,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _restoreServer(context, server),
                                          icon: const Icon(
                                              Icons.restore_outlined),
                                          label: const Text('Restore'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: successColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            elevation: 2,
                                            shadowColor: Colors.black26,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _deleteServer(context, server),
                                          icon:
                                              const Icon(Icons.delete_outline),
                                          label: const Text('Delete'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: errorColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            elevation: 2,
                                            shadowColor: Colors.black26,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editServer(
      BuildContext context, Server server, ServerProfile profile) async {
    final nameController = TextEditingController(text: server.name);
    final hireDateController = TextEditingController(text: profile.hireDate);
    final birthdayController = TextEditingController(text: profile.birthday);

    final result = await showDialog<Map<String, dynamic>>(
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
                  labelText: 'Hire Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        _parseDate(hireDateController.text) ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    hireDateController.text =
                        '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: birthdayController,
                decoration: const InputDecoration(
                  labelText: 'Birthday',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.cake),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showMonthDayPicker(
                    context: context,
                    initialDate: _parseBirthday(birthdayController.text) ??
                        DateTime(DateTime.now().year, 1, 1),
                    helpText: 'Select Birthday',
                    cancelText: 'Cancel',
                    confirmText: 'Save',
                  );
                  if (date != null) {
                    birthdayController.text =
                        '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
                  }
                },
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
              // Check if only profile info (hire date/birthday) is being changed
              final nameChanged = nameController.text.trim() != server.name;
              final profileChanged =
                  hireDateController.text.trim() != profile.hireDate ||
                      birthdayController.text.trim() != profile.birthday;

              if (nameChanged) {
                // PIN required for name changes
                final pin = await _promptForPin(
                    context, 'Enter PIN to change server name');
                if (pin == null || !mounted) return;

                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'hireDate': hireDateController.text.trim(),
                  'birthday': birthdayController.text.trim(),
                  'pin': pin,
                  'nameChanged': true,
                });
              } else if (profileChanged) {
                // No PIN required for profile info only
                if (!mounted) return;
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'hireDate': hireDateController.text.trim(),
                  'birthday': birthdayController.text.trim(),
                  'pin': '',
                  'nameChanged': false,
                });
              } else {
                // No changes made
                if (!mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final app = context.read<AppState>();

      // Update server name if changed and PIN was provided
      if (result['nameChanged'] == true &&
          result['name']!.isNotEmpty &&
          result['name'] != server.name) {
        final pin = result['pin'] as String;
        final success =
            await app.renameServer(server.id, result['name']!, pin: pin);
        if (!success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wrong PIN or rename failed')),
            );
          }
          return;
        }
      }

      // Update profile information (no PIN required)
      final updatedProfile = profile.copyWith(
        hireDate: result['hireDate']!,
        birthday: result['birthday']!,
      );
      await app.updateServerProfile(server.id, updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server updated successfully')),
        );
      }
    }
  }

  Future<void> _restoreServer(BuildContext context, Server server) async {
    final app = context.read<AppState>();
    final profile = app.profiles[server.id] ?? ServerProfile();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [successColor, successColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restore_outlined,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Restore ${server.name}?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: successColor.withOpacity(0.3)),
              ),
              child: const Text(
                'Restoring will make this server visible in active rosters again. '
                'They will be available for shift assignments.',
                style: TextStyle(height: 1.3),
              ),
            ),
            if (profile.archiveNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Archive notes:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: warningColor.withOpacity(0.1),
                  border: Border.all(color: warningColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  profile.archiveNotes,
                  style: TextStyle(
                    fontSize: 14,
                    color: warningColor.withOpacity(0.8),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ℹ️ Archive notes will be cleared when restoring.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: infoColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: successColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 2,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // No PIN required for restoring - admin is already authenticated
      final updatedProfile = profile.copyWith(
        isArchived: false,
        archiveNotes: '', // Clear archive notes when restoring
      );
      await app.updateServerProfile(server.id, updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${server.name} has been restored')),
        );
      }
    }
  }

  Future<void> _deleteServer(BuildContext context, Server server) async {
    final result = await _showDeleteDialog(context, server.name);

    if (result != null) {
      final pin = await _promptForPin(
          context, 'Enter PIN to permanently delete server');
      if (pin == null) return;

      final app = context.read<AppState>();

      // Store deletion notes in profile before deleting
      if (result.isNotEmpty) {
        final profile = app.profiles[server.id] ?? ServerProfile();
        final updatedProfile = profile.copyWith(archiveNotes: result);
        await app.updateServerProfile(server.id, updatedProfile);
      }

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
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDate(String date) {
    if (date.isEmpty) return null;
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Invalid date format
    }
    return null;
  }

  DateTime? _parseBirthday(String birthday) {
    if (birthday.isEmpty) return null;
    try {
      final parts = birthday.split('/');
      if (parts.length == 2) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        // Use current year as a reference for birthday picker
        return DateTime(DateTime.now().year, month, day);
      }
    } catch (e) {
      // Invalid date format
    }
    return null;
  }

  Future<String?> _showDeleteDialog(
      BuildContext context, String serverName) async {
    final notesController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [errorColor, errorColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Delete $serverName?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: errorColor.withOpacity(0.3)),
              ),
              child: const Text(
                'This will permanently delete the server and ALL their data. '
                'This action cannot be undone. Consider archiving instead.',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                    height: 1.3),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Optional: Add notes about why this server is being deleted:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'e.g., Terminated for cause, data cleanup, duplicate entry...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: errorColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, notesController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 2,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
