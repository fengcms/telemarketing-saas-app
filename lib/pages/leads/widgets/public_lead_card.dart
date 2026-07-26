/// 公海线索卡片组件
///
/// 展示公海线索信息 + 领取按钮。
/// - 不显示归属人行（公海线索无归属人）
/// - 不显示 nextFollowupAt 徽章（公海线索未设置跟进计划）
/// - 状态标签固定为"待跟进"
/// - 卡片不可点进详情：员工无权限查看公海线索详情，仅领取到自己名下后才可看
/// - 分类/项目名通过 [OptionsCacheService] 解析为显示名（修复原先写死的"商铺"）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/lead.dart';
import 'package:telemarketing_app/providers/options_provider.dart';
import 'package:telemarketing_app/services/options_cache_service.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 公海线索卡片组件
class PublicLeadCard extends ConsumerWidget {
  final Lead lead;

  /// 领取按钮是否正在加载中
  final bool claiming;

  /// 点击领取按钮
  final VoidCallback? onClaim;

  const PublicLeadCard({
    super.key,
    required this.lead,
    this.claiming = false,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cache = ref.watch(optionsCacheProvider);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          // 圆形领取按钮相对信息列上下居中，避免与姓名行顶对齐造成的视觉错位
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── 信息列 ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameRow(),
                  const SizedBox(height: 8),
                  _buildContactRow(),
                  const SizedBox(height: 6),
                  _buildCategoryRow(cache),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── 领取按钮（右侧上下居中圆形图标按钮）──
            _buildClaimButton(),
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
              color: BrandColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
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
              color: BrandColors.warning,
            ),
          ),
        ),
      ],
    );
  }

  // ── 行2：电话 + 更新时间（单行合并，压低高度）──

  Widget _buildContactRow() {
    return Row(
      children: [
        const Icon(Icons.call, size: 14, color: BrandColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            lead.phone,
            style: const TextStyle(
              fontSize: 14,
              color: BrandColors.textSecondary,
              letterSpacing: 0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.access_time, size: 14, color: BrandColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            _formatTime(lead.updatedAt),
            style: const TextStyle(fontSize: 12, color: BrandColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── 行3：分类标签 + 项目名（经 OptionsCache 解析真实分类）──

  Widget _buildCategoryRow(OptionsCacheService cache) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        cache.getCategoryName(lead.categoryId),
        cache.getProjectName(lead.projectId ?? lead.project?.id),
      ]),
      builder: (_, snapshot) {
        final catName = snapshot.data?[0] as String?;
        final projName = snapshot.data?[1] as String? ?? lead.project?.name;
        final hasC = catName != null && catName.isNotEmpty;
        final hasP = projName != null && projName.isNotEmpty;
        if (!hasC && !hasP) return const SizedBox(height: 20);
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
                child: Text(
                  catName,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF003CAB)),
                ),
              ),
            if (hasC && hasP) const SizedBox(width: 8),
            if (hasP)
              Expanded(
                child: Text(
                  projName,
                  style: const TextStyle(fontSize: 13, color: BrandColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        );
      },
    );
  }

  // ── 领取按钮（右侧上下居中圆形图标按钮，固定 44×44）──
  //
  // 固定尺寸保证领取 loading 时宽度不抖动（原胶囊按钮在 loading 时宽度收窄，
  // 导致左侧信息列重排）。loading 时仅中心图标换成 spinner，背景保持主题色。

  Widget _buildClaimButton() {
    final active = onClaim != null;
    final enabled = active && !claiming;
    final bgColor = active ? BrandColors.primary : BrandColors.textDisabled;

    return Tooltip(
      message: '领取该线索',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onClaim : null,
          customBorder: const CircleBorder(),
          splashColor: Colors.white.withValues(alpha: 0.25),
          highlightColor: Colors.white.withValues(alpha: 0.12),
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            width: 44,
            height: 44,
            child: Center(
              child: claiming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.person_add,
                      size: 22,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
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
