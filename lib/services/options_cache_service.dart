/// 下拉选项缓存服务
///
/// 缓存分类/项目等下拉选项数据，避免重复请求。
/// 内存缓存 TTL 在 [ApiConstants.optionsCacheTTL] 中配置（默认 36000 秒/10 小时）。
/// 同时持久化到 SharedPreferences，重开 APP 后先加载本地缓存再后台刷新。
library;

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telemarketing_app/services/api_client.dart';
import 'package:telemarketing_app/services/api_constants.dart';
import 'package:telemarketing_app/models/option_item.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';

/// 下拉选项缓存服务
///
/// 缓存分类/项目等下拉选项数据，避免重复请求。
/// 内存缓存 TTL 在 [ApiConstants.optionsCacheTTL] 中配置（默认 36000 秒/10 小时）。
/// 同时持久化到 SharedPreferences，重开 APP 后先加载本地缓存再后台刷新。
class OptionsCacheService {
  final ApiClient _apiClient;

  List<OptionItem> _categories = [];
  List<OptionItem> _projects = [];
  List<OptionItem> _users = [];
  List<OptionItem> _quickNotes = [];
  DateTime? _lastFetchTime;
  bool _localLoaded = false;
  /// 是否已确保租户 ID 从磁盘加载（见 [_ensureLoaded] 时序修复）
  bool _tenantIdEnsured = false;
  /// 进行中的刷新 Future（并发调用共享同一实例，避免重复请求）
  Future<void>? _loadingFuture;
  final Ref? _ref;

  /// 旧全局 key（仅用于跨租户 [clearAll] 迁移清理）
  static const _keyCategories = 'cache_options_categories';
  static const _keyProjects = 'cache_options_projects';
  static const _keyUsers = 'cache_options_users';
  static const _keyQuickNotes = 'cache_options_quick_notes';
  static const _keyTime = 'cache_options_time';

  /// 当前租户 ID 前缀（跨账号隔离；见 cache_coordinator.dart）
  String get _tid => _ref?.read(tenantServiceProvider).cachedTenantId ?? '';
  String get _kCategories => 'cache_options_${_tid}_categories';
  String get _kProjects => 'cache_options_${_tid}_projects';
  String get _kUsers => 'cache_options_${_tid}_users';
  String get _kQuickNotes => 'cache_options_${_tid}_quick_notes';
  String get _kTime => 'cache_options_${_tid}_time';

  OptionsCacheService({required this._apiClient, this._ref});

