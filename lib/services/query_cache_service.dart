import 'dart:async';
import '../utils/log.dart';

/// Query Cache Service for Performance Optimization
/// 
/// This service provides intelligent caching for frequently accessed database queries
/// to improve app performance and reduce database load.
class QueryCacheService {
  static final QueryCacheService _instance = QueryCacheService._internal();
  factory QueryCacheService() => _instance;
  QueryCacheService._internal();

  // Cache storage
  final Map<String, _CacheEntry> _cache = {};
  
  // Cache configuration
  static const Duration _defaultTtl = Duration(minutes: 5);
  static const int _maxCacheSize = 100;

  /// Get cached result or execute query if not cached
  Future<T> getOrExecute<T>(
    String cacheKey,
    Future<T> Function() queryExecutor, {
    Duration? ttl,
  }) async {
    final entry = _cache[cacheKey];
    final now = DateTime.now();
    
    // Check if cache entry exists and is still valid
    if (entry != null && now.isBefore(entry.expiresAt)) {
      d('[QueryCache] Cache hit for key: $cacheKey');
      return entry.data as T;
    }
    
    // Execute query and cache result
    d('[QueryCache] Cache miss for key: $cacheKey, executing query');
    final result = await queryExecutor();
    
    // Store in cache
    _cache[cacheKey] = _CacheEntry(
      data: result,
      expiresAt: now.add(ttl ?? _defaultTtl),
    );
    
    // Clean up old entries if cache is too large
    _cleanupCache();
    
    return result;
  }

  /// Invalidate cache entry
  void invalidate(String cacheKey) {
    _cache.remove(cacheKey);
    d('[QueryCache] Invalidated cache for key: $cacheKey');
  }

  /// Invalidate all cache entries matching pattern
  void invalidatePattern(String pattern) {
    final keysToRemove = _cache.keys.where((key) => key.contains(pattern)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    d('[QueryCache] Invalidated ${keysToRemove.length} cache entries matching pattern: $pattern');
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    d('[QueryCache] Cleared all cache entries');
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    final validEntries = _cache.values.where((entry) => now.isBefore(entry.expiresAt)).length;
    
    return {
      'total_entries': _cache.length,
      'valid_entries': validEntries,
      'expired_entries': _cache.length - validEntries,
      'cache_size_mb': _estimateCacheSize(),
    };
  }

  /// Clean up expired entries and limit cache size
  void _cleanupCache() {
    final now = DateTime.now();
    
    // Remove expired entries
    _cache.removeWhere((key, entry) => now.isAfter(entry.expiresAt));
    
    // Remove oldest entries if cache is too large
    if (_cache.length > _maxCacheSize) {
      final sortedEntries = _cache.entries.toList()
        ..sort((a, b) => a.value.expiresAt.compareTo(b.value.expiresAt));
      
      final entriesToRemove = sortedEntries.take(_cache.length - _maxCacheSize);
      for (final entry in entriesToRemove) {
        _cache.remove(entry.key);
      }
    }
  }

  /// Estimate cache size in MB
  double _estimateCacheSize() {
    // Rough estimation based on entry count
    return _cache.length * 0.001; // Assume ~1KB per entry on average
  }
}

/// Cache entry wrapper
class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry({
    required this.data,
    required this.expiresAt,
  });
}

/// Cache key generators for common queries
class CacheKeys {
  static String serverList() => 'servers:list:active';
  static String serverById(int id) => 'servers:by_id:$id';
  static String monthlyReport(int serverId, int monthKey) => 'monthly_report:$serverId:$monthKey';
  static String monthlyReportsForMonth(int monthKey) => 'monthly_reports:month:$monthKey';
  static String feedbackForServer(int serverId) => 'feedback:server:$serverId';
  static String feedbackForServerInRange(int serverId, DateTime start, DateTime end) => 
    'feedback:server:$serverId:range:${start.millisecondsSinceEpoch}:${end.millisecondsSinceEpoch}';
  static String npsCalculation(int serverId, String type) => 'nps_calculation:$serverId:$type';
}

