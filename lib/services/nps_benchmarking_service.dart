import 'package:flutter/foundation.dart';
import '../models/nps_score_feedback.dart';
import '../models/server.dart';

/// Industry benchmarking data and standards
class IndustryBenchmark {
  final String industry;
  final String category;
  final double averageNPS;
  final double excellentNPS;
  final double goodNPS;
  final double fairNPS;
  final double poorNPS;
  final String source;
  final DateTime lastUpdated;

  const IndustryBenchmark({
    required this.industry,
    required this.category,
    required this.averageNPS,
    required this.excellentNPS,
    required this.goodNPS,
    required this.fairNPS,
    required this.poorNPS,
    required this.source,
    required this.lastUpdated,
  });
}

/// Competitive benchmarking data
class CompetitiveBenchmark {
  final String competitorName;
  final String category;
  final double npsScore;
  final int responseCount;
  final String timeframe;
  final String source;
  final bool isVerified;

  const CompetitiveBenchmark({
    required this.competitorName,
    required this.category,
    required this.npsScore,
    required this.responseCount,
    required this.timeframe,
    required this.source,
    required this.isVerified,
  });
}

/// Performance target configuration
class PerformanceTarget {
  final String id;
  final String name;
  final String description;
  final double targetNPS;
  final DateTime targetDate;
  final String category;
  final bool isActive;
  final Map<String, dynamic> metadata;

  const PerformanceTarget({
    required this.id,
    required this.name,
    required this.description,
    required this.targetNPS,
    required this.targetDate,
    required this.category,
    this.isActive = true,
    this.metadata = const {},
  });
}

/// Benchmarking analysis result
class BenchmarkAnalysis {
  final double currentNPS;
  final double industryAverage;
  final String performanceRating;
  final double percentileRank;
  final List<String> strengths;
  final List<String> improvements;
  final List<PerformanceRecommendation> recommendations;
  final Map<String, double> competitorComparison;

  const BenchmarkAnalysis({
    required this.currentNPS,
    required this.industryAverage,
    required this.performanceRating,
    required this.percentileRank,
    required this.strengths,
    required this.improvements,
    required this.recommendations,
    required this.competitorComparison,
  });
}

/// Performance improvement recommendation
class PerformanceRecommendation {
  final String title;
  final String description;
  final String priority;
  final String category;
  final double potentialImpact;
  final int estimatedTimeframe;
  final List<String> actionItems;

  const PerformanceRecommendation({
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.potentialImpact,
    required this.estimatedTimeframe,
    required this.actionItems,
  });
}

/// Trend analysis data
class TrendAnalysis {
  final String period;
  final double startNPS;
  final double endNPS;
  final double change;
  final double changePercentage;
  final String trend;
  final List<String> factors;

  const TrendAnalysis({
    required this.period,
    required this.startNPS,
    required this.endNPS,
    required this.change,
    required this.changePercentage,
    required this.trend,
    required this.factors,
  });
}

/// Comprehensive NPS benchmarking service
class NPSBenchmarkingService extends ChangeNotifier {
  static final NPSBenchmarkingService _instance = NPSBenchmarkingService._internal();
  factory NPSBenchmarkingService() => _instance;
  NPSBenchmarkingService._internal();

  List<IndustryBenchmark> _industryBenchmarks = [];
  List<CompetitiveBenchmark> _competitiveBenchmarks = [];
  List<PerformanceTarget> _performanceTargets = [];
  BenchmarkAnalysis? _currentAnalysis;

  // Getters
  List<IndustryBenchmark> get industryBenchmarks => List.unmodifiable(_industryBenchmarks);
  List<CompetitiveBenchmark> get competitiveBenchmarks => List.unmodifiable(_competitiveBenchmarks);
  List<PerformanceTarget> get performanceTargets => List.unmodifiable(_performanceTargets);
  BenchmarkAnalysis? get currentAnalysis => _currentAnalysis;

  /// Initialize benchmarking service with industry data
  Future<void> initialize() async {
    await _loadIndustryBenchmarks();
    await _loadCompetitiveBenchmarks();
    await _loadPerformanceTargets();
    notifyListeners();
  }

