# Unified Storage Migration Plan

## 🎯 **Objective**
Consolidate Hive, SQLite/Sqflite, and Enhanced Business Data into a single Drift-based storage layer.

## 📊 **Current State Analysis**

### **Storage Systems in Use:**
1. **Hive Storage** (13 boxes)
   - `serversBox`, `totalsBox`, `shiftsBox`, `profilesBox`
   - `settingsBox`, `dayPlanBox`, `tapBox`, `tapTimestampsBox`
   - `performanceBox`, `businessDataBox`, `performanceSettingsBox`
   - `enhancedBusinessDataBox`, `stationsBox`, `assetsBox`

2. **SQLite/Sqflite** (Multiple implementations)
   - `SqfliteNPSDatabase` (Android)
   - `DriftNPSDatabase` (Cross-platform)
   - `NPSDatabase` (Legacy)
   - Tables: `servers`, `nps_feedback`, `nps_monthly_reports`, `nps_calculation_log`

3. **Enhanced Business Data** (Hive boxes)
   - Performance metrics, business analytics, station assignments

## 🏗️ **Unified Architecture Design**

### **Single Database Schema**
```sql
-- Core Tables
CREATE TABLE servers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  original_id TEXT,
  team_color TEXT,
  station_type TEXT,
  hire_date TEXT NOT NULL,
  active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE shift_records (
  id TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  shift_type TEXT NOT NULL,
  start_date TEXT NOT NULL,
  counts TEXT NOT NULL, -- JSON
  pizookie_counts TEXT, -- JSON
  station_assignments TEXT, -- JSON
  section_assignments TEXT, -- JSON
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE server_profiles (
  server_id TEXT PRIMARY KEY,
  avatar_path TEXT,
  birthday TEXT,
  hire_date TEXT,
  team_color TEXT,
  station_type TEXT,
  performance_data TEXT, -- JSON
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (server_id) REFERENCES servers(original_id)
);

CREATE TABLE nps_feedback (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  server_id TEXT NOT NULL,
  feedback_type TEXT NOT NULL CHECK(feedback_type IN ('yes', 'maybe', 'no')),
  feedback_date TEXT NOT NULL,
  sales_amount REAL,
  table_number INTEGER,
  shift_period TEXT CHECK(shift_period IN ('breakfast', 'lunch', 'dinner', 'late_night')),
  guest_count INTEGER,
  notes TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (server_id) REFERENCES servers(original_id)
);

CREATE TABLE nps_monthly_reports (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  server_id TEXT NOT NULL,
  month_year TEXT NOT NULL,
  all_time_nps_percentage REAL,
  three_month_nps_percentage REAL,
  one_month_nps_percentage REAL,
  all_time_sales REAL DEFAULT 0.00,
  all_time_table_count INTEGER DEFAULT 0,
  month_feedback_yes INTEGER DEFAULT 0,
  month_feedback_maybe INTEGER DEFAULT 0,
  month_feedback_no INTEGER DEFAULT 0,
  three_month_feedback_yes INTEGER DEFAULT 0,
  three_month_feedback_maybe INTEGER DEFAULT 0,
  three_month_feedback_no INTEGER DEFAULT 0,
  all_time_feedback_yes INTEGER DEFAULT 0,
  all_time_feedback_maybe INTEGER DEFAULT 0,
  all_time_feedback_no INTEGER DEFAULT 0,
  generated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  data_as_of_date TEXT NOT NULL,
  FOREIGN KEY (server_id) REFERENCES servers(original_id),
  UNIQUE(server_id, month_year)
);

CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE performance_data (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  server_id TEXT NOT NULL,
  data_type TEXT NOT NULL, -- 'shift', 'monthly', 'analytics'
  data_content TEXT NOT NULL, -- JSON
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (server_id) REFERENCES servers(original_id)
);

CREATE TABLE business_data (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  month_year TEXT NOT NULL,
  data_type TEXT NOT NULL, -- 'monthly', 'enhanced', 'analytics'
  data_content TEXT NOT NULL, -- JSON
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE station_assignments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  server_id TEXT NOT NULL,
  shift_date TEXT NOT NULL,
  shift_type TEXT NOT NULL,
  station_type TEXT,
  section_assignment TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (server_id) REFERENCES servers(original_id)
);

-- Indexes for performance
CREATE INDEX idx_servers_active ON servers(active);
CREATE INDEX idx_servers_hire_date ON servers(hire_date);
CREATE INDEX idx_feedback_server_id ON nps_feedback(server_id);
CREATE INDEX idx_feedback_date ON nps_feedback(feedback_date);
CREATE INDEX idx_feedback_server_date ON nps_feedback(server_id, feedback_date);
CREATE INDEX idx_feedback_type ON nps_feedback(feedback_type);
CREATE INDEX idx_monthly_reports_server ON nps_monthly_reports(server_id);
CREATE INDEX idx_monthly_reports_month ON nps_monthly_reports(month_year);
CREATE INDEX idx_performance_server ON performance_data(server_id);
CREATE INDEX idx_business_month ON business_data(month_year);
CREATE INDEX idx_station_server ON station_assignments(server_id);
```

