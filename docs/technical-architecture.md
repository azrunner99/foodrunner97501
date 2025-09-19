# Server NPS Technical Architecture

## System Overview

The Server NPS system consists of multiple layers designed to capture, store, analyze, and report on guest feedback regarding server performance. The architecture follows Flutter best practices with Provider state management and SQLite for data persistence.

## Component Architecture

### 1. User Interface Layer

#### ServerNPSScreen (`lib/screens/server_nps_screen.dart`)
- **Status**: ✅ Implemented
- **Purpose**: Main administrative interface for NPS management
- **Components**:
  - Overview Tab: System status and summary metrics
  - Data Entry Tab: Manual feedback entry and batch operations
  - Analytics Tab: Reporting and trend analysis
- **Navigation**: Accessible via Admin Tools → Server NPS
- **Dependencies**: Provider for state management

#### Admin Integration (`lib/screens/clean_admin_screen.dart`)
- **Status**: ✅ Implemented
- **Purpose**: Admin tools menu with Server NPS access
- **Features**:
  - Server NPS tile with smiley icon indicator
  - Auto-unlock for testing (temporary)
  - Back navigation to home screen
- **Note**: Uses `clean_admin_screen.dart` due to build cache corruption issues

### 2. State Management Layer

#### NPSProvider
- **Status**: ✅ Implemented
- **Purpose**: Centralized state management for NPS data
- **Responsibilities**:
  - Server roster management
  - Feedback data management
  - Monthly calculation engine
  - Report generation coordination
- **Pattern**: Provider pattern for reactive UI updates

#### AppState Integration
- **Status**: 🔄 Planned
- **Purpose**: Integration with existing app state management
- **File**: `lib/app_state.dart`
- **Requirements**:
  - NPS data persistence
  - Admin access control
  - Backup system compatibility

### 3. Data Storage Layer

#### SQLite Database Schema

##### servers Table
```sql
CREATE TABLE servers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    hire_date DATE NOT NULL,
    active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

##### nps_feedback Table
```sql
CREATE TABLE nps_feedback (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER NOT NULL,
    feedback_type TEXT CHECK(feedback_type IN ('yes', 'maybe', 'no')),
    feedback_date DATE NOT NULL,
    sales_amount DECIMAL(10,2),
    table_number INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (server_id) REFERENCES servers(id)
);
```

##### nps_monthly_reports Table
```sql
CREATE TABLE nps_monthly_reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER NOT NULL,
    report_month INTEGER NOT NULL, -- YYYYMM format
    all_time_nps_percentage DECIMAL(5,2),
    three_month_nps_percentage DECIMAL(5,2),
    one_month_nps_percentage DECIMAL(5,2),
    all_time_sales DECIMAL(12,2),
    all_time_table_count INTEGER,
    feedback_count_yes INTEGER DEFAULT 0,
    feedback_count_maybe INTEGER DEFAULT 0,
    feedback_count_no INTEGER DEFAULT 0,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (server_id) REFERENCES servers(id),
    UNIQUE(server_id, report_month)
);
```

- **Status**: ✅ Implemented
- **File**: `lib/storage/nps_database.dart`
- **Purpose**: SQLite operations for NPS data
- **Dependencies**: `sqflite` package
- **Methods**:
  - Server CRUD operations
  - Feedback recording
  - Monthly report generation
  - Historical data queries

### 4. Business Logic Layer

- **Status**: ✅ Implemented
- **File**: `lib/utils/nps_calculator.dart`
- **Purpose**: Core NPS calculation algorithms
- **Functions**:
  - `calculateAllTimeNPS(serverId)`: Cumulative NPS since hire
  - `calculateThreeMonthNPS(serverId, endDate)`: Rolling 3-month NPS
  - `calculateOneMonthNPS(serverId, month)`: Single month NPS
  - `generateTrendAnalysis(serverId)`: Compare 1-month vs 3-month

#### Feedback Processor (Planned)
- **Status**: 🔄 Planned
- **File**: `lib/utils/feedback_processor.dart`
- **Purpose**: Process and validate feedback entries
- **Functions**:
  - `recordFeedback(serverId, type, date, sales, table)`
  - `validateFeedbackData(feedbackData)`
  - `batchProcessFeedback(feedbackList)`

#### Report Generator (Planned)
- **Status**: 🔄 Planned
- **File**: `lib/utils/report_generator.dart`
- **Purpose**: Monthly report creation and management
- **Functions**:
  - `generateMonthlyReport(month, year)`
  - `getServerReport(serverId, month)`
  - `exportReportData(month, format)`

### 5. Data Models

#### Server Model (Planned)
```dart
class Server {
  final int id;
  final String name;
  final DateTime hireDate;
  final bool active;
  
