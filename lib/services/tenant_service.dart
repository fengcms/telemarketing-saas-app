/// 租户信息服务
library;

import 'package:telemarketing_app/services/api_client.dart';
import 'package:telemarketing_app/services/api_constants.dart';

/// 租户信息服务
class TenantService {
  final ApiClient _apiClient;

  TenantService({required this._apiClient});

  /// 获取租户配置（含 noCallWindow）
  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _apiClient.dio.get(ApiConstants.profile);
    final data = response.data;
    if (data is Map && data['success'] == true) {
      return (data['data'] as Map<String, dynamic>)['settings']
          as Map<String, dynamic>? ?? {};
    }
    return {};
  }

  /// 获取租户名称（个人中心"所属租户"展示用）
  ///
  /// 返回 GET /api/tenant/profile 的 [data.name] 字符串；
  /// 解析失败或字段缺失时返回空字符串，由调用方决定是否隐藏该行。
  Future<String> fetchTenantName() async {
    final response = await _apiClient.dio.get(ApiConstants.profile);
    final data = response.data;
    if (data is Map && data['success'] == true) {
      final profile = data['data'] as Map<String, dynamic>? ?? {};
      return (profile['name'] as String?) ?? '';
    }
    return '';
  }
}
