/// 通话记录接口服务
///
/// 面向「个人通话记录列表」场景：按手机号模糊搜索（q）+ 接听类型筛选，
/// 服务端按 Token 自动限定当前用户可见范围。
library;

import 'package:dio/dio.dart';
import 'package:telemarketing_app/services/api_client.dart';
import 'package:telemarketing_app/services/api_constants.dart';
import 'package:telemarketing_app/models/call_record.dart';

/// 通话记录接口服务
class CallService {
  final ApiClient _apiClient;

  CallService({required this._apiClient});

  // ── 我的通话记录列表 ──

  /// 获取当前用户的通话记录列表（分页 + 筛选）
  ///
  /// [q] 手机号片段模糊搜索（接口跨字段 LIKE %q%，空白不传），
  /// 见 api.md §通话记录 / GET /api/tenant/calls。
  /// [answerType] 接听类型筛选，传 null/空表示「全部」。
  /// [page] 页码（从 1 起），[size] 每页条数（默认 20）。
  /// 返回 `(items, total, pages)`，便于列表页判断「是否还有下一页」。
  Future<({List<CallRecord> items, int total, int pages})> fetchMyCalls({
    String? q,
    String? answerType,
    int page = 1,
    int size = 20,
  }) async {
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
        return (
          items: items,
          total: _toInt(body['total']) ?? 0,
          pages: _toInt(body['pages']) ?? 1,
        );
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
