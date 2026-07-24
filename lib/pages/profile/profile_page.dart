/// 个人中心页（"我的" Tab）
///
/// 设计文档：docs/design/page-design/13-个人中心.md
/// 展示当前登录用户的基本信息、个人业绩概览、功能入口与团队入口。
/// 子页（通话记录/客户列表/设置/团队统计/个人统计）本轮未开发，
/// 入口统一跳转 [ComingSoonPage] 占位，后续迭代替换。
///
/// 数据来源：
/// - 用户信息：authProvider（本地缓存，来自登录响应）
/// - 所属租户：tenantService.fetchTenantName()（GET /api/tenant/profile）
/// - 业绩概览：homeService.fetchMyStats(today)（GET /api/tenant/stats/mine）
/// - 今日待办：共享 scheduleStatsProvider.dueToday（GET /api/tenant/schedules/stats/mine）
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/home_stats.dart';
import 'package:telemarketing_app/pages/coming_soon_page.dart';
import 'package:telemarketing_app/pages/call_records/call_records_page.dart';
import 'package:telemarketing_app/pages/profile/widgets/profile_menu_row.dart';
import 'package:telemarketing_app/pages/profile/widgets/profile_stats_card.dart';
import 'package:telemarketing_app/pages/profile/widgets/profile_user_card.dart';
import 'package:telemarketing_app/pages/schedules/widgets/schedule_skeleton.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'package:telemarketing_app/providers/home_provider.dart';
import 'package:telemarketing_app/providers/schedule_stats_provider.dart';

// ── 颜色常量（对齐 TDesign 设计规范）──
const Color _brandColor = Color(0xFF0052D9);
const Color _pageBg = Color(0xFFF3F3F3);
const Color _textSecondary = Color(0xFFA6A6A6);
const Color _errorColor = Color(0xFFD54941);

