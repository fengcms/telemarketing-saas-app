/// 日程搜索页
///
/// 从线索详情「最近日程 → 查看全部」跳入，按手机号搜索日程。
/// 使用局部 state（不碰全局 scheduleListProvider），避免污染底部 Tab 日程状态。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';
import 'package:telemarketing_app/models/schedule.dart';
import 'package:telemarketing_app/providers/schedule_stats_provider.dart';
import 'package:telemarketing_app/providers/options_provider.dart';
import 'package:telemarketing_app/pages/schedules/widgets/schedule_card.dart';
import 'package:telemarketing_app/pages/schedules/widgets/schedule_skeleton.dart';
import 'package:telemarketing_app/pages/schedules/schedule_detail_page.dart';
import 'package:telemarketing_app/widgets/app_search_bar.dart';

/// 日程搜索页（按手机号）
class ScheduleSearchPage extends ConsumerStatefulWidget {
  /// 初始搜索词（手机号）
  final String? initialQuery;

  const ScheduleSearchPage({super.key, this.initialQuery});

  @override
  ConsumerState<ScheduleSearchPage> createState() =>
      _ScheduleSearchPageState();
}

class _ScheduleSearchPageState extends ConsumerState<ScheduleSearchPage> {
  final List<Schedule> _items = [];
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  String? _query; // 搜索词（null = 不搜）
  int _page = 1;
  int _total = 0;
  int _serverTime = 0;

  bool _isLoading = true; // 首屏骨架
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _isFetching = false; // 重入锁
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    // 监听输入变化，实时切换清除按钮显隐
    _searchCtrl.addListener(_onSearchChanged);
    // 从线索详情跳来时预填搜索词，首屏即带 q 查询
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchCtrl.text = widget.initialQuery!;
      _query = widget.initialQuery;
    }
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  /// 输入变化 → 刷新清除按钮显隐
  void _onSearchChanged() => setState(() {});

  /// 滚动到底部阈值 → 加载下一页
  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  /// 首屏 / 刷新 / 搜索后重拉第一页
  Future<void> _loadInitial() async {
    if (_isFetching) return;
    _isFetching = true;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await ref.read(scheduleServiceProvider).fetchSchedules(
            q: _query,
            statusIn: 'pending,completed,cancelled', // 取全部状态
            page: 1,
          );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.items);
        _page = 1;
        _total = res.total;
        _serverTime = res.serverTime;
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
    if (_isLoadingMore || _isLoading || _items.length >= _total) return;
    setState(() => _isLoadingMore = true);
    try {
      final next = _page + 1;
      final res = await ref.read(scheduleServiceProvider).fetchSchedules(
            q: _query,
            statusIn: 'pending,completed,cancelled',
            page: next,
          );
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items);
        _page = next;
        _total = res.total;
        _serverTime = res.serverTime;
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

  /// 搜索（空词则取消搜索）
  void _doSearch(String q) {
    final trimmed = q.trim();
    setState(() {
      _query = trimmed.isEmpty ? null : trimmed;
    });
    _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日程搜索'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
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

  /// 搜索栏（复用公共 AppSearchBar，与线索列表/通话记录搜索栏表现一致）
  Widget _buildSearchBar() {
    return AppSearchBar(
      controller: _searchCtrl,
      onSearch: _doSearch,
      hintText: '搜索手机号',
      keyboardType: TextInputType.phone,
    );
  }

  /// 列表区（骨架 / 错误 / 空态 / 数据）
  Widget _buildList() {
    if (_isLoading) {
      return const ScheduleSkeleton();
    }
    if (_error != null) {
      return _ErrorState(onRetry: _loadInitial);
    }
    if (_items.isEmpty) {
      return _EmptyState(isSearch: _query != null);
    }
    // 归属人姓名统一解析（去重 watch，保留 id 兜底）
    final ownerNames = <String, String>{};
    for (final item in _items) {
      final id = item.userId;
      if (id != null && id.isNotEmpty) {
        ownerNames[id] = ref.watch(userNameProvider(id)).value ?? id;
      }
    }

    return ListView(
      controller: _scrollCtrl,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8),
      children: [
        ..._items.map(
          (s) => ScheduleCard(
            schedule: s,
            serverTime: _serverTime,
            ownerName: ownerNames[s.userId],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ScheduleDetailPage(scheduleId: s.id),
                ),
              );
            },
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
        else if (_items.length >= _total)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '没有更多了',
                style: TextStyle(fontSize: 13, color: BrandColors.textSecondary),
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
          const Text('加载失败',
              style: TextStyle(fontSize: 14, color: BrandColors.textPrimary)),
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
          Icon(
            isSearch ? Icons.search_off : Icons.event_note,
            size: 40,
            color: const Color(0xFFDCDCDC),
          ),
          const SizedBox(height: 8),
          Text(
            isSearch ? '未找到相关日程' : '暂无日程',
            style: const TextStyle(fontSize: 14, color: BrandColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
