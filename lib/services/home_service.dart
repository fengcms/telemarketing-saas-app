/// 首页看板数据服务
///
/// 封装首页所需的 2 个接口调用：
/// 1. [fetchMyStats] - GET /api/tenant/stats/mine（今日跟进/接通/线索总数）
/// 2. [fetchHomeSummary] - GET /api/tenant/schedules/home-summary（待办数/即将到期/预览列表）
library;

import 'package:dio/dio.dart';
import 'package:telemarketing_app/services/api_client.dart';
import 'package:telemarketing_app/services/api_constants.dart';
import 'package:telemarketing_app/services/api_exception.dart';
import 'package:telemarketing_app/models/home_stats.dart';
import 'package:telemarketing_app/models/home_summary.dart';

/// 首页看板数据服务
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

  /// 获取首页日程聚合（今日待办 + 即将到期 + 预览列表）
  ///
  /// 调 GET /api/tenant/schedules/home-summary，一次性返回
  /// [HomeSummary]（todayPending / dueSoonCount / pendingTotal / schedules）。
  /// 替代原先的待办列表查询、日程统计查询、即将到期时间窗查询三个请求。
  Future<HomeSummary> fetchHomeSummary() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.homeSummary);
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return HomeSummary.fromJson(data as Map<String, dynamic>);
      }
      throw const ApiException(
        statusCode: 200,
        code: 'UNKNOWN',
        message: '获取首页日程失败',
      );
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// 获取服务端时间（从 HTTP 响应头 Date 解析）
  ///
  /// 供 [schedule_service.dart] 复用，避免额外请求。
  static int getServerTime(Response response) {
    try {
      final dateStr = response.headers.value('Date');
      if (dateStr != null) {
        return DateTime.parse(dateStr).millisecondsSinceEpoch ~/ 1000;
      }
    } catch (_) {}
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }
}
