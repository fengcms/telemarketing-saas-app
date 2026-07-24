/// 通话记录服务 Provider
///
/// 与 [leadServiceProvider] 同构，注入 [ApiClient]。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'package:telemarketing_app/services/api_client.dart';
import 'package:telemarketing_app/services/call_service.dart';

/// 通话记录服务实例
final callServiceProvider = Provider<CallService>((ref) {
  return CallService(apiClient: ref.read(apiClientProvider));
});
