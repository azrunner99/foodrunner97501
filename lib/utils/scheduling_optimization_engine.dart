import 'dart:math' as math;
import '../models.dart';
import '../models/performance_models.dart';
import '../app_state.dart';
import '../utils/performance_calculator.dart';

/// Intelligent scheduling optimization engine
/// Provides data-driven scheduling recommendations based on performance analysis
class SchedulingOptimizationEngine {
  static const double _minimumPerformanceThreshold = 60.0;
  static const int _historicalDataDays = 60;

  /// Generate optimal shift schedule recommendations
  static Future<ScheduleRecommendation> generateOptimalSchedule({
    required List<Server> availableServers,
    required DateTime scheduleDate,
    required ShiftType shiftType,
    required int targetTeamSize,
    Map<String, dynamic>? businessProjections,
    List<String>? unavailableServerIds,
  }) async {
    final unavailable = unavailableServerIds ?? [];
    final eligibleServers =
        availableServers.where((s) => !unavailable.contains(s.id)).toList();

    if (eligibleServers.length < targetTeamSize) {
      return ScheduleRecommendation(
        scheduleDate: scheduleDate,
        shiftType: shiftType,
        recommendedTeam: TeamRecommendation(
          servers: [],
          teamProfiles: [],
          averagePerformance: 0.0,
          teamSynergy: 0.0,
          balanceScore: 0.0,
        ),
        alternativeTeams: [],
        teamScore: 0.0,
        confidence: 0.0,
        warnings: ['Insufficient available servers for optimal team size'],
        optimizationNotes: [],
      );
    }

    // Analyze server performance for the specific shift type and day
    final serverAnalytics = await _analyzeServerPerformanceProfiles(
      eligibleServers,
      shiftType,
      scheduleDate,
    );

    // Generate primary team recommendation
    final primaryTeam = _generateOptimalTeam(
      serverAnalytics,
      targetTeamSize,
      shiftType,
    );

    // Generate alternative team configurations
    final alternativeTeams = _generateAlternativeTeams(
      serverAnalytics,
      targetTeamSize,
      shiftType,
      excludeTeam: primaryTeam.servers,
    );

    // Calculate team synergy and balance scores
    final teamScore = _calculateTeamScore(primaryTeam, shiftType);
    final confidence =
        _calculateRecommendationConfidence(primaryTeam, serverAnalytics);

    // Generate optimization insights and warnings
    final warnings = _generateSchedulingWarnings(primaryTeam, serverAnalytics);
    final optimizationNotes =
        _generateOptimizationNotes(primaryTeam, serverAnalytics);

    return ScheduleRecommendation(
      scheduleDate: scheduleDate,
      shiftType: shiftType,
      recommendedTeam: primaryTeam,
      alternativeTeams: alternativeTeams,
      teamScore: teamScore,
      confidence: confidence,
      warnings: warnings,
      optimizationNotes: optimizationNotes,
    );
  }

  /// Analyze historical patterns for optimal team sizing
  static Future<TeamSizeRecommendation> analyzeOptimalTeamSize({
    required ShiftType shiftType,
    required DateTime targetDate,
    Map<String, dynamic>? businessProjections,
  }) async {
    final appState = AppState();
    final historicalShifts = appState.history;

    // Filter shifts by type and recent history
    final relevantShifts = historicalShifts.where((shift) {
      final shiftDate = shift.start;
      final daysDifference = targetDate.difference(shiftDate).inDays;
      return daysDifference >= 0 &&
          daysDifference <= _historicalDataDays &&
          shift.shiftType.toLowerCase() == shiftType.name.toLowerCase();
    }).toList();

    if (relevantShifts.length < 10) {
      return TeamSizeRecommendation(
        recommendedSize: 4, // Default
        confidenceLevel: 0.3,
        historicalAnalysis: 'Insufficient historical data',
        projectedWorkload: WorkloadProjection.medium,
        recommendations: ['Use default team size due to limited data'],
      );
    }

    // Analyze team performance vs team size
    final teamSizeAnalysis = _analyzeTeamSizePerformance(relevantShifts);

    // Consider business projections if available
    var workloadProjection = WorkloadProjection.medium;
    if (businessProjections != null) {
      workloadProjection =
          _calculateWorkloadProjection(businessProjections, targetDate);
    }

    // Calculate optimal team size based on analysis
    final optimalSize =
        _calculateOptimalTeamSize(teamSizeAnalysis, workloadProjection);
    final confidence = _calculateTeamSizeConfidence(teamSizeAnalysis);

    return TeamSizeRecommendation(
      recommendedSize: optimalSize,
      confidenceLevel: confidence,
      historicalAnalysis: _generateTeamSizeAnalysis(teamSizeAnalysis),
      projectedWorkload: workloadProjection,
      recommendations:
          _generateTeamSizeRecommendations(optimalSize, workloadProjection),
    );
  }

