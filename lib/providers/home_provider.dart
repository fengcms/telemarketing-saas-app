/// 首页数据服务实例
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/home_stats.dart';
import 'package:telemarketing_app/models/schedule.dart';
import 'package:telemarketing_app/models/home_summary.dart';
import 'package:telemarketing_app/services/home_service.dart';
import 'auth_provider.dart';

// ── HomeService Provider ──

/// 首页数据服务实例
final homeServiceProvider = Provider<HomeService>((ref) {
  return HomeService(apiClient: ref.read(apiClientProvider));
});

// ── Home Page State ──

/// 首页看板页面状态
class HomePageState {
  /// 是否处于首屏加载中
  final bool isInitialLoading;

  /// 统计数据（来自 stats/mine：跟进/接通/线索总数）
  final HomeStats? stats;

  /// 待办日程列表（最多 5 条，来自 home-summary）
  final List<Schedule>? schedules;

  /// 今日待办数（严格今日窗口，来自 home-summary.todayPending）
  /// 替代原 stats.dueToday（含历史逾期）口径。
  final int todayPending;

  /// 即将到期日程数（未来 30 分钟，用于提醒条）
  final int dueSoonCount;

  /// 统计区域独立加载态
  final bool isLoadingStats;

  /// 日程区域独立加载态
  final bool isLoadingSchedules;

  /// 统计区域错误
  final String? statsError;

  /// 日程区域错误
  final String? schedulesError;

  /// 是否离线
  final bool isOffline;

  /// 用户已关闭到期提醒条（当次会话）
  final bool isDueSoonBannerClosed;

  /// 缓存的服务端时间（Unix 秒）
  final int serverTime;

  const HomePageState({
    this.isInitialLoading = true,
    this.stats,
    this.schedules,
    this.todayPending = 0,
    this.dueSoonCount = 0,
    this.isLoadingStats = false,
    this.isLoadingSchedules = false,
    this.statsError,
    this.schedulesError,
    this.isOffline = false,
    this.isDueSoonBannerClosed = false,
    this.serverTime = 0,
  });

  HomePageState copyWith({
    bool? isInitialLoading,
    HomeStats? stats,
    List<Schedule>? schedules,
    int? todayPending,
    int? dueSoonCount,
    bool? isLoadingStats,
    bool? isLoadingSchedules,
    String? statsError,
    String? schedulesError,
    bool? isOffline,
    bool? isDueSoonBannerClosed,
    int? serverTime,
  }) {
    return HomePageState(
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      stats: stats ?? this.stats,
      schedules: schedules ?? this.schedules,
      todayPending: todayPending ?? this.todayPending,
      dueSoonCount: dueSoonCount ?? this.dueSoonCount,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      isLoadingSchedules: isLoadingSchedules ?? this.isLoadingSchedules,
      statsError: statsError,
      schedulesError: schedulesError,
      isOffline: isOffline ?? this.isOffline,
      isDueSoonBannerClosed:
          isDueSoonBannerClosed ?? this.isDueSoonBannerClosed,
      serverTime: serverTime ?? this.serverTime,
    );
  }

  /// 是否应显示到期提醒条
  bool get shouldShowDueSoonBanner =>
      dueSoonCount > 0 &&
      !isDueSoonBannerClosed &&
      !isInitialLoading;
}

/// 首页看板状态管理
class HomePageNotifier extends StateNotifier<HomePageState> {
  final Ref _ref;
  Timer? _pollingTimer;
  bool _isDisposed = false;

  HomePageNotifier(this._ref) : super(const HomePageState()) {
    // 监听认证状态：登出时重置首页数据，避免切换账号后显示旧数据
    _ref.listen(authProvider, (_, next) {
      if (next.status == AuthStatus.unauthenticated) {
        reset();
      } else if (next.status == AuthStatus.authenticated) {
        loadData();
      }
    });
    loadData();
    _startPolling();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pollingTimer?.cancel();
    super.dispose();
  }

  // ── 数据加载 ──

