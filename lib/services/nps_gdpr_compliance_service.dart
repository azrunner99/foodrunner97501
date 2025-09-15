import 'package:flutter/foundation.dart';

/// GDPR consent types
enum ConsentType {
  dataProcessing,
  marketing,
  analytics,
  cookies,
  dataSharing,
  profiling,
}

/// Data retention categories with different retention periods
enum DataCategory {
  personalIdentifiers, // Name, email, phone - 7 years
  feedbackData, // NPS scores, comments - 7 years
  analyticsData, // Usage metrics - 3 years
  auditLogs, // Security logs - 10 years
  sessionData, // Login data - 1 year
  marketingData, // Marketing preferences - 3 years
}

/// GDPR data subject rights
enum DataSubjectRight {
  access, // Right to access personal data
  rectification, // Right to correct inaccurate data
  erasure, // Right to be forgotten
  portability, // Right to data portability
  restriction, // Right to restrict processing
  objection, // Right to object to processing
  notification, // Right to be notified of data breaches
}

/// User consent record
class ConsentRecord {
  final String id;
  final String userId;
  final ConsentType consentType;
  final bool granted;
  final DateTime timestamp;
  final String version; // Privacy policy version
  final String ipAddress;
  final String userAgent;
  final Map<String, dynamic> metadata;

  const ConsentRecord({
    required this.id,
    required this.userId,
    required this.consentType,
    required this.granted,
    required this.timestamp,
    required this.version,
    required this.ipAddress,
    required this.userAgent,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'consentType': consentType.name,
      'granted': granted,
      'timestamp': timestamp.toIso8601String(),
      'version': version,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'metadata': metadata,
    };
  }

