import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lead.dart';
import '../models/option_item.dart';
import '../services/api_client.dart';
import '../services/lead_service.dart';
import 'auth_provider.dart';

// ── Providers ──

final leadServiceProvider = Provider<LeadService>((ref) {
  return LeadService(apiClient: ref.read(apiClientProvider));
});

/// 用于区分"未传参"和"传 null"的 sentinel 值
class _Unset {
  const _Unset();
}
const _unset = _Unset();

/// 线索列表状态
class LeadListState {
  final bool isInitialLoading;
  final List<Lead> leads;
  final int total;
  final int currentPage;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  // 搜索/筛选/排序
  final String keyword;
  final String? statusFilter;   // status__in
  final String? categoryId;
  final String? projectId;
  final int? dateFrom;
  final int? dateTo;
  final String sortBy;          // -updatedAt / nextFollowupAt

  // 缓存选项数据
  final List<OptionItem> categories;
  final List<OptionItem> projects;
  final bool isLoadingOptions;

  const LeadListState({
    this.isInitialLoading = true,
    this.leads = const [],
    this.total = 0,
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.errorMessage,
    this.keyword = '',
    this.statusFilter,
    this.categoryId,
    this.projectId,
    this.dateFrom,
    this.dateTo,
    this.sortBy = '-updatedAt',
    this.categories = const [],
    this.projects = const [],
    this.isLoadingOptions = false,
  });

  LeadListState copyWith({
    bool? isInitialLoading,
    List<Lead>? leads,
    int? total,
    int? currentPage,
    bool? isLoadingMore,
    bool? hasMore,
    Object? errorMessage = _unset,
    String? keyword,
    Object? statusFilter = _unset,
    Object? categoryId = _unset,
    Object? projectId = _unset,
    Object? dateFrom = _unset,
    Object? dateTo = _unset,
    String? sortBy,
    List<OptionItem>? categories,
    List<OptionItem>? projects,
    bool? isLoadingOptions,
  }) {
    return LeadListState(
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      leads: leads ?? this.leads,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage is _Unset ? this.errorMessage : errorMessage as String?,
      keyword: keyword ?? this.keyword,
      statusFilter: statusFilter is _Unset ? this.statusFilter : statusFilter as String?,
      categoryId: categoryId is _Unset ? this.categoryId : categoryId as String?,
      projectId: projectId is _Unset ? this.projectId : projectId as String?,
      dateFrom: dateFrom is _Unset ? this.dateFrom : dateFrom as int?,
      dateTo: dateTo is _Unset ? this.dateTo : dateTo as int?,
      sortBy: sortBy ?? this.sortBy,
      categories: categories ?? this.categories,
      projects: projects ?? this.projects,
      isLoadingOptions: isLoadingOptions ?? this.isLoadingOptions,
    );
  }

  /// 是否有激活的筛选条件
  bool get hasActiveFilters =>
      (statusFilter != null && statusFilter!.isNotEmpty) ||
      (categoryId != null && categoryId!.isNotEmpty) ||
      (projectId != null && projectId!.isNotEmpty) ||
      dateFrom != null ||
      dateTo != null;

  /// 激活的筛选条件数量
  int get activeFilterCount {
    int count = 0;
    if (statusFilter != null && statusFilter!.isNotEmpty) count++;
    if (categoryId != null && categoryId!.isNotEmpty) count++;
    if (projectId != null && projectId!.isNotEmpty) count++;
    if (dateFrom != null || dateTo != null) count++;
    return count;
  }
}

class LeadListNotifier extends StateNotifier<LeadListState> {
  final Ref _ref;

  LeadListNotifier(this._ref) : super(const LeadListState()) {
    _loadInitial();
  }

  String get _scope {
    final user = _ref.read(authProvider).user;
    if (user?.role == 'tenant_manager' || user?.role == 'tenant_admin') {
      return 'all';
    }
    return 'mine';
  }

  // ── 首屏加载 ──

  Future<void> _loadInitial() async {
    state = const LeadListState();
    final service = _ref.read(leadServiceProvider);

    // 并行请求数据 + 缓存选项
    final results = await Future.wait([
      _fetchPage(service, 1),
      _loadOptions(service),
    ]);

    final pageResult = results[0] as ({List<Lead> leads, int total});
    state = state.copyWith(
      isInitialLoading: false,
      leads: pageResult.leads,
      total: pageResult.total,
      currentPage: 1,
      hasMore: pageResult.leads.length < pageResult.total,
    );
  }

  Future<({List<Lead> leads, int total})> _fetchPage(
      LeadService service, int page) async {
    try {
      return await service.fetchLeads(
        scope: _scope,
        page: page,
        keyword: state.keyword.isNotEmpty ? state.keyword : null,
        statusIn: state.statusFilter,
        categoryId: state.categoryId,
        projectId: state.projectId,
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
        sort: state.sortBy,
      );
    } catch (e) {
      return (leads: <Lead>[], total: 0);
    }
  }

