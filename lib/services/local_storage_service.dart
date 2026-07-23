/// 本地凭据存储服务
///
/// 管理登录页的"保存登录邮箱"和"保存登录密码"功能。
/// - 邮箱：明文存储于 SharedPreferences（非敏感信息）
/// - 密码：加密存储于 flutter_secure_storage（Android Keystore）
///
/// 设计文档参考：docs/design/page-design/01-登录页.md §3.5
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 本地凭据存储服务
///
/// 管理登录页的"保存登录邮箱"和"保存登录密码"功能。
/// - 邮箱：明文存储于 SharedPreferences（非敏感信息）
/// - 密码：加密存储于 flutter_secure_storage（Android Keystore）
///
/// 设计文档参考：docs/design/page-design/01-登录页.md §3.5
class LocalStorageService {
  static const _keySavedEmail = 'saved_login_email';
  static const _keySavedPassword = 'saved_login_password';
  static const _keySaveEmailChecked = 'saved_login_save_email_checked';
  static const _keySavePasswordChecked = 'saved_login_save_password_checked';

  final FlutterSecureStorage _secureStorage;

  LocalStorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // ── 邮箱 ──

  /// 保存登录邮箱（明文 SharedPreferences）
  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySavedEmail, email);
  }

  /// 读取已保存的邮箱
  Future<String?> loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySavedEmail);
  }

  /// 清除已保存的邮箱
  Future<void> clearEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySavedEmail);
  }

  // ── 密码 ──

  /// 保存登录密码（加密 flutter_secure_storage）
  Future<void> savePassword(String password) async {
    await _secureStorage.write(key: _keySavedPassword, value: password);
  }

  /// 读取已保存的密码
  Future<String?> loadPassword() async {
    return _secureStorage.read(key: _keySavedPassword);
  }

  /// 清除已保存的密码
  Future<void> clearPassword() async {
    await _secureStorage.delete(key: _keySavedPassword);
  }

  // ── 复选框状态 ──

  /// 保存「保存登录邮箱」复选框状态
  Future<void> saveSaveEmailChecked(bool checked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySaveEmailChecked, checked);
  }

  /// 读取「保存登录邮箱」复选框状态（默认 true）
  Future<bool> loadSaveEmailChecked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySaveEmailChecked) ?? true;
  }

  /// 保存「保存登录密码」复选框状态
  Future<void> saveSavePasswordChecked(bool checked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySavePasswordChecked, checked);
  }

  /// 读取「保存登录密码」复选框状态（默认 false）
  Future<bool> loadSavePasswordChecked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySavePasswordChecked) ?? false;
  }
}
