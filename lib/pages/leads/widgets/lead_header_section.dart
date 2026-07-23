/// 线索详情页头部信息区（Section A）
///
/// 设计文档 §3.2 - 头部信息区
/// 包含：姓名+标签、电话号码、详细信息（公司/职位/归属）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:telemarketing_app/constants/lead_constants.dart';
import 'package:telemarketing_app/models/lead_detail.dart';
import 'package:telemarketing_app/providers/options_provider.dart';
import 'dial_helper.dart';

/// 线索详情页头部信息区（Section A）
///
/// 设计文档 §3.2 - 头部信息区
/// 包含：姓名+标签、电话号码、详细信息（公司/职位/归属）
class LeadHeaderSection extends ConsumerWidget {
  final LeadDetail detail;

  const LeadHeaderSection({super.key, required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 姓名 + 状态/分类标签 ──
          _buildNameAndTags(context, ref),
          const SizedBox(height: 12),
          // ── 电话号码区域 ──
          _buildPhoneRow(context),
          const SizedBox(height: 16),
          // ── 详细信息 ──
          _buildInfoRows(),
        ],
      ),
    );
  }

  // ── 姓名 + 标签行 ──

  Widget _buildNameAndTags(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 姓名（左对齐）
        Expanded(
          child: Text(
            detail.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF181818),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        // 状态标签
        _buildStatusTag(),
        const SizedBox(width: 6),
        // 分类标签（通过 OptionsCacheService 解析名称）
        if (detail.categoryId != null && detail.categoryId!.isNotEmpty)
          _buildCategoryTag(ref),
      ],
    );
  }

  Widget _buildStatusTag() {
    final (bgColor, textColor, label) =
        LeadConstants.statusColorStyle(detail.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
        ),
      ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        categoryName,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF0052D9),
        ),
      ),
    );
  }

  // ── 电话号码区域 ──

  Widget _buildPhoneRow(BuildContext context) {
    final hasPhone = detail.phone.isNotEmpty;
    return Row(
      children: [
        Icon(
          TDIcons.call,
          size: 20,
          color: hasPhone
              ? const Color(0xFF0052D9)
              : const Color(0xFFDCDCDC),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasPhone ? _formatPhone(detail.phone) : '暂无电话',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: hasPhone
                  ? const Color(0xFF0052D9)
                  : const Color(0xFFA6A6A6),
              letterSpacing: 0.05,
            ),
          ),
        ),
        // 右侧拨号 FAB
        if (hasPhone && !detail.isConverted) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            height: 56,
            child: FloatingActionButton(
              onPressed: () => handleDial(
                phone: detail.phone,
                context: context,
              ),
              backgroundColor: const Color(0xFF0052D9),
              child: const Icon(
                TDIcons.call,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 格式化电话号码为可读格式
  ///
  /// 完整号码（11位）格式化为 "138 1234 1234" 3-4-4 分段
  /// 脱敏号码（如 170****9444）格式化为 "170 **** 9444"
  String _formatPhone(String phone) {
    // 尝试处理脱敏号码格式: 前缀 + **** + 后缀
    final maskedMatch =
        RegExp(r'^(\d{3})\*{3,}(\d{4})$').firstMatch(phone);
    if (maskedMatch != null) {
      return '${maskedMatch.group(1)} **** ${maskedMatch.group(2)}';
    }
    // 完整号码 3-4-4 分段
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 7)} ${digits.substring(7)}';
    }
    // 其他情况直接返回原字符串
    return phone;
  }

  // ── 详细信息行 ──

  Widget _buildInfoRows() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 公司
        if (detail.company != null && detail.company!.isNotEmpty)
          _infoRow(
            icon: Icons.business,
            label: '公司',
            value: detail.company!,
          ),
        // 职位
        if (detail.position != null && detail.position!.isNotEmpty)
          _infoRow(
            icon: Icons.work,
            label: '职位',
            value: detail.position!,
          ),
        // 归属（TM/TA 可见）
        if (detail.owner != null)
          _infoRow(
            icon: Icons.person,
            label: '归属',
            value: detail.owner!.name,
          ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFA6A6A6)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFA6A6A6),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF181818),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
