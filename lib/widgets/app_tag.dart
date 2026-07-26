/// 方块标签（4px 圆角小标签）
///
/// 用于详情页状态/分类标签，区别于胶囊式的 TagChip。
///
/// ── 使用示例 ──
/// ```dart
/// AppTag(label: '跟进中', backgroundColor: Color(0xFFFDECEE), textColor: Color(0xFFD54941))
/// ```
library;

import 'package:flutter/material.dart';

/// 方块标签
class AppTag extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;

  /// 内边距（默认 6×2，与原样式一致）
  final EdgeInsetsGeometry padding;

  const AppTag({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: textColor ?? const Color(0xFF0052D9),
        ),
      ),
    );
  }
}