  Future<void> _loadOptions(LeadService service) async {
    try {
      final results = await Future.wait([
        service.fetchCategories(),
        service.fetchProjects(),
      ]);
      final cats = results[0] as List<OptionItem>;
      final projs = results[1] as List<OptionItem>;
      state = state.copyWith(categories: cats, projects: projs);
    } catch (_) {}
  }

  // ── 搜索 ──

  /// 按关键词搜索（用户点击搜索按钮或键盘回车时触发）
  void search(String keyword) {
    state = state.copyWith(keyword: keyword, isInitialLoading: true);
    _ref.read(leadServiceProvider).fetchLeads(
      scope: _scope,
      page: 1,
      keyword: keyword.isNotEmpty ? keyword : null,
      statusIn: state.statusFilter,
      categoryId: state.categoryId,
      projectId: state.projectId,
      dateFrom: state.dateFrom,
      dateTo: state.dateTo,
      sort: state.sortBy,
    ).then((result) {
      if (mounted) {
        state = state.copyWith(
          isInitialLoading: false,
          leads: result.leads,
          total: result.total,
          currentPage: 1,
          hasMore: result.leads.length < result.total,
        );
      }
    }).catchError((_) {
      if (mounted) {
        state = state.copyWith(
          isInitialLoading: false,
          errorMessage: '搜索失败，请重试',
        );
      }
    });
  }

  // ── 加载更多 ──

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);

    final nextPage = state.currentPage + 1;
    try {
      final service = _ref.read(leadServiceProvider);
      final result = await service.fetchLeads(
        scope: _scope,
        page: nextPage,
        keyword: state.keyword.isNotEmpty ? state.keyword : null,
        statusIn: state.statusFilter,
        categoryId: state.categoryId,
        projectId: state.projectId,
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
        sort: state.sortBy,
      );
      state = state.copyWith(
        isLoadingMore: false,
        leads: [...state.leads, ...result.leads],
        total: result.total,
        currentPage: nextPage,
        hasMore: state.leads.length + result.leads.length < result.total,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  // ── 排序 ──

  void toggleSort() {
    final newSort =
        state.sortBy == '-updatedAt' ? 'nextFollowupAt' : '-updatedAt';
    state = state.copyWith(sortBy: newSort, isInitialLoading: true);
    _reloadPage(1);
  }

  // ── 筛选 ──

  void applyFilters({
    String? statusFilter,
    String? categoryId,
    String? projectId,
    int? dateFrom,
    int? dateTo,
  }) {
    state = state.copyWith(
      statusFilter: statusFilter,
      categoryId: categoryId,
      projectId: projectId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      isInitialLoading: true,
    );
    _reloadPage(1);
  }

  void clearFilter(String key) {
    switch (key) {
      case 'status':
        state = state.copyWith(statusFilter: null, isInitialLoading: true);
        break;
      case 'category':
        state = state.copyWith(categoryId: null, isInitialLoading: true);
        break;
      case 'project':
        state = state.copyWith(projectId: null, isInitialLoading: true);
        break;
      case 'date':
        state = state.copyWith(
            dateFrom: null, dateTo: null, isInitialLoading: true);
        break;
    }
    _reloadPage(1);
  }

  void resetFilters() {
    state = state.copyWith(
      statusFilter: null,
      categoryId: null,
      projectId: null,
      dateFrom: null,
      dateTo: null,
      isInitialLoading: true,
    );
    _reloadPage(1);
  }

  // ── 下拉刷新 ──

  Future<void> refresh() async {
    state = state.copyWith(isInitialLoading: true);
    _reloadPage(1);
  }

  void _reloadPage(int page) {
    _ref.read(leadServiceProvider).fetchLeads(
      scope: _scope,
      page: page,
      keyword: state.keyword.isNotEmpty ? state.keyword : null,
      statusIn: state.statusFilter,
      categoryId: state.categoryId,
      projectId: state.projectId,
      dateFrom: state.dateFrom,
      dateTo: state.dateTo,
      sort: state.sortBy,
    ).then((result) {
      if (mounted) {
        state = state.copyWith(
          isInitialLoading: false,
          leads: result.leads,
          total: result.total,
          currentPage: page,
          hasMore: result.leads.length < result.total,
          errorMessage: null,
        );
      }
    }).catchError((e) {
      if (mounted) {
        state = state.copyWith(
          isInitialLoading: false,
          errorMessage: '加载失败，请重试',
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}

final leadListProvider =
    StateNotifierProvider<LeadListNotifier, LeadListState>((ref) {
  return LeadListNotifier(ref);
});
