import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nps_filter_service.dart';
import '../providers/nps_provider.dart';

class NPSFilterWidget extends StatefulWidget {
  final VoidCallback? onFiltersChanged;

  const NPSFilterWidget({
    super.key,
    this.onFiltersChanged,
  });

  @override
  State<NPSFilterWidget> createState() => _NPSFilterWidgetState();
}

class _NPSFilterWidgetState extends State<NPSFilterWidget> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _presetNameController = TextEditingController();
  final TextEditingController _presetDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _keywordController.dispose();
    _presetNameController.dispose();
    _presetDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NPSFilterService>(
      builder: (context, filterService, child) {
        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(filterService),
              if (filterService.hasActiveFilters) _buildActiveFiltersChips(filterService),
              _buildFilterTabs(),
              SizedBox(
                height: 400,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDateTimeFilters(filterService),
                    _buildScoreFilters(filterService),
                    _buildServerFilters(filterService),
                    _buildAdvancedFilters(filterService),
                  ],
                ),
              ),
              _buildActions(filterService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(NPSFilterService filterService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 24),
          const SizedBox(width: 8),
          const Text(
            'Advanced Filters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (filterService.hasActiveFilters) 
            Chip(
              label: Text('${filterService.activeFilterCount} active'),
              backgroundColor: Theme.of(context).primaryColor,
              labelStyle: const TextStyle(color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips(NPSFilterService filterService) {
    final criteria = filterService.currentCriteria;
    final List<Widget> chips = [];

    if (criteria.datePreset != null) {
      chips.add(_buildFilterChip(
        'Date: ${_getDatePresetLabel(criteria.datePreset!)}',
        () => filterService.updateCriteria(datePreset: null, startDate: null, endDate: null),
      ));
    }

    if (criteria.scoreCategory != ScoreCategory.all) {
      chips.add(_buildFilterChip(
        'Category: ${_getScoreCategoryLabel(criteria.scoreCategory)}',
        () => filterService.updateCriteria(scoreCategory: ScoreCategory.all),
      ));
    }

    if (criteria.minScore != null || criteria.maxScore != null) {
      final min = criteria.minScore ?? 0;
      final max = criteria.maxScore ?? 10;
      chips.add(_buildFilterChip(
        'Score: $min-$max',
        () => filterService.updateCriteria(minScore: null, maxScore: null),
      ));
    }

    if (criteria.selectedServerIds.isNotEmpty) {
      chips.add(_buildFilterChip(
        'Servers: ${criteria.selectedServerIds.length}',
        () => filterService.updateCriteria(selectedServerIds: []),
      ));
    }

    if (criteria.hasFeedback != null) {
      chips.add(_buildFilterChip(
        criteria.hasFeedback! ? 'With Feedback' : 'Without Feedback',
        () => filterService.updateCriteria(hasFeedback: null),
      ));
    }

    if (criteria.feedbackKeywords.isNotEmpty) {
      chips.add(_buildFilterChip(
        'Keywords: ${criteria.feedbackKeywords.length}',
        () => filterService.updateCriteria(feedbackKeywords: []),
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: chips,
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
    );
  }

  Widget _buildFilterTabs() {
    return TabBar(
      controller: _tabController,
      labelColor: Theme.of(context).primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Theme.of(context).primaryColor,
      tabs: const [
        Tab(icon: Icon(Icons.date_range), text: 'Date & Time'),
        Tab(icon: Icon(Icons.star), text: 'Scores'),
        Tab(icon: Icon(Icons.dns), text: 'Servers'),
        Tab(icon: Icon(Icons.tune), text: 'Advanced'),
      ],
    );
  }

  Widget _buildDateTimeFilters(NPSFilterService filterService) {
    final criteria = filterService.currentCriteria;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Date Range Presets', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: DateRangePreset.values.where((p) => p != DateRangePreset.custom).map((preset) {
              final isSelected = criteria.datePreset == preset;
              return FilterChip(
                label: Text(_getDatePresetLabel(preset)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    filterService.setDateRangePreset(preset);
                    widget.onFiltersChanged?.call();
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Custom Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, true, filterService),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      criteria.startDate?.toString().substring(0, 10) ?? 'Select date',
                      style: TextStyle(
                        color: criteria.startDate != null ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, false, filterService),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      criteria.endDate?.toString().substring(0, 10) ?? 'Select date',
                      style: TextStyle(
                        color: criteria.endDate != null ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreFilters(NPSFilterService filterService) {
    final criteria = filterService.currentCriteria;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Score Categories', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ScoreCategory.values.map((category) {
              final isSelected = criteria.scoreCategory == category;
              return FilterChip(
                label: Text(_getScoreCategoryLabel(category)),
                selected: isSelected,
                onSelected: (selected) {
                  filterService.updateCriteria(
                    scoreCategory: selected ? category : ScoreCategory.all,
                  );
                  widget.onFiltersChanged?.call();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Custom Score Range', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Min Score',
                    border: OutlineInputBorder(),
                  ),
                  value: criteria.minScore,
                  items: List.generate(11, (index) => 
                    DropdownMenuItem(value: index, child: Text(index.toString()))
                  ),
                  onChanged: (value) {
                    filterService.updateCriteria(minScore: value);
                    widget.onFiltersChanged?.call();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Max Score',
                    border: OutlineInputBorder(),
                  ),
                  value: criteria.maxScore,
                  items: List.generate(11, (index) => 
                    DropdownMenuItem(value: index, child: Text(index.toString()))
                  ),
                  onChanged: (value) {
                    filterService.updateCriteria(maxScore: value);
                    widget.onFiltersChanged?.call();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServerFilters(NPSFilterService filterService) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Server Selection', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<NPSProvider>(
              builder: (context, npsProvider, child) {
                final servers = npsProvider.servers;
                final criteria = filterService.currentCriteria;
                
                if (servers.isEmpty) {
                  return const Center(
                    child: Text('No servers available'),
                  );
                }
                
                return ListView.builder(
                  itemCount: servers.length,
                  itemBuilder: (context, index) {
                    final server = servers[index];
                    final serverId = server.id.toString();
                    final isSelected = criteria.selectedServerIds.contains(serverId);
                    
                    return CheckboxListTile(
                      title: Text(server.name),
                      subtitle: Text('ID: ${server.id}'),
                      value: isSelected,
                      onChanged: (selected) {
                        final newSelection = List<String>.from(criteria.selectedServerIds);
                        if (selected == true) {
                          newSelection.add(serverId);
                        } else {
                          newSelection.remove(serverId);
                        }
                        filterService.updateCriteria(selectedServerIds: newSelection);
                        widget.onFiltersChanged?.call();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters(NPSFilterService filterService) {
    final criteria = filterService.currentCriteria;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Feedback Filters', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  label: const Text('With Feedback'),
                  selected: criteria.hasFeedback == true,
                  onSelected: (selected) {
                    filterService.updateCriteria(
                      hasFeedback: selected ? true : null,
                    );
                    widget.onFiltersChanged?.call();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilterChip(
                  label: const Text('Without Feedback'),
                  selected: criteria.hasFeedback == false,
                  onSelected: (selected) {
                    filterService.updateCriteria(
                      hasFeedback: selected ? false : null,
                    );
                    widget.onFiltersChanged?.call();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Feedback Keywords', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _keywordController,
            decoration: InputDecoration(
              labelText: 'Add keyword',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  final keyword = _keywordController.text.trim();
                  if (keyword.isNotEmpty) {
                    final newKeywords = List<String>.from(criteria.feedbackKeywords);
                    if (!newKeywords.contains(keyword)) {
                      newKeywords.add(keyword);
                      filterService.updateCriteria(feedbackKeywords: newKeywords);
                      widget.onFiltersChanged?.call();
                    }
                    _keywordController.clear();
                  }
                },
              ),
            ),
            onSubmitted: (value) {
              final keyword = value.trim();
              if (keyword.isNotEmpty) {
                final newKeywords = List<String>.from(criteria.feedbackKeywords);
                if (!newKeywords.contains(keyword)) {
                  newKeywords.add(keyword);
                  filterService.updateCriteria(feedbackKeywords: newKeywords);
                  widget.onFiltersChanged?.call();
                }
                _keywordController.clear();
              }
            },
          ),
          const SizedBox(height: 8),
          if (criteria.feedbackKeywords.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: criteria.feedbackKeywords.map((keyword) {
                return Chip(
                  label: Text(keyword),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    final newKeywords = List<String>.from(criteria.feedbackKeywords);
                    newKeywords.remove(keyword);
                    filterService.updateCriteria(feedbackKeywords: newKeywords);
                    widget.onFiltersChanged?.call();
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(NPSFilterService filterService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: filterService.hasActiveFilters 
              ? () {
                  filterService.resetFilters();
                  widget.onFiltersChanged?.call();
                }
              : null,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear All'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: filterService.hasActiveFilters 
              ? () => _showSavePresetDialog(context, filterService)
              : null,
            icon: const Icon(Icons.save),
            label: const Text('Save Preset'),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showPresetsDialog(context, filterService),
            icon: const Icon(Icons.bookmark),
            label: const Text('Load Preset'),
          ),
        ],
      ),
    );
  }

  void _selectDate(BuildContext context, bool isStartDate, NPSFilterService filterService) async {
    final initialDate = isStartDate 
      ? filterService.currentCriteria.startDate ?? DateTime.now()
      : filterService.currentCriteria.endDate ?? DateTime.now();
      
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (pickedDate != null) {
      if (isStartDate) {
        filterService.updateCriteria(startDate: pickedDate, datePreset: DateRangePreset.custom);
      } else {
        filterService.updateCriteria(endDate: pickedDate, datePreset: DateRangePreset.custom);
      }
      widget.onFiltersChanged?.call();
    }
  }

  void _showSavePresetDialog(BuildContext context, NPSFilterService filterService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Filter Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _presetNameController,
              decoration: const InputDecoration(
                labelText: 'Preset Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _presetDescController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_presetNameController.text.trim().isNotEmpty) {
                filterService.savePreset(
                  _presetNameController.text.trim(),
                  _presetDescController.text.trim(),
                );
                _presetNameController.clear();
                _presetDescController.clear();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preset saved successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPresetsDialog(BuildContext context, NPSFilterService filterService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Presets'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              const Text('Default Presets', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: filterService.getDefaultPresets().length,
                  itemBuilder: (context, index) {
                    final preset = filterService.getDefaultPresets()[index];
                    return ListTile(
                      title: Text(preset.name),
                      subtitle: Text(preset.description),
                      trailing: ElevatedButton(
                        onPressed: () {
                          filterService.applyCriteria(preset.criteria);
                          widget.onFiltersChanged?.call();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Apply'),
                      ),
                    );
                  },
                ),
              ),
              if (filterService.savedPresets.isNotEmpty) ...[
                const Divider(),
                const Text('Saved Presets', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: filterService.savedPresets.length,
                    itemBuilder: (context, index) {
                      final preset = filterService.savedPresets[index];
                      return ListTile(
                        title: Text(preset.name),
                        subtitle: Text(preset.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                filterService.applyCriteria(preset.criteria);
                                widget.onFiltersChanged?.call();
                                Navigator.of(context).pop();
                              },
                              child: const Text('Apply'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                filterService.deletePreset(preset.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getDatePresetLabel(DateRangePreset preset) {
    switch (preset) {
      case DateRangePreset.today:
        return 'Today';
      case DateRangePreset.yesterday:
        return 'Yesterday';
      case DateRangePreset.lastWeek:
        return 'Last Week';
      case DateRangePreset.lastMonth:
        return 'Last Month';
      case DateRangePreset.lastQuarter:
        return 'Last Quarter';
      case DateRangePreset.lastYear:
        return 'Last Year';
      case DateRangePreset.custom:
        return 'Custom';
    }
  }

  String _getScoreCategoryLabel(ScoreCategory category) {
    switch (category) {
      case ScoreCategory.all:
        return 'All Scores';
      case ScoreCategory.detractors:
        return 'Detractors (0-6)';
      case ScoreCategory.passives:
        return 'Passives (7-8)';
      case ScoreCategory.promoters:
        return 'Promoters (9-10)';
    }
  }
}