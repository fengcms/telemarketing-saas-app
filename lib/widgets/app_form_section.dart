/// 表单区块组件
///
/// 用于表单页面中「标签 + 内容」的标准区块布局，
/// 统一标签样式、必填标记、间距，避免每个表单页面重复编写。
///
/// 样式参考：线索详情「新增跟进记录」抽屉的跟进内容区块。
///
/// ── 布局结构 ──
/// Column(crossAxisAlignment: start)
///   └── Row
///       ├── 标签文字（14px, textPrimary）
///       └── * 必填标记（红色 error, 仅 required=true 时显示）
///   └── SizedBox(height: 8)  ← 标签与内容的间距
///   └── child
///
/// ── 使用示例 ──
/// ```dart
/// // 普通区块
/// AppFormSection(
///   label: '备注',
///   child: TextField(decoration: InputDecoration(hintText: '补充说明...')),
/// )
///
/// // 必填区块
/// AppFormSection(
///   label: '跟进内容',
///   required: true,
///   child: TextField(maxLines: 5, minLines: 2, ...),
/// )
///
/// // 含多个子元素的区块（文本域 + 快捷备注）
/// AppFormSection(
///   label: '跟进内容',
///   required: true,
///   child: Column(
///     crossAxisAlignment: CrossAxisAlignment.start,
///     children: [
///       TextField(...),                  // 文本域
///       SizedBox(height: 12),
///       Text('快捷备注', style: ...),    // 子标题
///       SizedBox(height: 8),
///       TagChipRow(chips: ...),         // 标签行
///     ],
///   ),
/// )
/// ```
library;

import 'package:flutter/material.dart';
import '../theme/color_scheme.dart';

/// 表单区块组件
///
/// 统一「标签 + 必填标记 + 间距 + 内容」的布局结构。
class AppFormSection extends StatelessWidget {
  /// 区块标签文字（14px, 深色）
  final String label;

  /// 是否必填（显示红色 \* 标记）
  final bool required;

  /// 区块内容
  final Widget child;

  /// 标签与内容之间的间距，默认 8px
  final double spacing;

  const AppFormSection({
    super.key,
    required this.label,
    this.required = false,
    required this.child,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: BrandColors.textPrimary,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  color: BrandColors.error,
                ),
              ),
          ],
        ),
        SizedBox(height: spacing),
        child,
      ],
    );
  }
}
