/// 当前选中的底部 Tab 索引
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'home/home_page.dart';
import 'leads/leads_list_page.dart';
import 'profile/profile_page.dart';
import 'schedules/schedule_list_page.dart';
import 'package:telemarketing_app/providers/schedule_stats_provider.dart';

/// 当前选中的底部 Tab 索引
final currentTabProvider = StateProvider<int>((ref) => 0);

/// 主页面壳（底部 Tab 导航）
///
/// 包含 4 个底部 Tab：
/// 0: 首页 | 1: 线索 | 2: 日程 | 3: 我的
///
/// 子页面通过 [switchToTab] 切换 Tab。
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);

    /// 切换 Tab 回调（供 HomePage 调用）
    void switchTab(int index) {
      ref.read(currentTabProvider.notifier).state = index;
    }

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: [
          HomePage(onSwitchTab: switchTab),
          const LeadsListPage(),
          const ScheduleListPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(currentTab, ref),
    );
  }

  Widget _buildBottomNav(int currentTab, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentTab,
        onTap: (index) => ref.read(currentTabProvider.notifier).state = index,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0052D9),
        unselectedItemColor: const Color(0xFFA6A6A6),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(TDIcons.home, size: 24),
            activeIcon: Icon(TDIcons.home, size: 24),
            label: '首页',
          ),
          const BottomNavigationBarItem(
            icon: Icon(TDIcons.view_list, size: 24),
            activeIcon: Icon(TDIcons.view_list, size: 24),
            label: '线索',
          ),
          BottomNavigationBarItem(
            icon: _scheduleBadge(ref, false),
            activeIcon: _scheduleBadge(ref, true),
            label: '日程',
          ),
          const BottomNavigationBarItem(
            icon: Icon(TDIcons.user, size: 24),
            activeIcon: Icon(TDIcons.user, size: 24),
            label: '我的',
          ),
        ],
      ),
    );
  }
  /// 日程 Tab 角标：展示今日待办数（dueToday）
  /// 数据来自共享的 [scheduleStatsProvider]，与日程列表页 Tab 计数同源。
  Widget _scheduleBadge(WidgetRef ref, bool active) {
    final dueToday = ref.watch(scheduleStatsProvider).dueToday;
    return Badge(
      isLabelVisible: dueToday > 0,
      label: Text('$dueToday'),
      child: Icon(
        TDIcons.calendar,
        size: 24,
        color: active ? const Color(0xFF0052D9) : const Color(0xFFA6A6A6),
      ),
    );
  }
}
