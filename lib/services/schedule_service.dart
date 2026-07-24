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
import 'package:telemarketing_app/models/schedule_detail.dart';
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

  /// 获取团队日程统计（仅 TA/TM）
  ///
  /// TA/TM 角色可查看团队整体的日程统计，包含团队级 dueToday。
  /// 若接口不可用（404/未实现），调用方应降级为 [fetchMyScheduleStats]。
  Future<ScheduleStats> fetchTeamScheduleStats() async {
    try {
      final response =
          await _apiClient.dio.get(ApiConstants.schedulesStats);
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return ScheduleStats.fromJson(data as Map<String, dynamic>);
      }
      return const ScheduleStats();
    } on DioException catch (_) {
      // 接口不可用时降级，由调用方处理
      rethrow;
    }
  }

  /// 获取日程详情（含 lead 快照 + call 摘要）
  Future<ScheduleDetail> fetchScheduleDetail(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.schedules}/$id',
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final body = data['data'] as Map<String, dynamic>? ?? {};
        return ScheduleDetail.fromJson(body);
      }
      throw const ApiException(
        statusCode: 200,
        code: 'UNKNOWN',
        message: '获取日程详情失败',
      );
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// 标记完成（POST /:id/complete）
  Future<void> completeSchedule(String id) => _postAction(id, 'complete');

  /// 取消日程（POST /:id/cancel）
  Future<void> cancelSchedule(String id) => _postAction(id, 'cancel');

  /// 重新打开（POST /:id/reopen）
  Future<void> reopenSchedule(String id) => _postAction(id, 'reopen');

  /// 状态类动作统一封装（complete/cancel/reopen 均无需 body）
  Future<void> _postAction(String id, String action) async {
    try {
      await _apiClient.dio
          .post('${ApiConstants.schedules}/$id/$action');
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// 删除日程（软删，DELETE /:id）
  Future<void> deleteSchedule(String id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.schedules}/$id');
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// 编辑日程（改期/标题/内容，PATCH /:id）
  ///
  /// [scheduledAt] 新的计划时间（Unix 秒）；[title]/[content] 至少传一个。
  Future<void> patchSchedule(
    String id, {
    int? scheduledAt,
    String? title,
    String? content,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (scheduledAt != null) body['scheduledAt'] = scheduledAt;
      if (title != null) body['title'] = title;
      if (content != null) body['content'] = content;
      await _apiClient.dio.patch(
        '${ApiConstants.schedules}/$id',
        data: body,
      );
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// 新建日程（POST /api/tenant/schedules）
  ///
  /// [leadId] 关联线索 ID；[scheduledAt] 计划时间（Unix 秒）；
  /// [title] 必填（≤200 字）；[content] 可选（≤2000 字）；
  /// [userId] 仅 TM/TA 替他人建时传；[callRecordId] 关联通话记录。
  /// 返回新建日程 ID（失败返回 null）。
  Future<String?> createSchedule({
    required String leadId,
    required int scheduledAt,
    required String title,
    String? content,
    String? userId,
    String? callRecordId,
  }) async {
    try {
      final body = <String, dynamic>{
        'leadId': leadId,
        'scheduledAt': scheduledAt,
        'title': title,
      };
      if (content != null && content.isNotEmpty) body['content'] = content;
      if (userId != null && userId.isNotEmpty) body['userId'] = userId;
      if (callRecordId != null && callRecordId.isNotEmpty) {
        body['callRecordId'] = callRecordId;
      }
      final response = await _apiClient.dio.post(
        ApiConstants.schedules,
        data: body,
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return data['data']?['id']?.toString();
      }
      return null;
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
