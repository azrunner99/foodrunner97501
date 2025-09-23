/// Comprehensive Shift Data Models
/// Extended data capture for advanced analytics and correlations

import 'package:intl/intl.dart';

/// Enhanced shift completion data with all performance metrics
class ComprehensiveShiftData {
  final String shiftId;
  final DateTime shiftDate;
  final String shiftType; // Lunch, Dinner
  final DateTime startTime;
  final DateTime endTime;
  final List<ServerShiftPerformance> serverPerformances;
  final Map<String, SectionPerformance> sectionPerformances;
  final ShiftBusinessMetrics businessMetrics;
  final Map<String, StationMetrics> stationMetrics;
  final List<ShiftCorrelation> correlations;

  ComprehensiveShiftData({
    required this.shiftId,
    required this.shiftDate,
    required this.shiftType,
    required this.startTime,
    required this.endTime,
    required this.serverPerformances,
    required this.sectionPerformances,
    required this.businessMetrics,
    required this.stationMetrics,
    required this.correlations,
  });

  double get totalShiftHours => endTime.difference(startTime).inMinutes / 60.0;
  int get totalRuns => serverPerformances.fold(0, (sum, sp) => sum + sp.totalRuns);
  double get totalSales => businessMetrics.totalSales;
  double get runsPerHour => totalShiftHours > 0 ? totalRuns / totalShiftHours : 0;
  double get salesPerRun => totalRuns > 0 ? totalSales / totalRuns : 0;

  Map<String, dynamic> toMap() => {
    'shiftId': shiftId,
    'shiftDate': shiftDate.toIso8601String(),
    'shiftType': shiftType,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'serverPerformances': serverPerformances.map((sp) => sp.toMap()).toList(),
    'sectionPerformances': sectionPerformances.map((k, v) => MapEntry(k, v.toMap())),
    'businessMetrics': businessMetrics.toMap(),
    'stationMetrics': stationMetrics.map((k, v) => MapEntry(k, v.toMap())),
    'correlations': correlations.map((c) => c.toMap()).toList(),
  };

  factory ComprehensiveShiftData.fromMap(Map<String, dynamic> map) {
    return ComprehensiveShiftData(
      shiftId: map['shiftId'],
      shiftDate: DateTime.parse(map['shiftDate']),
      shiftType: map['shiftType'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      serverPerformances: (map['serverPerformances'] as List)
          .map((sp) => ServerShiftPerformance.fromMap(sp))
          .toList(),
      sectionPerformances: (map['sectionPerformances'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, SectionPerformance.fromMap(v))),
      businessMetrics: ShiftBusinessMetrics.fromMap(map['businessMetrics']),
      stationMetrics: (map['stationMetrics'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, StationMetrics.fromMap(v))),
      correlations: (map['correlations'] as List)
          .map((c) => ShiftCorrelation.fromMap(c))
          .toList(),
    );
  }
}

/// Individual server performance during a shift
class ServerShiftPerformance {
  final String serverId;
  final String serverName;
  final String? assignedStation;
  final String? assignedSection;
  final int totalRuns;
  final int pizookieRuns;
  final double hoursWorked;
  final double? tipAmount;
  final double? salesGenerated;
  final int? tablesServed;
  final double? averageTicketSize;
  final List<RunTimestamp> runTimestamps;
  final Map<String, dynamic> performanceMetrics;

  ServerShiftPerformance({
    required this.serverId,
    required this.serverName,
    this.assignedStation,
    this.assignedSection,
    required this.totalRuns,
    required this.pizookieRuns,
    required this.hoursWorked,
    this.tipAmount,
    this.salesGenerated,
    this.tablesServed,
    this.averageTicketSize,
    required this.runTimestamps,
    required this.performanceMetrics,
  });

  double get runsPerHour => hoursWorked > 0 ? totalRuns / hoursWorked : 0;
  double get salesPerHour => (hoursWorked > 0 && salesGenerated != null) ? salesGenerated! / hoursWorked : 0;
  double get tipsPerHour => (hoursWorked > 0 && tipAmount != null) ? tipAmount! / hoursWorked : 0;
  double get salesPerRun => (totalRuns > 0 && salesGenerated != null) ? salesGenerated! / totalRuns : 0;
  double get efficiencyScore => _calculateEfficiencyScore();

