/// 日程详情页
///
/// 设计文档：docs/design/page-design/11-日程详情.md
/// - 顶栏返回 + 标题 + ⋮ 菜单（编辑/删除按权限显隐）
/// - 加载骨架屏 / 错误重试 / 404「不存在」 / 403「无权查看」
/// - 标题+状态标签、计划时间卡（逾期红字+标签）、关联线索卡
///   （tap→线索详情；线索擦除显「已删除」不可点且无拨号键）、
///   日程内容卡、其他信息卡（归属人姓名映射）
/// - 底部操作栏（pending：取消/拨号/完成；completed|cancelled：重新打开）
/// - 完成/取消/重开/删除走接口后刷新；拨号走 handleDial
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:telemarketing_app/models/schedule_detail.dart';
import 'package:telemarketing_app/pages/leads/lead_detail_page.dart';
import 'package:telemarketing_app/pages/leads/widgets/dial_helper.dart';
import 'package:telemarketing_app/pages/leads/widgets/follow_up_panel.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'package:telemarketing_app/providers/options_provider.dart';
import 'package:telemarketing_app/providers/schedule_list_provider.dart';
import 'package:telemarketing_app/providers/schedule_stats_provider.dart';
import 'package:telemarketing_app/services/api_exception.dart';
import 'widgets/schedule_form_sheet.dart';
import 'widgets/schedule_detail_cards.dart';
import 'widgets/schedule_detail_actions.dart';

/// 日程详情页
class ScheduleDetailPage extends ConsumerStatefulWidget {
  /// 日程 ID（必传）
  final String scheduleId;

  const ScheduleDetailPage({super.key, required this.scheduleId});

