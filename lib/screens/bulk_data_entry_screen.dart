import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/performance_models.dart';
import '../storage.dart';
import '../widgets/wallpaper_background.dart';

/// Comprehensive data entry screen for business data and server performance
class BulkDataEntryScreen extends StatefulWidget {
  final DateTime? initialMonth;
  final MonthlyBusinessData? existingBusinessData;

  const BulkDataEntryScreen({
    super.key,
    this.initialMonth,
    this.existingBusinessData,
  });

  @override
  State<BulkDataEntryScreen> createState() => _BulkDataEntryScreenState();
}

class _BulkDataEntryScreenState extends State<BulkDataEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _guestCountController = TextEditingController();
  final _salesController = TextEditingController();
  
  // Server-specific data controllers
  final Map<String, TextEditingController> _serverGuestControllers = {};
  final Map<String, TextEditingController> _serverSalesControllers = {};
  final Map<String, TextEditingController> _npsAllTimeControllers = {};
  final Map<String, TextEditingController> _npsThreeMonthControllers = {};
  final Map<String, TextEditingController> _npsOneMonthControllers = {};
  
  int _selectedTabIndex = 0;
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now();
  bool _isLoading = false;
  bool _hasUnsavedChanges = false; // Track if user has entered data
  List<String> _existingDataWarnings = []; // Track warnings about existing data

  @override
  void initState() {
    super.initState();
    final currentMonth = widget.initialMonth ?? DateTime.now();
    _selectedStartDate = DateTime(currentMonth.year, currentMonth.month, 1);
    _selectedEndDate = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    _initializeControllers();
    _checkExistingDataWarning(); // Check for existing data on initialization
  }

  @override
  void dispose() {
    _guestCountController.dispose();
    _salesController.dispose();
    _disposeServerControllers();
    super.dispose();
  }

  void _initializeControllers() {
    final appState = context.read<AppState>();
    final servers = appState.servers;
    
    // Initialize with existing data if available
    if (widget.existingBusinessData != null) {
      _guestCountController.text = widget.existingBusinessData!.totalGuestCount.toStringAsFixed(0);
      _salesController.text = widget.existingBusinessData!.totalSales.toStringAsFixed(2);
    }
    
    // Add listeners to track changes
    _guestCountController.addListener(_onDataChanged);
    _salesController.addListener(_onDataChanged);
    
    // Initialize server-specific controllers
    for (final server in servers) {
      _serverGuestControllers[server.id] = TextEditingController();
      _serverSalesControllers[server.id] = TextEditingController();
      _npsAllTimeControllers[server.id] = TextEditingController();
      _npsThreeMonthControllers[server.id] = TextEditingController();
      _npsOneMonthControllers[server.id] = TextEditingController();
      
      // Add listeners to server controllers
      _serverGuestControllers[server.id]!.addListener(_onDataChanged);
      _serverSalesControllers[server.id]!.addListener(_onDataChanged);
      _npsAllTimeControllers[server.id]!.addListener(_onDataChanged);
      _npsThreeMonthControllers[server.id]!.addListener(_onDataChanged);
      _npsOneMonthControllers[server.id]!.addListener(_onDataChanged);
      
      // Load existing server-specific data if available
      if (widget.existingBusinessData != null) {
        final existingGuests = widget.existingBusinessData!.serverSpecificGuests[server.id];
        final existingSales = widget.existingBusinessData!.serverSpecificSales[server.id];
        
        if (existingGuests != null) {
          _serverGuestControllers[server.id]!.text = existingGuests.toStringAsFixed(0);
        }
        if (existingSales != null) {
          _serverSalesControllers[server.id]!.text = existingSales.toStringAsFixed(2);
        }
      }
    }
  }

  void _onDataChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _disposeServerControllers() {
    for (final controller in _serverGuestControllers.values) {
      controller.dispose();
    }
    for (final controller in _serverSalesControllers.values) {
      controller.dispose();
    }
    for (final controller in _npsAllTimeControllers.values) {
      controller.dispose();
    }
    for (final controller in _npsThreeMonthControllers.values) {
      controller.dispose();
    }
    for (final controller in _npsOneMonthControllers.values) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final servers = context.watch<AppState>().servers;
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bulk Data Entry'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade600.withOpacity(0.8),
                  Colors.blue.shade400.withOpacity(0.6),
                ],
              ),
            ),
          ),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: _isLoading
            ? null
            : Container(
                width: 180,
                height: 56,
                child: FloatingActionButton.extended(
                  onPressed: _saveData,
                  backgroundColor: Colors.green.shade600,
                  elevation: 8,
                  icon: const Icon(Icons.save, color: Colors.white, size: 28),
                  label: const Text(
                    'Save All Data',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: WallpaperBackground(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
          child: Column(
            children: [
              // Date Range Selection
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Entry Period',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _selectStartDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(_formatDate(_selectedStartDate)),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('to'),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: _selectEndDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(_formatDate(_selectedEndDate)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Existing Data Warning
              if (_existingDataWarnings.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Existing Data Found',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _existingDataWarnings.join(', '),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Saving will prompt you to overwrite existing data.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Tab Selector
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTabIndex = 0),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTabIndex == 0 ? Colors.blue : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant,
                                color: _selectedTabIndex == 0 ? Colors.blue : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Restaurant Totals',
                                style: TextStyle(
                                  color: _selectedTabIndex == 0 ? Colors.blue : Colors.grey,
                                  fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTabIndex = 1),
                        borderRadius: const BorderRadius.only(topRight: Radius.circular(12)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTabIndex == 1 ? Colors.blue : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people,
                                color: _selectedTabIndex == 1 ? Colors.blue : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Individual Servers',
                                style: TextStyle(
                                  color: _selectedTabIndex == 1 ? Colors.blue : Colors.grey,
                                  fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tab Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _selectedTabIndex == 0
                      ? _buildRestaurantTotalsTab()
                      : _buildIndividualServersTab(servers),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true; // Allow navigation if no unsaved changes
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save entered data?'),
        content: const Text('You have unsaved changes. Do you want to save your data before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Don't save
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Save
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Save the data
      await _saveData();
    }

    return true; // Allow navigation after handling save
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedStartDate = picked);
      await _checkExistingDataWarning();
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedStartDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedEndDate = picked);
      await _checkExistingDataWarning();
    }
  }

  Widget _buildRestaurantTotalsTab() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurant-Wide Metrics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter overall restaurant performance data for the selected period',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            
            // Guest count input
            TextFormField(
              controller: _guestCountController,
              decoration: InputDecoration(
                labelText: 'Total Guest Count',
                hintText: 'Enter total guests served',
                prefixIcon: const Icon(Icons.people),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter guest count';
                }
                final count = int.tryParse(value);
                if (count == null || count <= 0) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Sales input
            TextFormField(
              controller: _salesController,
              decoration: InputDecoration(
                labelText: 'Total Sales (\$)',
                hintText: 'Enter total sales amount',
                prefixIcon: const Icon(Icons.attach_money),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter sales amount';
                }
                final sales = double.tryParse(value);
                if (sales == null || sales <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Use the "Individual Servers" tab to enter detailed data for each server including NPS scores and individual performance metrics.',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualServersTab(List servers) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Individual Server Data',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter detailed performance data for each server',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              itemCount: servers.length,
              itemBuilder: (context, index) {
                final server = servers[index];
                return _buildServerDataCard(server);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerDataCard(server) {
    // Ensure controllers exist for this server
    if (!_serverGuestControllers.containsKey(server.id)) {
      _serverGuestControllers[server.id] = TextEditingController();
    }
    if (!_serverSalesControllers.containsKey(server.id)) {
      _serverSalesControllers[server.id] = TextEditingController();
    }
    if (!_npsAllTimeControllers.containsKey(server.id)) {
      _npsAllTimeControllers[server.id] = TextEditingController();
    }
    if (!_npsThreeMonthControllers.containsKey(server.id)) {
      _npsThreeMonthControllers[server.id] = TextEditingController();
    }
    if (!_npsOneMonthControllers.containsKey(server.id)) {
      _npsOneMonthControllers[server.id] = TextEditingController();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Server header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    server.name.isNotEmpty ? server.name.substring(0, 1).toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (server.stationType != null)
                        Text(
                          server.stationType!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Performance metrics row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _serverGuestControllers[server.id],
                    decoration: const InputDecoration(
                      labelText: 'Guest Count',
                      hintText: '0',
                      prefixIcon: Icon(Icons.people_outline),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _serverSalesControllers[server.id],
                    decoration: const InputDecoration(
                      labelText: 'Sales (\$)',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // NPS scores section
            Text(
              'NPS Scores',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _npsAllTimeControllers[server.id],
                    decoration: const InputDecoration(
                      labelText: 'All Time',
                      hintText: '0-100',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => _validateNPSScore(value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _npsThreeMonthControllers[server.id],
                    decoration: const InputDecoration(
                      labelText: '3 Month',
                      hintText: '0-100',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => _validateNPSScore(value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _npsOneMonthControllers[server.id],
                    decoration: const InputDecoration(
                      labelText: '1 Month',
                      hintText: '0-100',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => _validateNPSScore(value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _validateNPSScore(String? value) {
    if (value != null && value.isNotEmpty) {
      final score = double.tryParse(value);
      if (score == null || score < 0 || score > 100) {
        return 'Score must be 0-100';
      }
    }
    return null;
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use the user-selected date range, not widget.initialMonth
      final startDate = _selectedStartDate;
      final endDate = _selectedEndDate;
      
      // Check if we need to handle multiple months or a custom date range
      final isMultiMonth = startDate.month != endDate.month || startDate.year != endDate.year;
      
      if (isMultiMonth) {
        // Handle date range spanning multiple months
        await _saveDateRangeData(startDate, endDate);
      } else {
        // Single month - use existing logic but with correct date
        await _saveSingleMonthData(startDate);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data saved successfully for ${_formatDate(startDate)} to ${_formatDate(endDate)}!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate data was saved
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSingleMonthData(DateTime monthDate) async {
    final monthKey = '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}';
    
    // Collect server-specific data first
    final Map<String, double> serverGuests = {};
    final Map<String, double> serverSales = {};
    
    for (final entry in _serverGuestControllers.entries) {
      final serverId = entry.key;
      final guestText = entry.value.text;
      final salesText = _serverSalesControllers[serverId]!.text;
      
      if (guestText.isNotEmpty) {
        serverGuests[serverId] = double.parse(guestText);
      }
      if (salesText.isNotEmpty) {
        serverSales[serverId] = double.parse(salesText);
      }
    }
    
    // Check for existing data and confirm overwrite if needed
    final existingData = await Storage.getMonthlyBusinessData(monthKey);
    if (existingData != null && mounted) {
      final decision = await _confirmDataOverwrite(monthDate);
      if (decision == 'cancel') {
        return; // User cancelled
      } else if (decision == 'merge') {
        // Handle merge logic
        final existingBusinessData = MonthlyBusinessData.fromMap(existingData);
        final newBusinessData = MonthlyBusinessData(
          month: monthDate,
          totalGuestCount: double.tryParse(_guestCountController.text) ?? 0.0,
          totalSales: double.tryParse(_salesController.text) ?? 0.0,
          serverSpecificGuests: serverGuests,
          serverSpecificSales: serverSales,
          validated: true,
          entryDate: DateTime.now(),
        );
        final mergedData = await _mergeBusinessData(existingBusinessData, newBusinessData);
        await Storage.saveMonthlyBusinessData(monthKey, mergedData.toMap());
        return; // Merge complete, exit method
      }
      // If decision == 'overwrite', continue with normal save
    }
    
    // Create business data
    final businessData = MonthlyBusinessData(
      month: monthDate,
      totalGuestCount: double.tryParse(_guestCountController.text) ?? 0.0,
      totalSales: double.tryParse(_salesController.text) ?? 0.0,
      serverSpecificGuests: serverGuests,
      serverSpecificSales: serverSales,
      validated: true,
      entryDate: DateTime.now(),
    );
    
    // Save business data
    await Storage.saveMonthlyBusinessData(monthKey, businessData.toMap());
    
    // Save NPS data for each server with scores
    for (final serverId in _npsAllTimeControllers.keys) {
      final allTimeText = _npsAllTimeControllers[serverId]!.text;
      final threeMonthText = _npsThreeMonthControllers[serverId]!.text;
      final oneMonthText = _npsOneMonthControllers[serverId]!.text;
      
      if (allTimeText.isNotEmpty || threeMonthText.isNotEmpty || oneMonthText.isNotEmpty) {
        final allTimeScore = double.tryParse(allTimeText) ?? 0.0;
        final threeMonthScore = double.tryParse(threeMonthText) ?? allTimeScore;
        final oneMonthScore = double.tryParse(oneMonthText) ?? threeMonthScore;
        
        // Create NPSData for this server
        final npsData = NPSData(
          serverId: serverId,
          month: monthDate,
          monthlyScore: oneMonthScore,
          threeMonthAverage: threeMonthScore,
          responseCount: 10, // Default response count
          categoryBreakdown: {
            'Service Quality': oneMonthScore,
            'Food Quality': oneMonthScore,
            'Atmosphere': oneMonthScore,
            'Speed of Service': oneMonthScore,
            'Overall Experience': oneMonthScore,
          },
          guestComments: [],
          lastUpdated: DateTime.now(),
        );
        
        // Save NPS data using the storage box
        final npsKey = '${monthKey}_nps_$serverId';
        await Storage.enhancedBusinessDataBox.put(npsKey, npsData.toMap());
      }
    }
  }

  Future<void> _saveDateRangeData(DateTime startDate, DateTime endDate) async {
    // For now, distribute the data proportionally across the months in the range
    // This is a simplified implementation - could be enhanced for more complex scenarios
    
    final months = <DateTime>[];
    DateTime current = DateTime(startDate.year, startDate.month, 1);
    final end = DateTime(endDate.year, endDate.month, 1);
    
    while (current.isBefore(end) || current == end) {
      months.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }
    
    // Distribute the totals across the months proportionally
    final totalGuests = double.tryParse(_guestCountController.text) ?? 0.0;
    final totalSales = double.tryParse(_salesController.text) ?? 0.0;
    final guestsPerMonth = totalGuests / months.length;
    final salesPerMonth = totalSales / months.length;
    
    for (final month in months) {
      // Check for existing data
      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      final existingData = await Storage.getMonthlyBusinessData(monthKey);
      if (existingData != null && mounted) {
        final decision = await _confirmDataOverwrite(month);
        if (decision == 'cancel') {
          continue; // Skip this month
        }
        // Note: For date range data, we don't support merge - only overwrite or cancel
      }
      
      // Create proportional business data for this month
      final businessData = MonthlyBusinessData(
        month: month,
        totalGuestCount: guestsPerMonth,
        totalSales: salesPerMonth,
        serverSpecificGuests: {}, // Could distribute server data proportionally too
        serverSpecificSales: {},
        validated: true,
        entryDate: DateTime.now(),
      );
      
      await Storage.saveMonthlyBusinessData(monthKey, businessData.toMap());
    }
  }

  Future<String?> _confirmDataOverwrite(DateTime month) async {
    final monthKey = Storage.generateMonthKey(month);
    final existingData = await Storage.getMonthlyBusinessData(monthKey);
    
    if (existingData == null) return 'proceed'; // No conflict
    
    final existingGuests = existingData['totalGuestCount']?.toString() ?? '0';
    final existingSales = existingData['totalSales']?.toString() ?? '0';
    final existingEntryDate = existingData['entryDate'] != null 
        ? DateTime.parse(existingData['entryDate']).toString().substring(0, 16)
        : 'Unknown';
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Data Conflict for ${_getMonthName(month)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Existing data found:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Guests: $existingGuests'),
                  Text('• Sales: \$${double.parse(existingSales).toStringAsFixed(2)}'),
                  Text('• Entered: $existingEntryDate'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('How would you like to proceed?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('merge'),
            child: const Text('Merge Data'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('overwrite'),
            child: const Text('Overwrite'),
          ),
        ],
      ),
    );
    return result;
  }
  
  Future<MonthlyBusinessData> _mergeBusinessData(MonthlyBusinessData existing, MonthlyBusinessData newData) async {
    // For guest count and sales, we'll add them together (assuming they're complementary)
    // In a real app, you might want more sophisticated merging logic
    return MonthlyBusinessData(
      month: existing.month,
      totalGuestCount: existing.totalGuestCount + newData.totalGuestCount,
      totalSales: existing.totalSales + newData.totalSales,
      serverSpecificGuests: {
        ...existing.serverSpecificGuests,
        ...newData.serverSpecificGuests,
      },
      serverSpecificSales: {
        ...existing.serverSpecificSales,
        ...newData.serverSpecificSales,
      },
      validated: true,
      entryDate: DateTime.now(), // Update entry date to current time
    );
  }

  String _getMonthName(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _checkExistingDataWarning() async {
    // Get comprehensive summary of existing data for the date range
    final summary = await Storage.getDateRangeDataSummary(_selectedStartDate, _selectedEndDate);
    final warnings = <String>[];
    
    if (summary['monthsWithData'] > 0) {
      final monthsWithData = summary['monthsWithData'] as int;
      final totalMonths = summary['monthsInRange'] as int;
      
      if (monthsWithData == totalMonths) {
        warnings.add('All months in selected range already have data');
      } else {
        warnings.add('$monthsWithData of $totalMonths months already have data');
      }
      
      // Add specific month details
      final monthDetails = summary['monthDetails'] as Map<String, Map<String, dynamic>>;
      for (final entry in monthDetails.entries) {
        final monthKey = entry.key;
        final details = entry.value;
        final guests = details['guests']?.toString() ?? '0';
        final sales = details['sales']?.toString() ?? '0';
        warnings.add('$monthKey: $guests guests, \$${double.parse(sales).toStringAsFixed(0)} sales');
      }
    }
    
    setState(() {
      _existingDataWarnings = warnings;
    });
  }
}