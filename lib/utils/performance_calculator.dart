import 'dart:math' as math;
import '../models/performance_models.dart';
import '../models.dart';
import '../storage.dart';
import '../providers/nps_provider.dart';
import 'log.dart';

/// Core performance calculation engine with mathematical algorithms
class PerformanceCalculator {
  /// Default shift difficulty multipliers
  static const Map<String, double> defaultDifficultyMultipliers = {
    'lunch': 1.0, // Baseline
    'dinner': 1.3, // 30% more complex
    'double': 1.6, // 60% more complex (full day)
  };

  /// Minimum expected performance thresholds (defaults, can be overridden)
  static const double baseExpectedRunsPerShift = 8.0;
  static const double baseExpectedGuestEfficiency = 0.15; // runs per guest
  static const double baseExpectedSalesEfficiency =
      12.0; // runs per $1000 sales

  // Winsorization caps (configurable) to reduce skew from outliers
  static const double averageCheckMinCap =
      40.0; // lower bound for reasonable avg check
  static const double averageCheckMaxCap =
      120.0; // upper bound for reasonable avg check

  /// Calculate dynamic baselines from historical restaurant data
  static Future<Map<String, double>> calculateDynamicBaselines({
    required DateTime startDate,
    required DateTime endDate,
    List<ShiftRecord>? shifts, // Optional shifts data
  }) async {
    try {
      // Load business data for the period to calculate realistic baselines
      final businessDataKeys = await Storage.getAllBusinessDataKeys();

      if (businessDataKeys.isEmpty) {
        return {
          'runsPerShift': baseExpectedRunsPerShift,
          'guestEfficiency': baseExpectedGuestEfficiency,
          'salesEfficiency': baseExpectedSalesEfficiency,
        };
      }

      double totalGuests = 0;
      double totalSales = 0;
      double totalRuns = 0;
      int totalShifts = 0;
      int monthsWithData = 0;

      // Load business data for the period
      for (final monthKey in businessDataKeys) {
        final businessData = await Storage.getMonthlyBusinessData(monthKey);
        if (businessData != null) {
          monthsWithData++;
          totalGuests += businessData['totalGuestCount'] as double? ?? 0.0;
          totalSales += businessData['totalSales'] as double? ?? 0.0;
        }
      }

      // If shifts are provided, calculate total runs and shifts
      if (shifts != null) {
        totalShifts = shifts.length;
        for (final shift in shifts) {
          for (final serverRuns in shift.counts.values) {
            totalRuns += serverRuns;
          }
        }
      } else {
        // Estimate based on typical restaurant patterns if no shift data available
        totalShifts = monthsWithData * 60; // Estimate ~60 shifts per month
        totalRuns = totalShifts *
            baseExpectedRunsPerShift; // Use default for estimation
      }

      // Calculate baselines from actual data
      final avgRunsPerShift =
          totalShifts > 0 ? totalRuns / totalShifts : baseExpectedRunsPerShift;
      final avgGuestEfficiency = totalGuests > 0
          ? totalRuns / totalGuests
          : baseExpectedGuestEfficiency;
      final avgSalesEfficiency = totalSales > 0
          ? totalRuns / (totalSales / 1000)
          : baseExpectedSalesEfficiency;

      // Use historical averages but ensure reasonable minimums
      return {
        'runsPerShift': math.max(
            4.0, math.min(16.0, avgRunsPerShift)), // Cap between 4-16 runs
        'guestEfficiency': math.max(
            0.05, math.min(0.50, avgGuestEfficiency)), // Cap between 5%-50%
        'salesEfficiency': math.max(5.0,
            math.min(25.0, avgSalesEfficiency)), // Cap between 5-25 per $1000
      };
    } catch (e) {
      // Fall back to default values if there's any error
      return {
        'runsPerShift': baseExpectedRunsPerShift,
        'guestEfficiency': baseExpectedGuestEfficiency,
        'salesEfficiency': baseExpectedSalesEfficiency,
      };
    }
  }

