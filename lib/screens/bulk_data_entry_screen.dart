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

  @override
  void initState() {
    super.initState();
    final currentMonth = widget.initialMonth ?? DateTime.now();
    _selectedStartDate = DateTime(currentMonth.year, currentMonth.month, 1);
    _selectedEndDate = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    _initializeControllers();
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
    
    // Initialize server-specific controllers
    for (final server in servers) {
      _serverGuestControllers[server.id] = TextEditingController();
      _serverSalesControllers[server.id] = TextEditingController();
      _npsAllTimeControllers[server.id] = TextEditingController();
      _npsThreeMonthControllers[server.id] = TextEditingController();
      _npsOneMonthControllers[server.id] = TextEditingController();
      
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
    
    return Scaffold(
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
            )
          else
            TextButton.icon(
              onPressed: _saveData,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Save All Data',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
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
    );
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
      final currentMonth = widget.initialMonth ?? DateTime.now();
      final monthKey = '${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}';
      
      // Collect server-specific data
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
      
      // Create business data
      final businessData = MonthlyBusinessData(
        month: currentMonth,
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
            month: currentMonth,
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All business data saved successfully!'),
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
}