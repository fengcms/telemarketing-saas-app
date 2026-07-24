/// 日程数据服务
///
/// 封装日程列表与统计接口：
/// 1. [fetchSchedules] - GET /api/tenant/schedules
/// 2. [fetchMyScheduleStats] - GET /api/tenant/schedules/stats/mine
library;

import 'package:dio/dio.dart';
import 'package:telemarketing_app/services/api_client.dart';
import 'package:telemarketing_app/services/api_constants.dart';
import 'package:telemarketing_app/services/api_exception.dart';
import 'package:telemarketing_app/services/home_service.dart';
import 'package:telemarketing_app/models/schedule.dart';
import 'package:telemarketing_app/models/schedule_stats.dart';

/// 日程列表查询结果
class ScheduleListResult {
  /// 当前页日程列表
  final List<Schedule> items;

  /// 总数
  final int total;

  /// 服务端时间（Unix 秒，从响应头解析），用于逾期判定
  final int serverTime;

  const ScheduleListResult({
    required this.items,
    required this.total,
    required this.serverTime,
  });
}

/// 日程数据服务
class ScheduleService {
  final ApiClient _apiClient;

  ScheduleService({required this._apiClient});

  /// 获取日程列表
  ///
  /// [status] pending/completed/cancelled（默认 pending）
  /// [userId] 不传（null）时 TM/TA 取团队，TE 强制自己
  /// [page]/[size] 分页；[sort] 默认 scheduledAt。
  /// 注意：本端点后端仅支持 [sort] 字段，方向由后端固定为升序
  /// （按 scheduledAt 由近到远），不接受 `order`/`sortDir` 等方向参数，
  /// 传了会触发 400 INVALID_FILTER_FIELD 导致整请求失败。
  Future<ScheduleListResult> fetchSchedules({
    String status = 'pending',
    String? userId,
    int page = 1,
    int size = 20,
    String sort = 'scheduledAt',
  }) async {
    try {
      final query = <String, dynamic>{
        'status': status,
        'page': page,
        'size': size,
        'sort': sort,
      };
      if (userId != null && userId.isNotEmpty) {
        query['userId'] = userId;
      }
      final response = await _apiClient.dio.get(
        ApiConstants.schedules,
        queryParameters: query,
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final body = data['data'] as Map? ?? {};
        final List<Schedule> items = (body['items'] as List<dynamic>?)
                ?.map((e) => Schedule.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        final total = _toInt(body['total']);
        // 复用首页的响应头时间解析，免一次额外请求
        final serverTime = HomeService.getServerTime(response);
        return ScheduleListResult(
          items: items,
          total: total,
          serverTime: serverTime,
        );
      }
      throw const ApiException(
        statusCode: 200,
        code: 'UNKNOWN',
        message: '获取日程失败',
      );
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// 获取我的日程统计（byStatus + overdue + dueToday）
  Future<ScheduleStats> fetchMyScheduleStats() async {
    try {
      final response =
          await _apiClient.dio.get(ApiConstants.schedulesStatsMine);
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return ScheduleStats.fromJson(data as Map<String, dynamic>);
      }
      return const ScheduleStats();
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
