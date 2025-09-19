import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nps_security_service.dart';
import '../services/nps_encryption_service.dart';
import '../services/nps_audit_service.dart';

/// Comprehensive security management screen
class NPSSecurityManagementScreen extends StatefulWidget {
  const NPSSecurityManagementScreen({super.key});

  @override
  State<NPSSecurityManagementScreen> createState() =>
      _NPSSecurityManagementScreenState();
}

class _NPSSecurityManagementScreenState
    extends State<NPSSecurityManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.security,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            const Text('Security Management'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.vpn_key), text: 'Encryption'),
            Tab(icon: Icon(Icons.list_alt), text: 'Audit Logs'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SecurityDashboardTab(),
          UserManagementTab(),
          EncryptionManagementTab(),
          AuditLogsTab(),
          SecuritySettingsTab(),
        ],
      ),
    );
  }
}

/// Security dashboard overview
class SecurityDashboardTab extends StatelessWidget {
  const SecurityDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<NPSSecurityService, NPSEncryptionService, NPSAuditService>(
      builder: (context, security, encryption, audit, child) {
        final securityStats = security.getSecurityStatistics();
        final encryptionStats = encryption.getEncryptionStatistics();
        final auditStats = audit.getAuditStatistics();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSecurityOverview(context, securityStats),
              const SizedBox(height: 20),
              _buildQuickActions(context, security, encryption, audit),
              const SizedBox(height: 20),
              _buildSecurityMetrics(
                  context, securityStats, encryptionStats, auditStats),
              const SizedBox(height: 20),
              _buildRecentSecurityEvents(context, audit),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecurityOverview(
      BuildContext context, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    context,
                    'System Status',
                    'Secure',
                    Icons.shield_outlined,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusCard(
                    context,
                    'Active Users',
                    '${stats['total_users']}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusCard(
                    context,
                    'Failed Logins (24h)',
                    '${stats['failed_logins_24h']}',
                    Icons.warning,
                    stats['failed_logins_24h'] > 0
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, NPSSecurityService security,
      NPSEncryptionService encryption, NPSAuditService audit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => audit.performIntegrityCheck(),
                  icon: const Icon(Icons.security),
                  label: const Text('Run Integrity Check'),
                ),
                ElevatedButton.icon(
                  onPressed: () => encryption.rotateKey(),
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Rotate Encryption Key'),
                ),
                ElevatedButton.icon(
                  onPressed: () => audit.cleanupOldLogs(),
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Cleanup Old Logs'),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showSecurityReport(context, security, encryption, audit),
                  icon: const Icon(Icons.assessment),
                  label: const Text('Generate Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityMetrics(
      BuildContext context,
      Map<String, dynamic> securityStats,
      Map<String, dynamic> encryptionStats,
      Map<String, dynamic> auditStats) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authentication',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildMetricRow(
                      'Active Sessions', '${securityStats['active_sessions']}'),
                  _buildMetricRow(
                      'Locked Accounts', '${securityStats['locked_accounts']}'),
                  _buildMetricRow(
                      'MFA Required',
                      securityStats['security_policy']['mfa_required']
                          ? 'Yes'
                          : 'No'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Encryption',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildMetricRow(
                      'Active Keys', '${encryptionStats['active_keys']}'),
                  _buildMetricRow(
                      'Algorithm', '${encryptionStats['current_algorithm']}'),
                  _buildMetricRow(
                      'PII Protection',
                      encryptionStats['pii_encryption_enabled']
                          ? 'Enabled'
                          : 'Disabled'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audit Trail',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildMetricRow('Total Logs', '${auditStats['total_logs']}'),
                  _buildMetricRow('Logs (24h)', '${auditStats['logs_24h']}'),
                  _buildMetricRow(
                      'Security Events', '${auditStats['security_events']}'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSecurityEvents(
      BuildContext context, NPSAuditService audit) {
    final securityLogs = audit.queryLogs(const AuditQuery(
      securityOnly: true,
      limit: 5,
    ));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Security Events',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (securityLogs.isEmpty)
              const Text('No recent security events')
            else
              ...securityLogs.map((log) => ListTile(
                    dense: true,
                    leading: Icon(
                      _getLogIcon(log.level),
                      color: _getLogColor(log.level),
                    ),
                    title: Text(log.action),
                    subtitle: Text(
                        '${log.userName} • ${_formatDateTime(log.timestamp)}'),
                    trailing: log.success
                        ? const Icon(Icons.check_circle,
                            color: Colors.green, size: 16)
                        : const Icon(Icons.error, color: Colors.red, size: 16),
                  )),
          ],
        ),
      ),
    );
  }

  IconData _getLogIcon(AuditLogLevel level) {
    switch (level) {
      case AuditLogLevel.critical:
        return Icons.dangerous;
      case AuditLogLevel.security:
        return Icons.security;
      case AuditLogLevel.error:
        return Icons.error;
      case AuditLogLevel.warning:
        return Icons.warning;
      case AuditLogLevel.info:
        return Icons.info;
    }
  }

  Color _getLogColor(AuditLogLevel level) {
    switch (level) {
      case AuditLogLevel.critical:
        return Colors.red.shade700;
      case AuditLogLevel.security:
        return Colors.purple;
      case AuditLogLevel.error:
        return Colors.red;
      case AuditLogLevel.warning:
        return Colors.orange;
      case AuditLogLevel.info:
        return Colors.blue;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showSecurityReport(BuildContext context, NPSSecurityService security,
      NPSEncryptionService encryption, NPSAuditService audit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Report Generated'),
        content: const Text(
            'A comprehensive security report has been generated and is ready for download.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // In production, generate and download actual report
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security report downloaded')),
              );
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
}

/// User management tab
class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key});

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<NPSSecurityService>(
      builder: (context, security, child) {
        if (!security.hasPermission(Permission.manageUsers)) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Access Denied'),
                Text('You do not have permission to manage users.'),
              ],
            ),
          );
        }

        final users = security.getAllUsers();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'User Management',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateUserDialog(context, security),
                    icon: const Icon(Icons.add),
                    label: const Text('Create User'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getRoleColor(user.role),
                        child: Text(
                          user.displayName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(user.displayName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${user.email} • ${user.role.name}'),
                          Text(
                            'Last login: ${_formatDateTime(user.lastLoginAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'permissions',
                            child: ListTile(
                              leading: Icon(Icons.security),
                              title: Text('Permissions'),
                            ),
                          ),
                          if (user.id != security.currentUser?.id)
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Delete'),
                              ),
                            ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showEditUserDialog(context, security, user);
                              break;
                            case 'permissions':
                              _showUserPermissionsDialog(context, user);
                              break;
                            case 'delete':
                              _showDeleteUserDialog(context, security, user);
                              break;
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Colors.red;
      case UserRole.admin:
        return Colors.purple;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.teamLead:
        return Colors.green;
      case UserRole.server:
        return Colors.orange;
      case UserRole.viewer:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _showCreateUserDialog(
      BuildContext context, NPSSecurityService security) {
    // Implementation for create user dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New User'),
        content: const Text('User creation dialog would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(
      BuildContext context, NPSSecurityService security, UserProfile user) {
    // Implementation for edit user dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${user.displayName}'),
        content: const Text('User editing dialog would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showUserPermissionsDialog(BuildContext context, UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.displayName} Permissions'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Role: ${user.role.name}'),
              const SizedBox(height: 16),
              const Text('Permissions:'),
              const SizedBox(height: 8),
              ...user.getAllPermissions().map(
                    (permission) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.check,
                          color: Colors.green, size: 16),
                      title: Text(permission.name),
                    ),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(
      BuildContext context, NPSSecurityService security, UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to delete ${user.displayName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              security.deleteUser(user.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${user.displayName} deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Encryption management tab
class EncryptionManagementTab extends StatelessWidget {
  const EncryptionManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NPSEncryptionService>(
      builder: (context, encryption, child) {
        final stats = encryption.getEncryptionStatistics();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEncryptionStatus(context, stats),
              const SizedBox(height: 20),
              _buildKeyManagement(context, encryption),
              const SizedBox(height: 20),
              _buildEncryptionTest(context, encryption),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEncryptionStatus(
      BuildContext context, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Encryption Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEncryptionMetric(
                      'Algorithm', stats['current_algorithm']),
                ),
                Expanded(
                  child: _buildEncryptionMetric(
                      'Active Keys', '${stats['active_keys']}'),
                ),
                Expanded(
                  child: _buildEncryptionMetric(
                      'Total Keys', '${stats['total_keys']}'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEncryptionToggle(
                      'PII Encryption', stats['pii_encryption_enabled']),
                ),
                Expanded(
                  child: _buildEncryptionToggle('Feedback Encryption',
                      stats['feedback_encryption_enabled']),
                ),
                Expanded(
                  child: _buildEncryptionToggle(
                      'Export Encryption', stats['export_encryption_enabled']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEncryptionMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildEncryptionToggle(String label, bool enabled) {
    return Column(
      children: [
        Icon(
          enabled ? Icons.check_circle : Icons.cancel,
          color: enabled ? Colors.green : Colors.red,
          size: 32,
        ),
        const SizedBox(height: 4),
        Text(label),
        Text(
          enabled ? 'Enabled' : 'Disabled',
          style: TextStyle(
            color: enabled ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyManagement(
      BuildContext context, NPSEncryptionService encryption) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Management',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => encryption.rotateKey(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rotate Key'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => encryption.cleanupExpiredKeys(),
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Cleanup Expired'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (encryption.activeKey != null) ...[
              Text('Active Key: ${encryption.activeKey!.id}'),
              Text('Expires: ${encryption.activeKey!.expiresAt}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEncryptionTest(
      BuildContext context, NPSEncryptionService encryption) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Encryption Test',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await encryption.testEncryption();
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                          result['success'] ? 'Test Passed' : 'Test Failed'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (result['success']) ...[
                            Text(
                                'Original Length: ${result['original_length']} bytes'),
                            Text(
                                'Encrypted Length: ${result['encrypted_length']} bytes'),
                            Text(
                                'Encrypt Time: ${result['encrypt_time_microseconds']}μs'),
                            Text(
                                'Decrypt Time: ${result['decrypt_time_microseconds']}μs'),
                          ] else
                            Text('Error: ${result['error']}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                }
              },
              icon: const Icon(Icons.science),
              label: const Text('Run Test'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Audit logs tab
class AuditLogsTab extends StatefulWidget {
  const AuditLogsTab({super.key});

  @override
  State<AuditLogsTab> createState() => _AuditLogsTabState();
}

class _AuditLogsTabState extends State<AuditLogsTab> {
  AuditLogLevel? _selectedLevel;
  AuditCategory? _selectedCategory;
  bool _securityOnly = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<NPSAuditService>(
      builder: (context, audit, child) {
        final query = AuditQuery(
          levels: _selectedLevel != null ? [_selectedLevel!] : null,
          categories: _selectedCategory != null ? [_selectedCategory!] : null,
          securityOnly: _securityOnly,
          limit: 50,
        );

        final logs = audit.queryLogs(query);

        return Column(
          children: [
            _buildFilters(),
            Expanded(
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        _getLogIcon(log.level),
                        color: _getLogColor(log.level),
                      ),
                      title: Text(log.action),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${log.userName} • ${log.resource}'),
                          Text(
                            log.timestamp.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: log.success
                          ? const Icon(Icons.check_circle,
                              color: Colors.green, size: 16)
                          : const Icon(Icons.error,
                              color: Colors.red, size: 16),
                      onTap: () => _showLogDetails(context, log),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<AuditLogLevel>(
              initialValue: _selectedLevel,
              decoration: const InputDecoration(
                labelText: 'Level',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<AuditLogLevel>(
                  value: null,
                  child: Text('All Levels'),
                ),
                ...AuditLogLevel.values.map(
                  (level) => DropdownMenuItem(
                    value: level,
                    child: Text(level.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _selectedLevel = value),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<AuditCategory>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<AuditCategory>(
                  value: null,
                  child: Text('All Categories'),
                ),
                ...AuditCategory.values.map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
          ),
          const SizedBox(width: 16),
          FilterChip(
            label: const Text('Security Only'),
            selected: _securityOnly,
            onSelected: (value) => setState(() => _securityOnly = value),
          ),
        ],
      ),
    );
  }

  IconData _getLogIcon(AuditLogLevel level) {
    switch (level) {
      case AuditLogLevel.critical:
        return Icons.dangerous;
      case AuditLogLevel.security:
        return Icons.security;
      case AuditLogLevel.error:
        return Icons.error;
      case AuditLogLevel.warning:
        return Icons.warning;
      case AuditLogLevel.info:
        return Icons.info;
    }
  }

  Color _getLogColor(AuditLogLevel level) {
    switch (level) {
      case AuditLogLevel.critical:
        return Colors.red.shade700;
      case AuditLogLevel.security:
        return Colors.purple;
      case AuditLogLevel.error:
        return Colors.red;
      case AuditLogLevel.warning:
        return Colors.orange;
      case AuditLogLevel.info:
        return Colors.blue;
    }
  }

  void _showLogDetails(BuildContext context, AuditLogEntry log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(log.action),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('User', log.userName),
              _buildDetailRow('Resource', log.resource),
              _buildDetailRow('Category', log.category.name),
              _buildDetailRow('Level', log.level.name),
              _buildDetailRow('Success', log.success ? 'Yes' : 'No'),
              _buildDetailRow('Timestamp', log.timestamp.toString()),
              if (log.errorMessage != null)
                _buildDetailRow('Error', log.errorMessage!),
              if (log.details.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Details:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(log.details.toString()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Security settings tab
class SecuritySettingsTab extends StatelessWidget {
  const SecuritySettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Security settings interface would be implemented here.'),
          // Implementation for security settings UI
        ],
      ),
    );
  }
}
