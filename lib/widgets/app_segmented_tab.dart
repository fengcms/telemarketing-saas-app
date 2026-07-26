/// 带计数徽标的分段 Tab 栏
///
/// 用于「待办/已完成」这类带计数的双（多）态切换，封装下划线指示器 +
/// 选中蓝字 + 计数胶囊逻辑。与 [LeadsTopBar]（胶囊 Tab）、[AppFilterChips]
/// （单选药丸）区分：本组件强调「计数 + 下划线」语义。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 单个分段项
class SegmentedTabItem {
  /// 唯一标识（如 'pending' / 'completed'）
  final String key;

  /// 展示文案
  final String label;

  /// 计数徽标，0 则不显示
  final int count;

  const SegmentedTabItem({
    required this.key,
    required this.label,
    this.count = 0,
  });
}

/// 带计数徽标的分段 Tab 栏
class AppSegmentedTab extends StatelessWidget {
  /// 分段项列表
  final List<SegmentedTabItem> tabs;

  /// 当前选中项的 key
  final String activeKey;

  /// 切换回调，回传选中项的 key
  final ValueChanged<String> onChanged;

  /// 栏高，默认 48
  final double height;

  const AppSegmentedTab({
    super.key,
    required this.tabs,
    required this.activeKey,
    required this.onChanged,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: height,
      child: Row(
        children: tabs.map((t) {
          final active = t.key == activeKey;
          return Expanded(
            child: _TabItemView(
              label: t.label,
              count: t.count,
              active: active,
              onTap: () => onChanged(t.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TabItemView extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _TabItemView({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  color: active ? BrandColors.primary : BrandColors.textSecondary,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: active ? BrandColors.primary : BrandColors.textSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: 28,
            color: active ? BrandColors.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
