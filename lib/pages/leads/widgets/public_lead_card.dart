/// 公海线索卡片组件
///
/// 展示公海线索信息 + 领取按钮。
/// - 不显示归属人行（公海线索无归属人）
/// - 不显示 nextFollowupAt 徽章（公海线索未设置跟进计划）
/// - 状态标签固定为"待跟进"
/// - 底部分割线 +「领取该线索」按钮
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/models/lead.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 公海线索卡片组件
class PublicLeadCard extends StatelessWidget {
  final Lead lead;

  /// 领取按钮是否正在加载中
  final bool claiming;

  /// 点击卡片信息区域
  final VoidCallback? onTap;

  /// 点击领取按钮
  final VoidCallback? onClaim;

  const PublicLeadCard({
    super.key,
    required this.lead,
    this.claiming = false,
    this.onTap,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 信息区域 ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameRow(),
                  const SizedBox(height: 8),
                  _buildPhoneRow(),
                  const SizedBox(height: 6),
                  _buildCategoryRow(),
                  const SizedBox(height: 6),
                  _buildUpdateTimeRow(),
                ],
              ),
            ),

            // ── 分割线 ──
            const Divider(height: 0, color: Color(0xFFEEEEEE)),

            // ── 领取按钮区域 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonal(
                    onPressed: claiming || onClaim == null ? null : onClaim,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: claiming
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: BrandColors.primary,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, size: 16),
                              const SizedBox(width: 6),
                              const Text('领取该线索'),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 行1：姓名 + 状态标签（固定"待跟进"）──

  Widget _buildNameRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            lead.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF181818),
            ),
          ),
        ),
        // 固定"待跟进"标签
        Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Color(0x1AED7B2F),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: const Text(
            '待跟进',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFED7B2F),
            ),
          ),
        ),
      ],
    );
  }

  // ── 行2：电话 ──

  Widget _buildPhoneRow() {
    return Row(
      children: [
        const Icon(Icons.call, size: 14, color: Color(0xFFA6A6A6)),
        const SizedBox(width: 6),
        Text(
          lead.phone,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFFA6A6A6),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ── 行3：分类标签 + 项目名 ──

  Widget _buildCategoryRow() {
    final hasCategory = lead.categoryId != null && lead.categoryId!.isNotEmpty;
    final projName = lead.project?.name ?? '';
    final hasProject = projName.isNotEmpty && lead.project?.id != null;

    return Row(
      children: [
        if (hasCategory)
          Container(
            height: 20,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD9E1FF),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '商铺',
              style: TextStyle(fontSize: 12, color: Color(0xFF003CAB)),
            ),
          ),
        if (hasCategory && hasProject) const SizedBox(width: 8),
        if (hasProject)
          Expanded(
            child: Text(
              projName,
              style: const TextStyle(fontSize: 13, color: Color(0xFFA6A6A6)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (!hasCategory && !hasProject) const SizedBox(height: 20),
      ],
    );
  }

  // ── 行4：最后更新时间 ──

  Widget _buildUpdateTimeRow() {
    return Row(
      children: [
        const Icon(Icons.access_time, size: 14, color: Color(0xFFA6A6A6)),
        const SizedBox(width: 4),
        Text(
          '最后更新: ${_formatTime(lead.updatedAt)}',
          style: const TextStyle(fontSize: 12, color: Color(0xFFA6A6A6)),
        ),
      ],
    );
  }

  // ── 时间格式化 ──

  String _formatTime(int? unixSec) {
    if (unixSec == null || unixSec <= 0) return '--';
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = now - unixSec;
    if (diff < 60) return '刚刚';
    if (diff < 3600) return '${diff ~/ 60}分钟前';
    if (diff < 86400) return '${diff ~/ 3600}小时前';
    if (diff < 172800) return '昨天';
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSec * 1000);
    return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
