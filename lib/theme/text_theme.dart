/// Material 3 文字主题配置
///
/// 以 M3 默认 Typography 为基底，微调字号与字重以贴近项目既有设计规范。
/// 无自定义字体，使用系统默认字体。
library;

import 'package:flutter/material.dart';
import 'color_scheme.dart';

/// 品牌字体常量
abstract final class BrandTextStyle {
  BrandTextStyle._();

  // ── 常用 FontWeight ──
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // ── 字号映射 ──
  static const double sizeXs = 11;
  static const double sizeSm = 12;
  static const double sizeBase = 14;
  static const double sizeMd = 16;
  static const double sizeLg = 18;
  static const double sizeXl = 20;
  static const double size2xl = 24;
}

/// 品牌文字主题
///
/// 覆盖 M3 [TextTheme] 中项目用到的样式：
/// - titleLarge  → 页面标题（20px Medium）
/// - titleMedium → 板块标题（16px Medium）
/// - bodyLarge   → 正文（14px Regular）
/// - bodyMedium  → 辅助文字（12px Regular）
/// - labelLarge  → 按钮/动作文字（14px Medium）
const TextTheme brandTextTheme = TextTheme(
  // ── 头部 ──
  headlineLarge: TextStyle(
    fontSize: BrandTextStyle.size2xl,
    fontWeight: BrandTextStyle.semiBold,
    color: BrandColors.textPrimary,
  ),
  headlineMedium: TextStyle(
    fontSize: BrandTextStyle.sizeXl,
    fontWeight: BrandTextStyle.semiBold,
    color: BrandColors.textPrimary,
  ),

  // ── 标题 ──
  titleLarge: TextStyle(
    fontSize: BrandTextStyle.sizeXl,
    fontWeight: BrandTextStyle.medium,
    color: BrandColors.textPrimary,
  ),
  titleMedium: TextStyle(
    fontSize: BrandTextStyle.sizeMd,
    fontWeight: BrandTextStyle.medium,
    color: BrandColors.textPrimary,
  ),
  titleSmall: TextStyle(
    fontSize: BrandTextStyle.sizeBase,
    fontWeight: BrandTextStyle.medium,
    color: BrandColors.textPrimary,
  ),

  // ── 正文 ──
  bodyLarge: TextStyle(
    fontSize: BrandTextStyle.sizeBase,
    fontWeight: BrandTextStyle.regular,
    color: BrandColors.textPrimary,
  ),
  bodyMedium: TextStyle(
    fontSize: BrandTextStyle.sizeSm,
    fontWeight: BrandTextStyle.regular,
    color: BrandColors.textSecondary,
  ),
  bodySmall: TextStyle(
    fontSize: BrandTextStyle.sizeXs,
    fontWeight: BrandTextStyle.regular,
    color: BrandColors.textSecondary,
  ),

  // ── 标签/按钮 ──
  labelLarge: TextStyle(
    fontSize: BrandTextStyle.sizeBase,
    fontWeight: BrandTextStyle.medium,
    color: BrandColors.textPrimary,
  ),
  labelMedium: TextStyle(
    fontSize: BrandTextStyle.sizeSm,
    fontWeight: BrandTextStyle.medium,
    color: BrandColors.textSecondary,
  ),
  labelSmall: TextStyle(
    fontSize: BrandTextStyle.sizeXs,
    fontWeight: BrandTextStyle.medium,
    color: BrandColors.textSecondary,
  ),
);