/// 个人中心页
///
/// 组合用户信息卡、业绩概览卡、功能入口与团队入口（TM/TA 可见），
/// 支持下拉刷新与首屏骨架屏；退出登录沿用原 _ProfileTab 的确认弹窗逻辑。
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  /// 骨架屏 shimmer 动画控制器
  late final AnimationController _skeletonCtrl;

  /// 首屏加载中（显示骨架屏）
  bool _isLoading = true;

  /// 业绩统计加载失败（显示"点击重试"）
  bool _statsError = false;

  /// 所属租户名（来自 profile 接口）
  String _tenantName = '';

  /// 业绩统计数据（null 表示未加载）
  HomeStats? _stats;

  @override
  void initState() {
    super.initState();
    _skeletonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _skeletonCtrl.dispose();
    super.dispose();
  }

  /// 并行业绩数据：租户名 + 今日业绩
  ///
  /// 今日待办复用共享 provider（幂等 load），用户信息来自本地缓存无需请求。
  Future<void> _load() async {
    final today = _todayStr();
    final tenantService = ref.read(tenantServiceProvider);
    final homeService = ref.read(homeServiceProvider);
    // 今日待办：触发一次共享 provider 刷新（幂等），由 watch 自动反映
    ref.read(scheduleStatsProvider.notifier).load();

    // 并行发起：租户名 + 业绩统计
    final tenantNameFuture = _safe(() => tenantService.fetchTenantName());
    final statsFuture = _safe(() => homeService.fetchMyStats(today));
    final tenantName = await tenantNameFuture;
    final stats = await statsFuture;

    if (!mounted) return;
    setState(() {
      _tenantName = tenantName ?? '';
      _stats = stats;
      _statsError = stats == null;
      _isLoading = false;
    });
  }

  /// 安全调用：捕获异常返回 null，避免单接口失败阻断整页
  Future<T?> _safe<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }

  /// 当前日期 YYYY-MM-DD（业绩统计取当天）
  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';
  }

  /// 角色中文标签；非 TE/TM/TA 返回空串（按 TE 处理，隐藏团队入口）
  String _roleLabel(String role) {
    switch (role) {
      case 'TE':
        return '电销专员';
      case 'TM':
        return '团队经理';
      case 'TA':
        return '团队助理';
      default:
        return '';
    }
  }

  /// 跳转子页（本轮统一占位）
  void _push(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final role = user?.role ?? '';
    final roleLabel = _roleLabel(role);
    final isManager = role == 'TM' || role == 'TA';
    final dueToday = ref.watch(scheduleStatsProvider).dueToday;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: _brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 用户信息区
              _isLoading
                  ? _UserCardSkeleton(ctrl: _skeletonCtrl)
                  : ProfileUserCard(
                      name: user?.name ?? '',
                      roleLabel: roleLabel,
                      email: user?.email ?? '',
                      tenantName: _tenantName,
                    ),
              const SizedBox(height: 24),

              // 我的业绩
              _sectionTitle('我的业绩'),
              const SizedBox(height: 12),
              _isLoading
                  ? _StatsCardSkeleton(ctrl: _skeletonCtrl)
                  : _statsError
                      ? _statsErrorWidget()
                      : ProfileStatsCard(
                          leadsTotal: _stats?.myLeadsTotal ?? 0,
                          followupCount: _stats?.followupCount ?? 0,
                          answeredCount: _stats?.answeredCount ?? 0,
                          dueToday: dueToday,
                          onTap: () =>
                              _push(const ComingSoonPage(featureName: '个人统计')),
                        ),
              const SizedBox(height: 24),

              // 功能入口（标题按需求隐藏）
              ProfileMenuGroup(
                title: '',
                children: [
                  ProfileMenuRow(
                    icon: Icons.call,
                    title: '通话记录',
                    onTap: () => _push(const CallRecordsPage()),
                  ),
                  ProfileMenuRow(
                    icon: Icons.people,
                    title: '客户列表',
                    onTap: () =>
                        _push(const ComingSoonPage(featureName: '客户列表')),
                  ),
                  ProfileMenuRow(
                    icon: Icons.settings,
                    title: '设置',
                    onTap: () =>
                        _push(const ComingSoonPage(featureName: '设置')),
                  ),
                  ProfileMenuRow(
                    icon: Icons.logout,
                    title: '退出登录',
                    color: _errorColor,
                    onTap: _onLogout,
                  ),
                ],
              ),

              // 团队入口（仅 TM/TA 可见）
              if (isManager) ...[
                const SizedBox(height: 24),
                ProfileMenuGroup(
                  title: '团队',
                  children: [
                    ProfileMenuRow(
                      icon: Icons.dashboard,
                      title: '团队统计',
                      onTap: () =>
                          _push(const ComingSoonPage(featureName: '团队统计')),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// 分组标题（gray-6，14px Medium，用于"我的业绩"等次级标题）
  Widget _sectionTitle(String t) => Text(
        t,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _textSecondary,
        ),
      );

  /// 业绩加载失败提示（可点击重试）
  Widget _statsErrorWidget() {
    return InkWell(
      onTap: () {
        if (!mounted) return;
        setState(() => _statsError = false);
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: _pageBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            '数据加载失败，点击重试',
            style: TextStyle(fontSize: 14, color: _errorColor),
          ),
        ),
      ),
    );
  }

  /// 退出登录确认弹窗，确认后清空登录态跳登录页
  void _onLogout() {
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
            child: const Text('退出', style: TextStyle(color: _errorColor)),
          ),
        ],
      ),
    );
  }
}

/// 用户信息区骨架屏（对齐真实卡片布局）
class _UserCardSkeleton extends StatelessWidget {
  final AnimationController ctrl;

  const _UserCardSkeleton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBlock(ctrl: ctrl, width: 56, height: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBlock(ctrl: ctrl, width: 120, height: 18),
                const SizedBox(height: 8),
                ShimmerBlock(ctrl: ctrl, width: 180, height: 14),
                const SizedBox(height: 8),
                ShimmerBlock(ctrl: ctrl, width: 140, height: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 业绩概览区骨架屏（4 个等分占位块，白色卡片对齐真实布局）
class _StatsCardSkeleton extends StatelessWidget {
  final AnimationController ctrl;

  const _StatsCardSkeleton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(
          4,
          (_) => Expanded(
            child: Column(
              children: [
                ShimmerBlock(ctrl: ctrl, width: 40, height: 20),
                const SizedBox(height: 8),
                ShimmerBlock(ctrl: ctrl, width: 48, height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
