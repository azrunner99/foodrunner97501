import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';

/// User roles and permissions for NPS system security
enum UserRole {
  superAdmin,
  admin,
  manager,
  teamLead,
  server,
  viewer,
}

enum Permission {
  // Data Access
  viewAllNPSData,
  viewOwnNPSData,
  viewTeamNPSData,
  viewReports,
  
  // Data Modification
  createFeedback,
  editFeedback,
  deleteFeedback,
  bulkOperations,
  
  // Analytics & Reporting
  accessAnalytics,
  exportData,
  viewBenchmarks,
  manageBenchmarks,
  
  // System Administration
  manageUsers,
  configureSystem,
  viewAuditLogs,
  manageBackups,
  
  // Notifications
  manageNotifications,
  sendNotifications,
  
  // Security
  manageRoles,
  configureSecurity,
  encryptData,
  
  // Compliance
  manageRetention,
  exportForCompliance,
  deletePersonalData,
}

/// User profile with role and permissions
class UserProfile {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final UserRole role;
  final List<Permission> customPermissions;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isActive;
  final bool requiresPasswordChange;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    required this.role,
    this.customPermissions = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.lastLoginAt,
    this.isActive = true,
    this.requiresPasswordChange = false,
  });

  bool hasPermission(Permission permission) {
    return _getRolePermissions(role).contains(permission) || 
           customPermissions.contains(permission);
  }

  bool hasAnyPermission(List<Permission> permissions) {
    return permissions.any((p) => hasPermission(p));
  }

  List<Permission> getAllPermissions() {
    final rolePermissions = _getRolePermissions(role);
    final allPermissions = <Permission>{...rolePermissions, ...customPermissions};
    return allPermissions.toList();
  }

  static List<Permission> _getRolePermissions(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Permission.values; // All permissions
      
      case UserRole.admin:
        return [
          Permission.viewAllNPSData,
          Permission.viewReports,
          Permission.createFeedback,
          Permission.editFeedback,
          Permission.deleteFeedback,
          Permission.bulkOperations,
          Permission.accessAnalytics,
          Permission.exportData,
          Permission.viewBenchmarks,
          Permission.manageBenchmarks,
          Permission.manageUsers,
          Permission.viewAuditLogs,
          Permission.manageNotifications,
          Permission.sendNotifications,
          Permission.manageRetention,
          Permission.exportForCompliance,
        ];
      
      case UserRole.manager:
        return [
          Permission.viewTeamNPSData,
          Permission.viewAllNPSData,
          Permission.viewReports,
          Permission.createFeedback,
          Permission.editFeedback,
          Permission.accessAnalytics,
          Permission.exportData,
          Permission.viewBenchmarks,
          Permission.manageNotifications,
          Permission.sendNotifications,
        ];
      
      case UserRole.teamLead:
        return [
          Permission.viewTeamNPSData,
          Permission.viewReports,
          Permission.createFeedback,
          Permission.editFeedback,
          Permission.accessAnalytics,
          Permission.viewBenchmarks,
          Permission.sendNotifications,
        ];
      
      case UserRole.server:
        return [
          Permission.viewOwnNPSData,
          Permission.createFeedback,
          Permission.viewReports,
        ];
      
      case UserRole.viewer:
        return [
          Permission.viewReports,
        ];
    }
  }
}

/// Security session management
class SecuritySession {
  final String sessionId;
  final String userId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String ipAddress;
  final String userAgent;
  final Map<String, dynamic> metadata;
  final bool isActive;

  const SecuritySession({
    required this.sessionId,
    required this.userId,
    required this.createdAt,
    required this.expiresAt,
    required this.ipAddress,
    required this.userAgent,
    this.metadata = const {},
    this.isActive = true,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => isActive && !isExpired;
}

/// Security audit log entry
class SecurityAuditLog {
  final String id;
  final String userId;
  final String userName;
  final String action;
  final String resource;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  final String ipAddress;
  final String userAgent;
  final bool success;
  final String? errorMessage;

  const SecurityAuditLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.resource,
    required this.details,
    required this.timestamp,
    required this.ipAddress,
    required this.userAgent,
    required this.success,
    this.errorMessage,
  });
}