  factory ConsentRecord.fromJson(Map<String, dynamic> json) {
    return ConsentRecord(
      id: json['id'],
      userId: json['userId'],
      consentType: ConsentType.values.firstWhere((t) => t.name == json['consentType']),
      granted: json['granted'],
      timestamp: DateTime.parse(json['timestamp']),
      version: json['version'],
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Data retention policy
class RetentionPolicy {
  final DataCategory category;
  final Duration retentionPeriod;
  final String description;
  final bool autoDelete;
  final String legalBasis;

  const RetentionPolicy({
    required this.category,
    required this.retentionPeriod,
    required this.description,
    this.autoDelete = true,
    required this.legalBasis,
  });

  static List<RetentionPolicy> getDefaultPolicies() {
    return [
      const RetentionPolicy(
        category: DataCategory.personalIdentifiers,
        retentionPeriod: Duration(days: 365 * 7), // 7 years
        description: 'Personal identifiers retained for legal compliance',
        legalBasis: 'Legal obligation - employment records',
      ),
      const RetentionPolicy(
        category: DataCategory.feedbackData,
        retentionPeriod: Duration(days: 365 * 7), // 7 years
        description: 'NPS feedback data for business improvement',
        legalBasis: 'Legitimate interest - service improvement',
      ),
      const RetentionPolicy(
        category: DataCategory.analyticsData,
        retentionPeriod: Duration(days: 365 * 3), // 3 years
        description: 'Analytics data for business insights',
        legalBasis: 'Legitimate interest - business analytics',
      ),
      const RetentionPolicy(
        category: DataCategory.auditLogs,
        retentionPeriod: Duration(days: 365 * 10), // 10 years
        description: 'Security audit logs for compliance',
        legalBasis: 'Legal obligation - security compliance',
      ),
      const RetentionPolicy(
        category: DataCategory.sessionData,
        retentionPeriod: Duration(days: 365), // 1 year
        description: 'User session data for security',
        legalBasis: 'Legitimate interest - security monitoring',
      ),
      const RetentionPolicy(
        category: DataCategory.marketingData,
        retentionPeriod: Duration(days: 365 * 3), // 3 years
        description: 'Marketing preferences and communications',
        legalBasis: 'Consent - marketing communications',
      ),
    ];
  }
}

/// Data subject request
class DataSubjectRequest {
  final String id;
  final String userId;
  final String userEmail;
  final DataSubjectRight requestType;
  final String description;
  final DateTime submissionDate;
  final DateTime deadline; // 30 days from submission
  final String status; // pending, processing, completed, rejected
  final String? responseDetails;
  final DateTime? completedDate;
  final List<String> affectedDataCategories;
  final Map<String, dynamic> metadata;

  const DataSubjectRequest({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.requestType,
    required this.description,
    required this.submissionDate,
    required this.deadline,
    required this.status,
    this.responseDetails,
    this.completedDate,
    this.affectedDataCategories = const [],
    this.metadata = const {},
  });

  bool get isOverdue => DateTime.now().isAfter(deadline) && status != 'completed';
  
  Duration get timeRemaining => deadline.difference(DateTime.now());
}

/// Data breach incident
class DataBreachIncident {
  final String id;
  final DateTime discoveryDate;
  final DateTime? notificationDate;
  final String severity; // low, medium, high, critical
  final String description;
  final List<String> affectedDataTypes;
  final int estimatedAffectedUsers;
  final String containmentActions;
  final bool regulatorNotified;
  final bool usersNotified;
  final String status; // investigating, contained, resolved
  final Map<String, dynamic> details;

  const DataBreachIncident({
    required this.id,
    required this.discoveryDate,
    this.notificationDate,
    required this.severity,
    required this.description,
    required this.affectedDataTypes,
    required this.estimatedAffectedUsers,
    required this.containmentActions,
    this.regulatorNotified = false,
    this.usersNotified = false,
    required this.status,
    this.details = const {},
  });

  bool get requiresRegulatorNotification {
    // High risk breaches must be reported within 72 hours
    return severity == 'high' || severity == 'critical';
  }

  bool get requiresUserNotification {
    // Notify users if high risk to rights and freedoms
    return severity == 'critical' || affectedDataTypes.contains('personal_identifiers');
  }
}

/// Privacy impact assessment
class PrivacyImpactAssessment {
  final String id;
  final String title;
  final String description;
  final DateTime assessmentDate;
  final String assessor;
  final List<String> dataTypes;
  final List<String> processingPurposes;
  final String riskLevel; // low, medium, high
  final List<String> identifiedRisks;
  final List<String> mitigationMeasures;
  final DateTime reviewDate;
  final String status; // draft, approved, needs_review

  const PrivacyImpactAssessment({
    required this.id,
    required this.title,
    required this.description,
    required this.assessmentDate,
    required this.assessor,
    required this.dataTypes,
    required this.processingPurposes,
    required this.riskLevel,
    required this.identifiedRisks,
    required this.mitigationMeasures,
    required this.reviewDate,
    required this.status,
  });
}

/// GDPR compliance service
class NPSGDPRComplianceService extends ChangeNotifier {
  final List<ConsentRecord> _consentRecords = [];
  final List<RetentionPolicy> _retentionPolicies = [];
  final List<DataSubjectRequest> _dataSubjectRequests = [];
  final List<DataBreachIncident> _dataBreaches = [];
  final List<PrivacyImpactAssessment> _privacyAssessments = [];
  
  String _currentPrivacyPolicyVersion = '1.0';
  DateTime _lastDataProtectionReview = DateTime.now();

  // Getters
  List<ConsentRecord> get consentRecords => List.unmodifiable(_consentRecords);
  List<RetentionPolicy> get retentionPolicies => List.unmodifiable(_retentionPolicies);
  List<DataSubjectRequest> get dataSubjectRequests => List.unmodifiable(_dataSubjectRequests);
  List<DataBreachIncident> get dataBreaches => List.unmodifiable(_dataBreaches);
  List<PrivacyImpactAssessment> get privacyAssessments => List.unmodifiable(_privacyAssessments);
  String get currentPrivacyPolicyVersion => _currentPrivacyPolicyVersion;

  /// Initialize GDPR compliance service
  void initialize() {
    _retentionPolicies.addAll(RetentionPolicy.getDefaultPolicies());
    _createSampleData();
  }

  /// Create sample compliance data for demo
  void _createSampleData() {
    // Sample consent records
    _consentRecords.addAll([
      ConsentRecord(
        id: 'consent_001',
        userId: 'server_001',
        consentType: ConsentType.dataProcessing,
        granted: true,
        timestamp: DateTime.now().subtract(const Duration(days: 30)),
        version: '1.0',
        ipAddress: '192.168.1.100',
        userAgent: 'Mobile App',
      ),
      ConsentRecord(
        id: 'consent_002',
        userId: 'server_001',
        consentType: ConsentType.analytics,
        granted: true,
        timestamp: DateTime.now().subtract(const Duration(days: 30)),
        version: '1.0',
        ipAddress: '192.168.1.100',
        userAgent: 'Mobile App',
      ),
      ConsentRecord(
        id: 'consent_003',
        userId: 'manager_001',
        consentType: ConsentType.marketing,
        granted: false,
        timestamp: DateTime.now().subtract(const Duration(days: 15)),
        version: '1.0',
        ipAddress: '192.168.1.101',
        userAgent: 'Web Browser',
      ),
    ]);

    // Sample data subject request
    _dataSubjectRequests.add(
      DataSubjectRequest(
        id: 'dsr_001',
        userId: 'server_002',
        userEmail: 'server2@restaurant.com',
        requestType: DataSubjectRight.access,
        description: 'Request for all personal data held by the organization',
        submissionDate: DateTime.now().subtract(const Duration(days: 5)),
        deadline: DateTime.now().add(const Duration(days: 25)),
        status: 'processing',
        affectedDataCategories: ['personalIdentifiers', 'feedbackData'],
      ),
    );
  }

  /// Record user consent
  Future<void> recordConsent({
    required String userId,
    required ConsentType consentType,
    required bool granted,
    required String ipAddress,
    required String userAgent,
    Map<String, dynamic> metadata = const {},
  }) async {
    final consentRecord = ConsentRecord(
      id: 'consent_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      consentType: consentType,
      granted: granted,
      timestamp: DateTime.now(),
      version: _currentPrivacyPolicyVersion,
      ipAddress: ipAddress,
      userAgent: userAgent,
      metadata: metadata,
    );

    _consentRecords.add(consentRecord);
    notifyListeners();
  }

  /// Get user consents
  List<ConsentRecord> getUserConsents(String userId) {
    return _consentRecords.where((record) => record.userId == userId).toList();
  }

  /// Check if user has granted specific consent
  bool hasUserConsent(String userId, ConsentType consentType) {
    final userConsents = getUserConsents(userId);
    final latestConsent = userConsents
        .where((c) => c.consentType == consentType)
        .fold<ConsentRecord?>(null, (latest, current) {
      if (latest == null || current.timestamp.isAfter(latest.timestamp)) {
        return current;
      }
      return latest;
    });

    return latestConsent?.granted ?? false;
  }

  /// Submit data subject request
  Future<String> submitDataSubjectRequest({
    required String userId,
    required String userEmail,
    required DataSubjectRight requestType,
    required String description,
    List<String> affectedDataCategories = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    final requestId = 'dsr_${DateTime.now().millisecondsSinceEpoch}';
    final request = DataSubjectRequest(
      id: requestId,
      userId: userId,
      userEmail: userEmail,
      requestType: requestType,
      description: description,
      submissionDate: DateTime.now(),
      deadline: DateTime.now().add(const Duration(days: 30)), // GDPR 30-day deadline
      status: 'pending',
      affectedDataCategories: affectedDataCategories,
      metadata: metadata,
    );

    _dataSubjectRequests.add(request);
    notifyListeners();

    return requestId;
  }

  /// Process data subject request
  Future<void> processDataSubjectRequest(String requestId, String status, {String? responseDetails}) async {
    final index = _dataSubjectRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final request = _dataSubjectRequests[index];
      final updatedRequest = DataSubjectRequest(
        id: request.id,
        userId: request.userId,
        userEmail: request.userEmail,
        requestType: request.requestType,
        description: request.description,
        submissionDate: request.submissionDate,
        deadline: request.deadline,
        status: status,
        responseDetails: responseDetails,
        completedDate: status == 'completed' ? DateTime.now() : request.completedDate,
        affectedDataCategories: request.affectedDataCategories,
        metadata: request.metadata,
      );

      _dataSubjectRequests[index] = updatedRequest;
      notifyListeners();
    }
  }

  /// Export user data (for data portability requests)
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    // In a real implementation, this would collect data from all systems
    final userData = {
      'user_id': userId,
      'export_date': DateTime.now().toIso8601String(),
      'data_categories': {
        'consent_records': getUserConsents(userId).map((c) => c.toJson()).toList(),
        'nps_feedback': [], // Would fetch from NPS database
        'session_data': [], // Would fetch from session logs
        'profile_data': {}, // Would fetch from user profile
      },
      'metadata': {
        'export_format': 'JSON',
        'privacy_policy_version': _currentPrivacyPolicyVersion,
      },
    };

    return userData;
  }

  /// Delete user data (for erasure requests)
  Future<Map<String, dynamic>> deleteUserData(String userId, {List<String>? specificCategories}) async {
    var deletedItems = <String, int>{};

    // Delete consent records (except those required for legal compliance)
    if (specificCategories == null || specificCategories.contains('consent_records')) {
      final initialCount = _consentRecords.length;
      _consentRecords.removeWhere((record) => 
        record.userId == userId && 
        record.consentType != ConsentType.dataProcessing // Keep processing consent for legal basis
      );
      deletedItems['consent_records'] = initialCount - _consentRecords.length;
    }

    // In a real implementation, would delete from all relevant databases
    if (specificCategories == null || specificCategories.contains('feedback_data')) {
      deletedItems['feedback_data'] = 0; // Would delete NPS feedback
    }

    if (specificCategories == null || specificCategories.contains('session_data')) {
      deletedItems['session_data'] = 0; // Would delete session logs
    }

    notifyListeners();

    return {
      'user_id': userId,
      'deletion_date': DateTime.now().toIso8601String(),
      'deleted_items': deletedItems,
      'retained_items': {
        'audit_logs': 'Retained for legal compliance',
        'processing_consent': 'Retained as legal basis for previous processing',
      },
    };
  }

  /// Report data breach
  Future<void> reportDataBreach({
    required String description,
    required String severity,
    required List<String> affectedDataTypes,
    required int estimatedAffectedUsers,
    required String containmentActions,
    Map<String, dynamic> details = const {},
  }) async {
    final breach = DataBreachIncident(
      id: 'breach_${DateTime.now().millisecondsSinceEpoch}',
      discoveryDate: DateTime.now(),
      severity: severity,
      description: description,
      affectedDataTypes: affectedDataTypes,
      estimatedAffectedUsers: estimatedAffectedUsers,
      containmentActions: containmentActions,
      status: 'investigating',
      details: details,
    );

    _dataBreaches.add(breach);
    
    // Auto-schedule notifications if required
    if (breach.requiresRegulatorNotification) {
      // In production, would trigger automatic regulator notification
      if (kDebugMode) {
        print('🚨 GDPR: High-risk data breach detected - regulator notification required within 72 hours');
      }
    }

    if (breach.requiresUserNotification) {
      // In production, would trigger user notifications
      if (kDebugMode) {
        print('📧 GDPR: User notification required for data breach');
      }
    }

    notifyListeners();
  }

  /// Perform data retention cleanup
  Future<Map<String, int>> performRetentionCleanup() async {
    final cleanupResults = <String, int>{};
    final now = DateTime.now();

    for (final policy in _retentionPolicies) {
      final cutoffDate = now.subtract(policy.retentionPeriod);
      var deletedCount = 0;

      switch (policy.category) {
        case DataCategory.personalIdentifiers:
          // In production, would clean up expired personal data
          break;
        case DataCategory.feedbackData:
          // In production, would clean up old feedback data
          break;
        case DataCategory.analyticsData:
          // In production, would clean up old analytics data
          break;
        case DataCategory.auditLogs:
          // In production, would clean up old audit logs
          break;
        case DataCategory.sessionData:
          // Clean up old consent records as example
          final initialCount = _consentRecords.length;
          if (policy.category == DataCategory.sessionData) {
            _consentRecords.removeWhere((record) => 
              record.timestamp.isBefore(cutoffDate)
            );
            deletedCount = initialCount - _consentRecords.length;
          }
          break;
        case DataCategory.marketingData:
          // In production, would clean up old marketing data
          break;
      }

      cleanupResults[policy.category.name] = deletedCount;
    }

    if (cleanupResults.values.any((count) => count > 0)) {
      notifyListeners();
    }

    return cleanupResults;
  }

  /// Get GDPR compliance statistics
  Map<String, dynamic> getComplianceStatistics() {
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));

    // Consent statistics
    final consentStats = <String, int>{};
    for (final consentType in ConsentType.values) {
      consentStats[consentType.name] = _consentRecords
          .where((r) => r.consentType == consentType && r.granted)
          .length;
    }

    // Data subject request statistics
    final pendingRequests = _dataSubjectRequests.where((r) => r.status == 'pending').length;
    final overdueRequests = _dataSubjectRequests.where((r) => r.isOverdue).length;
    final completedRequests = _dataSubjectRequests.where((r) => r.status == 'completed').length;

    // Data breach statistics
    final recentBreaches = _dataBreaches.where((b) => b.discoveryDate.isAfter(last30Days)).length;
    final highRiskBreaches = _dataBreaches.where((b) => b.severity == 'high' || b.severity == 'critical').length;

    return {
      'consent_statistics': consentStats,
      'data_subject_requests': {
        'total': _dataSubjectRequests.length,
        'pending': pendingRequests,
        'overdue': overdueRequests,
        'completed': completedRequests,
        'completion_rate': _dataSubjectRequests.isNotEmpty 
            ? (completedRequests / _dataSubjectRequests.length * 100).round()
            : 0,
      },
      'data_breaches': {
        'total': _dataBreaches.length,
        'recent_30_days': recentBreaches,
        'high_risk': highRiskBreaches,
      },
      'privacy_policy': {
        'current_version': _currentPrivacyPolicyVersion,
        'last_review_date': _lastDataProtectionReview.toIso8601String(),
      },
      'retention_policies': _retentionPolicies.length,
      'privacy_assessments': _privacyAssessments.length,
    };
  }

