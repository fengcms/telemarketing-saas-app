import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../models/call_record.dart';
import '../../../providers/lead_detail_provider.dart';
import '../../../providers/lead_list_provider.dart';

/// 通话记录补正弹窗
///
/// 设计文档 §2.6 - 通话记录补正弹窗
/// 仅 TM/TA 可见可用，用于修正接听类型/时长/结束时间
void showCorrectCallDialog(
  BuildContext context, {
  required String callId,
  required CallRecord record,
}) {
  showDialog(
    context: context,
    builder: (_) => _CorrectCallDialog(
      callId: callId,
      record: record,
    ),
  );
}

class _CorrectCallDialog extends ConsumerStatefulWidget {
  final String callId;
  final CallRecord record;

  const _CorrectCallDialog({
    required this.callId,
    required this.record,
  });

  @override
  ConsumerState<_CorrectCallDialog> createState() =>
      _CorrectCallDialogState();
}

class _CorrectCallDialogState
    extends ConsumerState<_CorrectCallDialog> {
  String? _selectedAnswerType;
  int _durationMinutes = 0;
  int _durationSeconds = 0;
  bool _isSubmitting = false;
  bool _showDuration = false;

  static const _answerTypes = [
    ('answered', '已接听'),
    ('no_answer', '无人接听'),
    ('rejected', '拒接'),
    ('empty_number', '空号'),
    ('suspended', '停机'),
  ];

  @override
  void initState() {
    super.initState();
    // 预填当前值
    _selectedAnswerType = widget.record.answerType;
    if (widget.record.duration != null) {
      _durationMinutes = widget.record.duration! ~/ 60;
      _durationSeconds = widget.record.duration! % 60;
    }
    _showDuration = widget.record.answerType == 'answered';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '补正通话记录',
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
            // 接听类型
            const Text(
              '接听类型',
              style: TextStyle(fontSize: 14, color: Color(0xFF181818)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _answerTypes.map((type) {
                final (value, label) = type;
                final isSelected = _selectedAnswerType == value;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAnswerType = value;
                      _showDuration = value == 'answered';
                    });
                  },
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0052D9)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0052D9)
                            : const Color(0xFFE7E7E7),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF181818),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            // 通话时长（已接听时显示）
            if (_showDuration) ...[
              const SizedBox(height: 16),
              const Text(
                '通话时长',
                style: TextStyle(fontSize: 14, color: Color(0xFF181818)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: TDStepper(
                      value: _durationMinutes,
                      min: 0,
                      max: 99,
                      onChange: (v) =>
                          setState(() => _durationMinutes = v),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '分',
                      style:
                          TextStyle(fontSize: 13, color: Color(0xFFA6A6A6)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: TDStepper(
                      value: _durationSeconds,
                      min: 0,
                      max: 59,
                      step: 5,
                      onChange: (v) =>
                          setState(() => _durationSeconds = v),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '秒',
                      style:
                          TextStyle(fontSize: 13, color: Color(0xFFA6A6A6)),
                    ),
                  ),
                ],
              ),
            ],
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
                  '保存',
                  style: TextStyle(color: Color(0xFF0052D9)),
                ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(leadServiceProvider);
      final duration = _showDuration
          ? _durationMinutes * 60 + _durationSeconds
          : null;

      await service.correctCallRecord(
        callId: widget.callId,
        answerType: _selectedAnswerType,
        duration: duration,
        endedAt: null, // 结束时间可选，暂不提供 UI
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.read(leadDetailProvider.notifier).refreshCalls();
      TDToast.showText('通话记录已补正', context: context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      TDToast.showText('保存失败，请重试', context: context);
    }
  }
}
