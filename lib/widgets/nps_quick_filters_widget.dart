import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nps_filter_service.dart';

class NPSQuickFiltersWidget extends StatelessWidget {
  final VoidCallback? onFilterChanged;

  const NPSQuickFiltersWidget({
    super.key,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NPSFilterService>(
      builder: (context, filterService, child) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.speed, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Quick Filters',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (filterService.hasActiveFilters)
                      TextButton.icon(
                        onPressed: () {
                          filterService.resetFilters();
                          onFilterChanged?.call();
                        },
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildQuickFilterChips(filterService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickFilterChips(NPSFilterService filterService) {
    final quickFilters = [
      QuickFilter(
        label: 'Today',
        icon: Icons.today,
        action: () {
          filterService.setDateRangePreset(DateRangePreset.today);
          onFilterChanged?.call();
        },
        isActive: filterService.currentCriteria.datePreset == DateRangePreset.today,
      ),
      QuickFilter(
        label: 'This Week',
        icon: Icons.date_range,
        action: () {
          filterService.setDateRangePreset(DateRangePreset.lastWeek);
          onFilterChanged?.call();
        },
        isActive: filterService.currentCriteria.datePreset == DateRangePreset.lastWeek,
      ),
      QuickFilter(
        label: 'Detractors',
        icon: Icons.thumb_down,
        color: Colors.red,
        action: () {
          filterService.updateCriteria(scoreCategory: ScoreCategory.detractors);
          onFilterChanged?.call();
        },
        isActive: filterService.currentCriteria.scoreCategory == ScoreCategory.detractors,
      ),
      QuickFilter(
        label: 'Promoters',
        icon: Icons.thumb_up,
        color: Colors.green,
        action: () {
          filterService.updateCriteria(scoreCategory: ScoreCategory.promoters);
          onFilterChanged?.call();
        },
        isActive: filterService.currentCriteria.scoreCategory == ScoreCategory.promoters,
      ),
      QuickFilter(
        label: 'With Feedback',
        icon: Icons.comment,
        action: () {
          filterService.updateCriteria(hasFeedback: true);
          onFilterChanged?.call();
        },
        isActive: filterService.currentCriteria.hasFeedback == true,
      ),
      QuickFilter(
        label: 'Critical (0-3)',
        icon: Icons.warning,
        color: Colors.orange,
        action: () {
          filterService.updateCriteria(minScore: 0, maxScore: 3);
          onFilterChanged?.call();
        },
        isActive: filterService.currentCriteria.minScore == 0 && 
                  filterService.currentCriteria.maxScore == 3,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: quickFilters.map((filter) => _buildQuickFilterChip(filter)).toList(),
    );
  }

  Widget _buildQuickFilterChip(QuickFilter filter) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filter.icon,
            size: 16,
            color: filter.isActive 
              ? Colors.white 
              : (filter.color ?? Colors.grey[600]),
          ),
          const SizedBox(width: 4),
          Text(filter.label),
        ],
      ),
      selected: filter.isActive,
      onSelected: (_) => filter.action(),
      backgroundColor: filter.color?.withOpacity(0.1),
      selectedColor: filter.color ?? Colors.blue,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: filter.isActive 
          ? Colors.white 
          : (filter.color ?? Colors.grey[700]),
        fontWeight: filter.isActive ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class QuickFilter {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback action;
  final bool isActive;

  const QuickFilter({
    required this.label,
    required this.icon,
    required this.action,
    required this.isActive,
    this.color,
  });
}