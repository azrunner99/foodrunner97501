import 'dart:math' as math;
import '../app_state.dart';
import 'message_variety_engine.dart';

/// Analytics and optimization service for message performance
class MessageAnalyticsService {
  
  /// Analyze message engagement patterns for optimization
  static MessageAnalytics analyzeMessagePerformance(Map<String, ServerProfile> profiles) {
    final analytics = MessageAnalytics();
    
    // Aggregate data from all server profiles
    final Map<String, MessageMetrics> messageStats = {};
    
    for (final profile in profiles.values) {
      for (final entry in profile.messageEngagement.entries) {
        final message = entry.key;
        final engagement = entry.value;
        final usageCount = profile.messageUsageCount[message] ?? 0;
        final lastUsed = profile.messageLastUsed[message];
        
        if (!messageStats.containsKey(message)) {
          messageStats[message] = MessageMetrics(message: message);
        }
        
        final metrics = messageStats[message]!;
        metrics.totalShows += usageCount;
        metrics.totalEngagement += engagement;
        metrics.serverCount++;
        
        if (lastUsed != null) {
          if (metrics.lastShown == null || lastUsed.isAfter(metrics.lastShown!)) {
            metrics.lastShown = lastUsed;
          }
          if (metrics.firstShown == null || lastUsed.isBefore(metrics.firstShown!)) {
            metrics.firstShown = lastUsed;
          }
        }
      }
    }
    
    // Calculate derived metrics
    for (final metrics in messageStats.values) {
      metrics.avgEngagement = metrics.serverCount > 0 
        ? metrics.totalEngagement / metrics.serverCount 
        : 0.0;
      metrics.showsPerServer = metrics.serverCount > 0 
        ? metrics.totalShows / metrics.serverCount 
        : 0.0;
    }
    
    analytics.messageMetrics = messageStats;
    analytics.totalMessages = messageStats.length;
    analytics.totalShows = messageStats.values.fold(0, (sum, m) => sum + m.totalShows);
    analytics.avgEngagementGlobal = _calculateGlobalEngagement(messageStats.values);
    
    return analytics;
  }
  
  /// Identify top performing messages by category
  static Map<MessageCategory, List<String>> getTopPerformingMessages(
    MessageAnalytics analytics, 
    {int topCount = 10}
  ) {
    final categorizedMessages = <MessageCategory, List<MessageMetrics>>{};
    
    // Group messages by category (simplified categorization)
    for (final metrics in analytics.messageMetrics.values) {
      final category = _categorizeMessage(metrics.message);
      categorizedMessages.putIfAbsent(category, () => []).add(metrics);
    }
    
    // Sort each category by performance score and take top performers
    final topPerformers = <MessageCategory, List<String>>{};
    
    for (final entry in categorizedMessages.entries) {
      final category = entry.key;
      final messages = entry.value;
      
      // Sort by engagement score (weighted by usage frequency)
      messages.sort((a, b) {
        final scoreA = a.avgEngagement * math.log(a.totalShows + 1);
        final scoreB = b.avgEngagement * math.log(b.totalShows + 1);
        return scoreB.compareTo(scoreA);
      });
      
      topPerformers[category] = messages
        .take(topCount)
        .map((m) => m.message)
        .toList();
    }
    
    return topPerformers;
  }
  
  /// Identify underperforming messages that should be replaced
  static List<String> getUnderperformingMessages(
    MessageAnalytics analytics,
    {double engagementThreshold = 0.3}
  ) {
    return analytics.messageMetrics.values
      .where((m) => m.avgEngagement < engagementThreshold && m.totalShows >= 5)
      .map((m) => m.message)
      .toList();
  }
  
  /// Generate variety optimization recommendations
  static VarietyOptimization generateOptimizationRecommendations(
    MessageAnalytics analytics
  ) {
    final optimization = VarietyOptimization();
    
    // Identify staleness issues
    final now = DateTime.now();
    final staleMessages = analytics.messageMetrics.values
      .where((m) => m.lastShown != null && 
                   now.difference(m.lastShown!).inDays > 7 &&
                   m.totalShows < 3)
      .map((m) => m.message)
      .toList();
    
    // Identify overused messages
    final overusedMessages = analytics.messageMetrics.values
      .where((m) => m.showsPerServer > 10.0)
      .map((m) => m.message)
      .toList();
    
    // Identify high-engagement patterns
    final highEngagementMessages = analytics.messageMetrics.values
      .where((m) => m.avgEngagement > 0.8)
      .toList();
    
    // Extract common patterns from high-engagement messages
    final patterns = _extractEngagementPatterns(highEngagementMessages);
    
    optimization.staleMessages = staleMessages;
    optimization.overusedMessages = overusedMessages;
    optimization.successPatterns = patterns;
    optimization.recommendedCategoryBalance = _calculateOptimalCategoryBalance(analytics);
    
    return optimization;
  }
  
  /// Calculate global engagement average
  static double _calculateGlobalEngagement(Iterable<MessageMetrics> metrics) {
    if (metrics.isEmpty) return 0.0;
    
    double totalWeightedEngagement = 0.0;
    int totalWeight = 0;
    
    for (final metric in metrics) {
      totalWeightedEngagement += metric.avgEngagement * metric.totalShows;
      totalWeight += metric.totalShows;
    }
    
    return totalWeight > 0 ? totalWeightedEngagement / totalWeight : 0.0;
  }
  
