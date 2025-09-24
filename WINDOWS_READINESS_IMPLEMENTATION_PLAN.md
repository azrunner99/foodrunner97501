# 🪟 Windows Readiness Implementation Plan
*Food Runs Counter - Cross-Platform Database & Storage Strategy*

---

## 📋 Executive Summary

**Goal**: Enable full Windows desktop functionality while maintaining Android compatibility.

**Challenge**: Current app relies on mobile-only packages (`sqflite`, `shared_preferences`) that don't work on Windows.

**Solution**: Implement platform-adaptive storage layer that automatically selects appropriate backends without changing business logic.

---

## 🔍 Current Architecture Analysis

### Storage Systems in Use:
1. **Primary Storage**: `shared_preferences` → JSON-encoded data via custom `Box` wrapper
2. **Database Storage**: `sqflite` → SQLite for NPS system
3. **File Storage**: `path_provider` → Document directories for backups/exports

### Platform Compatibility Issues:

| Component | Android | Windows | Issue |
|-----------|---------|---------|--------|
| `shared_preferences` | ✅ | ❌ | Registry-based on Windows, doesn't match SharedPreferences API |
| `sqflite` | ✅ | ❌ | Mobile-specific SQLite wrapper |
| `path_provider` | ✅ | ⚠️ | Limited Windows support |

---

## 🎯 Implementation Strategy

### Phase 1: Platform Detection & Abstraction Layer
**Duration**: 1-2 days  
**Risk Level**: 🟢 Low

Create platform-aware storage abstraction that maintains existing API.

### Phase 2: Universal Storage Backend
**Duration**: 2-3 days  
**Risk Level**: 🟡 Medium

Replace platform-specific storage with universal alternatives.

### Phase 3: Database Migration
**Duration**: 3-4 days  
**Risk Level**: 🟡 Medium

Migrate from `sqflite` to cross-platform SQLite solution.

### Phase 4: File System Adaptation
**Duration**: 1-2 days  
**Risk Level**: 🟢 Low

Update file operations for Windows compatibility.

---

## 📚 Detailed Implementation Plan

### Phase 1: Platform Detection & Abstraction Layer

#### 1.1 Create Platform Detection Service
**File**: `lib/services/platform_service.dart`

```dart
import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart';

class PlatformService {
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isMobile => isAndroid || (!kIsWeb && Platform.isIOS);
  static bool get isDesktop => isWindows || (!kIsWeb && (Platform.isLinux || Platform.isMacOS));
}
```

#### 1.2 Create Storage Abstraction Interface  
**File**: `lib/storage/storage_interface.dart`

```dart
abstract class StorageInterface {
  Future<void> init();
  Future<dynamic> get(String key);
  Future<void> put(String key, dynamic value);
  Future<void> delete(String key);
  Future<Set<String>> getKeys();
  Future<void> clear();
}
```

#### 1.3 Update Box Wrapper
**File**: `lib/storage.dart` (modify existing)

```dart
class Box {
  final String prefix;
  final StorageInterface _storage;
  
  Box(this.prefix) : _storage = StorageFactory.create();
  
  // Existing methods remain the same, but delegate to _storage
}
```

### Phase 2: Universal Storage Backend

#### 2.1 Install Cross-Platform Packages
**File**: `pubspec.yaml`

```yaml
dependencies:
  # Remove: shared_preferences (Android-only)
  # Add: Universal storage
  hive: ^2.2.3          # Cross-platform key-value storage
  hive_flutter: ^1.1.0  # Flutter integration
  path_provider: ^2.1.5 # Already exists, update for Windows
  
dev_dependencies:
  hive_generator: ^2.0.0  # Code generation
  build_runner: ^2.4.6    # Build tools
```

#### 2.2 Implement Hive Storage Backend
**File**: `lib/storage/hive_storage.dart`

```dart
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_interface.dart';

class HiveStorage implements StorageInterface {
  static const String _boxName = 'food_runs_storage';
  Box<dynamic>? _box;

  @override
  Future<void> init() async {
    if (PlatformService.isDesktop) {
      final appDir = await getApplicationDocumentsDirectory();
      Hive.init('${appDir.path}/FoodRunsCounter');
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      Hive.init(appDir.path);
    }
    
    _box = await Hive.openBox(_boxName);
  }

  @override
  Future<dynamic> get(String key) async => _box?.get(key);
  
  @override
  Future<void> put(String key, dynamic value) async => 
      await _box?.put(key, value);
}
```

