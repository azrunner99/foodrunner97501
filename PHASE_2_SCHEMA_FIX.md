# Phase 2 Critical Schema Issue

## 🚨 PROBLEM FOUND

**File**: `lib/storage/unified_database.dart`  
**Line**: 62

**Current (WRONG)**:
```dart
class Servers extends Table {
  IntColumn get id => integer().autoIncrement()();  // ❌ INTEGER!
```

**Needed (CORRECT)**:
```dart
class Servers extends Table {
  TextColumn get id => text()();  // ✅ TEXT (String IDs)
```

## 🔧 WHY THIS MATTERS

Throughout Phase 1, we standardized on **String IDs**:
- AppState uses String IDs
- NPS Database now uses TEXT IDs
- ServerIdResolver works with String IDs
- All widgets expect String IDs

**UnifiedDatabase must also use String IDs for consistency!**

## ✅ FIX REQUIRED BEFORE PHASE 2.2

We must update the schema BEFORE implementing the real service, otherwise we'll have the same ID mismatch problems all over again!

**Will fix in Phase 2.1**

