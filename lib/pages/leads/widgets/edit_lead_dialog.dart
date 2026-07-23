/// 编辑线索弹窗
///
/// 设计文档 §2.4 - 编辑线索弹窗
/// 分类下拉 + 状态下拉（TE仅前向流转）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../constants/lead_constants.dart';
import '../../../models/lead_detail.dart';
import '../../../providers/lead_detail_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/lead_list_provider.dart';
import '../../../providers/options_provider.dart';

/// 编辑线索弹窗
///
/// 设计文档 §2.4 - 编辑线索弹窗
/// 分类下拉 + 状态下拉（TE仅前向流转）
void showEditLeadDialog(
  BuildContext context, {
  required String leadId,
  required LeadDetail detail,
}) {
  showDialog(
    context: context,
    builder: (_) => _EditLeadDialog(
      leadId: leadId,
      detail: detail,
    ),
  );
}

/// 线索状态的前向流转映射
const Map<String, List<String>> _forwardStatusMap = {
  'pending': ['pending', 'following'],
  'assigned': ['assigned', 'following'],
  'following': ['following', 'converted'],
  'converted': ['converted'], // 终态，不可再修改
  'invalid': ['invalid', 'pending'], // 无效可重新激活
};

class _EditLeadDialog extends ConsumerStatefulWidget {
  final String leadId;
  final LeadDetail detail;

  const _EditLeadDialog({
    required this.leadId,
    required this.detail,
  });

  @override
  ConsumerState<_EditLeadDialog> createState() => _EditLeadDialogState();
}

class _EditLeadDialogState extends ConsumerState<_EditLeadDialog> {
  String? _selectedCategoryId;
  String? _selectedStatus;
  bool _isSubmitting = false;
  List<String> _availableCategories = [];
  List<String> _availableStatuses = [];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.detail.categoryId;
    _selectedStatus = widget.detail.status;
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final isManager = ref.read(authProvider).user?.role == 'tenant_admin' ||
        ref.read(authProvider).user?.role == 'tenant_manager';

    // 状态选项
    final forwardStatuses =
        _forwardStatusMap[widget.detail.status] ?? [widget.detail.status];
    _availableStatuses = isManager
        ? LeadConstants.statusLabels.keys.toList()
        : forwardStatuses;

    // 分类选项
    try {
      final cache = ref.read(optionsCacheProvider);
      final cats = await cache.getCategories();
      if (mounted) {
        setState(() {
          _availableCategories = cats.map((c) => c.id).toList();
        });
      }
    } catch (_) {
      // 静默失败
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '编辑线索',
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
          children: [
            // 分类
            _buildSelector(
              label: '分类',
              value: _selectedCategoryId ?? '请选择',
              onTap: () => _showCategoryPicker(),
            ),
            const SizedBox(height: 16),
            // 状态
            _buildSelector(
              label: '状态',
              value: LeadConstants.displayName(_selectedStatus),
              onTap: () => _showStatusPicker(),
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
                  '保存',
                  style: TextStyle(color: Color(0xFF0052D9)),
                ),
        ),
      ],
    );
  }

  Widget _buildSelector({
    required String label,
    required String value,
    required VoidCallback onTap,
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
        GestureDetector(
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
                  value,
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
      ],
    );
  }

  void _showCategoryPicker() {
    if (_availableCategories.isEmpty) {
      TDToast.showText('暂无可选分类', context: context);
      return;
    }
    // 简单底部滚动选择
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '选择分类',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Divider(),
            ..._availableCategories.map((cat) => ListTile(
                  title: Text(cat),
                  trailing: cat == _selectedCategoryId
                      ? const Icon(Icons.check, color: Color(0xFF0052D9))
                      : null,
                  onTap: () {
                    setState(() => _selectedCategoryId = cat);
                    Navigator.of(ctx).pop();
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '选择状态',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Divider(),
            ..._availableStatuses.map((status) => ListTile(
                  title: Text(LeadConstants.displayName(status)),
                  subtitle: Text(status),
                  trailing: status == _selectedStatus
                      ? const Icon(Icons.check, color: Color(0xFF0052D9))
                      : null,
                  onTap: () {
                    setState(() => _selectedStatus = status);
                    Navigator.of(ctx).pop();
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(leadServiceProvider);
      await service.updateLead(
        id: widget.leadId,
        categoryId: _selectedCategoryId,
        status: _selectedStatus,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.read(leadDetailProvider.notifier).refreshAll();
      TDToast.showText('线索已更新', context: context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      TDToast.showText('保存失败，请重试', context: context);
    }
  }
}
