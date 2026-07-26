/// 统一错误/空态展示
///
/// 居中图标 + 错误文字 + 可选操作按钮。
///
/// ── 使用示例 ──
/// ```dart
/// AppErrorBody(
///   icon: Icons.info,
///   message: '该线索已删除或不存在',
///   actionText: '返回列表',
///   onAction: () => Navigator.of(context).pop(),
/// )
/// ```
library;

import 'package:flutter/material.dart';
import '../theme/color_scheme.dart';

/// 统一错误/空态组件
class AppErrorBody extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const AppErrorBody({
    super.key,
    required this.icon,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: BrandColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: BrandColors.textPrimary,
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
