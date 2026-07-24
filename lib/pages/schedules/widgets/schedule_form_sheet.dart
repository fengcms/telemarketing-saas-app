/// 新建 / 编辑日程抽屉（底部 BottomSheet）
///
/// 设计文档：docs/design/page-design/12-新建日程.md
/// - 作为公共组件，被两处共用：
///   1) 线索详情「日程」按钮 → 创建模式（leadId + 姓名/手机号预填标题）
///   2) 日程详情页「编辑」菜单 → 编辑模式（回填内容/计划时间）
/// - [ScheduleFormContent] 承载全部表单逻辑（含顶部标题行与提交按钮）
/// - [showScheduleFormSheet] 用 showModalBottomSheet 包裹，返回 bool?
///   （true=有变更并保存，false/null=未变更或放弃）
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:telemarketing_app/models/option_item.dart';
import 'package:telemarketing_app/models/schedule_detail.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'package:telemarketing_app/providers/options_provider.dart';
import 'package:telemarketing_app/providers/schedule_list_provider.dart';
import 'package:telemarketing_app/providers/schedule_stats_provider.dart';
import 'package:telemarketing_app/services/api_exception.dart';
import 'package:telemarketing_app/widgets/tag_chip.dart';

part 'schedule_form_fields.dart';

/// 弹出日程表单抽屉
///
/// 创建模式参数：[leadId] 必传 + 可选 [leadName]/[leadPhone]/[prefillContent]
/// 编辑模式参数：[scheduleId] 必传 + [initial]（回填用）
/// 返回 true 表示用户保存了变更，调用方可据此刷新列表/详情缓存。
Future<bool?> showScheduleFormSheet(
  BuildContext context, {
  // 创建模式
  String? leadId,
  String? leadName,
  String? leadPhone,
  String? prefillContent,
  // 编辑模式
  String? scheduleId,
  ScheduleDetail? initial,
}) async {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ScheduleFormContent(
      leadId: leadId,
      leadName: leadName,
      leadPhone: leadPhone,
      prefillContent: prefillContent,
      scheduleId: scheduleId,
      initial: initial,
    ),
  );
}

/// 新建 / 编辑日程表单内容（抽屉内承载）
///
/// 自带：顶部 SheetHeader（标题+关闭×）；中部滚动表单；底部全宽提交按钮。
/// 保存成功 → pop(true)；放弃/关闭 → 确认后 pop(false)。
class ScheduleFormContent extends ConsumerStatefulWidget {
  /// 创建模式：关联线索 ID
  final String? leadId;

  /// 创建模式：关联线索姓名（预填标题用）
  final String? leadName;

  /// 创建模式：关联线索手机号（预填标题用，明文）
  final String? leadPhone;

  /// 创建模式：预填内容（跟进面板入口）
  final String? prefillContent;

  /// 编辑模式：日程 ID
  final String? scheduleId;

  /// 编辑模式：已加载的详情（回填用）
  final ScheduleDetail? initial;

  const ScheduleFormContent({
    super.key,
    this.leadId,
    this.leadName,
    this.leadPhone,
    this.prefillContent,
    this.scheduleId,
    this.initial,
  });

  @override
  ConsumerState<ScheduleFormContent> createState() =>
      _ScheduleFormContentState();
}

class _ScheduleFormContentState extends ConsumerState<ScheduleFormContent> {
  final _contentCtrl = TextEditingController();

  /// 选中的日期（年月日）
  late DateTime _selectedDate;

  /// 选中的时间（时分）
  late TimeOfDay _selectedTime;

  /// 创建模式：自动生成的标题（用户不可见）
  String _autoTitle = '';

  /// 归属人（仅 TM/TA）
  OptionItem? _owner;

  /// 可选归属人列表（TM/TA）
  List<OptionItem> _owners = const [];

  /// 提交中（防重复）
  bool _isSubmitting = false;

  /// 是否有未保存修改（用于返回放弃确认）
  bool _dirty = false;

  /// 计划时间校验错误
  String? _dateError;

