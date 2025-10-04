import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../storage/nps_database.dart';
import '../storage.dart';
import '../services/server_id_resolver.dart';
import '../utils/log.dart';

/// Phase 6: NPS Widget Calculation Audit Service
/// Systematically tests all NPS calculations and identifies issues
class Phase6CalculationAuditService {
  static const String _tag = 'Phase6Audit';

  Future<Phase6AuditReport> auditCalculations() async {
    final stopwatch = Stopwatch()..start();
    final report = Phase6AuditReport();
    
    try {
      d('[$_tag] 🔍 Starting NPS Widget Calculation Audit');
      
      // Test 1: Data Retrieval Audit
      await _auditDataRetrieval(report);
      
      // Test 2: Server ID Resolution Audit
      await _auditServerResolution(report);
      
      // Test 3: NPS Score Calculation Audit
      await _auditNPSCalculations(report);
      
      // Test 4: Date/Period Filtering Audit
      await _auditDateFiltering(report);
      
      // Test 5: Widget-Specific Data Audit
      await _auditWidgetSpecificData(report);
      
      report.executionTimeMs = stopwatch.elapsedMilliseconds;
      report.success = report.criticalIssues == 0;
      
      d('[$_tag] ✅ Calculation audit completed');
      
    } catch (e) {
      report.success = false;
      report.errors.add('Audit failed: $e');
      d('[$_tag] ❌ Audit failed: $e');
    } finally {
      stopwatch.stop();
    }
    
    return report;
  }
  
  Future<void> _auditDataRetrieval(Phase6AuditReport report) async {
    try {
      final npsDb = NPSDatabase.instance;
      final db = await npsDb.database;
      
      // Count total NPS entries
      final totalEntries = await db.rawQuery('SELECT COUNT(*) as count FROM nps_entries');
      report.totalNPSEntries = totalEntries.first['count'] as int;
      
      // Check date range of entries
      final dateRange = await db.rawQuery('''
        SELECT 
          MIN(date) as earliest_date,
          MAX(date) as latest_date,
          COUNT(DISTINCT date) as unique_dates,
          COUNT(DISTINCT server_id) as unique_servers
        FROM nps_entries
      ''');
      
      if (dateRange.isNotEmpty) {
        final range = dateRange.first;
        report.dataDateRange = '${range['earliest_date']} to ${range['latest_date']}';
        report.uniqueDates = range['unique_dates'] as int;
        report.uniqueServersWithNPS = range['unique_servers'] as int;
      }
      
      // Sample recent entries
      final recentEntries = await db.rawQuery('''
        SELECT server_id, rating, date, comment 
        FROM nps_entries 
        ORDER BY created_at DESC 
        LIMIT 5
      ''');
      
      report.sampleEntries = recentEntries.map((entry) => 
        'Server: ${entry['server_id']}, Rating: ${entry['rating']}, Date: ${entry['date']}'
      ).toList();
      
      d('[$_tag] Data retrieval: ${report.totalNPSEntries} entries, ${report.uniqueServersWithNPS} servers');
      
    } catch (e) {
      report.criticalIssues++;
      report.errors.add('Data retrieval audit failed: $e');
    }
  }
  
  Future<void> _auditServerResolution(Phase6AuditReport report) async {
    try {
      final npsDb = NPSDatabase.instance;
      final db = await npsDb.database;
      
      // Get all unique server IDs from NPS data
      final serverIds = await db.rawQuery('SELECT DISTINCT server_id FROM nps_entries');
      
      int resolvedCount = 0;
      int unresolvedCount = 0;
      List<String> unresolvedIds = [];
      
      for (final row in serverIds) {
        final serverId = row['server_id'] as String;
        final server = await ServerIdResolver.resolveToServerObject(serverId);
        
        if (server != null) {
          resolvedCount++;
        } else {
          unresolvedCount++;
          unresolvedIds.add(serverId);
        }
      }
      
      report.resolvedServerIds = resolvedCount;
      report.unresolvedServerIds = unresolvedCount;
      report.unresolvedIdSamples = unresolvedIds.take(5).toList();
      
      if (unresolvedCount > 0) {
        report.warnings.add('$unresolvedCount server IDs cannot be resolved to names');
        if (unresolvedCount > resolvedCount) {
          report.criticalIssues++;
        }
      }
      
      d('[$_tag] Server resolution: $resolvedCount resolved, $unresolvedCount unresolved');
      
    } catch (e) {
      report.criticalIssues++;
      report.errors.add('Server resolution audit failed: $e');
    }
  }
  
