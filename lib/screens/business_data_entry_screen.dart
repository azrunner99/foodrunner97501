import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../models/performance_models.dart';
import '../storage.dart';

class BusinessDataEntryScreen extends StatefulWidget {
  final DateTime? initialMonth;
  
  const BusinessDataEntryScreen({
    super.key,
    this.initialMonth,
  });

  @override
  State<BusinessDataEntryScreen> createState() => _BusinessDataEntryScreenState();
}

class _BusinessDataEntryScreenState extends State<BusinessDataEntryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedMonth;
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  // Business Data Controllers
  final _guestCountController = TextEditingController();
  final _salesController = TextEditingController();
  
  // Server NPS Data
  final Map<String, TextEditingController> _npsControllers = {};
  final Map<String, TextEditingController> _responseCountControllers = {};
  final Map<String, Map<String, TextEditingController>> _categoryControllers = {};
  final Map<String, List<TextEditingController>> _commentControllers = {};
  
  // Existing business data
  MonthlyBusinessData? _existingBusinessData;
  EnhancedMonthlyBusinessData? _existingEnhancedData;
  
  final List<String> _npsCategories = [
    'Service Quality',
    'Food Quality', 
    'Atmosphere',
    'Speed of Service',
    'Overall Experience',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedMonth = widget.initialMonth ?? DateTime.now();
    _initializeControllers();
    _loadExistingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _guestCountController.dispose();
    _salesController.dispose();
    _disposeNPSControllers();
    super.dispose();
  }

  void _initializeControllers() {
    final servers = context.read<AppState>().servers;
    
    for (final server in servers) {
      // Main NPS score controller
      _npsControllers[server.id] = TextEditingController();
      _responseCountControllers[server.id] = TextEditingController();
      
      // Category breakdown controllers
      _categoryControllers[server.id] = {};
      for (final category in _npsCategories) {
        _categoryControllers[server.id]![category] = TextEditingController();
      }
      
      // Comment controllers (up to 3 comments per server)
      _commentControllers[server.id] = List.generate(3, (index) => TextEditingController());
    }
    
    // Add listeners for unsaved changes tracking
    _guestCountController.addListener(_markUnsavedChanges);
    _salesController.addListener(_markUnsavedChanges);
    
    for (final controllers in _npsControllers.values) {
      controllers.addListener(_markUnsavedChanges);
    }
  }

  void _disposeNPSControllers() {
    for (final controller in _npsControllers.values) {
      controller.dispose();
    }
    for (final controller in _responseCountControllers.values) {
      controller.dispose();
    }
    for (final serverCategories in _categoryControllers.values) {
      for (final controller in serverCategories.values) {
        controller.dispose();
      }
    }
    for (final serverComments in _commentControllers.values) {
      for (final controller in serverComments) {
        controller.dispose();
      }
    }
  }

  void _markUnsavedChanges() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);
    
    try {
      final monthKey = Storage.generateMonthKey(_selectedMonth);
      
      // Load existing business data
      final businessDataMap = await Storage.getMonthlyBusinessData(monthKey);
      if (businessDataMap != null) {
        _existingBusinessData = MonthlyBusinessData.fromMap(businessDataMap);
        _guestCountController.text = _existingBusinessData!.totalGuestCount.toString();
        _salesController.text = _existingBusinessData!.totalSales.toString();
      }
      
      // Load existing enhanced data (with NPS)
      final enhancedDataMap = await Storage.getEnhancedMonthlyBusinessData(monthKey);
      if (enhancedDataMap != null) {
        _existingEnhancedData = EnhancedMonthlyBusinessData.fromMap(enhancedDataMap);
        _populateNPSData();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading existing data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateNPSData() {
    if (_existingEnhancedData == null) return;
    
    for (final entry in _existingEnhancedData!.serverNPSData.entries) {
      final serverId = entry.key;
      final npsData = entry.value;
      
      _npsControllers[serverId]?.text = npsData.monthlyScore.toStringAsFixed(1);
      _responseCountControllers[serverId]?.text = npsData.responseCount.toString();
      
      // Populate category breakdowns
      for (final categoryEntry in npsData.categoryBreakdown.entries) {
        _categoryControllers[serverId]?[categoryEntry.key]?.text = 
          categoryEntry.value.toStringAsFixed(1);
      }
      
      // Populate comments
      for (int i = 0; i < npsData.guestComments.length && i < 3; i++) {
        _commentControllers[serverId]?[i].text = npsData.guestComments[i];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Business Data Entry - ${_getMonthDisplayName(_selectedMonth)}'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_hasUnsavedChanges)
            IconButton(
              icon: const Icon(Icons.warning, color: Colors.orange),
              onPressed: _showUnsavedChangesDialog,
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAllData,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change_month',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 8),
                    Text('Change Month'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import_data',
                child: Row(
                  children: [
                    Icon(Icons.file_upload),
                    SizedBox(width: 8),
                    Text('Import Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_data',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.business), text: 'Business'),
            Tab(icon: Icon(Icons.star_rate), text: 'NPS Scores'),
            Tab(icon: Icon(Icons.analytics), text: 'Summary'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildBusinessDataTab(),
                  _buildNPSDataTab(),
                  _buildSummaryTab(),
                ],
              ),
      ),
      floatingActionButton: _hasUnsavedChanges
          ? FloatingActionButton.extended(
              onPressed: _saveAllData,
              backgroundColor: Colors.green.shade700,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save All', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildBusinessDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.business, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Monthly Business Metrics',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    controller: _guestCountController,
                    label: 'Total Guest Count',
                    icon: Icons.people,
                    hint: 'Enter total guests served this month',
                    isInteger: true,
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    controller: _salesController,
                    label: 'Total Sales (\$)',
                    icon: Icons.attach_money,
                    hint: 'Enter total sales revenue for the month',
                    isInteger: false,
                  ),
                  const SizedBox(height: 16),
                  if (_existingBusinessData != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Previous Data Found',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text('Guests: ${_existingBusinessData!.totalGuestCount.toStringAsFixed(0)}'),
                          Text('Sales: \$${_existingBusinessData!.totalSales.toStringAsFixed(2)}'),
                          Text('Last Updated: ${_formatDateTime(_existingBusinessData!.entryDate)}'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCalculationsCard(),
        ],
      ),
    );
  }

  Widget _buildNPSDataTab() {
    final servers = context.read<AppState>().servers;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_rate, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Net Promoter Score (NPS) Data',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter monthly NPS scores (0-100%) and guest feedback for each server. The 3-month average is automatically calculated and is the primary metric used for performance evaluation.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...servers.map((server) => _buildServerNPSCard(server)),
        ],
      ),
    );
  }

  Widget _buildServerNPSCard(Server server) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade700,
          child: Text(
            server.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          server.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: _buildNPSSubtitle(server.id),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        controller: _npsControllers[server.id]!,
                        label: 'Monthly NPS Score (%)',
                        icon: Icons.percent,
                        hint: '0-100',
                        isInteger: false,
                        maxValue: 100,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildNumberField(
                        controller: _responseCountControllers[server.id]!,
                        label: 'Response Count',
                        icon: Icons.people_outline,
                        hint: 'Number of responses',
                        isInteger: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Category Breakdown',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._npsCategories.map((category) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildNumberField(
                    controller: _categoryControllers[server.id]![category]!,
                    label: category,
                    icon: Icons.category,
                    hint: '0-100%',
                    isInteger: false,
                    maxValue: 100,
                  ),
                )),
                const SizedBox(height: 16),
                Text(
                  'Guest Comments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...List.generate(3, (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextFormField(
                    controller: _commentControllers[server.id]![index],
                    decoration: InputDecoration(
                      labelText: 'Comment ${index + 1}',
                      hintText: 'Enter guest feedback (optional)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.comment),
                    ),
                    maxLines: 2,
                    onChanged: (_) => _markUnsavedChanges(),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNPSSubtitle(String serverId) {
    final npsText = _npsControllers[serverId]?.text ?? '';
    if (npsText.isEmpty) {
      return const Text('No NPS data entered');
    }
    
    final score = double.tryParse(npsText) ?? 0.0;
    final category = _getNPSCategory(score);
    
    return Row(
      children: [
        Text(category.emoji),
        const SizedBox(width: 4),
        Text(
          '${score.toStringAsFixed(1)}% - ${category.displayName}',
          style: TextStyle(color: category.color),
        ),
      ],
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBusinessSummaryCard(),
          const SizedBox(height: 16),
          _buildNPSSummaryCard(),
          const SizedBox(height: 16),
          _buildActionButtonsCard(),
        ],
      ),
    );
  }

  Widget _buildBusinessSummaryCard() {
    final guestCount = int.tryParse(_guestCountController.text) ?? 0;
    final sales = double.tryParse(_salesController.text) ?? 0.0;
    final avgSpend = guestCount > 0 ? sales / guestCount : 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    'Total Guests',
                    guestCount.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryMetric(
                    'Total Sales',
                    '\$${sales.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    'Avg Spend/Guest',
                    '\$${avgSpend.toStringAsFixed(2)}',
                    Icons.receipt,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryMetric(
                    'Data Quality',
                    _getDataQuality(),
                    Icons.check_circle,
                    _getDataQualityColor(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNPSSummaryCard() {
    final servers = context.read<AppState>().servers;
    final npsScores = <double>[];
    var totalResponses = 0;
    
    for (final server in servers) {
      final scoreText = _npsControllers[server.id]?.text ?? '';
      final responsesText = _responseCountControllers[server.id]?.text ?? '';
      
      if (scoreText.isNotEmpty) {
        final score = double.tryParse(scoreText) ?? 0.0;
        if (score > 0) npsScores.add(score);
      }
      
      if (responsesText.isNotEmpty) {
        totalResponses += int.tryParse(responsesText) ?? 0;
      }
    }
    
    final avgNPS = npsScores.isNotEmpty 
        ? npsScores.reduce((a, b) => a + b) / npsScores.length 
        : 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NPS Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    'Restaurant NPS',
                    '${avgNPS.toStringAsFixed(1)}%',
                    Icons.star,
                    _getNPSCategory(avgNPS).color,
                  ),
                ),
                Expanded(
                  child: _buildSummaryMetric(
                    'Total Responses',
                    totalResponses.toString(),
                    Icons.comment,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    'Servers with Data',
                    '${npsScores.length}/${servers.length}',
                    Icons.person_add,
                    npsScores.length == servers.length ? Colors.green : Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryMetric(
                    'NPS Category',
                    _getNPSCategory(avgNPS).displayName,
                    Icons.category,
                    _getNPSCategory(avgNPS).color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _validateAndSave,
                    icon: const Icon(Icons.save),
                    label: const Text('Save & Validate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearAllData,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previewReport,
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview Report'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportData,
                    icon: const Icon(Icons.download),
                    label: const Text('Export Data'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required bool isInteger,
    double? maxValue,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  _markUnsavedChanges();
                },
              )
            : null,
      ),
      keyboardType: isInteger 
          ? TextInputType.number 
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        if (isInteger) FilteringTextInputFormatter.digitsOnly
        else FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (value) {
        if (maxValue != null && value.isNotEmpty) {
          final numValue = double.tryParse(value) ?? 0.0;
          if (numValue > maxValue) {
            controller.text = maxValue.toString();
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
          }
        }
        _markUnsavedChanges();
      },
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        
        final numValue = isInteger 
            ? int.tryParse(value) 
            : double.tryParse(value);
            
        if (numValue == null) {
          return 'Please enter a valid ${isInteger ? 'number' : 'decimal'}';
        }
        
        if (maxValue != null && numValue > maxValue) {
          return 'Value cannot exceed ${maxValue.toStringAsFixed(0)}';
        }
        
        return null;
      },
    );
  }

  Widget _buildCalculationsCard() {
    final guestCount = int.tryParse(_guestCountController.text) ?? 0;
    final sales = double.tryParse(_salesController.text) ?? 0.0;
    final daysInMonth = _getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calculations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildCalculationRow('Average Spend per Guest', guestCount > 0 
                ? '\$${(sales / guestCount).toStringAsFixed(2)}'
                : '\$0.00'),
            _buildCalculationRow('Sales per Day', sales > 0 
                ? '\$${(sales / daysInMonth).toStringAsFixed(2)}'
                : '\$0.00'),
            _buildCalculationRow('Guests per Day', guestCount > 0 
                ? '${(guestCount / daysInMonth).toStringAsFixed(1)}'
                : '0.0'),
          ],
        ),
      ),
    );
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  Widget _buildCalculationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  Widget _buildSummaryMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods

  String _getMonthDisplayName(DateTime month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  NPSCategory _getNPSCategory(double score) {
    if (score >= 80) return NPSCategory.exceptional;
    if (score >= 70) return NPSCategory.excellent;
    if (score >= 60) return NPSCategory.good;
    if (score >= 50) return NPSCategory.fair;
    return NPSCategory.needsImprovement;
  }

  String _getDataQuality() {
    var score = 0;
    var maxScore = 5;
    
    // Business data completeness
    if (_guestCountController.text.isNotEmpty) score++;
    if (_salesController.text.isNotEmpty) score++;
    
    // NPS data completeness
    var hasNPSData = false;
    for (final controller in _npsControllers.values) {
      if (controller.text.isNotEmpty) {
        hasNPSData = true;
        break;
      }
    }
    if (hasNPSData) score++;
    
    // Validation checks
    final guestCount = int.tryParse(_guestCountController.text) ?? 0;
    final sales = double.tryParse(_salesController.text) ?? 0.0;
    if (guestCount > 0 && sales > 0) score++;
    
    // Consistency checks
    if (guestCount > 0 && sales > 0 && (sales / guestCount) > 5 && (sales / guestCount) < 200) {
      score++; // Reasonable average spend
    }
    
    final percentage = (score / maxScore) * 100;
    if (percentage >= 80) return 'Excellent';
    if (percentage >= 60) return 'Good';
    if (percentage >= 40) return 'Fair';
    return 'Poor';
  }

  Color _getDataQualityColor() {
    final quality = _getDataQuality();
    switch (quality) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.blue;
      case 'Fair':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  // Action methods

  Future<void> _saveAllData() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _saveBusinessData();
      await _saveNPSData();
      
      setState(() => _hasUnsavedChanges = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBusinessData() async {
    final guestCount = int.tryParse(_guestCountController.text) ?? 0;
    final sales = double.tryParse(_salesController.text) ?? 0.0;
    
    if (guestCount <= 0 || sales <= 0) return;
    
    final businessData = MonthlyBusinessData(
      month: _selectedMonth,
      totalGuestCount: guestCount.toDouble(),
      totalSales: sales,
      serverSpecificGuests: {}, // TODO: Calculate from shift data
      serverSpecificSales: {}, // TODO: Calculate from shift data
      validated: true,
      entryDate: DateTime.now(),
    );
    
    final monthKey = Storage.generateMonthKey(_selectedMonth);
    await Storage.saveMonthlyBusinessData(monthKey, businessData.toMap());
  }

  Future<void> _saveNPSData() async {
    final servers = context.read<AppState>().servers;
    final serverNPSData = <String, NPSData>{};
    var totalNPS = 0.0;
    var npsCount = 0;
    
    for (final server in servers) {
      final scoreText = _npsControllers[server.id]?.text ?? '';
      if (scoreText.isEmpty) continue;
      
      final monthlyScore = double.tryParse(scoreText) ?? 0.0;
      if (monthlyScore <= 0) continue;
      
      final responseCount = int.tryParse(_responseCountControllers[server.id]?.text ?? '0') ?? 0;
      
      // Get category breakdown
      final categoryBreakdown = <String, double>{};
      for (final category in _npsCategories) {
        final categoryScore = double.tryParse(
          _categoryControllers[server.id]?[category]?.text ?? '0'
        ) ?? 0.0;
        if (categoryScore > 0) {
          categoryBreakdown[category] = categoryScore;
        }
      }
      
      // Get comments
      final comments = <String>[];
      for (final controller in _commentControllers[server.id] ?? []) {
        if (controller.text.trim().isNotEmpty) {
          comments.add(controller.text.trim());
        }
      }
      
      // Calculate 3-month average (simplified - would need historical data)
      final threeMonthAverage = monthlyScore; // TODO: Calculate from historical data
      
      final npsData = NPSData(
        serverId: server.id,
        month: _selectedMonth,
        monthlyScore: monthlyScore,
        threeMonthAverage: threeMonthAverage,
        responseCount: responseCount,
        categoryBreakdown: categoryBreakdown,
        guestComments: comments,
        lastUpdated: DateTime.now(),
      );
      
      serverNPSData[server.id] = npsData;
      totalNPS += monthlyScore;
      npsCount++;
    }
    
    if (serverNPSData.isNotEmpty) {
      final guestCount = int.tryParse(_guestCountController.text) ?? 0;
      final sales = double.tryParse(_salesController.text) ?? 0.0;
      
      final enhancedData = EnhancedMonthlyBusinessData(
        month: _selectedMonth,
        totalGuests: guestCount,
        totalSales: sales,
        serverNPSData: serverNPSData,
        restaurantNPSAverage: npsCount > 0 ? totalNPS / npsCount : 0.0,
        serverShiftCounts: {}, // TODO: Calculate from shift data
        serverSalesShare: {}, // TODO: Calculate from shift data
        lastUpdated: DateTime.now(),
      );
      
      final monthKey = Storage.generateMonthKey(_selectedMonth);
      await Storage.saveEnhancedMonthlyBusinessData(monthKey, enhancedData.toMap());
    }
  }

  void _validateAndSave() {
    // TODO: Add validation logic
    _saveAllData();
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to clear all entered data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performClearAll();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _performClearAll() {
    _guestCountController.clear();
    _salesController.clear();
    
    for (final controller in _npsControllers.values) {
      controller.clear();
    }
    for (final controller in _responseCountControllers.values) {
      controller.clear();
    }
    for (final serverCategories in _categoryControllers.values) {
      for (final controller in serverCategories.values) {
        controller.clear();
      }
    }
    for (final serverComments in _commentControllers.values) {
      for (final controller in serverComments) {
        controller.clear();
      }
    }
    
    setState(() => _hasUnsavedChanges = false);
  }

  void _previewReport() {
    // TODO: Implement report preview
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report preview coming soon!')),
    );
  }

  void _exportData() {
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export coming soon!')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'change_month':
        _showMonthPicker();
        break;
      case 'import_data':
        // TODO: Implement data import
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data import coming soon!')),
        );
        break;
      case 'export_data':
        _exportData();
        break;
    }
  }

  void _showMonthPicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDatePickerMode: DatePickerMode.year,
    ).then((selectedDate) {
      if (selectedDate != null) {
        setState(() {
          _selectedMonth = DateTime(selectedDate.year, selectedDate.month, 1);
        });
        _loadExistingData();
      }
    });
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Would you like to save them now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Editing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _hasUnsavedChanges = false);
            },
            child: const Text('Discard Changes'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveAllData();
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}