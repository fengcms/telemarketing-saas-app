/// 团队统计 - 逐日趋势折线图
///
/// fl_chart LineChart（3 系列：跟进数 / 接通数 / 转化数）。
/// X = date(MM-DD)，动画 800ms，区域填充 10%。
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:telemarketing_app/models/team_stats.dart';
import 'package:telemarketing_app/theme/chart_colors.dart';

/// 逐日趋势折线图
class TrendLineChart extends StatelessWidget {
  final List<DailyTrend> trend;

  const TrendLineChart({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (trend.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            '暂无趋势数据',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    final follow = <FlSpot>[];
    final answered = <FlSpot>[];
    final converted = <FlSpot>[];
    for (var i = 0; i < trend.length; i++) {
      final t = trend[i];
      follow.add(FlSpot(i.toDouble(), t.followup.toDouble()));
      answered.add(FlSpot(i.toDouble(), t.answered.toDouble()));
      converted.add(FlSpot(i.toDouble(), t.converted.toDouble()));
    }
    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            _line(follow, ChartColors.trendFollowup),
            _line(answered, ChartColors.trendAnswered),
            _line(converted, ChartColors.trendConverted),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= trend.length) return const SizedBox();
                  return Text(
                    trend[i].mmdd,
                    style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(enabled: true),
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color c) => LineChartBarData(
        spots: spots,
        isCurved: true,
        color: c,
        barWidth: 2,
        dotData: FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: c.withValues(alpha: 0.1)),
      );
}
