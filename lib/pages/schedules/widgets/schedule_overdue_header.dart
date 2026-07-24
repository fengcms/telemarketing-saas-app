/// 逾期吸顶头部
///
/// 逾期日程组置于列表最上方，红色"已逾期(N)"吸顶提示。
library;

import 'package:flutter/material.dart';

/// 逾期吸顶头部
class ScheduleOverdueHeader extends StatelessWidget {
  /// 逾期数量
  final int count;

  /// 点击回调（跳转滚动到对应组别，null 则不可点击）
  final VoidCallback? onTap;

  const ScheduleOverdueHeader(
      {super.key, required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        // 底部分割线：多个吸顶头堆叠时保持清晰分隔
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 16, color: Color(0xFFD54941)),
          const SizedBox(width: 6),
          Text(
            '已逾期 ($count)',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD54941),
            ),
          ),
        ],
      ),
    );
    return onTap == null
        ? child
        : GestureDetector(onTap: onTap, child: child);
  }
}