/// Security policy configuration
class SecurityPolicy {
  final Duration sessionTimeout;
  final int maxLoginAttempts;
  final Duration lockoutDuration;
  final bool requireMFA;
  final int passwordMinLength;
  final bool requireSpecialChars;
  final bool requireNumbers;
  final bool requireUppercase;
  final Duration passwordExpiry;
  final int passwordHistoryCount;
  final bool auditAllActions;
  final bool encryptSensitiveData;
  final Duration dataRetentionPeriod;

  const SecurityPolicy({
    this.sessionTimeout = const Duration(hours: 8),
    this.maxLoginAttempts = 3,
    this.lockoutDuration = const Duration(minutes: 30),
    this.requireMFA = false,
    this.passwordMinLength = 8,
    this.requireSpecialChars = true,
    this.requireNumbers = true,
    this.requireUppercase = true,
    this.passwordExpiry = const Duration(days: 90),
    this.passwordHistoryCount = 5,
    this.auditAllActions = true,
    this.encryptSensitiveData = true,
    this.dataRetentionPeriod = const Duration(days: 365 * 7), // 7 years
  });
}

/// Main security service for NPS system
class NPSSecurityService extends ChangeNotifier {
  UserProfile? _currentUser;
  SecuritySession? _currentSession;
  final List<SecurityAuditLog> _auditLogs = [];
  final Map<String, UserProfile> _users = {};
  final Map<String, SecuritySession> _sessions = {};
  SecurityPolicy _securityPolicy = const SecurityPolicy();
  final Map<String, int> _loginAttempts = {};
  final Map<String, DateTime> _lockedAccounts = {};

  // Getters
  UserProfile? get currentUser => _currentUser;
  SecuritySession? get currentSession => _currentSession;
  List<SecurityAuditLog> get auditLogs => List.unmodifiable(_auditLogs);
  SecurityPolicy get securityPolicy => _securityPolicy;
  bool get isLoggedIn => _currentUser != null && _currentSession?.isValid == true;

  /// Initialize security service with demo users
  void initialize() {
    _createDemoUsers();
    _log('SYSTEM', 'system', 'Security service initialized', 'system', {});
  }