## 🚀 **Migration Implementation Plan**

### **Phase 1: Foundation Setup (Week 1)**

#### 1.1 Create Unified Database Schema
**File**: `lib/storage/unified_database.dart`

```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:drift/native.dart' as drift_native;

part 'unified_database.g.dart';

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
])
class UnifiedDatabase extends _$UnifiedDatabase {
  UnifiedDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'unified_food_runs.db');
  }
}

// Table definitions
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

class ShiftRecords extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get shiftType => text()();
  TextColumn get startDate => text()();
  TextColumn get counts => text()(); // JSON
  TextColumn get pizookieCounts => text().nullable()(); // JSON
  TextColumn get stationAssignments => text().nullable()(); // JSON
  TextColumn get sectionAssignments => text().nullable()(); // JSON
  TextColumn get createdAt => text().withDefault(const Constant('CURRENT_TIMESTAMP'))();
}

// ... (other table definitions)
```

#### 1.2 Create Unified Data Access Layer
**File**: `lib/services/unified_storage_service.dart`

```dart
import '../storage/unified_database.dart';
import '../models.dart';
import '../models/performance_models.dart';

class UnifiedStorageService {
  static UnifiedStorageService? _instance;
  static UnifiedStorageService get instance => _instance ??= UnifiedStorageService._();
  
  UnifiedStorageService._();
  
  late UnifiedDatabase _db;
  
  Future<void> init() async {
    _db = UnifiedDatabase();
  }
  
  // Server operations
  Future<List<Server>> getAllServers() async {
    final rows = await _db.select(_db.servers);
    return rows.map((row) => Server(
      id: row.originalId ?? row.id.toString(),
      name: row.name,
      teamColor: row.teamColor,
      stationType: row.stationType,
      hireDate: DateTime.tryParse(row.hireDate),
    )).toList();
  }
  
  Future<void> saveServer(Server server) async {
    await _db.into(_db.servers).insertOnConflictUpdate(ServersCompanion(
      originalId: Value(server.id),
      name: Value(server.name),
      teamColor: Value(server.teamColor),
      stationType: Value(server.stationType),
      hireDate: Value(server.hireDate?.toIso8601String() ?? ''),
      active: Value(true),
    ));
  }
  
  // Shift operations
  Future<List<ShiftRecord>> getAllShifts() async {
    final rows = await _db.select(_db.shiftRecords);
    return rows.map((row) => ShiftRecord.fromMap({
      'id': row.id,
      'label': row.label,
      'shiftType': row.shiftType,
      'start': row.startDate,
      'counts': jsonDecode(row.counts),
      'pizookieCounts': row.pizookieCounts != null ? jsonDecode(row.pizookieCounts!) : {},
      'stationAssignments': row.stationAssignments != null ? jsonDecode(row.stationAssignments!) : {},
      'sectionAssignments': row.sectionAssignments != null ? jsonDecode(row.sectionAssignments!) : {},
    })).toList();
  }
  
  Future<void> saveShift(ShiftRecord shift) async {
    await _db.into(_db.shiftRecords).insertOnConflictUpdate(ShiftRecordsCompanion(
      id: Value(shift.id),
      label: Value(shift.label),
      shiftType: Value(shift.shiftType),
      startDate: Value(shift.start.toIso8601String()),
      counts: Value(jsonEncode(shift.counts)),
      pizookieCounts: Value(shift.pizookieCounts.isNotEmpty ? jsonEncode(shift.pizookieCounts) : null),
      stationAssignments: Value(shift.stationAssignments?.isNotEmpty == true ? jsonEncode(shift.stationAssignments!) : null),
      sectionAssignments: Value(shift.sectionAssignments?.isNotEmpty == true ? jsonEncode(shift.sectionAssignments!) : null),
    ));
  }
  
  // NPS operations
  Future<void> saveNPSFeedback(Map<String, dynamic> feedback) async {
    await _db.into(_db.npsFeedback).insert(NPSFeedbackCompanion(
      serverId: Value(feedback['server_id'] as String),
      feedbackType: Value(feedback['feedback_type'] as String),
      feedbackDate: Value(feedback['feedback_date'] as String),
      salesAmount: Value(feedback['sales_amount'] as double?),
      tableNumber: Value(feedback['table_number'] as int?),
      shiftPeriod: Value(feedback['shift_period'] as String?),
      guestCount: Value(feedback['guest_count'] as int?),
      notes: Value(feedback['notes'] as String?),
    ));
  }
  
  Future<List<Map<String, dynamic>>> getNPSFeedback(String serverId) async {
    final rows = await (_db.select(_db.npsFeedback)
      ..where((tbl) => tbl.serverId.equals(serverId)));
    return rows.map((row) => {
      'id': row.id,
      'server_id': row.serverId,
      'feedback_type': row.feedbackType,
      'feedback_date': row.feedbackDate,
      'sales_amount': row.salesAmount,
      'table_number': row.tableNumber,
      'shift_period': row.shiftPeriod,
      'guest_count': row.guestCount,
      'notes': row.notes,
      'created_at': row.createdAt,
    }).toList();
  }
  
  // Settings operations
  Future<T?> getSetting<T>(String key) async {
    final row = await (_db.select(_db.appSettings)
      ..where((tbl) => tbl.key.equals(key)))
      .getSingleOrNull();
    return row?.value as T?;
  }
  
  Future<void> setSetting(String key, dynamic value) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(AppSettingsCompanion(
      key: Value(key),
      value: Value(value.toString()),
    ));
  }
  
  // Performance data operations
  Future<void> savePerformanceData(String serverId, String dataType, Map<String, dynamic> data) async {
    await _db.into(_db.performanceData).insert(PerformanceDataCompanion(
      serverId: Value(serverId),
      dataType: Value(dataType),
      dataContent: Value(jsonEncode(data)),
    ));
  }
  
  Future<List<Map<String, dynamic>>> getPerformanceData(String serverId, String dataType) async {
    final rows = await (_db.select(_db.performanceData)
      ..where((tbl) => tbl.serverId.equals(serverId) & tbl.dataType.equals(dataType)));
    return rows.map((row) => jsonDecode(row.dataContent)).toList();
  }
}
```

