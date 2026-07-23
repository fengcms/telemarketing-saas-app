/// 首页今日概况 Section + 统计卡片网格
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/home_stats.dart';
import '../../providers/home_provider.dart';
import 'home_skeletons.dart';

/// 今日概况 Section（标题 + 日期 + 统计网格）
class HomeStatsSection extends ConsumerWidget {
  final HomePageState state;

  const HomeStatsSection({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dateLabel =
        '${today.month}月${today.day}日 ${weekDays[today.weekday - 1]}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '今日工作概况',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181818),
                  ),
                ),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFC5C5C5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.isLoadingStats && state.stats == null)
              _buildStatsGrid(null, ref)
            else if (state.statsError != null && state.stats == null)
              _buildErrorRetry(state.statsError!, () {
                ref.read(homePageProvider.notifier).retryStats();
              })
            else
              _buildStatsGrid(state.stats, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(HomeStats? stats, WidgetRef ref) {
    if (stats == null && ref.read(homePageProvider).isLoadingStats) {
      return const Row(
        children: [
          Expanded(child: SkeletonStatCard()),
          SizedBox(width: 12),
          Expanded(child: SkeletonStatCard()),
        ],
      );
    }
    if (stats == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statCard('今日跟进', '${stats.followupCount}')),
            const SizedBox(width: 12),
            Expanded(child: _statCard('今日接通', '${stats.answeredCount}')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _statCard('线索总数', '${stats.myLeadsTotal}')),
            const SizedBox(width: 12),
            Expanded(
                child: _statCard('今日到期', '${stats.dueToday}')),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF181818),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFA6A6A6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorRetry(String error, VoidCallback onRetry) {
    return Column(
      children: [
        const Icon(Icons.cloud_off, size: 48, color: Color(0xFFDCDCDC)),
        const SizedBox(height: 8),
        Text(error,
            style: const TextStyle(fontSize: 13, color: Color(0xFFC5C5C5))),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0052D9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('重试',
                style: TextStyle(fontSize: 13, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
