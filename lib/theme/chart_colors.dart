/// 图表配色（对齐品牌规范 + M3 深色自适应由 colorScheme 控制）
///
/// 颜色取品牌蓝系与状态语义色，集中管理便于环形图 / 折线图 / 漏斗统一调用。
library;

import 'package:flutter/material.dart';

/// 图表配色常量
class ChartColors {
  ChartColors._();

  /// 品牌蓝 brand-7
  static const Color brand = Color(0xFF0052D9);

  /// 品牌蓝浅 brand-6
  static const Color brandLight = Color(0xFF366EF4);

  /// 成功绿 success-7
  static const Color success = Color(0xFF2BA471);

  /// 成功绿深 success-7-deep（用于"已转化"，与"接通"success 区分）
  static const Color successDeep = Color(0xFF1F8A56);

  /// 警告橙 warning-7（公海呆滞高亮）
  static const Color warning = Color(0xFFE37318);

  /// 无效灰 gray-4
  static const Color invalid = Color(0xFFDCDCDC);

  /// 状态分布环形 5 色：公海 / 已分配 / 跟进中 / 已转化 / 无效
  static const List<Color> statusPalette = [
    brand, // 公海 pending
    brandLight, // 已分配 assigned
    success, // 跟进中 following
    successDeep, // 已转化 converted
    invalid, // 无效 invalid
  ];

  /// 折线图 3 系列配色
  static const Color trendFollowup = brandLight; // 跟进数
  static const Color trendAnswered = success; // 接通数
  static const Color trendConverted = successDeep; // 转化数
}