### **Phase 2: Data Migration (Week 2)**

#### 2.1 Create Migration Service
**File**: `lib/services/storage_migration_service.dart`

```dart
import '../storage.dart';
import '../storage/unified_database.dart';
import 'unified_storage_service.dart';

class StorageMigrationService {
  static Future<void> migrateAllData() async {
    final unifiedService = UnifiedStorageService.instance;
    await unifiedService.init();
    
    // Migrate Hive data
    await _migrateHiveData();
    
    // Migrate SQLite data
    await _migrateSQLiteData();
    
    // Migrate Enhanced Business Data
    await _migrateEnhancedBusinessData();
  }
  
  static Future<void> _migrateHiveData() async {
    // Migrate servers
    final servers = await Storage.serversBox.get('list') as List? ?? [];
    for (final serverData in servers) {
      final server = Server.fromMap(Map<String, dynamic>.from(serverData));
      await UnifiedStorageService.instance.saveServer(server);
    }
    
    // Migrate shifts
    final shifts = await Storage.shiftsBox.get('list') as List? ?? [];
    for (final shiftData in shifts) {
      final shift = ShiftRecord.fromMap(Map<String, dynamic>.from(shiftData));
      await UnifiedStorageService.instance.saveShift(shift);
    }
    
    // Migrate profiles
    final profiles = await Storage.profilesBox.getAll();
    for (final entry in profiles.entries) {
      final profile = ServerProfile.fromMap(Map<String, dynamic>.from(entry.value));
      await UnifiedStorageService.instance.saveServerProfile(entry.key, profile);
    }
    
    // Migrate settings
    final settings = await Storage.settingsBox.getAll();
    for (final entry in settings.entries) {
      await UnifiedStorageService.instance.setSetting(entry.key, entry.value);
    }
  }
  
  static Future<void> _migrateSQLiteData() async {
    // Migrate NPS feedback
    final npsAdapter = NPSDatabaseAdapter(DatabaseFactory.instance);
    final feedback = await npsAdapter.getAllNPSFeedback();
    for (final record in feedback) {
      await UnifiedStorageService.instance.saveNPSFeedback(record);
    }
    
    // Migrate monthly reports
    final reports = await npsAdapter.getAllMonthlyReports();
    for (final report in reports) {
      await UnifiedStorageService.instance.saveMonthlyReport(report);
    }
  }
  
  static Future<void> _migrateEnhancedBusinessData() async {
    // Migrate performance data
    final performanceData = await Storage.performanceBox.getAll();
    for (final entry in performanceData.entries) {
      await UnifiedStorageService.instance.savePerformanceData(
        entry.key, 'performance', Map<String, dynamic>.from(entry.value));
    }
    
    // Migrate business data
    final businessData = await Storage.businessDataBox.getAll();
    for (final entry in businessData.entries) {
      await UnifiedStorageService.instance.saveBusinessData(
        entry.key, Map<String, dynamic>.from(entry.value));
    }
  }
}
```

