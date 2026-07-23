/// 线索列表筛选弹窗组件
library;

import 'package:flutter/material.dart';

/// 筛选选项 chip（已废弃，请使用 TagChip）
///
/// 保留作为 SelectChip 引用兼容层。
/// 实际逻辑委托给 TagChip。
@Deprecated('Use TagChip from widgets/tag_chip.dart instead')
class SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0052D9) : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : const Color(0xFF181818),
          ),
        ),
      ),
    );
  }
}
