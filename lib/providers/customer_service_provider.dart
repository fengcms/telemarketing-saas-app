/// 客户服务 Provider
///
/// 与 [leadServiceProvider] / [callServiceProvider] 同构，注入 [ApiClient]。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'package:telemarketing_app/services/api_client.dart';
import 'package:telemarketing_app/services/customer_service.dart';

/// 客户服务实例
final customerServiceProvider = Provider<CustomerService>((ref) {
  return CustomerService(apiClient: ref.read(apiClientProvider));
});