  /// Create demo users for testing
  void _createDemoUsers() {
    final demoUsers = [
      UserProfile(
        id: 'super_admin_001',
        username: 'superadmin',
        email: 'superadmin@restaurant.com',
        displayName: 'Super Administrator',
        role: UserRole.superAdmin,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      UserProfile(
        id: 'admin_001',
        username: 'admin',
        email: 'admin@restaurant.com',
        displayName: 'System Administrator',
        role: UserRole.admin,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      UserProfile(
        id: 'manager_001',
        username: 'manager',
        email: 'manager@restaurant.com',
        displayName: 'Restaurant Manager',
        role: UserRole.manager,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      UserProfile(
        id: 'server_001',
        username: 'server1',
        email: 'server1@restaurant.com',
        displayName: 'Server #1',
        role: UserRole.server,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      UserProfile(
        id: 'viewer_001',
        username: 'viewer',
        email: 'viewer@restaurant.com',
        displayName: 'View Only User',
        role: UserRole.viewer,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        lastLoginAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    for (final user in demoUsers) {
      _users[user.id] = user;
    }
  }

  /// Authenticate user (simplified for demo)
  Future<bool> authenticateUser(String username, String password) async {
    try {
      // Check for locked accounts
      if (_isAccountLocked(username)) {
        _log(username, 'unknown', 'Authentication failed - account locked', 'auth', {
          'reason': 'account_locked',
        });
        return false;
      }

      // Find user by username
      final user = _users.values.firstWhere(
        (u) => u.username == username,
        orElse: () => throw Exception('User not found'),
      );

      // Simple password check (in real app, use proper hashing)
      final validPasswords = {
        'superadmin': 'super123',
        'admin': 'admin123',
        'manager': 'manager123',
        'server1': 'server123',
        'viewer': 'viewer123',
      };

      if (validPasswords[username] != password) {
        _incrementLoginAttempts(username);
        _log(username, user.id, 'Authentication failed - invalid password', 'auth', {
          'reason': 'invalid_password',
        });
        return false;
      }

      // Reset login attempts on successful login
      _loginAttempts.remove(username);
      _lockedAccounts.remove(username);

      // Create session
      await _createSession(user);

      _log(username, user.id, 'User authenticated successfully', 'auth', {
        'role': user.role.name,
      });

      notifyListeners();
      return true;
    } catch (e) {
      _incrementLoginAttempts(username);
      _log(username, 'unknown', 'Authentication failed - ${e.toString()}', 'auth', {
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Create security session
  Future<void> _createSession(UserProfile user) async {
    final sessionId = _generateSessionId();
    final session = SecuritySession(
      sessionId: sessionId,
      userId: user.id,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(_securityPolicy.sessionTimeout),
      ipAddress: '127.0.0.1', // Demo IP
      userAgent: 'Flutter App',
    );

    _currentUser = user;
    _currentSession = session;
    _sessions[sessionId] = session;
  }

  /// Generate secure session ID
  String _generateSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Check if account is locked
  bool _isAccountLocked(String username) {
    final lockTime = _lockedAccounts[username];
    if (lockTime == null) return false;

    if (DateTime.now().isBefore(lockTime.add(_securityPolicy.lockoutDuration))) {
      return true;
    } else {
      _lockedAccounts.remove(username);
      return false;
    }
  }

  /// Increment login attempts and lock if needed
  void _incrementLoginAttempts(String username) {
    _loginAttempts[username] = (_loginAttempts[username] ?? 0) + 1;
    
    if (_loginAttempts[username]! >= _securityPolicy.maxLoginAttempts) {
      _lockedAccounts[username] = DateTime.now();
      _log(username, 'unknown', 'Account locked due to excessive login attempts', 'security', {
        'attempts': _loginAttempts[username],
      });
    }
  }

  /// Logout user
  void logout() {
    if (_currentUser != null) {
      _log(_currentUser!.username, _currentUser!.id, 'User logged out', 'auth', {});
    }

    _currentUser = null;
    _currentSession = null;
    notifyListeners();
  }

  /// Check permission for current user
  bool hasPermission(Permission permission) {
    return _currentUser?.hasPermission(permission) ?? false;
  }

  /// Check multiple permissions
  bool hasAnyPermission(List<Permission> permissions) {
    return _currentUser?.hasAnyPermission(permissions) ?? false;
  }

  /// Require permission and throw if not available
  void requirePermission(Permission permission) {
    if (!hasPermission(permission)) {
      final action = 'Access denied - missing permission: ${permission.name}';
      _log(
        _currentUser?.username ?? 'anonymous',
        _currentUser?.id ?? 'unknown',
        action,
        'security',
        {'required_permission': permission.name},
      );
      throw SecurityException('Access denied: ${permission.name}');
    }
  }

  /// Update security policy
  void updateSecurityPolicy(SecurityPolicy policy) {
    _securityPolicy = policy;
    _log(
      _currentUser?.username ?? 'system',
      _currentUser?.id ?? 'system',
      'Security policy updated',
      'admin',
      {'policy': 'updated'},
    );
    notifyListeners();
  }

  /// Get all users (admin only)
  List<UserProfile> getAllUsers() {
    requirePermission(Permission.manageUsers);
    return _users.values.toList();
  }

  /// Create new user (admin only)
  Future<void> createUser(UserProfile user) async {
    requirePermission(Permission.manageUsers);
    
    _users[user.id] = user;
    _log(
      _currentUser?.username ?? 'system',
      _currentUser?.id ?? 'system',
      'User created',
      'user_management',
      {
        'new_user_id': user.id,
        'new_user_role': user.role.name,
      },
    );
    notifyListeners();
  }

  /// Update user (admin only)
  Future<void> updateUser(UserProfile user) async {
    requirePermission(Permission.manageUsers);
    
    _users[user.id] = user;
    _log(
      _currentUser?.username ?? 'system',
      _currentUser?.id ?? 'system',
      'User updated',
      'user_management',
      {
        'updated_user_id': user.id,
        'updated_user_role': user.role.name,
      },
    );
    notifyListeners();
  }

  /// Delete user (admin only)
  Future<void> deleteUser(String userId) async {
    requirePermission(Permission.manageUsers);
    
    final user = _users.remove(userId);
    if (user != null) {
      _log(
        _currentUser?.username ?? 'system',
        _currentUser?.id ?? 'system',
        'User deleted',
        'user_management',
        {
          'deleted_user_id': userId,
          'deleted_user_role': user.role.name,
        },
      );
      notifyListeners();
    }
  }

  /// Log security action
  void _log(String username, String userId, String action, String resource, Map<String, dynamic> details) {
    final logEntry = SecurityAuditLog(
      id: _generateLogId(),
      userId: userId,
      userName: username,
      action: action,
      resource: resource,
      details: details,
      timestamp: DateTime.now(),
      ipAddress: _currentSession?.ipAddress ?? '127.0.0.1',
      userAgent: _currentSession?.userAgent ?? 'Unknown',
      success: true,
    );

    _auditLogs.add(logEntry);
    
    // Keep only recent logs (in production, persist to database)
    if (_auditLogs.length > 10000) {
      _auditLogs.removeRange(0, _auditLogs.length - 10000);
    }
  }

  /// Generate log ID
  String _generateLogId() {
    return 'log_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// Get audit logs (admin only)
  List<SecurityAuditLog> getAuditLogs({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? action,
    String? resource,
  }) {
    requirePermission(Permission.viewAuditLogs);
    
    var logs = _auditLogs.toList();
    
    if (startDate != null) {
      logs = logs.where((log) => log.timestamp.isAfter(startDate)).toList();
    }
    
    if (endDate != null) {
      logs = logs.where((log) => log.timestamp.isBefore(endDate)).toList();
    }
    
    if (userId != null) {
      logs = logs.where((log) => log.userId == userId).toList();
    }
    
    if (action != null) {
      logs = logs.where((log) => log.action.toLowerCase().contains(action.toLowerCase())).toList();
    }
    
    if (resource != null) {
      logs = logs.where((log) => log.resource.toLowerCase().contains(resource.toLowerCase())).toList();
    }
    
    return logs.reversed.toList(); // Most recent first
  }

  /// Audit action - use this for all sensitive operations
  void auditAction(String action, String resource, Map<String, dynamic> details) {
    if (_securityPolicy.auditAllActions) {
      _log(
        _currentUser?.username ?? 'anonymous',
        _currentUser?.id ?? 'unknown',
        action,
        resource,
        details,
      );
    }
  }

  /// Check if session is valid and refresh if needed
  bool validateSession() {
    if (_currentSession?.isValid != true) {
      logout();
      return false;
    }
    return true;
  }

  /// Get security statistics
  Map<String, dynamic> getSecurityStatistics() {
    requirePermission(Permission.viewAuditLogs);
    
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final last7Days = now.subtract(const Duration(days: 7));
    
    final logsLast24h = _auditLogs.where((log) => log.timestamp.isAfter(last24Hours)).length;
    final logsLast7d = _auditLogs.where((log) => log.timestamp.isAfter(last7Days)).length;
    final failedLogins = _auditLogs.where((log) => 
      log.action.contains('Authentication failed') && 
      log.timestamp.isAfter(last24Hours)
    ).length;
    
    return {
      'total_users': _users.length,
      'active_sessions': _sessions.values.where((s) => s.isValid).length,
      'audit_logs_24h': logsLast24h,
      'audit_logs_7d': logsLast7d,
      'failed_logins_24h': failedLogins,
      'locked_accounts': _lockedAccounts.length,
      'security_policy': {
        'session_timeout_hours': _securityPolicy.sessionTimeout.inHours,
        'max_login_attempts': _securityPolicy.maxLoginAttempts,
        'mfa_required': _securityPolicy.requireMFA,
        'audit_enabled': _securityPolicy.auditAllActions,
      },
    };
  }
}

/// Security exception for access denied scenarios
class SecurityException implements Exception {
  final String message;
  const SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}