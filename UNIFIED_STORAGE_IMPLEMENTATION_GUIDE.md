# Unified Storage Implementation Guide

## 🎯 **Overview**

This guide provides step-by-step instructions for implementing the unified storage system that consolidates Hive, SQLite/Sqflite, and Enhanced Business Data into a single Drift-based solution.

## 📋 **Prerequisites**

- Flutter SDK 3.3.0+
- Existing app with multi-storage architecture
- Backup of current data (recommended)

## 🚀 **Implementation Steps**

### **Step 1: Install Dependencies**

The required dependencies are already in your `pubspec.yaml`:

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

Run the following command to generate the Drift database code:

```bash
flutter packages pub run build_runner build
```

This will create the `unified_database.g.dart` file with all the generated code.

### **Step 3: Update Main App Initialization**

Update your `main.dart` to initialize the unified storage:

```dart
import 'package:flutter/material.dart';
import 'services/storage_migration_service.dart';
import 'services/unified_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize unified storage
  await UnifiedStorageService.instance.init();
  
  // Run migration if needed
  await StorageMigrationService.migrateIfNeeded();
  
  runApp(MyApp());
}
```

### **Step 4: Update AppState**

Replace your current `AppState` with the new `AppStateUnified`:

```dart
// In your main app file
import 'app_state_unified.dart';

// Replace AppState with AppStateUnified
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppStateUnified(),
      child: MaterialApp(
        // ... rest of your app
      ),
    );
  }
}
```

### **Step 5: Update Services**

Update your services to use the unified storage:

```dart
// Example: Update NPSProvider
import '../services/unified_storage_service.dart';

class NPSProvider extends ChangeNotifier {
  final UnifiedStorageService _storage = UnifiedStorageService.instance;
  
  Future<void> submitFeedback(Map<String, dynamic> feedback) async {
    await _storage.saveNPSFeedback(feedback);
    // ... rest of your logic
  }
}
```

### **Step 6: Update Backup System**

Update your backup system to work with unified storage:

```dart
// In backup_manager.dart
import '../services/unified_storage_service.dart';

class BackupManager {
  static Future<BackupResult> createBackup({String? customName}) async {
    final storage = UnifiedStorageService.instance;
    
    // Get all data from unified storage
    final servers = await storage.getAllServers();
    final shifts = await storage.getAllShifts();
    final profiles = await storage.getAllServerProfiles();
    final npsData = await storage.getAllNPSFeedback();
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
    
    // ... rest of backup logic
  }
}
```

## 🔄 **Migration Process**

### **Automatic Migration**

The migration happens automatically when the app starts:

1. **Check for existing data** in unified storage
2. **If no data exists**, migrate from old storage systems
3. **Validate migration** results
4. **Continue with app startup**

### **Manual Migration**

You can also run the migration manually:

```bash
# Run migration script
dart run lib/scripts/migrate_to_unified_storage.dart migrate

# Test unified storage
dart run lib/scripts/migrate_to_unified_storage.dart test

# Rollback if needed
dart run lib/scripts/migrate_to_unified_storage.dart rollback /path/to/backup.json
```

## 🧪 **Testing**

### **Test the Migration**

1. **Create a backup** of your current data
2. **Run the migration** script
3. **Test the app** to ensure everything works
4. **Verify data integrity** by checking all features

### **Test Commands**

```bash
# Test unified storage system
dart run lib/scripts/migrate_to_unified_storage.dart test

# Run complete migration
dart run lib/scripts/migrate_to_unified_storage.dart migrate
```

## 📊 **Database Schema**

The unified database includes these tables:

- **servers** - Server information
- **shift_records** - Food run shift data
- **server_profiles** - Extended server information
- **nps_feedback** - Guest feedback data
- **nps_monthly_reports** - Calculated monthly performance
- **app_settings** - Application configuration
- **performance_data** - Server performance metrics
- **business_data** - Restaurant business metrics
- **station_assignments** - Server station/section assignments
- **tap_logs** - Food run tap data
- **day_plans** - Daily planning data
- **assets** - Avatar and banner paths

## 🔧 **Configuration**

### **Database Location**

The unified database is stored at:
- **Android**: `getApplicationDocumentsDirectory()/unified_food_runs.db`
- **Windows**: `getApplicationDocumentsDirectory()/unified_food_runs.db`
- **iOS**: `getApplicationDocumentsDirectory()/unified_food_runs.db`

### **Performance Optimization**

The unified storage includes:
- **Indexes** on frequently queried columns
- **Foreign key constraints** for data integrity
- **JSON storage** for complex data structures
- **Efficient queries** using Drift ORM

## 🚨 **Troubleshooting**

### **Common Issues**

1. **Migration fails**
   - Check that all old storage systems are accessible
   - Verify data integrity in source systems
   - Check logs for specific error messages

2. **Data not appearing**
   - Ensure migration completed successfully
   - Check that AppState is using unified storage
   - Verify database file exists and is accessible

3. **Performance issues**
   - Check database indexes are created
   - Monitor query performance
   - Consider data archiving for old records

### **Debug Commands**

```bash
# Check database statistics
dart run lib/scripts/migrate_to_unified_storage.dart test

# View migration logs
# Check console output during app startup

# Verify data integrity
# Compare record counts before and after migration
```

## 📈 **Benefits**

### **Performance Improvements**

- **Single database** instead of multiple storage systems
- **Optimized queries** with proper indexing
- **Reduced memory usage** with efficient data structures
- **Faster data access** with unified API

### **Maintainability**

- **Single storage layer** to maintain
- **Type-safe operations** with Drift ORM
- **Consistent API** across all data operations
- **Easier debugging** with unified logging

### **Cross-Platform**

- **Works on all platforms** (Android, Windows, iOS)
- **Consistent behavior** across platforms
- **No platform-specific code** needed
- **Future-proof** architecture

## 🔄 **Rollback Plan**

If migration fails or causes issues:

1. **Stop the app** immediately
2. **Restore from backup** using the rollback script
3. **Investigate the issue** using debug logs
4. **Fix the problem** and retry migration
5. **Test thoroughly** before proceeding

### **Rollback Commands**

```bash
# Rollback to previous state
dart run lib/scripts/migrate_to_unified_storage.dart rollback /path/to/backup.json

# Verify rollback success
# Check that old storage systems are working
# Test app functionality
```

## 📚 **Additional Resources**

- **Drift Documentation**: https://drift.simonbinder.eu/
- **SQLite Documentation**: https://www.sqlite.org/docs.html
- **Flutter Database Guide**: https://docs.flutter.dev/development/data-and-backend/state-mgmt/options#sqlite

## 🎉 **Success Criteria**

Migration is successful when:

- ✅ All data migrated without errors
- ✅ App starts and functions normally
- ✅ All features work as expected
- ✅ Performance is maintained or improved
- ✅ Backup/restore functionality works
- ✅ No data loss or corruption

## 📞 **Support**

If you encounter issues during migration:

1. **Check the logs** for error messages
2. **Verify data integrity** in source systems
3. **Test with a small dataset** first
4. **Create multiple backups** before migration
5. **Contact support** with specific error details

Remember: The migration process is designed to be safe and reversible. Always create backups before starting the migration process.