### **Phase 3: AppState Refactoring (Week 3)**

#### 3.1 Update AppState to Use Unified Storage
**File**: `lib/app_state.dart` (modifications)

```dart
import '../services/unified_storage_service.dart';

class AppState extends ChangeNotifier {
  // ... existing fields ...
  
  final UnifiedStorageService _storage = UnifiedStorageService.instance;
  
  Future<void> load() async {
    // Load servers from unified storage
    _servers.clear();
    _servers.addAll(await _storage.getAllServers());
    
    // Load shifts from unified storage
    _history.clear();
    _history.addAll(await _storage.getAllShifts());
    
    // Load profiles from unified storage
    _profiles.clear();
    final profiles = await _storage.getAllServerProfiles();
    for (final profile in profiles) {
      _profiles[profile.serverId] = profile;
    }
    
    // Load settings from unified storage
    _hours = WeeklyHours.fromMap(
      await _storage.getSetting<Map<String, dynamic>>('weekly_hours') ?? {});
    
    // ... other loading logic ...
  }
  
  Future<void> addServer(Server server) async {
    _servers.add(server);
    await _storage.saveServer(server);
    notifyListeners();
  }
  
  Future<void> addShift(ShiftRecord shift) async {
    _history.add(shift);
    await _storage.saveShift(shift);
    notifyListeners();
  }
  
  Future<void> updateServerProfile(String serverId, ServerProfile profile) async {
    _profiles[serverId] = profile;
    await _storage.saveServerProfile(serverId, profile);
    notifyListeners();
  }
  
  // ... other methods updated to use unified storage ...
}
```

### **Phase 4: Service Layer Updates (Week 4)**

#### 4.1 Update NPS Services
**File**: `lib/providers/nps_provider.dart` (modifications)

