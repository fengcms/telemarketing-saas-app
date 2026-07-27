/// 日程统计共享 Provider
///
/// 单一数据源：拉取并缓存「我的 / 团队日程统计」
/// （GET /api/tenant/schedules/stats/mine 或 stats）。
/// 供底部 Tab 角标（todayPending）与日程列表页 Tab 计数共用，
/// 避免重复请求（决策 c：统一数据源）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/services/schedule_service.dart';
import 'package:telemarketing_app/services/schedule_detail_cache.dart';
import 'package:telemarketing_app/models/schedule_stats.dart';
import 'auth_provider.dart';

/// 日程数据服务实例
final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService(apiClient: ref.read(apiClientProvider));
});

/// 日程详情缓存（内存，10 分钟 TTL）
///
/// 详情页「缓存优先」读取：命中即秒开、后台静默刷新；
/// 任一处写操作后 [ScheduleDetailCache.invalidate] 失效，下次进入重新拉取。
final scheduleDetailCacheProvider = Provider<ScheduleDetailCache>((ref) {
  return ScheduleDetailCache();
});

/// 用于区分"未传参"和"传 null"的 sentinel 值
class _Unset {
  const _Unset();
}
const _unset = _Unset();

/// 日程统计状态
///
/// 同时持有「我的」与「团队」两份统计（见 [load]）：
/// - [mineStats]：个人口径，供 home 角标 / 个人中心 / 日程「我的」视图共用；
/// - [teamStats]：团队口径，仅 TM/TA，供日程「团队」视图使用。
/// 日程页 Tab 数字通过 [pendingForScope] / [completedForScope] 按当前
/// scope 取对应口径，避免「经理看到团队总数但列表是我的」的错位。
class ScheduleStatsState {
  /// 是否加载中
  final bool isLoading;

  /// 我的统计（个人口径）
  final ScheduleStats? mineStats;

  /// 团队统计（仅 TM/TA，null 表示无权限 / 接口不可用）
  final ScheduleStats? teamStats;

  /// 错误信息
  final Object? errorMessage;

  const ScheduleStatsState({
    this.isLoading = false,
    this.mineStats,
    this.teamStats,
    this.errorMessage,
  });

  ScheduleStatsState copyWith({
    bool? isLoading,
    ScheduleStats? mineStats,
    ScheduleStats? teamStats,
    Object? errorMessage = _unset,
  }) {
    return ScheduleStatsState(
      isLoading: isLoading ?? this.isLoading,
      mineStats: mineStats ?? this.mineStats,
      teamStats: teamStats ?? this.teamStats,
      errorMessage:
          errorMessage is _Unset ? this.errorMessage : errorMessage,
    );
  }

  /// 今日待办数（底部 Tab 角标 / 个人中心用，严格今日窗口，我的口径）
  /// 与首页 home-summary.todayPending 同源，全端一致。
  int get todayPending => mineStats?.todayPending ?? 0;

  /// 按 scope 取待办总数（日程列表 Tab 计数用）
  ///
  /// [scope] 为 'team' 时返回团队口径，否则返回我的口径。
  int pendingForScope(String scope) =>
      (scope == 'team' ? teamStats : mineStats)?.pending ?? 0;

  /// 按 scope 取已完成总数（日程列表 Tab 计数用）
  int completedForScope(String scope) =>
      (scope == 'team' ? teamStats : mineStats)?.completed ?? 0;
}

/// 日程统计状态管理
class ScheduleStatsNotifier extends StateNotifier<ScheduleStatsState> {
  final Ref _ref;

  ScheduleStatsNotifier(this._ref) : super(const ScheduleStatsState(isLoading: true)) {
    load();
  }

  /// 加载统计
  ///
  /// 同时拉取「我的」与「团队」两份（TM/TA 才拉团队）：
  /// - mine 为个人口径，home 角标 / 个人中心 / 日程「我的」视图共用；
  /// - team 为团队口径，仅 TM/TA，接口不可用静默降级为 null
  ///   （团队视图 Tab 数字显示 0，但团队头部摘要条由列表 [teamStats] 提供，不受影响）。
  /// 两份都缓存进 state，日程页按当前 scope 取对应口径，
  /// 切「我的 / 团队」无需重新请求即可同步数字。
  Future<void> load() async {
    try {
      final service = _ref.read(scheduleServiceProvider);
      final user = _ref.read(authProvider).user;
      final isManager =
          user?.role == 'tenant_admin' || user?.role == 'tenant_manager';

      // 我的统计（个人口径，必拉）
      final mine = await service.fetchMyScheduleStats();

      // 团队统计仅 TM/TA；接口不可用降级为 null
      ScheduleStats? team;
      if (isManager) {
        try {
          team = await service.fetchTeamScheduleStats();
        } catch (_) {
          team = null;
        }
      }

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          mineStats: mine,
          teamStats: team,
        );
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isLoading: false, errorMessage: '加载统计失败');
      }
    }
  }

  /// 下拉刷新
  Future<void> refresh() => load();
}

/// 日程统计共享 Provider
final scheduleStatsProvider =
    StateNotifierProvider<ScheduleStatsNotifier, ScheduleStatsState>((ref) {
  return ScheduleStatsNotifier(ref);
});
