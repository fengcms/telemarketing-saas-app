/// 日程统计共享 Provider
///
/// 单一数据源：拉取并缓存「我的日程统计」
/// （GET /api/tenant/schedules/stats/mine）。
/// 供底部 Tab 角标（dueToday）与日程列表页 Tab 计数共用，
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
class ScheduleStatsState {
  /// 是否加载中
  final bool isLoading;

  /// 统计结果
  final ScheduleStats? stats;

  /// 错误信息
  final Object? errorMessage;

  const ScheduleStatsState({
    this.isLoading = false,
    this.stats,
    this.errorMessage,
  });

  ScheduleStatsState copyWith({
    bool? isLoading,
    ScheduleStats? stats,
    Object? errorMessage = _unset,
  }) {
    return ScheduleStatsState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      errorMessage:
          errorMessage is _Unset ? this.errorMessage : errorMessage,
    );
  }

  /// 今日待办数（底部 Tab 角标用）
  int get dueToday => stats?.dueToday ?? 0;

  /// 待办总数（列表 Tab 计数用）
  int get pending => stats?.pending ?? 0;

  /// 已完成总数（列表 Tab 计数用）
  int get completed => stats?.completed ?? 0;
}

/// 日程统计状态管理
class ScheduleStatsNotifier extends StateNotifier<ScheduleStatsState> {
  final Ref _ref;

  ScheduleStatsNotifier(this._ref) : super(const ScheduleStatsState()) {
    load();
  }

  /// 加载统计
  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final service = _ref.read(scheduleServiceProvider);
      final stats = await service.fetchMyScheduleStats();
      if (mounted) {
        state = state.copyWith(isLoading: false, stats: stats);
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
