/// 编辑线索面板（底部抽屉样式）
///
/// 设计文档 §2.4 - 编辑线索弹窗
/// 分类平铺 + 状态平铺（TE仅前向流转）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../constants/lead_constants.dart';
import '../../../models/lead_detail.dart';
import '../../../models/option_item.dart';
import '../../../providers/lead_detail_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/lead_list_provider.dart';
import '../../../providers/options_provider.dart';

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
              _buildHeader(),
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

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFDCDCDC),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Spacer(),
        Text(
          '编辑 ${widget.detail.name} 线索',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF181818),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.close, size: 20, color: Color(0xFFA6A6A6)),
        ),
      ],
    );
  }

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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._categories.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _chip(
                    c.name,
                    _selectedCategoryId == c.id,
                    () => setState(() => _selectedCategoryId = c.id),
                  ),
                )),
                const SizedBox(width: 4),
              ],
            ),
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._availableStatuses.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _chip(
                  LeadConstants.displayName(s),
                  _selectedStatus == s,
                  () => setState(() => _selectedStatus = s),
                ),
              )),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ],
    );
  }

  /// 平铺 chip（选中态高亮）
  Widget _chip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0052D9) : Colors.white,
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
            color: isSelected ? Colors.white : const Color(0xFF181818),
          ),
        ),
      ),
    );
  }

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
