/// 线索列表页
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'package:telemarketing_app/providers/lead_list_provider.dart';
import 'package:telemarketing_app/models/lead.dart';
import 'package:telemarketing_app/models/lead_list_context.dart';
import 'package:telemarketing_app/models/option_item.dart';
import 'package:telemarketing_app/constants/lead_constants.dart';
import 'package:telemarketing_app/widgets/app_search_bar.dart';
import 'package:telemarketing_app/widgets/lead_card.dart';
import 'lead_detail_page.dart';
import 'widgets/leads_filter_sheet.dart';
import 'widgets/leads_skeletons.dart';
import 'widgets/leads_top_bar.dart';

/// 线索列表页
class LeadsListPage extends ConsumerStatefulWidget {
  const LeadsListPage({super.key});

  @override
  ConsumerState<LeadsListPage> createState() => _LeadsListPageState();
}

class _LeadsListPageState extends ConsumerState<LeadsListPage> {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(leadListProvider.notifier).loadMore();
    }
  }

  /// 触发搜索
  void _doSearch(String keyword) {
    ref.read(leadListProvider.notifier).search(keyword);
  }

  /// 筛选标签栏
  Widget _buildFilterTags(LeadListState state) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (state.statusFilter != null && state.statusFilter!.isNotEmpty)
              _buildTag(
                '状态',
                LeadConstants.displayName(state.statusFilter),
                () => ref.read(leadListProvider.notifier).clearFilter('status'),
              ),
            if (state.categoryId != null && state.categoryId!.isNotEmpty)
              _buildTag(
                '分类',
                _findOptionName(state.categories, state.categoryId),
                () => ref.read(leadListProvider.notifier).clearFilter('category'),
              ),
            if (state.projectId != null && state.projectId!.isNotEmpty)
              _buildTag(
                '项目',
                _findOptionName(state.projects, state.projectId),
                () => ref.read(leadListProvider.notifier).clearFilter('project'),
              ),
            if (state.dateFrom != null || state.dateTo != null)
              _buildTag(
                '时间',
                '已选',
                () => ref.read(leadListProvider.notifier).clearFilter('date'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, String value, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 12, right: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                '$label: $value',
                style: const TextStyle(fontSize: 12, color: Color(0xFF0052D9)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.close,
                size: 16,
                color: Color(0xFF0052D9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _findOptionName(List<OptionItem> options, String? id) {
    if (id == null) return '';
    final found = options.where((o) => o.id == id);
    return found.isNotEmpty ? found.first.name : id;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leadListProvider);
    final user = ref.watch(authProvider).user;
    final isManager =
        user?.role == 'tenant_admin' || user?.role == 'tenant_manager';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            LeadsTopBar(
              state: state,
              onShowSort: () => _showSortSheet(state),
              onShowFilter: _showFilterSheet,
            ),
            AppSearchBar(
              controller: _searchCtrl,
              onSearch: _doSearch,
              hintText: '搜索线索姓名/电话/公司',
            ),
            // ── 筛选标签栏 ──
            if (state.hasActiveFilters)
              _buildFilterTags(state),
            Expanded(child: _buildBody(state, isManager)),
          ],
        ),
      ),
    );
  }

  // ── 顶部导航栏 ──


  // ── 排序弹窗 ──

  void _showSortSheet(LeadListState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => LeadsSortSheet(state: state),
    );
  }

  // ── 筛选弹窗 ──

  void _showFilterSheet() {
    final state = ref.read(leadListProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => LeadsFilterSheet(state: state),
    );
  }


  // ── 主体区域 ──

  Widget _buildBody(LeadListState state, bool isManager) {
    if (state.isInitialLoading) {
      return _buildSkeleton();
    }

    if (state.errorMessage != null && state.leads.isEmpty) {
      return _buildError(state.errorMessage!);
    }

    if (state.leads.isEmpty) {
      return _buildEmpty(state.keyword.isNotEmpty);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(leadListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        itemCount: state.leads.length + 1,
        itemBuilder: (context, index) {
          if (index == state.leads.length) {
            return _buildFooter(state);
          }
          return _buildLeadCard(state.leads[index], isManager, index);
        },
      ),
    );
  }

  // ── 线索卡片 ──

  Widget _buildLeadCard(Lead lead, bool isManager, int index) {
    return LeadCard(
      lead: lead,
      showOwner: isManager,
      onTap: () {
        // 构建列表上下文（底部导航条用）
        final ids = ref.read(leadListProvider).leads
            .map((l) => l.id)
            .toList();
        final listContext = LeadListContext(
          ids: ids,
          index: index,
          source: 'leads',
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LeadDetailPage(
              leadId: lead.id,
              listContext: listContext,
            ),
          ),
        );
      },
    );
  }

  // ── 底部 ──

  Widget _buildFooter(LeadListState state) {
    if (state.isLoadingMore) {
      return const SizedBox(
        height: 56,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!state.hasMore && state.leads.isNotEmpty) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: Text(
            '— 已加载全部线索 —',
            style: TextStyle(fontSize: 12, color: Color(0x99C5C5C5)),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }

  // ── 骨架屏（修 overflow） ──

  Widget _buildSkeleton() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LeadSkBlock(width: 100, height: 16),
            SizedBox(height: 12),
            LeadSkBlock(width: 160, height: 14),
            SizedBox(height: 12),
            LeadSkBlock(width: 80, height: 14),
            SizedBox(height: 12),
            LeadSkBlock(width: 120, height: 14),
          ],
        ),
      ),
    );
  }

  // ── 空态 ──

  Widget _buildEmpty(bool isSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.inbox,
            size: 80,
            color: const Color(0xFFDCDCDC),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? '未找到相关线索' : '暂无线索',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF181818),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearch ? '请尝试其他关键词或筛选条件' : '请联系管理员导入',
            style: const TextStyle(fontSize: 14, color: Color(0xFFA6A6A6)),
          ),
        ],
      ),
    );
  }

  // ── 错误态 ──

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Color(0xFFDCDCDC)),
          const SizedBox(height: 16),
          const Text(
            '加载失败',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF181818),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFFA6A6A6)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.read(leadListProvider.notifier).refresh(),
            child: const Text(
              '重新加载',
              style: TextStyle(color: Color(0xFF0052D9)),
            ),
          ),
        ],
      ),
    );
  }
}
