/// 个人统计 - 今日概况（固定展示 myToday 实时数据，不随日期范围变化）
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/widgets/stat_card.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          StatCard(
            label: '今日跟进',
            value: followupCount.toString(),
            valueFontSize: 30,
          ),
          StatCard(
            label: '今日接通',
            value: answeredCount.toString(),
            valueFontSize: 30,
          ),
        ],
      ),
    );
  }
}
