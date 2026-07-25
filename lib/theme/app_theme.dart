/// [ThemeData] 主入口
///
/// 汇聚颜色、文字、组件三层的自定义配置，生成项目统一的 M3 主题。
/// 所有业务代码应通过此入口获取主题，而非在页面中硬编码色值/样式。
library;

import 'package:flutter/material.dart';
import 'color_scheme.dart';
import 'text_theme.dart';
import 'component_tokens.dart';

/// 品牌 Material 3 亮色主题
///
/// ```dart
/// MaterialApp(
///   theme: buildBrandTheme(),
/// )
/// ```
ThemeData buildBrandTheme() {
  final theme = ThemeData(
    useMaterial3: true,
    colorScheme: brandColorScheme,
    textTheme: brandTextTheme,

    // 全局基础属性
    scaffoldBackgroundColor: BrandColors.surface,
    primaryColor: BrandColors.primary,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,

    // 视觉密度（TDesign 风格：紧凑）
    visualDensity: VisualDensity.compact,

    // 分割线颜色
    dividerColor: BrandColors.border,

    // 禁用态全局透明度（配合 WidgetStateProperty 使用）
    disabledColor: BrandColors.textDisabled,
  );

  // 合并各组件主题覆写
  return componentTokens.mergeInto(theme);
}
