/// 日期吸顶头部
///
/// 列表按日期分组的组头（今天 / 明天 / 后天 / 本周 / 更早）。
library;

import 'package:flutter/material.dart';

/// 日期吸顶头部
class ScheduleDateHeader extends StatelessWidget {
  /// 日期标题（今天 / 明天 / 本周 …）
  final String title;

  /// 点击回调（跳转滚动到对应组别，null 则不可点击）
  final VoidCallback? onTap;

  const ScheduleDateHeader(
      {super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        // 底部分割线：多个吸顶头堆叠时保持清晰分隔，避免糊成灰片
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
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
    return onTap == null
        ? child
        : GestureDetector(onTap: onTap, child: child);
  }
}