  /// Calculate comprehensive performance data for a server
  static ServerPerformanceData calculateServerPerformance({
    required String serverId,
    required DateTime startDate,
    required DateTime endDate,
    required List<ShiftRecord> shifts,
    required MonthlyBusinessData? businessData,
    required DateTime hireDate,
    Map<String, double>? customDifficultyMultipliers,
    List<NPSData>? npsHistory,
    int? totalServerCount, // Add server count for proper distribution
  }) {
    // Extract server-specific data from shifts
    final serverShifts =
        _extractServerShifts(serverId, shifts, startDate, endDate);
    final totalFoodRuns = serverShifts.fold<int>(
        0, (sum, shift) => sum + (shift.counts[serverId] ?? 0));
    final shiftsWorked = serverShifts.length;
    final daysEmployed = DateTime.now().difference(hireDate).inDays;

    // Timeframe alignment:
    // - Use MonthlyBusinessData (selected period) for efficiency metrics (runs per check, runs per $1K)
    // - Use NPS all-time totals ONLY to compute average check for Sales Ability scoring
    //   (NPS saved monthly reports currently store all-time totals, not per-month).

    // Efficiency inputs from business data (period-contextual)
    double periodCheckCount = businessData?.serverSpecificGuests[serverId] ??
        (businessData?.totalGuestCount ?? 0.0) /
            math.max(1, totalServerCount ?? 1);
    double periodSales = businessData?.serverSpecificSales[serverId] ??
        (businessData?.totalSales ?? 0.0) / math.max(1, totalServerCount ?? 1);

  d('DEBUG: Period efficiency inputs for $serverId -> checks: $periodCheckCount, sales: $periodSales');

    // Optional NPS all-time totals used for average-check computation
    double npsAllTimeChecks = 0.0;
    double npsAllTimeSales = 0.0;

    if (npsHistory != null && npsHistory.isNotEmpty) {
    d('DEBUG: Searching for serverId "$serverId" in ${npsHistory.length} NPS history entries');
      final serverNpsData =
          npsHistory.where((nps) => nps.serverId == serverId).toList();
    d('DEBUG: Found ${serverNpsData.length} NPS data entries for server $serverId');
      if (serverNpsData.isNotEmpty) {
        final latestNps =
            serverNpsData.reduce((a, b) => a.month.isAfter(b.month) ? a : b);
        npsAllTimeChecks = latestNps.responseCount.toDouble();
        npsAllTimeSales = latestNps.categoryBreakdown['sales'] ?? 0.0;
    d('DEBUG: NPS all-time totals for $serverId -> checks: $npsAllTimeChecks, sales: \$${npsAllTimeSales.toStringAsFixed(2)}');
      }
    } else {
  d('DEBUG: No NPS history available for average-check computation');
    }

    // Calculate shift complexities
    final shiftComplexities = _calculateShiftComplexities(
      serverShifts,
      customDifficultyMultipliers ?? defaultDifficultyMultipliers,
      businessData,
    );

    // Calculate core metrics
    final metrics = _calculatePerformanceMetrics(
      totalFoodRuns: totalFoodRuns,
      shiftsWorked: shiftsWorked,
      guestCount: periodCheckCount,
      sales: periodSales,
      daysEmployed: daysEmployed,
      shiftComplexities: shiftComplexities,
      serverShifts: serverShifts,
      serverId: serverId,
      startDate: startDate,
      endDate: endDate,
      npsHistory: npsHistory,
    );

    // Calculate NPS data availability for fair scoring
    final npsDataMonths = npsHistory
            ?.where((nps) => nps.serverId == serverId)
            .where((nps) =>
                nps.month.isAfter(startDate.subtract(const Duration(days: 90))))
            .length ??
        0;

    // Calculate overall performance score
    // For Sales Ability (average check), prefer NPS all-time totals when available; fallback to period inputs
    final avgCheckSalesSource =
        npsAllTimeSales > 0 ? npsAllTimeSales : periodSales;
    final avgCheckChecksSource =
        npsAllTimeChecks > 0 ? npsAllTimeChecks : periodCheckCount;

    final performanceScore = _calculateOverallScore(
      metrics,
      daysEmployed,
      npsDataMonths,
      avgCheckSalesSource,
      avgCheckChecksSource,
    );

    // Determine rating and flags
    final rating = _getRatingFromScore(performanceScore);
    final flags = _generatePerformanceFlags(
        metrics, performanceScore, daysEmployed, serverShifts);

    // Generate insights
    final insights = _generateInsights(
        serverId, metrics, performanceScore, flags, daysEmployed);

    return ServerPerformanceData(
      serverId: serverId,
      startDate: startDate,
      endDate: endDate,
      totalFoodRuns: totalFoodRuns,
      shiftsWorked: shiftsWorked,
      daysEmployed: daysEmployed,
      totalGuestCount: periodCheckCount,
      totalSales: periodSales,
      shiftTypes: shiftComplexities,
      metrics: metrics,
      performanceScore: performanceScore,
      rating: rating,
      flags: flags,
      insights: insights,
      calculatedDate: DateTime.now(),
    );
  }

