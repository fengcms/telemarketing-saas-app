/// 首页看板数据服务
///
/// 封装首页所需的 4 个接口调用：
/// 1. [fetchMyStats] - GET /api/tenant/stats/mine
/// 2. [fetchPendingSchedules] - GET /api/tenant/schedules?status=pending&page=1&size=5
/// 3. [fetchMyScheduleStats] - GET /api/tenant/schedules/stats/mine
/// 4. [fetchDueSoonCount] - GET /api/tenant/schedules?status=pending&scheduledAt__gte=...&page=1&size=1
library;

import 'package:dio/dio.dart';
import 'package:telemarketing_app/services/api_client.dart';
import 'package:telemarketing_app/services/api_constants.dart';
import 'package:telemarketing_app/services/api_exception.dart';
import 'package:telemarketing_app/models/home_stats.dart';
import 'package:telemarketing_app/models/schedule.dart';

/// 首页看板数据服务
///
/// 封装首页所需的 4 个接口调用：
/// 1. [fetchMyStats] - GET /api/tenant/stats/mine
/// 2. [fetchPendingSchedules] - GET /api/tenant/schedules?status=pending&page=1&size=5
/// 3. [fetchMyScheduleStats] - GET /api/tenant/schedules/stats/mine
/// 4. [fetchDueSoonCount] - GET /api/tenant/schedules?status=pending&scheduledAt__gte=...&page=1&size=1
class HomeService {
  final ApiClient _apiClient;

  HomeService({required this._apiClient});

  /// 获取今日个人统计数据
  ///
  /// 返回 [HomeStats]（含 followupCount、answeredCount、myLeadsTotal）。
  Future<HomeStats> fetchMyStats(String dateStr) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.statsMine,
        queryParameters: {
          'dateFrom': dateStr,
          'dateTo': dateStr,
        },
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return HomeStats.fromMyStats(data as Map<String, dynamic>);
      }
      throw const ApiException(
        statusCode: 200,
        code: 'UNKNOWN',
        message: '获取统计数据失败',
      );
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// 获取待办日程预览（最多 5 条）
  ///
  /// 返回 [schedules] 列表 + [total] 总数。
  Future<({List<Schedule> schedules, int total})> fetchPendingSchedules() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.schedules,
        queryParameters: {
          'status': 'pending',
          'page': 1,
          'size': 5,
          'sort': 'scheduledAt',
        },
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final body = data['data'] as Map? ?? {};
        final List<Schedule> items = (body['items'] as List<dynamic>?)
                ?.map((e) => Schedule.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        return (schedules: items, total: _toInt(body['total']));
      }
      return (schedules: <Schedule>[], total: 0);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// 获取我的日程统计
  ///
  /// 返回 [HomeStats]（仅 dueToday 字段有效）。
  Future<HomeStats> fetchMyScheduleStats() async {
    try {
      final response =
          await _apiClient.dio.get(ApiConstants.schedulesStatsMine);
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return HomeStats.fromScheduleStats(data as Map<String, dynamic>);
      }
      return const HomeStats();
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// 获取即将到期日程数（未来 30 分钟内）
  ///
  /// [serverTime] 为服务端时间 Unix 秒。
  /// 返回到期日程总数 N（N ≥ 1 时显示提醒条）。
  Future<int> fetchDueSoonCount(int serverTime) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.schedules,
        queryParameters: {
          'status': 'pending',
          'scheduledAt__gte': serverTime,
          'scheduledAt__lte': serverTime + 1800,
          'page': 1,
          'size': 1,
        },
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final body = data['data'] as Map? ?? {};
        return _toInt(body['total']);
      }
      return 0;
    } on DioException {
      return 0; // 静默失败
    }
  }

  /// 获取服务端时间（从 HTTP 响应头 Date 解析）
  static int getServerTime(Response response) {
    try {
      final dateStr = response.headers.value('Date');
      if (dateStr != null) {
        return DateTime.parse(dateStr).millisecondsSinceEpoch ~/ 1000;
      }
    } catch (_) {}
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
