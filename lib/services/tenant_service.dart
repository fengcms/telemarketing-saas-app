/// 租户信息服务（带 10h 缓存 + SharedPreferences 持久化）
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telemarketing_app/services/api_client.dart';
import 'package:telemarketing_app/services/api_constants.dart';

/// 租户信息服务（带 10h 缓存 + SharedPreferences 持久化）
///
/// 缓存租户配置（settings）和租户名称，10h 内打开 APP 不再请求。
/// 个人中心「更新公司数据」按钮可调用 [refresh] 手动刷新。
class TenantService {
  final ApiClient _apiClient;

  TenantService({required this._apiClient});

  Map<String, dynamic>? _cachedSettings;
  String? _cachedName;
  String? _cachedTenantId;
  DateTime? _lastFetchTime;
  bool _localLoaded = false;

  static const _keySettings = 'cache_tenant_settings';
  static const _keyName = 'cache_tenant_name';
  static const _keyTenantId = 'cache_tenant_id';
  static const _keyTime = 'cache_tenant_time';

  bool get _isValid =>
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!).inSeconds <
          ApiConstants.optionsCacheTTL;

  Future<void> _ensureLoaded() async {
    if (!_localLoaded) {
      await _loadFromLocal();
      _localLoaded = true;
    }
    if (!_isValid) {
      await _refreshFromApi();
    }
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString(_keyTime);
      if (timeStr != null) {
        _lastFetchTime = DateTime.tryParse(timeStr);
      }
      final settingsStr = prefs.getString(_keySettings);
      if (settingsStr != null) {
        _cachedSettings = jsonDecode(settingsStr) as Map<String, dynamic>;
      }
      _cachedName = prefs.getString(_keyName);
      _cachedTenantId = prefs.getString(_keyTenantId);
    } catch (_) {}
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastFetchTime != null) {
        await prefs.setString(_keyTime, _lastFetchTime!.toIso8601String());
      }
      if (_cachedSettings != null) {
        await prefs.setString(_keySettings, jsonEncode(_cachedSettings));
      }
      if (_cachedName != null) {
        await prefs.setString(_keyName, _cachedName!);
      }
      if (_cachedTenantId != null) {
        await prefs.setString(_keyTenantId, _cachedTenantId!);
      }
    } catch (_) {}
  }

  Future<void> _refreshFromApi() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.profile);
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final profile = data['data'] as Map<String, dynamic>? ?? {};
        _cachedSettings =
            profile['settings'] as Map<String, dynamic>? ?? {};
        _cachedName = profile['name']?.toString() ?? '';
        _cachedTenantId = profile['id']?.toString();
        _lastFetchTime = DateTime.now();
        await _saveToLocal();
      }
    } catch (_) {
      // 静默失败，保留旧缓存
    }
  }

  /// 获取租户配置（含 noCallWindow/allowSelfClaim）
  ///
  /// 优先返回缓存数据，缓存失效时从 API 拉取。
  Future<Map<String, dynamic>> fetchProfile() async {
    await _ensureLoaded();
    return Map<String, dynamic>.from(_cachedSettings ?? {});
  }

  /// 获取租户名称（个人中心"所属租户"展示用）
  Future<String> fetchTenantName() async {
    await _ensureLoaded();
    return _cachedName ?? '';
  }

  /// 当前租户 ID（profile.data.id）
  ///
  /// 供跨账号缓存隔离判定使用（见 [CacheCoordinator] / [AuthNotifier.login]）。
  /// 注意：在 [fetchTenantId] 刷新前读取，即为「上一次登录的租户」。
  String? get cachedTenantId => _cachedTenantId;

  /// 确保已加载后返回当前租户 ID
  ///
  /// [force] 为 true 时忽略本地 TTL 缓存，强制重新拉取 profile。
  /// 用于登录路径：必须拿到「本次登录」的真实租户 ID，
  /// 否则跨租户但本地缓存未过期时会误判为同租户，导致 options 泄漏。
  Future<String?> fetchTenantId({bool force = false}) async {
    if (force) _lastFetchTime = null;
    await _ensureLoaded();
    return _cachedTenantId;
  }

  /// 清空租户共享缓存（内存 + 磁盘）
  ///
  /// 跨租户切换时由 [CacheCoordinator._clearTenantShared] 调用。
  /// 仅删自身 `cache_tenant_*` key，不触碰 [TokenStorage] 的登录凭据 key。
  Future<void> clearAll() async {
    _cachedSettings = null;
    _cachedName = null;
    _cachedTenantId = null;
    _lastFetchTime = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySettings);
      await prefs.remove(_keyName);
      await prefs.remove(_keyTenantId);
      await prefs.remove(_keyTime);
    } catch (_) {}
  }

  /// 手动刷新缓存（清空并重新请求）
  Future<void> refresh() async {
    _lastFetchTime = null;
    _cachedSettings = null;
    _cachedName = null;
    await _refreshFromApi();
  }
}
