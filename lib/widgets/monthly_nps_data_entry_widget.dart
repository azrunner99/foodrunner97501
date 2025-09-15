import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nps_provider.dart';
import '../models/server.dart';
import '../models/nps_feedback.dart';

/// Widget for monthly NPS data entry
/// Allows bulk entry of NPS scores and feedback for servers over a month period
class MonthlyNPSDataEntryWidget extends StatefulWidget {
  const MonthlyNPSDataEntryWidget({super.key});

  @override
  State<MonthlyNPSDataEntryWidget> createState() => _MonthlyNPSDataEntryWidgetState();
}

class _MonthlyNPSDataEntryWidgetState extends State<MonthlyNPSDataEntryWidget> {
  DateTime _selectedMonth = DateTime.now();
  NPSServer? _selectedServer;
  final List<NPSFeedbackEntry> _feedbackEntries = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<NPSProvider>(
      builder: (context, npsProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(npsProvider),
              const SizedBox(height: 24),
              _buildMonthSelector(),
              const SizedBox(height: 16),
              _buildServerSelector(npsProvider),
              const SizedBox(height: 24),
              Expanded(
                child: _buildDataEntrySection(),
              ),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(NPSProvider npsProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade100,
            Colors.orange.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly NPS Data Entry',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter NPS scores and feedback for servers by month',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Month',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectMonth,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerSelector(NPSProvider npsProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Server',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<NPSServer>(
              value: _selectedServer,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Choose a server...'),
              isExpanded: true,
              items: npsProvider.servers.map((server) {
                return DropdownMenuItem<NPSServer>(
                  value: server,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: server.active ? Colors.green : Colors.grey,
                        child: Text(
                          server.name.isNotEmpty ? server.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          server.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!server.active) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Inactive',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              onChanged: (server) {
                setState(() {
                  _selectedServer = server;
                  _loadExistingData();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataEntrySection() {
    if (_selectedServer == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Select a server to enter NPS data',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NPS Data for ${_selectedServer!.name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addFeedbackEntry,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _feedbackEntries.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No feedback entries yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Click "Add Entry" to start',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _feedbackEntries.length,
                      itemBuilder: (context, index) {
                        return _buildFeedbackEntryCard(index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackEntryCard(int index) {
    final entry = _feedbackEntries[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Entry ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _removeFeedbackEntry(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Remove entry',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('NPS Score (0-10)', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: entry.score?.toString() ?? '',
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '0-10',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final score = int.tryParse(value);
                          if (score != null && score >= 0 && score <= 10) {
                            entry.score = score;
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Feedback Comments', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: entry.comment ?? '',
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Optional feedback...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          entry.comment = value.isEmpty ? null : value;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearAllEntries,
            child: const Text('Clear All'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Save Data'),
          ),
        ),
      ],
    );
  }

  void _selectMonth() async {
    debugPrint('🔘 Month selector tapped!');
    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        debugPrint('🔘 Opening month picker dialog...');
        return _MonthYearPickerDialog(
          initialDate: _selectedMonth,
        );
      },
    );

    if (selectedDate != null) {
      debugPrint('🔘 Month selected: $selectedDate');
      setState(() {
        _selectedMonth = selectedDate;
        _loadExistingData();
      });
    } else {
      debugPrint('🔘 Month selection cancelled');
    }
  }

  void _addFeedbackEntry() {
    setState(() {
      _feedbackEntries.add(NPSFeedbackEntry());
    });
  }

  void _removeFeedbackEntry(int index) {
    setState(() {
      _feedbackEntries.removeAt(index);
    });
  }

  void _clearAllEntries() {
    setState(() {
      _feedbackEntries.clear();
    });
  }

  void _loadExistingData() {
    // TODO: Load existing feedback data for the selected server and month
    // This would query the database for existing entries
  }

  Future<void> _saveData() async {
    if (_selectedServer == null || _feedbackEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a server and add at least one entry'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // final npsProvider = context.read<NPSProvider>();
      
      for (final entry in _feedbackEntries) {
        if (entry.score != null) {
          // Convert NPS score (0-10) to feedback type
          FeedbackType feedbackType;
          if (entry.score! >= 9) {
            feedbackType = FeedbackType.yes; // Promoters (9-10)
          } else if (entry.score! >= 7) {
            feedbackType = FeedbackType.maybe; // Passives (7-8)
          } else {
            feedbackType = FeedbackType.no; // Detractors (0-6)
          }
          
          final feedback = NPSFeedback(
            serverId: _selectedServer!.id!,
            feedbackType: feedbackType,
            feedbackDate: _selectedMonth,
            notes: entry.comment != null ? 'NPS Score: ${entry.score}/10. ${entry.comment}' : 'NPS Score: ${entry.score}/10',
          );
          
          // TODO: Add method to NPSProvider to save feedback
          // await npsProvider.addFeedback(feedback);
          debugPrint('Would save feedback: ${feedback.notes}');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NPS data prepared successfully! (Save functionality coming soon)'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear entries after successful save
      setState(() {
        _feedbackEntries.clear();
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error preparing data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

/// Helper class for managing feedback entries during data entry
class NPSFeedbackEntry {
  int? score;
  String? comment;
  
  NPSFeedbackEntry({this.score, this.comment});
}

class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const _MonthYearPickerDialog({
    required this.initialDate,
  });

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Month'),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Year selection
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedYear--;
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '$_selectedYear',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedYear++;
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Month selection grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(12, (index) {
                final monthIndex = index + 1;
                final monthNames = [
                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                ];
                
                return SizedBox(
                  width: 70,
                  height: 35,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedMonth = monthIndex;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedMonth == monthIndex
                          ? Theme.of(context).primaryColor
                          : null,
                      foregroundColor: _selectedMonth == monthIndex
                          ? Colors.white
                          : null,
                      padding: const EdgeInsets.all(4),
                    ),
                    child: Text(
                      monthNames[index],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final selectedDate = DateTime(_selectedYear, _selectedMonth, 1);
            Navigator.of(context).pop(selectedDate);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}