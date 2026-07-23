/// 线索详情状态
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lead_detail.dart';
import '../models/follow_up_record.dart';
import '../models/call_record.dart';
import '../models/lead_list_context.dart';
import '../services/lead_service.dart';
import 'auth_provider.dart';
import 'lead_list_provider.dart';

// ── 线索详情状态 ──

/// 线索详情状态
class LeadDetailState {
  // 线索详情
  final bool isLoadingDetail;
  final LeadDetail? detail;
  final String? detailError;

  // 跟进时间线
  final bool isLoadingFollowUps;
  final List<FollowUpRecord> allFollowUps; // 全量数据
  final String? followUpsError;

  // 通话记录摘要
  final bool isLoadingCalls;
  final List<CallRecord> calls;
  final int callsTotal;
  final String? callsError;

  // 列表上下文（底部导航条用）
  final LeadListContext? listContext;

  const LeadDetailState({
    this.isLoadingDetail = true,
    this.detail,
    this.detailError,
    this.isLoadingFollowUps = true,
    this.allFollowUps = const [],
    this.followUpsError,
    this.isLoadingCalls = true,
    this.calls = const [],
    this.callsTotal = 0,
    this.callsError,
    this.listContext,
  });

  LeadDetailState copyWith({
    bool? isLoadingDetail,
    Object? detail = _unset,
    Object? detailError = _unset,
    bool? isLoadingFollowUps,
    List<FollowUpRecord>? allFollowUps,
    Object? followUpsError = _unset,
    bool? isLoadingCalls,
    List<CallRecord>? calls,
    int? callsTotal,
    Object? callsError = _unset,
    Object? listContext = _unset,
  }) {
    return LeadDetailState(
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      detail: detail is _Unset ? this.detail : detail as LeadDetail?,
      detailError: detailError is _Unset
          ? this.detailError
          : detailError as String?,
      isLoadingFollowUps:
          isLoadingFollowUps ?? this.isLoadingFollowUps,
      allFollowUps: allFollowUps ?? this.allFollowUps,
      followUpsError: followUpsError is _Unset
          ? this.followUpsError
          : followUpsError as String?,
      isLoadingCalls: isLoadingCalls ?? this.isLoadingCalls,
      calls: calls ?? this.calls,
      callsTotal: callsTotal ?? this.callsTotal,
      callsError: callsError is _Unset
          ? this.callsError
          : callsError as String?,
      listContext: listContext is _Unset
          ? this.listContext
          : listContext as LeadListContext?,
    );
  }

  /// 所有数据是否都已加载完成
  bool get isAllLoaded =>
      !isLoadingDetail && !isLoadingFollowUps && !isLoadingCalls;

  /// 是否有加载错误
  bool get hasAnyError =>
      detailError != null ||
      followUpsError != null ||
      callsError != null;
}

class _Unset {
  const _Unset();
}
const _unset = _Unset();

// ── Notifier ──

/// 线索详情状态管理器
class LeadDetailNotifier extends StateNotifier<LeadDetailState> {
  final Ref _ref;
  late final LeadService _service;
  String? _currentLeadId;
  StreamSubscription? _authSub;

  LeadDetailNotifier(this._ref) : super(const LeadDetailState()) {
    _service = _ref.read(leadServiceProvider);
  }

  /// 加载线索详情
  ///
  /// [leadId] 线索 ID
  /// [listContext] 从列表页携带的列表上下文（可选）
  /// [raw] TA 角色传 true
  Future<void> loadLead({
    required String leadId,
    LeadListContext? listContext,
    bool raw = false,
  }) async {
    _currentLeadId = leadId;
    state = LeadDetailState(listContext: listContext);

    // 并行发起 3 个请求，使用 unawaited 避免分析警告
    unawaited(Future.wait([
      _fetchDetail(leadId, raw),
      _fetchFollowUps(leadId),
      _fetchCalls(leadId),
    ]));
  }

  /// 重新加载当前线索
  void reload() {
    if (_currentLeadId == null) return;
    loadLead(leadId: _currentLeadId!, listContext: state.listContext);
  }

  // ── 数据获取 ──

  Future<void> _fetchDetail(String leadId, bool raw) async {
    try {
      final detail = await _service.fetchLeadDetail(
        id: leadId,
        raw: raw,
      );
      if (mounted) {
        state = state.copyWith(
          isLoadingDetail: false,
          detail: detail,
          detailError: detail == null ? '线索已删除或不存在' : null,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoadingDetail: false,
          detailError: '加载失败，请重试',
        );
      }
    }
  }

  Future<void> _fetchFollowUps(String leadId) async {
    try {
      final items = await _service.fetchFollowUps(leadId);
      if (mounted) {
        state = state.copyWith(
          isLoadingFollowUps: false,
          allFollowUps: items,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoadingFollowUps: false,
          followUpsError: '加载失败',
        );
      }
    }
  }

  Future<void> _fetchCalls(String leadId) async {
    try {
      final result = await _service.fetchCalls(
        leadId: leadId,
        size: 3,
      );
      if (mounted) {
        state = state.copyWith(
          isLoadingCalls: false,
          calls: result.items,
          callsTotal: result.total,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoadingCalls: false,
          callsError: '加载失败',
        );
      }
    }
  }

  // ── 操作回调 ──

  /// 创建跟进记录后刷新跟进时间线（不刷新全部，保持其他数据不变）
  Future<void> refreshFollowUps() async {
    if (_currentLeadId == null) return;
    state = state.copyWith(isLoadingFollowUps: true);
    await _fetchFollowUps(_currentLeadId!);
  }

  /// 刷新通话记录摘要
  Future<void> refreshCalls() async {
    if (_currentLeadId == null) return;
    state = state.copyWith(isLoadingCalls: true);
    await _fetchCalls(_currentLeadId!);
  }

  /// 刷新全部数据
  Future<void> refreshAll() async {
    if (_currentLeadId == null) return;
    // TA/TM 角色传 true 以获取明文姓名/电话
    final user = _ref.read(authProvider).user;
    final raw = user?.role == 'tenant_admin' || user?.role == 'tenant_manager';
    state = LeadDetailState(listContext: state.listContext);
    await Future.wait([
      _fetchDetail(_currentLeadId!, raw),
      _fetchFollowUps(_currentLeadId!),
      _fetchCalls(_currentLeadId!),
    ]);
  }

  // ── 底部导航条 ──

  /// 切换到上一个线索
  Future<void> goToPrev() async {
    final ctx = state.listContext;
    if (ctx == null || !ctx.hasPrev) return;
    final prevId = ctx.prevId!;
    loadLead(
      leadId: prevId,
      listContext: ctx.prev(),
    );
  }

  /// 切换到下一个线索
  Future<void> goToNext() async {
    final ctx = state.listContext;
    if (ctx == null || !ctx.hasNext) return;
    final nextId = ctx.nextId!;
    loadLead(
      leadId: nextId,
      listContext: ctx.next(),
    );
  }

  /// 移除已失效的线索 ID 并跳转下一条
  void skipRemoved(String removedId) {
    final ctx = state.listContext;
    if (ctx == null) return;
    final newCtx = ctx.skipAndNext(removedId: removedId);
    if (newCtx.hasNext || newCtx.hasPrev) {
      loadLead(leadId: newCtx.ids[newCtx.index], listContext: newCtx);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

// ── Provider ──

final leadDetailProvider =
    StateNotifierProvider<LeadDetailNotifier, LeadDetailState>((ref) {
  return LeadDetailNotifier(ref);
});
