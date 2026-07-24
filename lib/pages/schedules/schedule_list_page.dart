/// 日程列表页
///
/// 设计文档：docs/design/page-design/10-日程列表.md
/// - 待办 / 已完成 双 Tab（计数来自共享统计）
/// - TM/TA 可切换 我的 / 团队
/// - 列表按语义桶分组（已逾期/今天/明天/后天/本周/下周/更晚）+ 逾期置顶，日期头与逾期头吸顶
/// - 下拉刷新（同时刷新统计角标）/ 上拉加载更多
/// - 点击卡片跳转详情页（doc 11，下一节点 v0.13 落地，暂留入口）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/schedule.dart';
import 'package:telemarketing_app/providers/schedule_list_provider.dart';
import 'package:telemarketing_app/providers/schedule_stats_provider.dart';
import 'widgets/schedule_card.dart';
import 'widgets/schedule_date_header.dart';
import 'widgets/schedule_overdue_header.dart';
import 'widgets/schedule_skeleton.dart';
import 'schedule_detail_page.dart';

/// 日程列表页
class ScheduleListPage extends ConsumerStatefulWidget {
  const ScheduleListPage({super.key});

  @override
  ConsumerState<ScheduleListPage> createState() => _ScheduleListPageState();
}

class _ScheduleListPageState extends ConsumerState<ScheduleListPage> {
  final ScrollController _scrollCtrl = ScrollController();

