import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token 安全存储服务
///
/// 使用 flutter_secure_storage（底层 Android Keystore）加密存储
/// accessToken（15 分钟有效期）和 refreshToken（7 天有效期）。
class TokenStorage {
  final FlutterSecureStorage _storage;

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';
  static const _keyUserEmail = 'user_email';
  static const _keyUserRole = 'user_role';

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ── Token 存取 ──

  /// 保存登录凭据（Token + 用户信息）
  Future<void> saveAuth({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String userName,
    required String userEmail,
    required String userRole,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
      _storage.write(key: _keyUserId, value: userId),
      _storage.write(key: _keyUserName, value: userName),
      _storage.write(key: _keyUserEmail, value: userEmail),
      _storage.write(key: _keyUserRole, value: userRole),
    ]);
  }

  /// 更新 Token（刷新后换发）
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: _keyAccessToken);

  Future<String?> getRefreshToken() =>
      _storage.read(key: _keyRefreshToken);

  Future<String?> getUserId() => _storage.read(key: _keyUserId);

  Future<String?> getUserName() => _storage.read(key: _keyUserName);

  Future<String?> getUserEmail() => _storage.read(key: _keyUserEmail);

  Future<String?> getUserRole() => _storage.read(key: _keyUserRole);

  /// 清除所有登录凭据（登出时调用）
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
