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
}
