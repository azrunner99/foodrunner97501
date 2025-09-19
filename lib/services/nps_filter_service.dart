import 'package:flutter/foundation.dart';
import '../models/nps_score_feedback.dart';

/// Enum for different filter types
enum FilterType {
  dateRange,
  scoreCategory,
  serverGroup,
  feedbackPresence,
  userLocation,
  custom
}

/// Enum for score categories
enum ScoreCategory {
  all,
  detractors, // 0-6
  passives, // 7-8
  promoters // 9-10
}

/// Enum for predefined date ranges
enum DateRangePreset {
  today,
  yesterday,
  lastWeek,
  lastMonth,
  lastQuarter,
  lastYear,
  custom
}

/// Filter criteria for NPS data
class NPSFilterCriteria {
  // Date filtering
  DateTime? startDate;
  DateTime? endDate;
  DateRangePreset? datePreset;

  // Score filtering
  ScoreCategory scoreCategory;
  int? minScore;
  int? maxScore;

  // Server filtering
  List<String> selectedServerIds;
  List<String> selectedServerGroups;

  // Feedback filtering
  bool? hasFeedback;
  List<String> feedbackKeywords;

  // Location filtering
  List<String> selectedLocations;

  // Custom filters
  Map<String, dynamic> customFilters;

  NPSFilterCriteria({
    this.startDate,
    this.endDate,
    this.datePreset,
    this.scoreCategory = ScoreCategory.all,
    this.minScore,
    this.maxScore,
    this.selectedServerIds = const [],
    this.selectedServerGroups = const [],
    this.hasFeedback,
    this.feedbackKeywords = const [],
    this.selectedLocations = const [],
    this.customFilters = const {},
  });

  /// Create a copy with updated values
  NPSFilterCriteria copyWith({
    DateTime? startDate,
    DateTime? endDate,
    DateRangePreset? datePreset,
    ScoreCategory? scoreCategory,
    int? minScore,
    int? maxScore,
    List<String>? selectedServerIds,
    List<String>? selectedServerGroups,
    bool? hasFeedback,
    List<String>? feedbackKeywords,
    List<String>? selectedLocations,
    Map<String, dynamic>? customFilters,
  }) {
    return NPSFilterCriteria(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      datePreset: datePreset ?? this.datePreset,
      scoreCategory: scoreCategory ?? this.scoreCategory,
      minScore: minScore ?? this.minScore,
      maxScore: maxScore ?? this.maxScore,
      selectedServerIds: selectedServerIds ?? this.selectedServerIds,
      selectedServerGroups: selectedServerGroups ?? this.selectedServerGroups,
      hasFeedback: hasFeedback ?? this.hasFeedback,
      feedbackKeywords: feedbackKeywords ?? this.feedbackKeywords,
      selectedLocations: selectedLocations ?? this.selectedLocations,
      customFilters: customFilters ?? this.customFilters,
    );
  }

  /// Check if any filters are active
  bool get hasActiveFilters {
    return startDate != null ||
        endDate != null ||
        scoreCategory != ScoreCategory.all ||
        minScore != null ||
        maxScore != null ||
        selectedServerIds.isNotEmpty ||
        selectedServerGroups.isNotEmpty ||
        hasFeedback != null ||
        feedbackKeywords.isNotEmpty ||
        selectedLocations.isNotEmpty ||
        customFilters.isNotEmpty;
  }

  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (startDate != null || endDate != null) count++;
    if (scoreCategory != ScoreCategory.all) count++;
    if (minScore != null || maxScore != null) count++;
    if (selectedServerIds.isNotEmpty) count++;
    if (selectedServerGroups.isNotEmpty) count++;
    if (hasFeedback != null) count++;
    if (feedbackKeywords.isNotEmpty) count++;
    if (selectedLocations.isNotEmpty) count++;
    if (customFilters.isNotEmpty) count++;
    return count;
  }

  /// Reset all filters
  void reset() {
    startDate = null;
    endDate = null;
    datePreset = null;
    scoreCategory = ScoreCategory.all;
    minScore = null;
    maxScore = null;
    selectedServerIds = [];
    selectedServerGroups = [];
    hasFeedback = null;
    feedbackKeywords = [];
    selectedLocations = [];
    customFilters = {};
  }
}

