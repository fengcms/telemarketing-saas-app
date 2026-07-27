/// 个人统计 Provider
///
/// 单一数据源：拉取并缓存「个人业务统计」（GET /api/tenant/stats/mine），
/// 按日期范围（今日/本周/本月/自定义）切换。
/// 内置 5 分钟按范围 key 的内存缓存，避免频繁切范围重复请求。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'package:telemarketing_app/services/home_service.dart';
import 'package:telemarketing_app/models/personal_stats.dart';

/// 个人统计数据服务实例
final personalStatsServiceProvider = Provider<HomeService>((ref) {
  return HomeService(apiClient: ref.read(apiClientProvider));
});

/// 日期范围类型
enum DateRangeKind {
  /// 今日（from == to == 今天）
  today,

  /// 本周（本周一 ~ 今天）
  thisWeek,

  /// 本月（本月 1 号 ~ 今天）
  thisMonth,

  /// 自定义（设计允许超 1 年，仅拦截起 > 止）
  custom,
}

/// 缓存项
class _CachedItem {
  final PersonalStats stats;
  final DateTime fetchedAt;

  _CachedItem(this.stats, this.fetchedAt);
}

/// 用于区分"未传参"和"传 null"的 sentinel 值
class _Unset {
  const _Unset();
}
const _unset = _Unset();

/// 个人统计状态
class PersonalStatsState {
  /// 是否加载中
  final bool isLoading;

  /// 统计结果（null 表示尚未加载 / 加载失败）
  final PersonalStats? stats;

  /// 错误信息（null 表示无错误）
  final Object? errorMessage;

  /// 当前日期范围类型
  final DateRangeKind rangeKind;

  /// 起始日期 yyyy-MM-dd
  final String dateFrom;

  /// 结束日期 yyyy-MM-dd
  final String dateTo;

  const PersonalStatsState({
    this.isLoading = false,
    this.stats,
    this.errorMessage,
    this.rangeKind = DateRangeKind.today,
    this.dateFrom = '',
    this.dateTo = '',
  });

  PersonalStatsState copyWith({
    bool? isLoading,
    PersonalStats? stats,
    Object? errorMessage = _unset,
    DateRangeKind? rangeKind,
    String? dateFrom,
    String? dateTo,
  }) {
    return PersonalStatsState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      errorMessage: errorMessage is _Unset ? this.errorMessage : errorMessage,
      rangeKind: rangeKind ?? this.rangeKind,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }
}

/// yyyy-MM-dd 格式化（不依赖 intl）
String formatRangeDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 根据范围类型解析起止日期
(String, String) _resolvePreset(DateRangeKind kind) {
  final now = DateTime.now();
  switch (kind) {
    case DateRangeKind.today:
      final s = formatRangeDate(now);
      return (s, s);
    case DateRangeKind.thisWeek:
      final monday = now.subtract(Duration(days: now.weekday - 1));
      return (formatRangeDate(monday), formatRangeDate(now));
    case DateRangeKind.thisMonth:
      final first = DateTime(now.year, now.month, 1);
      return (formatRangeDate(first), formatRangeDate(now));
    case DateRangeKind.custom:
      return ('', '');
  }
}

/// 个人统计状态管理
class PersonalStatsNotifier extends StateNotifier<PersonalStatsState> {
  final Ref _ref;

  /// 按范围 key 的 5 分钟缓存
  final Map<String, _CachedItem> _cache = {};

  PersonalStatsNotifier(this._ref)
      : super(const PersonalStatsState(isLoading: true)) {
    load();
  }

  (String, String) _currentRange() {
    if (state.rangeKind == DateRangeKind.custom) {
      return (state.dateFrom, state.dateTo);
    }
    return _resolvePreset(state.rangeKind);
  }

  /// 加载统计
  ///
  /// [force] 为 true 时忽略缓存强制刷新。
  /// 命中 5 分钟缓存且非强制时直接复用，不发起请求。
  Future<void> load({bool force = false}) async {
    final (from, to) = _currentRange();
    if (from.isEmpty || to.isEmpty) return;
    final userId = _ref.read(authProvider).user?.id ?? '';
    final key = '$userId~$from~$to';

    final cached = _cache[key];
    if (!force &&
        cached != null &&
        DateTime.now().difference(cached.fetchedAt).inMinutes < 5) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          stats: cached.stats,
          errorMessage: null,
          dateFrom: from,
          dateTo: to,
        );
      }
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      dateFrom: from,
      dateTo: to,
    );
    try {
      final service = _ref.read(personalStatsServiceProvider);
      final stats = await service.fetchPersonalStats(
        dateFrom: from,
        dateTo: to,
      );
      _cache[key] = _CachedItem(stats, DateTime.now());
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          stats: stats,
          errorMessage: null,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        );
      }
    }
  }

  /// 切换到「今日」
  void setRangeToday() {
    state = state.copyWith(rangeKind: DateRangeKind.today);
    load();
  }

  /// 切换到「本周」
  void setRangeThisWeek() {
    state = state.copyWith(rangeKind: DateRangeKind.thisWeek);
    load();
  }

  /// 切换到「本月」
  void setRangeThisMonth() {
    state = state.copyWith(rangeKind: DateRangeKind.thisMonth);
    load();
  }

  /// 设置自定义范围
  ///
  /// [from]/[to] 格式 yyyy-MM-dd。from > to 时静默忽略（前端已拦截）。
  void setCustomRange(String from, String to) {
    if (from.compareTo(to) > 0) return;
    state = state.copyWith(
      rangeKind: DateRangeKind.custom,
      dateFrom: from,
      dateTo: to,
    );
    load();
  }

  /// 下拉刷新（强制）
  Future<void> refresh() => load(force: true);
}

/// 个人统计 Provider
final personalStatsProvider =
    StateNotifierProvider<PersonalStatsNotifier, PersonalStatsState>((ref) {
  return PersonalStatsNotifier(ref);
});