  /// Extract shifts where the specified server worked
  static List<ShiftRecord> _extractServerShifts(
    String serverId,
    List<ShiftRecord> allShifts,
    DateTime startDate,
    DateTime endDate,
  ) {
    return allShifts.where((shift) {
      final shiftDate = shift.start;
      final hasServerData = shift.counts.containsKey(serverId) &&
          (shift.counts[serverId] ?? 0) > 0;
      final inDateRange =
          shiftDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
              shiftDate.isBefore(endDate.add(const Duration(days: 1)));
      return hasServerData && inDateRange;
    }).toList();
  }

  /// Calculate shift complexity factors
  static List<ShiftComplexity> _calculateShiftComplexities(
    List<ShiftRecord> serverShifts,
    Map<String, double> difficultyMultipliers,
    MonthlyBusinessData? businessData,
  ) {
    return serverShifts.map((shift) {
      final shiftType = shift.shiftType.toLowerCase();
      final multiplier = difficultyMultipliers[shiftType] ?? 1.0;

      // For monthly data entry, estimate shift-level metrics from monthly totals
      // This is approximate since actual shift-level data isn't tracked
      final totalShiftsInData = serverShifts.length;
      final estimatedGuests = totalShiftsInData > 0
          ? (businessData?.totalGuestCount ?? 0.0) / totalShiftsInData
          : 0.0;
      final estimatedSales = totalShiftsInData > 0
          ? (businessData?.totalSales ?? 0.0) / totalShiftsInData
          : 0.0;

      return ShiftComplexity(
        shiftType: shiftType,
        difficultyMultiplier: multiplier,
        guestCount: estimatedGuests.round(),
        sales: estimatedSales,
        date: shift.start,
      );
    }).toList();
  }

  /// Calculate core performance metrics
  static PerformanceMetrics _calculatePerformanceMetrics({
    required int totalFoodRuns,
    required int shiftsWorked,
    required double guestCount,
    required double sales,
    required int daysEmployed,
    required List<ShiftComplexity> shiftComplexities,
    required List<ShiftRecord> serverShifts,
    required String serverId,
    required DateTime startDate,
    required DateTime endDate,
    List<NPSData>? npsHistory,
  }) {
    // Raw efficiency: food runs per shift
    final rawEfficiency = shiftsWorked > 0 ? totalFoodRuns / shiftsWorked : 0.0;

    // Check efficiency: food runs per check served (using check count from NPS data when available)
    final guestEfficiency = guestCount > 0 ? totalFoodRuns / guestCount : 0.0;

    // Sales efficiency: food runs per $1000 in sales
    final salesEfficiency = sales > 0 ? totalFoodRuns / (sales / 1000) : 0.0;

  d('DEBUG: Sales Efficiency Calculation for server $serverId:');
  d('DEBUG:   totalFoodRuns: $totalFoodRuns');
  d('DEBUG:   sales: \$${sales.toStringAsFixed(2)}');
  d('DEBUG:   sales/1000: ${sales > 0 ? (sales / 1000).toStringAsFixed(3) : "N/A"}');
  d('DEBUG:   salesEfficiency: ${salesEfficiency.toStringAsFixed(3)} runs per \$1K');

    // Enhanced experience factor for monthly data context
    final experienceFactor = _calculateExperienceFactor(daysEmployed,
        npsHistory?.where((nps) => nps.serverId == serverId).length ?? 0);

    // Consistency score: based on variance in daily performance
    final consistencyScore = _calculateConsistencyScore(serverShifts, serverId);

    // Complexity-adjusted performance
    final adjustedPerformance = _calculateComplexityAdjustedPerformance(
      serverShifts,
      serverId,
      shiftComplexities,
    );

    // Calculate NPS scores
    final npsScores = _calculateNPSScore(
      serverId: serverId,
      startDate: startDate,
      endDate: endDate,
      npsHistory: npsHistory,
    );

    return PerformanceMetrics(
      rawEfficiency: rawEfficiency,
      guestEfficiency: guestEfficiency,
      salesEfficiency: salesEfficiency,
      consistencyScore: consistencyScore,
      experienceFactor: experienceFactor,
      adjustedPerformance: adjustedPerformance,
      npsScore: npsScores['npsScore']!,
      npsThreeMonth: npsScores['npsThreeMonth']!,
      npsOneMonth: npsScores['npsOneMonth']!,
    );
  }

