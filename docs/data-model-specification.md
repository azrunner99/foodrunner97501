# Server NPS Data Model Specification

## Overview

This document defines the complete data model for the Server NPS system, including database schema, data relationships, constraints, and business rules. The model supports comprehensive guest feedback tracking with temporal analysis capabilities.

## Database Schema

### 1. servers Table

**Purpose**: Store server employee information and employment details.

```sql
CREATE TABLE servers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    hire_date DATE NOT NULL,
    active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_servers_active ON servers(active);
CREATE INDEX idx_servers_hire_date ON servers(hire_date);
```

**Field Specifications**:
- `id`: Unique server identifier (auto-incrementing primary key)
- `name`: Server's full name (required, non-empty string)
- `hire_date`: Employment start date (required, format: YYYY-MM-DD)
- `active`: Employment status (1 = active, 0 = inactive, default: 1)
- `created_at`: Record creation timestamp (auto-generated)
- `updated_at`: Last modification timestamp (updated on changes)

**Business Rules**:
- Server names must be unique within the active server roster
- Hire date cannot be in the future
- Inactive servers retain all historical data but don't appear in active reports
- Deletion is not permitted; use `active = 0` for terminations

### 2. nps_feedback Table

**Purpose**: Store individual guest feedback responses about server performance.

```sql
CREATE TABLE nps_feedback (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER NOT NULL,
    feedback_type TEXT NOT NULL CHECK(feedback_type IN ('yes', 'maybe', 'no')),
    feedback_date DATE NOT NULL,
    sales_amount DECIMAL(10,2),
    table_number INTEGER,
    shift_period TEXT CHECK(shift_period IN ('breakfast', 'lunch', 'dinner', 'late_night')),
    guest_count INTEGER,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE RESTRICT
);

-- Indexes for performance
CREATE INDEX idx_feedback_server_id ON nps_feedback(server_id);
CREATE INDEX idx_feedback_date ON nps_feedback(feedback_date);
CREATE INDEX idx_feedback_server_date ON nps_feedback(server_id, feedback_date);
CREATE INDEX idx_feedback_type ON nps_feedback(feedback_type);
```

**Field Specifications**:
- `id`: Unique feedback record identifier
- `server_id`: Reference to server who received feedback (required)
- `feedback_type`: Guest response ('yes', 'maybe', 'no') (required)
- `feedback_date`: Date when feedback was given (required)
- `sales_amount`: Total sales for the table/service (optional, 2 decimal places)
- `table_number`: Table identifier for the service (optional)
- `shift_period`: Time period of service (optional)
- `guest_count`: Number of guests at the table (optional)
- `notes`: Additional comments or context (optional)
- `created_at`: Record creation timestamp

**Business Rules**:
- Feedback date cannot be in the future
- Sales amount must be positive if provided
- Guest count must be positive if provided
- Each feedback entry represents one guest experience
- Multiple entries can exist for the same server on the same date

### 3. nps_monthly_reports Table

**Purpose**: Store pre-calculated monthly NPS reports for performance optimization.

