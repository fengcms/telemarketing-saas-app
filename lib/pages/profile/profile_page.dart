/// 个人中心页（"我的" Tab）
///
/// 设计文档：docs/design/page-design/13-个人中心.md
/// 展示当前登录用户的基本信息、个人业绩概览、功能入口与团队入口。
/// 子页：团队统计已开发（v0.25，入口直连 [TeamStatsPage]）；
/// 个人统计已开发（v0.32，业绩卡直连 [PersonalStatsPage]）。
/// 设置页已开发，入口直连 [SettingsPage]。
/// 通话记录/客户列表已开发，入口直连对应页面。
///
/// 数据来源：
/// - 用户信息：authProvider（本地缓存，来自登录响应）
/// - 所属租户：tenantService.fetchTenantName()（GET /api/tenant/profile）
/// - 业绩概览：TE 用 homeService.fetchMyStats(today)（GET /api/tenant/stats/mine）；
///   TM/TA 改用 homeService.fetchManagerTodayStats()（GET /api/tenant/stats/today，团队当日）
/// - 今日待办：共享 scheduleStatsProvider.todayPending（GET /api/tenant/schedules/stats/mine，严格今日窗口）
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/home_stats.dart';
import 'package:telemarketing_app/models/manager_today_stats.dart';
import 'package:telemarketing_app/theme/role_label.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';
import 'package:telemarketing_app/pages/call_records/call_records_page.dart';
import 'package:telemarketing_app/pages/customers/customer_list_page.dart';
import 'package:telemarketing_app/pages/settings/settings_page.dart';
import 'package:telemarketing_app/pages/team_stats/team_stats_page.dart';
import 'package:telemarketing_app/pages/personal_stats/personal_stats_page.dart';
import 'package:telemarketing_app/pages/theme_preview_page.dart';
import 'package:telemarketing_app/pages/profile/widgets/profile_menu_row.dart';
import 'package:telemarketing_app/pages/profile/widgets/profile_stats_card.dart';
import 'package:telemarketing_app/pages/profile/widgets/team_stats_overview_card.dart';
import 'package:telemarketing_app/pages/profile/widgets/profile_user_card.dart';
import 'package:telemarketing_app/pages/schedules/widgets/schedule_skeleton.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'package:telemarketing_app/providers/home_provider.dart';
import 'package:telemarketing_app/providers/options_provider.dart';
import 'package:telemarketing_app/providers/schedule_stats_provider.dart';
import 'package:telemarketing_app/core/dev_tools.dart';
import 'package:telemarketing_app/widgets/app_toast.dart';

