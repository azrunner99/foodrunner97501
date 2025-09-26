import 'dart:math' as math;
import '../models/historical_nps_data.dart';
import '../services/historical_nps_aggregation_service.dart';
import '../utils/log.dart';

/// Service for tracking and analyzing performance timelines
class PerformanceTimelineService {
  static final PerformanceTimelineService _instance = PerformanceTimelineService._internal();
  factory PerformanceTimelineService() => _instance;
  PerformanceTimelineService._internal();

  static PerformanceTimelineService get instance => _instance;

  late HistoricalNPSAggregationService _aggregationService;
  final Map<String, HistoricalNPSData> _timelineCache = {};
  DateTime? _lastCacheUpdate;

  Future<void> initialize() async {
    _aggregationService = HistoricalNPSAggregationService.instance;
    await _aggregationService.initialize();
    d('[PerformanceTimelineService] Initialized');
  }

  /// Get performance timeline for a specific server
  Future<PerformanceTimeline?> getTimelineForServer(String serverId) async {
    try {
      d('[PerformanceTimelineService] Getting timeline for server: $serverId');
      
      // Check cache first
      if (_timelineCache.containsKey(serverId) && _isCacheValid()) {
        final historicalData = _timelineCache[serverId]!;
        return _buildTimeline(historicalData);
      }
      
      // Load fresh data
      final historicalData = await _aggregationService.getHistoricalDataForServer(serverId);
      if (historicalData == null) {
        d('[PerformanceTimelineService] No historical data found for server: $serverId');
        return null;
      }
      
      // Cache the data
      _timelineCache[serverId] = historicalData;
      _lastCacheUpdate = DateTime.now();
      
      return _buildTimeline(historicalData);
    } catch (e) {
      d('[PerformanceTimelineService] Error getting timeline for server $serverId: $e');
      return null;
    }
  }

  /// Get performance timelines for all servers
  Future<List<PerformanceTimeline>> getAllTimelines() async {
    try {
      d('[PerformanceTimelineService] Getting timelines for all servers');
      
      // Check if we need to refresh cache
      if (!_isCacheValid()) {
        await _refreshAllTimelines();
      }
      
      return _timelineCache.values.map((data) => _buildTimeline(data)).toList();
    } catch (e) {
      d('[PerformanceTimelineService] Error getting all timelines: $e');
      return [];
    }
  }

  /// Get performance comparison between servers
  Future<PerformanceComparison?> getPerformanceComparison(List<String> serverIds) async {
    try {
      d('[PerformanceTimelineService] Getting performance comparison for ${serverIds.length} servers');
      
      final timelines = <PerformanceTimeline>[];
      for (final serverId in serverIds) {
        final timeline = await getTimelineForServer(serverId);
        if (timeline != null) {
          timelines.add(timeline);
        }
      }
      
      if (timelines.length < 2) {
        d('[PerformanceTimelineService] Need at least 2 servers for comparison');
        return null;
      }
      
      return _buildPerformanceComparison(timelines);
    } catch (e) {
      d('[PerformanceTimelineService] Error getting performance comparison: $e');
      return null;
    }
  }

