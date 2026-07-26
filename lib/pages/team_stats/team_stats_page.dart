/// 团队统计独立页（v0.25）
///
/// 入口：个人中心 → 团队 → 团队统计（TM/TA 可见）。
/// 结构：AppBar（返回 + 刷新）+ 吸顶日期范围 + 骨架/空/错态 + 4 模块。
/// 数据：teamStatsProvider（GET /api/tenant/stats，按范围 5 分钟缓存）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/providers/team_stats_provider.dart';
import 'widgets/date_range_selector.dart';
import 'widgets/overview_cards.dart';
import 'widgets/conversion_funnel.dart';
import 'widgets/status_donut.dart';
import 'widgets/trend_line_chart.dart';
import 'widgets/agent_ranking.dart';

/// 团队看板页
class TeamStatsPage extends ConsumerWidget {
  const TeamStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(teamStatsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('团队看板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(teamStatsProvider.notifier).refresh(),
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

  Widget _body(TeamStatsState s, WidgetRef ref, BuildContext context) {
    if (s.errorMessage != null) {
      return _error(s.errorMessage.toString(), ref);
    }
    if (s.stats == null) {
      return const _StatsSkeleton();
    }
    if (s.isEmpty) {
      return _empty();
    }
    final stats = s.stats!;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          OverviewCards(
            stats: stats,
            rangeKind: s.rangeKind,
            compare: stats.compareYesterday,
          ),
          _module(
            context,
            title: '转化漏斗',
            child: ConversionFunnel(funnel: stats.funnel),
          ),
          _module(
            context,
            title: '状态分布',
            child: StatusDonut(
              byStatus: stats.byStatus,
              total: stats.total,
            ),
          ),
          _module(
            context,
            title: '逐日趋势',
            child: TrendLineChart(trend: stats.dailyTrend),
          ),
          _module(
            context,
            title: '坐席绩效排行',
            child: AgentRanking(agents: stats.agentPerf),
          ),
        ],
      ),
    );
  }

  Widget _module(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [child],
      ),
    );
  }

  Widget _error(String msg, WidgetRef ref) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                '加载失败',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                msg,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(teamStatsProvider.notifier).refresh(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );

  Widget _empty() => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                '当前时间范围暂无数据',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 4),
              Text(
                '试试切换「今日 / 本周 / 本月」',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
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
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: List.generate(4, (_) => _box(scheme)),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _box(scheme, height: 120),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(ColorScheme scheme, {double height = 80}) => FadeTransition(
        opacity: _alpha,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}