  /// Generate GDPR compliance report
  Future<Map<String, dynamic>> generateComplianceReport() async {
    final stats = getComplianceStatistics();
    final now = DateTime.now();

    return {
      'report_date': now.toIso8601String(),
      'report_type': 'GDPR Compliance Report',
      'organization': 'Restaurant NPS System',
      'reporting_period': {
        'start': now.subtract(const Duration(days: 30)).toIso8601String(),
        'end': now.toIso8601String(),
      },
      'compliance_statistics': stats,
      'recommendations': _generateComplianceRecommendations(stats),
      'action_items': _generateActionItems(),
      'next_review_date': now.add(const Duration(days: 90)).toIso8601String(),
    };
  }

  /// Generate compliance recommendations based on current state
  List<String> _generateComplianceRecommendations(Map<String, dynamic> stats) {
    final recommendations = <String>[];

    // Check for overdue data subject requests
    if (stats['data_subject_requests']['overdue'] > 0) {
      recommendations.add('Address ${stats['data_subject_requests']['overdue']} overdue data subject requests immediately');
    }

    // Check consent rates
    final consentStats = stats['consent_statistics'] as Map<String, int>;
    final totalUsers = 5; // Demo value
    if (consentStats['dataProcessing']! < totalUsers) {
      recommendations.add('Ensure all users have provided data processing consent');
    }

    // Check for recent high-risk breaches
    if (stats['data_breaches']['high_risk'] > 0) {
      recommendations.add('Review security measures following high-risk data breaches');
    }

    // General recommendations
    recommendations.addAll([
      'Conduct regular privacy impact assessments for new features',
      'Review and update privacy policy annually',
      'Provide GDPR training for all staff handling personal data',
      'Implement automated data retention cleanup',
      'Regular audit of third-party data processors',
    ]);

    return recommendations;
  }

