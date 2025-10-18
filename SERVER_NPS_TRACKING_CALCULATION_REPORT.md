# Server NPS Tracking Screen - Calculation Analysis Report

**Date**: October 9, 2025  
**Purpose**: Detailed analysis of how each tab/widget calculates its metrics  
**Status**: Analysis Complete - No Changes Made

---

## 🎯 **Overview**

The Server NPS Tracking screen (accessed via Admin Settings) contains **4 main tabs**, each with different widgets and calculation methods. Here's exactly how each one works:

---

## 📊 **Tab 1: Data Entry**

**Widget**: `MonthlyNPSDataEntryWidget`

### What It Does:
- Allows manual entry of monthly NPS data for each server
- Displays form fields for: 1-month NPS%, 3-month NPS%, All-time NPS%, Sales, Table Count

### Data Sources:
- **Loads existing data from**: `NPSMonthlyReport` table via `getAllNPSMonthlyReports()` mixin method
- **Filters by**: Selected month (e.g., September 2025 = reportMonth 202509)
- **Saves to**: NPS database via `NPSProvider.saveMonthlyReport()`

### Calculations:
- **No calculations** - this is a data entry form only
- Validates that NPS percentages are between 0-100
- Stores raw values directly as entered

### Data Contributing to Results:
- **User-entered data** only
- No automatic calculations or aggregations

---

## 📈 **Tab 2: Status (Server NPS Status Widget)**

**Widget**: `ServerNPSStatusWidget`

### What It Does:
- Displays **Intelligent Performance Classification** for each server
- Shows which servers are "Star Performers", "Needs Attention", etc.

### Data Sources:
- **Primary**: `getAllNPSMonthlyReports()` - Gets all monthly reports from database
- **Secondary**: `getServerNPSHistory(serverId)` - Gets history for each specific server
- **Filtering**: Automatically excludes orphaned numeric IDs (e.g., "1", "2", "3")

### Calculations:

#### **1. Performance Classification** (via `IntelligentPerformanceClassifier`)
```dart
// For each server:
final classification = classifier.classifyServerPerformance(
  monthlyReports: monthlyReports,    // All monthly reports for this server
  serverName: serverName,             // Server display name
  serverId: serverId,                 // Canonical server ID
);
```

The classifier analyzes:
- **Recent performance trends** (last 3-6 months)
- **Consistency** (standard deviation of NPS scores)
- **Improvement rate** (slope of performance over time)
- **Benchmark achievement** (meeting 80% standard)

#### **2. Historical NPS Data Construction**
For each server, creates `HistoricalNPSData` object with:
- **Monthly Performance**: Extracted from each `NPSMonthlyReport`
  - `oneMonthNPS`: report.oneMonthNpsPercentage
  - `threeMonthNPS`: report.threeMonthNpsPercentage  
  - `allTimeNPS`: report.allTimeNpsPercentage
  - `tableCount`: report.allTimeTableCount
  - `sales`: report.allTimeSales

- **Trend Direction**: Calculated as `TrendDirection.stable` (default)
- **Volatility**: Default 0.0
- **Total Months Reported**: Count of monthly reports

### Data Contributing to Results:
✅ **NPSMonthlyReport.oneMonthNpsPercentage** - Recent 1-month NPS  
✅ **NPSMonthlyReport.threeMonthNpsPercentage** - Recent 3-month NPS  
✅ **NPSMonthlyReport.allTimeNpsPercentage** - All-time NPS  
✅ **NPSMonthlyReport.allTimeSales** - Total sales  
✅ **NPSMonthlyReport.allTimeTableCount** - Total tables served  
✅ **NPSMonthlyReport.reportMonth** - Month/year of report  
✅ **Server name** from AppState servers list

### Performance Tiers:
The classifier assigns one of these tiers:
- **Star Performer** - Consistently high (85%+), improving
- **High Performer** - Above standard (80%+), stable
- **Solid Contributor** - Meeting standard (75-80%)
- **Needs Attention** - Below standard (70-75%)
- **Critical** - Well below standard (<70%)
- **Unknown** - Insufficient data

---

## 💥 **Tab 3: Analytics (Enhanced NPS Analytics Widget)**

**Widget**: `EnhancedNPSAnalyticsWidget`

### What It Does:
- Shows **aggregate metrics** across all servers
- Displays **average NPS**, **total sales**, **total checks**, **trending months**

### Data Sources:
- **Primary**: `getAllNPSMonthlyReports()` - All monthly reports
- **Historical**: `HistoricalNPSAggregationService.getAllHistoricalDataWithAppState(servers)` 
- **Timelines**: `PerformanceTimelineService.getAllTimelines()`

