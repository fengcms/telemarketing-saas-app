/// 通话记录接口服务
///
/// 面向「个人通话记录列表」场景：按手机号模糊搜索（q）+ 接听类型筛选，
/// 服务端按 Token 自动限定当前用户可见范围。
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/services/api_client.dart';
import 'package:telemarketing_app/services/api_constants.dart';
import 'package:telemarketing_app/models/call_record.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';

/// 通话记录接口服务
class CallService {
  final ApiClient _apiClient;
  final Ref? _ref;

  CallService({required this._apiClient, this._ref});

  // ── 首屏列表缓存（随 App 存活，避免每次进入都请求）──
  /// 缓存 TTL：5 分钟
  static const int callListCacheTtl = 300;

  ({List<CallRecord> items, int total, int pages})? _cache;
  String? _cacheKey;
  DateTime? _cacheTime;

  String _buildKey(String? q, String? answerType) {
    final uid = _ref?.read(authProvider).user?.id ?? '';
    return '$uid|${q ?? ''}|${answerType ?? ''}';
  }

  /// 跨账号隔离：清空通话列表缓存（见 [CacheCoordinator]）
  void clear() {
    _cache = null;
    _cacheKey = null;
    _cacheTime = null;
  }

  bool _isCacheValid(String key) =>
      _cache != null &&
      _cacheKey == key &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!).inSeconds < callListCacheTtl;

  /// 供列表页在发请求前同步判断缓存是否有效（命中则直接套用、无骨架）
  ({List<CallRecord> items, int total, int pages})? peekCache(
    String? q,
    String? answerType,
  ) =>
      _isCacheValid(_buildKey(q, answerType)) ? _cache : null;

  // ── 我的通话记录列表 ──

  /// 获取当前用户的通话记录列表（分页 + 筛选）
  ///
  /// [q] 手机号片段模糊搜索（接口跨字段 LIKE %q%，空白不传），
  /// 见 api.md §通话记录 / GET /api/tenant/calls。
  /// [answerType] 接听类型筛选，传 null/空表示「全部」。
  /// [page] 页码（从1起），[size] 每页条数（默认20）。
  /// [force] 强制绕过缓存（如下拉刷新），直接拉最新并刷新缓存时间戳。
  /// 返回 (items, total, pages)，便于列表页判断「是否还有下一页」。
  ///
  /// 首屏（page==1）结果按 (q, answerType) 缓存 5 分钟；
  /// 命中有效缓存时直接返回，不发网络请求。翻页（page>=2）始终走网络。
  Future<({List<CallRecord> items, int total, int pages})> fetchMyCalls({
    String? q,
    String? answerType,
    int page = 1,
    int size = 20,
    bool force = false,
  }) async {
    // 首屏命中有效缓存（非强制）→ 直接返回，不发请求
    if (page == 1 && !force) {
      final hit = peekCache(q, answerType);
      if (hit != null) return hit;
    }
    try {
      final params = <String, dynamic>{
        'sort': '-startedAt',
        'page': page,
        'size': size,
      };
      // 仅当搜索词非空时才传 q，避免触发后端 INVALID_PARAMS(400)
      if (q != null && q.isNotEmpty) {
        params['q'] = q;
      }
      // 设计 §4.4：点击「全部」不传 answerType
      if (answerType != null && answerType.isNotEmpty) {
        params['answerType'] = answerType;
      }
      final response = await _apiClient.dio.get(
        ApiConstants.calls,
        queryParameters: params,
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final body = data['data'] as Map? ?? {};
        final List<CallRecord> items = (body['items'] as List<dynamic>?)
                ?.map(
                    (e) => CallRecord.fromJson(e as Map<String, dynamic>))
                .toList() ??
            <CallRecord>[];
        final result = (
          items: items,
          total: _toInt(body['total']) ?? 0,
          pages: _toInt(body['pages']) ?? 1,
        );
        // 仅首屏结果写入缓存（翻页数据无需缓存）
        if (page == 1) {
          _cache = result;
          _cacheKey = _buildKey(q, answerType);
          _cacheTime = DateTime.now();
        }
        return result;
      }
      return (items: <CallRecord>[], total: 0, pages: 1);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
