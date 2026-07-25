/// 统一确认/提示弹窗
///
/// 封装 [showDialog] + [AlertDialog] 重复样板，提供静态方法直接调用。
/// 样式由 M3 主题的 [DialogTheme] 统一控制（圆角/标题/内容字体）。
///
/// ── 使用示例 ──
/// ```dart
/// // 确认弹窗
/// final confirmed = await AppDialog.confirm(
///   context: context,
///   title: '确认删除',
///   content: '确定要删除这条跟进记录吗？',
///   confirmText: '删除',
///   confirmColor: Colors.red,
///   onConfirm: () => _deleteRecord(id),
/// );
///
/// // 提示弹窗
/// await AppDialog.alert(
///   context: context,
///   title: '密码修改成功',
///   content: '请使用新密码重新登录。',
/// );
///
/// // 带额外操作的确认弹窗
/// final confirmed = await AppDialog.confirm(
///   context: context,
///   title: '确认退出',
///   content: '确定要退出登录吗？',
///   cancelText: '再想想',
///   confirmText: '退出',
///   onConfirm: () => _logout(),
/// );
/// ```
///
/// ── 返回值 ──
/// - `true` 用户点了确认
/// - `false` 或 `null` 用户点了取消/关闭
library;

import 'package:flutter/material.dart';

/// 统一弹窗
abstract final class AppDialog {
  AppDialog._();

  /// 确认弹窗
  ///
  /// 显示「取消 + 确认」两个按钮，用户点击确认后执行 [onConfirm]。
  /// 返回 `true` 表示确认，否则返回 `false`。
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String content,
    String cancelText = '取消',
    String confirmText = '确认',
    Color? confirmColor,
    required VoidCallback onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              onConfirm();
            },
            style: confirmColor != null
                ? FilledButton.styleFrom(backgroundColor: confirmColor)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// 提示弹窗
  ///
  /// 只有一个「知道了」按钮，用于信息提示场景。
  /// 返回 `true`。
  static Future<bool?> alert({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = '知道了',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
