/// Token 安全存储服务
///
/// - 原生（Android/iOS）：[flutter_secure_storage]（底层 Keystore/Keychain）加密存储；
/// - Web：flutter_secure_storage 依赖 `crypto.subtle`，在不安全上下文（HTTP 非 localhost
///   源）下会抛异常，故 Web 改用 [shared_preferences]（localStorage，无 crypto 依赖）。
///
/// 通过 [kIsWeb] 分支选择后端，对外接口保持一致（均为 async）。
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Token 安全存储服务
class TokenStorage {
  /// 原生后端（仅非 Web 使用）
  final FlutterSecureStorage? _secureStorage;

  /// Web 后端缓存（懒加载）
  SharedPreferences? _prefs;

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';
  static const _keyUserEmail = 'user_email';
  static const _keyUserRole = 'user_role';

  TokenStorage({FlutterSecureStorage? storage})
      : _secureStorage = kIsWeb ? null : (storage ?? const FlutterSecureStorage());

  /// Web 下懒加载并缓存 [SharedPreferences] 实例
  Future<SharedPreferences> get _webPrefs async =>
      _prefs ??= await SharedPreferences.getInstance();

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
    if (kIsWeb) {
      final p = await _webPrefs;
      await Future.wait([
        p.setString(_keyAccessToken, accessToken),
        p.setString(_keyRefreshToken, refreshToken),
        p.setString(_keyUserId, userId),
        p.setString(_keyUserName, userName),
        p.setString(_keyUserEmail, userEmail),
        p.setString(_keyUserRole, userRole),
      ]);
      return;
    }
    await Future.wait([
      _secureStorage!.write(key: _keyAccessToken, value: accessToken),
      _secureStorage!.write(key: _keyRefreshToken, value: refreshToken),
      _secureStorage!.write(key: _keyUserId, value: userId),
      _secureStorage!.write(key: _keyUserName, value: userName),
      _secureStorage!.write(key: _keyUserEmail, value: userEmail),
      _secureStorage!.write(key: _keyUserRole, value: userRole),
    ]);
  }

  /// 更新 Token（刷新后换发）
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb) {
      final p = await _webPrefs;
      await Future.wait([
        p.setString(_keyAccessToken, accessToken),
        p.setString(_keyRefreshToken, refreshToken),
      ]);
      return;
    }
    await Future.wait([
      _secureStorage!.write(key: _keyAccessToken, value: accessToken),
      _secureStorage!.write(key: _keyRefreshToken, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) return (await _webPrefs).getString(_keyAccessToken);
    return _secureStorage!.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) return (await _webPrefs).getString(_keyRefreshToken);
    return _secureStorage!.read(key: _keyRefreshToken);
  }

  Future<String?> getUserId() async {
    if (kIsWeb) return (await _webPrefs).getString(_keyUserId);
    return _secureStorage!.read(key: _keyUserId);
  }

  Future<String?> getUserName() async {
    if (kIsWeb) return (await _webPrefs).getString(_keyUserName);
    return _secureStorage!.read(key: _keyUserName);
  }

  Future<String?> getUserEmail() async {
    if (kIsWeb) return (await _webPrefs).getString(_keyUserEmail);
    return _secureStorage!.read(key: _keyUserEmail);
  }

  Future<String?> getUserRole() async {
    if (kIsWeb) return (await _webPrefs).getString(_keyUserRole);
    return _secureStorage!.read(key: _keyUserRole);
  }

  /// 清除所有登录凭据（登出时调用）
  ///
  /// 注意：只删除 Token/用户信息相关的 key，
  /// 避免误伤 LocalStorageService 保存的密码等数据。
  Future<void> clearAll() async {
    if (kIsWeb) {
      final p = await _webPrefs;
      await Future.wait([
        p.remove(_keyAccessToken),
        p.remove(_keyRefreshToken),
        p.remove(_keyUserId),
        p.remove(_keyUserName),
        p.remove(_keyUserEmail),
        p.remove(_keyUserRole),
      ]);
      return;
    }
    await Future.wait([
      _secureStorage!.delete(key: _keyAccessToken),
      _secureStorage!.delete(key: _keyRefreshToken),
      _secureStorage!.delete(key: _keyUserId),
      _secureStorage!.delete(key: _keyUserName),
      _secureStorage!.delete(key: _keyUserEmail),
      _secureStorage!.delete(key: _keyUserRole),
    ]);
  }
}
