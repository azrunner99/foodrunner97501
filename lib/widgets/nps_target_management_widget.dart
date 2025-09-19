import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nps_benchmarking_service.dart';

class NPSTargetManagementWidget extends StatefulWidget {
  const NPSTargetManagementWidget({super.key});

  @override
  State<NPSTargetManagementWidget> createState() =>
      _NPSTargetManagementWidgetState();
}

class _NPSTargetManagementWidgetState extends State<NPSTargetManagementWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetNPSController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 90));
  String _selectedCategory = 'Quarterly';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetNPSController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NPSBenchmarkingService>(
      builder: (context, benchmarkService, child) {
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildExistingTargets(benchmarkService),
                const SizedBox(height: 20),
                _buildAddTargetForm(benchmarkService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.flag,
          size: 28,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 12),
        Text(
          'Performance Targets',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
      ],
    );
  }

  Widget _buildExistingTargets(NPSBenchmarkingService service) {
    final targets = service.performanceTargets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Targets',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (targets.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Text(
                'No performance targets set',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...targets.map((target) => _buildTargetCard(target, service)),
      ],
    );
  }

  Widget _buildTargetCard(
      PerformanceTarget target, NPSBenchmarkingService service) {
    final daysUntilTarget = target.targetDate.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilTarget < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: target.isActive
            ? (isOverdue
                ? Colors.red.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1))
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: target.isActive
              ? (isOverdue
                  ? Colors.red.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.3))
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      target.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editTarget(target, service);
                      break;
                    case 'delete':
                      _deleteTarget(target, service);
                      break;
                    case 'toggle':
                      _toggleTarget(target, service);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          target.isActive ? Icons.pause : Icons.play_arrow,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(target.isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTargetInfo(
                'Target NPS',
                target.targetNPS.toStringAsFixed(1),
                Icons.flag,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildTargetInfo(
                'Category',
                target.category,
                Icons.category,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildTargetInfo(
                'Due Date',
                '${target.targetDate.day}/${target.targetDate.month}/${target.targetDate.year}',
                Icons.calendar_today,
                isOverdue ? Colors.red : Colors.orange,
              ),
              const SizedBox(width: 16),
              _buildTargetInfo(
                'Days Left',
                isOverdue ? 'Overdue' : daysUntilTarget.toString(),
                Icons.schedule,
                isOverdue ? Colors.red : Colors.grey,
              ),
            ],
          ),
          if (!target.isActive)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'INACTIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTargetInfo(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAddTargetForm(NPSBenchmarkingService service) {
    return ExpansionTile(
      title: const Text(
        'Add New Target',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      leading: const Icon(Icons.add_circle),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Target Name',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Q1 2025 Goal',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a target name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    hintText: 'Brief description of the target',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _targetNPSController,
                        decoration: const InputDecoration(
                          labelText: 'Target NPS Score',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., 25.0',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter target NPS';
                          }
                          final nps = double.tryParse(value);
                          if (nps == null || nps < -100 || nps > 100) {
                            return 'Enter valid NPS (-100 to 100)';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Daily', child: Text('Daily')),
                          DropdownMenuItem(
                              value: 'Weekly', child: Text('Weekly')),
                          DropdownMenuItem(
                              value: 'Monthly', child: Text('Monthly')),
                          DropdownMenuItem(
                              value: 'Quarterly', child: Text('Quarterly')),
                          DropdownMenuItem(
                              value: 'Annual', child: Text('Annual')),
                          DropdownMenuItem(
                              value: 'Competitive', child: Text('Competitive')),
                          DropdownMenuItem(
                              value: 'Custom', child: Text('Custom')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Target Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearForm,
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _addTarget(service),
                        child: const Text('Add Target'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addTarget(NPSBenchmarkingService service) {
    if (_formKey.currentState!.validate()) {
      final target = PerformanceTarget(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        targetNPS: double.parse(_targetNPSController.text),
        targetDate: _selectedDate,
        category: _selectedCategory,
      );

      service.addPerformanceTarget(target);
      _clearForm();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target added successfully')),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _targetNPSController.clear();
    setState(() {
      _selectedDate = DateTime.now().add(const Duration(days: 90));
      _selectedCategory = 'Quarterly';
    });
  }

  void _editTarget(PerformanceTarget target, NPSBenchmarkingService service) {
    // Pre-fill form with target data
    _nameController.text = target.name;
    _descriptionController.text = target.description;
    _targetNPSController.text = target.targetNPS.toString();
    setState(() {
      _selectedDate = target.targetDate;
      _selectedCategory = target.category;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Target'),
        content: SizedBox(
          width: double.maxFinite,
          child: _buildAddTargetForm(service),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearForm();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final updatedTarget = PerformanceTarget(
                  id: target.id,
                  name: _nameController.text.trim(),
                  description: _descriptionController.text.trim(),
                  targetNPS: double.parse(_targetNPSController.text),
                  targetDate: _selectedDate,
                  category: _selectedCategory,
                  isActive: target.isActive,
                  metadata: target.metadata,
                );

                service.updatePerformanceTarget(target.id, updatedTarget);
                _clearForm();
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Target updated successfully')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteTarget(PerformanceTarget target, NPSBenchmarkingService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Target'),
        content: Text('Are you sure you want to delete "${target.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              service.removePerformanceTarget(target.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Target deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleTarget(PerformanceTarget target, NPSBenchmarkingService service) {
    final updatedTarget = PerformanceTarget(
      id: target.id,
      name: target.name,
      description: target.description,
      targetNPS: target.targetNPS,
      targetDate: target.targetDate,
      category: target.category,
      isActive: !target.isActive,
      metadata: target.metadata,
    );

    service.updatePerformanceTarget(target.id, updatedTarget);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Target ${updatedTarget.isActive ? 'activated' : 'deactivated'}',
        ),
      ),
    );
  }
}
