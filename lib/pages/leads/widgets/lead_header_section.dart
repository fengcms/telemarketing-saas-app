/// 线索详情页头部信息区（Section A）
///
/// 设计文档 §3.2 - 头部信息区
/// 包含：姓名+标签、电话号码、详细信息（公司/职位/归属）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/constants/lead_constants.dart';
import 'package:telemarketing_app/models/lead_detail.dart';
import 'package:telemarketing_app/models/customer_detail.dart';
import 'package:telemarketing_app/providers/options_provider.dart';
import 'package:telemarketing_app/widgets/app_info_row.dart';
import 'package:telemarketing_app/widgets/app_tag.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';
import 'dial_helper.dart';

/// 线索详情页头部信息区（Section A）
class LeadHeaderSection extends ConsumerWidget {
  final LeadDetail detail;
  final CustomerDetail? customer;
  final VoidCallback? onDial;

  const LeadHeaderSection({
    super.key,
    required this.detail,
    this.customer,
    this.onDial,
  });

  /// 显示的沉淀备注：已转化线索优先客户备注，否则线索备注
  String? get _displayRemark {
    if (detail.isConverted && customer != null) {
      return customer!.remark ?? detail.remark;
    }
    return detail.remark;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNameAndTags(context, ref),
          const SizedBox(height: 12),
          _buildPhoneRow(context),
          const SizedBox(height: 16),
          _buildInfoRows(),
        ],
      ),
    );
  }

  Widget _buildNameAndTags(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            detail.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: BrandColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _buildStatusTag(),
        if (detail.isConverted && customer != null) ...[
          const SizedBox(width: 6),
          _buildLevelTag(),
        ],
        if (!detail.isConverted &&
            detail.categoryId != null &&
            detail.categoryId!.isNotEmpty) ...[
          const SizedBox(width: 6),
          _buildCategoryTag(ref),
        ],
      ],
    );
  }

  Widget _buildStatusTag() {
    final (bgColor, textColor, label) =
        LeadConstants.statusColorStyle(detail.status);
    return AppTag(
      label: label,
      backgroundColor: bgColor,
      textColor: textColor,
    );
  }

  /// 客户级别 tag（仅已转化线索显示）
  Widget _buildLevelTag() {
    final level = customer?.level ?? 'normal';
    final (bgColor, textColor) =
        LeadConstants.customerLevelColorStyle(level);
    return AppTag(
      label: LeadConstants.customerLevelLabel(level),
      backgroundColor: bgColor,
      textColor: textColor,
    );
  }

  Widget _buildCategoryTag(WidgetRef ref) {
    final categoryNameAsync =
        ref.watch(categoryNameProvider(detail.categoryId!));
    final categoryName = categoryNameAsync.when(
      data: (name) => name,
      loading: () => detail.categoryId!,
      error: (_, _) => detail.categoryId!,
    );
    return AppTag(label: categoryName);
  }

  Widget _buildPhoneRow(BuildContext context) {
    final hasPhone = detail.phone.isNotEmpty;
    return Row(
      children: [
        Icon(
          Icons.call,
          size: 20,
          color: hasPhone
              ? BrandColors.primary
              : BrandColors.textDisabled,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasPhone ? _formatPhone(detail.phone) : '暂无电话',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: hasPhone
                  ? BrandColors.primary
                  : BrandColors.textSecondary,
              letterSpacing: 0.05,
            ),
          ),
        ),
        if (hasPhone && !detail.isConverted) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            height: 56,
            child: FloatingActionButton(
              onPressed: () {
                onDial?.call();
                handleDial(
                  phone: detail.phone,
                  context: context,
                );
              },
              child: const Icon(Icons.call, color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }

  String _formatPhone(String phone) {
    final maskedMatch =
        RegExp(r'^(\d{3})\*{3,}(\d{4})$').firstMatch(phone);
    if (maskedMatch != null) {
      return '${maskedMatch.group(1)} **** ${maskedMatch.group(2)}';
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 7)} ${digits.substring(7)}';
    }
    return phone;
  }

  Widget _buildInfoRows() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detail.company != null && detail.company!.isNotEmpty)
          AppInfoRow(
            icon: Icons.business,
            label: '公司',
            value: detail.company!,
          ),
        if (detail.position != null && detail.position!.isNotEmpty)
          AppInfoRow(
            icon: Icons.work,
            label: '职位',
            value: detail.position!,
          ),
        if (detail.owner != null)
          AppInfoRow(
            icon: Icons.person,
            label: '归属',
            value: detail.owner!.name,
          ),
        // 备注：已转化线索优先显示客户备注，否则显示线索备注
        if (_displayRemark != null)
          AppInfoRow(
            icon: Icons.notes,
            label: '备注',
            value: _displayRemark!,
          ),
      ],
    );
  }
}
