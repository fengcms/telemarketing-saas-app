import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'home/home_page.dart';
import 'leads/leads_list_page.dart';
import 'coming_soon_page.dart';
import '../providers/auth_provider.dart';

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
    final authState = ref.watch(authProvider);
    final user = authState.user;

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
          const ComingSoonPage(featureName: '日程管理'),
          _ProfileTab(
            userName: user?.name ?? '用户',
            userEmail: user?.email ?? '',
          ),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(TDIcons.home, size: 24),
            activeIcon: Icon(TDIcons.home, size: 24),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(TDIcons.view_list, size: 24),
            activeIcon: Icon(TDIcons.view_list, size: 24),
            label: '线索',
          ),
          BottomNavigationBarItem(
            icon: Icon(TDIcons.calendar, size: 24),
            activeIcon: Icon(TDIcons.calendar, size: 24),
            label: '日程',
          ),
          BottomNavigationBarItem(
            icon: Icon(TDIcons.user, size: 24),
            activeIcon: Icon(TDIcons.user, size: 24),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

/// 「我的」Tab（含退出登录）
class _ProfileTab extends ConsumerWidget {
  final String userName;
  final String userEmail;

  const _ProfileTab({
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: const Color(0xFF0052D9),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: Color(0xFF0052D9),
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              userEmail,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7A90)),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => _onLogout(context, ref),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('退出登录'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD54941),
                side: const BorderSide(color: Color(0xFFD54941)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onLogout(BuildContext context, WidgetRef ref) {
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
}
