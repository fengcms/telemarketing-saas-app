/// 个人统计 - 转化率饼图
///
/// 左右分区布局：左侧实心饼图（已转化 vs 未转化），右侧百分比大字 + 图例。
/// 饼图固定 150×150，避免布局空间失控（前版环形因自适应占比导致高度异常）。
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:telemarketing_app/models/personal_stats.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 转化率饼图（实心，已转化 / 未转化 两扇区）
class ConversionPie extends StatelessWidget {
  final PersonalStats stats;

  const ConversionPie({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final converted = stats.converted;
    final leadsTotal = stats.leadsTotal;
    final notConverted = leadsTotal - converted;
    final hasData = leadsTotal > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── 左侧：实心饼图（固定尺寸）──
        SizedBox(
          width: 150,
          height: 150,
          child: hasData
              ? PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 2,
                    centerSpaceRadius: 0,
                    borderData: FlBorderData(show: false),
                    sections: [
                      PieChartSectionData(
                        value: converted.toDouble(),
                        color: BrandColors.primary,
                        title: '',
                        radius: 60,
                      ),
                      PieChartSectionData(
                        value: notConverted.toDouble(),
                        color: BrandColors.line,
                        title: '',
                        radius: 60,
                      ),
                    ],
                    pieTouchData: PieTouchData(enabled: false),
                  ),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                )
              : Container(
                  decoration: BoxDecoration(
                    color: BrandColors.line,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '暂无',
                      style: TextStyle(
                        fontSize: 13,
                        color: BrandColors.textSecondary,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 20),
        // ── 右侧：百分比 + 图例 ──
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stats.conversionRateDisplay,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              _Legend(
                color: BrandColors.primary,
                label: '已转化',
                value: '$converted',
              ),
              const SizedBox(height: 8),
              _Legend(
                color: BrandColors.line,
                label: '未转化',
                value: '$notConverted',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 饼图图例行
class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: BrandColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: BrandColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
