/// 编辑线索面板（底部抽屉样式）
///
/// 设计文档 §2.4 - 编辑线索弹窗
/// 分类平铺 + 状态平铺（TE仅前向流转）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:telemarketing_app/constants/lead_constants.dart';
import 'package:telemarketing_app/models/lead_detail.dart';
import 'package:telemarketing_app/models/option_item.dart';
import 'package:telemarketing_app/providers/lead_detail_provider.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'package:telemarketing_app/providers/lead_list_provider.dart';
import 'package:telemarketing_app/providers/options_provider.dart';
import 'package:telemarketing_app/widgets/sheet_header.dart';
import 'package:telemarketing_app/widgets/tag_chip.dart';

/// 显示编辑线索面板（底部抽屉）
void showEditLeadDialog(
  BuildContext context, {
  required String leadId,
  required LeadDetail detail,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditLeadPanel(
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

class _EditLeadPanel extends ConsumerStatefulWidget {
  final String leadId;
  final LeadDetail detail;

  const _EditLeadPanel({
    required this.leadId,
    required this.detail,
  });

  @override
  ConsumerState<_EditLeadPanel> createState() => _EditLeadPanelState();
}

class _EditLeadPanelState extends ConsumerState<_EditLeadPanel> {
  String? _selectedCategoryId;
  String? _selectedStatus;
  bool _isSubmitting = false;
  List<OptionItem> _categories = [];
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
          _categories = cats;
        });
      }
    } catch (_) {
      // 静默失败
    }
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
              SheetHeader(title: '编辑 ${widget.detail.name} 线索'),
              const SizedBox(height: 20),

              // ── 线索分类 ──
              _buildCategorySelector(),
              const SizedBox(height: 16),

              // ── 状态 ──
              _buildStatusSelector(),

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


  // ── 分类选择器（横向平铺 chips） ──

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '线索分类',
          style: TextStyle(fontSize: 14, color: Color(0xFF181818)),
        ),
        const SizedBox(height: 8),
        if (_categories.isEmpty)
          const Text(
            '暂无可选分类',
            style: TextStyle(fontSize: 12, color: Color(0xFFA6A6A6)),
          )
        else
          TagChipRow(
            scrollable: true,
            chips: _categories.map((c) => TagChipData(
              label: c.name,
              selected: _selectedCategoryId == c.id,
              onTap: () => setState(() => _selectedCategoryId = c.id),
            )).toList(),
          ),
      ],
    );
  }

  // ── 状态选择器（横向平铺 chips） ──

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '状态',
          style: TextStyle(fontSize: 14, color: Color(0xFF181818)),
        ),
        const SizedBox(height: 8),
        TagChipRow(
          scrollable: true,
          chips: _availableStatuses.map((s) => TagChipData(
            label: LeadConstants.displayName(s),
            selected: _selectedStatus == s,
            onTap: () => setState(() => _selectedStatus = s),
          )).toList(),
        ),
      ],
    );
  }

  /// 平铺 chip（选中态高亮）

  // ── 提交按钮 ──

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TDButton(
        text: _isSubmitting ? '' : '保存',
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