  /// Generate personalized server scheduling recommendations
  static Future<Map<String, ServerScheduleRecommendation>>
      generateServerRecommendations({
    required List<Server> servers,
    required DateRange schedulingPeriod,
  }) async {
    final recommendations = <String, ServerScheduleRecommendation>{};

    for (final server in servers) {
      final performance =
          await _getServerPerformanceAnalysis(server.id, schedulingPeriod);
      final workloadCapacity =
          _calculateServerWorkloadCapacity(server.id, performance);
      final optimalShifts =
          _identifyOptimalShiftsForServer(server.id, performance);
      final restRecommendations =
          _calculateRestRecommendations(server.id, performance);

      recommendations[server.id] = ServerScheduleRecommendation(
        serverId: server.id,
        serverName: server.name,
        performanceProfile: performance,
        workloadCapacity: workloadCapacity,
        optimalShiftTypes: optimalShifts,
        recommendedShiftsPerWeek:
            _calculateRecommendedShiftsPerWeek(workloadCapacity),
        restDaysNeeded: restRecommendations.daysNeeded,
        schedulingPriority: _calculateSchedulingPriority(performance),
        strengths: _identifyServerStrengths(performance),
        developmentAreas: _identifyDevelopmentAreas(performance),
        notes: _generateServerSchedulingNotes(performance),
      );
    }

    return recommendations;
  }

  /// Detect scheduling conflicts and provide resolutions
  static List<SchedulingConflict> detectSchedulingConflicts({
    required List<TeamRecommendation> proposedSchedule,
    required List<Server> allServers,
  }) {
    final conflicts = <SchedulingConflict>[];

    // Check for over-scheduling
    final serverScheduleCounts = <String, int>{};
    for (final team in proposedSchedule) {
      for (final serverId in team.servers) {
        serverScheduleCounts[serverId] =
            (serverScheduleCounts[serverId] ?? 0) + 1;
      }
    }

    for (final entry in serverScheduleCounts.entries) {
      if (entry.value > 5) {
        // More than 5 shifts per week
        final server = allServers.firstWhere((s) => s.id == entry.key);
        conflicts.add(SchedulingConflict(
          type: ConflictType.overScheduling,
          serverId: entry.key,
          serverName: server.name,
          description:
              'Server scheduled for ${entry.value} shifts (exceeds recommended maximum)',
          severity: ConflictSeverity.high,
          suggestions: [
            'Reduce shift count to 4-5 per week',
            'Consider redistributing shifts to other servers',
            'Schedule additional rest days',
          ],
        ));
      }
    }

    // Check for performance-based conflicts
    for (final team in proposedSchedule) {
      final teamPerformanceIssues = _detectTeamPerformanceConflicts(team);
      conflicts.addAll(teamPerformanceIssues);
    }

    return conflicts;
  }

  /// Analyze server performance profiles for scheduling
  static Future<Map<String, ServerPerformanceProfile>>
      _analyzeServerPerformanceProfiles(
    List<Server> servers,
    ShiftType shiftType,
    DateTime scheduleDate,
  ) async {
    final profiles = <String, ServerPerformanceProfile>{};
    final appState = AppState();
    final shifts = appState.history;

    for (final server in servers) {
      // Calculate recent performance
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));

      final performance = PerformanceCalculator.calculateServerPerformance(
        serverId: server.id,
        startDate: startDate,
        endDate: endDate,
        shifts: shifts,
        businessData: null,
        hireDate: DateTime.now().subtract(const Duration(days: 90)),
      );

      // Analyze shift type preference
      final shiftTypePerformance =
          _analyzeShiftTypePerformance(server.id, shifts, shiftType);

      // Analyze day of week patterns
      final dayOfWeekPerformance =
          _analyzeDayOfWeekPerformance(server.id, shifts, scheduleDate.weekday);

      // Calculate availability and reliability
      final reliability = _calculateServerReliability(server.id, shifts);

