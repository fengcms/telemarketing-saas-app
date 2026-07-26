/// 团队统计 - 逐日趋势分组柱状图
///
/// fl_chart BarChart（每日一组 3 柱：跟进 / 接通 / 转化）。
/// 配 3 色图例 + 点按 tooltip；天数 ≤10 铺满屏宽，>10 横向滚动每格 46px。
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:telemarketing_app/models/team_stats.dart';
import 'package:telemarketing_app/theme/chart_colors.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 逐日趋势分组柱状图
class TrendBarChart extends StatelessWidget {
  final List<DailyTrend> trend;

  const TrendBarChart({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('暂无趋势数据', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // ── 图例（3 色，复用状态语义色）──
    const legend = <(String, Color)>[
      ('跟进', ChartColors.trendFollowup),
      ('接通', ChartColors.trendAnswered),
      ('转化', ChartColors.trendConverted),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: legend.map((e) {
            final (label, color) = e;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const perDay = 46.0;
            final fitWidth = constraints.maxWidth;
            final needScroll = trend.length * perDay > fitWidth;
            final chartWidth = needScroll ? trend.length * perDay : fitWidth;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: needScroll
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: chartWidth,
                height: 240,
                child: BarChart(_data()),
              ),
            );
          },
        ),
      ],
    );
  }

  BarChartData _data() {
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < trend.length; i++) {
      final t = trend[i];
      groups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 4,
          barRods: [
            _rod(t.followup.toDouble(), ChartColors.trendFollowup),
            _rod(t.answered.toDouble(), ChartColors.trendAnswered),
            _rod(t.converted.toDouble(), ChartColors.trendConverted),
          ],
        ),
      );
    }

    // X 轴标签疏化：天数多时隔若干个显示一个，避免 MM-DD 拥挤
    final step = (trend.length / 8).ceil().clamp(1, trend.length);

    return BarChartData(
      barGroups: groups,
      groupsSpace: 10,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (v, _) => Text(
              v.toInt().toString(),
              style: const TextStyle(fontSize: 10, color: BrandColors.textSecondary),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= trend.length) return const SizedBox();
              if (i % step != 0 && i != trend.length - 1) {
                return const SizedBox();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  trend[i].mmdd,
                  style: const TextStyle(fontSize: 10, color: BrandColors.textSecondary),
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipColor: (_) => BrandColors.textPrimary,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final labels = ['跟进', '接通', '转化'];
            final t = trend[groupIndex];
            return BarTooltipItem(
              '${t.mmdd}\n${labels[rodIndex]}  ${rod.toY.toInt()}',
              const TextStyle(color: Colors.white, fontSize: 12),
            );
          },
        ),
      ),
    );
  }

  BarChartRodData _rod(double v, Color c) => BarChartRodData(
        toY: v,
        color: c,
        width: 10,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(3),
          topRight: Radius.circular(3),
        ),
      );
}
