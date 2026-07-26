/// 客户列表「等级」筛选条
///
/// 设计文档 §3.3（按 api.md 实际枚举 normal/important/vip/lost）。
/// 等级横滚胶囊筛选（全部/普通/重要/VIP/流失）。
/// 视觉与交互统一走公共组件 [AppFilterChips]，不再自绘分段控件。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/widgets/app_filter_chips.dart';

/// 等级筛选项（code 为 null 表示「全部」）
const List<FilterChipItem> levelFilters = [
  FilterChipItem(code: null, label: '全部'),
  FilterChipItem(code: 'normal', label: '普通'),
  FilterChipItem(code: 'important', label: '重要'),
  FilterChipItem(code: 'vip', label: 'VIP'),
  FilterChipItem(code: 'lost', label: '流失'),
];

/// 等级横滚筛选条
class CustomerFilterBar extends StatelessWidget {
  /// 当前选中的等级（null = 全部）
  final String? selectedLevel;

  /// 切换等级筛选
  final ValueChanged<String?> onLevelChanged;

  const CustomerFilterBar({
    super.key,
    required this.selectedLevel,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppFilterChips(
      items: levelFilters,
      selectedCode: selectedLevel,
      onChanged: onLevelChanged,
    );
  }
}