/// 个人中心页
///
/// 组合用户信息卡、业绩概览卡、功能入口与团队入口（TM/TA 可见），
/// 支持下拉刷新与首屏骨架屏。
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

  /// 团队当日统计（TM/TA 视角；TE 为 null）
  /// 来自 [HomeService.fetchManagerTodayStats]（GET /api/tenant/stats/today）
  ManagerTodayStats? _managerTodayStats;

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

  /// 并行业绩数据：租户名 + 当日业绩/团队业绩
  ///
  /// - TE：拉个人 [HomeService.fetchMyStats]（GET /api/tenant/stats/mine）
  /// - TM/TA：拉团队 [HomeService.fetchManagerTodayStats]（GET /api/tenant/stats/today）
  /// 今日待办复用共享 provider（幂等 load），用户信息来自本地缓存无需请求。
  Future<void> _load() async {
    final today = _todayStr();
    final role = ref.read(authProvider).user?.role ?? '';
    final isManager = role == 'tenant_manager' || role == 'tenant_admin';
    final tenantService = ref.read(tenantServiceProvider);
    final homeService = ref.read(homeServiceProvider);

    // 并行发起：租户名 + （按角色分支的）业绩统计
    final tenantNameFuture = _safe(() => tenantService.fetchTenantName());
    final Future<ManagerTodayStats?> managerFuture = isManager
        ? _safe(() => homeService.fetchManagerTodayStats())
        : Future.value(null);
    final Future<HomeStats?> myFuture = isManager
        ? Future.value(null)
        : _safe(() => homeService.fetchMyStats(today));
    final tenantName = await tenantNameFuture;
    final managerStats = await managerFuture;
    final myStats = await myFuture;

    if (!mounted) return;
    setState(() {
      _tenantName = tenantName ?? '';
      _managerTodayStats = managerStats;
      _stats = myStats;
      _statsError = isManager ? managerStats == null : myStats == null;
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

  /// 跳转子页（本轮统一占位）
  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  /// 手动刷新公司基础数据（options + 租户信息）
  Future<void> _refreshCompanyData() async {
    if (!mounted) return;
    AppToast.show(context, '正在更新公司数据…');
    try {
      await Future.wait([
        ref.read(optionsCacheProvider).refresh(),
        ref.read(tenantServiceProvider).refresh(),
      ]);
      if (!mounted) return;
      AppToast.show(context, '公司数据已更新');
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, '更新失败，请重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final role = user?.role ?? '';
    final roleText = roleLabel(role);
    final isManager = role == 'tenant_manager' || role == 'tenant_admin';
    final todayPending = ref.watch(scheduleStatsProvider).todayPending;

    return Scaffold(
      backgroundColor: BrandColors.surface,
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: BrandColors.primary,
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
                      roleLabel: roleText,
                      email: user?.email ?? '',
                      tenantName: _tenantName,
                    ),
              const SizedBox(height: 24),

              // 业绩区块（TM/TA 显示团队业绩概览；TE 显示我的业绩）
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _sectionTitle(isManager ? '团队业绩概览' : '我的业绩'),
                  if (isManager)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _push(const PersonalStatsPage()),
                      child: const Text('查看我的业绩 →'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (isManager)
                _isLoading
                    ? _ManagerStatsCardSkeleton(ctrl: _skeletonCtrl)
                    : _statsError
                        ? _statsErrorWidget()
                        : TeamStatsOverviewCard(stats: _managerTodayStats!)
              else
                _isLoading
                    ? _StatsCardSkeleton(ctrl: _skeletonCtrl)
                    : _statsError
                        ? _statsErrorWidget()
                        : ProfileStatsCard(
                            leadsTotal: _stats?.myLeadsTotal ?? 0,
                            followupCount: _stats?.followupCount ?? 0,
                            answeredCount: _stats?.answeredCount ?? 0,
                            todayPending: todayPending,
                            onTap: () => _push(const PersonalStatsPage()),
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
                    onTap: () => _push(const CustomerListPage()),
                  ),
                  ProfileMenuRow(
                    icon: Icons.settings,
                    title: '设置',
                    onTap: () => _push(const SettingsPage()),
                  ),
                  ProfileMenuRow(
                    icon: Icons.cloud_sync,
                    title: '更新公司数据',
                    onTap: _refreshCompanyData,
                  ),
                  // 开发版：主题预览入口
                  if (enableDevTools)
                    ProfileMenuRow(
                      icon: Icons.palette,
                      title: '主题预览',
                      onTap: () => _push(const ThemePreviewPage()),
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
                      onTap: () => _push(const TeamStatsPage()),
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
      color: BrandColors.textSecondary,
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
          color: BrandColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            '数据加载失败，点击重试',
            style: TextStyle(fontSize: 14, color: BrandColors.error),
          ),
        ),
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

/// 团队业绩概览区骨架屏（3 行占位：数字 + 环比 + 标签，对齐 [TeamStatsOverviewCard]）
class _ManagerStatsCardSkeleton extends StatelessWidget {
  final AnimationController ctrl;

  const _ManagerStatsCardSkeleton({required this.ctrl});

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
                const SizedBox(height: 2),
                ShimmerBlock(ctrl: ctrl, width: 32, height: 14),
                const SizedBox(height: 4),
                ShimmerBlock(ctrl: ctrl, width: 48, height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
