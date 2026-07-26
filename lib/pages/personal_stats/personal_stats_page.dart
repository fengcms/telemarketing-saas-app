/// 个人统计独立页（v0.32）
///
/// 入口：个人中心 → 统计概览区（ProfileStatsCard）/「个人统计」不再单独成项，业绩卡即入口。
/// 结构：AppBar（返回 + 刷新）+ 吸顶日期范围 + 骨架/错态 + 今日概况 + 数据详情 + 转化率环。
/// 数据：personalStatsProvider（GET /api/tenant/stats/mine，按范围 5 分钟缓存）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/providers/personal_stats_provider.dart';
import 'widgets/date_range_selector.dart';
import 'widgets/today_overview.dart';
import 'widgets/detail_grid.dart';
import 'widgets/conversion_ring.dart';
import 'package:telemarketing_app/widgets/app_error_body.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 个人统计页
class PersonalStatsPage extends ConsumerWidget {
  const PersonalStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(personalStatsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人统计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(personalStatsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          const DateRangeSelector(),
          Expanded(
            child: _body(s, ref, context),
          ),
        ],
      ),
    );
  }

  Widget _body(PersonalStatsState s, WidgetRef ref, BuildContext context) {
    if (s.errorMessage != null) {
      return AppErrorBody(
        icon: Icons.cloud_off,
        title: '加载失败',
        message: s.errorMessage.toString(),
        actionText: '重试',
        onAction: () =>
            ref.read(personalStatsProvider.notifier).refresh(),
      );
    }
    if (s.stats == null) {
      return const _StatsSkeleton();
    }
    final stats = s.stats!;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('今日概况'),
          TodayOverview(
            followupCount: stats.todayFollowup,
            answeredCount: stats.todayAnswered,
          ),
          _sectionTitle('数据详情'),
          DetailGrid(stats: stats),
          _sectionTitle('转化率详情'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.3),
              ),
            ),
            child: ConversionRing(stats: stats),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
}

/// 首屏骨架（灰块呼吸动画）
class _StatsSkeleton extends StatefulWidget {
  const _StatsSkeleton();

  @override
  State<_StatsSkeleton> createState() => _StatsSkeletonState();
}

class _StatsSkeletonState extends State<_StatsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);
  late final Animation<double> _alpha =
      Tween<double>(begin: 0.4, end: 0.8).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _box(height: 90)),
              SizedBox(width: 12),
              Expanded(child: _box(height: 90)),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: List.generate(6, (_) => _box()),
          ),
          const SizedBox(height: 24),
          _box(height: 168),
        ],
      ),
    );
  }

  Widget _box({double height = 90}) => FadeTransition(
        opacity: _alpha,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: BrandColors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}