  /// Simple message categorization based on content
  static MessageCategory _categorizeMessage(String message) {
    final lower = message.toLowerCase();
    
    if (lower.contains('speed') || lower.contains('fast') || lower.contains('quick') || 
        lower.contains('lightning') || lower.contains('rapid')) {
      return MessageCategory.speedBased;
    }
    
    if (lower.contains('win') || lower.contains('lead') || lower.contains('beat') || 
        lower.contains('champion') || lower.contains('dominating')) {
      return MessageCategory.competitiveBased;
    }
    
    if (lower.contains('perfect') || lower.contains('flawless') || lower.contains('precision') || 
        lower.contains('mastery') || lower.contains('excellence')) {
      return MessageCategory.consistencyBased;
    }
    
    return MessageCategory.achievementBased; // Default category
  }
  
  /// Extract patterns from high-engagement messages
  static List<String> _extractEngagementPatterns(List<MessageMetrics> highEngagement) {
    final patterns = <String>[];
    
    // Analyze emoji usage
    final emojiUsage = <String, int>{};
    final keywordUsage = <String, int>{};
    
    for (final metric in highEngagement) {
      final message = metric.message.toLowerCase();
      
      // Count emojis
      for (final char in message.runes) {
        final emoji = String.fromCharCode(char);
        if (_isEmoji(emoji)) {
          emojiUsage[emoji] = (emojiUsage[emoji] ?? 0) + 1;
        }
      }
      
      // Count keywords
      final words = message.split(RegExp(r'[^a-zA-Z]+'));
      for (final word in words) {
        if (word.length > 3) {
          keywordUsage[word] = (keywordUsage[word] ?? 0) + 1;
        }
      }
    }
    
    // Identify top patterns
    final topEmojis = emojiUsage.entries
      .where((e) => e.value >= 3)
      .map((e) => 'Emoji: ${e.key} (${e.value} uses)')
      .toList();
    
    final topKeywords = keywordUsage.entries
      .where((e) => e.value >= 3)
      .map((e) => 'Keyword: ${e.key} (${e.value} uses)')
      .toList();
    
    patterns.addAll(topEmojis);
    patterns.addAll(topKeywords);
    
    return patterns;
  }
  
  /// Calculate optimal category balance based on engagement
  static Map<MessageCategory, double> _calculateOptimalCategoryBalance(MessageAnalytics analytics) {
    final categoryEngagement = <MessageCategory, List<double>>{};
    
    // Group engagement scores by category
    for (final metric in analytics.messageMetrics.values) {
      final category = _categorizeMessage(metric.message);
      categoryEngagement.putIfAbsent(category, () => []).add(metric.avgEngagement);
    }
    
    // Calculate average engagement per category
    final categoryAverage = <MessageCategory, double>{};
    for (final entry in categoryEngagement.entries) {
      final scores = entry.value;
      categoryAverage[entry.key] = scores.isEmpty ? 0.0 : 
        scores.reduce((a, b) => a + b) / scores.length;
    }
    
    // Normalize to percentages (higher engagement = higher recommended percentage)
    final totalEngagement = categoryAverage.values.fold(0.0, (a, b) => a + b);
    final balance = <MessageCategory, double>{};
    
    if (totalEngagement > 0) {
      for (final entry in categoryAverage.entries) {
        balance[entry.key] = entry.value / totalEngagement;
      }
    }
    
    return balance;
  }
  
  /// Simple emoji detection
  static bool _isEmoji(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 0x1F600 && code <= 0x1F64F) || // Emoticons
           (code >= 0x1F300 && code <= 0x1F5FF) || // Misc Symbols
           (code >= 0x1F680 && code <= 0x1F6FF) || // Transport
           (code >= 0x2600 && code <= 0x26FF) ||   // Misc symbols
           (code >= 0x2700 && code <= 0x27BF);     // Dingbats
  }
}

/// Analytics data structure
class MessageAnalytics {
  Map<String, MessageMetrics> messageMetrics = {};
  int totalMessages = 0;
  int totalShows = 0;
  double avgEngagementGlobal = 0.0;
  DateTime? lastAnalysis;
  
  MessageAnalytics() {
    lastAnalysis = DateTime.now();
  }
}

/// Individual message performance metrics
class MessageMetrics {
  final String message;
  int totalShows = 0;
  double totalEngagement = 0.0;
  double avgEngagement = 0.0;
  double showsPerServer = 0.0;
  int serverCount = 0;
  DateTime? firstShown;
  DateTime? lastShown;
  
  MessageMetrics({required this.message});
  
  double get performanceScore => avgEngagement * math.log(totalShows + 1);
}

/// Optimization recommendations
class VarietyOptimization {
  List<String> staleMessages = [];
  List<String> overusedMessages = [];
  List<String> successPatterns = [];
  Map<MessageCategory, double> recommendedCategoryBalance = {};
  
  /// Get actionable recommendations as text
  List<String> getRecommendations() {
    final recommendations = <String>[];
    
    if (staleMessages.isNotEmpty) {
      recommendations.add('Consider retiring ${staleMessages.length} stale messages');
    }
    
    if (overusedMessages.isNotEmpty) {
      recommendations.add('Reduce frequency of ${overusedMessages.length} overused messages');
    }
    
    if (successPatterns.isNotEmpty) {
      recommendations.add('High-engagement patterns found: ${successPatterns.take(3).join(", ")}');
    }
    
    return recommendations;
  }
}