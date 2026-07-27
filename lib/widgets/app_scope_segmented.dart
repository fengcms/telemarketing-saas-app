/// 作用域切换胶囊（白底，蓝底背景适配）
///
/// 用于「我的 / 团队」「我的线索 / 公海线索」这类二态（或多态）作用域切换。
/// 并排白色胶囊：选中白底蓝字、未选中透明白底白字，适配深色（品牌蓝）顶栏背景。
/// 形态对齐线索列表页 `LeadsTopBar` 的左侧 Tab 切换。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 单个作用域选项（value 用于状态存储，label 用于展示）
class ScopeOption {
  /// 唯一标识（如 'mine' / 'team'）
  final String value;

  /// 展示文案
  final String label;

  const ScopeOption(this.value, this.label);
}

/// 作用域切换胶囊组（白底，蓝底适配）
class AppScopeSegmented extends StatelessWidget {
  /// 可选项（按顺序并排）
  final List<ScopeOption> options;

  /// 当前选中 value
  final String currentValue;

  /// 切换回调，回传选中项的 value
  final ValueChanged<String> onChanged;

  const AppScopeSegmented({
    super.key,
    required this.options,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((o) {
        final selected = o.value == currentValue;
        return _Pill(
          label: o.label,
          selected: selected,
          onTap: () => onChanged(o.value),
        );
      }).toList(),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white24,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: selected ? BrandColors.primary : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
