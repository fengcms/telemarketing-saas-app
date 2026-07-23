/// 线索详情状态
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/lead_detail.dart';
import 'package:telemarketing_app/models/lead_detail_bundle.dart';
import 'package:telemarketing_app/models/follow_up_record.dart';
import 'package:telemarketing_app/models/call_record.dart';
import 'package:telemarketing_app/models/schedule.dart';
import 'package:telemarketing_app/models/lead_list_context.dart';
import 'package:telemarketing_app/services/lead_service.dart';
import 'package:telemarketing_app/services/lead_detail_cache.dart';
import 'auth_provider.dart';
import 'lead_list_provider.dart';

// ── 线索详情状态 ──

/// 线索详情状态
///
/// 重构为单一聚合源 [bundle]：一次请求拿齐 lead / followups /
/// calls(≤5) / schedules(≤5)，各区块通过 getter 取数。
class LeadDetailState {
  /// 是否正在首次加载（缓存未命中时）
  final bool isLoading;

  /// 聚合数据（缓存命中或请求成功后为非 null）
  final LeadDetailBundle? bundle;

  /// 加载错误（bundle 为 null 时有效）
  final String? error;

  /// 列表上下文（决定底部导航条显隐）
  final LeadListContext? listContext;

  const LeadDetailState({
    this.isLoading = true,
    this.bundle,
    this.error,
    this.listContext,
  });

  LeadDetailState copyWith({
    bool? isLoading,
    Object? bundle = _unset,
    Object? error = _unset,
    Object? listContext = _unset,
  }) {
    return LeadDetailState(
      isLoading: isLoading ?? this.isLoading,
      bundle: bundle is _Unset ? this.bundle : bundle as LeadDetailBundle?,
      error: error is _Unset ? this.error : error as String?,
      listContext:
          listContext is _Unset ? this.listContext : listContext as LeadListContext?,
    );
  }

  // ── 便捷 getter：代理到 bundle，兼容既有 widget 读取 ──

  /// 线索对象
  LeadDetail? get detail => bundle?.lead;

  /// 全量跟进时间线
  List<FollowUpRecord> get allFollowUps => bundle?.followups ?? const [];

  /// 最近通话
  List<CallRecord> get calls => bundle?.calls ?? const [];

  /// 最近日程
  List<Schedule> get schedules => bundle?.schedules ?? const [];

  /// 是否处于错误态（无数据）
  bool get hasError => error != null;
}

class _Unset {
  const _Unset();
}
const _unset = _Unset();

// ── Provider ──

/// 线索详情缓存（内存，10 分钟 TTL）
final leadDetailCacheProvider = Provider<LeadDetailCache>((ref) {
  return LeadDetailCache();
});

// ── Notifier ──

/// 线索详情状态管理器
class LeadDetailNotifier extends StateNotifier<LeadDetailState> {
  final Ref _ref;
  late final LeadService _service;
  late final LeadDetailCache _cache;
  String? _currentLeadId;

  LeadDetailNotifier(this._ref) : super(const LeadDetailState()) {
    _service = _ref.read(leadServiceProvider);
    _cache = _ref.read(leadDetailCacheProvider);
  }

  /// 加载线索详情
  ///
  /// 缓存优先：命中即秒开渲染，并后台静默刷新 + 预加载下一个；
  /// 未命中则显示骨架屏，单请求拉取后写入缓存。
  ///
  /// [leadId] 线索 ID
  /// [listContext] 从列表页携带的列表上下文（可选）
  /// [raw] TA/TM 角色传 true 获取明文姓名/电话
  Future<void> loadLead({
    required String leadId,
    LeadListContext? listContext,
    bool raw = false,
  }) async {
    _currentLeadId = leadId;

    final cached = _cache.get(leadId);
    if (cached != null) {
      // 秒开：直接渲染缓存，后台刷新保证新鲜
      state = LeadDetailState(
        isLoading: false,
        bundle: cached,
        listContext: listContext,
      );
      unawaited(_fetchBundle(leadId, raw));
      unawaited(_preloadNext(listContext));
      return;
    }

    state = LeadDetailState(isLoading: true, listContext: listContext);
    await _fetchBundle(leadId, raw);
    await _preloadNext(listContext);
  }

