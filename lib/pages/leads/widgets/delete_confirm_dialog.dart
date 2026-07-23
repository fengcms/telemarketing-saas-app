import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../providers/lead_detail_provider.dart';
import '../../../providers/lead_list_provider.dart';

/// 删除跟进记录确认弹窗
///
/// 设计文档 §2.7 - 删除确认弹窗
/// 确定删除 / 取消
void showDeleteConfirmDialog(
  BuildContext context, {
  required String leadId,
  required String followUpId,
}) {
  showDialog(
    context: context,
    builder: (_) => _DeleteConfirmDialog(
      leadId: leadId,
      followUpId: followUpId,
    ),
  );
}

class _DeleteConfirmDialog extends ConsumerStatefulWidget {
  final String leadId;
  final String followUpId;

  const _DeleteConfirmDialog({
    required this.leadId,
    required this.followUpId,
  });

  @override
  ConsumerState<_DeleteConfirmDialog> createState() =>
      _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState
    extends ConsumerState<_DeleteConfirmDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '删除跟进记录',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF181818),
        ),
      ),
      content: const Text(
        '确定要删除该跟进记录吗？\n删除后将无法恢复。',
        style: TextStyle(fontSize: 14, color: Color(0xFF181818)),
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
          onPressed: _isDeleting ? null : _delete,
          child: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  '确定删除',
                  style: TextStyle(color: Color(0xFFD54941)),
                ),
        ),
      ],
    );
  }

  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    try {
      final service = ref.read(leadServiceProvider);
      await service.deleteFollowUp(
        leadId: widget.leadId,
        followUpId: widget.followUpId,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.read(leadDetailProvider.notifier).refreshFollowUps();
      TDToast.showText('跟进记录已删除', context: context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      TDToast.showText('删除失败，请重试', context: context);
    }
  }
}
