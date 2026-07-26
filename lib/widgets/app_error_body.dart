/// 统一错误/空态展示
///
/// 居中图标 + 标题(可选) + 错误文字 + 可选操作按钮。
///
/// ── 使用示例 ──
/// ```dart
/// AppErrorBody(
///   icon: Icons.info,
///   message: '该线索已删除或不存在',
///   actionText: '返回列表',
///   onAction: () => Navigator.of(context).pop(),
/// )
///
/// // 带标题的两级文案（如列表加载失败）
/// AppErrorBody(
///   icon: Icons.error_outline,
///   title: '加载失败',
///   message: '网络异常，请稍后重试',
///   actionText: '重新加载',
///   onAction: () {},
/// )
/// ```
library;

import 'package:flutter/material.dart';
import '../theme/color_scheme.dart';

/// 统一错误/空态组件
class AppErrorBody extends StatelessWidget {
  final IconData icon;

  /// 图标尺寸（默认 64，与原样式一致）
  final double iconSize;

  /// 图标颜色（默认 [BrandColors.textSecondary]）
  final Color? iconColor;

  /// 可选标题（16 / w500 / textPrimary），位于图标与正文之间
  final String? title;

  final String message;

  /// 正文颜色（默认 [BrandColors.textPrimary]）
  final Color? messageColor;

  final String? actionText;
  final VoidCallback? onAction;

  const AppErrorBody({
    super.key,
    required this.icon,
    this.iconSize = 64,
    this.iconColor,
    this.title,
    required this.message,
    this.messageColor,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: iconColor ?? BrandColors.textSecondary),
          const SizedBox(height: 16),
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: BrandColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: messageColor ?? BrandColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onAction,
              child: Text(actionText!),
            ),
          ],
        ],
      ),
    );
  }
}