```sql
CREATE TABLE nps_monthly_reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER NOT NULL,
    report_month INTEGER NOT NULL, -- YYYYMM format (e.g., 202401 for January 2024)
    report_year INTEGER NOT NULL,
    
    -- NPS Percentages
    all_time_nps_percentage DECIMAL(5,2),
    three_month_nps_percentage DECIMAL(5,2),
    one_month_nps_percentage DECIMAL(5,2),
    
    -- Cumulative Metrics
    all_time_sales DECIMAL(12,2) DEFAULT 0.00,
    all_time_table_count INTEGER DEFAULT 0,
    
    -- Monthly Feedback Counts
    month_feedback_yes INTEGER DEFAULT 0,
    month_feedback_maybe INTEGER DEFAULT 0,
    month_feedback_no INTEGER DEFAULT 0,
    month_total_feedback INTEGER GENERATED ALWAYS AS (
        month_feedback_yes + month_feedback_maybe + month_feedback_no
    ) STORED,
    
    -- Three-Month Feedback Counts
    three_month_feedback_yes INTEGER DEFAULT 0,
    three_month_feedback_maybe INTEGER DEFAULT 0,
    three_month_feedback_no INTEGER DEFAULT 0,
    three_month_total_feedback INTEGER GENERATED ALWAYS AS (
        three_month_feedback_yes + three_month_feedback_maybe + three_month_feedback_no
    ) STORED,
    
    -- All-Time Feedback Counts
    all_time_feedback_yes INTEGER DEFAULT 0,
    all_time_feedback_maybe INTEGER DEFAULT 0,
    all_time_feedback_no INTEGER DEFAULT 0,
    all_time_total_feedback INTEGER GENERATED ALWAYS AS (
        all_time_feedback_yes + all_time_feedback_maybe + all_time_feedback_no
    ) STORED,
    
    -- Metadata
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_as_of_date DATE NOT NULL,
    
    FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE RESTRICT,
    UNIQUE(server_id, report_month)
);

-- Indexes for performance
CREATE INDEX idx_monthly_reports_server_id ON nps_monthly_reports(server_id);
CREATE INDEX idx_monthly_reports_month ON nps_monthly_reports(report_month);
CREATE INDEX idx_monthly_reports_year ON nps_monthly_reports(report_year);
CREATE INDEX idx_monthly_reports_server_month ON nps_monthly_reports(server_id, report_month);
```

**Field Specifications**:
- `report_month`: YYYYMM format (e.g., 202401 for January 2024)
- `report_year`: Four-digit year for easier querying
- `*_nps_percentage`: NPS scores as percentages (-100.00 to 100.00)
- `all_time_sales`: Cumulative sales since hire date
- `all_time_table_count`: Cumulative table count since hire date
- `*_feedback_*`: Breakdown of feedback counts by type and period
- `*_total_feedback`: Auto-calculated total feedback counts
- `data_as_of_date`: Date through which data was calculated

**Business Rules**:
- One report per server per month maximum
- NPS percentages calculated as: ((Yes - No) / Total) * 100
- All-time metrics must be monotonically increasing for active servers
- Monthly reports are generated after month-end
- Historical reports are immutable once generated

### 4. nps_calculation_log Table (Optional)

**Purpose**: Audit trail for NPS calculations and report generation.

```sql
CREATE TABLE nps_calculation_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    calculation_type TEXT NOT NULL, -- 'monthly_report', 'ad_hoc', 'data_correction'
    server_id INTEGER,
    report_month INTEGER,
    calculation_start TIMESTAMP NOT NULL,
    calculation_end TIMESTAMP NOT NULL,
    records_processed INTEGER NOT NULL,
    success BOOLEAN NOT NULL,
    error_message TEXT,
    created_by TEXT, -- User or system identifier
    
    FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE SET NULL
);

CREATE INDEX idx_calc_log_type ON nps_calculation_log(calculation_type);
CREATE INDEX idx_calc_log_date ON nps_calculation_log(calculation_start);
```

## Data Relationships

### Entity Relationship Diagram

```
servers (1) ──────┐
                  │
                  │ 1:N
                  │
                  ▼
            nps_feedback (N)
                  │
                  │
                  │ N:1
                  │
                  ▼
         nps_monthly_reports (1)
```

### Relationship Rules

1. **servers → nps_feedback**: One-to-Many
   - One server can have multiple feedback entries
   - Feedback must reference a valid server
   - Server deletion is restricted if feedback exists

2. **servers → nps_monthly_reports**: One-to-Many
   - One server can have multiple monthly reports
   - Each report corresponds to one calendar month
   - Reports aggregate all feedback for the server/month

3. **nps_feedback → nps_monthly_reports**: Many-to-One (implicit)
   - Multiple feedback entries contribute to one monthly report
   - Monthly reports are derived from feedback data
   - Direct foreign key not enforced (calculated relationship)

## NPS Calculation Formulas

### Basic NPS Formula
```
NPS = ((Total Yes - Total No) / Total Feedback) × 100
```

### Time Period Calculations

