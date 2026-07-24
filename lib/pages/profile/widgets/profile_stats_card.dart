/// 个人中心 - 我的业绩概览卡片
///
/// 4 列等分：我的线索 / 今日跟进 / 今日接通 / 今日待办。
/// 白色圆角卡片，列间以淡灰色细线（上下留间隙）分隔；
/// 数字 brand-7 20px Bold，标签 gray-6 12px；整卡可点击跳转个人统计（本轮占位）。
library;

import 'package:flutter/material.dart';

/// 个人中心业绩概览卡片
///
/// [leadsTotal] 我的线索总数（stats/mine.myLeadsTotal）
/// [followupCount] 今日跟进数（stats/mine.myToday.followupCount）
/// [answeredCount] 今日接通数（stats/mine.myToday.answeredCount）
/// [dueToday] 今日待办数（schedules/stats/mine 共享 provider）
/// [onTap] 点击整卡回调（跳个人统计占位页）
class ProfileStatsCard extends StatelessWidget {
  final int leadsTotal;
  final int followupCount;
  final int answeredCount;
  final int dueToday;
  final VoidCallback? onTap;

  const ProfileStatsCard({
    super.key,
    required this.leadsTotal,
    required this.followupCount,
    required this.answeredCount,
    required this.dueToday,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
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
            _column('我的线索', leadsTotal),
            _divider(),
            _column('今日跟进', followupCount),
            _divider(),
            _column('今日接通', answeredCount),
            _divider(),
            _column('今日待办', dueToday),
          ],
        ),
      ),
    );
  }

  /// 列间淡灰细线（固定 28px 高，上下留间隙，不顶天立地）
  ///
  /// 不用 VerticalDivider：它在 Row + Expanded 混排时交叉轴高度约束不定，
  /// 常渲染成 0 高不可见，故用手写固定高 Container 保证必定显示。
  Widget _divider() => SizedBox(
        height: 28,
        child: Container(width: 1, color: const Color(0xFFE7E7E7)),
      );

  /// 单列指标（数字 + 标签）
  Widget _column(String label, int value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            _format(value),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0052D9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFA6A6A6),
            ),
          ),
        ],
      ),
    );
  }

  /// 数值格式化：超过 9999 显示 "9999+"，避免 4 列拥挤
  String _format(int n) => n > 9999 ? '9999+' : '$n';
}
