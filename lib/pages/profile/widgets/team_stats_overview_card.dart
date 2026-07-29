/// 个人中心 - 团队业绩概览卡片（TM/TA 视角）
///
/// 4 列等分：今日跟进 / 今日接通 / 今日转化 / 今日待办。
/// 每列：数字(20px Bold 品牌色) + 环比小标(11px 绿↗/红↘/灰—) + 标签(12px 灰)。
/// 白色圆角卡片，列间以淡灰色细线分隔；风格对齐 [ProfileStatsCard]。
/// 数据来自 [ManagerTodayStats]（GET /api/tenant/stats/today 实时 COUNT）。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/models/manager_today_stats.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 团队业绩概览卡片
///
/// [stats] 团队当日统计（[ManagerTodayStats]）。
class TeamStatsOverviewCard extends StatelessWidget {
  final ManagerTodayStats stats;

  const TeamStatsOverviewCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _column(
            '今日跟进',
            stats.todayFollowup,
            stats.compareYesterday.followupDiff,
          ),
          _divider(),
          _column(
            '今日接通',
            stats.todayAnswered,
            stats.compareYesterday.answeredDiff,
          ),
          _divider(),
          _column(
            '今日转化',
            stats.todayConverted,
            stats.compareYesterday.convertedDiff,
          ),
          _divider(),
          _column('今日待办', stats.todayPending, null),
        ],
      ),
    );
  }

  /// 列间淡灰细线（固定 28px 高，上下留间隙）
  ///
  /// 同 [ProfileStatsCard] 处理：VerticalDivider 在 Row+Expanded 混排时
  /// 交叉轴高度约束不定，常渲染成 0 高，故用手写固定高 Container 保证显示。
  Widget _divider() => SizedBox(
        height: 44,
        child: Container(width: 1, color: BrandColors.border),
      );

  /// 单列指标（数字 + 环比小标 + 标签）
  ///
  /// [diff] 为 null（如待办列接口未返回对应差值）时不显示环比小标。
  Widget _column(String label, int value, int? diff) {
    return Expanded(
      child: Column(
        children: [
          Text(
            _format(value),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: BrandColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          _compareBadge(diff),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: BrandColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 环比小标：diff>0 绿↗+N；diff<0 红↘N；diff==0 灰—；null 不显示
  Widget _compareBadge(int? diff) {
    if (diff == null) {
      return const SizedBox(height: 14); // 占位保持列对齐
    }
    final color = diff > 0
        ? BrandColors.success
        : diff < 0
            ? BrandColors.error
            : BrandColors.textSecondary;
    final arrow = diff > 0 ? '↗' : diff < 0 ? '↘' : '—';
    final text = diff > 0 ? '$arrow +$diff' : diff < 0 ? '$arrow ${diff.abs()}' : arrow;
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }

  /// 数值格式化：超过 9999 显示 "9999+"，避免 4 列拥挤
  String _format(int n) => n > 9999 ? '9999+' : '$n';
}
