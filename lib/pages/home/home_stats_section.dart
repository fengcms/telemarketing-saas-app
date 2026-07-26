/// 首页今日概况 Section + 统计卡片网格
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/home_stats.dart';
import 'package:telemarketing_app/providers/home_provider.dart';
import 'package:telemarketing_app/widgets/app_card_section.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';
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

    return AppCardSection(
      title: '今日工作概况',
      trailing: dateLabel,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: state.isLoadingStats && state.stats == null
          ? _buildStatsGrid(null)
          : state.statsError != null && state.stats == null
              ? _buildErrorRetry(state.statsError!, () {
                  ref.read(homePageProvider.notifier).retryStats();
                })
              : _buildStatsGrid(state.stats),
    );
  }

  Widget _buildStatsGrid(HomeStats? stats) {
    if (stats == null) {
      return const Row(
        children: [
          Expanded(child: SkeletonStatCard()),
          SizedBox(width: 12),
          Expanded(child: SkeletonStatCard()),
        ],
      );
    }

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
            Expanded(child: _statCard('线索总数', '${stats.myLeadsTotal}')),
            const SizedBox(width: 12),
            Expanded(child: _statCard('今日到期', '${state.todayPending}')),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: BrandColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: BrandColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorRetry(String error, VoidCallback onRetry) {
    return Column(
      children: [
        const Icon(Icons.cloud_off, size: 48, color: BrandColors.textDisabled),
        const SizedBox(height: 8),
        Text(error,
            style: const TextStyle(
                fontSize: 13, color: BrandColors.textSecondary)),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: onRetry,
          child: const Text('重试'),
        ),
      ],
    );
  }
}
