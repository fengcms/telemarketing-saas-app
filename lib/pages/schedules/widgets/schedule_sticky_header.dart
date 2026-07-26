/// 日程分组吸顶头部（合并日期头 / 逾期头）
///
/// 列表按语义桶分组（已逾期 / 今天 / 明天 / 本周 …）的组头，灰底 + 0.5px 底线。
/// 普通日期头只传 [title]；逾期头传 [icon] + [iconColor] 并自定义 [title]
/// （如「已逾期 (3)」）。两态合并为一个组件，消除重复实现。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 日程分组吸顶头部
class ScheduleStickyHeader extends StatelessWidget {
  /// 标题文字（普通头：今天 / 明天 / 本周 …；逾期头：已逾期 (N)）
  final String title;

  /// 可选前置图标（逾期头用 [Icons.error_outline]）
  final IconData? icon;

  /// 图标与文字颜色（逾期头用 [BrandColors.error]），默认取 [iconColor] 或 error
  final Color? iconColor;

  /// 点击回调（平滑滚动到对应分组，null 则不可点击）
  final VoidCallback? onTap;

  const ScheduleStickyHeader({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final contentColor = iconColor ?? BrandColors.error;
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
      child: icon == null
          ? Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: BrandColors.textSecondary,
              ),
            )
          : Row(
              children: [
                Icon(icon, size: 16, color: contentColor),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: contentColor,
                  ),
                ),
              ],
            ),
    );
    return onTap == null ? child : GestureDetector(onTap: onTap, child: child);
  }
}