  Future<void> _auditNPSCalculations(Phase6AuditReport report) async {
    try {
      final npsDb = NPSDatabase.instance;
      final db = await npsDb.database;
      
      // Test basic NPS calculation logic
      final npsData = await db.rawQuery('''
        SELECT 
          COUNT(CASE WHEN rating >= 9 THEN 1 END) as promoters,
          COUNT(CASE WHEN rating <= 6 THEN 1 END) as detractors,
          COUNT(*) as total_responses,
          AVG(rating) as avg_rating
        FROM nps_entries
      ''');
      
      if (npsData.isNotEmpty) {
        final data = npsData.first;
        final promoters = data['promoters'] as int;
        final detractors = data['detractors'] as int;
        final total = data['total_responses'] as int;
        final avgRating = data['avg_rating'] as double?;
        
        report.totalPromoters = promoters;
        report.totalDetractors = detractors;
        report.totalResponses = total;
        report.averageRating = avgRating ?? 0.0;
        
        // Calculate NPS score manually
        if (total > 0) {
          final npsScore = ((promoters - detractors) / total * 100).round();
          report.calculatedNPSScore = npsScore;
        }
        
        // Test per-server calculations
        final serverNPS = await db.rawQuery('''
          SELECT 
            server_id,
            COUNT(CASE WHEN rating >= 9 THEN 1 END) as promoters,
            COUNT(CASE WHEN rating <= 6 THEN 1 END) as detractors,
            COUNT(*) as responses,
            AVG(rating) as avg_rating
          FROM nps_entries 
          GROUP BY server_id
          HAVING COUNT(*) >= 2
          LIMIT 10
        ''');
        
        report.serverCalculationSamples = serverNPS.map((row) {
          final promoters = row['promoters'] as int;
          final detractors = row['detractors'] as int;
          final responses = row['responses'] as int;
          final nps = responses > 0 ? ((promoters - detractors) / responses * 100).round() : 0;
          return 'Server ${row['server_id']}: NPS $nps (${row['responses']} responses, avg ${(row['avg_rating'] as double).toStringAsFixed(1)})';
        }).toList();
      }
      
      d('[$_tag] NPS calculations: ${report.totalResponses} responses, NPS score ${report.calculatedNPSScore}');
      
    } catch (e) {
      report.criticalIssues++;
      report.errors.add('NPS calculation audit failed: $e');
    }
  }
  