      profiles[server.id] = ServerPerformanceProfile(
        serverId: server.id,
        serverName: server.name,
        overallPerformance: performance,
        shiftTypeEfficiency: shiftTypePerformance,
        dayOfWeekEfficiency: dayOfWeekPerformance,
        reliabilityScore: reliability,
        preferredShiftTypes: _identifyPreferredShiftTypes(server.id, shifts),
        optimalDaysOfWeek: _identifyOptimalDaysOfWeek(server.id, shifts),
        currentWorkload: _calculateCurrentWorkload(server.id, shifts),
        fatigueLevel: _calculateFatigueLevel(server.id, shifts),
      );
    }

    return profiles;
  }

  /// Generate optimal team composition
  static TeamRecommendation _generateOptimalTeam(
    Map<String, ServerPerformanceProfile> serverProfiles,
    int targetSize,
    ShiftType shiftType,
  ) {
    final eligibleProfiles = serverProfiles.values
        .where((p) =>
            p.overallPerformance.performanceScore >=
            _minimumPerformanceThreshold)
        .toList();

    // Sort by shift-specific performance
    eligibleProfiles.sort((a, b) {
      final aScore = a.shiftTypeEfficiency * 0.4 +
          a.overallPerformance.performanceScore * 0.3 +
          a.reliabilityScore * 0.3;
      final bScore = b.shiftTypeEfficiency * 0.4 +
          b.overallPerformance.performanceScore * 0.3 +
          b.reliabilityScore * 0.3;
      return bScore.compareTo(aScore);
    });

    // Select team with balance considerations
    final selectedServers = <String>[];
    final selectedProfiles = <ServerPerformanceProfile>[];

    // Always include top performer
    if (eligibleProfiles.isNotEmpty) {
      selectedServers.add(eligibleProfiles[0].serverId);
      selectedProfiles.add(eligibleProfiles[0]);
    }

    // Add remaining servers balancing performance and diversity
    for (int i = 1;
        i < eligibleProfiles.length && selectedServers.length < targetSize;
        i++) {
      final candidate = eligibleProfiles[i];

      // Check if adding this server improves team balance
      if (_wouldImproveTeamBalance(selectedProfiles, candidate)) {
        selectedServers.add(candidate.serverId);
        selectedProfiles.add(candidate);
      }
    }

    // Fill remaining slots if needed
    while (selectedServers.length < targetSize &&
        selectedServers.length < eligibleProfiles.length) {
      for (final profile in eligibleProfiles) {
        if (!selectedServers.contains(profile.serverId)) {
          selectedServers.add(profile.serverId);
          selectedProfiles.add(profile);
          break;
        }
      }
    }

    return TeamRecommendation(
      servers: selectedServers,
      teamProfiles: selectedProfiles,
      averagePerformance: selectedProfiles.isNotEmpty
          ? selectedProfiles
                  .map((p) => p.overallPerformance.performanceScore)
                  .reduce((a, b) => a + b) /
              selectedProfiles.length
          : 0.0,
      teamSynergy: _calculateTeamSynergy(selectedProfiles),
      balanceScore: _calculateTeamBalance(selectedProfiles),
    );
  }

  /// Generate alternative team configurations
  static List<TeamRecommendation> _generateAlternativeTeams(
      Map<String, ServerPerformanceProfile> serverProfiles,
      int targetSize,
      ShiftType shiftType,
      {List<String>? excludeTeam}) {
    final alternatives = <TeamRecommendation>[];
    final exclude = excludeTeam ?? [];

    // Generate 2-3 alternative configurations
    for (int alt = 0; alt < 3; alt++) {
      final availableProfiles = serverProfiles.values
          .where((p) => !exclude.contains(p.serverId))
          .toList();

      if (availableProfiles.length < targetSize) break;

      // Use different optimization strategies for each alternative
      final team = _generateAlternativeTeamConfiguration(
        availableProfiles,
        targetSize,
        alt,
      );

      if (team.servers.isNotEmpty) {
        alternatives.add(team);
        exclude.addAll(team.servers);
      }
    }

    return alternatives;
  }

  /// Calculate team performance score
  static double _calculateTeamScore(
      TeamRecommendation team, ShiftType shiftType) {
    if (team.teamProfiles.isEmpty) return 0.0;

    final performanceWeight = 0.4;
    final synergyWeight = 0.3;
    final balanceWeight = 0.3;

    return (team.averagePerformance * performanceWeight) +
        (team.teamSynergy * synergyWeight) +
        (team.balanceScore * balanceWeight);
  }

  /// Calculate recommendation confidence
  static double _calculateRecommendationConfidence(
    TeamRecommendation team,
    Map<String, ServerPerformanceProfile> allProfiles,
  ) {
    if (team.teamProfiles.isEmpty) return 0.0;

    // Base confidence on data quality and team stability
    final dataQuality = team.teamProfiles
            .map((p) => p.overallPerformance.shiftsWorked > 10 ? 1.0 : 0.5)
            .reduce((a, b) => a + b) /
        team.teamProfiles.length;

    final performanceStability = 1.0 -
        (team.teamProfiles
                .map((p) =>
                    p.overallPerformance.metrics.consistencyScore / 100.0)
                .reduce((a, b) => a + b) /
            team.teamProfiles.length);

    return (dataQuality + performanceStability) / 2.0;
  }

  /// Generate scheduling warnings
  static List<String> _generateSchedulingWarnings(
    TeamRecommendation team,
    Map<String, ServerPerformanceProfile> profiles,
  ) {
    final warnings = <String>[];

    for (final profile in team.teamProfiles) {
      if (profile.fatigueLevel > 0.8) {
        warnings.add('${profile.serverName} shows high fatigue levels');
      }

      if (profile.currentWorkload > 0.9) {
        warnings.add('${profile.serverName} has very high current workload');
      }

      if (profile.reliabilityScore < 0.7) {
        warnings.add('${profile.serverName} has lower reliability score');
      }
    }

    return warnings;
  }

  /// Generate optimization notes
  static List<String> _generateOptimizationNotes(
    TeamRecommendation team,
    Map<String, ServerPerformanceProfile> profiles,
  ) {
    final notes = <String>[];

    if (team.averagePerformance > 85.0) {
      notes.add('High-performing team selected with strong track record');
    }

    if (team.teamSynergy > 80.0) {
      notes.add('Team shows excellent synergy and collaboration potential');
    }

    final experiencedServers = team.teamProfiles
        .where((p) => p.overallPerformance.daysEmployed > 90)
        .length;
    if (experiencedServers >= team.teamProfiles.length * 0.6) {
      notes.add('Team has good experience balance for training newer servers');
    }

    return notes;
  }

  /// Analyze team size performance from historical data
  static Map<int, double> _analyzeTeamSizePerformance(
      List<ShiftRecord> shifts) {
    final teamSizePerformance = <int, List<double>>{};

    for (final shift in shifts) {
      final teamSize = shift.counts.values.where((count) => count > 0).length;
      final totalRuns =
          shift.counts.values.fold<int>(0, (sum, count) => sum + count);
      final efficiency = teamSize > 0 ? totalRuns / teamSize : 0.0;

      teamSizePerformance.putIfAbsent(teamSize, () => []).add(efficiency);
    }

    final averages = <int, double>{};
    for (final entry in teamSizePerformance.entries) {
      if (entry.value.isNotEmpty) {
        averages[entry.key] =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }

    return averages;
  }

  /// Calculate workload projection
  static WorkloadProjection _calculateWorkloadProjection(
    Map<String, dynamic> businessProjections,
    DateTime targetDate,
  ) {
    // Analyze business projections to determine expected workload
    final projectedSales =
        businessProjections['projectedSales'] as double? ?? 1.0;
    final projectedGuests =
        businessProjections['projectedGuests'] as double? ?? 1.0;
    final seasonalFactor =
        businessProjections['seasonalFactor'] as double? ?? 1.0;

    final workloadMultiplier =
        (projectedSales + projectedGuests + seasonalFactor) / 3.0;

    if (workloadMultiplier > 1.3) return WorkloadProjection.high;
    if (workloadMultiplier > 1.1) return WorkloadProjection.medium;
    if (workloadMultiplier < 0.8) return WorkloadProjection.low;
    return WorkloadProjection.medium;
  }

  /// Calculate optimal team size
  static int _calculateOptimalTeamSize(
    Map<int, double> teamSizeAnalysis,
    WorkloadProjection workload,
  ) {
    if (teamSizeAnalysis.isEmpty) return 4; // Default

    // Find the team size with best efficiency
    var bestSize = 4;
    var bestEfficiency = 0.0;

    for (final entry in teamSizeAnalysis.entries) {
      if (entry.value > bestEfficiency && entry.key >= 3 && entry.key <= 8) {
        bestEfficiency = entry.value;
        bestSize = entry.key;
      }
    }

    // Adjust based on workload projection
    switch (workload) {
      case WorkloadProjection.high:
        bestSize = math.min(bestSize + 1, 8);
        break;
      case WorkloadProjection.low:
        bestSize = math.max(bestSize - 1, 3);
        break;
      case WorkloadProjection.medium:
        // Keep optimal size
        break;
    }

    return bestSize;
  }

  /// Helper methods for detailed analysis
  static double _analyzeShiftTypePerformance(
      String serverId, List<ShiftRecord> shifts, ShiftType shiftType) {
    final relevantShifts = shifts
        .where((s) =>
            s.shiftType.toLowerCase() == shiftType.name.toLowerCase() &&
            s.counts.containsKey(serverId))
        .toList();

    if (relevantShifts.isEmpty) return 50.0; // Neutral score

    final totalRuns = relevantShifts.fold<int>(
        0, (sum, shift) => sum + (shift.counts[serverId] ?? 0));
    return (totalRuns / relevantShifts.length) * 10; // Scale to 0-100
  }

  static double _analyzeDayOfWeekPerformance(
      String serverId, List<ShiftRecord> shifts, int weekday) {
    final relevantShifts = shifts
        .where(
            (s) => s.start.weekday == weekday && s.counts.containsKey(serverId))
        .toList();

    if (relevantShifts.isEmpty) return 50.0; // Neutral score

    final totalRuns = relevantShifts.fold<int>(
        0, (sum, shift) => sum + (shift.counts[serverId] ?? 0));
    return (totalRuns / relevantShifts.length) * 10; // Scale to 0-100
  }

  static double _calculateServerReliability(
      String serverId, List<ShiftRecord> shifts) {
    final recentShifts = shifts
        .where((s) =>
            s.start
                .isAfter(DateTime.now().subtract(const Duration(days: 30))) &&
            s.counts.containsKey(serverId))
        .toList();

    if (recentShifts.isEmpty) return 0.5; // Neutral score

    // Calculate consistency of attendance and performance
    final performances =
        recentShifts.map((s) => s.counts[serverId] ?? 0).toList();
    if (performances.isEmpty) return 0.5;

    final avg = performances.reduce((a, b) => a + b) / performances.length;
    final variance =
        performances.map((p) => math.pow(p - avg, 2)).reduce((a, b) => a + b) /
            performances.length;
    final cv = avg > 0 ? math.sqrt(variance) / avg : 1.0;

    return math.max(
        0.0, 1.0 - cv); // Lower coefficient of variation = higher reliability
  }

  static List<ShiftType> _identifyPreferredShiftTypes(
      String serverId, List<ShiftRecord> shifts) {
    final shiftTypePerformance = <String, double>{};

    for (final shiftTypeName in ['lunch', 'dinner']) {
      final performance = _analyzeShiftTypePerformance(serverId, shifts,
          shiftTypeName == 'lunch' ? ShiftType.lunch : ShiftType.dinner);
      shiftTypePerformance[shiftTypeName] = performance;
    }

    // Return shift types with above-average performance
    final avgPerformance = shiftTypePerformance.values.reduce((a, b) => a + b) /
        shiftTypePerformance.length;
    return shiftTypePerformance.entries
        .where((e) => e.value > avgPerformance)
        .map((e) => e.key == 'lunch' ? ShiftType.lunch : ShiftType.dinner)
        .toList();
  }

  static List<int> _identifyOptimalDaysOfWeek(
      String serverId, List<ShiftRecord> shifts) {
    final dayPerformance = <int, double>{};

    for (int day = 1; day <= 7; day++) {
      dayPerformance[day] = _analyzeDayOfWeekPerformance(serverId, shifts, day);
    }

    final avgPerformance =
        dayPerformance.values.reduce((a, b) => a + b) / dayPerformance.length;
    return dayPerformance.entries
        .where((e) => e.value > avgPerformance)
        .map((e) => e.key)
        .toList();
  }

  static double _calculateCurrentWorkload(
      String serverId, List<ShiftRecord> shifts) {
    final recentShifts = shifts
        .where((s) =>
            s.start.isAfter(DateTime.now().subtract(const Duration(days: 7))) &&
            s.counts.containsKey(serverId))
        .length;

    return math.min(
        recentShifts / 5.0, 1.0); // Normalize to 0-1 (5 shifts/week = 100%)
  }

  static double _calculateFatigueLevel(
      String serverId, List<ShiftRecord> shifts) {
    final recentShifts = shifts
        .where((s) =>
            s.start
                .isAfter(DateTime.now().subtract(const Duration(days: 14))) &&
            s.counts.containsKey(serverId))
        .toList();

    if (recentShifts.length < 3) return 0.0;

    // Check for declining performance pattern
    final performances =
        recentShifts.map((s) => s.counts[serverId] ?? 0).toList();
    final firstHalf = performances.take(performances.length ~/ 2).toList();
    final secondHalf = performances.skip(performances.length ~/ 2).toList();

    if (firstHalf.isEmpty || secondHalf.isEmpty) return 0.0;

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    final decline = firstAvg > 0 ? (firstAvg - secondAvg) / firstAvg : 0.0;
    return math.max(0.0, math.min(decline, 1.0));
  }

  static bool _wouldImproveTeamBalance(
      List<ServerPerformanceProfile> currentTeam,
      ServerPerformanceProfile candidate) {
    if (currentTeam.isEmpty) return true;

    // Check if candidate adds diversity to experience levels
    final currentExperienceLevels =
        currentTeam.map((p) => p.overallPerformance.daysEmployed).toList();
    final avgExperience = currentExperienceLevels.reduce((a, b) => a + b) /
        currentExperienceLevels.length;

    // Prefer candidates that balance experience
    if (avgExperience > 120 && candidate.overallPerformance.daysEmployed < 90)
      return true;
    if (avgExperience < 60 && candidate.overallPerformance.daysEmployed > 120)
      return true;

    return true; // Default to accepting
  }

  static double _calculateTeamSynergy(List<ServerPerformanceProfile> profiles) {
    if (profiles.length < 2) return 50.0;

    // Calculate based on performance complementarity and reliability
    final avgReliability =
        profiles.map((p) => p.reliabilityScore).reduce((a, b) => a + b) /
            profiles.length;
    final performanceVariance = _calculateVariance(
        profiles.map((p) => p.overallPerformance.performanceScore).toList());

    // Lower variance = better synergy (more consistent team)
    final synergyScore = (avgReliability * 100) - (performanceVariance * 2);
    return math.max(0.0, math.min(synergyScore, 100.0));
  }

  static double _calculateTeamBalance(List<ServerPerformanceProfile> profiles) {
    if (profiles.isEmpty) return 0.0;

    // Balance based on experience and performance distribution
    final experienceLevels =
        profiles.map((p) => p.overallPerformance.daysEmployed).toList();
    final performanceLevels =
        profiles.map((p) => p.overallPerformance.performanceScore).toList();

    final experienceBalance = 100.0 -
        _calculateVariance(experienceLevels.map((e) => e.toDouble()).toList());
    final performanceBalance = 100.0 - _calculateVariance(performanceLevels);

    return (experienceBalance + performanceBalance) / 2.0;
  }

  static double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) /
            values.length;
    return variance;
  }

  static TeamRecommendation _generateAlternativeTeamConfiguration(
    List<ServerPerformanceProfile> availableProfiles,
    int targetSize,
    int alternativeIndex,
  ) {
    // Different strategies for each alternative
    List<ServerPerformanceProfile> selected;

    switch (alternativeIndex) {
      case 0: // Reliability-focused
        selected = availableProfiles.toList()
          ..sort((a, b) => b.reliabilityScore.compareTo(a.reliabilityScore));
        break;
      case 1: // Experience-balanced
        selected = _selectExperienceBalancedTeam(availableProfiles, targetSize);
        break;
      case 2: // High-potential focused
        selected = availableProfiles
            .where((p) => p.overallPerformance.performanceScore > 70.0)
            .toList()
          ..sort((a, b) => b.overallPerformance.performanceScore
              .compareTo(a.overallPerformance.performanceScore));
        break;
      default:
        selected = availableProfiles.toList();
    }

    final teamServers =
        selected.take(targetSize).map((p) => p.serverId).toList();
    final teamProfiles = selected.take(targetSize).toList();

    return TeamRecommendation(
      servers: teamServers,
      teamProfiles: teamProfiles,
      averagePerformance: teamProfiles.isNotEmpty
          ? teamProfiles
                  .map((p) => p.overallPerformance.performanceScore)
                  .reduce((a, b) => a + b) /
              teamProfiles.length
          : 0.0,
      teamSynergy: _calculateTeamSynergy(teamProfiles),
      balanceScore: _calculateTeamBalance(teamProfiles),
    );
  }

  static List<ServerPerformanceProfile> _selectExperienceBalancedTeam(
    List<ServerPerformanceProfile> profiles,
    int targetSize,
  ) {
    final experienced =
        profiles.where((p) => p.overallPerformance.daysEmployed > 120).toList();
    final intermediate = profiles
        .where((p) =>
            p.overallPerformance.daysEmployed > 60 &&
            p.overallPerformance.daysEmployed <= 120)
        .toList();
    final newer =
        profiles.where((p) => p.overallPerformance.daysEmployed <= 60).toList();

    final selected = <ServerPerformanceProfile>[];

    // Try to balance experience levels
    final experiencedCount =
        math.min(experienced.length, (targetSize * 0.4).ceil());
    final intermediateCount =
        math.min(intermediate.length, (targetSize * 0.4).ceil());
    final newerCount = targetSize - experiencedCount - intermediateCount;

    selected.addAll(experienced.take(experiencedCount));
    selected.addAll(intermediate.take(intermediateCount));
    selected.addAll(newer.take(math.max(0, newerCount)));

    // Fill remaining slots if needed
    while (selected.length < targetSize) {
      for (final profile in profiles) {
        if (!selected.contains(profile)) {
          selected.add(profile);
          break;
        }
      }
      if (selected.length == profiles.length) break;
    }

    return selected;
  }

  static Future<ServerPerformanceData> _getServerPerformanceAnalysis(
    String serverId,
    DateRange period,
  ) async {
    final appState = AppState();
    final shifts = appState.history;

    return PerformanceCalculator.calculateServerPerformance(
      serverId: serverId,
      startDate: period.start,
      endDate: period.end,
      shifts: shifts,
      businessData: null,
      hireDate: DateTime.now().subtract(const Duration(days: 90)),
    );
  }

  static WorkloadCapacity _calculateServerWorkloadCapacity(
    String serverId,
    ServerPerformanceData performance,
  ) {
    final efficiency = performance.metrics.rawEfficiency;
    final consistency = performance.metrics.consistencyScore;
    final experience = performance.daysEmployed;

    final capacityScore = (efficiency / 10 * 0.4) +
        (consistency / 100 * 0.3) +
        (math.min(experience / 180, 1.0) * 0.3);

    if (capacityScore > 0.8) return WorkloadCapacity.high;
    if (capacityScore > 0.6) return WorkloadCapacity.medium;
    return WorkloadCapacity.low;
  }

  static List<ShiftType> _identifyOptimalShiftsForServer(
    String serverId,
    ServerPerformanceData performance,
  ) {
    // This would analyze historical performance by shift type
    // For now, return both types as optimal
    return [ShiftType.lunch, ShiftType.dinner];
  }

  static RestRecommendations _calculateRestRecommendations(
    String serverId,
    ServerPerformanceData performance,
  ) {
    final workload = _calculateCurrentWorkload(serverId, AppState().history);
    final fatigue = _calculateFatigueLevel(serverId, AppState().history);

    var daysNeeded = 1; // Minimum one day off
    if (workload > 0.8 || fatigue > 0.6) daysNeeded = 2;
    if (workload > 0.9 || fatigue > 0.8) daysNeeded = 3;

    return RestRecommendations(
      daysNeeded: daysNeeded,
      reason: fatigue > 0.6
          ? 'High fatigue levels detected'
          : workload > 0.8
              ? 'High workload requires additional rest'
              : 'Standard rest period',
    );
  }

  static int _calculateRecommendedShiftsPerWeek(WorkloadCapacity capacity) {
    switch (capacity) {
      case WorkloadCapacity.high:
        return 5;
      case WorkloadCapacity.medium:
        return 4;
      case WorkloadCapacity.low:
        return 3;
    }
  }

  static SchedulingPriority _calculateSchedulingPriority(
      ServerPerformanceData performance) {
    if (performance.performanceScore > 85.0) return SchedulingPriority.high;
    if (performance.performanceScore > 70.0) return SchedulingPriority.medium;
    return SchedulingPriority.low;
  }

  static List<String> _identifyServerStrengths(
      ServerPerformanceData performance) {
    final strengths = <String>[];

    if (performance.metrics.rawEfficiency > 7.0)
      strengths.add('High efficiency');
    if (performance.metrics.consistencyScore > 80.0)
      strengths.add('Consistent performance');
    if (performance.performanceScore > 85.0)
      strengths.add('Overall excellence');
    if (performance.daysEmployed > 120)
      strengths.add('Experienced team member');

    return strengths;
  }

  static List<String> _identifyDevelopmentAreas(
      ServerPerformanceData performance) {
    final areas = <String>[];

    if (performance.metrics.rawEfficiency < 5.0)
      areas.add('Efficiency improvement needed');
    if (performance.metrics.consistencyScore < 70.0)
      areas.add('Consistency development');
    if (performance.performanceScore < 70.0)
      areas.add('Overall performance enhancement');

    return areas;
  }

  static List<String> _generateServerSchedulingNotes(
      ServerPerformanceData performance) {
    final notes = <String>[];

    if (performance.daysEmployed < 30) {
      notes.add('New server - consider pairing with experienced team members');
    }

    if (performance.metrics.consistencyScore > 90.0) {
      notes.add('Highly reliable - excellent for consistent scheduling');
    }

    if (performance.performanceScore > 95.0) {
      notes.add('Top performer - consider for leadership opportunities');
    }

    return notes;
  }

  static List<SchedulingConflict> _detectTeamPerformanceConflicts(
      TeamRecommendation team) {
    final conflicts = <SchedulingConflict>[];

    // Check for team balance issues
    if (team.balanceScore < 50.0) {
      conflicts.add(SchedulingConflict(
        type: ConflictType.teamBalance,
        description: 'Team lacks balance in experience or performance levels',
        severity: ConflictSeverity.medium,
        suggestions: [
          'Mix experienced and newer servers',
          'Balance high and moderate performers',
          'Consider team training opportunities',
        ],
      ));
    }

    // Check for low team synergy
    if (team.teamSynergy < 60.0) {
      conflicts.add(SchedulingConflict(
        type: ConflictType.teamSynergy,
        description: 'Low predicted team synergy',
        severity: ConflictSeverity.medium,
        suggestions: [
          'Review team member compatibility',
          'Consider alternative team configurations',
          'Focus on team building activities',
        ],
      ));
    }

    return conflicts;
  }

  static double _calculateTeamSizeConfidence(Map<int, double> analysis) {
    return analysis.isNotEmpty ? math.min(analysis.length / 5.0, 1.0) : 0.3;
  }

  static String _generateTeamSizeAnalysis(Map<int, double> analysis) {
    if (analysis.isEmpty) return 'Limited historical data available';

    final bestSize =
        analysis.entries.reduce((a, b) => a.value > b.value ? a : b);
    return 'Historical data shows team size ${bestSize.key} performs best with ${bestSize.value.toStringAsFixed(1)} average efficiency';
  }

  static List<String> _generateTeamSizeRecommendations(
      int optimalSize, WorkloadProjection workload) {
    final recommendations = <String>[];

    recommendations.add('Recommended team size: $optimalSize servers');

    switch (workload) {
      case WorkloadProjection.high:
        recommendations.add(
            'High workload expected - consider having backup servers available');
        break;
      case WorkloadProjection.low:
        recommendations.add(
            'Lower workload projected - opportunity for training newer servers');
        break;
      case WorkloadProjection.medium:
        recommendations.add(
            'Standard workload expected - maintain regular team composition');
        break;
    }

    return recommendations;
  }
}

