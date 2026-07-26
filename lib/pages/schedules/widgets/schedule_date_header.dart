/// 日期吸顶头部
///
/// 列表按日期分组的组头（今天 / 明天 / 后天 / 本周 / 更早）。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 日期吸顶头部
class ScheduleDateHeader extends StatelessWidget {
  /// 日期标题（今天 / 明天 / 本周 …）
  final String title;

  /// 点击回调（跳转滚动到对应组别，null 则不可点击）
  final VoidCallback? onTap;

  const ScheduleDateHeader({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: 40,
      decoration: BoxDecoration(
        color: BrandColors.surface,
        // 底部分割线：多个吸顶头堆叠时保持清晰分隔，避免糊成灰片
        border: const Border(
          bottom: BorderSide(color: BrandColors.line, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: BrandColors.textSecondary,
        ),
      ),
    );
    return onTap == null ? child : GestureDetector(onTap: onTap, child: child);
  }
}
