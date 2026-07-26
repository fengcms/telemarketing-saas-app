/// 个人统计 - 今日概况（固定展示 myToday 实时数据，不随日期范围变化）
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 今日概况 2 卡（今日跟进 / 今日接通）
class TodayOverview extends StatelessWidget {
  final int followupCount;
  final int answeredCount;

  const TodayOverview({
    super.key,
    required this.followupCount,
    required this.answeredCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          _card('今日跟进', followupCount),
          _card('今日接通', answeredCount),
        ],
      ),
    );
  }

  Widget _card(String label, int value) => Container(
        decoration: BoxDecoration(
          color: BrandColors.primarySurface,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: BrandColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: BrandColors.primary,
              ),
            ),
          ],
        ),
      );
}
