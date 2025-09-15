import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nps_filter_service.dart';

class NPSFilterSummaryWidget extends StatelessWidget {
  final VoidCallback? onClearFilters;
  final VoidCallback? onEditFilters;

  const NPSFilterSummaryWidget({
    super.key,
    this.onClearFilters,
    this.onEditFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NPSFilterService>(
      builder: (context, filterService, child) {
        if (!filterService.hasActiveFilters) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_alt,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Active Filters (${filterService.activeFilterCount})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onEditFilters,
                      icon: const Icon(Icons.edit, size: 16),
                      tooltip: 'Edit Filters',
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                    IconButton(
                      onPressed: onClearFilters,
                      icon: const Icon(Icons.clear, size: 16),
                      tooltip: 'Clear All Filters',
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildFilterSummaryChips(filterService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSummaryChips(NPSFilterService filterService) {
    final criteria = filterService.currentCriteria;
    final List<Widget> chips = [];

    // Date filter
    if (criteria.startDate != null || criteria.endDate != null) {
      String dateText;
      if (criteria.datePreset != null) {
        dateText = _getDatePresetLabel(criteria.datePreset!);
      } else {
        final start = criteria.startDate?.toString().substring(0, 10) ?? '';
        final end = criteria.endDate?.toString().substring(0, 10) ?? '';
        dateText = '$start to $end';
      }
      chips.add(_buildSummaryChip(
        Icons.date_range,
        'Date: $dateText',
        Colors.blue,
      ));
    }

    // Score category filter
    if (criteria.scoreCategory != ScoreCategory.all) {
      chips.add(_buildSummaryChip(
        _getScoreCategoryIcon(criteria.scoreCategory),
        _getScoreCategoryLabel(criteria.scoreCategory),
        _getScoreCategoryColor(criteria.scoreCategory),
      ));
    }

    // Score range filter
    if (criteria.minScore != null || criteria.maxScore != null) {
      final min = criteria.minScore ?? 0;
      final max = criteria.maxScore ?? 10;
      chips.add(_buildSummaryChip(
        Icons.score,
        'Score: $min-$max',
        Colors.purple,
      ));
    }

    // Server filter
    if (criteria.selectedServerIds.isNotEmpty) {
      chips.add(_buildSummaryChip(
        Icons.dns,
        'Servers: ${criteria.selectedServerIds.length}',
        Colors.orange,
      ));
    }

    // Feedback filter
    if (criteria.hasFeedback != null) {
      chips.add(_buildSummaryChip(
        Icons.comment,
        criteria.hasFeedback! ? 'With Feedback' : 'Without Feedback',
        criteria.hasFeedback! ? Colors.green : Colors.grey,
      ));
    }

    // Keywords filter
    if (criteria.feedbackKeywords.isNotEmpty) {
      chips.add(_buildSummaryChip(
        Icons.search,
        'Keywords: ${criteria.feedbackKeywords.join(", ")}',
        Colors.teal,
      ));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _buildSummaryChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
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
        return 'Custom Range';
    }
  }

  String _getScoreCategoryLabel(ScoreCategory category) {
    switch (category) {
      case ScoreCategory.all:
        return 'All Scores';
      case ScoreCategory.detractors:
        return 'Detractors';
      case ScoreCategory.passives:
        return 'Passives';
      case ScoreCategory.promoters:
        return 'Promoters';
    }
  }

  IconData _getScoreCategoryIcon(ScoreCategory category) {
    switch (category) {
      case ScoreCategory.all:
        return Icons.all_inclusive;
      case ScoreCategory.detractors:
        return Icons.thumb_down;
      case ScoreCategory.passives:
        return Icons.remove;
      case ScoreCategory.promoters:
        return Icons.thumb_up;
    }
  }

  Color _getScoreCategoryColor(ScoreCategory category) {
    switch (category) {
      case ScoreCategory.all:
        return Colors.grey;
      case ScoreCategory.detractors:
        return Colors.red;
      case ScoreCategory.passives:
        return Colors.amber;
      case ScoreCategory.promoters:
        return Colors.green;
    }
  }
}