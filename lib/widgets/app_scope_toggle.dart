/// 作用域切换药丸
///
/// 用于「我的 / 团队」「我的 / 全部」这类二态（或多态）作用域切换。
/// 点击循环切换到下一个选项，避免引入下拉菜单，保持轻量一致。
/// 样式为白底半透明药丸，适配深色 AppBar 背景。
library;

import 'package:flutter/material.dart';

/// 单个作用域选项（value 用于状态存储，label 用于展示）
class ScopeOption {
  final String value;
  final String label;

  const ScopeOption(this.value, this.label);
}

/// 作用域切换药丸
class AppScopeToggle extends StatelessWidget {
  /// 可选项列表（按顺序循环切换）
  final List<ScopeOption> options;

  /// 当前选中的 value
  final String currentValue;

  /// 切换回调，回传新选中的 value
  final ValueChanged<String> onChanged;

  const AppScopeToggle({
    super.key,
    required this.options,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        options.firstWhere((o) => o.value == currentValue, orElse: () => options.first).label;
    return GestureDetector(
      onTap: () {
        final idx = options.indexWhere((o) => o.value == currentValue);
        final next = options[(idx + 1) % options.length];
        onChanged(next.value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.white),
        ),
      ),
    );
  }
}