  /// 并行加载所有首页数据（首屏 + 下拉刷新）
  Future<void> loadData() async {
    if (_isDisposed) return;

    final today = _getTodayDate();
    final homeService = _ref.read(homeServiceProvider);

    // 并行发起 2 个请求：业务统计 + 首页日程聚合
    final results = await Future.wait([
      _safeCall(() => homeService.fetchMyStats(today)),
      _safeCall(() => homeService.fetchHomeSummary()),
    ]);

    if (_isDisposed) return;

    final statsResult = results[0];
    final summary =
        (results[1] is HomeSummary) ? results[1] as HomeSummary : null;

    HomeStats? mergedStats;
    String? statsError;
    List<Schedule>? schedules;
    int todayPending = 0;
    int dueSoonCount = 0;
    String? schedulesError;

    // 处理统计结果
    if (statsResult != null && statsResult is HomeStats) {
      mergedStats = statsResult;
      statsError = null;
    } else {
      statsError = '加载统计数据失败';
    }

    // 处理首页日程聚合
    if (summary != null) {
      schedules = summary.schedules;
      todayPending = summary.todayPending;
      dueSoonCount = summary.dueSoonCount;
      schedulesError = null;
    } else {
      schedulesError = '加载日程失败';
    }

    state = state.copyWith(
      isInitialLoading: false,
      stats: mergedStats,
      schedules: schedules,
      todayPending: todayPending,
      dueSoonCount: dueSoonCount,
      isLoadingStats: false,
      isLoadingSchedules: false,
      statsError: statsError,
      schedulesError: schedulesError,
    );
  }

  /// 重置状态（退出登录时调用，避免切换账号后显示旧数据）
  void reset() {
    if (_isDisposed) return;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    state = const HomePageState();
  }

  /// 下拉刷新
  Future<void> refresh() async {
    if (_isDisposed) return;
    state = state.copyWith(
      isLoadingStats: true,
      isLoadingSchedules: true,
      statsError: null,
      schedulesError: null,
    );
    await loadData();
  }

  /// 重试统计区域
  Future<void> retryStats() async {
    if (_isDisposed) return;
    state = state.copyWith(isLoadingStats: true, statsError: null);
    await loadData();
  }

  /// 重试日程区域
  Future<void> retrySchedules() async {
    if (_isDisposed) return;
    state = state.copyWith(isLoadingSchedules: true, schedulesError: null);
    await loadData();
  }

  // ── 轮询 ──

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _silentRefresh(),
    );
  }

  /// 静默刷新（轮询 + 后台回前台）
  Future<void> _silentRefresh() async {
    if (_isDisposed) return;
    final today = _getTodayDate();
    final homeService = _ref.read(homeServiceProvider);

    // 静默刷新不显示 loading 状态
    final stats = await _safeCall(() => homeService.fetchMyStats(today));
    final summary =
        await _safeCall(() => homeService.fetchHomeSummary());

    if (_isDisposed) return;

    HomeStats? mergedStats = state.stats;
    if (stats != null && stats is HomeStats) {
      mergedStats = stats;
    }

    List<Schedule>? scheduleList = state.schedules;
    int todayPending = state.todayPending;
    int dueSoonCount = state.dueSoonCount;
    if (summary != null && summary is HomeSummary) {
      scheduleList = summary.schedules;
      todayPending = summary.todayPending;
      dueSoonCount = summary.dueSoonCount;
    }

    state = state.copyWith(
      stats: mergedStats,
      schedules: scheduleList,
      todayPending: todayPending,
      dueSoonCount: dueSoonCount,
    );
  }

  // ── 网络状态 ──

  /// 设置离线状态
  void setOffline(bool offline) {
    if (_isDisposed) return;
    state = state.copyWith(isOffline: offline);
  }

  // ── 到期提醒条 ──

  /// 关闭到期提醒条
  void closeDueSoonBanner() {
    if (_isDisposed) return;
    state = state.copyWith(isDueSoonBannerClosed: true);
  }

  // ── 后台/前台切换 ──

  /// APP 回到前台时触发
  void onResume() {
    if (_isDisposed) return;
    _startPolling(); // 重启定时器
    // 检查是否距上次更新超过 10 分钟
    _silentRefresh();
  }

  /// APP 进入后台时暂停轮询
  void onPause() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // ── 工具方法 ──

  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 安全调用：捕获所有异常，返回 null
  Future<dynamic> _safeCall<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }
}

/// 首页看板状态 Provider
final homePageProvider =
    StateNotifierProvider<HomePageNotifier, HomePageState>((ref) {
  return HomePageNotifier(ref);
});
