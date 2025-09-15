import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/server.dart';
import '../models/nps_feedback.dart';
import '../providers/nps_provider.dart';

/// Widget for capturing guest feedback about servers
class FeedbackEntryWidget extends StatefulWidget {
  const FeedbackEntryWidget({super.key});
  
  @override
  State<FeedbackEntryWidget> createState() => _FeedbackEntryWidgetState();
}

class _FeedbackEntryWidgetState extends State<FeedbackEntryWidget> {
  final _formKey = GlobalKey<FormState>();
  final _salesAmountController = TextEditingController();
  final _tableNumberController = TextEditingController();
  final _guestCountController = TextEditingController();
  final _notesController = TextEditingController();
  
  NPSServer? _selectedServer;
  FeedbackType? _selectedFeedbackType;
  DateTime _feedbackDate = DateTime.now();
  ShiftPeriod? _selectedShiftPeriod;
  bool _isSubmitting = false;
  
  @override
  void dispose() {
    _salesAmountController.dispose();
    _tableNumberController.dispose();
    _guestCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _selectFeedbackDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _feedbackDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      helpText: 'Select feedback date',
    );
    
    if (selectedDate != null) {
      setState(() {
        _feedbackDate = selectedDate;
      });
    }
  }
  
  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedServer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a server'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_selectedFeedbackType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select feedback response'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final npsProvider = Provider.of<NPSProvider>(context, listen: false);
      
      final feedback = NPSFeedback(
        serverId: _selectedServer!.id!,
        feedbackType: _selectedFeedbackType!,
        feedbackDate: _feedbackDate,
        salesAmount: _salesAmountController.text.trim().isNotEmpty
            ? double.tryParse(_salesAmountController.text.trim())
            : null,
        tableNumber: _tableNumberController.text.trim().isNotEmpty
            ? int.tryParse(_tableNumberController.text.trim())
            : null,
        shiftPeriod: _selectedShiftPeriod,
        guestCount: _guestCountController.text.trim().isNotEmpty
            ? int.tryParse(_guestCountController.text.trim())
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
      
      final success = await npsProvider.submitFeedback(feedback);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Feedback submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _resetForm();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(npsProvider.errorMessage ?? 'Failed to submit feedback'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  void _resetForm() {
    setState(() {
      _selectedServer = null;
      _selectedFeedbackType = null;
      _feedbackDate = DateTime.now();
      _selectedShiftPeriod = null;
      _salesAmountController.clear();
      _tableNumberController.clear();
      _guestCountController.clear();
      _notesController.clear();
    });
    _formKey.currentState?.reset();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<NPSProvider>(
      builder: (context, npsProvider, child) {
        final activeServers = npsProvider.activeServers;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Guest Feedback Entry',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Server Selection
                  DropdownButtonFormField<NPSServer>(
                    value: _selectedServer,
                    decoration: const InputDecoration(
                      labelText: 'Server *',
                      border: OutlineInputBorder(),
                    ),
                    items: activeServers.map((server) {
                      return DropdownMenuItem(
                        value: server,
                        child: Text(server.name),
                      );
                    }).toList(),
                    onChanged: (server) {
                      setState(() {
                        _selectedServer = server;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a server';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Feedback Question and Response
                  const Text(
                    'Would you like to have the same server again?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<FeedbackType>(
                          title: const Text('Yes'),
                          value: FeedbackType.yes,
                          groupValue: _selectedFeedbackType,
                          onChanged: (value) {
                            setState(() {
                              _selectedFeedbackType = value;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<FeedbackType>(
                          title: const Text('Maybe'),
                          value: FeedbackType.maybe,
                          groupValue: _selectedFeedbackType,
                          onChanged: (value) {
                            setState(() {
                              _selectedFeedbackType = value;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<FeedbackType>(
                          title: const Text('No'),
                          value: FeedbackType.no,
                          groupValue: _selectedFeedbackType,
                          onChanged: (value) {
                            setState(() {
                              _selectedFeedbackType = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Feedback Date
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Feedback Date: ${_formatDate(_feedbackDate)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _selectFeedbackDate,
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Change Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Optional Fields
                  const Text(
                    'Additional Information (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _salesAmountController,
                          decoration: const InputDecoration(
                            labelText: 'Sales Amount',
                            hintText: '0.00',
                            prefixText: '\$',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final amount = double.tryParse(value.trim());
                              if (amount == null || amount < 0) {
                                return 'Enter valid amount';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _tableNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Table Number',
                            hintText: 'e.g., 12',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final table = int.tryParse(value.trim());
                              if (table == null || table <= 0) {
                                return 'Enter valid table';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<ShiftPeriod>(
                          value: _selectedShiftPeriod,
                          decoration: const InputDecoration(
                            labelText: 'Shift Period',
                            border: OutlineInputBorder(),
                          ),
                          items: ShiftPeriod.values.map((period) {
                            return DropdownMenuItem(
                              value: period,
                              child: Text(period.displayName),
                            );
                          }).toList(),
                          onChanged: (period) {
                            setState(() {
                              _selectedShiftPeriod = period;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _guestCountController,
                          decoration: const InputDecoration(
                            labelText: 'Guest Count',
                            hintText: 'e.g., 4',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final count = int.tryParse(value.trim());
                              if (count == null || count <= 0) {
                                return 'Enter valid count';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Additional comments...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 24),
                  
                  // Submit and Reset Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSubmitting
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Submitting...'),
                                  ],
                                )
                              : const Text(
                                  'Submit Feedback',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: _isSubmitting ? null : _resetForm,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Widget for displaying recent feedback entries
class RecentFeedbackWidget extends StatelessWidget {
  const RecentFeedbackWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<NPSProvider>(
      builder: (context, npsProvider, child) {
        final recentFeedback = npsProvider.recentFeedback;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Feedback (Last 30 Days)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (recentFeedback.isNotEmpty)
                      Chip(
                        label: Text('${recentFeedback.length} entries'),
                        backgroundColor: Colors.blue.shade100,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (recentFeedback.isEmpty)
                  const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No recent feedback',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: recentFeedback.length,
                      itemBuilder: (context, index) {
                        final feedback = recentFeedback[index];
                        final server = npsProvider.getServerById(feedback.serverId);
                        
                        return FeedbackListTile(
                          feedback: feedback,
                          serverName: server?.name ?? 'Unknown Server',
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// List tile for displaying individual feedback entries
class FeedbackListTile extends StatelessWidget {
  final NPSFeedback feedback;
  final String serverName;
  
  const FeedbackListTile({
    super.key,
    required this.feedback,
    required this.serverName,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getFeedbackColor(feedback.feedbackType),
          child: Icon(
            _getFeedbackIcon(feedback.feedbackType),
            color: Colors.white,
          ),
        ),
        title: Text(
          serverName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Response: ${feedback.feedbackType.displayName}'),
            Text('Date: ${_formatDate(feedback.feedbackDate)}'),
            if (feedback.salesAmount != null)
              Text('Sales: \$${feedback.salesAmount!.toStringAsFixed(2)}'),
            if (feedback.notes != null && feedback.notes!.isNotEmpty)
              Text(
                'Notes: ${feedback.notes!}',
                style: const TextStyle(fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (feedback.tableNumber != null)
              Text(
                'Table ${feedback.tableNumber}',
                style: const TextStyle(fontSize: 12),
              ),
            if (feedback.shiftPeriod != null)
              Text(
                feedback.shiftPeriod!.displayName,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
  
  Color _getFeedbackColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.yes:
        return Colors.green;
      case FeedbackType.maybe:
        return Colors.orange;
      case FeedbackType.no:
        return Colors.red;
    }
  }
  
  IconData _getFeedbackIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.yes:
        return Icons.thumb_up;
      case FeedbackType.maybe:
        return Icons.thumbs_up_down;
      case FeedbackType.no:
        return Icons.thumb_down;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}