/// 首页今日概况 Section + 统计卡片网格
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/home_stats.dart';
import 'package:telemarketing_app/models/manager_today_stats.dart';
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
      // TM/TA 展示「团队今日概览」，TE 展示「今日工作概况」
      title: state.isManager ? '团队今日概览' : '今日工作概况',
      trailing: dateLabel,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: _buildStatsContent(ref),
    );
  }

  Widget _buildStatsContent(WidgetRef ref) {
    if (state.isManager) {
      final m = state.managerTodayStats;
      if (m == null) {
        if (state.managerStatsError != null && !state.isLoadingStats) {
          return _buildErrorRetry(state.managerStatsError!, () {
            ref.read(homePageProvider.notifier).retryStats();
          });
        }
        return _buildTeamSkeleton();
      }
      return _buildTeamGrid(m);
    }

    // TE：个人维度
    if (state.stats == null) {
      if (state.statsError != null && !state.isLoadingStats) {
        return _buildErrorRetry(state.statsError!, () {
          ref.read(homePageProvider.notifier).retryStats();
        });
      }
      return _buildSkeleton();
    }
    return _buildPersonalGrid(state.stats!);
  }

  // ── 团队当日网格（TM/TA）──

  Widget _buildTeamGrid(ManagerTodayStats m) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _teamCard('团队今日跟进', m.todayFollowup,
                    diff: m.compareYesterday.followupDiff)),
            const SizedBox(width: 12),
            Expanded(
                child: _teamCard('团队今日接通', m.todayAnswered,
                    diff: m.compareYesterday.answeredDiff)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _teamCard('团队今日转化', m.todayConverted,
                    diff: m.compareYesterday.convertedDiff)),
            const SizedBox(width: 12),
            Expanded(child: _teamCard('团队今日待办', m.todayPending)),
          ],
        ),
      ],
    );
  }

  Widget _teamCard(String label, int value, {int? diff}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$value',
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
          if (diff != null) ...[
            const SizedBox(height: 4),
            _diffBadge(diff),
          ],
        ],
      ),
    );
  }

  /// 较昨日同时段环比小标
  /// [diff] > 0 绿 ↗、< 0 红 ↘、== 0 灰 — 持平
  Widget _diffBadge(int diff) {
    final Color color;
    final String text;
    if (diff > 0) {
      color = Colors.green.shade600;
      text = '↗ +$diff';
    } else if (diff < 0) {
      color = Colors.red.shade500;
      text = '↘ ${diff.abs()}';
    } else {
      color = BrandColors.textDisabled;
      text = '— 持平';
    }
    return Text(
      text,
      style: TextStyle(fontSize: 12, color: color),
    );
  }

  // ── 个人网格（TE，原逻辑）──

  Widget _buildPersonalGrid(HomeStats stats) {
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

  // ── 骨架 / 错误态 ──

  Widget _buildSkeleton() {
    return const Row(
      children: [
        Expanded(child: SkeletonStatCard()),
        SizedBox(width: 12),
        Expanded(child: SkeletonStatCard()),
      ],
    );
  }

  Widget _buildTeamSkeleton() {
    return Column(
      children: [
        _buildSkeleton(),
        const SizedBox(height: 12),
        _buildSkeleton(),
      ],
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
