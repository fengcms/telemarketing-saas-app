/// 日期吸顶头部
///
/// 列表按日期分组的组头（今天 / 明天 / 后天 / 本周 / 更早）。
library;

import 'package:flutter/material.dart';

/// 日期吸顶头部
class ScheduleDateHeader extends StatelessWidget {
  /// 日期标题（今天 / 明天 / 本周 …）
  final String title;

  const ScheduleDateHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: const Color(0xFFF3F3F3),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7A90),
        ),
      ),
    );
  }
}
