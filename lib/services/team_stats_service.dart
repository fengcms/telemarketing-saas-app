/// 团队统计服务
///
/// 封装 GET /api/tenant/stats（租户级团队业务统计，按日期区间聚合）。
library;

import 'package:dio/dio.dart';
import 'package:telemarketing_app/services/api_client.dart';
import 'package:telemarketing_app/services/api_exception.dart';
import 'package:telemarketing_app/services/api_constants.dart';
import 'package:telemarketing_app/models/team_stats.dart';

/// 所选日期范围内无统计数据（后端返回仅含 message 的空 body）
class NoDataInRangeException implements Exception {
  const NoDataInRangeException();
}

/// 团队统计服务
class TeamStatsService {
  final ApiClient _apiClient;

  TeamStatsService({required this._apiClient});

  /// 获取团队统计
  ///
  /// [dateFrom]/[dateTo] 格式 yyyy-MM-dd，闭区间。
  /// 成功返回 [TeamStats]；区间内无数据时抛 [NoDataInRangeException]；
  /// 其余异常由 [ApiClient.parseError] 统一转换。
  Future<TeamStats> fetchTeamStats({
    required String dateFrom,
    required String dateTo,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.statsTeam,
        queryParameters: {'dateFrom': dateFrom, 'dateTo': dateTo},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final body =
            data['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
        // 无数据范围：body 仅含 message 无统计字段
        if (body.containsKey('message') && !body.containsKey('total')) {
          throw const NoDataInRangeException();
        }
        return TeamStats.fromJson(body);
      }
      throw const ApiException(
        statusCode: 200,
        code: 'UNKNOWN',
        message: '获取团队统计失败',
      );
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
