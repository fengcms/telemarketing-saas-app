/// 胶囊式选择标签组件
///
/// 用于行程快速选择、分类选择、筛选选项等场景。
/// 28px 高的胶囊形，选中态蓝底白字，未选中态灰底黑字。
library;

import 'package:flutter/material.dart';

/// 胶囊式选择标签数据模型
class TagChipData {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const TagChipData({
    required this.label,
    required this.selected,
    required this.onTap,
  });
}

/// 胶囊式选择标签行
///
/// [scrollable] 为 false 时使用 Wrap 自动换行（Mode 1），
/// 为 true 时使用 SingleChildScrollView + Row 横向滚动（Mode 2）。
class TagChipRow extends StatelessWidget {
  final bool scrollable;
  final List<TagChipData> chips;

  const TagChipRow({
    super.key,
    this.scrollable = false,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    final children = chips.map((c) => Padding(
      padding: EdgeInsets.only(right: scrollable ? 8 : 0),
      child: TagChip(
        label: c.label,
        selected: c.selected,
        onTap: c.onTap,
      ),
    )).toList();

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: children),
      );
    }

    // Wrap 模式：自动换行
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: children,
    );
  }
}

/// 胶囊式选择标签
class TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const TagChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0052D9) : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : const Color(0xFF181818),
            ),
          ),
        ),
      ),
    );
  }
}
