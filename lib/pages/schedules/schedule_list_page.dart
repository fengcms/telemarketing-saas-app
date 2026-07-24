/// 日程列表页
///
/// 设计文档：docs/design/page-design/10-日程列表.md
/// - 待办 / 已完成 双 Tab（计数来自共享统计）
/// - TM/TA 可切换 我的 / 团队
/// - 列表按日期分组 + 逾期置顶，日期头与逾期头吸顶
/// - 下拉刷新（同时刷新统计角标）/ 上拉加载更多
/// - 点击卡片跳转详情页（doc 11，下一节点 v0.13 落地，暂留入口）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/schedule.dart';
import 'package:telemarketing_app/pages/coming_soon_page.dart';
import 'package:telemarketing_app/providers/schedule_list_provider.dart';
import 'package:telemarketing_app/providers/schedule_stats_provider.dart';
import 'widgets/schedule_card.dart';
import 'widgets/schedule_date_header.dart';
import 'widgets/schedule_overdue_header.dart';

/// 日程列表页
class ScheduleListPage extends ConsumerStatefulWidget {
  const ScheduleListPage({super.key});

  @override
  ConsumerState<ScheduleListPage> createState() => _ScheduleListPageState();
}

class _ScheduleListPageState extends ConsumerState<ScheduleListPage> {
  final ScrollController _scrollCtrl = ScrollController();

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
    if (state.isInitialLoading) return _buildSkeleton();

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
      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            height: 40,
            child: g.isOverdue
                ? ScheduleOverdueHeader(count: g.items.length)
                : ScheduleDateHeader(title: g.title),
          ),
        ),
      );
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => ScheduleCard(
              schedule: g.items[i],
              serverTime: state.serverTime,
              onTap: _onTapSchedule,
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

  void _onTapSchedule() {
    // 详情页（doc 11）拆为下一节点 v0.13，暂留入口
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ComingSoonPage(featureName: '日程详情'),
      ),
    );
  }

  // ── 骨架屏 ──

  Widget _buildSkeleton() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 96,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
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

  /// 纯前端分组：[逾期] 置顶（仅待办 Tab）→ 按日期分桶（今天/明天/后天/本周/更早）
  ///
  /// 注意：日期标签基于设备本地时间计算，跨天不会自动重算，
  /// 需下拉刷新或重建才会更新（跨天重算机制见开发文档，标记为待开发）。
  List<_Group> _group(List<Schedule> items, int serverTime, String tab) {
    if (tab == 'pending') {
      final overdue = items
          .where((s) => s.isOverdue(serverTime))
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      final normal =
          items.where((s) => !s.isOverdue(serverTime)).toList();
      final groups = <_Group>[];
      if (overdue.isNotEmpty) {
        groups.add(_Group(
          key: 'overdue',
          title: '已逾期 (${overdue.length})',
          isOverdue: true,
          items: overdue,
        ));
      }
      groups.addAll(_dateGroups(normal));
      return groups;
    }
    return _dateGroups(items);
  }

  List<_Group> _dateGroups(List<Schedule> items) {
    final buckets = <String, List<Schedule>>{};
    for (final s in items) {
      final key = _dateKey(s.scheduledAt);
      buckets.putIfAbsent(key, () => []).add(s);
    }
    final keys = buckets.keys.toList()
      ..sort((a, b) => _keyTime(a).compareTo(_keyTime(b)));
    return keys.map((k) {
      final list = buckets[k]!
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return _Group(
        key: k,
        title: _dateTitle(k),
        isOverdue: false,
        items: list,
      );
    }).toList();
  }

  String _dateKey(int scheduledAt) {
    final dt = DateTime.fromMillisecondsSinceEpoch(scheduledAt * 1000);
    return '${dt.year}-${dt.month}-${dt.day}';
  }

  int _keyTime(String k) {
    final p = k.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]).millisecondsSinceEpoch ~/ 1000;
  }

  String _dateTitle(String key) {
    final dt = DateTime.parse(key);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = dt.difference(today).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '明天';
    if (diff == 2) return '后天';
    if (diff > 2 && diff < 8) return '本周';
    if (diff == -1) return '昨天';
    return '更早';
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