  /// Load industry benchmarking data
  Future<void> _loadIndustryBenchmarks() async {
    _industryBenchmarks = [
      IndustryBenchmark(
        industry: 'Restaurant',
        category: 'Casual Dining',
        averageNPS: 15.0,
        excellentNPS: 50.0,
        goodNPS: 30.0,
        fairNPS: 10.0,
        poorNPS: -10.0,
        source: 'CustomerGauge Restaurant Industry Report 2024',
        lastUpdated: DateTime.now().subtract(const Duration(days: 30)),
      ),
      IndustryBenchmark(
        industry: 'Restaurant',
        category: 'Fast Casual',
        averageNPS: 25.0,
        excellentNPS: 60.0,
        goodNPS: 40.0,
        fairNPS: 20.0,
        poorNPS: 0.0,
        source: 'QSR Magazine NPS Study 2024',
        lastUpdated: DateTime.now().subtract(const Duration(days: 45)),
      ),
      IndustryBenchmark(
        industry: 'Restaurant',
        category: 'Fine Dining',
        averageNPS: 35.0,
        excellentNPS: 70.0,
        goodNPS: 50.0,
        fairNPS: 25.0,
        poorNPS: 10.0,
        source: 'Hospitality Research Group 2024',
        lastUpdated: DateTime.now().subtract(const Duration(days: 20)),
      ),
      IndustryBenchmark(
        industry: 'Hospitality',
        category: 'General',
        averageNPS: 20.0,
        excellentNPS: 55.0,
        goodNPS: 35.0,
        fairNPS: 15.0,
        poorNPS: -5.0,
        source: 'Global Hospitality Insights 2024',
        lastUpdated: DateTime.now().subtract(const Duration(days: 60)),
      ),
    ];
  }

  /// Load competitive benchmarking data
  Future<void> _loadCompetitiveBenchmarks() async {
    _competitiveBenchmarks = [
      CompetitiveBenchmark(
        competitorName: 'Competitor A',
        category: 'Casual Dining',
        npsScore: 22.0,
        responseCount: 1250,
        timeframe: 'Q3 2024',
        source: 'Industry Survey',
        isVerified: true,
      ),
      CompetitiveBenchmark(
        competitorName: 'Competitor B',
        category: 'Casual Dining',
        npsScore: 18.0,
        responseCount: 980,
        timeframe: 'Q3 2024',
        source: 'Third-party Analysis',
        isVerified: false,
      ),
      CompetitiveBenchmark(
        competitorName: 'Industry Leader',
        category: 'Casual Dining',
        npsScore: 45.0,
        responseCount: 3200,
        timeframe: 'Q3 2024',
        source: 'Public Reports',
        isVerified: true,
      ),
    ];
  }

  /// Load performance targets
  Future<void> _loadPerformanceTargets() async {
    _performanceTargets = [
      PerformanceTarget(
        id: 'q4_2024_target',
        name: 'Q4 2024 NPS Target',
        description: 'Achieve above-average industry performance',
        targetNPS: 20.0,
        targetDate: DateTime(2024, 12, 31),
        category: 'Quarterly',
      ),
      PerformanceTarget(
        id: 'annual_2025_target',
        name: '2025 Annual Target',
        description: 'Reach excellent performance tier',
        targetNPS: 35.0,
        targetDate: DateTime(2025, 12, 31),
        category: 'Annual',
      ),
      PerformanceTarget(
        id: 'competitor_benchmark',
        name: 'Competitor Parity',
        description: 'Match or exceed top competitor performance',
        targetNPS: 25.0,
        targetDate: DateTime(2025, 6, 30),
        category: 'Competitive',
      ),
    ];
  }

  /// Analyze current performance against benchmarks
  BenchmarkAnalysis analyzePerformance(List<NPSScoreFeedback> feedback, List<NPSServer> servers) {
    if (feedback.isEmpty) {
      return BenchmarkAnalysis(
        currentNPS: 0.0,
        industryAverage: _getIndustryAverage(),
        performanceRating: 'Insufficient Data',
        percentileRank: 0.0,
        strengths: [],
        improvements: ['Collect more feedback data'],
        recommendations: [],
        competitorComparison: {},
      );
    }

    final currentNPS = _calculateNPS(feedback);
    final industryAverage = _getIndustryAverage();
    final performanceRating = _getPerformanceRating(currentNPS);
    final percentileRank = _calculatePercentileRank(currentNPS);
    
    final analysis = BenchmarkAnalysis(
      currentNPS: currentNPS,
      industryAverage: industryAverage,
      performanceRating: performanceRating,
      percentileRank: percentileRank,
      strengths: _identifyStrengths(currentNPS, feedback),
      improvements: _identifyImprovements(currentNPS, feedback),
      recommendations: _generateRecommendations(currentNPS, feedback),
      competitorComparison: _getCompetitorComparison(currentNPS),
    );

    _currentAnalysis = analysis;
    notifyListeners();
    return analysis;
  }