  /// Get performance insights for a specific server
  Future<List<PerformanceInsight>> getPerformanceInsights(String serverId) async {
    try {
      d('[PerformanceTimelineService] Getting performance insights for server: $serverId');
      
      final timeline = await getTimelineForServer(serverId);
      if (timeline == null) return [];
      
      final insights = <PerformanceInsight>[];
      
      // Trend insights
      if (timeline.trend.direction == TrendDirection.improving) {
        insights.add(PerformanceInsight(
          type: 'positive_trend',
          title: 'Performance Improving',
          description: timeline.trend.description,
          priority: 'medium',
          actionItems: ['Continue current practices', 'Share success strategies with team'],
          generatedDate: DateTime.now(),
          serverId: serverId,
        ));
      } else if (timeline.trend.direction == TrendDirection.declining) {
        insights.add(PerformanceInsight(
          type: 'negative_trend',
          title: 'Performance Declining',
          description: timeline.trend.description,
          priority: 'high',
          actionItems: ['Schedule coaching session', 'Identify improvement areas', 'Set performance goals'],
          generatedDate: DateTime.now(),
          serverId: serverId,
        ));
      }
      
      // Volatility insights
      if (timeline.volatility > 20.0) {
        insights.add(PerformanceInsight(
          type: 'high_volatility',
          title: 'Inconsistent Performance',
          description: 'Performance varies significantly month to month (${timeline.volatility.toStringAsFixed(1)} point standard deviation)',
          priority: 'medium',
          actionItems: ['Identify consistency factors', 'Develop performance stabilization plan'],
          generatedDate: DateTime.now(),
          serverId: serverId,
        ));
      }
      
      // Seasonal insights
      if (timeline.seasonalPattern != null) {
        final currentMonth = DateTime.now().month;
        final expected = timeline.seasonalPattern!.getExpectedPerformance(currentMonth);
        final current = timeline.mostRecentPerformance?.oneMonthNPS ?? 0.0;
        
        if (current > expected + 10.0) {
          insights.add(PerformanceInsight(
            type: 'seasonal_peak',
            title: 'Exceeding Seasonal Expectations',
            description: 'Current performance (${current.toStringAsFixed(1)}%) exceeds seasonal average (${expected.toStringAsFixed(1)}%)',
            priority: 'low',
            actionItems: ['Document successful strategies', 'Share with team'],
            generatedDate: DateTime.now(),
            serverId: serverId,
          ));
        } else if (current < expected - 10.0) {
          insights.add(PerformanceInsight(
            type: 'seasonal_low',
            title: 'Below Seasonal Expectations',
            description: 'Current performance (${current.toStringAsFixed(1)}%) below seasonal average (${expected.toStringAsFixed(1)}%)',
            priority: 'medium',
            actionItems: ['Review seasonal challenges', 'Adjust expectations', 'Provide additional support'],
            generatedDate: DateTime.now(),
            serverId: serverId,
          ));
        }
      }
      
      // Classification insights
      switch (timeline.classification) {
        case PerformanceClassification.elite:
          insights.add(PerformanceInsight(
            type: 'recognition',
            title: 'Elite Performer',
            description: 'Consistently high performance across all timeframes',
            priority: 'low',
            actionItems: ['Consider for leadership role', 'Mentor other team members'],
            generatedDate: DateTime.now(),
            serverId: serverId,
          ));
          break;
        case PerformanceClassification.critical:
          insights.add(PerformanceInsight(
            type: 'urgent_attention',
            title: 'Critical Performance Issues',
            description: 'Consistently poor performance requires immediate attention',
            priority: 'high',
            actionItems: ['Immediate coaching session', 'Performance improvement plan', 'Regular check-ins'],
            generatedDate: DateTime.now(),
            serverId: serverId,
          ));
          break;
        case PerformanceClassification.concerning:
          insights.add(PerformanceInsight(
            type: 'attention_needed',
            title: 'Performance Concerns',
            description: 'Performance trends or consistency issues need attention',
            priority: 'medium',
            actionItems: ['Schedule coaching session', 'Identify root causes', 'Develop improvement plan'],
            generatedDate: DateTime.now(),
            serverId: serverId,
          ));
          break;
        default:
          break;
      }
      
      d('[PerformanceTimelineService] Generated ${insights.length} insights for server: $serverId');
      return insights;
    } catch (e) {
      d('[PerformanceTimelineService] Error getting performance insights for server $serverId: $e');
      return [];
    }
  }

  /// Refresh all timeline data
  Future<void> _refreshAllTimelines() async {
    try {
      d('[PerformanceTimelineService] Refreshing all timeline data');
      
      final allHistoricalData = await _aggregationService.getAllHistoricalData();
      _timelineCache.clear();
      
      for (final data in allHistoricalData) {
        _timelineCache[data.serverId] = data;
      }
      
      _lastCacheUpdate = DateTime.now();
      d('[PerformanceTimelineService] Refreshed ${_timelineCache.length} timelines');
    } catch (e) {
      d('[PerformanceTimelineService] Error refreshing timelines: $e');
    }
  }

