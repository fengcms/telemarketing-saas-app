/// 团队统计 - 概览卡片 2×2
///
/// 总线索数 / 公海线索 / 转化率 / 跟进中。
/// 仅"今日"范围显示环比（较昨日）。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/models/team_stats.dart';
import 'package:telemarketing_app/providers/team_stats_provider.dart';
import 'package:telemarketing_app/theme/chart_colors.dart';

/// 概览卡片组
class OverviewCards extends StatelessWidget {
  final TeamStats stats;
  final DateRangeKind rangeKind;
  final TeamCompare compare;

  const OverviewCards({
    super.key,
    required this.stats,
    required this.rangeKind,
    required this.compare,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _card(
            scheme,
            '总线索数',
            formatBigNumber(stats.total),
            rangeKind == DateRangeKind.today ? _delta(compare.addedDiff) : null,
          ),
          _card(
            scheme,
            '公海线索',
            formatBigNumber(stats.byStatus.pending),
            stats.staleInPool > 0 ? _stale(stats.staleInPool) : null,
          ),
          _card(
            scheme,
            '转化率',
            '${stats.teamConversionRate.toStringAsFixed(1)}%',
            null,
          ),
          _card(
            scheme,
            '跟进中',
            formatBigNumber(stats.byStatus.following),
            rangeKind == DateRangeKind.today
                ? _delta(compare.followupDiff)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _card(
    ColorScheme scheme,
    String label,
    String value,
    Widget? badge,
  ) =>
      Card(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (badge != null) ...[
                const SizedBox(height: 4),
                badge,
              ],
            ],
          ),
        ),
      );

  Widget _delta(int diff) {
    if (diff == 0) {
      return Text(
        '较昨日 持平',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      );
    }
    final up = diff > 0;
    final color = up ? ChartColors.success : ChartColors.warning;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          up ? Icons.arrow_upward : Icons.arrow_downward,
          size: 12,
          color: color,
        ),
        Text(
          '较昨日 ${up ? '+' : ''}$diff',
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }

  Widget _stale(int n) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 12, color: ChartColors.warning),
          const SizedBox(width: 2),
          Text(
            '$n 条超 48h 未处理',
            style: TextStyle(fontSize: 11, color: ChartColors.warning),
          ),
        ],
      );
}

/// 大数字格式化：≤4 位原样；>4 位转"万"单位（保留 1 位小数）
String formatBigNumber(int n) {
  if (n < 10000) return n.toString();
  final wan = n / 10000;
  return '${wan.toStringAsFixed(wan.truncateToDouble() == wan ? 0 : 1)}万';
}
