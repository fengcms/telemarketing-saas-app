import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../models/lead_list_context.dart';
import '../../models/lead_detail.dart';
import '../../providers/lead_detail_provider.dart';
import 'widgets/lead_header_section.dart';
import 'widgets/lead_action_bar.dart';
import 'widgets/follow_up_timeline.dart';
import 'widgets/call_records_section.dart';
import 'widgets/lead_bottom_nav.dart';

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

class _LeadDetailPageState extends ConsumerState<LeadDetailPage> {
  @override
  void initState() {
    super.initState();
    // 首次加载完成后开始加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leadDetailProvider.notifier).loadLead(
            leadId: widget.leadId,
            listContext: widget.listContext,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leadDetailProvider);

    // 首屏加载全量加载态 → 显示骨架屏
    if (state.isLoadingDetail) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F3F3),
        appBar: TDNavBar(
          title: '线索详情',
          backgroundColor: Colors.white,
          useDefaultBack: false,
          boxShadow: [
            const BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
          leftBarItems: [
            TDNavBarItem(
              icon: TDIcons.chevron_left,
              action: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: _buildSkeleton(),
      );
    }

    // 线索已删除/不存在
    if (state.detail == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F3F3),
        appBar: TDNavBar(
          title: '线索详情',
          backgroundColor: Colors.white,
          useDefaultBack: false,
          boxShadow: [
            const BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
          leftBarItems: [
            TDNavBarItem(
              icon: TDIcons.chevron_left,
              action: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                TDIcons.info_circle_filled,
                size: 64,
                color: const Color(0xFFA6A6A6),
              ),
              const SizedBox(height: 16),
              Text(
                state.detailError ?? '该线索已删除或不存在',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF181818),
                ),
              ),
              const SizedBox(height: 24),
              TDButton(
                text: '返回列表',
                theme: TDButtonTheme.primary,
                size: TDButtonSize.medium,
                shape: TDButtonShape.round,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }

    final detail = state.detail!;

    // 主页面：TDNavBar + 可滚动内容
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: TDNavBar(
        title: '线索详情',
        backgroundColor: Colors.white,
        useDefaultBack: false,
        boxShadow: [
          const BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
        leftBarItems: [
          TDNavBarItem(
            icon: TDIcons.chevron_left,
            action: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── 头部信息区（Section A） ──
          SliverToBoxAdapter(
            child: LeadHeaderSection(detail: detail),
          ),

          // ── 操作按钮区（Section B） ──
          SliverToBoxAdapter(child: _buildActionBar(detail)),

          // ── 跟进时间线（Section C） ──
          SliverToBoxAdapter(
            child: _buildFollowUpSection(state),
          ),

          // ── 通话记录摘要（Section D） ──
          SliverToBoxAdapter(
            child: CallRecordsSection(
              records: state.calls,
              total: state.callsTotal,
              isLoading: state.isLoadingCalls,
              errorMessage: state.callsError,
            ),
          ),

          // 底部留白
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      // 底部导航条（仅 listContext 存在时显示）
      bottomNavigationBar: state.listContext != null
          ? LeadBottomNav(listContext: state.listContext!)
          : null,
    );
  }

  Widget _buildActionBar(LeadDetail detail) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
        ),
      ),
      child: LeadActionBar(detail: detail, leadId: detail.id),
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
      isLoading: state.isLoadingFollowUps,
      errorMessage: state.followUpsError,
      leadId: state.detail?.id ?? '',
    );
  }
}
