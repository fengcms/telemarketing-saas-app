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
import 'package:telemarketing_app/services/api_exception.dart';
import 'package:telemarketing_app/widgets/app_search_bar.dart';
import 'package:telemarketing_app/widgets/app_toast.dart';
import 'package:telemarketing_app/widgets/lead_card.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';
import 'lead_detail_page.dart';
import 'widgets/leads_filter_sheet.dart';
import 'widgets/leads_skeletons.dart';
import 'widgets/leads_top_bar.dart';
import 'widgets/public_lead_card.dart';

/// 线索列表页（我的线索 + 公海线索双 Tab）
class LeadsListPage extends ConsumerStatefulWidget {
  const LeadsListPage({super.key});

  @override
  ConsumerState<LeadsListPage> createState() => _LeadsListPageState();
}

class _LeadsListPageState extends ConsumerState<LeadsListPage> {
  final ScrollController _scrollCtrl = ScrollController();
  /// 我的线索搜索控制器
  final TextEditingController _mineSearchCtrl = TextEditingController();
  /// 公海线索搜索控制器（切换 Tab 时不丢失已输入文字）
  final TextEditingController _publicSearchCtrl = TextEditingController();

  // ── 公海线索状态 ──
  /// 0=我的线索，1=公海线索
  int _activeTab = 0;
  List<Lead> _publicLeads = [];
  int _publicPage = 1;
  int _publicTotal = 0;
  bool _publicLoading = true;
  bool _publicLoadingMore = false;
  String? _publicError;
  String _publicKeyword = '';
  /// 当前正在领取的线索 ID（null 表示无进行中的领取）
  String? _claimingLeadId;

