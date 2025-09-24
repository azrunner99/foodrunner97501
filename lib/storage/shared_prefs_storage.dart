import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_interface.dart';

/// SharedPreferences-based implementation of StorageInterface
/// 
/// This implementation maintains compatibility with the existing Android
/// storage system while providing the new StorageInterface contract.
/// Used as the default storage backend for mobile platforms.
class SharedPrefsStorage implements StorageInterface {
  SharedPreferences? _prefs;
  
  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  @override
  Future<dynamic> get(String key) async {
    final raw = _prefs?.getString(key);
    if (raw == null) return null;
    
    try {
      return jsonDecode(raw);
    } catch (e) {
      // Return raw string if JSON decode fails (backward compatibility)
      return raw;
    }
  }
  
  @override
  Future<void> put(String key, dynamic value) async {
    await _prefs?.setString(key, jsonEncode(value));
  }
  
  @override
  Future<void> delete(String key) async {
    await _prefs?.remove(key);
  }
  
  @override
  Future<Set<String>> getKeys() async {
    return _prefs?.getKeys() ?? <String>{};
  }
  
  @override
  Future<void> clear() async {
    await _prefs?.clear();
  }
  
  @override
  Future<bool> containsKey(String key) async {
    return _prefs?.containsKey(key) ?? false;
  }
  
  @override
  Future<int> get length async {
    final keys = await getKeys();
    return keys.length;
  }
  
  @override
  Future<void> close() async {
    // SharedPreferences doesn't require explicit cleanup
    _prefs = null;
  }
}