/// Predefined filter presets
class FilterPreset {
  final String id;
  final String name;
  final String description;
  final NPSFilterCriteria criteria;
  final bool isDefault;

  const FilterPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.criteria,
    this.isDefault = false,
  });
}

/// Service for managing NPS data filtering
class NPSFilterService extends ChangeNotifier {
  NPSFilterCriteria _currentCriteria = NPSFilterCriteria();
  final List<FilterPreset> _savedPresets = [];

  // Getters
  NPSFilterCriteria get currentCriteria => _currentCriteria;
  List<FilterPreset> get savedPresets => List.unmodifiable(_savedPresets);
  bool get hasActiveFilters => _currentCriteria.hasActiveFilters;
  int get activeFilterCount => _currentCriteria.activeFilterCount;

  /// Apply new filter criteria
  void applyCriteria(NPSFilterCriteria criteria) {
    _currentCriteria = criteria;
    notifyListeners();
  }

  /// Update specific filter criteria
  void updateCriteria({
    DateTime? startDate,
    DateTime? endDate,
    DateRangePreset? datePreset,
    ScoreCategory? scoreCategory,
    int? minScore,
    int? maxScore,
    List<String>? selectedServerIds,
    List<String>? selectedServerGroups,
    bool? hasFeedback,
    List<String>? feedbackKeywords,
    List<String>? selectedLocations,
    Map<String, dynamic>? customFilters,
  }) {
    _currentCriteria = _currentCriteria.copyWith(
      startDate: startDate,
      endDate: endDate,
      datePreset: datePreset,
      scoreCategory: scoreCategory,
      minScore: minScore,
      maxScore: maxScore,
      selectedServerIds: selectedServerIds,
      selectedServerGroups: selectedServerGroups,
      hasFeedback: hasFeedback,
      feedbackKeywords: feedbackKeywords,
      selectedLocations: selectedLocations,
      customFilters: customFilters,
    );
    notifyListeners();
  }

  /// Set date range preset
  void setDateRangePreset(DateRangePreset preset) {
    final now = DateTime.now();
    DateTime? start, end;

    switch (preset) {
      case DateRangePreset.today:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DateRangePreset.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        end = DateTime(
            yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case DateRangePreset.lastWeek:
        start = now.subtract(Duration(days: now.weekday - 1 + 7));
        end = now.subtract(Duration(days: now.weekday - 1 + 1));
        break;
      case DateRangePreset.lastMonth:
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case DateRangePreset.lastQuarter:
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final quarterStart = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
        start = DateTime(quarterStart.year, quarterStart.month - 3, 1);
        end = DateTime(quarterStart.year, quarterStart.month, 0, 23, 59, 59);
        break;
      case DateRangePreset.lastYear:
        start = DateTime(now.year - 1, 1, 1);
        end = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        break;
      case DateRangePreset.custom:
        // Don't set dates for custom range
        break;
    }

    updateCriteria(
      startDate: start,
      endDate: end,
      datePreset: preset,
    );
  }

  /// Reset all filters
  void resetFilters() {
    _currentCriteria.reset();
    notifyListeners();
  }

  /// Save current criteria as preset
  void savePreset(String name, String description) {
    final preset = FilterPreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      criteria: NPSFilterCriteria(
        startDate: _currentCriteria.startDate,
        endDate: _currentCriteria.endDate,
        datePreset: _currentCriteria.datePreset,
        scoreCategory: _currentCriteria.scoreCategory,
        minScore: _currentCriteria.minScore,
        maxScore: _currentCriteria.maxScore,
        selectedServerIds: List.from(_currentCriteria.selectedServerIds),
        selectedServerGroups: List.from(_currentCriteria.selectedServerGroups),
        hasFeedback: _currentCriteria.hasFeedback,
        feedbackKeywords: List.from(_currentCriteria.feedbackKeywords),
        selectedLocations: List.from(_currentCriteria.selectedLocations),
        customFilters: Map.from(_currentCriteria.customFilters),
      ),
    );

    _savedPresets.add(preset);
    notifyListeners();
  }

