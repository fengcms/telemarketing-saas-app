/// 通话记录「接听类型」筛选条
///
/// 设计文档 §4.4。
/// 接听类型横滚 Chip（全部/已接听/无人接听/拒接/空号/停机）。
library;

import 'package:flutter/material.dart';

/// 接听类型筛选项（code 为 null 表示「全部」）
const List<({String? code, String label})> _answerFilters = [
  (code: null, label: '全部'),
  (code: 'answered', label: '已接听'),
  (code: 'no_answer', label: '无人接听'),
  (code: 'rejected', label: '拒接'),
  (code: 'empty_number', label: '空号'),
  (code: 'suspended', label: '停机'),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _answerFilters.map((f) {
            final selected = f.code == selectedAnswerType;
            return _chip(
              label: f.label,
              selected: selected,
              onTap: () => onAnswerTypeChanged(f.code),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 自绘 Chip（规避零先例的 TDTag）
  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFF2F3FF)
                : const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(999),
            border: selected
                ? Border.all(color: const Color(0xFF0052D9), width: 1)
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected
                    ? const Color(0xFF0052D9)
                    : const Color(0xFF6B7A90),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
