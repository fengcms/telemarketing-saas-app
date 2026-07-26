/// 团队统计 - 吸顶日期范围选择器
///
/// 今日 / 本周 / 本月 / 自定义（≤90 天，Material 日期范围选择器）。
/// 选择自定义时调用 [showDateRangePicker]，拦截 >90 天。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/providers/team_stats_provider.dart';
import 'package:telemarketing_app/widgets/app_toast.dart';
import 'package:telemarketing_app/widgets/app_filter_chips.dart';

/// 吸顶日期范围选择条
class DateRangeSelector extends ConsumerWidget {
  const DateRangeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(teamStatsProvider);
    final notifier = ref.read(teamStatsProvider.notifier);
    return AppFilterChips(
      items: const [
        FilterChipItem(code: 'today', label: '今日'),
        FilterChipItem(code: 'thisWeek', label: '本周'),
        FilterChipItem(code: 'thisMonth', label: '本月'),
        FilterChipItem(code: 'custom', label: '自定义'),
      ],
      selectedCode: _codeOf(s.rangeKind),
      onChanged: (code) {
        if (code == null) return;
        if (code == 'today') {
          notifier.setRangeToday();
        } else if (code == 'thisWeek') {
          notifier.setRangeThisWeek();
        } else if (code == 'thisMonth') {
          notifier.setRangeThisMonth();
        } else if (code == 'custom') {
          _pickCustom(context, notifier);
        }
      },
    );
  }

  String _codeOf(DateRangeKind kind) {
    return switch (kind) {
      DateRangeKind.today => 'today',
      DateRangeKind.thisWeek => 'thisWeek',
      DateRangeKind.thisMonth => 'thisMonth',
      DateRangeKind.custom => 'custom',
    };
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
