/// 逾期吸顶头部
///
/// 逾期日程组置于列表最上方，红色"已逾期(N)"吸顶提示。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 逾期吸顶头部
class ScheduleOverdueHeader extends StatelessWidget {
  /// 逾期数量
  final int count;

  /// 点击回调（跳转滚动到对应组别，null 则不可点击）
  final VoidCallback? onTap;

  const ScheduleOverdueHeader({super.key, required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: 40,
      decoration: BoxDecoration(
        color: BrandColors.surface,
        // 底部分割线：多个吸顶头堆叠时保持清晰分隔
        border: const Border(
          bottom: BorderSide(color: BrandColors.line, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: BrandColors.error),
          const SizedBox(width: 6),
          Text(
            '已逾期 ($count)',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: BrandColors.error,
            ),
          ),
        ],
      ),
    );
    return onTap == null ? child : GestureDetector(onTap: onTap, child: child);
  }
}
