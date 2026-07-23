/// 线索相关接口服务
library;

import 'package:dio/dio.dart';
import 'package:telemarketing_app/services/api_client.dart';
import 'package:telemarketing_app/services/api_constants.dart';
import 'package:telemarketing_app/models/lead.dart';
import 'package:telemarketing_app/models/lead_detail_bundle.dart';
import 'package:telemarketing_app/models/follow_up_record.dart';
import 'package:telemarketing_app/models/call_record.dart';
import 'package:telemarketing_app/models/option_item.dart';

/// 线索相关接口服务
class LeadService {
  final ApiClient _apiClient;

  LeadService({required this._apiClient});

  // ── 线索详情 ──

  /// 获取线索详情（聚合接口）
  ///
  /// 后端一次请求返回 `lead` + `followups` + `calls`(最近5) +
  /// `schedules`(最近5)，封装为 [LeadDetailBundle]。
  ///
  /// [raw] TA/TM 角色传 true 获取明文姓名/电话。
  /// 返回 null 表示线索已被删除/擦除（404）。
  Future<LeadDetailBundle?> fetchLeadDetail({
    required String id,
    bool raw = false,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (raw) params['raw'] = 1;
      final response = await _apiClient.dio.get(
        '${ApiConstants.leads}/$id',
        queryParameters: params.isNotEmpty ? params : null,
      );
      final data = response.data;
      if (data is Map && data['success'] == true && data['data'] != null) {
        final body = data['data'] as Map<String, dynamic>;
        // 新接口：data 内含 lead / followups / calls / schedules
        return LeadDetailBundle.fromJson(body);
      }
      return null;
    } on DioException catch (e) {
      // 404 表示线索已删除/擦除
      if (e.response?.statusCode == 404) return null;
      throw ApiClient.parseError(e);
    }
  }

  // ── 跟进时间线 ──