  @override
  void initState() {
    super.initState();
    _initFields();
    _loadOwnersIfNeeded();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  /// 按模式回填字段
  void _initFields() {
    final initial = widget.initial;
    if (initial != null) {
      // 编辑：从详情回填（标题保持原值，用户不可改）
      final dt = DateTime.fromMillisecondsSinceEpoch(initial.scheduledAt * 1000);
      _selectedDate = DateTime(dt.year, dt.month, dt.day);
      _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      _contentCtrl.text = initial.content ?? '';
    } else {
      // 创建：计划时间默认 now+1h（取整 5 分钟）
      final base = DateTime.now().add(const Duration(hours: 1));
      _selectedDate = DateTime(base.year, base.month, base.day);
      _selectedTime = TimeOfDay(
        hour: base.hour,
        minute: (base.minute / 5).floor() * 5,
      );
      final name = widget.leadName ?? '';
      final phone = widget.leadPhone ?? '';
      _autoTitle = '🏷️ $name - $phone';
      _contentCtrl.text = widget.prefillContent ?? '';
    }
  }

  /// TM/TA 才加载归属人列表，默认当前用户
  Future<void> _loadOwnersIfNeeded() async {
    final user = ref.read(authProvider).user;
    final isManager = user?.role == 'TM' || user?.role == 'TA';
    if (!isManager) return;
    try {
      final users = await ref.read(optionsCacheProvider).getUsers();
      if (!mounted) return;
      setState(() {
        _owners = users;
        _owner = users.where((u) => u.id == user?.id).firstOrNull ??
            users.firstOrNull;
      });
    } catch (_) {
      // 加载失败：归属人列表空，仍可用默认（当前用户）
    }
  }

  /// 是否编辑模式
  bool get _isEdit => widget.scheduleId != null;

  /// 当前选中的计划时间（Unix 秒）
  int get _scheduledAt {
    final dt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    return dt.millisecondsSinceEpoch ~/ 1000;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 标题行（居中标题 + 右上角小关闭按钮，关闭接 _onBack 脏检查） ──
              Row(
                children: [
                  const Spacer(),
                  Text(
                    _isEdit ? '编辑日程' : '新建日程',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF181818),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _onBack,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close, size: 18,
                          color: Color(0xFFA6A6A6)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── 表单区块 ──
              _buildLeadSection(),
              _buildDateSection(),
              _buildTimeSection(),
              _buildNoteSection(),
              if (_owners.isNotEmpty) _buildOwnerSection(),

              const SizedBox(height: 24),

              // ── 全宽提交按钮 ──
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }


  // ── 操作处理 ──

  /// 关闭 / 取消（有未保存修改则确认放弃）
  Future<void> _onBack() async {
    if (_isSubmitting) return;
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('放弃编辑'),
          content: const Text('当前内容尚未保存，确定要离开吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('继续编辑',
                  style: TextStyle(color: Color(0xFF181818))),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('确定离开',
                  style: TextStyle(color: Color(0xFF0052D9))),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  /// 提交（创建 / 编辑）
  Future<void> _submit() async {
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    if (selected.millisecondsSinceEpoch == 0) {
      setState(() => _dateError = '请选择计划时间');
      return;
    }
    // P1 回归修复：补回「计划时间 ≥ 当前」下限校验（旧 schedule_dialog 的「仅未来」保护在重构时丢失）
    if (selected.isBefore(DateTime.now())) {
      setState(() => _dateError = '计划时间不能早于当前时间');
      return;
    }

    final content = _contentCtrl.text.trim();

    if (_isEdit) {
      final init = widget.initial!;
      final dt = DateTime.fromMillisecondsSinceEpoch(init.scheduledAt * 1000);
      final sameTime = dt.year == _selectedDate.year &&
          dt.month == _selectedDate.month &&
          dt.day == _selectedDate.day &&
          dt.hour == _selectedTime.hour &&
          dt.minute == _selectedTime.minute;
      final sameContent = (init.content ?? '') == content;
      if (sameTime && sameContent) {
        TDToast.showText('内容未变更', context: context);
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final svc = ref.read(scheduleServiceProvider);
      if (_isEdit) {
        await svc.patchSchedule(
          widget.scheduleId!,
          scheduledAt: _scheduledAt,
          content: content.isNotEmpty ? content : null,
        );
        if (!mounted) return;
        TDToast.showText('日程已更新', context: context);
      } else {
        await svc.createSchedule(
          leadId: widget.leadId!,
          scheduledAt: _scheduledAt,
          title: _autoTitle,
          content: content.isNotEmpty ? content : null,
          userId: _owner?.id,
        );
        if (!mounted) return;
        TDToast.showText('日程已创建', context: context);
      }
      try {
        ref.read(scheduleListProvider.notifier).refresh();
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      TDToast.showText(e.message, context: context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      TDToast.showText('保存失败，请重试', context: context);
    }
  }
}
