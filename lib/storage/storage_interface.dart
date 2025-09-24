/// Abstract interface for cross-platform storage backends
/// 
/// This interface defines the contract that all storage implementations
/// must follow, enabling platform-adaptive storage selection without
/// changing business logic code.
abstract class StorageInterface {
  /// Initialize the storage backend
  /// 
  /// This method must be called before any other storage operations.
  /// It sets up the underlying storage system and prepares it for use.
  Future<void> init();
  
  /// Retrieve a value by key
  /// 
  /// Returns the stored value for the given [key], or null if the key
  /// doesn't exist. Values are stored and retrieved as dynamic types.
  Future<dynamic> get(String key);
  
  /// Store a value with the given key
  /// 
  /// Stores [value] under the specified [key]. The value will be
  /// serialized appropriately for the underlying storage backend.
  Future<void> put(String key, dynamic value);
  
  /// Remove a value by key
  /// 
  /// Deletes the value stored under [key]. Does nothing if the key
  /// doesn't exist.
  Future<void> delete(String key);
  
  /// Get all keys currently stored
  /// 
  /// Returns a Set containing all keys that have values stored.
  /// Useful for iteration or checking what data exists.
  Future<Set<String>> getKeys();
  
  /// Clear all stored data
  /// 
  /// Removes all key-value pairs from storage. Use with caution
  /// as this operation is irreversible.
  Future<void> clear();
  
  /// Check if a key exists in storage
  /// 
  /// Returns true if [key] has a value stored, false otherwise.
  /// This is more efficient than calling get() when you only need
  /// to check existence.
  Future<bool> containsKey(String key);
  
  /// Get the number of stored key-value pairs
  /// 
  /// Returns the total count of items currently stored.
  Future<int> get length;
  
  /// Close the storage backend and release resources
  /// 
  /// Should be called when the storage is no longer needed.
  /// Some backends may require explicit cleanup.
  Future<void> close();
}