### Calculations:

#### **1. Key Metrics** (Method: `_buildKeyMetricsFromReports`)
```dart
// Group reports by server
final serverReports = <String, List<NPSMonthlyReport>>{};
for (final report in reports) {
  serverReports.putIfAbsent(report.serverId, () => []).add(report);
}

// Calculate average NPS per server, then average those
final serverAverages = <double>[];
for (final serverReportList in serverReports.values) {
  // Get most recent report for this server
  final mostRecentReport = serverReportList.reduce((a, b) {
    if (a.reportYear > b.reportYear) return a;
    if (a.reportYear < b.reportYear) return b;
    return a.reportMonth > b.reportMonth ? a : b;
  });
  
  serverAverages.add(mostRecentReport.allTimeNpsPercentage!);
}

final avgNPS = serverAverages.reduce((a, b) => a + b) / serverAverages.length;
```

**Key Metrics Calculated**:
1. **Average NPS**: Average of each server's most recent `allTimeNpsPercentage`
2. **Total Servers**: Count of unique servers with reports
3. **Total Sales**: Sum of `allTimeSales` from most recent report per server
4. **Total Checks**: Sum of `allTimeTableCount` from most recent report per server
5. **Months with Data**: Unique months represented (extracted from `reportMonth % 100`)

#### **2. Performance Score** (Method: `_calculateServerPerformanceScore`)
```dart
final baseScore = (oneMonth * 0.5) + (threeMonth * 0.3) + (allTime * 0.2);

// Trend multiplier (based on improvement)
if (threeMonth > oneMonth + 5) {
  trendMultiplier = 1.2;  // Strong improvement
} else if (threeMonth > oneMonth + 2) {
  trendMultiplier = 1.1;  // Improving
} else if (threeMonth < oneMonth - 5) {
  trendMultiplier = 0.9;  // Declining
}

// Benchmark bonus (80% standard)
if (recentPerformance >= 80) {
  benchmarkBonus = 1.0 + ((recentPerformance - 80) / 100.0);
} else {
  benchmarkBonus = recentPerformance / 80;
}

// Final score
final finalScore = baseScore * trendMultiplier * performanceMultiplier * benchmarkBonus;
```

### Data Contributing to Results:
✅ **NPSMonthlyReport.oneMonthNpsPercentage** - Weighted 50% in base score  
✅ **NPSMonthlyReport.threeMonthNpsPercentage** - Weighted 30% in base score  
✅ **NPSMonthlyReport.allTimeNpsPercentage** - Weighted 20% in base score  
✅ **NPSMonthlyReport.reportYear** - For chronological sorting  
✅ **NPSMonthlyReport.reportMonth** - For trend analysis  
✅ **NPSMonthlyReport.allTimeSales** - For total sales calculation  
✅ **NPSMonthlyReport.allTimeTableCount** - For total checks calculation

### Accuracy Notes:
⚠️ **Uses most recent report per server** - Not all months, just latest  
⚠️ **Trend calculation compares 1-month vs 3-month** - May not show true trend if data is sparse  
✅ **Automatic orphaned ID filtering** - Ensures clean data

---

## 🎯 **Tab 4: Impact (Impact Analytics Widget)**

**Widget**: `ImpactAnalyticsWidget`

### What It Does:
- Shows **Restaurant Impact Rankings** - "Who's helping vs hurting the restaurant"
- Ranks servers by their combined NPS performance and sales impact

### Data Sources:
- **Primary**: `getAllNPSMonthlyReports()` - All monthly reports

### Calculations:

#### **1. Aggregated Server Performance** (Method: `_calculateAggregatedServerPerformance`)

**Step 1: Extract Performance History**
```dart
final List<double> performanceHistory = [];
for (final report in serverReports) {
  final performance = report.threeMonthNpsPercentage 
    ?? report.oneMonthNpsPercentage 
    ?? report.allTimeNpsPercentage 
    ?? 0.0;
  performanceHistory.add(performance);
}
```

**Step 2: Calculate Key Metrics**
```dart
// Recent performance (last available)
final recentPerformance = performanceHistory.last;

// Overall average
final overallPerformance = performanceHistory.reduce((a, b) => a + b) 
  / performanceHistory.length;

// Consistency score (inverse of standard deviation)
final mean = overallPerformance;
final variance = performanceHistory
  .map((x) => (x - mean) * (x - mean))
  .reduce((a, b) => a + b) / performanceHistory.length;
final standardDeviation = sqrt(variance);
final consistencyScore = 100.0 - min(standardDeviation, 20.0);

// Improvement rate (first to last)
final improvementRate = performanceHistory.last - performanceHistory.first;
```