  /// Calculate NPS score from feedback
  double _calculateNPS(List<NPSScoreFeedback> feedback) {
    if (feedback.isEmpty) return 0.0;

    final promoters = feedback.where((f) => f.score >= 9).length;
    final detractors = feedback.where((f) => f.score <= 6).length;
    final total = feedback.length;

    return ((promoters - detractors) / total * 100);
  }

  /// Get industry average NPS
  double _getIndustryAverage() {
    if (_industryBenchmarks.isEmpty) return 15.0;
    return _industryBenchmarks
        .map((b) => b.averageNPS)
        .reduce((a, b) => a + b) / _industryBenchmarks.length;
  }

  /// Get performance rating based on NPS score
  String _getPerformanceRating(double nps) {
    if (nps >= 50) return 'Excellent';
    if (nps >= 30) return 'Good';
    if (nps >= 10) return 'Fair';
    if (nps >= 0) return 'Needs Improvement';
    return 'Poor';
  }

  /// Calculate percentile rank against industry
  double _calculatePercentileRank(double nps) {
    // Simplified percentile calculation based on industry benchmarks
    if (nps >= 50) return 90.0;
    if (nps >= 30) return 75.0;
    if (nps >= 15) return 50.0;
    if (nps >= 0) return 25.0;
    return 10.0;
  }

  /// Identify performance strengths
  List<String> _identifyStrengths(double nps, List<NPSScoreFeedback> feedback) {
    final strengths = <String>[];
    
    if (nps > _getIndustryAverage()) {
      strengths.add('Above industry average performance');
    }
    
    final promoterRate = feedback.where((f) => f.score >= 9).length / feedback.length;
    if (promoterRate > 0.4) {
      strengths.add('High promoter rate (${(promoterRate * 100).toInt()}%)');
    }
    
    final detractorRate = feedback.where((f) => f.score <= 6).length / feedback.length;
    if (detractorRate < 0.2) {
      strengths.add('Low detractor rate (${(detractorRate * 100).toInt()}%)');
    }
    
    if (feedback.length > 100) {
      strengths.add('Strong response volume indicating good engagement');
    }
    
    return strengths;
  }

  /// Identify areas for improvement
  List<String> _identifyImprovements(double nps, List<NPSScoreFeedback> feedback) {
    final improvements = <String>[];
    
    if (nps < _getIndustryAverage()) {
      improvements.add('Below industry average - focus on overall experience');
    }
    
    final detractorRate = feedback.where((f) => f.score <= 6).length / feedback.length;
    if (detractorRate > 0.3) {
      improvements.add('High detractor rate - address service issues');
    }
    
    final passiveRate = feedback.where((f) => f.score >= 7 && f.score <= 8).length / feedback.length;
    if (passiveRate > 0.4) {
      improvements.add('High passive rate - convert passives to promoters');
    }
    
    if (feedback.length < 50) {
      improvements.add('Low response volume - increase feedback collection');
    }
    
    return improvements;
  }

