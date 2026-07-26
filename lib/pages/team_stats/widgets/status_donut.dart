/// 团队统计 - 状态分布环形图
///
/// fl_chart PieChart（环宽，中心叠总计，右排 5 项图例）。
/// 公海 / 已分配 / 跟进中 / 已转化 / 无效。
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:telemarketing_app/models/team_stats.dart';
import 'package:telemarketing_app/theme/chart_colors.dart';

/// 状态分布环形图
class StatusDonut extends StatelessWidget {
  final TeamStatusBreakdown byStatus;
  final int total;

  const StatusDonut({
    super.key,
    required this.byStatus,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = <(String, int, Color)>[
      ('公海', byStatus.pending, ChartColors.statusPalette[0]),
      ('已分配', byStatus.assigned, ChartColors.statusPalette[1]),
      ('跟进中', byStatus.following, ChartColors.statusPalette[2]),
      ('已转化', byStatus.converted, ChartColors.statusPalette[3]),
      ('无效', byStatus.invalid, ChartColors.statusPalette[4]),
    ];
    final sum = items.fold<int>(0, (s, e) => s + e.$2);
    return Row(
      children: [
        SizedBox(
          width: 132,
          height: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 28,
                  borderData: FlBorderData(show: false),
                  sections: items.map((e) {
                    final (_, value, color) = e;
                    return PieChartSectionData(
                      value: value.toDouble(),
                      color: color,
                      title: '',
                      radius: 46,
                    );
                  }).toList(),
                  pieTouchData: PieTouchData(enabled: false),
                ),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '总计',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: items.map((e) {
              final (label, value, color) = e;
              final pct = sum > 0
                  ? (value / sum * 100).toStringAsFixed(1)
                  : '0.0';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(label, style: const TextStyle(fontSize: 13)),
                    ),
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 52,
                      child: Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
