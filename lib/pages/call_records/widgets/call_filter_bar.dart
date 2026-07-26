/// 通话记录「接听类型」筛选条
///
/// 设计文档 §4.4。
/// 接听类型横滚胶囊筛选（全部/已接听/无人接听/拒接/空号/停机）。
/// 视觉与交互统一走公共组件 [AppFilterChips]，不再自绘。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/widgets/app_filter_chips.dart';

/// 接听类型筛选项（code 为 null 表示「全部」）
const List<FilterChipItem> answerFilters = [
  FilterChipItem(code: null, label: '全部'),
  FilterChipItem(code: 'answered', label: '已接听'),
  FilterChipItem(code: 'no_answer', label: '无人接听'),
  FilterChipItem(code: 'rejected', label: '拒接'),
  FilterChipItem(code: 'empty_number', label: '空号'),
  FilterChipItem(code: 'suspended', label: '停机'),
];

/// 接听类型横滚筛选条
class CallFilterBar extends StatelessWidget {
  /// 当前选中的接听类型（null = 全部）
  final String? selectedAnswerType;

  /// 切换接听类型筛选
  final ValueChanged<String?> onAnswerTypeChanged;

  const CallFilterBar({
    super.key,
    required this.selectedAnswerType,
    required this.onAnswerTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppFilterChips(
      items: answerFilters,
      selectedCode: selectedAnswerType,
      onChanged: onAnswerTypeChanged,
    );
  }
}