**Step 3: Calculate Sales Impact**
```dart
// Total restaurant sales (all servers)
final totalRestaurantSales = allReports
  .map((r) => r.allTimeSales)
  .fold(0.0, (sum, sales) => sum + sales);

// This server's sales
final serverTotalSales = serverReports
  .map((r) => r.allTimeSales)
  .fold(0.0, (sum, sales) => sum + sales);

// Sales percentage
final salesPercentage = (serverTotalSales / totalRestaurantSales) * 100;
```

**Step 4: Determine Impact Level**
```dart
if (salesPercentage < 5.0) {
  // Low sales impact
  if (recentPerformance >= 80) {
    restaurantImpact = 'Minor Boost';
    impactLevel = 'Good';
  } else {
    restaurantImpact = 'Minor Drag';
    impactLevel = 'Bad';
  }
} else if (salesPercentage < 15.0) {
  // Medium sales impact
  if (recentPerformance >= 85) {
    restaurantImpact = 'Restaurant Booster';
    impactLevel = 'Excellent';
  } else if (recentPerformance >= 80) {
    restaurantImpact = 'Above Standard';
  } else if (recentPerformance >= 70) {
    restaurantImpact = 'Below Standard';
  } else {
    restaurantImpact = 'Restaurant Drag';  // HURTING
    impactLevel = 'Problem';
  }
} else {
  // High sales impact (15%+)
  if (recentPerformance >= 85) {
    restaurantImpact = 'STAR PERFORMER';  // Major booster
  } else if (recentPerformance >= 80) {
    restaurantImpact = 'Key Player';
  } else {
    restaurantImpact = 'MAJOR CONCERN';  // High sales but poor NPS
  }
}
```

### Data Contributing to Results:
✅ **NPSMonthlyReport.threeMonthNpsPercentage** (primary) - Used for recent performance  
✅ **NPSMonthlyReport.oneMonthNpsPercentage** (fallback) - If 3-month unavailable  
✅ **NPSMonthlyReport.allTimeNpsPercentage** (fallback) - If both above unavailable  
✅ **NPSMonthlyReport.allTimeSales** - For sales percentage calculation  
✅ **NPSMonthlyReport.reportMonth** - For chronological sorting  
⚠️ **All monthly reports combined** - Sums all sales across all months per server

### Impact Scoring Formula:
```
Impact Level = f(Sales Percentage, Recent NPS Performance, Improvement Trend)

Where:
- Sales Percentage = (Server Sales / Total Restaurant Sales) * 100
- Recent Performance = Most recent 3-month NPS (or best available)
- Improvement Trend = Last Performance - First Performance
```

### Accuracy Notes:
⚠️ **Uses ALL sales from ALL monthly reports** - May double-count if reports overlap  
⚠️ **Prefers threeMonthNpsPercentage** - Falls back to 1-month or all-time  
✅ **Chronological sorting** - Ensures "recent" is actually most recent  
✅ **Consistency calculation** - Penalizes volatile performers

---

## 📊 **Tab 5: Trends (Individual Server NPS Trend Widget)**

**Widget**: `IndividualServerNPSTrendWidget`

### What It Does:
- Shows **Advanced Trend Analysis** for each server
- Identifies servers trending up or down
- Provides performance pattern insights

### Data Sources:
- **Primary**: `getAllNPSMonthlyReports()` - All monthly reports
- **Trend Analysis**: `AdvancedTrendAnalysisService` - Calculates trends

### Calculations:

#### **1. Trend Analysis Per Server** (via `AdvancedTrendAnalysisService`)
```dart
for (final entry in reportsByServer.entries) {
  final serverId = entry.key;
  final serverReports = entry.value;
  
  if (serverReports.length >= 2) {
    final analysis = trend_analysis.AdvancedTrendAnalysisService
      .analyzeTrend(serverReports);
    _serverTrendAnalyses[serverId] = analysis;
  }
}
```

#### **2. Trend Direction Classification**
The `AdvancedTrendAnalysisService` assigns one of these:
- **Strongly Improving** - Consistent upward trend, slope > 5
- **Improving** - Upward trend, slope > 2
- **Stable** - Minimal change, -2 < slope < 2
- **Declining** - Downward trend, slope < -2
- **Strongly Declining** - Consistent downward trend, slope < -5

#### **3. Trend Distribution Summary**
```dart
final trendCounts = <TrendDirection, int>{};
for (final analysis in _serverTrendAnalyses.values) {
  trendCounts[analysis.trendDirection] = 
    (trendCounts[analysis.trendDirection] ?? 0) + 1;
}
```

