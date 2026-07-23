/// 线索列表页
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'package:telemarketing_app/providers/lead_list_provider.dart';
import 'package:telemarketing_app/models/lead.dart';
import 'package:telemarketing_app/models/lead_list_context.dart';
import 'package:telemarketing_app/models/option_item.dart';
import 'package:telemarketing_app/widgets/lead_card.dart';
import 'lead_detail_page.dart';
import 'widgets/leads_skeletons.dart';
import 'widgets/leads_filter_widgets.dart';
import 'widgets/leads_search_bar.dart';
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

  // 筛选面板临时状态
  String? _tempStatus;
  String? _tempCategoryId;
  String? _tempProjectId;
  int? _tempDateFrom;
  int? _tempDateTo;

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
            LeadsSearchBar(
              searchCtrl: _searchCtrl,
              onSearch: _doSearch,
              onShowFilter: _showFilterSheet,
              onShowSort: () => _showSortSheet(state),
            ),
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
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '排序方式',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _sortOption(ctx, '最近更新', '-updatedAt', state.sortBy),
            const Divider(height: 1),
            _sortOption(ctx, '待跟进优先', 'nextFollowupAt', state.sortBy),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sortOption(
    BuildContext ctx,
    String label,
    String value,
    String current,
  ) {
    final selected = value == current;
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? const Color(0xFF0052D9) : const Color(0xFFA6A6A6),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF0052D9) : const Color(0xFF181818),
        ),
      ),
      onTap: () {
        Navigator.of(ctx).pop();
        if (!selected) {
          final notifier = ref.read(leadListProvider.notifier);
          // 直接切换排序
          if (value == '-updatedAt' && current != '-updatedAt') {
            notifier.toggleSort();
          } else if (value == 'nextFollowupAt' && current != 'nextFollowupAt') {
            notifier.toggleSort();
          }
        }
      },
    );
  }

  // ── 筛选弹窗 ──

  void _showFilterSheet() {
    final state = ref.read(leadListProvider);
    _tempStatus = state.statusFilter;
    _tempCategoryId = state.categoryId;
    _tempProjectId = state.projectId;
    _tempDateFrom = state.dateFrom;
    _tempDateTo = state.dateTo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterSheetTitle(ctx, setSheetState),
              const SizedBox(height: 16),
              _buildStatusSection(setSheetState),
              if (state.categories.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildCategorySection(state, setSheetState),
              ],
              if (state.projects.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildProjectSection(state, setSheetState),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSheetTitle(BuildContext ctx, Function setSheetState) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '筛选',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            setSheetState(() {
              _tempStatus = null;
              _tempCategoryId = null;
              _tempProjectId = null;
              _tempDateFrom = null;
              _tempDateTo = null;
            });
          },
          child: const Text(
            '重置',
            style: TextStyle(color: Color(0xFFA6A6A6)),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            ref
                .read(leadListProvider.notifier)
                .applyFilters(
                  statusFilter: _tempStatus,
                  categoryId: _tempCategoryId,
                  projectId: _tempProjectId,
                  dateFrom: _tempDateFrom,
                  dateTo: _tempDateTo,
                );
          },
          child: const Text(
            '确定',
            style: TextStyle(color: Color(0xFF0052D9)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(Function setSheetState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '状态',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _buildStatusChips(setSheetState),
        ),
      ],
    );
  }

  Widget _buildCategorySection(LeadListState state, Function setSheetState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '分类',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _buildOptionChips(
            state.categories,
            _tempCategoryId,
            setSheetState,
            onSelected: (id) {
              setSheetState(
                () => _tempCategoryId = _tempCategoryId == id ? null : id,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProjectSection(LeadListState state, Function setSheetState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '项目',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _buildOptionChips(
            state.projects,
            _tempProjectId,
            setSheetState,
            onSelected: (id) {
              setSheetState(
                () => _tempProjectId = _tempProjectId == id ? null : id,
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStatusChips(Function setSheetState) {
    final statuses = [
      ('pending', '待分配'),
      ('assigned', '待跟进'),
      ('following', '跟进中'),
      ('converted', '已转化'),
      ('invalid', '无效'),
    ];
    return statuses.map((s) {
      final selected = _tempStatus == s.$1;
      return SelectChip(
          label: s.$2, selected: selected, onTap: () {
        setSheetState(() {
          _tempStatus = selected ? null : s.$1;
        });
      });
    }).toList();
  }

  List<Widget> _buildOptionChips(
    List<OptionItem> options,
    String? selectedId,
    Function setSheetState, {
    required void Function(String id) onSelected,
  }) {
    return options.map((o) {
      final selected = o.id == selectedId;
      return SelectChip(
          label: o.name, selected: selected, onTap: () => onSelected(o.id));
    }).toList();
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
