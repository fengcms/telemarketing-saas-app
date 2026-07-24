/// 新建 / 编辑日程抽屉（底部 BottomSheet）
///
/// 设计文档：docs/design/page-design/12-新建日程.md
/// - 作为公共组件，被两处共用：
///   1) 线索详情「日程」按钮 → 创建模式（leadId + 姓名/手机号预填标题）
///   2) 日程详情页「编辑」菜单 → 编辑模式（回填标题/内容/计划时间）
/// - [ScheduleFormContent] 承载全部表单逻辑（含抽屉头部与底部操作行）
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
  final screenH = MediaQuery.of(context).size.height;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => Container(
      constraints: BoxConstraints(maxHeight: screenH * 0.92),
      child: ScheduleFormContent(
        leadId: leadId,
        leadName: leadName,
        leadPhone: leadPhone,
        prefillContent: prefillContent,
        scheduleId: scheduleId,
        initial: initial,
      ),
    ),
  );
}

/// 新建 / 编辑日程表单内容（抽屉内承载）
///
/// 自带：顶部拖动把手 + 标题 + 关闭×；中部滚动表单；底部取消/保存操作行。
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
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  /// 选中的日期（年月日）
  late DateTime _selectedDate;

  /// 选中的时间（时分）
  late TimeOfDay _selectedTime;

  /// 归属人（仅 TM/TA）
  OptionItem? _owner;

  /// 可选归属人列表（TM/TA）
  List<OptionItem> _owners = const [];

  /// 提交中（防重复）
  bool _isSubmitting = false;

  /// 是否有未保存修改（用于返回放弃确认）
  bool _dirty = false;

  /// 计划时间校验错误（非空时在时间卡片下方展示）
  String? _dateError;

  @override
  void initState() {
    super.initState();
    _initFields();
    _loadOwnersIfNeeded();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  /// 按模式回填字段
  void _initFields() {
    final initial = widget.initial;
    if (initial != null) {
      // 编辑：从详情回填
      final dt = DateTime.fromMillisecondsSinceEpoch(initial.scheduledAt * 1000);
      _selectedDate = DateTime(dt.year, dt.month, dt.day);
      _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      _titleCtrl.text = initial.title;
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
      _titleCtrl.text = '🏷️ $name - $phone';
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
    return Column(
      children: [
        _buildSheetHeader(),
        Expanded(child: _buildBody()),
        _buildActionBar(),
      ],
    );
  }

  // ── 抽屉头部 ──

  Widget _buildSheetHeader() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _isEdit ? '编辑日程' : '新建日程',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF181818),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF181818), size: 22),
              tooltip: '关闭',
              onPressed: _onBack,
            ),
            const SizedBox(width: 4),
          ],
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  // ── 主体 ──

  Widget _buildBody() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 16 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeadSection(),
          _buildDateSection(),
          _buildTimeSection(),
          _buildTitleSection(),
          _buildContentSection(),
          if (_owners.isNotEmpty) _buildOwnerSection(),
        ],
      ),
    );
  }

  /// 关联线索（只读）
  Widget _buildLeadSection() {
    final name = _isEdit
        ? widget.initial?.lead?.name ?? ''
        : widget.leadName ?? '';
    final phone = _isEdit
        ? widget.initial?.lead?.phone ?? ''
        : widget.leadPhone ?? '';
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👤 关联线索',
            style: TextStyle(fontSize: 12, color: Color(0xFFA6A6A6)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  name.isEmpty ? '—' : name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF181818),
                  ),
                ),
              ),
              if (!_isEdit)
                const Text('（只读）',
                    style: TextStyle(fontSize: 12, color: Color(0xFFA6A6A6))),
            ],
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '📞 $phone',
              style: const TextStyle(fontSize: 14, color: Color(0xFFA6A6A6)),
            ),
          ],
        ],
      ),
    );
  }

  /// 计划时间（必填）
  Widget _buildDateSection() {
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 计划时间 *',
            style: TextStyle(fontSize: 12, color: Color(0xFFA6A6A6)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                border: Border.all(color: const Color(0xFFE7E7E7), width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF181818),
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today,
                      size: 20, color: Color(0xFFA6A6A6)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 快捷日期 chip
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _dateChip('明天', today.add(const Duration(days: 1))),
              _dateChip('后天', today.add(const Duration(days: 2))),
              _dateChip('大后天', today.add(const Duration(days: 3))),
              _dateChip('五天后', today.add(const Duration(days: 5))),
              _dateChip('七天后', today.add(const Duration(days: 7))),
            ],
          ),
        ],
      ),
    );
  }

  /// 日期快捷项
  Widget _dateChip(String label, DateTime target) {
    final selected = _isSameDay(_selectedDate, target);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedDate = target;
          _dateError = null;
          _dirty = true;
        });
      },
      selectedColor: const Color(0xFFF2F3FF),
      labelStyle: TextStyle(
        fontSize: 14,
        color: selected ? const Color(0xFF0052D9) : const Color(0xFF181818),
      ),
    );
  }

  /// 时间选择
  Widget _buildTimeSection() {
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                border: Border.all(color: const Color(0xFFE7E7E7), width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF181818),
                      ),
                    ),
                  ),
                  const Icon(Icons.access_time,
                      size: 20, color: Color(0xFFA6A6A6)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _timeChip('上午10点', 10, 0),
              _timeChip('下午2点', 14, 0),
              _timeChip('下午5点', 17, 0),
              _timeChip('晚上7点', 19, 0),
              _timeChip('晚上9点', 21, 0),
            ],
          ),
          if (_dateError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _dateError!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD54941),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 时间快捷项
  Widget _timeChip(String label, int hour, int minute) {
    final selected =
        _selectedTime.hour == hour && _selectedTime.minute == minute;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedTime = TimeOfDay(hour: hour, minute: minute);
          _dirty = true;
        });
      },
      selectedColor: const Color(0xFFF2F3FF),
      labelStyle: TextStyle(
        fontSize: 14,
        color: selected ? const Color(0xFF0052D9) : const Color(0xFF181818),
      ),
    );
  }

  /// 标题（可选，≤200）
  Widget _buildTitleSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '标题',
            style: TextStyle(fontSize: 12, color: Color(0xFFA6A6A6)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText: '如：跟进通话结果',
              hintStyle: TextStyle(fontSize: 14, color: Color(0xFFA6A6A6)),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE7E7E7)),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              counterText: '',
            ),
            onChanged: (_) => setState(() => _dirty = true),
          ),
        ],
      ),
    );
  }

  /// 内容（可选，≤2000）
  Widget _buildContentSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '内容',
            style: TextStyle(fontSize: 12, color: Color(0xFFA6A6A6)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentCtrl,
            maxLength: 2000,
            maxLines: 4,
            minLines: 2,
            decoration: const InputDecoration(
              hintText: '补充说明...',
              hintStyle: TextStyle(fontSize: 14, color: Color(0xFFA6A6A6)),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE7E7E7)),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              counterText: '',
            ),
            onChanged: (_) => setState(() => _dirty = true),
          ),
        ],
      ),
    );
  }

  /// 归属人（仅 TM/TA，编辑模式隐藏）
  Widget _buildOwnerSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👤 归属人',
            style: TextStyle(fontSize: 12, color: Color(0xFFA6A6A6)),
          ),
          const SizedBox(height: 8),
          DropdownButton<OptionItem>(
            isExpanded: true,
            value: _owner,
            hint: const Text('选择归属人'),
            items: _owners
                .map((u) => DropdownMenuItem(
                      value: u,
                      child: Text(u.name),
                    ))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _owner = v;
                _dirty = true;
              });
            },
          ),
        ],
      ),
    );
  }

  // ── 选择器（复用已验证的 TDPicker 调用） ──

  /// 日期选择（TDPicker.showDatePicker，onConfirm 回调参数为 `Map<String, int>`）
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    TDPicker.showDatePicker(
      context,
      title: '选择日期',
      dateStart: [today.year, today.month, today.day],
      dateEnd: [today.year + 1, today.month, today.day],
      initialDate: [
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ],
      onConfirm: (selected) {
        // TDPicker 回调参数为 Map<String,int>（year/month/day/hour/minute/second）
        final map = selected;
        setState(() {
          _selectedDate = DateTime(
            map['year'] ?? _selectedDate.year,
            map['month'] ?? _selectedDate.month,
            map['day'] ?? _selectedDate.day,
          );
          _dirty = true;
        });
        // 确认后需手动关闭选择器（TDPicker 不会自动 pop）
        Navigator.of(context).pop();
      },
    );
  }

  /// 时间选择（TDPicker.showDatePicker，仅启用 hour/minute）
  Future<void> _pickTime() async {
    TDPicker.showDatePicker(
      context,
      title: '选择时间',
      useYear: false,
      useMonth: false,
      useDay: false,
      useHour: true,
      useMinute: true,
      useSecond: false,
      initialDate: [
        DateTime.now().year,
        DateTime.now().month,
        _selectedTime.hour,
        _selectedTime.minute,
      ],
      onConfirm: (selected) {
        final map = selected;
        setState(() {
          _selectedTime = TimeOfDay(
            hour: map['hour'] ?? _selectedTime.hour,
            minute: map['minute'] ?? _selectedTime.minute,
          );
          _dirty = true;
        });
        Navigator.of(context).pop();
      },
    );
  }

  // ── 底部操作栏 ──

  Widget _buildActionBar() {
    final isEdit = _isEdit;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding:
          EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _isSubmitting ? null : _onBack,
            child: const Text(
              '取消',
              style: TextStyle(fontSize: 14, color: Color(0xFF181818)),
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 40,
            child: TDButton(
              text: _isSubmitting ? '' : (isEdit ? '保存' : '创建日程'),
              theme: TDButtonTheme.primary,
              shape: TDButtonShape.round,
              iconWidget: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : null,
              disabled: _isSubmitting,
              onTap: _isSubmitting ? null : _submit,
            ),
          ),
        ],
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
    // 校验计划时间不能为空（理论上 date/time 总有值，兜底）
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

    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (_isEdit) {
      // 编辑：未变更则不发请求
      final init = widget.initial!;
      final dt = DateTime.fromMillisecondsSinceEpoch(init.scheduledAt * 1000);
      final sameTime = dt.year == _selectedDate.year &&
          dt.month == _selectedDate.month &&
          dt.day == _selectedDate.day &&
          dt.hour == _selectedTime.hour &&
          dt.minute == _selectedTime.minute;
      final sameTitle = init.title == title;
      final sameContent = (init.content ?? '') == content;
      if (sameTime && sameTitle && sameContent) {
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
          title: title,
          content: content.isNotEmpty ? content : null,
        );
        if (!mounted) return;
        TDToast.showText('日程已更新', context: context);
      } else {
        await svc.createSchedule(
          leadId: widget.leadId!,
          scheduledAt: _scheduledAt,
          title: title,
          content: content.isNotEmpty ? content : null,
          userId: _owner?.id,
        );
        if (!mounted) return;
        TDToast.showText('日程已创建', context: context);
      }
      // 刷新列表（更新对应 tab 聚合）
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

  // ── 工具 ──

  /// 通用卡片容器
  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  /// 判断两个日期是否同一天
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
