import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../widgets/wallpaper_background.dart';

/// Compliance and documentation management for server integrity system
class IntegrityComplianceScreen extends StatefulWidget {
  const IntegrityComplianceScreen({super.key});

  @override
  State<IntegrityComplianceScreen> createState() => _IntegrityComplianceScreenState();
}

class _IntegrityComplianceScreenState extends State<IntegrityComplianceScreen> {
  String _selectedTab = 'policies';
  List<ComplianceDocument> _documents = [];
  List<AuditRecord> _auditRecords = [];

  @override
  void initState() {
    super.initState();
    _loadComplianceData();
  }

  void _loadComplianceData() {
    // Load sample compliance documents
    _documents = [
      ComplianceDocument(
        id: 'DOC-001',
        title: 'Server Integrity Monitoring Policy',
        type: DocumentType.policy,
        status: DocumentStatus.active,
        version: '2.1',
        lastUpdated: DateTime.now().subtract(const Duration(days: 30)),
        description: 'Comprehensive policy for server monitoring and integrity assessment',
        content: _getServerIntegrityPolicy(),
      ),
      ComplianceDocument(
        id: 'DOC-002',
        title: 'Data Privacy Protection Procedures',
        type: DocumentType.procedure,
        status: DocumentStatus.active,
        version: '1.5',
        lastUpdated: DateTime.now().subtract(const Duration(days: 15)),
        description: 'Procedures for protecting server data and maintaining privacy compliance',
        content: _getDataPrivacyProcedures(),
      ),
      ComplianceDocument(
        id: 'DOC-003',
        title: 'Alert Response Guidelines',
        type: DocumentType.guideline,
        status: DocumentStatus.active,
        version: '1.0',
        lastUpdated: DateTime.now().subtract(const Duration(days: 7)),
        description: 'Guidelines for responding to integrity alerts and escalation procedures',
        content: _getAlertResponseGuidelines(),
      ),
      ComplianceDocument(
        id: 'DOC-004',
        title: 'Investigation Standards',
        type: DocumentType.standard,
        status: DocumentStatus.draft,
        version: '0.8',
        lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
        description: 'Standards for conducting server integrity investigations',
        content: _getInvestigationStandards(),
      ),
    ];

    // Load sample audit records
    _auditRecords = [
      AuditRecord(
        id: 'AUD-001',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        action: 'Server Alert Generated',
        userId: 'system',
        serverId: '4f55jaewuhldbaoi',
        details: 'High risk level detected - mechanical pattern score 0.85',
        category: AuditCategory.alert,
      ),
      AuditRecord(
        id: 'AUD-002',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        action: 'Investigation Created',
        userId: 'manager_a',
        serverId: '4f55jaewuhldbaoi',
        details: 'New investigation case INV-001 created for click pattern anomaly',
        category: AuditCategory.investigation,
      ),
      AuditRecord(
        id: 'AUD-003',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        action: 'Policy Review',
        userId: 'admin',
        serverId: null,
        details: 'Server Integrity Monitoring Policy v2.1 reviewed and approved',
        category: AuditCategory.policy,
      ),
      AuditRecord(
        id: 'AUD-004',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        action: 'Data Export',
        userId: 'analyst_b',
        serverId: '7a2b8c3d',
        details: 'Server data exported for external audit compliance',
        category: AuditCategory.export,
      ),
    ];

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        return Scaffold(
          body: WallpaperBackground(
            child: Column(
              children: [
                // Compliance Header
                _buildComplianceHeader(),
                
                // Tab Navigation
                _buildTabNavigation(),
                
                // Main Content
                Expanded(
                  child: _buildTabContent(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComplianceHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green[900]!.withOpacity(0.9),
            Colors.green[700]!.withOpacity(0.9),
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Compliance & Documentation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Privacy Policies • Audit Trails • Documentation Management',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                tooltip: 'Export Compliance Report',
                onPressed: () => _exportComplianceReport(),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                tooltip: 'Compliance Settings',
                onPressed: () => _showComplianceSettings(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabButton('policies', 'Policies & Procedures', Icons.policy),
          _buildTabButton('audit', 'Audit Trail', Icons.history),
          _buildTabButton('privacy', 'Privacy Controls', Icons.privacy_tip),
          _buildTabButton('reports', 'Compliance Reports', Icons.assessment),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabId, String label, IconData icon) {
    final isSelected = _selectedTab == tabId;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = tabId;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.green : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.green : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.green : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'policies':
        return _buildPoliciesTab();
      case 'audit':
        return _buildAuditTab();
      case 'privacy':
        return _buildPrivacyTab();
      case 'reports':
        return _buildReportsTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPoliciesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Policies Overview
          _buildPoliciesOverviewCard(),
          
          const SizedBox(height: 16),
          
          // Document Library
          _buildDocumentLibraryCard(),
        ],
      ),
    );
  }

  Widget _buildPoliciesOverviewCard() {
    final activeCount = _documents.where((d) => d.status == DocumentStatus.active).length;
    final draftCount = _documents.where((d) => d.status == DocumentStatus.draft).length;
    final pendingCount = _documents.where((d) => d.status == DocumentStatus.pending).length;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.folder_open, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Document Library Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDocumentStat('Active', activeCount, Colors.green),
                ),
                Expanded(
                  child: _buildDocumentStat('Draft', draftCount, Colors.orange),
                ),
                Expanded(
                  child: _buildDocumentStat('Pending', pendingCount, Colors.blue),
                ),
                Expanded(
                  child: _buildDocumentStat('Total', _documents.length, Colors.grey[700]!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentStat(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentLibraryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.library_books, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Policy Documents',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _createNewDocument(),
                  icon: const Icon(Icons.add),
                  label: const Text('New Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final document = _documents[index];
                return _buildDocumentItem(document);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(ComplianceDocument document) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getDocumentTypeColor(document.type).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getDocumentTypeIcon(document.type),
            color: _getDocumentTypeColor(document.type),
          ),
        ),
        title: Text(
          document.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(document.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getDocumentStatusColor(document.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    document.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getDocumentStatusColor(document.status),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'v${document.version}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(document.lastUpdated),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Document Content:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    document.content,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _editDocument(document),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _downloadDocument(document),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (document.status == DocumentStatus.draft)
                      ElevatedButton.icon(
                        onPressed: () => _publishDocument(document),
                        icon: const Icon(Icons.publish, size: 16),
                        label: const Text('Publish'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audit Overview
          _buildAuditOverviewCard(),
          
          const SizedBox(height: 16),
          
          // Audit Trail
          _buildAuditTrailCard(),
        ],
      ),
    );
  }

  Widget _buildAuditOverviewCard() {
    final todayRecords = _auditRecords
        .where((r) => _isToday(r.timestamp))
        .length;
    final weekRecords = _auditRecords
        .where((r) => _isThisWeek(r.timestamp))
        .length;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Audit Activity Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAuditStat('Today', todayRecords, Colors.blue),
                ),
                Expanded(
                  child: _buildAuditStat('This Week', weekRecords, Colors.green),
                ),
                Expanded(
                  child: _buildAuditStat('Total Records', _auditRecords.length, Colors.orange),
                ),
                Expanded(
                  child: _buildAuditStat('Categories', AuditCategory.values.length, Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditStat(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTrailCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'Recent Audit Trail',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _exportAuditLog(),
                  icon: const Icon(Icons.download),
                  label: const Text('Export Log'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _auditRecords.length,
              itemBuilder: (context, index) {
                final record = _auditRecords[index];
                return _buildAuditRecordItem(record);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditRecordItem(AuditRecord record) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getAuditCategoryColor(record.category).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getAuditCategoryColor(record.category).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getAuditCategoryColor(record.category).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getAuditCategoryIcon(record.category),
              color: _getAuditCategoryColor(record.category),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.action,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      _formatDateTime(record.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  record.details,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'User: ${record.userId}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (record.serverId != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        'Server: ${record.serverId!.substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Privacy Overview
          _buildPrivacyOverviewCard(),
          
          const SizedBox(height: 16),
          
          // Data Protection Controls
          _buildDataProtectionCard(),
          
          const SizedBox(height: 16),
          
          // Privacy Settings
          _buildPrivacySettingsCard(),
        ],
      ),
    );
  }

  Widget _buildPrivacyOverviewCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.privacy_tip, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Privacy Protection Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPrivacyStat('Data Encryption', 'Active', Colors.green, Icons.lock),
                ),
                Expanded(
                  child: _buildPrivacyStat('Access Control', 'Enabled', Colors.green, Icons.security),
                ),
                Expanded(
                  child: _buildPrivacyStat('Audit Logging', 'On', Colors.green, Icons.visibility),
                ),
                Expanded(
                  child: _buildPrivacyStat('Retention Policy', '30 Days', Colors.blue, Icons.schedule),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDataProtectionCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Data Protection Controls',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProtectionControl(
              'Automatic Data Anonymization',
              'Server IDs and user data are automatically anonymized in reports',
              true,
              Icons.visibility_off,
            ),
            _buildProtectionControl(
              'Encrypted Data Storage',
              'All integrity data is encrypted at rest using AES-256',
              true,
              Icons.lock,
            ),
            _buildProtectionControl(
              'Secure Data Transmission',
              'Data is transmitted using TLS 1.3 encryption',
              true,
              Icons.security,
            ),
            _buildProtectionControl(
              'Data Retention Limits',
              'Integrity data is automatically purged after 30 days',
              true,
              Icons.delete_forever,
            ),
            _buildProtectionControl(
              'Access Logging',
              'All data access is logged for audit purposes',
              true,
              Icons.history,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtectionControl(String title, String description, bool enabled, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: enabled ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: enabled ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: enabled ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: enabled ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              enabled ? 'ACTIVE' : 'INACTIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: enabled ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettingsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Privacy Settings Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Data Retention Setting
            _buildSettingItem(
              'Data Retention Period',
              '30 days',
              'Configure how long integrity data is stored',
              () => _configureRetention(),
            ),
            
            // Anonymization Level
            _buildSettingItem(
              'Data Anonymization Level',
              'Full Anonymization',
              'Set the level of data anonymization in reports',
              () => _configureAnonymization(),
            ),
            
            // Export Controls
            _buildSettingItem(
              'Data Export Controls',
              'Manager Approval Required',
              'Configure requirements for data export operations',
              () => _configureExportControls(),
            ),
            
            // Access Permissions
            _buildSettingItem(
              'Access Permissions',
              'Role-Based Access',
              'Configure who can access integrity data',
              () => _configureAccessPermissions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, String value, String description, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report Overview
          _buildReportOverviewCard(),
          
          const SizedBox(height: 16),
          
          // Available Reports
          _buildAvailableReportsCard(),
        ],
      ),
    );
  }

  Widget _buildReportOverviewCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assessment, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Compliance Reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Generate comprehensive compliance reports for regulatory requirements, internal audits, and management review.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildReportStat('Reports Generated', '12', Colors.blue),
                ),
                Expanded(
                  child: _buildReportStat('This Month', '3', Colors.green),
                ),
                Expanded(
                  child: _buildReportStat('Scheduled', '2', Colors.orange),
                ),
                Expanded(
                  child: _buildReportStat('Templates', '5', Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableReportsCard() {
    final reports = [
      ComplianceReport(
        title: 'Server Integrity Compliance Report',
        description: 'Comprehensive report on server integrity monitoring and compliance status',
        type: 'Regulatory',
        lastGenerated: DateTime.now().subtract(const Duration(days: 7)),
      ),
      ComplianceReport(
        title: 'Data Privacy Assessment',
        description: 'Assessment of data privacy controls and protection measures',
        type: 'Privacy',
        lastGenerated: DateTime.now().subtract(const Duration(days: 14)),
      ),
      ComplianceReport(
        title: 'Audit Trail Summary',
        description: 'Summary of all system activities and access logs',
        type: 'Audit',
        lastGenerated: DateTime.now().subtract(const Duration(days: 3)),
      ),
      ComplianceReport(
        title: 'Risk Assessment Report',
        description: 'Analysis of server risks and mitigation measures',
        type: 'Risk',
        lastGenerated: DateTime.now().subtract(const Duration(days: 21)),
      ),
    ];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Available Reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return _buildReportItem(report);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(ComplianceReport report) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.description,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        report.type,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last: ${_formatDate(report.lastGenerated)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              ElevatedButton(
                onPressed: () => _generateReport(report),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text(
                  'Generate',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () => _scheduleReport(report),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text(
                  'Schedule',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Utility methods for UI
  Color _getDocumentTypeColor(DocumentType type) {
    switch (type) {
      case DocumentType.policy: return Colors.blue;
      case DocumentType.procedure: return Colors.green;
      case DocumentType.guideline: return Colors.orange;
      case DocumentType.standard: return Colors.purple;
    }
  }

  IconData _getDocumentTypeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.policy: return Icons.policy;
      case DocumentType.procedure: return Icons.list_alt;
      case DocumentType.guideline: return Icons.help_outline;
      case DocumentType.standard: return Icons.verified;
    }
  }

  Color _getDocumentStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.active: return Colors.green;
      case DocumentStatus.draft: return Colors.orange;
      case DocumentStatus.pending: return Colors.blue;
      case DocumentStatus.archived: return Colors.grey;
    }
  }

  Color _getAuditCategoryColor(AuditCategory category) {
    switch (category) {
      case AuditCategory.alert: return Colors.red;
      case AuditCategory.investigation: return Colors.orange;
      case AuditCategory.policy: return Colors.blue;
      case AuditCategory.export: return Colors.green;
      case AuditCategory.access: return Colors.purple;
    }
  }

  IconData _getAuditCategoryIcon(AuditCategory category) {
    switch (category) {
      case AuditCategory.alert: return Icons.warning;
      case AuditCategory.investigation: return Icons.search;
      case AuditCategory.policy: return Icons.policy;
      case AuditCategory.export: return Icons.download;
      case AuditCategory.access: return Icons.login;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.day}/${date.month}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return date.isAfter(weekStart);
  }

  // Sample content methods
  String _getServerIntegrityPolicy() {
    return '''
SERVER INTEGRITY MONITORING POLICY v2.1

1. PURPOSE
This policy establishes comprehensive guidelines for monitoring server integrity and detecting suspicious activities in food delivery operations.

2. SCOPE
This policy applies to all servers, monitoring systems, and personnel involved in food delivery tracking and integrity assessment.

3. MONITORING REQUIREMENTS
- Continuous real-time monitoring of server activities
- Statistical analysis of click patterns and behaviors
- Automated alert generation for anomalous activities
- Regular risk assessments and reporting

4. ALERT THRESHOLDS
- Yellow Alert: Z-score > 1.5 or mechanical score > 0.4
- Orange Alert: Z-score > 2.0 or mechanical score > 0.6
- Red Alert: Z-score > 2.5 or mechanical score > 0.8

5. PRIVACY PROTECTION
- All server data is anonymized in reports
- Access restricted to authorized personnel only
- Data encrypted in transit and at rest
- Automatic data purging after 30 days

6. COMPLIANCE
This policy ensures compliance with data protection regulations and internal security standards.
''';
  }

  String _getDataPrivacyProcedures() {
    return '''
DATA PRIVACY PROTECTION PROCEDURES v1.5

1. DATA COLLECTION
- Collect only necessary data for integrity monitoring
- Minimize personal data collection
- Implement data anonymization at collection point

2. DATA STORAGE
- Use AES-256 encryption for data at rest
- Secure database access with multi-factor authentication
- Regular security audits and vulnerability assessments

3. DATA ACCESS
- Role-based access control implementation
- Manager approval required for sensitive data access
- Complete audit logging of all data access

4. DATA RETENTION
- Maximum retention period: 30 days
- Automatic purging of expired data
- Secure deletion processes

5. DATA EXPORT
- Manager approval required for all exports
- Export logs maintained for audit purposes
- Anonymization applied to exported data
''';
  }

  String _getAlertResponseGuidelines() {
    return '''
ALERT RESPONSE GUIDELINES v1.0

1. IMMEDIATE RESPONSE (Red Alerts)
- Investigate within 1 hour
- Create formal investigation case
- Notify management immediately
- Document all actions taken

2. PRIORITY RESPONSE (Orange Alerts)
- Investigate within 4 hours
- Review server patterns and behaviors
- Determine if escalation is needed
- Update monitoring parameters if necessary

3. STANDARD RESPONSE (Yellow Alerts)
- Investigate within 24 hours
- Monitor for pattern continuation
- Document findings
- Adjust thresholds if appropriate

4. DOCUMENTATION
- All responses must be documented
- Include investigation findings
- Record any corrective actions
- Update alert thresholds based on learnings
''';
  }

  String _getInvestigationStandards() {
    return '''
INVESTIGATION STANDARDS v0.8 (DRAFT)

1. INVESTIGATION INITIATION
- Triggered by system alerts or manual reports
- Assign unique investigation ID
- Set investigation priority and timeline
- Assign responsible investigator

2. EVIDENCE COLLECTION
- Preserve all relevant server data
- Document click patterns and timing
- Collect peer comparison data
- Generate statistical analysis reports

3. ANALYSIS REQUIREMENTS
- Statistical significance testing
- Pattern recognition analysis
- Risk assessment scoring
- Peer comparison evaluation

4. DOCUMENTATION STANDARDS
- Complete investigation timeline
- Evidence preservation chain
- Analysis methodology documentation
- Findings and recommendations

5. RESOLUTION PROCESS
- Document investigation conclusions
- Implement corrective measures
- Update monitoring parameters
- Close investigation with summary
''';
  }

  // Action methods (simplified for demo)
  void _exportComplianceReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compliance report export functionality')),
    );
  }

  void _showComplianceSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compliance settings dialog')),
    );
  }

  void _createNewDocument() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New document creation dialog')),
    );
  }

  void _editDocument(ComplianceDocument document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit document: ${document.title}')),
    );
  }

  void _downloadDocument(ComplianceDocument document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading: ${document.title}')),
    );
  }

  void _publishDocument(ComplianceDocument document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Publishing: ${document.title}')),
    );
  }

  void _exportAuditLog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audit log export functionality')),
    );
  }

  void _configureRetention() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data retention configuration')),
    );
  }

  void _configureAnonymization() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anonymization level configuration')),
    );
  }

  void _configureExportControls() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export controls configuration')),
    );
  }

  void _configureAccessPermissions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Access permissions configuration')),
    );
  }

  void _generateReport(ComplianceReport report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating report: ${report.title}')),
    );
  }

  void _scheduleReport(ComplianceReport report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Scheduling report: ${report.title}')),
    );
  }
}

// Data classes for compliance system
class ComplianceDocument {
  final String id;
  final String title;
  final DocumentType type;
  final DocumentStatus status;
  final String version;
  final DateTime lastUpdated;
  final String description;
  final String content;

  ComplianceDocument({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.version,
    required this.lastUpdated,
    required this.description,
    required this.content,
  });
}

class AuditRecord {
  final String id;
  final DateTime timestamp;
  final String action;
  final String userId;
  final String? serverId;
  final String details;
  final AuditCategory category;

  AuditRecord({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.userId,
    this.serverId,
    required this.details,
    required this.category,
  });
}

class ComplianceReport {
  final String title;
  final String description;
  final String type;
  final DateTime lastGenerated;

  ComplianceReport({
    required this.title,
    required this.description,
    required this.type,
    required this.lastGenerated,
  });
}

enum DocumentType { policy, procedure, guideline, standard }
enum DocumentStatus { active, draft, pending, archived }
enum AuditCategory { alert, investigation, policy, export, access }
