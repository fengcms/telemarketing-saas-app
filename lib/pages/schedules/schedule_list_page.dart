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
import 'package:telemarketing_app/theme/color_scheme.dart';
import 'package:telemarketing_app/models/schedule.dart';
import 'package:telemarketing_app/providers/schedule_list_provider.dart';
import 'package:telemarketing_app/providers/schedule_stats_provider.dart';
import 'widgets/schedule_card.dart';
import 'widgets/schedule_sticky_header.dart';
import 'widgets/schedule_skeleton.dart';
import 'schedule_detail_page.dart';
import 'package:telemarketing_app/widgets/app_error_body.dart';
import 'package:telemarketing_app/widgets/app_empty_body.dart';
import 'package:telemarketing_app/widgets/app_segmented_tab.dart';
import 'package:telemarketing_app/widgets/app_scope_toggle.dart';
import 'package:telemarketing_app/widgets/app_sticky_header.dart';
import 'package:telemarketing_app/widgets/app_list_footer.dart';

part 'schedule_grouping.dart';

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
      backgroundColor: BrandColors.surface,
      appBar: AppBar(
        title: const Text('日程'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (canTeam)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AppScopeToggle(
                options: const [
                  ScopeOption('mine', '我的'),
                  ScopeOption('team', '团队'),
                ],
                currentValue: listState.scope,
                onChanged: (v) =>
                    ref.read(scheduleListProvider.notifier).switchScope(v),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(listState, statsState),
          Expanded(child: _buildBody(listState)),
        ],
      ),
    );
  }

  // ── Tab 栏 ──

  Widget _buildTabBar(ScheduleListState state, ScheduleStatsState stats) {
    return AppSegmentedTab(
      tabs: [
        SegmentedTabItem(key: 'pending', label: '待办', count: stats.pending),
        SegmentedTabItem(key: 'completed', label: '已完成', count: stats.completed),
      ],
      activeKey: state.activeTab,
      onChanged: (k) => ref.read(scheduleListProvider.notifier).switchTab(k),
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

    final groups = _groupSchedules(state.items, state.serverTime, state.activeTab);

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
          delegate: FixedStickyHeaderDelegate(
            height: 40,
            child: g.isOverdue
                ? ScheduleStickyHeader(
                    title: '已逾期 (${g.items.length})',
                    icon: Icons.error_outline,
                    iconColor: BrandColors.error,
                    onTap: () => _scrollToGroup(g.key),
                  )
                : ScheduleStickyHeader(
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

    slivers.add(
      SliverToBoxAdapter(
        child: AppListFooter(
          isLoadingMore: state.isLoadingMore,
          hasMore: state.hasMore,
        ),
      ),
    );
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
          AppErrorBody(
            icon: Icons.error_outline,
            iconSize: 80,
            iconColor: const Color(0xFFDCDCDC),
            title: '加载失败',
            message: message,
            messageColor: BrandColors.textSecondary,
            actionText: '重新加载',
            onAction: () =>
                ref.read(scheduleListProvider.notifier).refresh(),
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
          AppEmptyBody(
            icon: Icons.event_note,
            title: isPending ? '暂无待办日程' : '暂无已完成日程',
            desc: isPending
                ? '点击底部「+」或卡片「跟进」新建日程'
                : '完成的日程会显示在这里',
          ),
        ],
      ),
    );
  }

}