  /// 重新加载当前线索
  void reload() {
    if (_currentLeadId == null) return;
    loadLead(leadId: _currentLeadId!, listContext: state.listContext);
  }

  /// 单请求拉取聚合数据并写入缓存
  ///
  /// [raw] TA/TM 角色传 true。
  /// 失败时：若当前已有数据则静默保留（后台刷新场景），
  /// 仅当无任何数据时展示错误。
  Future<void> _fetchBundle(String leadId, bool raw) async {
    try {
      final bundle = await _service.fetchLeadDetail(id: leadId, raw: raw);
      // 先无条件写入缓存：保证数据新鲜（即便本次结果因导航离开而不展示）
      if (bundle != null) _cache.put(leadId, bundle);
      // 守卫：仅当「本次请求对应的线索，仍是当前正在查看的线索」时才写回 UI。
      // 避免上一个/下一个线索的静默刷新（unawaited）姗姗来迟时覆盖当前页 → 闪跳。
      if (mounted && leadId == _currentLeadId) {
        state = state.copyWith(
          isLoading: false,
          bundle: bundle,
          error: bundle == null ? '线索已删除或不存在' : null,
        );
      }
    } catch (e) {
      if (mounted && leadId == _currentLeadId && state.bundle == null) {
        state = state.copyWith(isLoading: false, error: '加载失败，请重试');
      }
    }
  }

  /// 预加载下一个线索（底部导航条存在时）
  ///
  /// 后台静默拉取并写入缓存，供「下一个」秒开。
  /// 已缓存或加载失败均不影响主流程。
  Future<void> _preloadNext(LeadListContext? ctx) async {
    if (ctx == null || !ctx.hasNext) return;
    final nextId = ctx.nextId;
    if (nextId == null || _cache.get(nextId) != null) return;
    try {
      final bundle = await _service.fetchLeadDetail(id: nextId);
      if (bundle != null) _cache.put(nextId, bundle);
    } catch (_) {
      // 预加载失败静默忽略
    }
  }

  // ── 写操作后刷新 ──

  /// 任一写操作后调用：失效缓存 + 单请求整体刷新。
  ///
  /// 保留旧 bundle 显示，后台拉取新数据后无缝替换。
  Future<void> refreshBundle() async {
    if (_currentLeadId == null) return;
    _cache.invalidate(_currentLeadId!);
    final user = _ref.read(authProvider).user;
    final raw = user?.role == 'tenant_admin' || user?.role == 'tenant_manager';
    unawaited(_fetchBundle(_currentLeadId!, raw));
  }

  // ── 底部导航条 ──

  /// 切换到上一个线索
  Future<void> goToPrev() async {
    final ctx = state.listContext;
    if (ctx == null || !ctx.hasPrev) return;
    final prevId = ctx.prevId;
    if (prevId == null) return;
    await loadLead(leadId: prevId, listContext: ctx.prev());
  }

  /// 切换到下一个线索
  Future<void> goToNext() async {
    final ctx = state.listContext;
    if (ctx == null || !ctx.hasNext) return;
    final nextId = ctx.nextId;
    if (nextId == null) return;
    await loadLead(leadId: nextId, listContext: ctx.next());
  }

  /// 移除已失效的线索 ID 并跳转下一条
  void skipRemoved(String removedId) {
    final ctx = state.listContext;
    if (ctx == null) return;
    final newCtx = ctx.skipAndNext(removedId: removedId);
    if (newCtx.hasNext || newCtx.hasPrev) {
      loadLead(
        leadId: newCtx.ids[newCtx.index],
        listContext: newCtx,
      );
    }
  }
}

// ── Provider ──

final leadDetailProvider =
    StateNotifierProvider<LeadDetailNotifier, LeadDetailState>((ref) {
  return LeadDetailNotifier(ref);
});