#### All-Time NPS
```sql
SELECT 
    server_id,
    ((SUM(CASE WHEN feedback_type = 'yes' THEN 1 ELSE 0 END) - 
      SUM(CASE WHEN feedback_type = 'no' THEN 1 ELSE 0 END)) * 100.0 / 
     COUNT(*)) AS all_time_nps
FROM nps_feedback 
WHERE server_id = ? 
GROUP BY server_id;
```

#### Three-Month NPS
```sql
SELECT 
    server_id,
    ((SUM(CASE WHEN feedback_type = 'yes' THEN 1 ELSE 0 END) - 
      SUM(CASE WHEN feedback_type = 'no' THEN 1 ELSE 0 END)) * 100.0 / 
     COUNT(*)) AS three_month_nps
FROM nps_feedback 
WHERE server_id = ? 
  AND feedback_date >= DATE('now', '-3 months')
GROUP BY server_id;
```

#### One-Month NPS
```sql
SELECT 
    server_id,
    ((SUM(CASE WHEN feedback_type = 'yes' THEN 1 ELSE 0 END) - 
      SUM(CASE WHEN feedback_type = 'no' THEN 1 ELSE 0 END)) * 100.0 / 
     COUNT(*)) AS one_month_nps
FROM nps_feedback 
WHERE server_id = ? 
  AND strftime('%Y-%m', feedback_date) = ?
GROUP BY server_id;
```

## Data Validation Rules

### Input Validation

#### Server Data
- `name`: Non-empty string, max 100 characters
- `hire_date`: Valid date, not in future
- `active`: Boolean value only

#### Feedback Data
- `server_id`: Must exist in servers table
- `feedback_type`: Must be 'yes', 'maybe', or 'no'
- `feedback_date`: Valid date, not in future, not before server hire date
- `sales_amount`: If provided, must be positive number
- `table_number`: If provided, must be positive integer
- `guest_count`: If provided, must be positive integer

#### Report Data
- `report_month`: Valid YYYYMM format
- `server_id`: Must exist in servers table
- NPS percentages: Must be between -100.00 and 100.00
- Feedback counts: Must be non-negative integers
- Total calculations: Must equal sum of individual counts

### Business Logic Validation

#### Temporal Consistency
- Feedback dates must be chronologically logical
- Monthly reports must align with calendar months
- All-time metrics must be cumulative and increasing

#### Data Integrity
- Feedback totals must match individual type counts
- NPS calculations must align with feedback data
- Historical data must remain immutable

## Performance Considerations

### Database Optimization

#### Indexing Strategy
- Primary keys on all tables
- Foreign key indexes for joins
- Composite indexes for common query patterns
- Date-based indexes for temporal queries

#### Query Optimization
- Use prepared statements for repeated queries
- Batch insert operations for bulk data
- Limit result sets with appropriate WHERE clauses
- Use EXPLAIN QUERY PLAN for performance analysis

### Calculation Optimization

#### Pre-calculated Reports
- Monthly reports reduce real-time calculation load
- Store intermediate calculations for faster access
- Update reports incrementally when possible

#### Caching Strategy
- Cache frequently accessed NPS calculations
- Invalidate cache when underlying data changes
- Use memory-efficient caching for mobile devices

## Data Migration Strategy

### Initial Data Import
1. Create database schema with all tables and indexes
2. Import existing server roster if available
3. Set up initial admin user access
4. Generate baseline monthly reports for current month

### Historical Data Migration
1. Import historical feedback data if available
2. Validate data integrity and business rules
3. Generate historical monthly reports
4. Verify calculation accuracy

### Ongoing Data Maintenance
1. Monthly report generation automation
2. Data archival policies for old feedback
3. Performance monitoring and optimization
4. Regular data integrity checks

## Security Considerations

### Data Protection
- Sensitive data encryption at rest
- Secure backup and restore procedures
- Access control for admin functions
- Audit trail for data modifications

### Input Sanitization
- Validate all user inputs
- Prevent SQL injection attacks
- Sanitize text fields for XSS prevention
- Implement rate limiting for data entry

### Privacy Compliance
- Guest feedback anonymization
- Data retention policies
- Right to data deletion procedures
- Consent management for data collection