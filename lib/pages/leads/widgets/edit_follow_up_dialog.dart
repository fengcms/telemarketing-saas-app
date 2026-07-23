import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../providers/lead_detail_provider.dart';
import '../../../providers/lead_list_provider.dart';

/// 编辑跟进记录弹窗
///
/// 设计文档 §2.5 - 编辑跟进记录弹窗（仅内容）
/// TE 仅可编辑自己创建且≤5 分钟的记录，TM/TA 不限。
void showEditFollowUpDialog(
  BuildContext context, {
  required String leadId,
  required String followUpId,
  required String currentContent,
}) {
  showDialog(
    context: context,
    builder: (_) => _EditFollowUpDialog(
      leadId: leadId,
      followUpId: followUpId,
      currentContent: currentContent,
    ),
  );
}

class _EditFollowUpDialog extends ConsumerStatefulWidget {
  final String leadId;
  final String followUpId;
  final String currentContent;

  const _EditFollowUpDialog({
    required this.leadId,
    required this.followUpId,
    required this.currentContent,
  });

  @override
  ConsumerState<_EditFollowUpDialog> createState() =>
      _EditFollowUpDialogState();
}

class _EditFollowUpDialogState extends ConsumerState<_EditFollowUpDialog> {
  late final TextEditingController _controller;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '编辑跟进记录',
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
            const Text(
              '跟进内容',
              style: TextStyle(fontSize: 14, color: Color(0xFF181818)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: TDTextarea(
                controller: _controller,
                hintText: '请输入跟进内容...',
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_controller.text.length}/2000',
                style: TextStyle(
                  fontSize: 12,
                  color: _controller.text.length >= 2000
                      ? const Color(0xFFD54941)
                      : const Color(0xFFA6A6A6),
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
          onPressed:
              _isSubmitting || _controller.text.trim().isEmpty
                  ? null
                  : _submit,
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
      await service.updateFollowUp(
        leadId: widget.leadId,
        followUpId: widget.followUpId,
        content: _controller.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.read(leadDetailProvider.notifier).refreshFollowUps();
      TDToast.showText('跟进记录已更新', context: context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      TDToast.showText('保存失败，请重试', context: context);
    }
  }
}
