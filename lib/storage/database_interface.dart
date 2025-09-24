/// Abstract interface for cross-platform database operations
/// 
/// This interface abstracts database operations to enable platform-specific 
/// implementations (sqflite for Android, drift for Windows) while maintaining
/// the same API for business logic.
abstract class DatabaseInterface {
  /// Initialize the database connection and schema
  Future<void> init();
  
  /// Execute a raw SQL query and return results
  Future<List<Map<String, dynamic>>> queryTable(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  });
  
  /// Insert data into a table and return the row ID
  Future<int> insertInto(
    String table, 
    Map<String, dynamic> data, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  });
  
  /// Update data in a table and return number of rows affected
  Future<int> updateTable(
    String table, 
    Map<String, dynamic> data, 
    String where, 
    List<dynamic> args, {
    ConflictAlgorithm? conflictAlgorithm,
  });
  
  /// Delete data from a table and return number of rows affected
  Future<int> deleteFrom(
    String table, 
    String where, 
    List<dynamic> args,
  );
  
  /// Execute raw SQL (for schema creation, etc.)
  Future<void> execute(String sql);
  
  /// Execute SQL in a transaction
  Future<T> runTransaction<T>(Future<T> Function(DatabaseTransaction txn) action);
  
  /// Get database version
  Future<int> getVersion();
  
  /// Close the database connection
  Future<void> close();
}

/// Abstract transaction interface
abstract class DatabaseTransaction {
  Future<List<Map<String, dynamic>>> queryTable(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  });
  
  Future<int> insertInto(String table, Map<String, dynamic> data);
  Future<int> updateTable(String table, Map<String, dynamic> data, String where, List<dynamic> args);
  Future<int> deleteFrom(String table, String where, List<dynamic> args);
  Future<void> execute(String sql);
}

/// Conflict resolution algorithms for insert/update operations
enum ConflictAlgorithm {
  rollback,
  abort,
  fail,
  ignore,
  replace,
}