/// Data classes for scheduling optimization

class ScheduleRecommendation {
  final DateTime scheduleDate;
  final ShiftType shiftType;
  final TeamRecommendation recommendedTeam;
  final List<TeamRecommendation> alternativeTeams;
  final double teamScore;
  final double confidence;
  final List<String> warnings;
  final List<String> optimizationNotes;

  ScheduleRecommendation({
    required this.scheduleDate,
    required this.shiftType,
    required this.recommendedTeam,
    required this.alternativeTeams,
    required this.teamScore,
    required this.confidence,
    required this.warnings,
    required this.optimizationNotes,
  });
}

class TeamRecommendation {
  final List<String> servers;
  final List<ServerPerformanceProfile> teamProfiles;
  final double averagePerformance;
  final double teamSynergy;
  final double balanceScore;

  TeamRecommendation({
    required this.servers,
    required this.teamProfiles,
    required this.averagePerformance,
    required this.teamSynergy,
    required this.balanceScore,
  });
}

class ServerPerformanceProfile {
  final String serverId;
  final String serverName;
  final ServerPerformanceData overallPerformance;
  final double shiftTypeEfficiency;
  final double dayOfWeekEfficiency;
  final double reliabilityScore;
  final List<ShiftType> preferredShiftTypes;
  final List<int> optimalDaysOfWeek;
  final double currentWorkload;
  final double fatigueLevel;

