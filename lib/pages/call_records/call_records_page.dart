/// 通话记录列表页
///
/// 设计文档 §2.1 + §4。
/// 功能：手机号搜索 + 接听类型筛选、下拉刷新、无限滚动加载、
/// 骨架/空态/错误态。行点击直接跳对应线索详情页（通话详情页不单独开发）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/call_record.dart';
import 'package:telemarketing_app/providers/call_service_provider.dart';
import 'package:telemarketing_app/pages/call_records/widgets/call_filter_bar.dart';
import 'package:telemarketing_app/pages/call_records/widgets/call_search_bar.dart';
import 'package:telemarketing_app/pages/call_records/widgets/call_record_row.dart';
import 'package:telemarketing_app/pages/call_records/widgets/call_list_skeleton.dart';
import 'package:telemarketing_app/pages/leads/lead_detail_page.dart';

/// 通话记录列表页
class CallRecordsPage extends ConsumerStatefulWidget {
  const CallRecordsPage({super.key});

  @override
  ConsumerState<CallRecordsPage> createState() => _CallRecordsPageState();
}

class _CallRecordsPageState extends ConsumerState<CallRecordsPage> {
  final List<CallRecord> _items = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  String? _phoneQuery; // 手机号搜索词（null = 不搜）
  String? _answerType; // null = 全部

  int _page = 1;
  int _pages = 1;

  bool _isLoading = true; // 初始加载（骨架）
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _isFetching = false; // 拉第一页重入锁（首屏/刷新/筛选共用）
  String? _error;

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
  /// initState 里的首次调用被自己短路、永不发请求。
  Future<void> _loadInitial() async {
    if (_isFetching) return;
    _isFetching = true;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await ref.read(callServiceProvider).fetchMyCalls(
            q: _phoneQuery,
            answerType: _answerType,
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
      final res = await ref.read(callServiceProvider).fetchMyCalls(
            q: _phoneQuery,
            answerType: _answerType,
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

  /// 接听类型筛选变更
  Future<void> _onAnswerTypeChanged(String? code) async {
    if (code == _answerType) return;
    setState(() => _answerType = code);
    await _loadInitial();
  }

  /// 手机号搜索（空词则取消搜索）
  void _doSearch(String q) {
    final trimmed = q.trim();
    setState(() {
      _phoneQuery = trimmed.isEmpty ? null : trimmed;
    });
    _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通话记录'),
        backgroundColor: const Color(0xFF0052D9),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 手机号搜索栏
          CallSearchBar(
            searchCtrl: _searchCtrl,
            onSearch: _doSearch,
          ),
          // 接听类型筛选
          CallFilterBar(
            selectedAnswerType: _answerType,
            onAnswerTypeChanged: _onAnswerTypeChanged,
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
      return const CallListSkeleton();
    }
    if (_error != null) {
      return _ErrorState(onRetry: _loadInitial);
    }
    if (_items.isEmpty) {
      return _EmptyState(isSearch: _phoneQuery != null);
    }
    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        ..._items.map(
          (r) => CallRecordRow(
            record: r,
            // 仅当关联线索存在时跳详情；空号/停机等无 leadId 的记录不响应点击
            onTap: r.leadId.isNotEmpty
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LeadDetailPage(leadId: r.leadId),
                      ),
                    );
                  }
                : null,
          ),
        ),
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
          Icon(isSearch ? Icons.search_off : Icons.call,
              size: 40, color: const Color(0xFFDCDCDC)),
          const SizedBox(height: 8),
          Text(
            isSearch ? '未找到相关通话' : '暂无通话记录',
            style: const TextStyle(fontSize: 14, color: Color(0xFF181818)),
          ),
          if (isSearch)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '请尝试其他手机号',
                style: TextStyle(fontSize: 14, color: Color(0xFFA6A6A6)),
              ),
            ),
        ],
      ),
    );
  }
}