#### 2.3 Implement SharedPreferences Fallback
**File**: `lib/storage/shared_prefs_storage.dart`

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'storage_interface.dart';

class SharedPrefsStorage implements StorageInterface {
  // Existing SharedPreferences implementation
  // Keep for Android compatibility during migration
}
```

#### 2.4 Create Storage Factory
**File**: `lib/storage/storage_factory.dart`

```dart
import 'storage_interface.dart';
import 'hive_storage.dart';
import 'shared_prefs_storage.dart';
import '../services/platform_service.dart';

class StorageFactory {
  static StorageInterface create() {
    if (PlatformService.isWindows) {
      return HiveStorage();
    } else {
      // Keep existing SharedPreferences for Android during migration
      return SharedPrefsStorage();
    }
  }
}
```

### Phase 3: Database Migration

#### 3.1 Install Cross-Platform SQLite
**File**: `pubspec.yaml`

```yaml
dependencies:
  # Remove: sqflite (Android-only)
  # Add: Cross-platform SQLite
  sqlite3_flutter_libs: ^0.5.0  # Native SQLite3 libraries
  drift: ^2.12.0                # Cross-platform SQLite ORM
  drift_flutter: ^0.1.0         # Flutter integration
  
dev_dependencies:
  drift_dev: ^2.12.0            # Code generation
```

#### 3.2 Create Database Abstraction
**File**: `lib/storage/database_interface.dart`

```dart
abstract class DatabaseInterface {
  Future<void> init();
  Future<List<Map<String, dynamic>>> query(String table);
  Future<int> insert(String table, Map<String, dynamic> data);
  Future<int> update(String table, Map<String, dynamic> data, String where, List<dynamic> args);
  Future<int> delete(String table, String where, List<dynamic> args);
  Future<void> execute(String sql);
  Future<void> close();
}
```

#### 3.3 Implement Drift Database Backend
**File**: `lib/storage/drift_database.dart`

```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'database_interface.dart';

@DriftDatabase(include: {'nps_schema.drift'})
class NPSDatabase extends _$NPSDatabase implements DatabaseInterface {
  NPSDatabase() : super(_openConnection());
  
  @override
  int get schemaVersion => 2;
  
  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'nps_database',
      web: false, // Disable web support for now
    );
  }
}
```

#### 3.4 Create Database Schema File
**File**: `lib/storage/nps_schema.drift`

```sql
-- Servers table
CREATE TABLE servers (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    hire_date TEXT NOT NULL,
    active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT,
    updated_at TEXT
);

-- NPS Feedback table  
CREATE TABLE nps_feedback (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER NOT NULL,
    feedback_type TEXT NOT NULL,
    feedback_date TEXT NOT NULL,
    sales_amount REAL,
    table_number INTEGER,
    created_at TEXT,
    FOREIGN KEY (server_id) REFERENCES servers (id)
);

-- Monthly reports table
CREATE TABLE nps_monthly_reports (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER NOT NULL,
    report_month INTEGER NOT NULL,
    all_time_nps_percentage REAL,
    three_month_nps_percentage REAL,
    one_month_nps_percentage REAL,
    all_time_sales REAL,
    all_time_table_count INTEGER,
    feedback_count_yes INTEGER DEFAULT 0,
    feedback_count_maybe INTEGER DEFAULT 0,
    feedback_count_no INTEGER DEFAULT 0,
    generated_at TEXT,
    FOREIGN KEY (server_id) REFERENCES servers (id)
);
```

#### 3.5 Update Database Services
**File**: `lib/storage/nps_database.dart` (modify existing)

```dart
class NPSDatabase {
  static NPSDatabase? _instance;
  static DatabaseInterface? _database;
  
