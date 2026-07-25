/// 健康检查服务 Provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'package:telemarketing_app/services/health_service.dart';

/// 健康检查服务实例
final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService(apiClient: ref.read(apiClientProvider));
});
