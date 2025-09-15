import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Encryption algorithms supported
enum EncryptionAlgorithm {
  aes256,
  xor, // Simple XOR for demo purposes
}

/// Encryption key information
class EncryptionKey {
  final String id;
  final String algorithm;
  final Uint8List keyData;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final Map<String, dynamic> metadata;

  const EncryptionKey({
    required this.id,
    required this.algorithm,
    required this.keyData,
    required this.createdAt,
    required this.expiresAt,
    this.isActive = true,
    this.metadata = const {},
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => isActive && !isExpired;
}

/// Encrypted data container
class EncryptedData {
  final String keyId;
  final String algorithm;
  final Uint8List encryptedBytes;
  final Uint8List? iv; // Initialization vector for AES
  final String? checksum;
  final DateTime encryptedAt;
  final Map<String, dynamic> metadata;

  const EncryptedData({
    required this.keyId,
    required this.algorithm,
    required this.encryptedBytes,
    this.iv,
    this.checksum,
    required this.encryptedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'keyId': keyId,
      'algorithm': algorithm,
      'encryptedBytes': base64.encode(encryptedBytes),
      'iv': iv != null ? base64.encode(iv!) : null,
      'checksum': checksum,
      'encryptedAt': encryptedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory EncryptedData.fromJson(Map<String, dynamic> json) {
    return EncryptedData(
      keyId: json['keyId'],
      algorithm: json['algorithm'],
      encryptedBytes: base64.decode(json['encryptedBytes']),
      iv: json['iv'] != null ? base64.decode(json['iv']) : null,
      checksum: json['checksum'],
      encryptedAt: DateTime.parse(json['encryptedAt']),
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Encryption configuration
class EncryptionConfig {
  final EncryptionAlgorithm defaultAlgorithm;
  final int keyRotationDays;
  final bool encryptPII; // Personally Identifiable Information
  final bool encryptFeedback;
  final bool encryptExports;
  final bool encryptBackups;
  final List<String> sensitiveFields;

  const EncryptionConfig({
    this.defaultAlgorithm = EncryptionAlgorithm.xor,
    this.keyRotationDays = 90,
    this.encryptPII = true,
    this.encryptFeedback = true,
    this.encryptExports = true,
    this.encryptBackups = true,
    this.sensitiveFields = const [
      'email',
      'comment',
      'feedback',
      'personal_data',
      'user_data',
    ],
  });
}

/// Data encryption service for NPS system
class NPSEncryptionService extends ChangeNotifier {
  final Map<String, EncryptionKey> _keys = {};
  EncryptionKey? _activeKey;
  EncryptionConfig _config = const EncryptionConfig();
  final Random _random = Random.secure();

  // Getters
  EncryptionKey? get activeKey => _activeKey;
  EncryptionConfig get config => _config;
  List<EncryptionKey> get allKeys => _keys.values.toList();

  /// Initialize encryption service
  void initialize() {
    _generateInitialKey();
  }

  /// Generate initial encryption key
  void _generateInitialKey() {
    final key = _generateKey();
    _keys[key.id] = key;
    _activeKey = key;
    notifyListeners();
  }

  /// Generate new encryption key
  EncryptionKey _generateKey() {
    final keyId = 'key_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
    final keyData = _generateRandomBytes(32); // 256-bit key
    
    return EncryptionKey(
      id: keyId,
      algorithm: _config.defaultAlgorithm.name,
      keyData: keyData,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(days: _config.keyRotationDays)),
      metadata: {
        'created_by': 'system',
        'purpose': 'nps_data_encryption',
      },
    );
  }

  /// Generate random bytes for keys/IVs
  Uint8List _generateRandomBytes(int length) {
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  /// Encrypt string data
  Future<EncryptedData> encryptString(String plaintext) async {
    if (_activeKey == null || !_activeKey!.isValid) {
      await rotateKey();
    }

    final key = _activeKey!;
    final plaintextBytes = utf8.encode(plaintext);
    
    switch (_config.defaultAlgorithm) {
      case EncryptionAlgorithm.aes256:
        return _encryptAES(plaintextBytes, key);
      case EncryptionAlgorithm.xor:
        return _encryptXOR(plaintextBytes, key);
    }
  }

  /// Decrypt string data
  Future<String> decryptString(EncryptedData encryptedData) async {
    final key = _keys[encryptedData.keyId];
    if (key == null) {
      throw EncryptionException('Encryption key not found: ${encryptedData.keyId}');
    }

    Uint8List decryptedBytes;
    
    switch (encryptedData.algorithm) {
      case 'aes256':
        decryptedBytes = _decryptAES(encryptedData, key);
        break;
      case 'xor':
        decryptedBytes = _decryptXOR(encryptedData, key);
        break;
      default:
        throw EncryptionException('Unsupported algorithm: ${encryptedData.algorithm}');
    }

    return utf8.decode(decryptedBytes);
  }

  /// Encrypt using XOR (simple demo implementation)
  EncryptedData _encryptXOR(Uint8List plaintext, EncryptionKey key) {
    final encrypted = Uint8List(plaintext.length);
    final keyBytes = key.keyData;
    
    for (int i = 0; i < plaintext.length; i++) {
      encrypted[i] = plaintext[i] ^ keyBytes[i % keyBytes.length];
    }

    // Simple checksum
    final checksum = _calculateChecksum(plaintext);

    return EncryptedData(
      keyId: key.id,
      algorithm: 'xor',
      encryptedBytes: encrypted,
      checksum: checksum,
      encryptedAt: DateTime.now(),
    );
  }

  /// Decrypt using XOR
  Uint8List _decryptXOR(EncryptedData encryptedData, EncryptionKey key) {
    final decrypted = Uint8List(encryptedData.encryptedBytes.length);
    final keyBytes = key.keyData;
    
    for (int i = 0; i < encryptedData.encryptedBytes.length; i++) {
      decrypted[i] = encryptedData.encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
    }

    // Verify checksum if available
    if (encryptedData.checksum != null) {
      final calculatedChecksum = _calculateChecksum(decrypted);
      if (calculatedChecksum != encryptedData.checksum) {
        throw EncryptionException('Data integrity check failed');
      }
    }

    return decrypted;
  }

  /// Encrypt using AES (placeholder - would use actual AES in production)
  EncryptedData _encryptAES(Uint8List plaintext, EncryptionKey key) {
    // In production, use actual AES encryption library
    // For demo, we'll use XOR with additional IV
    final iv = _generateRandomBytes(16); // AES block size
    final encrypted = Uint8List(plaintext.length);
    final keyBytes = key.keyData;
    
    // Simulate AES with XOR + IV
    for (int i = 0; i < plaintext.length; i++) {
      encrypted[i] = plaintext[i] ^ keyBytes[i % keyBytes.length] ^ iv[i % iv.length];
    }

    final checksum = _calculateChecksum(plaintext);

    return EncryptedData(
      keyId: key.id,
      algorithm: 'aes256',
      encryptedBytes: encrypted,
      iv: iv,
      checksum: checksum,
      encryptedAt: DateTime.now(),
    );
  }

  /// Decrypt using AES (placeholder)
  Uint8List _decryptAES(EncryptedData encryptedData, EncryptionKey key) {
    if (encryptedData.iv == null) {
      throw EncryptionException('IV required for AES decryption');
    }

    final decrypted = Uint8List(encryptedData.encryptedBytes.length);
    final keyBytes = key.keyData;
    final iv = encryptedData.iv!;
    
    // Simulate AES with XOR + IV
    for (int i = 0; i < encryptedData.encryptedBytes.length; i++) {
      decrypted[i] = encryptedData.encryptedBytes[i] ^ keyBytes[i % keyBytes.length] ^ iv[i % iv.length];
    }

    // Verify checksum
    if (encryptedData.checksum != null) {
      final calculatedChecksum = _calculateChecksum(decrypted);
      if (calculatedChecksum != encryptedData.checksum) {
        throw EncryptionException('Data integrity check failed');
      }
    }

    return decrypted;
  }

  /// Calculate simple checksum for integrity
  String _calculateChecksum(Uint8List data) {
    int sum = 0;
    for (int byte in data) {
      sum += byte;
    }
    return sum.toString();
  }

  /// Encrypt map/object data
  Future<Map<String, dynamic>> encryptMap(Map<String, dynamic> data) async {
    final encryptedMap = <String, dynamic>{};
    
    for (final entry in data.entries) {
      if (_shouldEncryptField(entry.key) && entry.value is String) {
        final encrypted = await encryptString(entry.value as String);
        encryptedMap[entry.key] = {
          '_encrypted': true,
          '_data': encrypted.toJson(),
        };
      } else {
        encryptedMap[entry.key] = entry.value;
      }
    }
    
    return encryptedMap;
  }

  /// Decrypt map/object data
  Future<Map<String, dynamic>> decryptMap(Map<String, dynamic> data) async {
    final decryptedMap = <String, dynamic>{};
    
    for (final entry in data.entries) {
      if (entry.value is Map<String, dynamic> && 
          entry.value['_encrypted'] == true) {
        final encryptedData = EncryptedData.fromJson(entry.value['_data']);
        decryptedMap[entry.key] = await decryptString(encryptedData);
      } else {
        decryptedMap[entry.key] = entry.value;
      }
    }
    
    return decryptedMap;
  }

  /// Check if field should be encrypted
  bool _shouldEncryptField(String fieldName) {
    return _config.sensitiveFields.any((field) => 
      fieldName.toLowerCase().contains(field.toLowerCase())
    );
  }

  /// Rotate encryption key
  Future<void> rotateKey() async {
    final newKey = _generateKey();
    _keys[newKey.id] = newKey;
    _activeKey = newKey;
    
    // Mark old keys as inactive (keep for decryption)
    for (final key in _keys.values) {
      if (key.id != newKey.id) {
        final updatedKey = EncryptionKey(
          id: key.id,
          algorithm: key.algorithm,
          keyData: key.keyData,
          createdAt: key.createdAt,
          expiresAt: key.expiresAt,
          isActive: false,
          metadata: key.metadata,
        );
        _keys[key.id] = updatedKey;
      }
    }
    
    notifyListeners();
  }

  /// Update encryption configuration
  void updateConfig(EncryptionConfig config) {
    _config = config;
    notifyListeners();
  }

  /// Get encryption statistics
  Map<String, dynamic> getEncryptionStatistics() {
    final activeKeys = _keys.values.where((k) => k.isActive).length;
    final expiredKeys = _keys.values.where((k) => k.isExpired).length;
    final totalKeys = _keys.length;
    
    return {
      'total_keys': totalKeys,
      'active_keys': activeKeys,
      'expired_keys': expiredKeys,
      'current_algorithm': _config.defaultAlgorithm.name,
      'key_rotation_days': _config.keyRotationDays,
      'pii_encryption_enabled': _config.encryptPII,
      'feedback_encryption_enabled': _config.encryptFeedback,
      'export_encryption_enabled': _config.encryptExports,
      'backup_encryption_enabled': _config.encryptBackups,
      'active_key_id': _activeKey?.id,
      'active_key_expires': _activeKey?.expiresAt.toIso8601String(),
    };
  }

  /// Clean up expired keys (admin function)
  int cleanupExpiredKeys() {
    final expiredKeys = _keys.values
        .where((k) => k.isExpired && !k.isActive)
        .toList();
    
    for (final key in expiredKeys) {
      _keys.remove(key.id);
    }
    
    if (expiredKeys.isNotEmpty) {
      notifyListeners();
    }
    
    return expiredKeys.length;
  }

  /// Export key for backup (admin only)
  Map<String, dynamic> exportKey(String keyId) {
    final key = _keys[keyId];
    if (key == null) {
      throw EncryptionException('Key not found: $keyId');
    }
    
    return {
      'id': key.id,
      'algorithm': key.algorithm,
      'keyData': base64.encode(key.keyData),
      'createdAt': key.createdAt.toIso8601String(),
      'expiresAt': key.expiresAt.toIso8601String(),
      'isActive': key.isActive,
      'metadata': key.metadata,
    };
  }

  /// Import key from backup (admin only)
  void importKey(Map<String, dynamic> keyData) {
    final key = EncryptionKey(
      id: keyData['id'],
      algorithm: keyData['algorithm'],
      keyData: base64.decode(keyData['keyData']),
      createdAt: DateTime.parse(keyData['createdAt']),
      expiresAt: DateTime.parse(keyData['expiresAt']),
      isActive: keyData['isActive'] ?? false,
      metadata: keyData['metadata'] ?? {},
    );
    
    _keys[key.id] = key;
    notifyListeners();
  }

  /// Test encryption/decryption with sample data
  Future<Map<String, dynamic>> testEncryption() async {
    final testData = 'This is sensitive NPS feedback data that should be encrypted.';
    final startTime = DateTime.now();
    
    try {
      // Encrypt
      final encrypted = await encryptString(testData);
      final encryptTime = DateTime.now().difference(startTime).inMicroseconds;
      
      // Decrypt
      final decryptStart = DateTime.now();
      final decrypted = await decryptString(encrypted);
      final decryptTime = DateTime.now().difference(decryptStart).inMicroseconds;
      
      final success = decrypted == testData;
      
      return {
        'success': success,
        'original_length': testData.length,
        'encrypted_length': encrypted.encryptedBytes.length,
        'encrypt_time_microseconds': encryptTime,
        'decrypt_time_microseconds': decryptTime,
        'algorithm': encrypted.algorithm,
        'key_id': encrypted.keyId,
        'test_timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'test_timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}

/// Encryption exception for encryption/decryption errors
class EncryptionException implements Exception {
  final String message;
  const EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}