  /// Calculate consistency score based on performance variance
  static double _calculateConsistencyScore(
      List<ShiftRecord> serverShifts, String serverId) {
    if (serverShifts.length < 2)
      return 100.0; // Single shift gets perfect consistency

    final performances = serverShifts
        .map((shift) => (shift.counts[serverId] ?? 0).toDouble())
        .where((count) => count > 0)
        .toList();

    if (performances.isEmpty) return 0.0;

    final mean = performances.reduce((a, b) => a + b) / performances.length;
    final variance =
        performances.map((p) => math.pow(p - mean, 2)).reduce((a, b) => a + b) /
            performances.length;
    final standardDeviation = math.sqrt(variance);

    // Coefficient of variation (CV) = standard deviation / mean
    final coefficientOfVariation = mean > 0 ? standardDeviation / mean : 0.0;

    // Convert CV to consistency score (0-100, where lower CV = higher consistency)
    // CV of 0.3 (30%) or higher gets 0 consistency, CV of 0 gets 100 consistency
    final consistencyScore = math.max(
        0.0,
        math.min(
            100.0, (1.0 - math.min(coefficientOfVariation / 0.3, 1.0)) * 100));

    return consistencyScore;
  }

  /// Calculate NPS-based performance score with trend analysis
  static Map<String, double> _calculateNPSScore({
    required String serverId,
    required DateTime startDate,
    required DateTime endDate,
    List<NPSData>? npsHistory,
  }) {
    // Default scores for servers without NPS data (neutral/average)
    const double defaultScore = 50.0;

    if (npsHistory == null || npsHistory.isEmpty) {
      return {
        'npsScore': defaultScore,
        'npsThreeMonth': defaultScore,
        'npsOneMonth': defaultScore,
      };
    }

    // Filter NPS data for this server within the evaluation period
    final serverNPS = npsHistory
        .where((nps) => nps.serverId == serverId)
        .where((nps) =>
            nps.month.isAfter(startDate.subtract(const Duration(days: 90))) &&
            nps.month.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    if (serverNPS.isEmpty) {
      return {
        'npsScore': defaultScore,
        'npsThreeMonth': defaultScore,
        'npsOneMonth': defaultScore,
      };
    }

    // Sort by date (most recent first)
    serverNPS.sort((a, b) => b.month.compareTo(a.month));

    // Calculate 3-month average (primary metric)
    final threeMonthData = serverNPS.take(3).toList();
    final threeMonthAverage = threeMonthData.isNotEmpty
        ? threeMonthData
                .map((nps) => nps.threeMonthAverage)
                .reduce((a, b) => a + b) /
            threeMonthData.length
        : defaultScore;

    // Calculate 1-month score (trend indicator)
    final oneMonthScore =
        serverNPS.isNotEmpty ? serverNPS.first.monthlyScore : defaultScore;

    // Calculate trend factor: is performance improving or declining?
    double trendFactor = 1.0;
    if (serverNPS.length >= 2) {
      final recent = serverNPS.first.monthlyScore;
      final previous = serverNPS[1].monthlyScore;
      final improvement = recent - previous;

      // Reward improvement, penalize decline
      // ±10 point change = ±5% adjustment to final score
      trendFactor = 1.0 +
          (improvement / 200.0); // 10 point improvement = 1.05x multiplier
      trendFactor =
          math.max(0.8, math.min(1.2, trendFactor)); // Cap at ±20% adjustment
    }

    // Weight the scores: 3-month average (80%) + 1-month trend (20%)
    final weightedNPSScore = (threeMonthAverage * 0.8) + (oneMonthScore * 0.2);

    // Apply trend factor
    final finalNPSScore = weightedNPSScore * trendFactor;

    return {
      'npsScore': math.max(0.0, math.min(100.0, finalNPSScore)),
      'npsThreeMonth': threeMonthAverage,
      'npsOneMonth': oneMonthScore,
    };
  }

  /// Calculate enhanced experience factor for monthly data context
  static double _calculateExperienceFactor(
      int daysEmployed, int npsDataMonths) {
    // Progressive experience curve rather than linear
    // Accounts for both tenure and data availability

    if (daysEmployed <= 0) return 0.6; // New hire minimum

    // Base experience curve - slower progression for monthly evaluation
    double experienceBase;
    if (daysEmployed < 30) {
      // First month: 60-75% performance expectation
      experienceBase = 0.6 + (daysEmployed / 30.0) * 0.15;
    } else if (daysEmployed < 90) {
      // Months 2-3: 75-90% performance expectation
      experienceBase = 0.75 + ((daysEmployed - 30) / 60.0) * 0.15;
    } else if (daysEmployed < 180) {
      // Months 4-6: 90-95% performance expectation
      experienceBase = 0.90 + ((daysEmployed - 90) / 90.0) * 0.05;
    } else {
      // 6+ months: 95-100% performance expectation
      experienceBase =
          0.95 + math.min(0.05, (daysEmployed - 180) / 360.0 * 0.05);
    }

    // Adjust based on NPS data availability
    // Servers with more evaluation history get slight adjustment towards full expectation
    if (npsDataMonths >= 3) {
      experienceBase = math.min(
          1.0, experienceBase + 0.02); // 2% bonus for established history
    } else if (npsDataMonths == 0 && daysEmployed < 60) {
      experienceBase = math.max(
          0.6, experienceBase - 0.05); // 5% reduction for very new with no NPS
    }

    return math.max(0.6, math.min(1.0, experienceBase));
  }

  /// Calculate complexity-adjusted performance
  static double _calculateComplexityAdjustedPerformance(
    List<ShiftRecord> serverShifts,
    String serverId,
    List<ShiftComplexity> shiftComplexities,
  ) {
    if (serverShifts.isEmpty || shiftComplexities.isEmpty) return 0.0;

    double totalWeightedScore = 0.0;
    double totalWeight = 0.0;

    for (int i = 0;
        i < serverShifts.length && i < shiftComplexities.length;
        i++) {
      final shift = serverShifts[i];
      final complexity = shiftComplexities[i];
      final runs = (shift.counts[serverId] ?? 0).toDouble();
      final weight = complexity.difficultyMultiplier;

      totalWeightedScore += runs * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? totalWeightedScore / totalWeight : 0.0;
  }

  /// Calculate overall performance score (0-100) with new weight structure:
  /// 50% NPS/Guest Perception, 30% Sales Ability, 20% Food Running Performance
  static double _calculateOverallScore(
      PerformanceMetrics metrics,
      int daysEmployed,
      int npsDataMonths,
      double totalSales,
      double totalChecks) {
  d('DEBUG: Calculating performance score with new weight structure');

    // NEW WEIGHT STRUCTURE (Based on user requirements)
    double npsWeight = 0.50; // 50% - Guest perception (NPS data)
    double salesWeight =
        0.30; // 30% - Sales ability (average check performance)
    double foodRunningWeight = 0.20; // 20% - Food running performance

    // Adjust weights only for servers with NO NPS data at all
    if (npsDataMonths == 0) {
  d('DEBUG: No NPS data available, redistributing weights');
      npsWeight = 0.0; // No NPS weight
      salesWeight = 0.60; // Increase sales weight to 60%
      foodRunningWeight = 0.40; // Increase food running weight to 40%
    } else if (npsDataMonths < 3) {
      // Servers with some NPS data but limited - slight reduction
    d('DEBUG: Limited NPS data ($npsDataMonths months), slight weight adjustment');
      final reduction =
          (3 - npsDataMonths) * 0.05; // 5% reduction per missing month
      npsWeight =
          math.max(0.35, npsWeight - reduction); // Minimum 35% NPS weight

      // Redistribute to other components
      final redistributed = (0.50 - npsWeight) / 2;
      salesWeight += redistributed;
      foodRunningWeight += redistributed;
    }

  d('DEBUG: Final weights - NPS: ${(npsWeight * 100).toStringAsFixed(1)}%, Sales: ${(salesWeight * 100).toStringAsFixed(1)}%, Food Running: ${(foodRunningWeight * 100).toStringAsFixed(1)}%');

    // Component 1: NPS/Guest Perception Score (0-100)
    final npsScore = metrics.npsScore;
  d('DEBUG: NPS Score: ${npsScore.toStringAsFixed(1)}/100');

    // Component 2: Sales Ability Score (based on average check performance)
    // Calculate average check from total sales and total checks from NPS data
    double averageCheck = 0.0;
    double salesAbilityScore = 0.0;

    if (npsDataMonths > 0) {
      // Use the actual sales and check data from NPS reports for accurate average check
      if (totalChecks > 0 && totalSales > 0) {
        averageCheck = totalSales / totalChecks;
        // Winsorize to reduce skew from anomalies
        averageCheck =
            _winsorize(averageCheck, averageCheckMinCap, averageCheckMaxCap);
        // Normalize average check to 0-100 scale using same caps
        salesAbilityScore = _normalizeToScore(
            averageCheck, averageCheckMinCap, averageCheckMaxCap);
      }
    } else {
      // Fallback for servers without NPS data - estimate from efficiency ratios
      if (metrics.guestEfficiency > 0 && metrics.salesEfficiency > 0) {
        // Estimate: if server does X runs per check and Y runs per $1K, what's the average check?
        averageCheck =
            (metrics.salesEfficiency * 1000) / metrics.guestEfficiency;
        averageCheck =
            _winsorize(averageCheck, averageCheckMinCap, averageCheckMaxCap);
        salesAbilityScore = _normalizeToScore(
            averageCheck, averageCheckMinCap, averageCheckMaxCap);
      }
    }

    // Neutral fallback if we couldn't compute a sales ability score (avoid unfair penalties)
    if (salesAbilityScore == 0.0) {
      salesAbilityScore = 50.0;
    }

  d('DEBUG: Sales Ability - Total Sales: \$${totalSales.toStringAsFixed(2)}, Total Checks: ${totalChecks.toStringAsFixed(0)}, Average Check: \$${averageCheck.toStringAsFixed(2)}, Score: ${salesAbilityScore.toStringAsFixed(1)}/100');

    // Component 3: Food Running Performance Score
    // Combines efficiency, productivity, and willingness to help
    final adjustedPerformanceScore = _normalizeToScore(
      metrics.adjustedPerformance,
      baseExpectedRunsPerShift,
      baseExpectedRunsPerShift * 2,
    );

    final efficiencyScore = _normalizeToScore(
      metrics.guestEfficiency,
      baseExpectedGuestEfficiency,
      baseExpectedGuestEfficiency * 2,
    );

    // Combine performance metrics for food running score
    final foodRunningScore = (adjustedPerformanceScore * 0.6) +
        (efficiencyScore * 0.2) +
        (metrics.consistencyScore * 0.2);
  d('DEBUG: Food Running Score: ${foodRunningScore.toStringAsFixed(1)}/100 (Performance: ${adjustedPerformanceScore.toStringAsFixed(1)}, Efficiency: ${efficiencyScore.toStringAsFixed(1)}, Consistency: ${metrics.consistencyScore.toStringAsFixed(1)})');

    // Calculate weighted final score
    final weightedScore = ((npsScore * npsWeight) +
        (salesAbilityScore * salesWeight) +
        (foodRunningScore * foodRunningWeight));

  d('DEBUG: Component Contributions - NPS: ${(npsScore * npsWeight).toStringAsFixed(1)}, Sales: ${(salesAbilityScore * salesWeight).toStringAsFixed(1)}, Food Running: ${(foodRunningScore * foodRunningWeight).toStringAsFixed(1)}');

    // Apply experience factor (servers improve over time)
    final finalScore = weightedScore * metrics.experienceFactor;

  d('DEBUG: Final Score: ${finalScore.toStringAsFixed(1)}/100 (Experience Factor: ${metrics.experienceFactor.toStringAsFixed(3)})');

    return math.max(0.0, math.min(100.0, finalScore));
  }

  /// Load historical NPS data for performance calculations using NPSProvider
  static Future<List<NPSData>> loadNPSHistory({
    required DateTime startDate,
    required DateTime endDate,
    NPSProvider? npsProvider,
  }) async {
    final npsHistory = <NPSData>[];

    try {
      if (npsProvider == null) {
        // Return empty list if no provider is available
        return [];
      }

      // Get all servers and generate monthly reports for the evaluation period
      final servers = npsProvider.servers;

      // Generate reports for the last 6 months to ensure sufficient data
      final now = DateTime.now();
      for (int monthsBack = 0; monthsBack < 6; monthsBack++) {
        final targetDate = DateTime(now.year, now.month - monthsBack, 1);

        // Skip if this month is outside our evaluation window
        if (targetDate.isBefore(startDate.subtract(const Duration(days: 30)))) {
          continue;
        }

        final monthKey = int.parse(
            '${targetDate.year}${targetDate.month.toString().padLeft(2, '0')}');

        // Generate reports for each server using saved monthly report data
        for (final server in servers) {
          try {
            // Use database.getMonthlyReport to access saved admin-entered data
            final reportData = await npsProvider.database
                .getMonthlyReport(server.id!, monthKey);

            if (reportData != null && reportData.isNotEmpty) {
              // Extract all-time data from the saved monthly report
              final allTimeSales =
                  (reportData['all_time_sales'] as num?)?.toDouble() ?? 0.0;
              final allTimeChecks =
                  (reportData['all_time_table_count'] as int?) ?? 0;
              final allTimeNps =
                  (reportData['all_time_nps_percentage'] as num?)?.toDouble() ??
                      0.0;

              // Convert saved monthly report to NPSData format expected by performance calculator
              final npsData = NPSData(
                serverId: server.originalId ??
                    server.id
                        .toString(), // Use original main app ID if available
                month: targetDate,
                monthlyScore: (reportData['one_month_nps_percentage'] as num?)
                        ?.toDouble() ??
                    allTimeNps,
                threeMonthAverage: allTimeNps,
                responseCount:
                    allTimeChecks, // Use actual check count from admin-entered data
                categoryBreakdown: {
                  'service': allTimeNps,
                  'overall': allTimeNps,
                  'sales':
                      allTimeSales, // Store sales data here for access by performance calculator
                },
                guestComments: [],
                lastUpdated: DateTime.now(),
              );

        d('DEBUG: Created NPSData for server ${server.id} (original: ${server.originalId}) with responseCount: $allTimeChecks, sales: \$${allTimeSales.toStringAsFixed(2)}');

              // Validate the data being stored
              if (allTimeChecks > 0 || allTimeSales > 0) {
                d('DEBUG: ✅ NPSData has valid data - checks: $allTimeChecks, sales: \$${allTimeSales.toStringAsFixed(2)}');
              } else {
                d('DEBUG: ⚠️ NPSData has no check/sales data for server ${server.id}');
              }

              npsHistory.add(npsData);
            } else {
        d('DEBUG: No monthly report data found for server ${server.id} month $monthKey');
            }
          } catch (e) {
      d('DEBUG: Error loading monthly report for server ${server.id} month $monthKey: $e');
            continue;
          }
        }
      }
    } catch (e) {
      // Return empty list if there's any error loading NPS data
      return [];
    }

    return npsHistory;
  }

  /// Normalize a value to 0-100 score based on expected range
  static double _normalizeToScore(
      double value, double expectedMin, double expectedMax) {
    if (expectedMax <= expectedMin) return 50.0; // Default if invalid range

    // Values at expectedMin get 50, values at expectedMax get 100
    // Values below expectedMin get proportionally less, values above get more
    final normalizedValue = (value - expectedMin) / (expectedMax - expectedMin);
    final score = 50.0 + (normalizedValue * 50.0);

    return math.max(0.0, math.min(100.0, score));
  }

  /// Winsorize a value to within [minCap, maxCap]
  static double _winsorize(double value, double minCap, double maxCap) {
    if (minCap > maxCap) return value;
    return math.max(minCap, math.min(maxCap, value));
  }

  /// Generate performance flags based on metrics
  static List<PerformanceFlag> _generatePerformanceFlags(
    PerformanceMetrics metrics,
    double performanceScore,
    int daysEmployed,
    List<ShiftRecord> serverShifts,
  ) {
    final flags = <PerformanceFlag>[];

    // High performer flag
    if (performanceScore >= 85.0 && metrics.consistencyScore >= 70.0) {
      flags.add(PerformanceFlag.highPerformer);
    }

    // Team leader flag
    if (performanceScore >= 90.0 && daysEmployed >= 90) {
      flags.add(PerformanceFlag.teamLeader);
    }

    // New hire flag
    if (daysEmployed <= 90) {
      flags.add(PerformanceFlag.newHire);
    }

    // Low efficiency flag
    if (metrics.rawEfficiency <
        PerformanceCalculator.baseExpectedRunsPerShift * 0.7) {
      flags.add(PerformanceFlag.lowEfficiency);
    }

    // Inconsistent flag
    if (metrics.consistencyScore < 50.0) {
      flags.add(PerformanceFlag.inconsistent);
    }

    // Recognition due flag
    if (performanceScore >= 80.0 && !flags.contains(PerformanceFlag.newHire)) {
      flags.add(PerformanceFlag.recognitionDue);
    }

    // Coaching needed flag
    if (performanceScore < 65.0 && daysEmployed >= 30) {
      flags.add(PerformanceFlag.coachingNeeded);
    }

    return flags;
  }

  /// Generate performance insights and recommendations
  static List<PerformanceInsight> _generateInsights(
    String serverId,
    PerformanceMetrics metrics,
    double performanceScore,
    List<PerformanceFlag> flags,
    int daysEmployed,
  ) {
    final insights = <PerformanceInsight>[];

    // High performer recognition
    if (flags.contains(PerformanceFlag.highPerformer)) {
      insights.add(PerformanceInsight(
        type: 'recognition',
        title: 'High Performer Recognition',
        description:
            'This server consistently exceeds performance expectations and demonstrates excellent efficiency.',
        priority: 'medium',
        actionItems: [
          'Consider for team leadership opportunities',
          'Recognize publicly for excellent performance',
          'Use as mentor for new hires',
        ],
        generatedDate: DateTime.now(),
        serverId: serverId,
      ));
    }

    // Low performance intervention
    if (performanceScore < 50.0) {
      insights.add(PerformanceInsight(
        type: 'alert',
        title: 'Performance Intervention Needed',
        description:
            'This server\'s performance is significantly below expectations and requires immediate attention.',
        priority: 'high',
        actionItems: [
          'Schedule one-on-one performance discussion',
          'Provide additional training on food running procedures',
          'Consider adjusting shift assignments temporarily',
          'Monitor daily performance closely',
        ],
        generatedDate: DateTime.now(),
        serverId: serverId,
      ));
    }

    // Consistency issues
    if (flags.contains(PerformanceFlag.inconsistent)) {
      insights.add(PerformanceInsight(
        type: 'recommendation',
        title: 'Consistency Improvement Opportunity',
        description:
            'This server shows high variance in daily performance, suggesting potential for improvement.',
        priority: 'medium',
        actionItems: [
          'Identify factors causing performance variation',
          'Provide consistent shift scheduling',
          'Review training on time management',
        ],
        generatedDate: DateTime.now(),
        serverId: serverId,
      ));
    }

    // New hire development
    if (flags.contains(PerformanceFlag.newHire) && performanceScore < 70.0) {
      insights.add(PerformanceInsight(
        type: 'recommendation',
        title: 'New Hire Development Plan',
        description:
            'New team member showing potential but needs continued support and training.',
        priority: 'medium',
        actionItems: [
          'Pair with experienced food runner mentor',
          'Provide regular feedback and encouragement',
          'Monitor progress weekly',
          'Ensure proper training completion',
        ],
        generatedDate: DateTime.now(),
        serverId: serverId,
      ));
    }

    // Coaching opportunity
    if (flags.contains(PerformanceFlag.coachingNeeded)) {
      insights.add(PerformanceInsight(
        type: 'recommendation',
        title: 'Coaching Opportunity',
        description:
            'This server would benefit from targeted coaching to improve performance.',
        priority: 'medium',
        actionItems: [
          'Schedule skills assessment session',
          'Provide specific feedback on improvement areas',
          'Set clear performance goals',
          'Follow up in 2 weeks',
        ],
        generatedDate: DateTime.now(),
        serverId: serverId,
      ));
    }

    return insights;
  }

  /// Calculate performance trends over time
  static List<PerformanceTrend> calculatePerformanceTrends(
    String serverId,
    List<ShiftRecord> shifts,
    int daysBack,
  ) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: daysBack));

