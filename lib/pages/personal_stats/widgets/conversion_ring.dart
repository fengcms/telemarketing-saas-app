/// 个人统计 - 转化率环形图
///
/// 中心显示转化率百分比；环用 CircularProgressIndicator（primary 填充 + 灰底环）。
/// 下方"转化 X / 线索 Y"说明。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/models/personal_stats.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 转化率环形
class ConversionRing extends StatelessWidget {
  final PersonalStats stats;

  const ConversionRing({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: stats.conversionProgress,
                  strokeWidth: 12,
                  backgroundColor: BrandColors.line,
                  color: BrandColors.primary,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stats.conversionRateDisplay,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: BrandColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '转化率',
                      style: TextStyle(
                        fontSize: 12,
                        color: BrandColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            stats.conversionSummary,
            style: const TextStyle(
              fontSize: 14,
              color: BrandColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
