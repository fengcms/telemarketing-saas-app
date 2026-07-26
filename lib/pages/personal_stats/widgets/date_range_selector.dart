/// 个人统计 - 吸顶日期范围选择器
///
/// 今日 / 本周 / 本月 / 自定义（设计允许超 1 年，仅拦截起 > 止）。
/// 统一使用公共组件 [AppFilterChips]，符合 §3 硬规则（禁止各页自绘 chip）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/providers/personal_stats_provider.dart';
import 'package:telemarketing_app/widgets/app_filter_chips.dart';

/// 吸顶日期范围选择条
class DateRangeSelector extends ConsumerWidget {
  const DateRangeSelector({super.key});

  /// DateRangeKind → AppFilterChips 的 code 映射
  static const Map<DateRangeKind, String> _kindToCode = {
    DateRangeKind.today: 'today',
    DateRangeKind.thisWeek: 'thisWeek',
    DateRangeKind.thisMonth: 'thisMonth',
    DateRangeKind.custom: 'custom',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(personalStatsProvider);
    final notifier = ref.read(personalStatsProvider.notifier);
    return AppFilterChips(
      items: const [
        FilterChipItem(code: 'today', label: '今日'),
        FilterChipItem(code: 'thisWeek', label: '本周'),
        FilterChipItem(code: 'thisMonth', label: '本月'),
        FilterChipItem(code: 'custom', label: '自定义'),
      ],
      selectedCode: _kindToCode[s.rangeKind],
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

  Future<void> _pickCustom(
    BuildContext context,
    PersonalStatsNotifier notifier,
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
    final from = _fmt(picked.start);
    final to = _fmt(picked.end);
    if (from.compareTo(to) > 0) return;
    notifier.setCustomRange(from, to);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
