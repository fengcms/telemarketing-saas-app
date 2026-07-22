/// 线索相关常量
///
/// 集中管理线索状态、颜色等映射关系，避免多份拷贝。
/// 引用方式：LeadConstants.statusLabels[code]
///           LeadConstants.statusColorStyle(code)
library;

import 'package:flutter/material.dart';

/// 线索常量
class LeadConstants {
  LeadConstants._();

  /// 状态码 → 中文显示名
  static const Map<String, String> statusLabels = {
    'pending': '待分配',
    'assigned': '待跟进',
    'following': '跟进中',
    'converted': '已转化',
    'invalid': '无效',
  };

  /// 获取状态的中文显示名，未知状态直接返回 code 本身
  static String labelOf(String code) => statusLabels[code] ?? code;

  /// 获取状态的中文显示名（带兜底）
  static String displayName(String? code) {
    if (code == null || code.isEmpty) return '--';
    return statusLabels[code] ?? code;
  }

  /// 获取状态标签的颜色样式 (背景色, 文字色, 显示名)
  static (Color, Color, String) statusColorStyle(String code) {
    final label = labelOf(code);
    switch (code) {
      case 'pending':
        return (
          const Color(0x1AE37318),
          const Color(0xFFE37318),
          label,
        );
      case 'assigned':
        return (
          const Color(0xFFD9E1FF),
          const Color(0xFF003CAB),
          label,
        );
      case 'following':
        return (
          const Color(0x1A0052D9),
          const Color(0xFF0052D9),
          label,
        );
      case 'converted':
        return (
          const Color(0xFF2BA471),
          const Color(0xFFFFFFFF),
          label,
        );
      case 'invalid':
        return (
          const Color(0x4DDCDCDC),
          const Color(0xFFA6A6A6),
          label,
        );
      default:
        return (
          const Color(0x1AE37318),
          const Color(0xFFE37318),
          code,
        );
    }
  }
}