  ServerPerformanceProfile({
    required this.serverId,
    required this.serverName,
    required this.overallPerformance,
    required this.shiftTypeEfficiency,
    required this.dayOfWeekEfficiency,
    required this.reliabilityScore,
    required this.preferredShiftTypes,
    required this.optimalDaysOfWeek,
    required this.currentWorkload,
    required this.fatigueLevel,
  });
}

class TeamSizeRecommendation {
  final int recommendedSize;
  final double confidenceLevel;
  final String historicalAnalysis;
  final WorkloadProjection projectedWorkload;
  final List<String> recommendations;

  TeamSizeRecommendation({
    required this.recommendedSize,
    required this.confidenceLevel,
    required this.historicalAnalysis,
    required this.projectedWorkload,
    required this.recommendations,
  });
}

class ServerScheduleRecommendation {
  final String serverId;
  final String serverName;
  final ServerPerformanceData performanceProfile;
  final WorkloadCapacity workloadCapacity;
  final List<ShiftType> optimalShiftTypes;
  final int recommendedShiftsPerWeek;
  final int restDaysNeeded;
  final SchedulingPriority schedulingPriority;
  final List<String> strengths;
  final List<String> developmentAreas;
  final List<String> notes;

  ServerScheduleRecommendation({
    required this.serverId,
    required this.serverName,
    required this.performanceProfile,
    required this.workloadCapacity,
    required this.optimalShiftTypes,
    required this.recommendedShiftsPerWeek,
    required this.restDaysNeeded,
    required this.schedulingPriority,
    required this.strengths,
    required this.developmentAreas,
    required this.notes,
  });
}

class SchedulingConflict {
  final ConflictType type;
  final String? serverId;
  final String? serverName;
  final String description;
  final ConflictSeverity severity;
  final List<String> suggestions;

  SchedulingConflict({
    required this.type,
    this.serverId,
    this.serverName,
    required this.description,
    required this.severity,
    required this.suggestions,
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);
}

class RestRecommendations {
  final int daysNeeded;
  final String reason;

  RestRecommendations({
    required this.daysNeeded,
    required this.reason,
  });
}

enum ShiftType { lunch, dinner }

enum WorkloadProjection { low, medium, high }

enum WorkloadCapacity { low, medium, high }

enum SchedulingPriority { low, medium, high }

enum ConflictType { overScheduling, teamBalance, teamSynergy, performance }

enum ConflictSeverity { low, medium, high }
