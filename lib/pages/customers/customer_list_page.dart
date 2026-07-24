/// 客户列表页
///
/// 设计文档 §2.1 + §4。
/// 功能：搜索(q) + 等级筛选(level, 通栏) + scope 切换(mine/all, TM/TA) +
/// 下拉刷新 + 无限滚动 + 骨架/空态/错误态。
/// 卡片点击直接跳对应线索详情（不单独开发客户详情页）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/customer.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'package:telemarketing_app/providers/customer_service_provider.dart';
import 'package:telemarketing_app/pages/customers/widgets/customer_filter_bar.dart';
import 'package:telemarketing_app/pages/customers/widgets/customer_search_bar.dart';
import 'package:telemarketing_app/pages/customers/widgets/customer_card.dart';
import 'package:telemarketing_app/pages/customers/widgets/customer_list_skeleton.dart';
import 'package:telemarketing_app/pages/leads/lead_detail_page.dart';

/// 客户列表页
class CustomerListPage extends ConsumerStatefulWidget {
  const CustomerListPage({super.key});

  @override
  ConsumerState<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends ConsumerState<CustomerListPage> {
  final List<Customer> _items = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  String? _query; // 搜索词（null = 不搜）
  String? _level; // 等级筛选（null = 全部）
  String _scope = 'mine'; // mine / all（TM/TA 可切）

  int _page = 1;
  int _pages = 1;

  bool _isLoading = true; // 初始加载（骨架）
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _isFetching = false; // 拉第一页重入锁（首屏/刷新/筛选共用）
  String? _error;

  /// 是否可切换 scope（TE 不可，TM/TA 可）
  bool get _canSwitchScope {
    final role = ref.read(authProvider).user?.role;
    return role != null && role != 'TE';
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// 滚动到底部阈值 → 加载下一页
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  /// 初始 / 刷新 / 切换筛选后重拉第一页
  ///
  /// 注意：守卫用 [_isFetching] 重入锁，不能用 [_isLoading]——
  /// [_isLoading] 初始值为 true（首屏骨架），若用其做守卫会让
  /// initState 里的首次调用被自己短路、永不发请求（通话记录页已踩过）。
  Future<void> _loadInitial() async {
    if (_isFetching) return;
    _isFetching = true;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await ref.read(customerServiceProvider).fetchCustomers(
            scope: _scope,
            q: _query,
            level: _level,
            page: 1,
          );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.items);
        _page = 1;
        _pages = res.pages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    } finally {
      _isFetching = false;
    }
  }

  /// 追加下一页
  Future<void> _loadMore() async {
    if (_isLoadingMore || _isLoading || _page >= _pages) return;
    setState(() => _isLoadingMore = true);
    try {
      final next = _page + 1;
      final res = await ref.read(customerServiceProvider).fetchCustomers(
            scope: _scope,
            q: _query,
            level: _level,
            page: next,
          );
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items);
        _page = next;
        _pages = res.pages;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
        _error = e.toString();
      });
    }
  }

  /// 下拉刷新
  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    await _loadInitial();
    _isRefreshing = false;
  }

  /// 等级筛选变更
  Future<void> _onLevelChanged(String? code) async {
    if (code == _level) return;
    setState(() => _level = code);
    await _loadInitial();
  }

  /// scope 切换（仅 TM/TA）
  Future<void> _onScopeChanged(String scope) async {
    if (scope == _scope) return;
    setState(() => _scope = scope);
    await _loadInitial();
  }

  /// 搜索（空词则取消搜索）
  void _doSearch(String q) {
    final trimmed = q.trim();
    setState(() {
      _query = trimmed.isEmpty ? null : trimmed;
    });
    _loadInitial();
  }

  /// 点击客户卡片 → 跳对应线索详情（仅 leadId 非空跳）
  void _openCustomer(Customer c) {
    if (c.leadId == null || c.leadId!.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LeadDetailPage(leadId: c.leadId!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('客户列表'),
        backgroundColor: const Color(0xFF0052D9),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: _canSwitchScope
            ? [
                PopupMenuButton<String>(
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _scope == 'all' ? '全部' : '我的',
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                  onSelected: _onScopeChanged,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'mine', child: Text('我的客户')),
                    PopupMenuItem(value: 'all', child: Text('全部客户')),
                  ],
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          // 搜索栏
          CustomerSearchBar(
            searchCtrl: _searchCtrl,
            onSearch: _doSearch,
          ),
          // 搜索栏与筛选栏间分隔线
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          // 等级筛选（通栏）
          CustomerFilterBar(
            selectedLevel: _level,
            onLevelChanged: _onLevelChanged,
          ),
          const SizedBox(height: 8),
          // 列表区
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 列表区（骨架 / 错误 / 空态 / 数据）
  Widget _buildList() {
    if (_isLoading) {
      return const CustomerListSkeleton();
    }
    if (_error != null) {
      return _ErrorState(onRetry: _loadInitial);
    }
    if (_items.isEmpty) {
      return _EmptyState(isSearch: _query != null);
    }
    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        ..._items.map((c) => CustomerCard(
              customer: c,
              onTap: () => _openCustomer(c),
            )),
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_page >= _pages)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '没有更多了',
                style: TextStyle(fontSize: 13, color: Color(0xFFA6A6A6)),
              ),
            ),
          ),
      ],
    );
  }
}

/// 错误态（含重试）
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: Color(0xFFDCDCDC)),
          const SizedBox(height: 8),
          const Text('加载失败', style: TextStyle(fontSize: 14, color: Color(0xFF181818))),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

/// 空态
class _EmptyState extends StatelessWidget {
  final bool isSearch;

  const _EmptyState({this.isSearch = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSearch ? Icons.search_off : Icons.people,
              size: 40, color: const Color(0xFFDCDCDC)),
          const SizedBox(height: 8),
          Text(
            isSearch ? '未找到匹配的客户' : '暂无客户',
            style: const TextStyle(fontSize: 14, color: Color(0xFF181818)),
          ),
          if (isSearch)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '请尝试其他关键词',
                style: TextStyle(fontSize: 14, color: Color(0xFFA6A6A6)),
              ),
            ),
        ],
      ),
    );
  }
}
