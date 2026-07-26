/// 个人统计 - 数据详情 2×3 卡片
///
/// 线索总数 / 跟进数 / 接通数 / 未接数 / 转化数 / 转化率。
/// 均展示"当前日期范围"聚合数据（随 Tab 切换重新请求）。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/models/personal_stats.dart';
import 'package:telemarketing_app/widgets/stat_card.dart';

/// 数据详情卡片组
class DetailGrid extends StatelessWidget {
  final PersonalStats stats;

  const DetailGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.85,
        children: [
          StatCard(label: '线索总数', value: formatBigNumber(stats.leadsTotal)),
          StatCard(label: '跟进数', value: formatBigNumber(stats.followed)),
          StatCard(label: '接通数', value: formatBigNumber(stats.answered)),
          StatCard(label: '未接数', value: formatBigNumber(stats.noAnswer)),
          StatCard(label: '转化数', value: formatBigNumber(stats.converted)),
          StatCard(label: '转化率', value: stats.conversionRateDisplay, accent: true),
        ],
      ),
    );
  }
}

/// 大数字格式化：<10000 原样；≥10000 转"万"单位（保留最多 1 位小数）
String formatBigNumber(int n) {
  if (n < 10000) return n.toString();
  final wan = n / 10000;
  return '${wan.toStringAsFixed(wan.truncateToDouble() == wan ? 0 : 1)}万';
}