  /// Generate performance recommendations
  List<PerformanceRecommendation> _generateRecommendations(double nps, List<NPSScoreFeedback> feedback) {
    final recommendations = <PerformanceRecommendation>[];
    
    if (nps < 20) {
      recommendations.add(PerformanceRecommendation(
        title: 'Service Recovery Program',
        description: 'Implement systematic approach to address detractor feedback',
        priority: 'High',
        category: 'Service',
        potentialImpact: 15.0,
        estimatedTimeframe: 90,
        actionItems: [
          'Train staff on service recovery techniques',
          'Establish feedback response protocols',
          'Create customer follow-up processes',
        ],
      ));
    }
    
    if (nps >= 20 && nps < 35) {
      recommendations.add(PerformanceRecommendation(
        title: 'Experience Enhancement',
        description: 'Focus on converting passive customers to promoters',
        priority: 'Medium',
        category: 'Experience',
        potentialImpact: 10.0,
        estimatedTimeframe: 120,
        actionItems: [
          'Identify key satisfaction drivers',
          'Enhance menu offerings',
          'Improve ambiance and atmosphere',
        ],
      ));
    }
    
    recommendations.add(PerformanceRecommendation(
      title: 'Feedback Collection Optimization',
      description: 'Increase response rates and feedback quality',
      priority: 'Medium',
      category: 'Data',
      potentialImpact: 5.0,
      estimatedTimeframe: 60,
      actionItems: [
        'Optimize feedback timing and channels',
        'Incentivize feedback participation',
        'Train staff on feedback importance',
      ],
    ));
    
    return recommendations;
  }

  /// Get competitor comparison data
  Map<String, double> _getCompetitorComparison(double currentNPS) {
    final comparison = <String, double>{};
    
    for (final competitor in _competitiveBenchmarks) {
      comparison[competitor.competitorName] = competitor.npsScore - currentNPS;
    }
    
    return comparison;
  }

  /// Get trend analysis for specified period
  TrendAnalysis getTrendAnalysis(List<NPSScoreFeedback> feedback, int days) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final midDate = now.subtract(Duration(days: days ~/ 2));
    
    final firstHalf = feedback.where((f) => 
      f.submissionDate.isAfter(startDate) && f.submissionDate.isBefore(midDate)
    ).toList();
    
    final secondHalf = feedback.where((f) => 
      f.submissionDate.isAfter(midDate) && f.submissionDate.isBefore(now)
    ).toList();
    
    final startNPS = _calculateNPS(firstHalf);
    final endNPS = _calculateNPS(secondHalf);
    final change = endNPS - startNPS;
    final changePercentage = startNPS != 0 ? (change / startNPS.abs()) * 100 : 0.0;
    
    String trend;
    if (change > 5) {
      trend = 'Improving';
    } else if (change < -5) {
      trend = 'Declining';
    } else {
      trend = 'Stable';
    }
    
    return TrendAnalysis(
      period: '${days} days',
      startNPS: startNPS,
      endNPS: endNPS,
      change: change,
      changePercentage: changePercentage,
      trend: trend,
      factors: _identifyTrendFactors(change),
    );
  }

  /// Identify factors contributing to trends
  List<String> _identifyTrendFactors(double change) {
    final factors = <String>[];
    
    if (change > 0) {
      factors.addAll([
        'Improved service quality',
        'Better staff training',
        'Menu enhancements',
        'Positive customer feedback loop',
      ]);
    } else if (change < 0) {
      factors.addAll([
        'Service quality issues',
        'Staff turnover impact',
        'Operational challenges',
        'Increased competition',
      ]);
    } else {
      factors.addAll([
        'Consistent performance',
        'Stable operations',
        'Balanced customer mix',
      ]);
    }
    
    return factors;
  }

  /// Add custom performance target
  void addPerformanceTarget(PerformanceTarget target) {
    _performanceTargets.add(target);
    notifyListeners();
  }

  /// Update performance target
  void updatePerformanceTarget(String targetId, PerformanceTarget updatedTarget) {
    final index = _performanceTargets.indexWhere((t) => t.id == targetId);
    if (index != -1) {
      _performanceTargets[index] = updatedTarget;
      notifyListeners();
    }
  }

  /// Remove performance target
  void removePerformanceTarget(String targetId) {
    _performanceTargets.removeWhere((t) => t.id == targetId);
    notifyListeners();
  }

  /// Get performance against targets
  Map<String, double> getTargetProgress(double currentNPS) {
    final progress = <String, double>{};
    
    for (final target in _performanceTargets.where((t) => t.isActive)) {
      final progressPercentage = (currentNPS / target.targetNPS * 100).clamp(0.0, 100.0);
      progress[target.name] = progressPercentage;
    }
    
    return progress;
  }

  /// Get industry benchmark for specific category
  IndustryBenchmark? getBenchmarkForCategory(String category) {
    return _industryBenchmarks.firstWhere(
      (b) => b.category.toLowerCase() == category.toLowerCase(),
      orElse: () => _industryBenchmarks.first,
    );
  }
}