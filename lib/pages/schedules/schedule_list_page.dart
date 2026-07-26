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
import 'package:telemarketing_app/theme/user_color.dart';
import 'package:telemarketing_app/theme/role_label.dart';
import 'package:telemarketing_app/models/schedule.dart';
import 'package:telemarketing_app/models/option_item.dart';
import 'package:telemarketing_app/providers/schedule_list_provider.dart';
import 'package:telemarketing_app/providers/schedule_stats_provider.dart';
import 'package:telemarketing_app/providers/options_provider.dart';
import 'widgets/schedule_card.dart';
import 'widgets/schedule_sticky_header.dart';
import 'widgets/schedule_skeleton.dart';
import 'widgets/team_schedule_header.dart';
import 'schedule_detail_page.dart';
import 'package:telemarketing_app/widgets/app_error_body.dart';
import 'package:telemarketing_app/widgets/app_empty_body.dart';
import 'package:telemarketing_app/widgets/app_segmented_tab.dart';
import 'package:telemarketing_app/widgets/app_scope_toggle.dart';
import 'package:telemarketing_app/widgets/app_sticky_header.dart';
import 'package:telemarketing_app/widgets/app_list_footer.dart';
import 'package:telemarketing_app/widgets/app_bottom_sheet.dart';
import 'schedule_grouping.dart';

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
          if (listState.scope == 'team') _buildTeamHeader(listState),
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

    final groups = groupSchedules(state.items, state.serverTime, state.activeTab);

    // 归属人姓名 + 颜色统一解析（按 userId 去重 watch，保留 id 兜底，避免每卡独立订阅）
    final ownerNames = <String, String>{};
    final ownerColors = <String, Color>{};
    for (final item in state.items) {
      final id = item.userId;
      if (id != null && id.isNotEmpty) {
        ownerNames[id] = ref.watch(userNameProvider(id)).value ?? id;
        ownerColors[id] = userColor(id);
      }
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(scheduleListProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: _buildSlivers(state, groups, ownerNames, ownerColors),
      ),
    );
  }

  /// 团队视图头部（仅 scope==team 渲染）：统计摘要条 + 员工筛选
  Widget _buildTeamHeader(ScheduleListState state) {
    final selectedId = state.selectedOwnerId;
    final int todayPending;
    final int overdue;
    final String ownerLabel;
    final Color? ownerColor;
    if (selectedId != null) {
      // 成员筛选中：本地从已加载成员列表计算（后端 userId 过滤后 items 即该成员）
      todayPending = _countTodayPending(state.items, state.serverTime);
      overdue = _countOverdue(state.items, state.serverTime);
      ownerLabel = ref.read(userNameProvider(selectedId)).value ?? selectedId;
      ownerColor = userColor(selectedId);
    } else {
      // 全团队：读团队统计接口（与首页/home-summary 同源）
      todayPending = state.teamStats?.todayPending ?? 0;
      overdue = state.teamStats?.overdue ?? 0;
      ownerLabel = '全部成员';
      ownerColor = null;
    }
    return TeamScheduleHeader(
      todayPending: todayPending,
      overdue: overdue,
      ownerLabel: ownerLabel,
      ownerColor: ownerColor,
      onPickOwner: _pickOwner,
    );
  }

  /// 打开员工筛选底部抽屉（成员列表来自 options 缓存）
  Future<void> _pickOwner() async {
    final users = await ref.read(optionsCacheProvider).getUsers();
    if (!mounted) return;
    final selected = ref.read(scheduleListProvider).selectedOwnerId;
    final result = await AppBottomSheet.show<String?>(
      context: context,
      title: '选择员工',
      child: _OwnerSheetContent(
        users: users,
        selectedId: selected,
        onSelect: (id) => Navigator.of(context).pop(id),
      ),
    );
    if (!mounted) return;
    ref.read(scheduleListProvider.notifier).selectOwner(result);
  }

  List<Widget> _buildSlivers(
    ScheduleListState state,
    List<ScheduleGroup> groups,
    Map<String, String> ownerNames,
    Map<String, Color> ownerColors,
  ) {
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
              ownerName: ownerNames[g.items[i].userId],
              ownerColor: ownerColors[g.items[i].userId],
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

  /// 本地统计：今日待办数（严格今日窗口、不含逾期，与后端 todayPending 同源）
  int _countTodayPending(List<Schedule> items, int serverTime) {
    final base = DateTime.fromMillisecondsSinceEpoch(serverTime * 1000);
    var n = 0;
    for (final s in items) {
      if (s.status != 'pending') continue;
      if (s.scheduledAt < serverTime) continue; // 已逾期不计入今日待办
      final dt = DateTime.fromMillisecondsSinceEpoch(s.scheduledAt * 1000);
      if (dt.year == base.year && dt.month == base.month && dt.day == base.day) {
        n++;
      }
    }
    return n;
  }

  /// 本地统计：逾期数（pending 且 scheduledAt < 服务端时间）
  int _countOverdue(List<Schedule> items, int serverTime) {
    var n = 0;
    for (final s in items) {
      if (s.status == 'pending' && s.scheduledAt < serverTime) n++;
    }
    return n;
  }
}

/// 员工筛选抽屉内容
class _OwnerSheetContent extends StatelessWidget {
  final List<OptionItem> users;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  const _OwnerSheetContent({
    required this.users,
    this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MemberTile(
          label: '全部成员',
          color: const Color(0xFF9E9E9E),
          selected: selectedId == null,
          onTap: () => onSelect(null),
        ),
        ...users.map(
          (u) => _MemberTile(
            label: u.name,
            color: userColor(u.id),
            role: roleLabel(u.role),
            selected: selectedId == u.id,
            onTap: () => onSelect(u.id),
          ),
        ),
      ],
    );
  }
}

/// 成员列表项（颜色圆点 + 姓名 + 选中勾）
class _MemberTile extends StatelessWidget {
  final String label;
  final Color color;
  final String? role;
  final bool selected;
  final VoidCallback onTap;

  const _MemberTile({
    required this.label,
    required this.color,
    this.role,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showRole = role != null && role!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 16, color: BrandColors.textPrimary),
                  ),
                  if (showRole) ...[
                    const SizedBox(width: 8),
                    Text(
                      role!,
                      style: const TextStyle(fontSize: 12, color: BrandColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 18, color: BrandColors.primary),
          ],
        ),
      ),
    );
  }
}