```dart
import '../services/unified_storage_service.dart';

class NPSProvider extends ChangeNotifier {
  final UnifiedStorageService _storage = UnifiedStorageService.instance;
  
  Future<void> submitFeedback(Map<String, dynamic> feedback) async {
    await _storage.saveNPSFeedback(feedback);
    await _loadRecentFeedback();
    notifyListeners();
  }
  
  Future<void> _loadRecentFeedback() async {
    // Load from unified storage instead of direct database access
    final feedback = await _storage.getRecentNPSFeedback();
    _recentFeedback = feedback;
  }
}
```

#### 4.2 Update Performance Services
**File**: `lib/services/performance_calculator.dart` (modifications)

```dart
import 'unified_storage_service.dart';

class PerformanceCalculator {
  final UnifiedStorageService _storage = UnifiedStorageService.instance;
  
  Future<PerformanceMetrics> calculateServerPerformance(String serverId) async {
    // Get data from unified storage
    final shifts = await _storage.getShiftsForServer(serverId);
    final npsData = await _storage.getNPSDataForServer(serverId);
    final performanceData = await _storage.getPerformanceData(serverId, 'monthly');
    
    // Calculate performance metrics
    return _calculateMetrics(shifts, npsData, performanceData);
  }
}
```

### **Phase 5: UI Compatibility (Week 5)**

#### 5.1 Update Backup System
**File**: `lib/utils/backup_manager.dart` (modifications)

```dart
class BackupManager {
  static Future<BackupResult> createBackup({String? customName}) async {
    final storage = UnifiedStorageService.instance;
    
    // Export all data from unified storage
    final servers = await storage.getAllServers();
    final shifts = await storage.getAllShifts();
    final profiles = await storage.getAllServerProfiles();
    final npsData = await storage.getAllNPSData();
    final settings = await storage.getAllSettings();
    
    // Create backup with unified data structure
    final backupData = {
      'metadata': {
        'version': '3.0',
        'timestamp': DateTime.now().toIso8601String(),
        'storage_type': 'unified_drift',
      },
      'servers': servers.map((s) => s.toMap()).toList(),
      'shifts': shifts.map((s) => s.toMap()).toList(),
      'profiles': profiles.map((p) => p.toMap()).toList(),
      'nps_data': npsData,
      'settings': settings,
    };
    
    // ... rest of backup logic ...
  }
}
```

## 🔄 **Migration Execution Steps**

### **Step 1: Install Dependencies**
```yaml
dependencies:
  drift: ^2.12.0
  drift_flutter: ^0.1.0
  sqlite3_flutter_libs: ^0.5.0

dev_dependencies:
  drift_dev: ^2.12.0
  build_runner: ^2.4.0
```

### **Step 2: Generate Database Code**
```bash
flutter packages pub run build_runner build
```

### **Step 3: Run Migration**
```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run migration
  await StorageMigrationService.migrateAllData();
  
  runApp(MyApp());
}
```

### **Step 4: Update AppState Initialization**
```dart
// In app_state.dart
Future<void> load() async {
  // Initialize unified storage
  await UnifiedStorageService.instance.init();
  
  // Load data from unified storage
  await _loadFromUnifiedStorage();
}
```

## ✅ **Benefits of Unified Storage**

1. **Single Source of Truth**: All data in one database
2. **Type Safety**: Compile-time checking with Drift
3. **Performance**: Optimized queries and relationships
4. **Cross-Platform**: Works on all platforms
5. **Maintainability**: Single storage layer to maintain
6. **Backup/Restore**: Simplified with single database
7. **Migration**: Easier data migration and schema updates

## 🚨 **Risk Mitigation**

1. **Backup Before Migration**: Full backup of all existing data
2. **Gradual Migration**: Phase-by-phase implementation
3. **Rollback Plan**: Keep old storage systems during transition
4. **Testing**: Comprehensive testing at each phase
5. **Data Validation**: Verify data integrity after migration

This unified storage solution will eliminate the complexity of managing multiple storage systems while providing better performance, type safety, and maintainability.


