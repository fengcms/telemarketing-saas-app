/// 团队日程视图头部（仅 scope==team 显示）
///
/// 由上至下：
/// 1. 统计摘要条：今日待办 N 条 · 逾期 M 条
/// 2. 员工筛选按钮：全部成员 / ● 姓名（带归属人颜色圆点）
///
/// 数值与选中态由列表页统一计算后下发（头部保持纯展示，
/// 便于复用与测试）。成员选择弹窗逻辑在列表页（持有 Riverpod）。

library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 团队日程头部
class TeamScheduleHeader extends StatelessWidget {
  /// 今日待办数（严格今日窗口，与首页/home-summary 同源）
  final int todayPending;

  /// 已逾期数
  final int overdue;

  /// 员工筛选当前选中文案（"全部成员" 或成员姓名）
  final String ownerLabel;

  /// 选中成员颜色圆点（null 表示"全部成员"，用灰色）
  final Color? ownerColor;

  /// 点击员工筛选按钮回调（列表页弹出成员 sheet）
  final VoidCallback onPickOwner;

  const TeamScheduleHeader({
    super.key,
    required this.todayPending,
    required this.overdue,
    required this.ownerLabel,
    this.ownerColor,
    required this.onPickOwner,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryBar(todayPending: todayPending, overdue: overdue),
        _OwnerFilterButton(
          label: ownerLabel,
          color: ownerColor,
          onTap: onPickOwner,
        ),
      ],
    );
  }
}

/// 统计摘要条
class _SummaryBar extends StatelessWidget {
  final int todayPending;
  final int overdue;

  const _SummaryBar({
    required this.todayPending,
    required this.overdue,
  });

  @override
  Widget build(BuildContext context) {
    final overdueZero = overdue <= 0;
    return Container(
      height: 48,
      color: BrandColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.event_note, size: 16, color: BrandColors.textSecondary),
          const SizedBox(width: 6),
          Text('今日待办 ', style: _labelStyle),
          Text('$todayPending', style: _todayNumStyle),
          Text(' 条', style: _labelStyle),
          const Spacer(),
          Icon(
            overdueZero ? Icons.check_circle_outline : Icons.warning_amber_outlined,
            size: 16,
            color: overdueZero ? BrandColors.textSecondary : BrandColors.error,
          ),
          const SizedBox(width: 6),
          Text('逾期 ', style: _labelStyle),
          Text('$overdue', style: overdueZero ? _zeroNumStyle : _overdueNumStyle),
          Text(' 条', style: _labelStyle),
        ],
      ),
    );
  }
}

/// 员工筛选按钮
class _OwnerFilterButton extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _OwnerFilterButton({
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.person_outline, size: 16, color: BrandColors.textSecondary),
            const SizedBox(width: 6),
            Text('员工：', style: _labelStyle),
            if (color != null)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            Text(label, style: const TextStyle(fontSize: 14, color: BrandColors.textPrimary)),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, size: 20, color: BrandColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

const _labelStyle = TextStyle(fontSize: 14, color: BrandColors.textSecondary);
const _todayNumStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.bold,
  color: BrandColors.primary,
);
const _overdueNumStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.bold,
  color: BrandColors.error,
);
const _zeroNumStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.bold,
  color: BrandColors.textSecondary,
);