  Server({
    required this.id,
    required this.name,
    required this.hireDate,
    this.active = true,
  });
}
```

#### NPSFeedback Model (Planned)
```dart
enum FeedbackType { yes, maybe, no }

class NPSFeedback {
  final int id;
  final int serverId;
  final FeedbackType type;
  final DateTime date;
  final double? salesAmount;
  final int? tableNumber;
  
  NPSFeedback({
    required this.id,
    required this.serverId,
    required this.type,
    required this.date,
    this.salesAmount,
    this.tableNumber,
  });
}
```

#### MonthlyReport Model (Planned)
```dart
class MonthlyReport {
  final int serverId;
  final int reportMonth; // YYYYMM
  final double allTimeNPS;
  final double threeMonthNPS;
  final double oneMonthNPS;
  final double allTimeSales;
  final int allTimeTableCount;
  final Map<FeedbackType, int> feedbackCounts;
  
  MonthlyReport({
    required this.serverId,
    required this.reportMonth,
    required this.allTimeNPS,
    required this.threeMonthNPS,
    required this.oneMonthNPS,
    required this.allTimeSales,
    required this.allTimeTableCount,
    required this.feedbackCounts,
  });
}
```

## Integration Points

### Existing System Integration

#### Storage System (`lib/storage.dart`)
- **Integration**: Extend existing backup/restore functionality
- **Requirements**: Include NPS data in backup operations
- **Status**: 🔄 Planned

#### App State (`lib/app_state.dart`)
- **Integration**: Add NPS data to global app state
- **Requirements**: Provider pattern compatibility
- **Status**: 🔄 Planned

#### Theme System (`lib/theme/`)
- **Integration**: Apply consistent theming to NPS screens
- **Requirements**: Color scheme and typography consistency
- **Status**: ✅ Already compatible

### External Dependencies

#### Required Packages
```yaml
dependencies:
  sqflite: ^2.3.0  # SQLite database
  intl: ^0.18.1    # Date formatting
  path: ^1.8.3     # File path utilities
```

#### Development Dependencies
```yaml
dev_dependencies:
  mockito: ^5.4.2  # Testing mocks
  test: ^1.24.6    # Unit testing
```

## Performance Considerations

### Database Optimization
- **Indexing**: Create indexes on frequently queried columns
  - `server_id` in feedback table
  - `feedback_date` for time-based queries
  - `report_month` for monthly reports

### Memory Management
- **Lazy Loading**: Load monthly reports on demand
- **Data Pagination**: Implement pagination for large feedback datasets
- **Cache Strategy**: Cache frequently accessed NPS calculations

### Calculation Efficiency
- **Incremental Updates**: Update NPS calculations as new feedback arrives
- **Batch Processing**: Process multiple feedback entries in transactions
- **Background Processing**: Generate monthly reports asynchronously

## Security & Data Integrity

### Data Validation
- **Input Validation**: Validate all feedback data before storage
- **Date Constraints**: Ensure feedback dates are within valid ranges
- **Server Validation**: Verify server exists before recording feedback

### Backup & Recovery
- **Integration**: Include NPS data in existing backup system
- **Versioning**: Maintain data version compatibility
- **Recovery**: Support selective NPS data restoration

### Access Control
- **Admin Only**: NPS management restricted to admin users
- **Audit Trail**: Log all NPS data modifications
- **Data Export**: Controlled export functionality for reports

## Testing Strategy

### Unit Testing
- **Model Tests**: Validate data model serialization/deserialization
- **Calculator Tests**: Verify NPS calculation accuracy
- **Database Tests**: Test SQLite operations

### Integration Testing
- **UI Integration**: Test ServerNPSScreen functionality
- **State Management**: Validate Provider state updates
- **Database Integration**: Test full data flow

### Performance Testing
- **Load Testing**: Test with large feedback datasets
- **Calculation Performance**: Benchmark NPS calculation speed
- **UI Responsiveness**: Ensure smooth user experience

## Deployment & Maintenance

### Migration Strategy
- **Database Migration**: Create initial database schema
- **Data Import**: Import any existing server data
- **Feature Rollout**: Gradual feature activation

### Monitoring & Maintenance
- **Error Logging**: Track calculation errors and database issues
- **Performance Monitoring**: Monitor calculation times and UI responsiveness
- **Data Quality**: Regular data integrity checks

### Future Enhancements
- **Real-time Updates**: Live dashboard updates
- **Advanced Analytics**: Predictive analysis and forecasting
- **Mobile Optimization**: Enhanced mobile experience
- **API Integration**: External system integrations