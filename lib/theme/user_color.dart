/// 归属人颜色映射工具
///
/// 8 色预设池，通过 [userId] 的 hashCode 取模分配，确保同一用户跨页面颜色一致。
/// 用于团队线索池、团队日程等需要按归属人标记颜色的场景。
library;

import 'package:flutter/material.dart';

/// 归属人颜色池
///
/// 8 种高可区分度颜色，覆盖常见团队成员数量（≤8 人各一色，>8 人循环取色）。
const List<Color> _colorPool = [
  Color(0xFFE53935), // 红
  Color(0xFF1E88E5), // 蓝
  Color(0xFF43A047), // 绿
  Color(0xFFFB8C00), // 橙
  Color(0xFF8E24AA), // 紫
  Color(0xFF00ACC1), // 青
  Color(0xFFD81B60), // 粉
  Color(0xFF6D4C41), // 棕
];

/// 根据 [userId] 获取归属人颜色
///
/// 算法：`colorPool[hashCode(userId) % colorPool.size]`
/// [userId] 为 null 时返回灰色。
Color userColor(String? userId) {
  if (userId == null || userId.isEmpty) return const Color(0xFF9E9E9E);
  return _colorPool[userId.hashCode % _colorPool.length];
}
