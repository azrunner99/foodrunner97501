# Phase 2 Implementation Plan - Real Unified Storage

**Start Date**: October 8, 2025  
**Status**: Ready to Begin  
**Priority**: CRITICAL - Core Data Persistence  
**Estimated Duration**: 2-4 weeks (but we'll go fast!)  
**Prerequisites**: ✅ Phase 1 Complete  

---

## 🎯 **Phase 2 Objective**

**Replace UnifiedStorageService in-memory stub with actual Drift database implementation.**

**Current Problem:**
```dart
// lib/services/unified_storage_service.dart - CURRENT (BROKEN)
class UnifiedStorageService {
  final List<Server> _servers = [];  // IN MEMORY - LOST ON RESTART!
  
  Future<void> saveServer(Server server) async {
    _servers.add(server);  // NOT PERSISTED TO DISK!
  }
}
```

**Goal:**
```dart
// AFTER PHASE 2 (FIXED)
class UnifiedStorageService {
  late UnifiedDatabase _db;  // REAL DRIFT DATABASE
  
  Future<void> saveServer(Server server) async {
    await _db.into(_db.servers).insertOnConflictUpdate(...);  // PERSISTED!
  }
}
```

---

## 📋 **Phase 2 Sub-Phases**

### **Phase 2.1: Analyze UnifiedDatabase Schema** (30 min)
- Review existing `unified_database.dart` schema
- Understand all 12 tables
- Identify which are actually used
- Plan table-by-table implementation

### **Phase 2.2: Implement Core Operations** (3-4 hours)
- Replace in-memory variables with Drift queries
- Implement Servers CRUD
- Implement ShiftRecords CRUD
- Implement ServerProfiles CRUD
- Add proper error handling

### **Phase 2.3: Implement Extended Operations** (2-3 hours)
- NPS Feedback operations
- Monthly Reports operations
- Settings operations
- Performance/Business data operations

### **Phase 2.4: Add Transaction Support** (1-2 hours)
- Multi-table transaction wrappers
- Rollback on error
- Data consistency guarantees

### **Phase 2.5: Data Migration Service** (3-4 hours)
- Migrate from Hive boxes to Unified DB
- Verify data integrity
- Rollback capability
- Progress reporting

### **Phase 2.6: Testing & Validation** (2-3 hours)
- Test all CRUD operations
- Verify data persistence
- Performance benchmarking
- Production readiness

---

## 🏗️ **Phase 2.1: Schema Analysis**

Let me first understand what we're working with in UnifiedDatabase:

**12 Tables Defined:**
1. `Servers` - Core server information
2. `ShiftRecords` - Food run shift data
3. `ServerProfiles` - Extended server information
4. `NPSFeedback` - Guest feedback data
5. `NPSMonthlyReports` - Calculated monthly performance
6. `AppSettings` - Application configuration
7. `PerformanceData` - Server performance metrics
8. `BusinessData` - Restaurant business metrics
9. `StationAssignments` - Server station/section assignments
10. `TapLogs` - Food run tap data
11. `DayPlans` - Daily planning data
12. `Assets` - Avatar and banner paths

**Priority Order for Implementation:**
1. **Servers** (Critical - foundation)
2. **ShiftRecords** (Critical - core functionality)
3. **ServerProfiles** (High - gamification)
4. **AppSettings** (High - configuration)
5. **DayPlans** (Medium - planning)
6. **TapLogs** (Medium - analytics)
7. **Assets** (Medium - UI)
8. **NPSFeedback** (Low - already in NPS DB)
9. **NPSMonthlyReports** (Low - already in NPS DB)
10. **PerformanceData** (Low - calculated)
11. **BusinessData** (Low - separate storage)
12. **StationAssignments** (Low - in shift records)

---

## 🚀 **Implementation Strategy**

### **Approach: Table-by-Table Replacement**

**Step 1**: Implement one table at a time
**Step 2**: Test after each table
**Step 3**: Gradually migrate data
**Step 4**: Validate and move to next table

**Safety**: Can rollback after each table implementation

---

## 📝 **Detailed Implementation Steps**

### **Phase 2.2.1: Servers Table** (FIRST - 1 hour)

**Current (stub)**:
```dart
final List<Server> _servers = [];

Future<List<Server>> getAllServers() async {
  return List.from(_servers);
}
```

**Target (Drift)**:
```dart
late UnifiedDatabase _db;

Future<List<Server>> getAllServers() async {
  final query = _db.select(_db.servers);
  final results = await query.get();
  return results.map((row) => Server(
    id: row.id.toString(),
    name: row.name,
    teamColor: row.teamColor,
    stationType: row.stationType,
    hireDate: row.hireDate != null ? DateTime.parse(row.hireDate) : null,
  )).toList();
}
```

**Implementation checklist**:
- [ ] Add UnifiedDatabase instance variable
- [ ] Initialize database in init()
- [ ] Implement getAllServers() with Drift query
- [ ] Implement saveServer() with insertOnConflictUpdate
- [ ] Implement deleteServer() with Drift delete
- [ ] Test basic CRUD operations
- [ ] Verify data persists across restarts

---

### **Phase 2.2.2: ShiftRecords Table** (SECOND - 1 hour)

**Challenges:**
- ShiftRecords have JSON fields (counts, assignments)
- Need to serialize/deserialize Maps

**Solution:**
```dart
Future<void> saveShift(ShiftRecord shift) async {
  await _db.into(_db.shiftRecords).insertOnConflictUpdate(
    ShiftRecordsCompanion(
      id: Value(shift.id),
      label: Value(shift.label),
      shiftType: Value(shift.shiftType),
      startDate: Value(shift.start.toIso8601String()),
      counts: Value(jsonEncode(shift.counts)),  // Serialize to JSON
      pizookieCounts: Value(jsonEncode(shift.pizookieCounts)),
      stationAssignments: Value(jsonEncode(shift.stationAssignments)),
      sectionAssignments: Value(jsonEncode(shift.sectionAssignments)),
    ),
  );
}
```

---

### **Phase 2.2.3: ServerProfiles Table** (THIRD - 1 hour)

**Challenges:**
- Large data structure with many fields
- Complex nested maps and lists
- Need efficient serialization

**Solution:**
```dart
Future<void> saveServerProfile(String serverId, ServerProfile profile) async {
  await _db.into(_db.serverProfiles).insertOnConflictUpdate(
    ServerProfilesCompanion(
      serverId: Value(serverId),
      avatarPath: Value(profile.avatarPath),
      birthday: Value(profile.birthday),
      hireDate: Value(profile.hireDate),
      teamColor: Value(profile.teamColor),
      stationType: Value(profile.stationType),
      performanceData: Value(jsonEncode(profile.toMap())),  // Serialize entire profile
    ),
  );
}
```

---

## 🔄 **Data Migration Strategy**

### **Phase 2.5: Hive to Drift Migration**

**Step 1: Read from Hive**
```dart
// Read existing servers from Hive
final serversList = await Storage.serversBox.get('list') as List?;
```

**Step 2: Write to UnifiedDatabase**
```dart
// Write to Drift
for (final serverMap in serversList) {
  final server = Server.fromMap(serverMap);
  await UnifiedStorageService.instance.saveServer(server);
}
```

**Step 3: Verify**
```dart
// Verify migration
final hiveCount = serversList.length;
final driftServers = await UnifiedStorageService.instance.getAllServers();
assert(driftServers.length == hiveCount, 'Migration verification failed!');
```

**Step 4: Dual-Write Period**
```dart
// Write to both during transition
await Storage.serversBox.put('list', serversList);  // Old
await UnifiedStorageService.instance.saveServer(server);  // New
```

**Step 5: Switch Reads**
```dart
// Start reading from UnifiedDatabase
final servers = await UnifiedStorageService.instance.getAllServers();
```

**Step 6: Deprecate Hive**
```dart
// Keep Hive as backup only
// Mark for future removal
```

---

## ⚠️ **Risk Mitigation**

### **Backup Strategy**:
1. Full database dump before Phase 2
2. Hive box export to JSON
3. UnifiedDatabase backup after each table
4. Multiple backup locations

### **Rollback Procedure**:
```bash
# If anything goes wrong:
git checkout <commit-before-phase-2>
flutter clean
flutter run

# Data is safe in Hive backups
```

### **Validation at Each Step**:
- [ ] Data count matches before/after
- [ ] No data corruption
- [ ] All fields preserved
- [ ] Relationships maintained
- [ ] Performance acceptable

---

## 📊 **Success Criteria**

Phase 2 is complete when:
- [ ] UnifiedStorageService uses real Drift database
- [ ] All data persists across app restarts
- [ ] Data migration from Hive successful
- [ ] No data loss (0% tolerance)
- [ ] Performance <100ms for typical operations
- [ ] All tests pass
- [ ] Production deployment ready

---

## 🎯 **Expected Outcomes**

**After Phase 2:**
- ✅ Single source of truth (UnifiedDatabase)
- ✅ Data persists correctly
- ✅ No more in-memory stub
- ✅ Foundation for deprecating Hive
- ✅ Ready for Phase 3 (auto-sync hooks)

**Benefits:**
- 🎯 Eliminates "data lost on restart" issue
- 🎯 Single database for all data
- 🎯 Better performance (indexed queries)
- 🎯 Easier backups (one database file)
- 🎯 Cleaner architecture

---

## 🚀 **Let's Begin!**

**Starting with Phase 2.1: Schema Analysis**

We'll analyze the existing UnifiedDatabase schema to understand exactly what we need to implement.

**Ready to start Phase 2.1?**




