/// 健康检查服务
///
/// 获取后端版本信息，用于设置页"关于"弹窗和底部版本号展示。
/// GET /health 无需鉴权，此处复用 [ApiClient] 的 Dio 实例（带 Authorization 头也无害）。
library;

import 'package:telemarketing_app/services/api_client.dart';
import 'package:telemarketing_app/services/api_constants.dart';

/// 健康检查服务
class HealthService {
  final ApiClient _apiClient;

  HealthService({required this._apiClient});

  /// 获取后端版本号
  ///
  /// 返回 GET /health 的 [data.version] 字符串。
  /// 请求失败或字段缺失时返回 null。
  Future<String?> fetchVersion() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.health);
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final body = data['data'] as Map<String, dynamic>? ?? {};
        return body['version'] as String?;
      }
    } catch (_) {
      // 静默失败，返回 null 由调用方兜底
    }
    return null;
  }
}
