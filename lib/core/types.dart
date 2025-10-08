/// Core type definitions for consistent ID handling across the application
/// 
/// This file provides typedefs to enforce consistent ID types throughout
/// the codebase, preventing INTEGER vs TEXT mismatches.
library;

/// Server identifier type - always TEXT/String
typedef ServerId = String;

/// User identifier type - always TEXT/String  
typedef UserId = String;



