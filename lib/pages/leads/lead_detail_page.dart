/// 线索详情页
///
/// 设计文档：05-线索详情.md
/// 入口：线索列表页/公海线索列表页 → 点击卡片
/// 路由参数：
///   [leadId] 必传，当前线索 ID
///   [listContext] 可选，列表上下文（决定底部导航条显隐）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/lead_detail.dart';
import 'package:telemarketing_app/models/lead_list_context.dart';
import 'package:telemarketing_app/pages/call_records/call_records_page.dart';
import 'package:telemarketing_app/pages/schedules/schedule_search_page.dart';
import 'package:telemarketing_app/providers/lead_detail_provider.dart';
import 'package:telemarketing_app/providers/schedule_list_provider.dart';
import 'package:telemarketing_app/widgets/app_action_bar.dart';
import 'widgets/lead_header_section.dart';
import 'widgets/follow_up_panel.dart';
import 'widgets/follow_up_timeline.dart';
import 'widgets/call_records_section.dart';
import 'widgets/schedule_section.dart';
import 'widgets/lead_bottom_nav.dart';
import 'widgets/edit_lead_dialog.dart';
import 'package:telemarketing_app/pages/schedules/widgets/schedule_form_sheet.dart';

/// 线索详情页
///
/// 设计文档：05-线索详情.md
/// 入口：线索列表页/公海线索列表页 → 点击卡片
/// 路由参数：
///   [leadId] 必传，当前线索 ID
///   [listContext] 可选，列表上下文（决定底部导航条显隐）
class LeadDetailPage extends ConsumerStatefulWidget {
  final String leadId;
  final LeadListContext? listContext;

  const LeadDetailPage({
    super.key,
    required this.leadId,
    this.listContext,
  });

  @override
  ConsumerState<LeadDetailPage> createState() => _LeadDetailPageState();
}

class _LeadDetailPageState extends ConsumerState<LeadDetailPage>
    with WidgetsBindingObserver {
  /// 是否刚完成拨号（onResume 后自动弹跟进面板用）
  bool _recentlyDialed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 首次加载完成后开始加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leadDetailProvider.notifier).loadLead(
            leadId: widget.leadId,
            listContext: widget.listContext,
          );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifeState) {
    // 无论是否最近拨号，只要从后台回到前台就清除标记
    if (lifeState == AppLifecycleState.resumed) {
      if (_recentlyDialed) {
        _recentlyDialed = false;
        // 通话结束返回，自动弹出跟进面板
        // 用 addPostFrameCallback 确保 build 完成后执行
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showFollowUpPanel(context, leadId: widget.leadId, fromDial: true);
          }
        });
      }
    } else if (lifeState == AppLifecycleState.paused) {
      // app 进入后台时不操作，保持标记
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leadDetailProvider);

    // 首次加载且无缓存：骨架屏
    if (state.isLoading && state.bundle == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F3F3),
        appBar: _buildNavBar(),
        body: _buildSkeleton(),
      );
    }

    // 加载失败 / 已删除：错误态
    if (state.bundle == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F3F3),
        appBar: _buildNavBar(),
        body: _buildErrorBody(state.error),
      );
    }

    final detail = state.detail!;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: _buildNavBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: LeadHeaderSection(
              detail: detail,
              onDial: () => _recentlyDialed = true,
            ),
          ),
          SliverToBoxAdapter(child: _buildActionBar(detail)),
          SliverToBoxAdapter(
            child: ScheduleSection(
              schedules: state.schedules,
              onViewAll: () => _jumpToScheduleSearch(detail.phone),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildFollowUpSection(state),
          ),
          SliverToBoxAdapter(
            child: CallRecordsSection(
              records: state.calls,
              total: 0,
              isLoading: false,
              errorMessage: null,
              onViewAll: () => _jumpToCallRecords(detail.phone),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      bottomNavigationBar: state.listContext != null
          ? LeadBottomNav(listContext: state.listContext!)
          : null,
    );
  }

  /// 统一的导航栏
  PreferredSizeWidget _buildNavBar() {
    return AppBar(
      title: const Text('线索详情'),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// 错误/已删除态
  Widget _buildErrorBody(String? errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info,
            size: 64,
            color: Color(0xFFA6A6A6),
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? '该线索已删除或不存在',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF181818),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('返回列表'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(LeadDetail detail) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
        ),
      ),
      child: AppActionBar(
        actions: [
          ActionItem(
            text: '跟进', type: ActionType.text, icon: Icons.reply,
            onTap: detail.isConverted
                ? null
                : () => showFollowUpPanel(context, leadId: detail.id),
          ),
          ActionItem(
            text: '日程', type: ActionType.text, icon: Icons.calendar_today,
            onTap: detail.isConverted
                ? null
                : () async {
                    final changed = await showScheduleFormSheet(
                      context,
                      leadId: detail.id,
                      leadName: detail.name,
                      leadPhone: detail.phone,
                    );
                    if (changed == true) {
                      try { ref.read(scheduleListProvider.notifier).refresh(); } catch (_) {}
                      try { ref.read(leadDetailProvider.notifier).refreshBundle(); } catch (_) {}
                    }
                  },
          ),
          ActionItem(
            text: '编辑', type: ActionType.text, icon: Icons.edit,
            onTap: () => showEditLeadDialog(context, leadId: detail.id, detail: detail),
          ),
        ],
      ),
    );
  }

  /// 跳日程搜索页（带线索手机号，搜索该号码关联的日程）
  void _jumpToScheduleSearch(String phone) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleSearchPage(initialQuery: phone),
      ),
    );
  }

  /// 跳通话记录页（带线索手机号，搜索该号码的通话记录）
  void _jumpToCallRecords(String phone) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CallRecordsPage(initialQuery: phone),
      ),
    );
  }

  // ── 骨架屏加载态 ──

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonBlock(width: 160, height: 28),
                const SizedBox(height: 12),
                _skeletonBlock(width: 200, height: 24),
                const SizedBox(height: 16),
                _skeletonBlock(width: double.infinity, height: 16),
                const SizedBox(height: 4),
                _skeletonBlock(width: 120, height: 16),
              ],
            ),
          ),
          // Action bar skeleton
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                4,
                (_) => _skeletonBlock(width: 48, height: 48, circular: true),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Timeline skeleton
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonBlock(width: 100, height: 20),
                const SizedBox(height: 16),
                _skeletonBlock(width: double.infinity, height: 14),
                const SizedBox(height: 8),
                _skeletonBlock(width: 200, height: 14),
                const SizedBox(height: 12),
                _skeletonBlock(width: double.infinity, height: 14),
                const SizedBox(height: 8),
                _skeletonBlock(width: 180, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonBlock({
    double width = double.infinity,
    double height = 16,
    bool circular = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(circular ? 24 : 4),
      ),
    );
  }

  // ── 跟进时间线区域 ──

  Widget _buildFollowUpSection(LeadDetailState state) {
    return FollowUpTimeline(
      allRecords: state.allFollowUps,
      isLoading: false,
      errorMessage: null,
      leadId: state.detail?.id ?? '',
    );
  }
}