  /// 缓存是否有效（未过期）
  bool get _isValid =>
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!).inSeconds <
          ApiConstants.optionsCacheTTL;

  /// 确保缓存有效
  ///
  /// 必须等待刷新完成：此前用 fire-and-forget 方式调用 [_refreshFromApi]，
  /// 导致后续 [getUserName] 等查找在 [_users] 仍为空时执行，
  /// 回退成原始 id 并被 FutureProvider 永久缓存（表现即「归属」显示 id）。
  /// 改为 await 同一刷新 Future（并发调用共享，仅发起一次请求）。
  Future<void> _ensureLoaded() async {
    // 关键修复：先确保租户 ID 已从磁盘加载。
    // 否则首屏（线索卡片等）在 TenantService 尚未 _loadFromLocal 时，
    // options 会用空前缀（_tid=''）读磁盘缓存，拿到空数据；
    // 而 TTL 内又不会回退 API 刷新，表现即「分类/项目显示成 ID」。
    // fetchTenantId() 内部先 _loadFromLocal（不依赖网络），仅租户缓存
    // 过期时才会请求 profile；冷启动常见场景仅一次磁盘读取。
    if (!_tenantIdEnsured) {
      try {
        await _ref?.read(tenantServiceProvider).fetchTenantId();
      } catch (_) {
        // 忽略：tenant 拉取失败不影响后续逻辑
      }
      _tenantIdEnsured = true;
    }

    // 先尝试从本地加载
    if (!_localLoaded) {
      await _loadFromLocal();
      _localLoaded = true;
    }

    // 内存缓存过期：等待刷新完成，避免首查落空
    if (!_isValid) {
      _loadingFuture ??= _refreshFromApi().whenComplete(() {
        _loadingFuture = null;
      });
      await _loadingFuture;
    }
  }

  /// 从本地 SharedPreferences 加载
  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString(_keyTime);
      if (timeStr != null) {
        _lastFetchTime = DateTime.tryParse(timeStr);
      }
      final cats = prefs.getString(_kCategories);
      final projs = prefs.getString(_kProjects);
      final users = prefs.getString(_kUsers);
      final notes = prefs.getString(_kQuickNotes);
      if (cats != null) _categories = _decodeList(cats);
      if (projs != null) _projects = _decodeList(projs);
      if (users != null) _users = _decodeList(users);
      if (notes != null) _quickNotes = _decodeList(notes);
    } catch (_) {}
  }

  /// 保存到本地 SharedPreferences
  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastFetchTime != null) {
        await prefs.setString(_keyTime, _lastFetchTime!.toIso8601String());
      }
      await prefs.setString(_kCategories, _encodeList(_categories));
      await prefs.setString(_kProjects, _encodeList(_projects));
      await prefs.setString(_kUsers, _encodeList(_users));
      await prefs.setString(_kQuickNotes, _encodeList(_quickNotes));
    } catch (_) {}
  }

  String _encodeList(List<OptionItem> items) {
    return jsonEncode(items.map((e) {
      final map = <String, dynamic>{'id': e.id, 'name': e.name};
      if (e.type != null) map['type'] = e.type;
      if (e.role != null) map['role'] = e.role;
      return map;
    }).toList());
  }

  List<OptionItem> _decodeList(String json) {
    final list = jsonDecode(json) as List;
    return list
        .map((e) => OptionItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 从 API 刷新缓存
  Future<void> _refreshFromApi() async {
    try {
      final results = await Future.wait([
        _fetchCategories(),
        _fetchProjects(),
        _fetchUsers(),
        _fetchQuickNotes(),
      ]);
      _categories = results[0];
      _projects = results[1];
      _users = results[2];
      _quickNotes = results[3];
      _lastFetchTime = DateTime.now();
      await _saveToLocal();
    } catch (_) {
      // 静默失败，保留旧缓存
    } finally {
    }
  }

  Future<List<OptionItem>> _fetchCategories() async {
    final response = await _apiClient.dio.get(ApiConstants.optionsCategories);
    return _parseOptions(response.data);
  }

  Future<List<OptionItem>> _fetchProjects() async {
    final response = await _apiClient.dio.get(ApiConstants.optionsProjects);
    return _parseOptions(response.data);
  }

  Future<List<OptionItem>> _fetchUsers() async {
    final response = await _apiClient.dio.get(ApiConstants.optionsUsers);
    return _parseOptions(response.data);
  }

  Future<List<OptionItem>> _fetchQuickNotes() async {
    final response =
        await _apiClient.dio.get(ApiConstants.optionsQuickNotes);
    return _parseOptions(response.data);
  }

  List<OptionItem> _parseOptions(dynamic data) {
    if (data is Map && data['success'] == true) {
      final items = data['data'] as List<dynamic>? ?? [];
      return items
          .map((e) => OptionItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── 公开查找方法 ──

  Future<String?> getCategoryName(String? id) async {
    if (id == null || id.isEmpty) return null;
    await _ensureLoaded();
    final found = _categories.where((c) => c.id == id);
    return found.isNotEmpty ? found.first.name : id;
  }

  Future<String?> getProjectName(String? id) async {
    if (id == null || id.isEmpty) return null;
    await _ensureLoaded();
    final found = _projects.where((p) => p.id == id);
    return found.isNotEmpty ? found.first.name : id;
  }

  Future<String?> getUserName(String? id) async {
    if (id == null || id.isEmpty) return null;
    await _ensureLoaded();
    final found = _users.where((u) => u.id == id);
    return found.isNotEmpty ? found.first.name : id;
  }

  // ── 批量访问 ──

  Future<List<OptionItem>> getCategories() async {
    await _ensureLoaded();
    return List.unmodifiable(_categories);
  }

  Future<List<OptionItem>> getProjects() async {
    await _ensureLoaded();
    return List.unmodifiable(_projects);
  }

  /// 获取快捷备注列表
  Future<List<OptionItem>> getQuickNotes() async {
    await _ensureLoaded();
    return List.unmodifiable(_quickNotes);
  }

  /// 获取用户下拉列表（归属人选择器用，TM/TA 可见）
  Future<List<OptionItem>> getUsers() async {
    await _ensureLoaded();
    return List.unmodifiable(_users);
  }

  Future<void> refresh() async {
    _lastFetchTime = null;
    await _refreshFromApi();
  }

  /// 跨租户隔离：清空选项缓存（内存 + 磁盘）
  ///
  /// 移除新（租户前缀）与旧（全局）两种 key，兼容历史缓存。
  /// 由 [CacheCoordinator._clearTenantShared] 在跨租户切换时调用。
  Future<void> clearAll() async {
    _categories = [];
    _projects = [];
    _users = [];
    _quickNotes = [];
    _lastFetchTime = null;
    _tenantIdEnsured = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      // 新（租户前缀）key
      await prefs.remove(_kCategories);
      await prefs.remove(_kProjects);
      await prefs.remove(_kUsers);
      await prefs.remove(_kQuickNotes);
      await prefs.remove(_kTime);
      // 旧（全局）key，迁移清理
      await prefs.remove(_keyCategories);
      await prefs.remove(_keyProjects);
      await prefs.remove(_keyUsers);
      await prefs.remove(_keyQuickNotes);
      await prefs.remove(_keyTime);
    } catch (_) {}
  }
}
