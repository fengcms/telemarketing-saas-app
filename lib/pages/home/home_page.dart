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
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:telemarketing_app/widgets/app_notice_bar.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';
import 'package:telemarketing_app/providers/home_provider.dart';
import 'package:telemarketing_app/providers/tab_provider.dart';
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
      // 仅在首页是当前 Tab 时才刷新，避免在其他页面（如线索详情拨号）前后台切换时
      // 无谓请求 stats/mine 与 home-summary
      if (ref.read(currentTabProvider) == 0) {
        notifier.onResume();
      }
    } else if (state == AppLifecycleState.paused) {
      // 进入后台统一暂停轮询（与当前 Tab 无关，暂停无害）
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

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homePageProvider);

    // 切回首页 Tab 时主动刷新（替代原先依赖全局 resumed 的那次刷新）
    ref.listen(currentTabProvider, (prev, next) {
      if (next == 0) {
        ref.read(homePageProvider.notifier).onResume();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        title: const Text('首页'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (homeState.isOffline)
            AppNoticeBar.warning(
              text: '当前处于离线状态，数据可能不及时',
            ),
          if (homeState.shouldShowDueSoonBanner)
            AppNoticeBar.info(
              text: '您有 ${homeState.dueSoonCount} 条日程即将到期',
              closable: true,
              onClose: () =>
                  ref.read(homePageProvider.notifier).closeDueSoonBanner(),
              onTap: () {
                // 跳转日程 Tab
              },
            ),
          Expanded(child: _buildBody(homeState)),
        ],
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

