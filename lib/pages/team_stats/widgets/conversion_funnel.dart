/// 团队统计 - 转化漏斗
///
/// 4 阶段进度条（公海 → 已分配 → 跟进中 → 已转化），
/// 基 = funnel.pending（后端修正键）；宽度动画 500ms。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/models/team_stats.dart';
import 'package:telemarketing_app/theme/chart_colors.dart';

/// 转化漏斗
class ConversionFunnel extends StatelessWidget {
  final TeamFunnel funnel;

  const ConversionFunnel({super.key, required this.funnel});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = funnel.pending;
    final stages = <(String, int, Color)>[
      ('公海', funnel.pending, ChartColors.brand),
      ('已分配', funnel.assigned, ChartColors.brandLight),
      ('跟进中', funnel.following, ChartColors.success),
      ('已转化', funnel.converted, ChartColors.successDeep),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: stages.map((s) {
        final (label, value, color) = s;
        final pct = base > 0 ? (value / base).clamp(0.0, 1.0) : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                  Text(
                    '$value · ${(pct * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: LayoutBuilder(
                  builder: (ctx, constraints) => AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    width: constraints.maxWidth * pct,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
