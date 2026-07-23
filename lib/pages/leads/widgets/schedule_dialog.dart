/// 预约下次跟进弹窗
///
/// 设计文档 §2.3 - 预约下次跟进弹窗
/// 日期默认明天、时间默认 09:00、备注可选
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../models/lead_detail.dart';
import '../../../providers/lead_list_provider.dart';

/// 预约下次跟进弹窗
///
/// 设计文档 §2.3 - 预约下次跟进弹窗
/// 日期默认明天、时间默认 09:00、备注可选
void showScheduleDialog(
  BuildContext context, {
  required String leadId,
  required LeadDetail detail,
}) {
  showDialog(
    context: context,
    builder: (_) => _ScheduleDialog(
      leadId: leadId,
      detail: detail,
    ),
  );
}

class _ScheduleDialog extends ConsumerStatefulWidget {
  final String leadId;
  final LeadDetail detail;

  const _ScheduleDialog({
    required this.leadId,
    required this.detail,
  });

  @override
  ConsumerState<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends ConsumerState<_ScheduleDialog> {
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
    return AlertDialog(
      title: const Text(
        '预约下次跟进',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF181818),
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期
            _buildField(
              label: '日期',
              child: _buildDateSelector(),
            ),
            const SizedBox(height: 16),
            // 时间
            _buildField(
              label: '时间',
              child: _buildTimeSelector(),
            ),
            const SizedBox(height: 16),
            // 备注（可选）
            _buildField(
              label: '备注（可选）',
              child: SizedBox(
                height: 80,
                child: TDTextarea(
                  controller: _remarkController,
                  hintText: '提醒内容...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '取消',
            style: TextStyle(color: Color(0xFF181818)),
          ),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  '确认预约',
                  style: TextStyle(color: Color(0xFF0052D9)),
                ),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF181818),
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (_dateError != null) ...[
          const SizedBox(height: 4),
          Text(
            _dateError!,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFD54941),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateSelector() {
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    return _buildSelector(
      text: dateStr,
      onTap: () {
        TDPicker.showDatePicker(
          context,
          title: '选择日期',
          onConfirm: (date) {
            final dt = date as DateTime;
            setState(() {
              _selectedDate = dt;
              _dateError = null;
            });
          },
        );
      },
    );
  }

  Widget _buildTimeSelector() {
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    return _buildSelector(
      text: timeStr,
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (time != null) {
          setState(() => _selectedTime = time);
        }
      },
    );
  }

  Widget _buildSelector({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
              text,
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
    );
  }

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
      final title =
          '跟进${widget.detail.name}，确认购房意向'; // 默认预约标题

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