  @override
  ConsumerState<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends ConsumerState<ScheduleDetailPage>
    with SingleTickerProviderStateMixin {
  /// 详情数据（加载完成且非错误态时为非 null）
  ScheduleDetail? _detail;

  /// 归属人姓名（由 userId 本地映射）
  String? _ownerName;

  /// 首屏加载中
  bool _isLoading = true;

  /// 错误码（来自 ApiException.code）：空表示正常
  String? _errorCode;

  /// 错误消息
  String? _errorMessage;

  /// 状态类操作（完成/取消/重开）进行中
  bool _actionLoading = false;

  /// 删除进行中（全屏半透明 loading）
  bool _isDeleting = false;

  /// 骨架屏 shimmer 动画控制器
  late final AnimationController _skeletonCtrl;

  @override
  void initState() {
    super.initState();
    _skeletonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _skeletonCtrl.dispose();
    _actionLoading = false;
    super.dispose();
  }

  /// 加载详情（缓存优先）
  ///
  /// [force] 为 false 时先查缓存：命中即秒开渲染 + 后台静默刷新；
  /// 未命中则显示骨架屏并请求。写操作后调用 [force]=true 仅刷新不闪骨架。
  Future<void> _load({bool force = false}) async {
    if (!mounted) return;
    final cache = ref.read(scheduleDetailCacheProvider);

    if (!force) {
      final cached = cache.get(widget.scheduleId);
      if (cached != null) {
        // 秒开：先渲染缓存
        final owner =
            await ref.read(optionsCacheProvider).getUserName(cached.userId);
        if (!mounted) return;
        setState(() {
          _detail = cached;
          _ownerName = owner;
          _isLoading = false;
          _errorCode = null;
          _errorMessage = null;
        });
        // 后台静默刷新，保证数据新鲜（失败不影响已显示内容）
        unawaited(_fetchFromServer());
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorCode = null;
      _errorMessage = null;
    });
    await _fetchFromServer();
  }

  /// 仅请求服务端并写缓存（不负责骨架屏显隐）
  Future<void> _fetchFromServer() async {
    try {
      final svc = ref.read(scheduleServiceProvider);
      final detail = await svc.fetchScheduleDetail(widget.scheduleId);
      final owner =
          await ref.read(optionsCacheProvider).getUserName(detail.userId);
      if (!mounted) return;
      // 写缓存（含后台刷新场景）
      ref.read(scheduleDetailCacheProvider).put(widget.scheduleId, detail);
      setState(() {
        _detail = detail;
        _ownerName = owner;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      // 已有显示内容时不覆盖（后台刷新失败静默），仅首屏无数据才报错误
      if (!mounted || _detail != null) return;
      setState(() {
        _errorCode = e.code;
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || _detail != null) return;
      setState(() {
        _errorCode = 'UNKNOWN';
        _errorMessage = '加载失败，请稍后重试';
        _isLoading = false;
      });
    }
  }

  /// 当前用户是否可编辑（创建者 / TM / TA）
  bool get _canEdit {
    final user = ref.read(authProvider).user;
    if (user == null || _detail == null) return false;
    return _detail!.userId == user.id ||
        user.role == 'TM' ||
        user.role == 'TA';
  }

  /// 当前用户是否可删除（归属人 / TA）
  bool get _canDelete {
    final user = ref.read(authProvider).user;
    if (user == null || _detail == null) return false;
    return _detail!.userId == user.id || user.role == 'TA';
  }

  /// ⋮ 菜单是否显示（无删除权限则隐藏）
  bool get _showMenu => _canDelete;

  @override
  Widget build(BuildContext context) {
    // 监听用户角色变化（编辑/删除显隐依赖）
    ref.watch(authProvider);
    final showContent = !_isLoading && _errorCode == null && _detail != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildBody()),
                if (showContent && _detail != null)
                  actionBar(
                    isPending: _detail!.status == 'pending',
                    hasLead: _detail!.lead != null,
                    actionLoading: _actionLoading,
                    onCancel: _onCancel,
                    onDial: _onDial,
                    onComplete: _onComplete,
                    onReopen: _onReopen,
                  ),
              ],
            ),
          ),
          // 删除 loading：全屏半透明遮罩 + 居中转圈
          if (_isDeleting)
            const ModalBarrier(dismissible: false, color: Color(0x66000000)),
          if (_isDeleting)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  // ── 顶栏 ──

  Widget _buildTopBar() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFF0052D9),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
            tooltip: '返回',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              '日程详情',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          if (_showMenu)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              tooltip: '更多',
              onSelected: _onMenuSelected,
              itemBuilder: (ctx) => [
                if (_canDelete)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      '删除',
                      style:
                          TextStyle(fontSize: 14, color: Color(0xFFD54941)),
                    ),
                  ),
              ],
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── 主体（状态分发） ──

  Widget _buildBody() {
    if (_isLoading) return scheduleDetailSkeleton(_skeletonCtrl);
    if (_errorCode != null) return _buildErrorState();
    if (_detail == null) return scheduleDetailSkeleton(_skeletonCtrl);
    final d = _detail!;
    return RefreshIndicator(
      onRefresh: () => _load(force: true),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: titleSection(d)),
          SliverToBoxAdapter(child: timeCard(d)),
          SliverToBoxAdapter(
            child: leadCard(
              d,
              d.lead == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LeadDetailPage(leadId: d.leadId),
                        ),
                      ),
            ),
          ),
          SliverToBoxAdapter(child: contentCard(d)),
          SliverToBoxAdapter(child: infoCard(d, _ownerName)),
          SliverToBoxAdapter(child: _buildBottomActions()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  /// 错误态（按错误码区分 404 / 403 / 通用）
  Widget _buildErrorState() {
    final is404 = _errorCode == 'NOT_FOUND';
    final is403 = _errorCode == 'AUTH_FORBIDDEN';
    final title = is404
        ? '该日程不存在或已被删除'
        : is403
            ? '无权查看该日程'
            : '加载失败';
    final message = is404 || is403 ? '' : (_errorMessage ?? '');
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(Icons.event_busy, size: 80, color: Color(0xFFDCDCDC)),
        const SizedBox(height: 16),
        Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF181818),
            ),
          ),
        ),
        if (message.isNotEmpty) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, color: Color(0xFFA6A6A6)),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              is404 || is403 ? '返回列表' : '重新加载',
              style: const TextStyle(color: Color(0xFF0052D9)),
            ),
          ),
        ),
      ],
    );
  }

  /// 底部操作栏（跟进 / 日程 / 编辑），追加在信息卡片下方
  Widget _buildBottomActions() {
    final d = _detail;
    if (d == null || d.lead == null) return const SizedBox.shrink();
    final lead = d.lead!;
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          actionButton(
            icon: TDIcons.rollback,
            label: '跟进',
            onTap: () => showFollowUpPanel(context, leadId: d.leadId),
          ),
          actionButton(
            icon: TDIcons.calendar,
            label: '日程',
            onTap: () async {
              final changed = await showScheduleFormSheet(
                context,
                leadId: d.leadId,
                leadName: lead.name,
                leadPhone: lead.phone,
              );
              if (changed == true && mounted) {
                ref.read(scheduleListProvider.notifier).refresh();
                ref.read(scheduleDetailCacheProvider).invalidate(d.id);
                await _fetchFromServer();
              }
            },
          ),
          actionButton(
            icon: TDIcons.edit,
            label: '编辑',
            onTap: _canEdit ? () => _onEdit() : null,
          ),
        ],
      ),
    );
  }

  // ── 操作处理 ──

  /// ⋮ 菜单选择分发
  void _onMenuSelected(String value) {
    if (value == 'delete') _onDelete();
  }

  /// 编辑（弹底部抽屉表单，回填当前数据；保存后失效缓存并刷新）
  Future<void> _onEdit() async {
    final d = _detail;
    if (d == null) return;
    final changed = await showScheduleFormSheet(
      context,
      scheduleId: d.id,
      initial: d,
    );
    if (changed == true && mounted) {
      ref.read(scheduleDetailCacheProvider).invalidate(d.id);
      await _fetchFromServer();
    }
  }

  /// 标记完成
  /// 执行状态类操作（完成/取消/重开）的通用样板
  ///
  /// [toastMsg] 成功后提示；[apiCall] 实际接口调用。统一处理 _actionLoading 守卫 +
  /// 接口 + 失效缓存 + 刷新详情 + 刷新列表 + 异常 toast + finally 复位。
  Future<void> _runStatusAction({
    required String toastMsg,
    required Future<void> Function() apiCall,
  }) async {
    if (_actionLoading || _detail == null) return;
    setState(() => _actionLoading = true);
    try {
      await apiCall();
      if (!mounted) return;
      TDToast.showText(toastMsg, context: context);
      ref.read(scheduleDetailCacheProvider).invalidate(_detail!.id);
      await _fetchFromServer();
      _refreshList();
    } on ApiException catch (e) {
      if (!mounted) return;
      TDToast.showText(e.message, context: context);
    } catch (_) {
      if (!mounted) return;
      TDToast.showText('操作失败，请重试', context: context);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  /// 标记完成
  Future<void> _onComplete() => _runStatusAction(
        toastMsg: '日程已完成',
        apiCall: () =>
            ref.read(scheduleServiceProvider).completeSchedule(_detail!.id),
      );

  /// 取消（确认弹窗 → 接口 → 刷新）
  Future<void> _onCancel() async {
    if (_actionLoading || _detail == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('取消日程'),
        content: const Text('确定要取消该日程吗？取消后可重新打开。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消操作', style: TextStyle(color: Color(0xFF181818))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定取消', style: TextStyle(color: Color(0xFF0052D9))),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _runStatusAction(
      toastMsg: '日程已取消',
      apiCall: () =>
          ref.read(scheduleServiceProvider).cancelSchedule(_detail!.id),
    );
  }

  /// 重新打开
  Future<void> _onReopen() => _runStatusAction(
        toastMsg: '日程已重新打开',
        apiCall: () =>
            ref.read(scheduleServiceProvider).reopenSchedule(_detail!.id),
      );

  /// 删除（确认弹窗 → 全屏 loading → 返回列表并刷新）
  Future<void> _onDelete() async {
    if (_detail == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除日程'),
        content: const Text('确定删除该日程？删除后不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消', style: TextStyle(color: Color(0xFF181818))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除', style: TextStyle(color: Color(0xFFD54941))),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isDeleting = true);
    try {
      await ref.read(scheduleServiceProvider).deleteSchedule(_detail!.id);
      if (!mounted) return;
      ref.read(scheduleDetailCacheProvider).invalidate(_detail!.id);
      _refreshList();
      TDToast.showText('日程已删除', context: context);
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      TDToast.showText(e.message, context: context);
      setState(() => _isDeleting = false);
    } catch (_) {
      if (!mounted) return;
      TDToast.showText('删除失败，请重试', context: context);
      setState(() => _isDeleting = false);
    }
  }

  /// 拨号（走 handleDial，含夜间禁呼判断）
  Future<void> _onDial() async {
    final lead = _detail?.lead;
    if (lead == null) return;
    await handleDial(phone: lead.phone, context: context);
  }

  /// 触发列表页刷新（返回后数据一致）
  void _refreshList() {
    try {
      ref.read(scheduleListProvider.notifier).refresh();
    } catch (_) {
      // 列表未挂载或无需刷新时静默
    }
  }
}
