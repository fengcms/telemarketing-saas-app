/// 个人统计 - 数据详情 2×3 卡片
///
/// 线索总数 / 跟进数 / 接通数 / 未接数 / 转化数 / 转化率。
/// 均展示"当前日期范围"聚合数据（随 Tab 切换重新请求）。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/models/personal_stats.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 数据详情卡片组
class DetailGrid extends StatelessWidget {
  final PersonalStats stats;

  const DetailGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          _card(scheme, '线索总数', formatBigNumber(stats.leadsTotal)),
          _card(scheme, '跟进数', formatBigNumber(stats.followed)),
          _card(scheme, '接通数', formatBigNumber(stats.answered)),
          _card(scheme, '未接数', formatBigNumber(stats.noAnswer)),
          _card(scheme, '转化数', formatBigNumber(stats.converted)),
          _card(scheme, '转化率', stats.conversionRateDisplay, accent: true),
        ],
      ),
    );
  }

  Widget _card(
    ColorScheme scheme,
    String label,
    String value, {
    bool accent = false,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: BrandColors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13, color: BrandColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: accent ? BrandColors.primary : BrandColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}

/// 大数字格式化：<10000 原样；≥10000 转"万"单位（保留最多 1 位小数）
String formatBigNumber(int n) {
  if (n < 10000) return n.toString();
  final wan = n / 10000;
  return '${wan.toStringAsFixed(wan.truncateToDouble() == wan ? 0 : 1)}万';
}
