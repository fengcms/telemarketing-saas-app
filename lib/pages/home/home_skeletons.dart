/// 首页骨架屏组件
///
/// 首页加载时显示的占位区块。
library;

import 'package:flutter/material.dart';

/// 骨架屏区块
class SkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  const SkeletonBlock({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE7E7E7),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// 骨架屏统计卡片
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          SkeletonBlock(width: 48, height: 32),
          SizedBox(height: 8),
          SkeletonBlock(width: 64, height: 14),
        ],
      ),
    );
  }
}

/// 骨架屏日程卡片
class SkeletonScheduleCard extends StatelessWidget {
  const SkeletonScheduleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const SkeletonBlock(width: 44, height: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBlock(width: 160, height: 16),
                const SizedBox(height: 8),
                SkeletonBlock(width: 100, height: 14),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

/// 骨架屏区块容器
class SkeletonSection extends StatelessWidget {
  final bool isSchedule;
  const SkeletonSection({super.key, this.isSchedule = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isSchedule ? 100 : 140,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E7E7),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            if (isSchedule) ...[
              const SkeletonScheduleCard(),
              const SkeletonScheduleCard(),
              const SkeletonScheduleCard(),
            ] else ...[
              const Row(
                children: [
                  Expanded(child: SkeletonStatCard()),
                  SizedBox(width: 12),
                  Expanded(child: SkeletonStatCard()),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(child: SkeletonStatCard()),
                  SizedBox(width: 12),
                  Expanded(child: SkeletonStatCard()),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
