import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../models/home_stats.dart';
import '../../models/schedule.dart';
import '../coming_soon_page.dart';

/// 首页看板
///
/// APP 默认首屏页面（底部 Tab 1），聚合展示：
/// - 今日工作概况（2x2 统计四宫格）
/// - 待办日程预览（最多 5 条）
/// - 快捷入口（我的线索、通话记录）
///
/// [onSwitchTab] 切换底部 Tab 回调（由 MainShell 传入）。
///
/// 设计文档参考：docs/design/page-design/03-首页看板.md
class HomePage extends ConsumerStatefulWidget {
  final void Function(int tabIndex)? onSwitchTab;

  const HomePage({super.key, this.onSwitchTab});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  StreamSubscription? _connectivitySubscription;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupConnectivity();
    _hasInitialized = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // ── 生命周期监听 ──

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(homePageProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      notifier.onResume();
    } else if (state == AppLifecycleState.paused) {
      notifier.onPause();
    }
  }

  // ── 网络状态监听 ──

  void _setupConnectivity() {
    final notifier = ref.read(homePageProvider.notifier);

    // 初始检测
    Connectivity().checkConnectivity().then((result) {
      if (mounted) {
        notifier.setOffline(result.contains(ConnectivityResult.none));
      }
    });

    // 持续监听
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) {
        notifier.setOffline(result.contains(ConnectivityResult.none));
      }
    });
  }

  /// 退出登录
  void _onLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('退出', style: TextStyle(color: Color(0xFFD54941))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homePageProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            _buildNavBar(user?.role ?? ''),
            if (homeState.isOffline) _buildOfflineBanner(),
            if (homeState.shouldShowDueSoonBanner) _buildDueSoonBanner(),
            Expanded(
              child: _buildBody(homeState),
            ),
          ],
        ),
      ),
    );
  }

  // ── TDNavBar ──

  Widget _buildNavBar(String role) {
    final isManager = role == 'tenant_admin' || role == 'tenant_manager';
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
              '首页',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          if (isManager)
            GestureDetector(
              onTap: () {
                // 团队看板 — 待开发
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ComingSoonPage(
                        featureName: '团队看板'),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text(
                  '团队看板',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          // 退出按钮（MVP 测试用）
          GestureDetector(
            onTap: () => _onLogout(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                '退出',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ── 顶部提示条 ──

  Widget _buildOfflineBanner() {
    return _buildNoticeBar(
      icon: TDIcons.error_circle,
      iconColor: const Color(0xFFE37318),
      bgColor: const Color(0xFFFFF3E0),
      textColor: const Color(0xFFE37318),
      text: '当前处于离线状态，数据可能不及时',
    );
  }

  Widget _buildDueSoonBanner() {
    final homeState = ref.read(homePageProvider);
    return _buildNoticeBar(
      icon: Icons.access_time,
      iconColor: const Color(0xFF0052D9),
      bgColor: const Color(0xFFE0EAFF),
      textColor: const Color(0xFF0052D9),
      text: '您有 ${homeState.dueSoonCount} 条日程即将到期',
      closable: true,
      onClose: () =>
          ref.read(homePageProvider.notifier).closeDueSoonBanner(),
      onTap: () {
        // 跳转日程 Tab — 待实现 Tab 切换机制后完善
      },
    );
  }

  Widget _buildNoticeBar({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color textColor,
    required String text,
    bool closable = false,
    VoidCallback? onClose,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 13, color: textColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (closable)
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  child:
                      const Icon(TDIcons.close, size: 16, color: Color(0xFF0052D9)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── 页面主体 ──

  Widget _buildBody(HomePageState state) {
    if (state.isInitialLoading) {
      return const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _SkeletonSection(),
              SizedBox(height: 16),
              _SkeletonSection(isSchedule: true),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(homePageProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            _buildTodayStatsSection(state),
            const SizedBox(height: 16),
            _buildScheduleSection(state),
            const SizedBox(height: 16),
            _buildQuickEntrySection(state),
          ],
        ),
      ),
    );
  }

  // ── 今日概况 Section ──

  Widget _buildTodayStatsSection(HomePageState state) {
    final today = DateTime.now();
    final weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dateLabel =
        '${today.month}月${today.day}日 ${weekDays[today.weekday - 1]}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '今日工作概况',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181818),
                  ),
                ),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFC5C5C5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.isLoadingStats && state.stats == null)
              _buildStatsGrid(null, state)
            else if (state.statsError != null && state.stats == null)
              _buildErrorRetry(state.statsError!, () {
                ref.read(homePageProvider.notifier).retryStats();
              })
            else
              _buildStatsGrid(state.stats, state),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(HomeStats? stats, HomePageState state) {
    if (state.isLoadingStats && stats == null) {
      return const Row(
        children: [
          Expanded(child: _SkeletonStatCard()),
          SizedBox(width: 12),
          Expanded(child: _SkeletonStatCard()),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    value: stats?.dueToday ?? 0, label: '今日待办')),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    value: stats?.followupCount ?? 0, label: '今日跟进')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    value: stats?.answeredCount ?? 0, label: '今日接通')),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    value: stats?.myLeadsTotal ?? 0, label: '我的线索')),
          ],
        ),
      ],
    );
  }

  // ── 待办日程 Section ──

  Widget _buildScheduleSection(HomePageState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Text(
                  '待办日程',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181818),
                  ),
                ),
                if ((state.stats?.dueToday ?? 0) > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0052D9),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${state.stats?.dueToday ?? 0}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    widget.onSwitchTab?.call(2); // 切换到日程 Tab
                  },
                  child: const Text(
                    '查看全部 >',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0052D9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (state.isLoadingSchedules && state.schedules == null)
            ...List.generate(
              3,
              (_) => const _SkeletonScheduleCard(),
            )
          else if (state.schedulesError != null && state.schedules == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildErrorRetry(state.schedulesError!, () {
                ref.read(homePageProvider.notifier).retrySchedules();
              }),
            )
          else if (state.schedules == null || state.schedules!.isEmpty)
            _buildEmptySchedule()
          else
            ...state.schedules!.asMap().entries.map(
                  (entry) => _buildScheduleItem(
                    entry.value,
                    isLast: entry.key == state.schedules!.length - 1,
                    serverTime: state.serverTime > 0
                        ? state.serverTime
                        : DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  ),
                ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(Schedule schedule,
      {required bool isLast, required int serverTime}) {
    final overdue = schedule.isOverdue(serverTime);
    return GestureDetector(
      onTap: () {
        // 跳转日程详情 — 待开发
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 16),
            SizedBox(
              width: 44,
              child: Text(
                schedule.timeDisplay,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: overdue
                      ? const Color(0xFFD54941)
                      : const Color(0xFF3C3C3C),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.title,
                    style: TextStyle(
                      fontSize: 15,
                      color: overdue
                          ? const Color(0xFFD54941)
                          : const Color(0xFF181818),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '线索：${schedule.leadName ?? "无"}',
                    style: TextStyle(
                      fontSize: 13,
                      color: overdue
                          ? const Color(0xFFF9B1B1)
                          : const Color(0xFFA6A6A6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (overdue)
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '已逾期',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFD54941),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySchedule() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_note, size: 64, color: Color(0xFFDCDCDC)),
            SizedBox(height: 12),
            Text(
              '暂无待办日程',
              style: TextStyle(fontSize: 15, color: Color(0xFFC5C5C5)),
            ),
            SizedBox(height: 4),
            Text(
              '完成当前线索跟进后可预约下次跟进',
              style: TextStyle(fontSize: 13, color: Color(0xFFDCDCDC)),
            ),
          ],
        ),
      ),
    );
  }

  // ── 快捷入口 Section ──

  Widget _buildQuickEntrySection(HomePageState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '快捷入口',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF181818),
              ),
            ),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickEntryCard(
                      icon: TDIcons.task,
                      title: '我的线索',
                    subtitle: state.stats != null
                        ? '${state.stats!.myLeadsTotal} 条'
                        : null,
                    onTap: () {
                      widget.onSwitchTab?.call(1); // 切换到线索 Tab
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickEntryCard(
                    icon: TDIcons.call,
                    title: '通话记录',
                    subtitle: null,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const ComingSoonPage(featureName: '通话记录'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickEntryCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF0052D9)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3C3C3C),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFC5C5C5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── 错误 + 重试 ──

  Widget _buildErrorRetry(String error, VoidCallback onRetry) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(TDIcons.error_circle,
                size: 16, color: Color(0xFFD54941)),
            const SizedBox(width: 6),
            Text(
              error,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFFD54941)),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onRetry,
              child: const Text(
                '重试',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0052D9),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── 统计卡片 ──

/// 单个统计数字卡片
class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final displayValue = value >= 1000 ? '999+' : value.toString();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0052D9),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFA6A6A6),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 骨架屏组件 ──

class _SkeletonSection extends StatelessWidget {
  final bool isSchedule;
  const _SkeletonSection({this.isSchedule = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isSchedule ? 100 : 140,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E7E7),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            if (isSchedule) ...[
              const _SkeletonScheduleCard(),
              const _SkeletonScheduleCard(),
              const _SkeletonScheduleCard(),
            ] else ...[
              const Row(
                children: [
                  Expanded(child: _SkeletonStatCard()),
                  SizedBox(width: 12),
                  Expanded(child: _SkeletonStatCard()),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(child: _SkeletonStatCard()),
                  SizedBox(width: 12),
                  Expanded(child: _SkeletonStatCard()),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonStatCard extends StatelessWidget {
  const _SkeletonStatCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          _SkeletonBlock(width: 48, height: 32),
          SizedBox(height: 8),
          _SkeletonBlock(width: 64, height: 14),
        ],
      ),
    );
  }
}

class _SkeletonScheduleCard extends StatelessWidget {
  const _SkeletonScheduleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const _SkeletonBlock(width: 44, height: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SkeletonBlock(width: 160, height: 16),
                const SizedBox(height: 8),
                _SkeletonBlock(width: 100, height: 14),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonBlock({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE7E7E7),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