  /// 各分组吸顶头的滚动定位锚点（按 group.key 复用，跨 rebuild 稳定）
  final Map<String, GlobalKey> _groupKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(scheduleListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(scheduleListProvider);
    final statsState = ref.watch(scheduleStatsProvider);
    final canTeam =
        ref.read(scheduleListProvider.notifier).canSwitchScope;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(listState, canTeam),
            _buildTabBar(listState, statsState),
            Expanded(child: _buildBody(listState)),
          ],
        ),
      ),
    );
  }

  // ── 顶部导航栏 ──

  Widget _buildTopBar(ScheduleListState state, bool canTeam) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFF0052D9),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              '日程',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          if (canTeam)
            GestureDetector(
              onTap: () {
                final next =
                    state.scope == 'mine' ? 'team' : 'mine';
                ref.read(scheduleListProvider.notifier).switchScope(next);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  state.scope == 'mine' ? '我的' : '团队',
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
            ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  // ── Tab 栏 ──

  Widget _buildTabBar(ScheduleListState state, ScheduleStatsState stats) {
    return Container(
      color: Colors.white,
      height: 48,
      child: Row(
        children: [
          _tabItem(state, stats, 'pending', '待办', stats.pending),
          _tabItem(state, stats, 'completed', '已完成', stats.completed),
        ],
      ),
    );
  }

  Widget _tabItem(
    ScheduleListState state,
    ScheduleStatsState stats,
    String tab,
    String label,
    int count,
  ) {
    final active = state.activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(scheduleListProvider.notifier).switchTab(tab),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    color: active
                        ? const Color(0xFF0052D9)
                        : const Color(0xFF6B7A90),
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF0052D9)
                          : const Color(0xFFA6A6A6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: 2,
              width: 28,
              color: active ? const Color(0xFF0052D9) : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  // ── 主体 ──

  Widget _buildBody(ScheduleListState state) {
    // 首屏加载 或 下拉刷新中：骨架屏占位，避免旧数据闪现
    if (state.isInitialLoading || state.isRefreshing) {
      return _buildSkeleton();
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return _buildError(state.errorMessage!);
    }

    if (state.items.isEmpty) return _buildEmpty(state.activeTab);

    final groups = _group(state.items, state.serverTime, state.activeTab);

    return RefreshIndicator(
      onRefresh: () => ref.read(scheduleListProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: _buildSlivers(state, groups),
      ),
    );
  }

  List<Widget> _buildSlivers(ScheduleListState state, List<_Group> groups) {
    final slivers = <Widget>[];
    for (final g in groups) {
      final anchorKey = _groupKey(g.key);
      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            height: 40,
            child: g.isOverdue
                ? ScheduleOverdueHeader(
                    count: g.items.length,
                    onTap: () => _scrollToGroup(g.key),
                  )
                : ScheduleDateHeader(
                    title: g.title,
                    onTap: () => _scrollToGroup(g.key),
                  ),
          ),
        ),
      );
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => ScheduleCard(
              key: i == 0 ? anchorKey : null,
              schedule: g.items[i],
              serverTime: state.serverTime,
              onTap: () => _onTapSchedule(g.items[i]),
            ),
            childCount: g.items.length,
          ),
        ),
      );
    }

    if (state.isLoadingMore) {
      slivers.add(
        const SliverToBoxAdapter(
          child: SizedBox(
            height: 56,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      );
    } else if (!state.hasMore && state.items.isNotEmpty) {
      slivers.add(
        const SliverToBoxAdapter(
          child: SizedBox(
            height: 48,
            child: Center(
              child: Text(
                '— 已加载全部 —',
                style: TextStyle(fontSize: 12, color: Color(0x99C5C5C5)),
              ),
            ),
          ),
        ),
      );
    } else {
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
    }
    return slivers;
  }

  void _onTapSchedule(Schedule s) {
    // 跳日程详情页（doc 11）
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleDetailPage(scheduleId: s.id),
      ),
    );
  }

  // ── 骨架屏（待办 / 已完成 共用） ──

  Widget _buildSkeleton() => const ScheduleSkeleton();

  /// 取分组的滚动锚点 GlobalKey（按 group.key 复用，跨 rebuild 稳定）
  GlobalKey _groupKey(String gKey) =>
      _groupKeys.putIfAbsent(gKey, GlobalKey.new);

  /// 点击吸顶头 → 平滑滚动到该分组（标题吸顶、卡片紧随其后）
  void _scrollToGroup(String gKey) {
    final ctx = _groupKeys[gKey]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.08, // 距顶约 40px，正落在吸顶头下方
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ── 错误态 ──

  Widget _buildError(String message) {
    return RefreshIndicator(
      onRefresh: () => ref.read(scheduleListProvider.notifier).refresh(),
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          const Icon(Icons.error_outline, size: 80, color: Color(0xFFDCDCDC)),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              '加载失败',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF181818),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, color: Color(0xFFA6A6A6)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () =>
                  ref.read(scheduleListProvider.notifier).refresh(),
              child: const Text(
                '重新加载',
                style: TextStyle(color: Color(0xFF0052D9)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 空态 ──

  Widget _buildEmpty(String tab) {
    final isPending = tab == 'pending';
    return RefreshIndicator(
      onRefresh: () => ref.read(scheduleListProvider.notifier).refresh(),
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          const Icon(Icons.event_note, size: 80, color: Color(0xFFDCDCDC)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              isPending ? '暂无待办日程' : '暂无已完成日程',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF181818),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              isPending ? '点击底部「+」或卡片「跟进」新建日程' : '完成的日程会显示在这里',
              style: const TextStyle(fontSize: 14, color: Color(0xFFA6A6A6)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 分组算法 ──

  /// 纯前端分组：语义桶模型（每个类别仅一个分组头，标签不会重复）。
  ///
  /// 待办 Tab（逾期置顶）：已逾期 → 今天 → 明天 → 后天 → 本周 → 下周 → 更晚
  /// 已完成 Tab（过去侧镜像）：今天 → 昨天 → 本周 → 上周 → 更早
  ///
  /// 周起点取周一（国内习惯）；下周之后统一归入「更晚」。
  /// 卡片本身已显示完整日期（YYYY-MM-DD HH:mm），按天分头无额外信息，
  /// 改语义桶可消除「两个本周/下周」这类同名头。
  ///
  /// 注意：日期标签基于设备本地时间计算，跨天不会自动重算，
  /// 需下拉刷新或重建才会更新（跨天重算机制见开发文档，标记为待开发）。
  List<_Group> _group(List<Schedule> items, int serverTime, String tab) {
    final order = <String, int>{};
    final buckets = <String, List<Schedule>>{};
    for (final s in items) {
      final key = _bucketKey(s, serverTime, tab);
      order[key] = _bucketOrder(key, tab);
      buckets.putIfAbsent(key, () => []).add(s);
    }
    final sortedKeys = buckets.keys.toList()
      ..sort((a, b) => order[a]!.compareTo(order[b]!));
    return sortedKeys.map((k) {
      final list = buckets[k]!
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return _Group(
        key: k,
        title: _bucketTitle(k),
        isOverdue: k == 'overdue',
        items: list,
      );
    }).toList();
  }

  /// 计算一条日程归属的语义桶 key
  String _bucketKey(Schedule s, int serverTime, String tab) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dt = DateTime.fromMillisecondsSinceEpoch(s.scheduledAt * 1000);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = day.difference(today).inDays;

    if (tab == 'pending') {
      if (s.isOverdue(serverTime)) return 'overdue';
      if (diff == 0) return 'today';
      if (diff == 1) return 'tomorrow';
      if (diff == 2) return 'day_after';
    } else {
      if (diff == 0) return 'today';
      if (diff == -1) return 'yesterday';
    }

    // 周边界（周一为一周起点）
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final thisSunday = monday.add(const Duration(days: 6));
    final nextMonday = monday.add(const Duration(days: 7));
    final nextSunday = nextMonday.add(const Duration(days: 6));
    final lastMonday = monday.subtract(const Duration(days: 7));

    if (tab == 'pending') {
      if (!day.isBefore(monday) && !day.isAfter(thisSunday)) return 'this_week';
      if (!day.isBefore(nextMonday) && !day.isAfter(nextSunday)) {
        return 'next_week';
      }
      return 'later';
    } else {
      // 已完成：本周更早的天 / 上周 / 更早
      if (!day.isBefore(monday) && day.isBefore(today)) return 'this_week';
      if (!day.isBefore(lastMonday) && day.isBefore(monday)) {
        return 'last_week';
      }
      return 'earlier';
    }
  }

  /// 桶的排序权重（数值越小越靠上）
  int _bucketOrder(String key, String tab) {
    const pendingOrder = <String, int>{
      'overdue': 0,
      'today': 1,
      'tomorrow': 2,
      'day_after': 3,
      'this_week': 4,
      'next_week': 5,
      'later': 6,
    };
    const doneOrder = <String, int>{
      'today': 0,
      'yesterday': 1,
      'this_week': 2,
      'last_week': 3,
      'earlier': 4,
    };
    return (tab == 'pending' ? pendingOrder : doneOrder)[key] ?? 99;
  }

  /// 桶标题
  String _bucketTitle(String key) {
    switch (key) {
      case 'overdue':
        return '已逾期';
      case 'today':
        return '今天';
      case 'tomorrow':
        return '明天';
      case 'day_after':
        return '后天';
      case 'this_week':
        return '本周';
      case 'next_week':
        return '下周';
      case 'later':
        return '更晚';
      case 'yesterday':
        return '昨天';
      case 'last_week':
        return '上周';
      case 'earlier':
        return '更早';
      default:
        return key;
    }
  }
}

/// 分组数据
class _Group {
  final String key;
  final String title;
  final bool isOverdue;
  final List<Schedule> items;

  _Group({
    required this.key,
    required this.title,
    required this.isOverdue,
    required this.items,
  });
}

/// 吸顶头部委托
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _StickyHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      child;

  @override
  bool shouldRebuild(_StickyHeaderDelegate old) => false;
}
