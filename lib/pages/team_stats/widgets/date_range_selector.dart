/// 团队统计 - 吸顶日期范围选择器
///
/// 今日 / 本周 / 本月 / 自定义（≤90 天，Material 日期范围选择器）。
/// 选择自定义时调用 [showDateRangePicker]，拦截 >90 天。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/providers/team_stats_provider.dart';
import 'package:telemarketing_app/widgets/app_toast.dart';

/// 吸顶日期范围选择条
class DateRangeSelector extends ConsumerWidget {
  const DateRangeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(teamStatsProvider);
    final notifier = ref.read(teamStatsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final options = <(String, DateRangeKind)>[
      ('今日', DateRangeKind.today),
      ('本周', DateRangeKind.thisWeek),
      ('本月', DateRangeKind.thisMonth),
      ('自定义', DateRangeKind.custom),
    ];
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 8,
          children: [
            for (final (label, kind) in options)
              ChoiceChip(
                label: Text(label),
                selected: s.rangeKind == kind,
                selectedColor: scheme.primary.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: s.rangeKind == kind
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                onSelected: (_) {
                  switch (kind) {
                    case DateRangeKind.today:
                      notifier.setRangeToday();
                    case DateRangeKind.thisWeek:
                      notifier.setRangeThisWeek();
                    case DateRangeKind.thisMonth:
                      notifier.setRangeThisMonth();
                    case DateRangeKind.custom:
                      _pickCustom(context, notifier);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustom(
    BuildContext context,
    TeamStatsNotifier notifier,
  ) async {
    final now = DateTime.now();
    final first = DateTime(now.year - 1, now.month, now.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 6)),
        end: now,
      ),
      builder: (ctx, child) => Theme(data: Theme.of(ctx), child: child!),
    );
    if (picked == null) return;
    final days = picked.end.difference(picked.start).inDays;
    if (days > 90) {
      if (context.mounted) {
        AppToast.show(context, '最多查看 90 天');
      }
      return;
    }
    final from = _fmt(picked.start);
    final to = _fmt(picked.end);
    if (from.compareTo(to) > 0) return;
    notifier.setCustomRange(from, to);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