  /// Generate action items for compliance improvement
  List<Map<String, dynamic>> _generateActionItems() {
    return [
      {
        'title': 'Review Data Retention Policies',
        'description': 'Audit current retention periods and update as needed',
        'priority': 'medium',
        'due_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      },
      {
        'title': 'Update Privacy Notice',
        'description': 'Review and update privacy notice for clarity and completeness',
        'priority': 'low',
        'due_date': DateTime.now().add(const Duration(days: 60)).toIso8601String(),
      },
      {
        'title': 'Conduct Privacy Impact Assessment',
        'description': 'Assess privacy risks for new analytics features',
        'priority': 'high',
        'due_date': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
      },
    ];
  }

  /// Update privacy policy version
  void updatePrivacyPolicyVersion(String newVersion) {
    _currentPrivacyPolicyVersion = newVersion;
    _lastDataProtectionReview = DateTime.now();
    notifyListeners();
  }

  /// Check compliance status
  Map<String, dynamic> checkComplianceStatus() {
    final issues = <String>[];
    final warnings = <String>[];

    // Check for overdue requests
    final overdueRequests = _dataSubjectRequests.where((r) => r.isOverdue).length;
    if (overdueRequests > 0) {
      issues.add('$overdueRequests overdue data subject requests');
    }

    // Check for unreported breaches
    final unreportedBreaches = _dataBreaches.where((b) => 
      b.requiresRegulatorNotification && !b.regulatorNotified
    ).length;
    if (unreportedBreaches > 0) {
      issues.add('$unreportedBreaches high-risk breaches require regulator notification');
    }

    // Check privacy policy age
    final daysSinceReview = DateTime.now().difference(_lastDataProtectionReview).inDays;
    if (daysSinceReview > 365) {
      warnings.add('Privacy policy not reviewed for over a year');
    }

    return {
      'status': issues.isEmpty ? 'compliant' : 'issues_detected',
      'issues': issues,
      'warnings': warnings,
      'last_check': DateTime.now().toIso8601String(),
    };
  }
}