  /// Check if cache is still valid (5 minutes)
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!).inMinutes < 5;
  }

  /// Build performance timeline from historical data
  PerformanceTimeline _buildTimeline(HistoricalNPSData historicalData) {
    return PerformanceTimeline(
      serverId: historicalData.serverId,
      serverName: historicalData.serverName,
      monthlyData: historicalData.monthlyData,
      trend: historicalData.trend,
      volatility: historicalData.volatility,
      seasonalPattern: historicalData.seasonalPattern,
      classification: historicalData.classification,
      overallScore: historicalData.overallPerformanceScore,
      lastUpdated: historicalData.lastUpdated,
      totalMonths: historicalData.totalMonthsReported,
    );
  }

  /// Build performance comparison
  PerformanceComparison _buildPerformanceComparison(List<PerformanceTimeline> timelines) {
    // Sort by overall score
    timelines.sort((a, b) => b.overallScore.compareTo(a.overallScore));
    
    // Calculate statistics
    final scores = timelines.map((t) => t.overallScore).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores.map((s) => (s - mean) * (s - mean)).reduce((a, b) => a + b) / scores.length;
    final standardDeviation = math.sqrt(variance);
    
    return PerformanceComparison(
      timelines: timelines,
      averageScore: mean,
      standardDeviation: standardDeviation,
      topPerformer: timelines.first,
      bottomPerformer: timelines.last,
      comparisonDate: DateTime.now(),
    );
  }
}

/// Performance timeline data structure
class PerformanceTimeline {
  final String serverId;
  final String serverName;
  final List<MonthlyPerformance> monthlyData;
  final PerformanceTrend trend;
  final double volatility;
  final SeasonalPattern? seasonalPattern;
  final PerformanceClassification classification;
  final double overallScore;
  final DateTime lastUpdated;
  final int totalMonths;

  PerformanceTimeline({
    required this.serverId,
    required this.serverName,
    required this.monthlyData,
    required this.trend,
    required this.volatility,
    this.seasonalPattern,
    required this.classification,
    required this.overallScore,
    required this.lastUpdated,
    required this.totalMonths,
  });

  /// Get most recent performance
  MonthlyPerformance? get mostRecentPerformance {
    return monthlyData.isNotEmpty ? monthlyData.first : null;
  }

  /// Get performance for a specific month
  MonthlyPerformance? getPerformanceForMonth(DateTime month) {
    final targetMonth = DateTime(month.year, month.month);
    try {
      return monthlyData.firstWhere(
        (data) => data.month.year == targetMonth.year && data.month.month == targetMonth.month,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get performance trend over last N months
  TrendDirection getTrendOverMonths(int months) {
    if (monthlyData.length < 2) return TrendDirection.stable;
    
    final recentData = monthlyData.take(months).toList();
    if (recentData.length < 2) return TrendDirection.stable;
    
    final first = recentData.last.oneMonthNPS;
    final last = recentData.first.oneMonthNPS;
    final difference = last - first;
    
    if (difference > 5.0) return TrendDirection.improving;
    if (difference < -5.0) return TrendDirection.declining;
    return TrendDirection.stable;
  }
}

/// Performance comparison data structure
class PerformanceComparison {
  final List<PerformanceTimeline> timelines;
  final double averageScore;
  final double standardDeviation;
  final PerformanceTimeline topPerformer;
  final PerformanceTimeline bottomPerformer;
  final DateTime comparisonDate;

  PerformanceComparison({
    required this.timelines,
    required this.averageScore,
    required this.standardDeviation,
    required this.topPerformer,
    required this.bottomPerformer,
    required this.comparisonDate,
  });

  /// Get performance gap between top and bottom performers
  double get performanceGap => topPerformer.overallScore - bottomPerformer.overallScore;

  /// Get relative performance of a server
  double getRelativePerformance(String serverId) {
    final timeline = timelines.firstWhere((t) => t.serverId == serverId);
    return timeline.overallScore - averageScore;
  }
}

/// Performance insight data structure
class PerformanceInsight {
  final String type;
  final String title;
  final String description;
  final String priority;
  final List<String> actionItems;
  final DateTime generatedDate;
  final String serverId;

  PerformanceInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.actionItems,
    required this.generatedDate,
    required this.serverId,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'priority': priority,
      'actionItems': actionItems,
      'generatedDate': generatedDate.toIso8601String(),
      'serverId': serverId,
    };
  }

  factory PerformanceInsight.fromMap(Map<String, dynamic> map) {
    return PerformanceInsight(
      type: map['type'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      priority: map['priority'] as String,
      actionItems: List<String>.from(map['actionItems'] as List),
      generatedDate: DateTime.parse(map['generatedDate'] as String),
      serverId: map['serverId'] as String,
    );
  }
}
