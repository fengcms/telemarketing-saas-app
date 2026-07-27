/// 跨账号缓存协调器
///
/// 按「租户」分层失效（详见 docs/dev/PLAN_34_CACHE_ISOLATION.md）：
/// - 用户私有（线索 / 日程 / 通话 / 个人统计 / 详情）：**任何切换都清**；
/// - 租户共享（options / 租户 profile / 团队聚合统计）：**同租户换人保留，仅跨租户清**。
///
/// 集中处理而非各 provider 各自监听，避免「登出瞬间构造器误发请求」，
/// 且天然支持「同租户保留共享缓存」的优化。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/providers/lead_list_provider.dart';
import 'package:telemarketing_app/providers/schedule_list_provider.dart';
import 'package:telemarketing_app/providers/personal_stats_provider.dart';
import 'package:telemarketing_app/providers/team_stats_provider.dart';
import 'package:telemarketing_app/providers/call_service_provider.dart';
import 'package:telemarketing_app/providers/lead_detail_provider.dart';
import 'package:telemarketing_app/providers/schedule_stats_provider.dart';
import 'package:telemarketing_app/providers/options_provider.dart';

/// 跨账号缓存协调器
class CacheCoordinator {
  final Ref _ref;

  CacheCoordinator(this._ref);

  /// 登出（即将切换账号，租户可能不变）：只清用户私有。
  ///
  /// 租户共享（options / 租户 profile）保留，供同租户换人加速访问。
  void onLogout() => _clearUserPrivate();

  /// 登录成功后：私有必清；跨租户再清共享。
  void onSessionChanged({required bool crossTenant}) {
    _clearUserPrivate();
    if (crossTenant) _clearTenantShared();
  }

  /// 用户私有数据：任何账号切换都清（同租户 + 跨租户）。
  void _clearUserPrivate() {
    _ref.invalidate(leadListProvider);
    _ref.invalidate(scheduleListProvider);
    _ref.invalidate(scheduleStatsProvider);
    _ref.invalidate(personalStatsProvider);
    _ref.read(callServiceProvider).clear();
    _ref.read(leadDetailCacheProvider).invalidateAll();
    _ref.read(scheduleDetailCacheProvider).invalidateAll();
    // 团队统计是租户聚合，不在此清（跨租户才清，见 [_clearTenantShared]）
  }

  /// 租户共享数据：仅跨租户清（含磁盘）。
  ///
  /// 注意：**[tenantServiceProvider] 不清**——
  /// 登录路径已通过 [fetchTenantId(force:true)] 强制刷新为
  /// 「本次登录」的正确租户（name/settings/id），再清就是销毁刚预热好的
  /// 公司数据，导致首页公司名经历「空白→重拉」闪烁，且那次 profile
  /// 请求白费。故跨租户只清 options（fetchTenantId 未触碰的共享数据）
  /// 与团队聚合统计。
  void _clearTenantShared() {
    _ref.read(optionsCacheProvider).clearAll();
    _ref.invalidate(teamStatsProvider);
  }
}

/// 协调器 Provider
final cacheCoordinatorProvider = Provider<CacheCoordinator>((ref) {
  return CacheCoordinator(ref);
});
