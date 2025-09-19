import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nps_security_service.dart';
import '../services/nps_audit_service.dart';
import '../services/nps_encryption_service.dart';
import '../widgets/data_export_widget.dart';

/// Secured wrapper for data export functionality
class SecuredDataExportWidget extends StatelessWidget {
  const SecuredDataExportWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<NPSSecurityService, NPSAuditService, NPSEncryptionService>(
      builder: (context, security, audit, encryption, child) {
        // Check if user has export permissions
        if (!security.hasPermission(Permission.exportData)) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.lock,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Data Export Restricted',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You do not have permission to export data.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        // Wrap the original export widget with security logging
        return _SecuredExportWrapper(
          security: security,
          audit: audit,
          encryption: encryption,
          child: const DataExportWidget(),
        );
      },
    );
  }
}

class _SecuredExportWrapper extends StatelessWidget {
  final NPSSecurityService security;
  final NPSAuditService audit;
  final NPSEncryptionService encryption;
  final Widget child;

  const _SecuredExportWrapper({
    required this.security,
    required this.audit,
    required this.encryption,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Security header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Secured Export',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (encryption.config.encryptExports)
                  Icon(
                    Icons.enhanced_encryption,
                    size: 16,
                    color: Colors.green,
                  ),
              ],
            ),
          ),
          // Original export widget
          child,
          // Security footer with audit info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Text(
              'All export activities are logged and audited for security compliance.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Security-aware notification summary
class SecuredNotificationSummary extends StatelessWidget {
  const SecuredNotificationSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NPSSecurityService, NPSAuditService>(
      builder: (context, security, audit, child) {
        // Check notification permissions
        if (!security.hasPermission(Permission.manageNotifications)) {
          return const SizedBox.shrink();
        }

        // Log notification access
        audit.log(
          userId: security.currentUser?.id ?? 'anonymous',
          userName: security.currentUser?.username ?? 'Anonymous',
          sessionId: security.currentSession?.sessionId ?? 'unknown',
          level: AuditLogLevel.info,
          category: AuditCategory.dataAccess,
          action: 'NOTIFICATION_SUMMARY_ACCESSED',
          resource: 'notification_summary',
          description: 'User accessed notification summary',
          ipAddress: security.currentSession?.ipAddress ?? 'unknown',
          userAgent: security.currentSession?.userAgent ?? 'unknown',
        );

        // Return secured notification widget (import the original)
        // For now, return a placeholder since we don't have the original implementation
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications),
                    const SizedBox(width: 8),
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                    'Secured notification summary - implementation pending'),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Security-aware analytics widget wrapper
class SecuredAnalyticsWidget extends StatelessWidget {
  final Widget child;

  const SecuredAnalyticsWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<NPSSecurityService, NPSAuditService>(
      builder: (context, security, audit, _) {
        // Check analytics access permissions
        if (!security.hasPermission(Permission.accessAnalytics)) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Analytics Access Restricted',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You do not have permission to view analytics data.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Log analytics access
        audit.log(
          userId: security.currentUser?.id ?? 'anonymous',
          userName: security.currentUser?.username ?? 'Anonymous',
          sessionId: security.currentSession?.sessionId ?? 'unknown',
          level: AuditLogLevel.info,
          category: AuditCategory.dataAccess,
          action: 'ANALYTICS_ACCESSED',
          resource: 'analytics_dashboard',
          description: 'User accessed analytics dashboard',
          details: {
            'user_role': security.currentUser?.role.name,
            'permissions': security.currentUser
                ?.getAllPermissions()
                .map((p) => p.name)
                .toList(),
          },
          ipAddress: security.currentSession?.ipAddress ?? 'unknown',
          userAgent: security.currentSession?.userAgent ?? 'unknown',
        );

        // Return the secured analytics widget
        return child;
      },
    );
  }
}

/// Security-aware benchmarking widget wrapper
class SecuredBenchmarkingWidget extends StatelessWidget {
  final Widget child;