  static DatabaseInterface get instance {
    if (PlatformService.isWindows) {
      return DriftNPSDatabase();
    } else {
      return SQLiteNPSDatabase(); // Existing implementation
    }
  }
}
```

### Phase 4: File System Adaptation

#### 4.1 Create Universal File Service
**File**: `lib/services/file_service.dart`

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'platform_service.dart';

class FileService {
  static Future<Directory> getApplicationDirectory() async {
    if (PlatformService.isWindows) {
      // Use Windows-appropriate directory
      return await getApplicationDocumentsDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }
  
  static Future<String> getBackupDirectory() async {
    final baseDir = await getApplicationDirectory();
    final backupDir = Directory('${baseDir.path}/FoodRunsCounter/backups');
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    return backupDir.path;
  }
}
```

#### 4.2 Update Storage Export/Import
**File**: `lib/storage.dart` (modify existing exportBoxes method)

```dart
static Future<String?> exportBoxes(List<String> prefixes) async {
  try {
    final backupPath = await FileService.getBackupDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filename = 'schema-$timestamp.json';
    final filePath = '$backupPath/$filename';
    
    // Export logic remains the same, just use new file path
    final file = File(filePath);
    await file.writeAsString(jsonEncode(snapshot), flush: true);
    
    return filePath;
  } catch (e) {
    d('[EXPORT] Failed to write backup: $e');
    return null;
  }
}
```

---

## 🔄 Migration Strategy

### Backward Compatibility Plan

1. **Dual Backend Support**: Run both storage systems in parallel during transition
2. **Data Migration**: Automatic one-time migration from SharedPreferences to Hive
3. **Rollback Capability**: Keep SharedPreferences data intact until Windows version stable

### Migration Steps

#### Step 1: Install New Dependencies
```bash
flutter pub add hive hive_flutter drift sqlite3_flutter_libs drift_flutter
flutter pub add -d hive_generator drift_dev build_runner
```

#### Step 2: Generate Code
```bash
flutter packages pub run build_runner build
```

#### Step 3: Test on Android First
- Implement with feature flags
- Verify existing functionality unchanged
- Run full test suite

#### Step 4: Enable Windows Support
- Test on Windows development environment
- Verify all features work correctly
- Performance testing

#### Step 5: Production Release
- Staged rollout
- Monitor for issues
- Fallback plan ready

---

## 🧪 Testing Strategy

### Unit Tests
- Platform detection logic
- Storage abstraction layer
- Database migration scripts
- File system operations

### Integration Tests
- Full app functionality on Windows
- Data persistence across app restarts
- Cross-platform data compatibility
- Performance benchmarks

### Platform-Specific Tests
- Windows: Desktop-specific UI behaviors
- Android: Existing functionality unchanged
- File system permissions

---

## 📊 Implementation Timeline

| Phase | Task | Duration | Dependencies |
|-------|------|----------|--------------|
| 1 | Platform abstraction | 2 days | None |
| 2 | Universal storage | 3 days | Phase 1 |
| 3 | Database migration | 4 days | Phase 2 |
| 4 | File system adaptation | 2 days | Phase 3 |
| 5 | Testing & debugging | 3 days | All phases |
| **Total** | **Complete Windows readiness** | **14 days** | |

---

## ⚠️ Risks & Mitigation

### High Risk
- **Data Loss**: Implement comprehensive backup before migration
- **Performance Impact**: Benchmark new storage layer performance

### Medium Risk  
- **Windows-Specific Bugs**: Extensive Windows testing required
- **Package Compatibility**: Some packages may have Windows issues

### Low Risk
- **User Experience**: UI may need Windows-specific adaptations
- **File Permissions**: Windows UAC considerations

---

## 🎉 Expected Benefits

### For Development
- **Single Codebase**: Write once, run on Android + Windows
- **Better Architecture**: More modular, testable storage layer
- **Future-Proof**: Ready for macOS/Linux expansion

### For Users
- **Windows Desktop App**: Full-featured Windows application
- **Better Performance**: Native Windows storage backends
- **Seamless Experience**: Consistent across platforms

---

## 📝 Next Steps

1. **Approval**: Review and approve implementation plan
2. **Environment Setup**: Prepare Windows development environment
3. **Phase 1 Implementation**: Start with platform abstraction layer
4. **Iterative Development**: Implement and test each phase
5. **Windows Release**: Deploy Windows-ready version

---

*This plan maintains 100% Android compatibility while enabling Windows desktop functionality. All changes are additive and backward-compatible.*