  /// 获取线索的全部跟进记录（接口当前不分页）
  Future<List<FollowUpRecord>> fetchFollowUps(String leadId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leads}/$leadId/followups',
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final body = data['data'] as Map? ?? {};
        final items = body['items'] as List<dynamic>? ?? [];
        return items
            .map((e) =>
                FollowUpRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ── 通话记录 ──

  /// 获取线索的通话记录
  ///
  /// [size] 摘要模式传 3，全部模式传 20
  Future<({List<CallRecord> items, int total})> fetchCalls({
    required String leadId,
    int page = 1,
    int size = 3,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.calls,
        queryParameters: {
          'leadId': leadId,
          'page': page,
          'size': size,
        },
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final body = data['data'] as Map? ?? {};
        final List<CallRecord> items = (body['items'] as List<dynamic>?)
                ?.map(
                    (e) => CallRecord.fromJson(e as Map<String, dynamic>))
                .toList() ??
            <CallRecord>[];
        return (items: items, total: _toInt(body['total']));
      }
      return (items: <CallRecord>[], total: 0);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ── 编辑线索 ──

  /// 编辑线索（分类/状态）
  Future<bool> updateLead({
    required String id,
    String? categoryId,
    String? status,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (categoryId != null) body['categoryId'] = categoryId;
      if (status != null) body['status'] = status;
      final response = await _apiClient.dio.patch(
        '${ApiConstants.leads}/$id',
        data: body,
      );
      final data = response.data;
      return data is Map && data['success'] == true;
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ── 创建跟进记录 ──

  /// 创建跟进记录
  ///
  /// [categoryId] 可选，同时更新线索分类。
  /// 提交后后端自动将线索置为 following。
  Future<String?> createFollowUp({
    required String leadId,
    required String content,
    required String answerType,
    int? duration,
    String? categoryId,
  }) async {
    try {
      final body = <String, dynamic>{
        'content': content,
        'answerType': answerType,
      };
      if (duration != null) body['duration'] = duration;
      if (categoryId != null) body['categoryId'] = categoryId;
      final response = await _apiClient.dio.post(
        '${ApiConstants.leads}/$leadId/followups',
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

  // ── 创建通话记录（含原子创建跟进） ──

  /// 复合「完成通话」端点。
  ///
  /// POST /api/tenant/leads/:id/calls
  /// 一次请求原子创建通话记录 + 跟进记录（content 非空时）。
  ///
  /// [startedAt] 通话开始时间（epoch 秒）
  /// [externalCallId] 客户端唯一 ID，用于幂等防重
  /// [phone] 电话号码（选填，缺省取线索手机号）
  /// [duration] 通话时长（秒）
  /// [answerType] 接听类型
  /// [content] 跟进内容（选填，非空时自动建跟进）
  /// [categoryId] 更新线索分类（选填）
  Future<Map<String, dynamic>> createCall({
    required String leadId,
    required int startedAt,
    required String externalCallId,
    required String answerType,
    String? phone,
    int? duration,
    String? content,
    String? categoryId,
  }) async {
    try {
      final body = <String, dynamic>{
        'startedAt': startedAt,
        'externalCallId': externalCallId,
        'answerType': answerType,
        'direction': 'outbound',
      };
      if (phone != null) body['phone'] = phone;
      if (duration != null) body['duration'] = duration;
      if (content != null && content.isNotEmpty) body['content'] = content;
      if (categoryId != null) body['categoryId'] = categoryId;
      final response = await _apiClient.dio.post(
        '${ApiConstants.leads}/$leadId/calls',
        data: body,
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return data['data'] as Map<String, dynamic>? ?? {};
      }
      throw Exception(data['error']?.toString() ?? '提交失败');
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ── 编辑跟进记录 ──

  /// 编辑跟进记录（仅 content）
  Future<bool> updateFollowUp({
    required String leadId,
    required String followUpId,
    required String content,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '${ApiConstants.leads}/$leadId/followups/$followUpId',
        data: {'content': content},
      );
      final data = response.data;
      return data is Map && data['success'] == true;
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ── 删除跟进记录 ──

  /// 删除跟进记录
  Future<bool> deleteFollowUp({
    required String leadId,
    required String followUpId,
  }) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiConstants.leads}/$leadId/followups/$followUpId',
      );
      final data = response.data;
      return data is Map && data['success'] == true;
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ── 新建日程（预约跟进） ──

  /// 创建预约跟进日程
  ///
  /// [scheduledAt] Unix 秒级时间戳
  /// [title] 必填，≤200 字
  /// [content] 可选，≤2000 字
  Future<String?> createSchedule({
    required String leadId,
    required int scheduledAt,
    required String title,
    String? content,
  }) async {
    try {
      final body = <String, dynamic>{
        'leadId': leadId,
        'scheduledAt': scheduledAt,
        'title': title,
      };
      if (content != null && content.isNotEmpty) {
        body['content'] = content;
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

  // ── 补正通话记录（TM/TA） ──

  /// 补正通话记录
  ///
  /// 仅 TM/TA 可调用，TE 返回 403。
  /// 所有参数均为可选，按需传入。
  Future<bool> correctCallRecord({
    required String callId,
    String? answerType,
    int? duration,
    int? endedAt,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (answerType != null) body['answerType'] = answerType;
      if (duration != null) body['duration'] = duration;
      if (endedAt != null) body['endedAt'] = endedAt;
      final response = await _apiClient.dio.patch(
        '${ApiConstants.calls}/$callId',
        data: body,
      );
      final data = response.data;
      return data is Map && data['success'] == true;
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// 获取线索列表
  ///
  /// [scope] TE: mine, TM/TA: all
  /// [page] 页码，从 1 开始
  /// [size] 每页条数，默认 20
  /// [keyword] 搜索关键词
  /// [statusIn] 状态筛选，逗号分隔
  /// [categoryId] 分类筛选
  /// [projectId] 项目筛选
  /// [dateFrom] / [dateTo] 时间段筛选（Unix 秒）
  /// [sort] 排序字段，默认 -updatedAt
  Future<({List<Lead> leads, int total})> fetchLeads({
    required String scope,
    int page = 1,
    int size = 20,
    String? keyword,
    String? statusIn,
    String? categoryId,
    String? projectId,
    int? dateFrom,
    int? dateTo,
    String sort = '-updatedAt',
  }) async {
    try {
      final params = <String, dynamic>{
        'scope': scope,
        'page': page,
        'size': size,
        'erased': 0,
        'sort': sort,
      };
      if (keyword != null && keyword.isNotEmpty) params['q'] = keyword;
      if (statusIn != null && statusIn.isNotEmpty) params['status__in'] = statusIn;
      if (categoryId != null && categoryId.isNotEmpty) params['categoryId'] = categoryId;
      if (projectId != null && projectId.isNotEmpty) params['projectId'] = projectId;
      if (dateFrom != null) params['updatedAt__gte'] = dateFrom;
      if (dateTo != null) params['updatedAt__lte'] = dateTo;

      final response = await _apiClient.dio.get(
        ApiConstants.leads,
        queryParameters: params,
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        final body = data['data'] as Map? ?? {};
        final List<Lead> items = (body['items'] as List<dynamic>?)
                ?.map((e) => Lead.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        return (leads: items, total: _toInt(body['total']));
      }
      return (leads: <Lead>[], total: 0);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// 获取分类选项列表
  Future<List<OptionItem>> fetchCategories() async {
    return _fetchOptions(ApiConstants.optionsCategories);
  }

  /// 获取项目选项列表
  Future<List<OptionItem>> fetchProjects() async {
    return _fetchOptions(ApiConstants.optionsProjects);
  }

  /// 获取用户选项列表（TM/TA 筛选面板用）
  Future<List<OptionItem>> fetchUsers() async {
    return _fetchOptions(ApiConstants.optionsUsers);
  }

  Future<List<OptionItem>> _fetchOptions(String endpoint) async {
    try {
      final response = await _apiClient.dio.get(endpoint);
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final items = data['data'] as List<dynamic>? ?? [];
        return items
            .map((e) => OptionItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
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
