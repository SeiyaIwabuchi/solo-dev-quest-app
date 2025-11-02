import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// T074-T077: Secure storage service for persisting authentication tokens
/// 
/// Wraps FlutterSecureStorage to provide a simple API for storing
/// Firebase Auth tokens in OS-level secure storage:
/// - iOS: Keychain (kSecClassGenericPassword)
/// - Android: EncryptedSharedPreferences (KeyStore)
/// 
/// Tokens are automatically deleted when:
/// - User explicitly signs out
/// - App is uninstalled
class SecureStorageService {
  /// FlutterSecureStorage instance
  final FlutterSecureStorage _storage;

  /// Storage keys
  static const String _firebaseTokenKey = 'firebase_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';

  /// Creates an instance of [SecureStorageService]
  /// 
  /// By default, uses the default FlutterSecureStorage instance.
  /// Custom instance can be provided for testing purposes.
  SecureStorageService({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  /// T075: Saves authentication tokens to secure storage
  /// 
  /// Stores Firebase ID token, refresh token, and expiry timestamp.
  /// All values are stored as encrypted strings in OS secure storage.
  /// 
  /// Parameters:
  /// - [firebaseToken]: Firebase ID token (JWT format)
  /// - [refreshToken]: Firebase refresh token
  /// - [tokenExpiry]: Token expiration timestamp (ISO 8601 format)
  Future<void> saveToken({
    required String firebaseToken,
    required String refreshToken,
    required String tokenExpiry,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _firebaseTokenKey, value: firebaseToken),
        _storage.write(key: _refreshTokenKey, value: refreshToken),
        _storage.write(key: _tokenExpiryKey, value: tokenExpiry),
      ]);
    } catch (e) {
      throw Exception('Failed to save tokens: $e');
    }
  }

  /// T076: Retrieves authentication tokens from secure storage
  /// 
  /// Returns a map containing the stored tokens, or null if no tokens exist.
  /// 
  /// Returns:
  /// - Map with keys: 'firebaseToken', 'refreshToken', 'tokenExpiry'
  /// - null if any required token is missing
  Future<Map<String, String>?> getToken() async {
    try {
      final results = await Future.wait([
        _storage.read(key: _firebaseTokenKey),
        _storage.read(key: _refreshTokenKey),
        _storage.read(key: _tokenExpiryKey),
      ]);

      final firebaseToken = results[0];
      final refreshToken = results[1];
      final tokenExpiry = results[2];

      // Return null if any token is missing
      if (firebaseToken == null || refreshToken == null || tokenExpiry == null) {
        return null;
      }

      return {
        'firebaseToken': firebaseToken,
        'refreshToken': refreshToken,
        'tokenExpiry': tokenExpiry,
      };
    } catch (e) {
      throw Exception('Failed to retrieve tokens: $e');
    }
  }

  /// T077: Deletes all authentication tokens from secure storage
  /// 
  /// Called when user signs out or when session expires.
  /// Removes all stored authentication tokens from OS secure storage.
  Future<void> deleteToken() async {
    try {
      await Future.wait([
        _storage.delete(key: _firebaseTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _tokenExpiryKey),
      ]);
    } catch (e) {
      throw Exception('Failed to delete tokens: $e');
    }
  }

  /// Deletes all data from secure storage
  /// 
  /// Use with caution - this removes ALL stored data, not just auth tokens.
  /// Useful for testing or complete app reset.
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw Exception('Failed to delete all data: $e');
    }
  }
}