    final trends = <PerformanceTrend>[];

    // Group shifts by week
    final weeklyData = <DateTime, List<ShiftRecord>>{};

    for (final shift in shifts) {
      if (shift.start.isBefore(startDate) || shift.start.isAfter(endDate))
        continue;
      if (!shift.counts.containsKey(serverId)) continue;

      // Get start of week for grouping
      final weekStart = _getStartOfWeek(shift.start);
      weeklyData.putIfAbsent(weekStart, () => []).add(shift);
    }

    // Calculate weekly performance scores
    for (final entry in weeklyData.entries) {
      final weekShifts = entry.value;
      final totalRuns = weekShifts.fold<int>(
          0, (sum, shift) => sum + (shift.counts[serverId] ?? 0));
      final shiftsWorked = weekShifts.length;

      // Simple score based on runs per shift
      final weeklyScore =
          shiftsWorked > 0 ? (totalRuns / shiftsWorked) * 10 : 0.0;
      final clampedScore = math.max(0.0, math.min(100.0, weeklyScore));

      trends.add(PerformanceTrend(
        date: entry.key,
        score: clampedScore,
        foodRuns: totalRuns,
        shifts: shiftsWorked,
      ));
    }

    // Sort by date
    trends.sort((a, b) => a.date.compareTo(b.date));

    return trends;
  }

  /// Get the start of the week (Monday) for a given date
  static DateTime _getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    final monday = date.subtract(Duration(days: daysFromMonday));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Helper method to get performance rating from score
  static PerformanceRating _getRatingFromScore(double score) {
    if (score >= 90.0) return PerformanceRating.elite;
    if (score >= 75.0) return PerformanceRating.strong;
    if (score >= 60.0) return PerformanceRating.developing;
    if (score >= 45.0) return PerformanceRating.needsAttention;
    return PerformanceRating.critical;
  }
}
