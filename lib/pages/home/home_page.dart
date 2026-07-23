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
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../coming_soon_page.dart';
import 'home_skeletons.dart';
import 'home_stats_section.dart';
import 'home_schedule_section.dart';
import 'home_quick_entry_section.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupConnectivity();
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
              SkeletonSection(),
              SizedBox(height: 16),
              SkeletonSection(isSchedule: true),
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
            HomeStatsSection(state: state),
            const SizedBox(height: 16),
            HomeScheduleSection(
              state: state,
              onViewAll: () => widget.onSwitchTab?.call(2),
            ),
            const SizedBox(height: 16),
            HomeQuickEntrySection(
              state: state,
              onSwitchToLeads: () => widget.onSwitchTab?.call(1),
            ),
          ],
        ),
      ),
    );
  }
}

