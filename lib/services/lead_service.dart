import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../services/api_constants.dart';
import '../services/api_exception.dart';
import '../models/lead.dart';
import '../models/option_item.dart';

/// 线索相关接口服务
class LeadService {
  final ApiClient _apiClient;

  LeadService({required ApiClient apiClient}) : _apiClient = apiClient;

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