  /// 是否显示公海 Tab（TE + allowSelfClaim）
  bool _showPublicTab = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _checkPublicAccess();
  }

  /// 检查是否显示公海 Tab
  Future<void> _checkPublicAccess() async {
    final user = ref.read(authProvider).user;
    // 仅 TE 可见公海
    if (user?.role != 'tenant_employee') return;
    try {
      final tenantService = ref.read(tenantServiceProvider);
      final settings = await tenantService.fetchProfile();
      // fetchProfile() 返回的是 settings 对象本身，直接取 allowSelfClaim
      final allowSelfClaim = settings['allowSelfClaim'] == true;
      if (mounted) {
        setState(() => _showPublicTab = allowSelfClaim);
        // 如果显示公海 Tab，自动加载公海数据（但不切换 Tab）
        if (allowSelfClaim) _loadPublicLeads();
      }
    } catch (_) {
      // 静默失败，不显示公海 Tab
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _mineSearchCtrl.dispose();
    _publicSearchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_activeTab == 1) {
      _onPublicScroll();
      return;
    }
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(leadListProvider.notifier).loadMore();
    }
  }

  /// 触发搜索
  void _doSearch(String keyword) {
    if (_activeTab == 1) {
      _loadPublicLeads(keyword: keyword, page: 1);
    } else {
      ref.read(leadListProvider.notifier).search(keyword);
    }
  }

  // ── 公海线索数据 ──

  /// 加载公海线索列表
  Future<void> _loadPublicLeads({String? keyword, int page = 1}) async {
    if (page == 1) {
      setState(() {
        _publicLoading = true;
        _publicError = null;
        _publicKeyword = keyword ?? '';
      });
    } else {
      setState(() => _publicLoadingMore = true);
    }

    try {
      final service = ref.read(leadServiceProvider);
      final result = await service.fetchLeads(
        scope: 'public',
        page: page,
        keyword: keyword?.isNotEmpty == true ? keyword : null,
        sort: '-updatedAt',
      );

      if (!mounted) return;
      setState(() {
        if (page == 1) {
          _publicLeads = result.leads;
        } else {
          _publicLeads = [..._publicLeads, ...result.leads];
        }
        _publicTotal = result.total;
        _publicPage = page;
        _publicLoading = false;
        _publicLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _publicLoading = false;
        _publicLoadingMore = false;
        if (page == 1) _publicError = '加载失败，请重试';
      });
    }
  }

  /// 领取公海线索
  Future<void> _onClaim(String leadId) async {
    if (_claimingLeadId != null) return;
    setState(() => _claimingLeadId = leadId);

    try {
      await ref.read(leadServiceProvider).claimLead(leadId);
      if (!mounted) return;
      AppToast.show(context, '领取成功，已加入您的线索池');
      // 从列表中移除该卡片
      setState(() {
        _publicLeads.removeWhere((l) => l.id == leadId);
        _publicTotal--;
        _claimingLeadId = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _claimingLeadId = null);
      if (e.message.contains('only pool leads') ||
          e.message.contains('已被领取')) {
        AppToast.show(context, '该线索已被领取');
        _loadPublicLeads(page: 1);
      } else if (e.message.contains('禁止拨打') ||
          e.message.contains('BLOCKLIST')) {
        AppToast.show(context, '该线索在禁拨名单中，无法领取');
      } else {
        AppToast.show(context, e.message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _claimingLeadId = null);
      AppToast.show(context, '网络异常，请重试');
    }
  }

  /// 公海滚动加载更多
  void _onPublicScroll() {
    if (_publicLoadingMore || !_hasMorePublic) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadPublicLeads(keyword: _publicKeyword, page: _publicPage + 1);
    }
  }

  bool get _hasMorePublic =>
      _publicLeads.length < _publicTotal && _publicTotal > 0;

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
            if (state.ownerId != null && state.ownerId!.isNotEmpty)
              _buildTag(
                '归属',
                '已指定',
                () => ref.read(leadListProvider.notifier).clearFilter('owner'),
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
    final isPublic = _activeTab == 1;

    return Scaffold(
      backgroundColor: BrandColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── 顶部标题栏（左 Tab + 右筛选/排序） ──
            LeadsTopBar(
              state: state,
              activeTab: _activeTab,
              showPublicTab: _showPublicTab,
              onTabChanged: _onTabChanged,
              onShowSort: () => _showSortSheet(state),
              onShowFilter: _showFilterSheet,
            ),

            // ── 团队统计摘要条（仅 TM/TA 可见，显示共 X 条） ──
            if (isManager && !isPublic)
              _buildSummaryBar(state.total),

            // ── 搜索栏（双控制器，切换 Tab 不丢失文字） ──
            AppSearchBar(
              controller: _activeTab == 0 ? _mineSearchCtrl : _publicSearchCtrl,
              onSearch: _doSearch,
              hintText: isPublic ? '搜索公海线索姓名/电话' : '搜索线索姓名/电话/公司',
            ),

            // ── 我的线索筛选标签栏 ──
            if (!isPublic && state.hasActiveFilters)
              _buildFilterTags(state),

            Expanded(child: isPublic ? _buildPublicBody() : _buildBody(state, isManager)),
          ],
        ),
      ),
    );
  }

  // ── Tab 切换 ──

  /// 切换线索 Tab（我的/公海），搜索文字不丢失
  void _onTabChanged(int tabIndex) {
    if (_activeTab == tabIndex) return;
    setState(() => _activeTab = tabIndex);
    if (tabIndex == 1 && _publicLeads.isEmpty && !_publicLoading) {
      _loadPublicLeads();
    }
  }

  // ── 顶部导航栏 ──

  /// 统计摘要条（仅 TM/TA 可见）
  Widget _buildSummaryBar(int total) {
    return Container(
      width: double.infinity,
      height: 40,
      color: const Color(0xFFF3F3F3),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Color(0xFF4E5969)),
          children: [
            const TextSpan(text: '共 '),
            TextSpan(
              text: _formatNum(total),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0052D9),
              ),
            ),
            const TextSpan(text: ' 条'),
          ],
        ),
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}万';
    final str = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }

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
    final st = ref.read(leadListProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => LeadsFilterSheet(state: st),
    );
  }

  // ── 主体区域（我的线索） ──

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
    final state = ref.read(leadListProvider);
    return LeadCard(
      lead: lead,
      showOwner: isManager,
      users: state.users,
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

  // ── 公海线索视图 ──

  Widget _buildPublicBody() {
    if (_publicLoading) {
      return _buildPublicSkeleton();
    }

    if (_publicError != null) {
      return _buildPublicError(_publicError!);
    }

    if (_publicLeads.isEmpty) {
      return _buildPublicEmpty();
    }

    return RefreshIndicator(
      onRefresh: () => _loadPublicLeads(page: 1),
      child: ListView.builder(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        itemCount: _publicLeads.length + 1,
        itemBuilder: (context, index) {
          if (index == _publicLeads.length) {
            return _buildPublicFooter();
          }
          final lead = _publicLeads[index];
          return PublicLeadCard(
            lead: lead,
            claiming: _claimingLeadId == lead.id,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LeadDetailPage(leadId: lead.id),
                ),
              );
            },
            onClaim: () => _onClaim(lead.id),
          );
        },
      ),
    );
  }

  Widget _buildPublicSkeleton() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: 3,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 160,
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
            SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              LeadSkBlock(width: 100, height: 36),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.waves, size: 80, color: Color(0xFFDCDCDC)),
          const SizedBox(height: 16),
          const Text(
            '当前公海没有可领取的线索',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF181818),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '新线索导入后将自动出现在这里',
            style: TextStyle(fontSize: 14, color: Color(0xFFA6A6A6)),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Color(0xFFDCDCDC)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFFA6A6A6)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _loadPublicLeads(page: 1),
            child: const Text(
              '重新加载',
              style: TextStyle(color: Color(0xFF0052D9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicFooter() {
    if (_publicLoadingMore) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (!_hasMorePublic && _publicLeads.isNotEmpty) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: Text(
            '— 已加载全部公海线索 —',
            style: TextStyle(fontSize: 12, color: Color(0x99C5C5C5)),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }

  // ── 底部（我的线索） ──

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
