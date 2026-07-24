/// 逾期吸顶头部
///
/// 逾期日程组置于列表最上方，红色"已逾期(N)"吸顶提示。
library;

import 'package:flutter/material.dart';

/// 逾期吸顶头部
class ScheduleOverdueHeader extends StatelessWidget {
  /// 逾期数量
  final int count;

  const ScheduleOverdueHeader({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: const Color(0xFFF3F3F3),
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
  }
}
