import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:drift/native.dart' as drift_native;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:flutter/foundation.dart';
import '../utils/log.dart';

part 'unified_database.g.dart';

/// Unified Database for Food Runs Counter
/// 
/// This database consolidates all data storage into a single SQLite database
/// using Drift ORM. It replaces the previous multi-storage architecture
/// (Hive + SQLite + Enhanced Business Data) with a unified solution.
@DriftDatabase(tables: [
  Servers,
  ShiftRecords,
  ServerProfiles,
  NPSFeedback,
  NPSMonthlyReports,
  AppSettings,
  PerformanceData,
  BusinessData,
  StationAssignments,
  TapLogs,
  DayPlans,
  Assets,
])
class UnifiedDatabase extends _$UnifiedDatabase {
  UnifiedDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  /// Open database connection with platform-appropriate configuration
  static QueryExecutor _openConnection() {
    // Ensure SQLite3 is available
    if (kIsWeb) {
      throw UnsupportedError('Web platform not supported for unified database');
    }
    
    return driftDatabase(name: 'unified_food_runs.db');
  }

  /// Initialize database with proper setup
  Future<void> init() async {
    try {
      // Ensure SQLite3 libraries are available
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      
      d('[UnifiedDatabase] Database initialized successfully');
    } catch (e) {
      d('[UnifiedDatabase] Error initializing database: $e');
      rethrow;
    }
  }
}

/// Servers table - Core server information
class Servers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get originalId => text().nullable()();
  TextColumn get teamColor => text().nullable()();
  TextColumn get stationType => text().nullable()();
  TextColumn get hireDate => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  TextColumn get createdAt => text().withDefault(const Constant('CURRENT_TIMESTAMP'))();
  TextColumn get updatedAt => text().withDefault(const Constant('CURRENT_TIMESTAMP'))();
}

/// Shift records table - Food run shift data
class ShiftRecords extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get shiftType => text()();
  TextColumn get startDate => text()();
  TextColumn get counts => text()(); // JSON: serverId -> runs
  TextColumn get pizookieCounts => text().nullable()(); // JSON: serverId -> pizookie runs
  TextColumn get stationAssignments => text().nullable()(); // JSON: serverId -> station
  TextColumn get sectionAssignments => text().nullable()(); // JSON: serverId -> section
  TextColumn get createdAt => text().withDefault(const Constant('CURRENT_TIMESTAMP'))();
}

/// Server profiles table - Extended server information
class ServerProfiles extends Table {
  TextColumn get serverId => text()();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get birthday => text().nullable()();
  TextColumn get hireDate => text().nullable()();
  TextColumn get teamColor => text().nullable()();
  TextColumn get stationType => text().nullable()();
  TextColumn get performanceData => text().nullable()(); // JSON: performance metrics
  TextColumn get createdAt => text().withDefault(const Constant('CURRENT_TIMESTAMP'))();
  TextColumn get updatedAt => text().withDefault(const Constant('CURRENT_TIMESTAMP'))();
  
  @override
  Set<Column> get primaryKey => {serverId};
}

/// NPS feedback table - Guest feedback data
class NPSFeedback extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text()();
  TextColumn get feedbackType => text()();
  TextColumn get feedbackDate => text()();
  RealColumn get salesAmount => real().nullable()();
  IntColumn get tableNumber => integer().nullable()();
  TextColumn get shiftPeriod => text().nullable()();
  IntColumn get guestCount => integer().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text().withDefault(const Constant('CURRENT_TIMESTAMP'))();
}

/// NPS monthly reports table - Calculated monthly performance
class NPSMonthlyReports extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text()();
  TextColumn get monthYear => text()();
  RealColumn get allTimeNpsPercentage => real().nullable()();
  RealColumn get threeMonthNpsPercentage => real().nullable()();
  RealColumn get oneMonthNpsPercentage => real().nullable()();
  RealColumn get allTimeSales => real().withDefault(const Constant(0.0))();
  IntColumn get allTimeTableCount => integer().withDefault(const Constant(0))();
  IntColumn get monthFeedbackYes => integer().withDefault(const Constant(0))();
  IntColumn get monthFeedbackMaybe => integer().withDefault(const Constant(0))();
  IntColumn get monthFeedbackNo => integer().withDefault(const Constant(0))();
  IntColumn get threeMonthFeedbackYes => integer().withDefault(const Constant(0))();
  IntColumn get threeMonthFeedbackMaybe => integer().withDefault(const Constant(0))();
  IntColumn get threeMonthFeedbackNo => integer().withDefault(const Constant(0))();
  IntColumn get allTimeFeedbackYes => integer().withDefault(const Constant(0))();
  IntColumn get allTimeFeedbackMaybe => integer().withDefault(const Constant(0))();
  IntColumn get allTimeFeedbackNo => integer().withDefault(const Constant(0))();
  TextColumn get generatedAt => text().withDefault(const Constant('CURRENT_TIMESTAMP'))();
  TextColumn get dataAsOfDate => text()();
  
  @override
  List<Set<Column>> get uniqueKeys => [
    {serverId, monthYear}
  ];
}

/// App settings table - Application configuration
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn get updatedAt => text().withDefault(const Constant('CURRENT_TIMESTAMP'))();
  
  @override
  Set<Column> get primaryKey => {key};
}

/// Performance data table - Server performance metrics
class PerformanceData extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text()();
  TextColumn get dataType => text()(); // 'shift', 'monthly', 'analytics', 'trend'
  TextColumn get dataContent => text()(); // JSON: performance data
  TextColumn get createdAt => text().withDefault(const Constant('CURRENT_TIMESTAMP'))();
}

/// Business data table - Restaurant business metrics
class BusinessData extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get monthYear => text()();
  TextColumn get dataType => text()(); // 'monthly', 'enhanced', 'analytics'
  TextColumn get dataContent => text()(); // JSON: business data
  TextColumn get createdAt => text().withDefault(const Constant('CURRENT_TIMESTAMP'))();
}

/// Station assignments table - Server station/section assignments
class StationAssignments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text()();
  TextColumn get shiftDate => text()();
  TextColumn get shiftType => text()();
  TextColumn get stationType => text().nullable()();
  TextColumn get sectionAssignment => text().nullable()();
  TextColumn get createdAt => text().withDefault(const Constant('CURRENT_TIMESTAMP'))();
}

/// Tap logs table - Food run tap data
class TapLogs extends Table {
  TextColumn get key => text()();
  TextColumn get data => text()(); // JSON: tap log data
  TextColumn get updatedAt => text().withDefault(const Constant('CURRENT_TIMESTAMP'))();
  
  @override
  Set<Column> get primaryKey => {key};
}

/// Day plans table - Daily planning data
class DayPlans extends Table {
  TextColumn get date => text()();
  TextColumn get data => text()(); // JSON: day plan data
  TextColumn get updatedAt => text().withDefault(const Constant('CURRENT_TIMESTAMP'))();
  
  @override
  Set<Column> get primaryKey => {date};
}

/// Assets table - Avatar and banner paths
class Assets extends Table {
  TextColumn get key => text()();
  TextColumn get data => text()(); // JSON: asset data
  TextColumn get updatedAt => text().withDefault(const Constant('CURRENT_TIMESTAMP'))();
  
  @override
  Set<Column> get primaryKey => {key};
}
