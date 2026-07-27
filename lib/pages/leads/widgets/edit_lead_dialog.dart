/// 编辑线索面板（底部抽屉样式）
///
/// 设计文档 §2.4 - 编辑线索弹窗
/// 分类平铺 + 状态平铺（TE仅前向流转）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/widgets/app_toast.dart';
import 'package:telemarketing_app/constants/lead_constants.dart';
import 'package:telemarketing_app/models/lead_detail.dart';
import 'package:telemarketing_app/models/option_item.dart';
import 'package:telemarketing_app/providers/lead_detail_provider.dart';
import 'package:telemarketing_app/providers/lead_list_provider.dart';
import 'package:telemarketing_app/providers/options_provider.dart';
import 'package:telemarketing_app/widgets/app_action_bar.dart';
import 'package:telemarketing_app/widgets/app_bottom_sheet.dart';
import 'package:telemarketing_app/widgets/app_form_section.dart';
import 'package:telemarketing_app/widgets/tag_chip.dart';
import 'package:telemarketing_app/services/api_exception.dart';

/// 显示编辑线索面板（底部抽屉）
void showEditLeadDialog(
  BuildContext context, {
  required String leadId,
  required LeadDetail detail,
}) {
  AppBottomSheet.show<void>(
    context: context,
    title: '编辑 ${detail.name} 线索',
    child: _EditLeadPanel(
      leadId: leadId,
      detail: detail,
    ),
  );
}

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
    // 状态选项：所有角色统一按权威状态机收敛（含当前态），
    // 避免 manager 编辑 converted 时误选回退项被后端 400 拒绝。
    _availableStatuses = LeadConstants.allowedStatuses(widget.detail.status);

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 线索分类 ──
        _buildCategorySelector(),
        const SizedBox(height: 16),
        // ── 状态 ──
        _buildStatusSelector(),
        const SizedBox(height: 24),
        // ── 提交按钮 ──
        _buildSubmitButton(),
      ],
    );
  }

  // ── 标题行 ──


  // ── 分类选择器（横向平铺 chips） ──

  Widget _buildCategorySelector() {
    return AppFormSection(
      label: '线索分类',
      child: _categories.isEmpty
          ? const Text(
              '暂无可选分类',
              style: TextStyle(fontSize: 12, color: Color(0xFFA6A6A6)),
            )
          : TagChipRow(
              scrollable: true,
              chips: _categories.map((c) => TagChipData(
                label: c.name,
                selected: _selectedCategoryId == c.id,
                onTap: () => setState(() => _selectedCategoryId = c.id),
              )).toList(),
            ),
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
      await service.updateLead(
        id: widget.leadId,
        categoryId: _selectedCategoryId,
        // 状态未真正变更时（仍为当前态）不传 status，交给后端保持原状。
        // 后端状态机只允许「向前流转」，self-transition（如 assigned→assigned）
        // 会被判为非法流转返回 400。仅当用户选了与当前不同的合法目标才传。
        status: _selectedStatus != widget.detail.status ? _selectedStatus : null,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.read(leadDetailProvider.notifier).refreshBundle();
      AppToast.show(context, '线索已更新');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      // 透出后端中文错误（如 STATUS_ROLLBACK_FORBIDDEN → “状态回退被拒…”）
      AppToast.show(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.show(context, '保存失败，请重试');
    }
  }
}
