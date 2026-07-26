/// 线索卡片组件
///
/// 5 行布局，严格按 design doc §3.3 实现。
/// categoryId/projectId 通过 [OptionsCacheService] 解析为显示名。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/constants/lead_constants.dart';
import 'package:telemarketing_app/models/lead.dart';
import 'package:telemarketing_app/models/option_item.dart';
import 'package:telemarketing_app/providers/options_provider.dart';
import 'package:telemarketing_app/services/options_cache_service.dart';
import 'package:telemarketing_app/theme/user_color.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 线索卡片组件
///
/// 5 行布局，严格按 design doc §3.3 实现。
/// categoryId/projectId 通过 [OptionsCacheService] 解析为显示名。
/// [users] 为团队成员列表（归属人姓名查找用），由父组件从 [LeadListState] 传入。
class LeadCard extends ConsumerWidget {
  final Lead lead;
  final bool showOwner; // TM/TA 可见
  final List<OptionItem>? users; // 归属人姓名查找缓存
  final VoidCallback? onTap;

  const LeadCard({
    super.key,
    required this.lead,
    this.showOwner = false,
    this.users,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cache = ref.watch(optionsCacheProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
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
            _buildNameRow(),
            const SizedBox(height: 8),
            _buildPhoneRow(),
            const SizedBox(height: 6),
            _buildCategoryRow(cache),
            const SizedBox(height: 6),
            _buildFollowUpRow(),
            if (showOwner)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildOwnerRow(),
              ),
          ],
        ),
      ),
    );
  }

  // ── 行1：姓名 + 状态标签 ──

  Widget _buildNameRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            lead.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: BrandColors.textPrimary,
            ),
          ),
        ),
        _buildStatusTag(lead.status),
      ],
    );
  }

  // ── 行2：电话 ──

  Widget _buildPhoneRow() {
    return Row(
      children: [
        const Icon(Icons.call, size: 14, color: BrandColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          lead.phone,
          style: const TextStyle(
            fontSize: 14,
            color: BrandColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ── 行3：分类标签 + 项目名 ──

  Widget _buildCategoryRow(OptionsCacheService cache) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        cache.getCategoryName(lead.categoryId),
        cache.getProjectName(lead.projectId ?? lead.project?.id),
      ]),
      builder: (_, snapshot) {
        final catName = snapshot.data?[0] as String?;
        final projName =
            snapshot.data?[1] as String? ?? lead.project?.name;
        final hasC = catName != null && catName.isNotEmpty;
        final hasP = projName != null && projName.isNotEmpty;
        return Row(
          children: [
            if (hasC)
              Container(
                height: 20,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9E1FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(catName,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF003CAB))),
              ),
            if (hasC && hasP) const SizedBox(width: 8),
            if (hasP)
              Expanded(
                child: Text(projName,
                    style: const TextStyle(
                        fontSize: 13, color: BrandColors.textSecondary),
                    overflow: TextOverflow.ellipsis),
              ),
            if (!hasC && !hasP) const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  // ── 行4：最后跟进时间 + 跟进倒计时徽章 ──

  Widget _buildFollowUpRow() {
    return Row(
      children: [
        const Icon(Icons.access_time, size: 14, color: BrandColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          '最后跟进: ${_formatTime(lead.lastFollowupAt)}',
          style: const TextStyle(
            fontSize: 12,
            color: BrandColors.textSecondary,
          ),
        ),
        const Spacer(),
        if (lead.nextFollowupAt != null && lead.nextFollowupAt! > 0)
          _buildFollowUpBadge(lead.nextFollowupAt!),
      ],
    );
  }

  // ── 行5（TM/TA 可见）：归属人 ──

  Widget _buildOwnerRow() {
    // owner 可能是嵌套对象或扁平 ownerId；降级从 users 缓存中查找
    final ownerName = lead.owner?.name;
    final uid = lead.owner?.id ?? lead.ownerId;
    final name = ownerName ??
        users?.where((u) => u.id == uid).firstOrNull?.name ??
        '未指定';
    final color = userColor(uid);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── 状态标签 ──

  Widget _buildStatusTag(String status) {
    final (bg, fg, text) = _statusStyle(status);
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }

  (Color, Color, String) _statusStyle(String status) =>
      LeadConstants.statusColorStyle(status);

  // ── 跟进倒计时徽章 ──

  Widget _buildFollowUpBadge(int nextFollowupAt) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diffDays = ((nextFollowupAt - now) / 86400).round();

    Color bg, fg;
    String text;
    if (diffDays < 0) {
      bg = const Color(0x1AD54941);
      fg = BrandColors.error;
      text = '已逾期${(-diffDays)}天';
    } else if (diffDays == 0) {
      bg = const Color(0x1A2BA471);
      fg = BrandColors.success;
      text = '今日可打';
    } else if (diffDays == 1) {
      bg = const Color(0x1AE37318);
      fg = const Color(0xFFE37318);
      text = '明天跟进';
    } else {
      bg = const Color(0x1AE37318);
      fg = const Color(0xFFE37318);
      text = '$diffDays天后跟进';
    }

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
      ),
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
