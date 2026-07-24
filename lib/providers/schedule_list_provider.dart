/// 日程列表状态管理
///
/// 待办/已完成双 Tab + 我的/团队范围（仅 TM/TA）。
/// 切 Tab / 范围时重置 page=1，并用 [_generation] 守卫忽略过期响应
/// （设计 §7.1：取消上一请求，避免竞态闪跳）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/schedule.dart';
import 'auth_provider.dart';
import 'schedule_stats_provider.dart';

/// 用于区分"未传参"和"传 null"的 sentinel 值
class _Unset {
  const _Unset();
}
const _unset = _Unset();

/// 日程列表状态
class ScheduleListState {
  /// 首屏加载中
  final bool isInitialLoading;

  /// 当前 Tab 的日程列表
  final List<Schedule> items;

  /// 总数
  final int total;

  /// 当前页
  final int currentPage;

  /// 加载更多中
  final bool isLoadingMore;

  /// 是否还有更多
  final bool hasMore;

  /// 错误信息
  final String? errorMessage;

  /// 当前 Tab：pending / completed
  final String activeTab;

  /// 范围：mine / team
  final String scope;

  /// 服务端时间（逾期判定用）
  final int serverTime;

  const ScheduleListState({
    this.isInitialLoading = true,
    this.items = const [],
    this.total = 0,
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.errorMessage,
    this.activeTab = 'pending',
    this.scope = 'mine',
    this.serverTime = 0,
  });

  ScheduleListState copyWith({
    bool? isInitialLoading,
    List<Schedule>? items,
    int? total,
    int? currentPage,
    bool? isLoadingMore,
    bool? hasMore,
    Object? errorMessage = _unset,
    String? activeTab,
    String? scope,
    int? serverTime,
  }) {
    return ScheduleListState(
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      items: items ?? this.items,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage:
          errorMessage is _Unset ? this.errorMessage : errorMessage as String?,
      activeTab: activeTab ?? this.activeTab,
      scope: scope ?? this.scope,
      serverTime: serverTime ?? this.serverTime,
    );
  }
}

/// 日程列表状态管理
class ScheduleListNotifier extends StateNotifier<ScheduleListState> {
  final Ref _ref;

  /// 请求代际：每次切 Tab / 范围 / 刷新时自增，
  /// 旧请求的响应若代际不匹配则忽略（防竞态闪跳）。
  int _generation = 0;

  ScheduleListNotifier(this._ref) : super(const ScheduleListState()) {
    _loadInitial();
  }

  bool get _isManager {
    final role = _ref.read(authProvider).user?.role;
    return role == 'tenant_admin' || role == 'tenant_manager';
  }

  /// 是否可切换团队视图（仅 TM/TA）
  bool get canSwitchScope => _isManager;

  /// 当前用户 ID；团队视图返回 null（不传 userId，由后端按角色返回团队）
  String? get _userId {
    final user = _ref.read(authProvider).user;
    if (user == null) return null;
    return state.scope == 'team' ? null : user.id;
  }

  // ── 首屏加载 ──

  Future<void> _loadInitial() async {
    final gen = ++_generation;
    final service = _ref.read(scheduleServiceProvider);
    try {
      final result =
          await service.fetchSchedules(status: state.activeTab, userId: _userId);
      if (!mounted || gen != _generation) return;
      state = state.copyWith(
        isInitialLoading: false,
        items: result.items,
        total: result.total,
        currentPage: 1,
        hasMore: result.items.length < result.total,
        serverTime: result.serverTime,
        errorMessage: null,
      );
    } catch (_) {
      if (!mounted || gen != _generation) return;
      state = state.copyWith(
        isInitialLoading: false,
        errorMessage: '加载失败，请重试',
      );
    }
  }

  // ── Tab / 范围切换 ──

  /// 切换 Tab（待办 / 已完成）
  void switchTab(String tab) {
    if (tab == state.activeTab) return;
    state = state.copyWith(
      activeTab: tab,
      isInitialLoading: true,
      isLoadingMore: false,
      items: const [],
      errorMessage: null,
    );
    _reload();
  }

  /// 切换范围（我的 / 团队，仅 TM/TA）
  void switchScope(String scope) {
    if (scope == state.scope) return;
    state = state.copyWith(
      scope: scope,
      isInitialLoading: true,
      isLoadingMore: false,
      items: const [],
      errorMessage: null,
    );
    _reload();
  }

  void _reload() {
    final gen = ++_generation;
    final service = _ref.read(scheduleServiceProvider);
    service
        .fetchSchedules(status: state.activeTab, userId: _userId)
        .then((result) {
      if (!mounted || gen != _generation) return;
      state = state.copyWith(
        isInitialLoading: false,
        items: result.items,
        total: result.total,
        currentPage: 1,
        hasMore: result.items.length < result.total,
        serverTime: result.serverTime,
        errorMessage: null,
      );
    }).catchError((_) {
      if (!mounted || gen != _generation) return;
      state = state.copyWith(
        isInitialLoading: false,
        errorMessage: '加载失败，请重试',
      );
    });
  }

  // ── 下拉刷新（同时刷新统计角标） ──

  Future<void> refresh() async {
    _ref.read(scheduleStatsProvider.notifier).refresh();
    _reload();
  }

  // ── 加载更多 ──

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isInitialLoading) {
      return;
    }
    final gen = _generation;
    state = state.copyWith(isLoadingMore: true);
    try {
      final service = _ref.read(scheduleServiceProvider);
      final nextPage = state.currentPage + 1;
      final result = await service.fetchSchedules(
        status: state.activeTab,
        userId: _userId,
        page: nextPage,
      );
      if (!mounted || gen != _generation) return;
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...result.items],
        total: result.total,
        currentPage: nextPage,
        hasMore: state.items.length + result.items.length < result.total,
      );
    } catch (_) {
      if (!mounted || gen != _generation) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

/// 日程列表 Provider
final scheduleListProvider =
    StateNotifierProvider<ScheduleListNotifier, ScheduleListState>((ref) {
  return ScheduleListNotifier(ref);
});
