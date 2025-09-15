# Server NPS Business Requirements

## Executive Summary

The Server NPS system tracks guest satisfaction with individual servers through a standardized feedback mechanism, providing management with actionable performance data across multiple time horizons.

## Guest Feedback Process

### Trigger Event
- **When**: After servers provide service to guests
- **Frequency**: Per guest experience (not per visit)
- **Method**: Post-service feedback collection

### Primary Question
**"Would you like to have the same server again?"**

### Response Options & Scoring
| Response | Effect on Server NPS | Business Logic |
|----------|---------------------|----------------|
| **"Yes"** | ✅ Improves NPS% | Positive guest experience |
| **"Maybe"** | ➖ No change to NPS% | Neutral guest experience |
| **"No"** | ❌ Reduces NPS% | Negative guest experience |

## NPS Metrics & Time Periods

### 1. All-Time NPS Score
- **Definition**: Server's cumulative NPS percentage since hired
- **Purpose**: Long-term performance baseline
- **Calculation**: Based on all guest feedback since employment start
- **Trend**: Generally stable, changes slowly over time

### 2. Three-Month NPS Score
- **Definition**: Rolling 3-month average NPS performance
- **Purpose**: Recent performance indicator with statistical significance
- **Calculation**: Guest feedback from last 3 calendar months
- **Trend**: More responsive to performance changes than all-time

### 3. One-Month NPS Score
- **Definition**: Current month's NPS snapshot
- **Purpose**: Most recent performance indicator and trend detection
- **Calculation**: Guest feedback from current calendar month only
- **Limitation**: May have limited statistical reliability due to smaller sample size

## Performance Trend Analysis

### Key Performance Indicator (KPI)
**1-Month vs 3-Month NPS Comparison**

#### Server Improving ⬆️
- **Condition**: 1-Month NPS > 3-Month NPS
- **Interpretation**: Server is trending upward
- **Impact**: All-time NPS score is likely increasing
- **Management Action**: Recognize improvement, identify success factors

#### Server Declining ⬇️
- **Condition**: 1-Month NPS < 3-Month NPS
- **Interpretation**: Server is trending downward
- **Impact**: All-time NPS score is likely decreasing
- **Management Action**: Investigate causes, provide support/training

#### Server Stable ➡️
- **Condition**: 1-Month NPS ≈ 3-Month NPS
- **Interpretation**: Consistent performance
- **Impact**: All-time NPS score is stable
- **Management Action**: Maintain current approach

## Monthly Reporting Cycle

### Report Availability
- **Frequency**: Once per month
- **Timing**: After month-end (typically first week of following month)
- **Coverage**: Complete server roster for the reporting period

### Report Contents

#### NPS Data (Per Server)
1. **All-Time NPS %** - Cumulative since hired
2. **3-Month NPS %** - Rolling quarter performance
3. **1-Month NPS %** - Current month snapshot

#### Supplementary Data (Per Server)
1. **All-Time Sales** - Cumulative sales since hired
2. **All-Time Table Count** - Total tables served since hired

### Data Characteristics
- **Sales Data**: Always increases if server is active (cumulative counter)
- **Table Count**: Always increases if server is active (cumulative counter)
- **NPS Data**: Can fluctuate based on guest feedback trends
- **Consistency**: New reports will show higher sales/tables vs. previous reports for active servers

## Business Rules & Constraints

### Data Integrity Rules
1. **Historical Consistency**: All-time values can only increase or remain stable
2. **Temporal Logic**: 1-month data feeds into 3-month calculations
3. **Sample Size**: Minimum feedback threshold for statistical relevance
4. **Date Boundaries**: Clear month boundaries for period calculations

### Performance Evaluation Guidelines
1. **Primary Metric**: NPS percentages (not raw feedback counts)
2. **Trend Analysis**: 1-month vs 3-month comparison is critical
3. **Context Consideration**: Sales and table count provide performance context
4. **Sample Reliability**: Consider feedback volume when interpreting 1-month data

### Reporting Standards
1. **Monthly Cadence**: Consistent reporting schedule
2. **Complete Roster**: All active servers included in each report
3. **Data Completeness**: All metrics provided for valid comparison
4. **Historical Access**: Previous months' reports retained for trend analysis

## Success Metrics

### System Goals
1. **Guest Satisfaction Tracking**: Reliable feedback collection and analysis
2. **Performance Transparency**: Clear visibility into server performance
3. **Trend Identification**: Early detection of performance changes
4. **Management Support**: Actionable data for personnel decisions

### Key Performance Indicators
1. **Feedback Response Rate**: Percentage of guests providing feedback
2. **NPS Score Distribution**: Range and average across server roster
3. **Performance Trend Accuracy**: Prediction reliability of trend indicators
4. **Management Action Correlation**: Impact of NPS-driven management decisions

## Integration Requirements

### Existing System Integration
1. **Server Management**: Link to current server roster and employment data
2. **Sales System**: Integration with existing sales tracking
3. **Table Assignment**: Connection to shift and table management
4. **Backup System**: Compatibility with existing data backup/restore

### New System Components
1. **Feedback Collection**: Guest survey mechanism
2. **Data Storage**: Monthly NPS record management
3. **Analytics Engine**: Trend analysis and reporting
4. **Admin Interface**: Data entry and report generation tools