/// 客户编辑面板（底部抽屉样式）
///
/// 仅经理/管理员在已转化线索上使用，编辑客户信息（姓名/级别/备注）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/widgets/app_toast.dart';
import 'package:telemarketing_app/models/customer_detail.dart';
import 'package:telemarketing_app/providers/lead_detail_provider.dart';
import 'package:telemarketing_app/providers/lead_list_provider.dart';
import 'package:telemarketing_app/services/api_exception.dart';
import 'package:telemarketing_app/widgets/app_action_bar.dart';
import 'package:telemarketing_app/widgets/app_bottom_sheet.dart';
import 'package:telemarketing_app/widgets/app_form_section.dart';
import 'package:telemarketing_app/widgets/app_textarea.dart';
import 'package:telemarketing_app/widgets/tag_chip.dart';

/// 显示编辑客户面板（底部抽屉）
void showEditCustomerDialog(
  BuildContext context, {
  required CustomerDetail customer,
}) {
  AppBottomSheet.show<void>(
    context: context,
    title: '编辑客户信息',
    child: _EditCustomerPanel(customer: customer),
  );
}

class _EditCustomerPanel extends ConsumerStatefulWidget {
  final CustomerDetail customer;

  const _EditCustomerPanel({required this.customer});

  @override
  ConsumerState<_EditCustomerPanel> createState() =>
      _EditCustomerPanelState();
}

class _EditCustomerPanelState extends ConsumerState<_EditCustomerPanel> {
  final _nameCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  String _selectedLevel = 'normal';
  bool _isSubmitting = false;

  /// 客户级别选项（用于 TagChipRow）
  static const _levelOptions = [
    ('normal', '普通'),
    ('important', '重要'),
    ('vip', 'VIP'),
    ('lost', '流失'),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.customer.name;
    _selectedLevel = widget.customer.level;
    _remarkCtrl.text = widget.customer.remark ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 姓名 ──
        _buildNameField(),
        const SizedBox(height: 16),
        // ── 客户级别 ──
        _buildLevelSelector(),
        const SizedBox(height: 16),
        // ── 备注 ──
        _buildRemarkField(),
        const SizedBox(height: 24),
        // ── 提交按钮 ──
        _buildSubmitButton(),
      ],
    );
  }

  // ── 姓名 ──

  Widget _buildNameField() {
    return AppFormSection(
      label: '姓名',
      child: TextField(
        controller: _nameCtrl,
        decoration: const InputDecoration(
          hintText: '请输入客户姓名',
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ── 客户级别 ──

  Widget _buildLevelSelector() {
    return AppFormSection(
      label: '客户级别',
      child: TagChipRow(
        scrollable: true,
        chips: _levelOptions.map((l) {
          final (value, label) = l;
          return TagChipData(
            label: label,
            selected: _selectedLevel == value,
            onTap: () => setState(() => _selectedLevel = value),
          );
        }).toList(),
      ),
    );
  }

  // ── 备注 ──

  Widget _buildRemarkField() {
    return AppFormSection(
      label: '备注',
      child: AppTextarea(
        controller: _remarkCtrl,
        hintText: '客户备注...',
      ),
    );
  }

  // ── 提交按钮 ──

  Widget _buildSubmitButton() {
    return AppActionBar.submit(
      text: '保存',
      loading: _isSubmitting,
      onPressed: _isSubmitting ? null : _submit,
    );
  }

  // ── 提交 ──

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(leadServiceProvider);
      final name = _nameCtrl.text.trim();
      final remark = _remarkCtrl.text.trim();
      await service.updateCustomer(
        id: widget.customer.id,
        name: name.isNotEmpty ? name : null,
        level: _selectedLevel,
        remark: remark.isNotEmpty ? remark : null,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.read(leadDetailProvider.notifier).refreshBundle();
      AppToast.show(context, '客户信息已更新');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.show(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.show(context, '保存失败，请重试');
    }
  }
}