  double _calculateEfficiencyScore() {
    double score = 0;
    score += (runsPerHour / 10) * 30; // 30% weight for runs/hour (target: 10/hour)
    score += (salesPerHour / 200) * 25; // 25% weight for sales/hour (target: $200/hour)
    score += (tipsPerHour / 25) * 20; // 20% weight for tips/hour (target: $25/hour)
    score += ((averageTicketSize ?? 0) / 30) * 15; // 15% weight for ticket size (target: $30)
    score += ((tablesServed ?? 0) / hoursWorked / 3) * 10; // 10% weight for tables/hour (target: 3/hour)
    return (score * 100).clamp(0, 100);
  }

  Map<String, dynamic> toMap() => {
    'serverId': serverId,
    'serverName': serverName,
    'assignedStation': assignedStation,
    'assignedSection': assignedSection,
    'totalRuns': totalRuns,
    'pizookieRuns': pizookieRuns,
    'hoursWorked': hoursWorked,
    'tipAmount': tipAmount,
    'salesGenerated': salesGenerated,
    'tablesServed': tablesServed,
    'averageTicketSize': averageTicketSize,
    'runTimestamps': runTimestamps.map((rt) => rt.toMap()).toList(),
    'performanceMetrics': performanceMetrics,
  };

  factory ServerShiftPerformance.fromMap(Map<String, dynamic> map) {
    return ServerShiftPerformance(
      serverId: map['serverId'],
      serverName: map['serverName'],
      assignedStation: map['assignedStation'],
      assignedSection: map['assignedSection'],
      totalRuns: map['totalRuns'],
      pizookieRuns: map['pizookieRuns'],
      hoursWorked: map['hoursWorked'],
      tipAmount: map['tipAmount'],
      salesGenerated: map['salesGenerated'],
      tablesServed: map['tablesServed'],
      averageTicketSize: map['averageTicketSize'],
      runTimestamps: (map['runTimestamps'] as List)
          .map((rt) => RunTimestamp.fromMap(rt))
          .toList(),
      performanceMetrics: Map<String, dynamic>.from(map['performanceMetrics']),
    );
  }
}

/// Section performance metrics
class SectionPerformance {
  final String sectionId;
  final String sectionName;
  final int tableCount;
  final double totalSales;
  final int totalTables;
  final double averageTicketSize;
  final double turnRate; // tables per hour
  final List<String> assignedServerIds;
  final Map<String, double> serverContributions; // serverId -> % of section sales

  SectionPerformance({
    required this.sectionId,
    required this.sectionName,
    required this.tableCount,
    required this.totalSales,
    required this.totalTables,
    required this.averageTicketSize,
    required this.turnRate,
    required this.assignedServerIds,
    required this.serverContributions,
  });

  double get salesPerTable => totalTables > 0 ? totalSales / totalTables : 0;
  double get utilizationRate => tableCount > 0 ? totalTables / tableCount : 0;

  Map<String, dynamic> toMap() => {
    'sectionId': sectionId,
    'sectionName': sectionName,
    'tableCount': tableCount,
    'totalSales': totalSales,
    'totalTables': totalTables,
    'averageTicketSize': averageTicketSize,
    'turnRate': turnRate,
    'assignedServerIds': assignedServerIds,
    'serverContributions': serverContributions,
  };

  factory SectionPerformance.fromMap(Map<String, dynamic> map) {
    return SectionPerformance(
      sectionId: map['sectionId'],
      sectionName: map['sectionName'],
      tableCount: map['tableCount'],
      totalSales: map['totalSales'],
      totalTables: map['totalTables'],
      averageTicketSize: map['averageTicketSize'],
      turnRate: map['turnRate'],
      assignedServerIds: List<String>.from(map['assignedServerIds']),
      serverContributions: Map<String, double>.from(map['serverContributions']),
    );
  }
}

/// Business metrics for the entire shift
class ShiftBusinessMetrics {
  final double totalSales;
  final double totalTips;
  final int totalCovers; // number of guests
  final int totalTables;
  final double averageTicketSize;
  final double laborCost;
  final double laborPercentage;
  final double salesPerCover;
  final double tipsPercentage;
  final Map<String, double> categoryBreakdown; // food, beverage, etc.

  ShiftBusinessMetrics({
    required this.totalSales,
    required this.totalTips,
    required this.totalCovers,
    required this.totalTables,
    required this.averageTicketSize,
    required this.laborCost,
    required this.laborPercentage,
    required this.salesPerCover,
    required this.tipsPercentage,
    required this.categoryBreakdown,
  });

  Map<String, dynamic> toMap() => {
    'totalSales': totalSales,
    'totalTips': totalTips,
    'totalCovers': totalCovers,
    'totalTables': totalTables,
    'averageTicketSize': averageTicketSize,
    'laborCost': laborCost,
    'laborPercentage': laborPercentage,
    'salesPerCover': salesPerCover,
    'tipsPercentage': tipsPercentage,
    'categoryBreakdown': categoryBreakdown,
  };

