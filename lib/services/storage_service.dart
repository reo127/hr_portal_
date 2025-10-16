import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  // Storage keys
  static const String _keyToken = 'jwt_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';
  static const String _keyTokenExpiry = 'token_expiry';
  static const String _keyLoginTime = 'login_time';

  // Save token and user data
  Future<void> saveAuthData({
    required String token,
    required String userId,
    required String username,
    required int tokenExpiry,
    required String loginTime,
  }) async {
    await Future.wait([
      _storage.write(key: _keyToken, value: token),
      _storage.write(key: _keyUserId, value: userId),
      _storage.write(key: _keyUsername, value: username),
      _storage.write(key: _keyTokenExpiry, value: tokenExpiry.toString()),
      _storage.write(key: _keyLoginTime, value: loginTime),
    ]);
  }

  // Get token
  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  // Get user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  // Get username
  Future<String?> getUsername() async {
    return await _storage.read(key: _keyUsername);
  }

  // Get token expiry
  Future<int?> getTokenExpiry() async {
    final expiry = await _storage.read(key: _keyTokenExpiry);
    return expiry != null ? int.tryParse(expiry) : null;
  }

  // Get login time
  Future<String?> getLoginTime() async {
    return await _storage.read(key: _keyLoginTime);
  }

  // Check if token is valid (not expired)
  Future<bool> isTokenValid() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return false;

    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return currentTime < expiry;
  }

  // Check if user is logged in
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Clear all auth data
  Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: _keyToken),
      _storage.delete(key: _keyUserId),
      _storage.delete(key: _keyUsername),
      _storage.delete(key: _keyTokenExpiry),
      _storage.delete(key: _keyLoginTime),
    ]);
  }

  // Clear all storage (nuclear option)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
