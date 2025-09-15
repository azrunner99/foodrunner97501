# Business Day Model Implementation Plan
*Based on GPT-5 consultation for overnight business hours handling*

## Overview
Implementing a business day model with 4:00 AM anchor to eliminate midnight crossing issues in restaurant operations. This replaces complex "yesterday's overnight period" logic with a clean, standardized business day concept.

## Core Concept
- **Business Day Anchor**: 4:00 AM (always after last possible close, before first possible open)
- **Business Date**: If current time < 4:00 AM, you're in yesterday's business day
- **Clean Boundaries**: Saturday 11 AM - 12:30 AM Sunday becomes one "Saturday business day"

## Implementation Phases

### Phase 1: Core Infrastructure ✅ Ready to Implement
1. **Add closeDayOffset to WeeklyHours model** (`lib/models.dart`)
   - Add `Map<int, int> closeDayOffset` field (weekday -> 0 or 1)
   - Update constructors, serialization, defaults
   - Migration logic: `closeDayOffset = (closeTime <= openTime) ? 1 : 0`

2. **Create businessDate helper function** (`lib/app_state.dart`)
   ```dart
   static DateTime businessDate(DateTime dateTime) {
     return (dateTime.hour < 4) 
       ? DateTime(dateTime.year, dateTime.month, dateTime.day - 1)
       : DateTime(dateTime.year, dateTime.month, dateTime.day);
   }
   ```

3. **Create business day interval builder**
   ```dart
   DateTimeRange businessDayInterval(DateTime businessDate, int weekday) {
     // Returns start/end times for the given business date
   }
   ```

### Phase 2: Time Logic Replacement ✅ Ready to Implement
1. **Replace isOpenNow function** (`lib/app_state.dart` line 825)
   - Current: Complex yesterday overnight + today logic
   - New: Simple business date + interval check
   
2. **Update HomeScreen roster logic** (`lib/screens/home_screen.dart` line 330-370)
   - Current: Complex yesterdayWeekday + overnight detection
   - New: businessDate() + weekday lookup

3. **Fix backup manager closing time** (`lib/utils/backup_manager.dart` line 1025-1050)
   - Current: Manual overnight time handling
   - New: Business day interval check

### Phase 3: UI Improvements ✅ Ready to Implement
1. **Update Settings Screen time picker** (`lib/screens/settings_screen.dart`)
   - Auto-set closeDayOffset when close < open
   - Display "Closes next day" indicator
   - Validation: reject open < 7:00 AM, close > 3:00 AM with offset=1

2. **Update time display formatting**
   - Show "(+1)" for next-day closes
   - Consistent business day terminology

### Phase 4: Data System Updates 🔄 Needs Analysis
1. **Roster Management** (`lib/screens/update_roster_screen.dart`)
   - Save rosters with `businessDate(now)` instead of calendar date
   - Ensures 7 AM manager creates "new day" roster

2. **Shift Assignment Logic**
   - Update shift.start business date association
   - Maintain backward compatibility

### Phase 5: Analysis & Reporting 🔄 Optional Enhancement
1. **Integrity Analysis** (`lib/screens/server_integrity_screen.dart`)
   - Group by business date instead of calendar date
   - More accurate overnight shift analysis

2. **Performance Calculations**
   - Business day grouping for trend analysis
   - Better cross-midnight performance tracking

## Migration Strategy

### Data Migration
1. **WeeklyHours Migration**
   ```dart
   // For each existing closeMinutes entry
   closeDayOffset[weekday] = (closeMinutes[weekday] >= 1440) ? 1 : 0;
   ```

2. **Historical Data Backfill**
   - Apply businessDate() to existing shift records
   - Update roster associations where needed
   - Maintain data integrity

### Rollback Plan
- Keep original overnight logic as backup
- Feature flag for business day model
- Gradual rollout with validation

## Testing Requirements

### Critical Test Cases (Must Pass)
1. **Saturday 11:00-00:15 (offset=1)**
   - `isOpen(Sunday 00:10)` → true
   - `isOpen(Sunday 00:16)` → false
   - `businessDate(Sunday 00:10)` → Saturday

2. **Sunday 10:00-02:45 (offset=1)**
   - `businessDate(Monday 02:44)` → Sunday
   - `businessDate(Monday 04:00)` → Monday

3. **Any day 07:00-23:00 (offset=0)**
   - `isOpen(06:59)` → false
   - `isOpen(07:00)` → true

4. **Validation Tests**
   - Reject open=06:30
   - Reject close=03:30 with offset=1

### Edge Cases
- Midnight exactly (00:00)
- 4:00 AM boundary conditions
- DST transitions
- Leap year February 29th

## Current State Analysis

### Working Systems ✅
- Hours storage (openMinutes/closeMinutes by weekday)
- Time picker with overnight detection
- Basic overnight logic patterns established

### Problem Areas 🔧
- `isOpenNow()` - Complex yesterday logic (line 825-855)
- HomeScreen roster display - Cross-day detection (line 330-370)
- Server click validation - Midnight boundary issues

### Dependencies
- Flutter DateTime handling
- Hive storage system
- Provider state management
- No external business day libraries needed

## Implementation Notes

### Key Files to Modify
1. `lib/models.dart` - WeeklyHours model updates
2. `lib/app_state.dart` - Core business logic
3. `lib/screens/home_screen.dart` - Roster display
4. `lib/screens/settings_screen.dart` - Time configuration
5. `lib/utils/backup_manager.dart` - Closing time detection

### Backwards Compatibility
- Maintain existing minute-based storage
- Graceful degradation for missing closeDayOffset
- Migration runs once on app update

### Performance Impact
- Minimal - mostly logic replacement
- BusinessDate calculation is O(1)
- No database schema changes needed

## Success Criteria
1. ✅ Overnight operations work consistently
2. ✅ Server clicks allowed during valid business hours
3. ✅ Roster display shows correct servers for business day
4. ✅ Time picker intuitive for overnight setups
5. ✅ All existing functionality preserved
6. ✅ No manual "yesterday period" logic needed

## Risk Assessment
- **Low Risk**: Core time logic replacement
- **Medium Risk**: Roster/shift data migration
- **Mitigation**: Thorough testing, gradual rollout, rollback plan

---

## Current Issue Context
User reported overnight operations not working at 12:05-12:13 AM during Saturday's business day (closes 12:30 AM). Fixed display logic but server clicks still blocked. This business day model will permanently resolve these midnight crossing issues.

**Implementation Priority**: Phase 1-2 addresses immediate overnight issues, Phase 3-5 provides long-term improvements.