  factory ShiftBusinessMetrics.fromMap(Map<String, dynamic> map) {
    return ShiftBusinessMetrics(
      totalSales: map['totalSales'],
      totalTips: map['totalTips'],
      totalCovers: map['totalCovers'],
      totalTables: map['totalTables'],
      averageTicketSize: map['averageTicketSize'],
      laborCost: map['laborCost'],
      laborPercentage: map['laborPercentage'],
      salesPerCover: map['salesPerCover'],
      tipsPercentage: map['tipsPercentage'],
      categoryBreakdown: Map<String, double>.from(map['categoryBreakdown']),
    );
  }
}

/// Station-specific metrics
class StationMetrics {
  final String stationType;
  final int totalRuns;
  final double totalSales;
  final double averageRunTime; // minutes
  final double efficiencyScore;
  final List<String> assignedServerIds;
  final Map<String, int> serverRunContributions;
  final double salesPerRun;

  StationMetrics({
    required this.stationType,
    required this.totalRuns,
    required this.totalSales,
    required this.averageRunTime,
    required this.efficiencyScore,
    required this.assignedServerIds,
    required this.serverRunContributions,
    required this.salesPerRun,
  });

  Map<String, dynamic> toMap() => {
    'stationType': stationType,
    'totalRuns': totalRuns,
    'totalSales': totalSales,
    'averageRunTime': averageRunTime,
    'efficiencyScore': efficiencyScore,
    'assignedServerIds': assignedServerIds,
    'serverRunContributions': serverRunContributions,
    'salesPerRun': salesPerRun,
  };

  factory StationMetrics.fromMap(Map<String, dynamic> map) {
    return StationMetrics(
      stationType: map['stationType'],
      totalRuns: map['totalRuns'],
      totalSales: map['totalSales'],
      averageRunTime: map['averageRunTime'],
      efficiencyScore: map['efficiencyScore'],
      assignedServerIds: List<String>.from(map['assignedServerIds']),
      serverRunContributions: Map<String, int>.from(map['serverRunContributions']),
      salesPerRun: map['salesPerRun'],
    );
  }
}

/// Correlation analysis between variables
class ShiftCorrelation {
  final String correlationType;
  final String variable1;
  final String variable2;
  final double correlationCoefficient;
  final double significance;
  final String interpretation;
  final Map<String, dynamic> additionalData;

  ShiftCorrelation({
    required this.correlationType,
    required this.variable1,
    required this.variable2,
    required this.correlationCoefficient,
    required this.significance,
    required this.interpretation,
    required this.additionalData,
  });

  bool get isSignificant => significance < 0.05;
  bool get isStrongCorrelation => correlationCoefficient.abs() > 0.7;

  Map<String, dynamic> toMap() => {
    'correlationType': correlationType,
    'variable1': variable1,
    'variable2': variable2,
    'correlationCoefficient': correlationCoefficient,
    'significance': significance,
    'interpretation': interpretation,
    'additionalData': additionalData,
  };

  factory ShiftCorrelation.fromMap(Map<String, dynamic> map) {
    return ShiftCorrelation(
      correlationType: map['correlationType'],
      variable1: map['variable1'],
      variable2: map['variable2'],
      correlationCoefficient: map['correlationCoefficient'],
      significance: map['significance'],
      interpretation: map['interpretation'],
      additionalData: Map<String, dynamic>.from(map['additionalData']),
    );
  }
}

/// Individual run timestamp for detailed analysis
class RunTimestamp {
  final DateTime timestamp;
  final String runType; // 'food', 'beverage', 'pizookie'
  final String? toSection;
  final int? tableNumber;
  final double? associatedSales;

  RunTimestamp({
    required this.timestamp,
    required this.runType,
    this.toSection,
    this.tableNumber,
    this.associatedSales,
  });

  Map<String, dynamic> toMap() => {
    'timestamp': timestamp.toIso8601String(),
    'runType': runType,
    'toSection': toSection,
    'tableNumber': tableNumber,
    'associatedSales': associatedSales,
  };

  factory RunTimestamp.fromMap(Map<String, dynamic> map) {
    return RunTimestamp(
      timestamp: DateTime.parse(map['timestamp']),
      runType: map['runType'],
      toSection: map['toSection'],
      tableNumber: map['tableNumber'],
      associatedSales: map['associatedSales'],
    );
  }
}