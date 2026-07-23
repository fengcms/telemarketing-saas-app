/// 线索卡片组件
///
/// 5 行布局，严格按 design doc §3.3 实现。
/// categoryId/projectId 通过 [OptionsCacheService] 解析为显示名。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:telemarketing_app/constants/lead_constants.dart';
import 'package:telemarketing_app/models/lead.dart';
import 'package:telemarketing_app/providers/options_provider.dart';
import 'package:telemarketing_app/services/options_cache_service.dart';

/// 线索卡片组件
///
/// 5 行布局，严格按 design doc §3.3 实现。
/// categoryId/projectId 通过 [OptionsCacheService] 解析为显示名。
class LeadCard extends ConsumerWidget {
  final Lead lead;
  final bool showOwner; // TM/TA 可见
  final VoidCallback? onTap;

  const LeadCard({
    super.key,
    required this.lead,
    this.showOwner = false,
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
              color: Color(0xFF181818),
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
        const Icon(TDIcons.call, size: 14, color: Color(0xFFA6A6A6)),
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
                        fontSize: 13, color: Color(0xFFA6A6A6)),
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
        const Icon(TDIcons.time, size: 14, color: Color(0xFFA6A6A6)),
        const SizedBox(width: 4),
        Text(
          '最后跟进: ${_formatTime(lead.lastFollowupAt)}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFA6A6A6),
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
    return Row(
      children: [
        const Icon(TDIcons.user, size: 14, color: Color(0xFFA6A6A6)),
        const SizedBox(width: 4),
        Text(
          '归属: ${lead.owner?.name ?? "--"}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFA6A6A6),
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
      fg = const Color(0xFFD54941);
      text = '已逾期${(-diffDays)}天';
    } else if (diffDays == 0) {
      bg = const Color(0x1A2BA471);
      fg = const Color(0xFF2BA471);
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
