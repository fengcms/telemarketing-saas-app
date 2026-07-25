/// 带字数指示器的多行文本域组件
///
/// 封装 [TextField]（多行模式），字数指示器浮在文本框内部右下角，
/// 当前字数 ≥ 最大字数时计数器变红。
///
/// 可选传入 [quickNotes] 快捷备注数组，在文本域下方以 [TagChipRow] 多行换行展示，
/// 点击后自动追加到文本域末尾（以空格分隔）。
///
/// 样式跟随 M3 主题（白底灰边框圆角 + 聚焦蓝色边框）。
///
/// ── 布局结构 ──
/// ┌─────────────────────────────────┐
/// │                                 │
/// │  这里是输入内容...               │
/// │                                 │
/// │                      42/200     │  ← 浮在边框内右下角
/// └─────────────────────────────────┘
/// [标签1] [标签2] [标签3] ...         ← 仅 quickNotes 不为空时多行换行
///
/// ── 使用示例 ──
/// ```dart
/// // 纯文本域（200 字）
/// AppTextarea(
///   controller: _ctrl,
///   hintText: '补充说明...',
/// )
///
/// // 文本域 + 快捷备注（跟进记录风格）
/// AppTextarea(
///   controller: _ctrl,
///   hintText: '请输入跟进内容...',
///   maxLength: 100,
///   maxLines: 4,
///   quickNotes: ['有意向', '需跟进', '已加微信'],
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/color_scheme.dart';
import 'tag_chip.dart';

/// 带字数指示器的多行文本域，可选快捷备注
class AppTextarea extends StatelessWidget {
  /// 输入控制器
  final TextEditingController controller;

  /// 占位提示文字
  final String hintText;

  /// 最大字数限制，默认 200
  final int maxLength;

  /// 最小显示行数，默认 2
  final int minLines;

  /// 最大显示行数，默认 5
  final int maxLines;

  /// 内容变化回调
  final ValueChanged<String>? onChanged;

  /// 快捷备注标签数组，传入后在文本域下方以 TagChipRow 多行换行展示
  final List<String>? quickNotes;

  const AppTextarea({
    super.key,
    required this.controller,
    required this.hintText,
    this.maxLength = 200,
    this.minLines = 2,
    this.maxLines = 5,
    this.onChanged,
    this.quickNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField(),
        if (quickNotes != null && quickNotes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildQuickNotes(),
        ],
      ],
    );
  }

  /// 文本域主体（Stack 内嵌字数指示器）
  Widget _buildTextField() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          inputFormatters: [
            LengthLimitingTextInputFormatter(maxLength),
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            // 隐藏默认计数器，用自定义的 Stack 浮层替代
            counterText: '',
          ),
        ),
        // 字数指示器浮在边框内右下角
        Positioned(
          right: 12,
          bottom: 8,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final len = controller.text.length;
              final isOver = len >= maxLength;
              return Text(
                '$len/$maxLength',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  color: isOver
                      ? BrandColors.error
                      : BrandColors.textSecondary,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 快捷备注标签行（多行换行模式）
  Widget _buildQuickNotes() {
    return TagChipRow(
      scrollable: false,
      chips: quickNotes!
          .map((note) => TagChipData(
                label: note,
                selected: false,
                onTap: () {
                  final text = controller.text;
                  controller.text =
                      text.isEmpty ? note : '$text $note';
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                  onChanged?.call(controller.text);
                },
              ))
          .toList(),
    );
  }
}
