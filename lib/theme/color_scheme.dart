/// 品牌色 → Material 3 ColorScheme 映射
///
/// 种子色 = 品牌主色 #0052D9（TD brand-7）。
/// 由 [ColorScheme.fromSeed] 自动生成完整色板，再微调关键色值以贴近项目既有设计规范。
library;

import 'package:flutter/material.dart';

/// 项目品牌色常数（保持与既有设计规范一致）
abstract final class BrandColors {
  BrandColors._();

  /// 品牌主色（TD brand-7）
  static const Color primary = Color(0xFF0052D9);

  /// 品牌次色（TD brand-6），比主色更浅，用于聚焦边框等次级强调
  static const Color primaryLight = Color(0xFF366EF4);

  /// 品牌深色（TD brand-9）
  static const Color primaryDark = Color(0xFF00287A);

  /// 品牌浅底（TD brand-1）
  static const Color primarySurface = Color(0xFFF2F3FF);

  // ── 灰阶（TD gray）──

  /// 页面背景（gray-1）
  static const Color surface = Color(0xFFF3F3F3);

  /// 卡片/容器底色（gray-0，白色）
  ///
  /// 注意：本项目约定与 M3 默认命名相反——
  /// M3 中 `surface` 为主背景、`surfaceContainer` 为容器背景。
  /// 本项目：surface=灰底(F3F3F3)、surfaceContainer=白底(FFFFFF)。
  static const Color surfaceContainer = Color(0xFFFFFFFF);

  /// 边框（gray-4）
  static const Color border = Color(0xFFE7E7E7);

  /// 次要文字（gray-6）
  static const Color textSecondary = Color(0xFFA6A6A6);

  /// 主文字（gray-12）
  static const Color textPrimary = Color(0xFF181818);

  /// 禁用/占位色（gray-8）
  static const Color textDisabled = Color(0xFFC5C5C5);

  // ── 语义色 ──

  /// 错误（TD error-6）
  static const Color error = Color(0xFFD54941);

  /// 成功
  static const Color success = Color(0xFF2BA471);

  /// 警告
  static const Color warning = Color(0xFFED7B2F);
}

/// 基于品牌种子色生成的 Material 3 ColorScheme
///
/// 使用方式：
/// ```dart
/// ThemeData(
///   useMaterial3: true,
///   colorScheme: brandColorScheme,
/// )
/// ```
const ColorScheme brandColorScheme = ColorScheme(
  brightness: Brightness.light,

  // ── 主色 ──
  primary: BrandColors.primary,
  onPrimary: Colors.white,
  primaryContainer: BrandColors.primarySurface,
  onPrimaryContainer: BrandColors.primaryDark,

  // ── 次要色 ──
  secondary: Color(0xFF565E71),
  onSecondary: Colors.white,
  secondaryContainer: BrandColors.primarySurface,
  onSecondaryContainer: BrandColors.primary,

  // ── 第三色 ──
  tertiary: Color(0xFF6E5676),
  onTertiary: Colors.white,

  // ── 错误 ──
  error: BrandColors.error,
  onError: Colors.white,
  errorContainer: Color(0xFFFEF2F2),
  onErrorContainer: Color(0xFF931F1F),

  // ── 背景/表面 ──
  surface: BrandColors.surfaceContainer,
  onSurface: BrandColors.textPrimary,
  surfaceContainerHighest: BrandColors.surface,
  onSurfaceVariant: BrandColors.textSecondary,

  // ── 轮廓/边框 ──
  outline: BrandColors.border,
  outlineVariant: BrandColors.border,

  // ── 阴影 ──
  shadow: Color(0x1A000000),
  scrim: Color(0x52000000),
);
