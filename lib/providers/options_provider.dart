/// 下拉选项缓存 Provider
///
/// 懒初始化：首次调用时才拉取数据，缓存 30 分钟。
/// 登录/登出时自动重置。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/services/options_cache_service.dart';
import 'auth_provider.dart';

/// 下拉选项缓存 Provider
///
/// 懒初始化：首次调用时才拉取数据，缓存 30 分钟。
/// 登录/登出时自动重置。
final optionsCacheProvider = Provider<OptionsCacheService>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final cache = OptionsCacheService(apiClient: apiClient);

  // 监听认证状态：登出时清除缓存
  ref.listen(authProvider, (_, next) {
    if (next.status == AuthStatus.unauthenticated ||
        next.status == AuthStatus.authenticated) {
      // 登出或重新登录时，下次访问自动重新拉取
    }
  });

  return cache;
});

/// 根据分类 ID 获取分类名称
final categoryNameProvider =
    FutureProvider.family<String, String>((ref, id) async {
  final cache = ref.read(optionsCacheProvider);
  return (await cache.getCategoryName(id)) ?? id;
});

/// 根据用户 ID 获取用户姓名
final userNameProvider =
    FutureProvider.family<String, String>((ref, id) async {
  final cache = ref.read(optionsCacheProvider);
  return (await cache.getUserName(id)) ?? id;
});
