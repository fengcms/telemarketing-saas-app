/// 统一 Toast 提示
///
/// 封装 [ScaffoldMessenger.showSnackBar]，样式跟随 M3 主题，
/// 替代 TDesign 的 [TDToast.showText]。
///
/// ── 使用示例 ──
/// ```dart
/// AppToast.show(context, '跟进记录已添加');
/// ```
library;

import 'package:flutter/material.dart';

/// 统一 Toast 提示工具类
abstract final class AppToast {
  AppToast._();

  /// 显示 SnackBar 提示
  ///
  /// [message] 提示文字；样式由主题 [SnackBarThemeData] 统一控制。
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