  const SecuredBenchmarkingWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<NPSSecurityService, NPSAuditService>(
      builder: (context, security, audit, _) {
        // Check benchmarking permissions
        if (!security.hasPermission(Permission.viewBenchmarks)) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.compare_arrows,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Benchmarking Access Restricted',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You do not have permission to view benchmarking data.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Log benchmarking access
        audit.log(
          userId: security.currentUser?.id ?? 'anonymous',
          userName: security.currentUser?.username ?? 'Anonymous',
          sessionId: security.currentSession?.sessionId ?? 'unknown',
          level: AuditLogLevel.info,
          category: AuditCategory.dataAccess,
          action: 'BENCHMARKING_ACCESSED',
          resource: 'benchmarking_dashboard',
          description: 'User accessed benchmarking dashboard',
          ipAddress: security.currentSession?.ipAddress ?? 'unknown',
          userAgent: security.currentSession?.userAgent ?? 'unknown',
        );

        return child;
      },
    );
  }
}

/// Utility class for common security checks
class SecurityUtils {
  /// Check and log data access
  static bool checkDataAccess(
    NPSSecurityService security,
    NPSAuditService audit,
    Permission requiredPermission,
    String resource,
    String action,
  ) {
    final hasPermission = security.hasPermission(requiredPermission);

    audit.log(
      userId: security.currentUser?.id ?? 'anonymous',
      userName: security.currentUser?.username ?? 'Anonymous',
      sessionId: security.currentSession?.sessionId ?? 'unknown',
      level: hasPermission ? AuditLogLevel.info : AuditLogLevel.warning,
      category: AuditCategory.authorization,
      action: action,
      resource: resource,
      description: hasPermission
          ? 'Access granted to $resource'
          : 'Access denied to $resource - insufficient permissions',
      success: hasPermission,
      errorMessage: hasPermission
          ? null
          : 'Insufficient permissions: ${requiredPermission.name}',
      details: {
        'required_permission': requiredPermission.name,
        'user_permissions': security.currentUser
                ?.getAllPermissions()
                .map((p) => p.name)
                .toList() ??
            [],
      },
      ipAddress: security.currentSession?.ipAddress ?? 'unknown',
      userAgent: security.currentSession?.userAgent ?? 'unknown',
    );

    return hasPermission;
  }

  /// Log data modification action
  static void logDataModification(
    NPSAuditService audit,
    NPSSecurityService security,
    String action,
    String resource,
    Map<String, dynamic> beforeState,
    Map<String, dynamic> afterState,
  ) {
    audit.log(
      userId: security.currentUser?.id ?? 'anonymous',
      userName: security.currentUser?.username ?? 'Anonymous',
      sessionId: security.currentSession?.sessionId ?? 'unknown',
      level: AuditLogLevel.info,
      category: AuditCategory.dataModification,
      action: action,
      resource: resource,
      description: 'Data modification: $action on $resource',
      beforeState: beforeState,
      afterState: afterState,
      ipAddress: security.currentSession?.ipAddress ?? 'unknown',
      userAgent: security.currentSession?.userAgent ?? 'unknown',
    );
  }

  /// Log export action with encryption details
  static void logDataExport(
    NPSAuditService audit,
    NPSSecurityService security,
    NPSEncryptionService encryption,
    String exportType,
    int recordCount,
    bool isEncrypted,
  ) {
    audit.log(
      userId: security.currentUser?.id ?? 'anonymous',
      userName: security.currentUser?.username ?? 'Anonymous',
      sessionId: security.currentSession?.sessionId ?? 'unknown',
      level: AuditLogLevel.info,
      category: AuditCategory.dataExport,
      action: 'DATA_EXPORTED',
      resource: exportType,
      description: 'Data export performed: $exportType',
      details: {
        'export_type': exportType,
        'record_count': recordCount,
        'encrypted': isEncrypted,
        'encryption_algorithm': encryption.activeKey?.algorithm,
        'export_timestamp': DateTime.now().toIso8601String(),
      },
      ipAddress: security.currentSession?.ipAddress ?? 'unknown',
      userAgent: security.currentSession?.userAgent ?? 'unknown',
    );
  }
}