Shows how many servers fall into each trend category.

### Data Contributing to Results:
✅ **All NPSMonthlyReport data** - Full history analyzed  
✅ **Report chronological order** - Sorted by reportMonth  
✅ **Minimum 2 reports required** - Can't calculate trend with only 1 data point  
✅ **Statistical slope calculation** - Linear regression on performance over time

### Accuracy Notes:
⚠️ **Requires minimum 2 monthly reports** - Servers with 1 report won't show  
✅ **Uses actual slope calculation** - Not just first vs last comparison  
✅ **Filters orphaned IDs** - Only valid servers included

---

## 🔍 **Data Accuracy Checklist**

### ✅ **What's Working Well:**
1. **Automatic ID filtering** - All widgets now filter out orphaned numeric IDs
2. **Consistent data source** - All use `getAllNPSMonthlyReports()` mixin method
3. **Type-safe data** - Direct use of `NPSMonthlyReport` models, no raw maps
4. **Chronological sorting** - Reports sorted by month/year for accurate "recent" calculations

### ⚠️ **Potential Accuracy Issues:**

#### **Issue 1: "Most Recent" Definition**
**Where**: Analytics Tab, Impact Tab  
**Problem**: "Most recent" is determined by `reportMonth` (YYYYMM format)  
**Example**: If September 2025 report exists but October 2025 doesn't, September is "most recent"  
**Impact**: Accurate - this is correct behavior  
**Status**: ✅ **No issue**

#### **Issue 2: Sales Summation in Impact Tab**
**Where**: Impact Analytics Widget  
**Problem**: Sums `allTimeSales` from ALL monthly reports per server  
**Example**: If server has 3 monthly reports, it sums allTimeSales 3 times  
**Impact**: **DOUBLE/TRIPLE COUNTING** - Sales percentage will be inflated  
**Status**: ⚠️ **POTENTIAL ISSUE**

**Recommendation**: Should use `allTimeSales` from MOST RECENT report only, not sum all reports

#### **Issue 3: Fallback Priority for NPS**
**Where**: Impact Analytics Widget  
**Problem**: Falls back from 3-month → 1-month → all-time  
**Example**: Server A has only all-time (60%), Server B has 3-month (85%)  
**Impact**: Comparing different metrics - not apples-to-apples  
**Status**: ⚠️ **ACCEPTABLE** - necessary to handle missing data

#### **Issue 4: Inconsistent Weighting**
**Where**: Analytics Tab performance score  
**Formula**: `oneMonth * 0.5 + threeMonth * 0.3 + allTime * 0.2`  
**Problem**: Recent performance (1-month) weighted higher than 3-month  
**Impact**: Volatile - a single bad month can tank the score  
**Status**: ⚠️ **DESIGN CHOICE** - may or may not be desired

---

## 📝 **Summary & Recommendations**

### **Current State:**
- All tabs are using **consistent data sources** (ServerDataMixin)
- **Automatic filtering** of orphaned IDs is working
- Calculations are **well-documented** in code
- No crashes or major bugs

### **Data Accuracy:**
- **Status Tab**: ✅ Accurate
- **Analytics Tab**: ✅ Mostly accurate (design choice on weighting)
- **Impact Tab**: ⚠️ **Sales may be over-counted** (sums all monthly reports)
- **Trends Tab**: ✅ Accurate (requires 2+ reports)

### **Recommendations:**

1. **Fix Sales Calculation in Impact Tab**  
   ```dart
   // Current (❌ WRONG):
   final serverTotalSales = serverReports
     .map((r) => r.allTimeSales)
     .fold(0.0, (sum, sales) => sum + sales);  // Sums ALL reports
   
   // Should be (✅ CORRECT):
   final mostRecentReport = serverReports.reduce((a, b) => 
     a.reportMonth > b.reportMonth ? a : b);
   final serverTotalSales = mostRecentReport.allTimeSales;  // Latest only
   ```

2. **Verify NPS Weighting in Analytics Tab**  
   - Confirm that 50% weight on 1-month NPS is intentional
   - Consider adjusting to favor 3-month stability

3. **Add Data Validation Warnings**  
   - Show warning if comparing different NPS types (1-month vs 3-month)
   - Indicate when using fallback metrics

4. **Document Minimum Data Requirements**  
   - Trends tab needs 2+ reports
   - Impact tab needs sales data
   - Analytics needs at least 1 report per server

---

**Report Generated**: October 9, 2025  
**Analysis Complete**: No changes made to application code  
**Status**: Ready for review and discussion