  /// Load preset
  void loadPreset(String presetId) {
    final preset = _savedPresets.firstWhere((p) => p.id == presetId);
    applyCriteria(preset.criteria);
  }

  /// Delete preset
  void deletePreset(String presetId) {
    _savedPresets.removeWhere((p) => p.id == presetId);
    notifyListeners();
  }

  /// Filter NPS feedback data based on current criteria
  List<NPSScoreFeedback> filterFeedback(List<NPSScoreFeedback> allFeedback) {
    return allFeedback.where((feedback) {
      // Date filtering
      if (_currentCriteria.startDate != null) {
        if (feedback.submissionDate.isBefore(_currentCriteria.startDate!)) {
          return false;
        }
      }
      if (_currentCriteria.endDate != null) {
        if (feedback.submissionDate.isAfter(_currentCriteria.endDate!)) {
          return false;
        }
      }

      // Score category filtering
      if (_currentCriteria.scoreCategory != ScoreCategory.all) {
        switch (_currentCriteria.scoreCategory) {
          case ScoreCategory.detractors:
            if (feedback.score > 6) return false;
            break;
          case ScoreCategory.passives:
            if (feedback.score < 7 || feedback.score > 8) return false;
            break;
          case ScoreCategory.promoters:
            if (feedback.score < 9) return false;
            break;
          case ScoreCategory.all:
            break;
        }
      }

      // Score range filtering
      if (_currentCriteria.minScore != null) {
        if (feedback.score < _currentCriteria.minScore!) return false;
      }
      if (_currentCriteria.maxScore != null) {
        if (feedback.score > _currentCriteria.maxScore!) return false;
      }

      // Server filtering
      if (_currentCriteria.selectedServerIds.isNotEmpty) {
        if (!_currentCriteria.selectedServerIds
            .contains(feedback.serverId.toString())) {
          return false;
        }
      }

      // Feedback presence filtering
      if (_currentCriteria.hasFeedback != null) {
        final hasFeedback = feedback.comment?.isNotEmpty ?? false;
        if (_currentCriteria.hasFeedback! != hasFeedback) {
          return false;
        }
      }

      // Feedback keyword filtering
      if (_currentCriteria.feedbackKeywords.isNotEmpty) {
        if (feedback.comment == null || feedback.comment!.isEmpty) {
          return false;
        }
        final feedbackLower = feedback.comment!.toLowerCase();
        final hasKeyword = _currentCriteria.feedbackKeywords
            .any((keyword) => feedbackLower.contains(keyword.toLowerCase()));
        if (!hasKeyword) return false;
      }

      return true;
    }).toList();
  }

  /// Get default filter presets
  List<FilterPreset> getDefaultPresets() {
    return [
      FilterPreset(
        id: 'detractors_last_week',
        name: 'Detractors - Last Week',
        description: 'All detractors (0-6) from the past week',
        criteria: NPSFilterCriteria(
          scoreCategory: ScoreCategory.detractors,
          datePreset: DateRangePreset.lastWeek,
        ),
        isDefault: true,
      ),
      FilterPreset(
        id: 'promoters_last_month',
        name: 'Promoters - Last Month',
        description: 'All promoters (9-10) from the past month',
        criteria: NPSFilterCriteria(
          scoreCategory: ScoreCategory.promoters,
          datePreset: DateRangePreset.lastMonth,
        ),
        isDefault: true,
      ),
      FilterPreset(
        id: 'with_feedback_today',
        name: 'Feedback Today',
        description: 'All responses with feedback from today',
        criteria: NPSFilterCriteria(
          hasFeedback: true,
          datePreset: DateRangePreset.today,
        ),
        isDefault: true,
      ),
      FilterPreset(
        id: 'critical_scores',
        name: 'Critical Scores',
        description: 'Very low scores (0-3) that need attention',
        criteria: NPSFilterCriteria(
          minScore: 0,
          maxScore: 3,
        ),
        isDefault: true,
      ),
    ];
  }
}