  Future<void> _auditDateFiltering(Phase6AuditReport report) async {
    try {
      final npsDb = NPSDatabase.instance;
      final db = await npsDb.database;
      final now = DateTime.now();
      
      // Test current month filtering
      final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final currentMonthData = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM nps_entries 
        WHERE date LIKE ?
      ''', ['$currentMonth%']);
      
      report.currentMonthEntries = currentMonthData.first['count'] as int;
      
      // Test last 30 days filtering
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final thirtyDaysData = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM nps_entries 
        WHERE date >= ?
      ''', [thirtyDaysAgo.toIso8601String().split('T')[0]]);
      
      report.last30DaysEntries = thirtyDaysData.first['count'] as int;
      
      // Test business_date filtering if available
      final businessDateData = await db.rawQuery('''
        SELECT 
          COUNT(*) as total,
          COUNT(CASE WHEN business_date IS NOT NULL THEN 1 END) as with_business_date
        FROM nps_entries
      ''');
      
      if (businessDateData.isNotEmpty) {
        final data = businessDateData.first;
        report.entriesWithBusinessDate = data['with_business_date'] as int;
        
        if ((data['with_business_date'] as int) < (data['total'] as int)) {
          report.warnings.add('Some entries missing business_date - may affect date-based widgets');
        }
      }
      
      d('[$_tag] Date filtering: ${report.currentMonthEntries} current month, ${report.last30DaysEntries} last 30 days');
      
    } catch (e) {
      report.warnings.add('Date filtering audit failed: $e');
    }
  }
  
  Future<void> _auditWidgetSpecificData(Phase6AuditReport report) async {
    try {
      final npsDb = NPSDatabase.instance;
      final db = await npsDb.database;
      
      // Check for data patterns that might break widgets
      
      // 1. Servers with only extreme ratings (all 1s or all 10s)
      final extremeRatings = await db.rawQuery('''
        SELECT server_id, MIN(rating) as min_rating, MAX(rating) as max_rating, COUNT(*) as count
        FROM nps_entries 
        GROUP BY server_id
        HAVING (MIN(rating) = MAX(rating) AND COUNT(*) > 1)
        LIMIT 5
      ''');
      
      if (extremeRatings.isNotEmpty) {
        report.warnings.add('${extremeRatings.length} servers have only identical ratings');
      }
      
      // 2. Check for missing or invalid timestamps
      final timestampIssues = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM nps_entries 
        WHERE timestamp IS NULL OR timestamp = 0
      ''');
      
      final badTimestamps = timestampIssues.first['count'] as int;
      if (badTimestamps > 0) {
        report.warnings.add('$badTimestamps entries have missing/invalid timestamps');
      }
      
      // 3. Check for shift_type distribution
      final shiftTypes = await db.rawQuery('''
        SELECT 
          shift_type,
          COUNT(*) as count
        FROM nps_entries 
        WHERE shift_type IS NOT NULL
        GROUP BY shift_type
      ''');
      
      report.shiftTypeDistribution = shiftTypes.map((row) => 
        '${row['shift_type']}: ${row['count']} entries'
      ).toList();
      
      d('[$_tag] Widget-specific audit completed');
      
    } catch (e) {
      report.warnings.add('Widget-specific audit failed: $e');
    }
  }
}

class Phase6AuditReport {
  bool success = false;
  int executionTimeMs = 0;
  int criticalIssues = 0;
  List<String> errors = [];
  List<String> warnings = [];
  
  // Data retrieval metrics
  int totalNPSEntries = 0;
  String dataDateRange = '';
  int uniqueDates = 0;
  int uniqueServersWithNPS = 0;
  List<String> sampleEntries = [];
  
  // Server resolution metrics
  int resolvedServerIds = 0;
  int unresolvedServerIds = 0;
  List<String> unresolvedIdSamples = [];
  
  // NPS calculation metrics
  int totalPromoters = 0;
  int totalDetractors = 0;
  int totalResponses = 0;
  double averageRating = 0.0;
  int calculatedNPSScore = 0;
  List<String> serverCalculationSamples = [];
  
  // Date filtering metrics
  int currentMonthEntries = 0;
  int last30DaysEntries = 0;
  int entriesWithBusinessDate = 0;
  
  // Widget-specific metrics
  List<String> shiftTypeDistribution = [];
  
  String get overallHealth {
    if (criticalIssues > 0) return 'Critical Issues';
    if (warnings.isNotEmpty) return 'Minor Issues';
    if (totalNPSEntries == 0) return 'No Data';
    return 'Healthy';
  }
  
  int get healthScore {
    if (criticalIssues > 0) return 0;
    if (totalNPSEntries == 0) return 10;
    
    int score = 100;
    score -= warnings.length * 10; // -10 per warning
    score -= (unresolvedServerIds * 5); // -5 per unresolved server
    
    return score.clamp(0, 100);
  }
}