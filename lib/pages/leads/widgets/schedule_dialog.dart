/// 新建日程面板（底部抽屉样式）
///
/// 设计文档 §2.3 - 预约下次跟进弹窗
/// 日期默认明天、时间默认 09:00、备注可选
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../models/lead_detail.dart';
import '../../../providers/lead_list_provider.dart';
import '../../../widgets/sheet_header.dart';

/// 显示预约下次跟进面板（底部抽屉）
void showScheduleDialog(
  BuildContext context, {
  required String leadId,
  required LeadDetail detail,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SchedulePanel(
      leadId: leadId,
      detail: detail,
    ),
  );
}

class _SchedulePanel extends ConsumerStatefulWidget {
  final String leadId;
  final LeadDetail detail;

  const _SchedulePanel({
    required this.leadId,
    required this.detail,
  });

  @override
  ConsumerState<_SchedulePanel> createState() => _SchedulePanelState();
}

class _SchedulePanelState extends ConsumerState<_SchedulePanel> {
  final _remarkController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isSubmitting = false;
  String? _dateError;

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
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
              // ── 标题行 ──
              SheetHeader(title: '新建日程（${widget.detail.name}）'),
              const SizedBox(height: 20),

              // ── 日期 ──
              _buildDateSelector(),
              const SizedBox(height: 16),

              // ── 时间 ──
              _buildTimeSelector(),
              const SizedBox(height: 16),

              // ── 备注 ──
              _buildRemarkField(),

              // ── 错误提示 ──
              if (_dateError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _dateError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD54941),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── 提交按钮 ──
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── 标题行 ──


  // ── 日期选择 ──

  Widget _buildDateSelector() {
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '日期',
          style: TextStyle(fontSize: 14, color: Color(0xFF181818)),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
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
              onConfirm: (date) {
                final dt = date as DateTime;
                setState(() {
                  _selectedDate = dt;
                  _dateError = null;
                });
              },
            );
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF181818),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFFA6A6A6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 日期快捷项：小 tag 一行展示
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _quickDateTag('明天', 1),
              const SizedBox(width: 8),
              _quickDateTag('后天', 2),
              const SizedBox(width: 8),
              _quickDateTag('大后天', 3),
              const SizedBox(width: 8),
              _quickDateTag('五天后', 5),
              const SizedBox(width: 8),
              _quickDateTag('七天后', 7),
            ],
          ),
        ),
      ],
    );
  }

  /// 日期快捷项 tag
  Widget _quickDateTag(String label, int daysLater) {
    final target = DateTime.now().add(Duration(days: daysLater));
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = target;
          _dateError = null;
        });
      },
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _selectedDate.year == target.year &&
                  _selectedDate.month == target.month &&
                  _selectedDate.day == target.day
              ? const Color(0xFF0052D9)
              : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _selectedDate.year == target.year &&
                    _selectedDate.month == target.month &&
                    _selectedDate.day == target.day
                ? Colors.white
                : const Color(0xFF181818),
          ),
        ),
      ),
    );
  }

  // ── 时间选择 ──

  Widget _buildTimeSelector() {
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '时间',
          style: TextStyle(fontSize: 14, color: Color(0xFF181818)),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
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
              onConfirm: (date) {
                final dt = date as DateTime;
                setState(() {
                  _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
                });
              },
            );
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF181818),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFFA6A6A6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 时间快捷项：小 tag 一行展示
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _quickTimeTag('上午10点', 10, 0),
              const SizedBox(width: 8),
              _quickTimeTag('下午2点', 14, 0),
              const SizedBox(width: 8),
              _quickTimeTag('下午5点', 17, 0),
              const SizedBox(width: 8),
              _quickTimeTag('晚上7点', 19, 0),
              const SizedBox(width: 8),
              _quickTimeTag('晚上9点', 21, 0),
            ],
          ),
        ),
      ],
    );
  }

  /// 时间快捷项 tag
  Widget _quickTimeTag(String label, int hour, int minute) {
    final isMatch =
        _selectedTime.hour == hour && _selectedTime.minute == minute;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTime = TimeOfDay(hour: hour, minute: minute));
      },
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isMatch ? const Color(0xFF0052D9) : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isMatch ? Colors.white : const Color(0xFF181818),
          ),
        ),
      ),
    );
  }

  Widget _buildRemarkField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '备注（可选）',
          style: TextStyle(fontSize: 14, color: Color(0xFF181818)),
        ),
        const SizedBox(height: 8),
        TDTextarea(
          controller: _remarkController,
          hintText: '提醒内容...',
          minLines: 2,
          maxLength: 200,
          showBottomDivider: false,
          indicator: true,
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          inputDecoration: InputDecoration(
            contentPadding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            border: InputBorder.none,
          ),
          textareaDecoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7E7E7), width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // ── 提交按钮 ──

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TDButton(
        text: _isSubmitting ? '' : '确认预约',
        theme: TDButtonTheme.primary,
        shape: TDButtonShape.round,
        iconWidget: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : null,
        disabled: _isSubmitting,
        onTap: _isSubmitting ? null : _submit,
      ),
    );
  }

  // ── 提交 ──

  Future<void> _submit() async {
    // 校验日期不能为过去时间
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    if (selectedDateTime.isBefore(now)) {
      setState(() => _dateError = '不能选择过去的时间');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _dateError = null;
    });

    try {
      final service = ref.read(leadServiceProvider);
      final title = '跟进${widget.detail.name}，确认购房意向';

      await service.createSchedule(
        leadId: widget.leadId,
        scheduledAt: selectedDateTime.millisecondsSinceEpoch ~/ 1000,
        title: title,
        content: _remarkController.text.trim().isNotEmpty
            ? _remarkController.text.trim()
            : null,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      TDToast.showText('预约成功', context: context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      TDToast.showText('预约失败，请重试', context: context);
    }
  }
}
