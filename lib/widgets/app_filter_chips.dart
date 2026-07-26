/// 统一横滚胶囊筛选条组件
///
/// 列表页搜索框下方的单选筛选条（接听类型、客户等级等）。
/// 与项目 M3 主题绑定，色值全部走 [BrandColors]，不硬编码。
///
/// ── 视觉规格 ──
/// 白色容器 → 横滚药丸 chip：
///   - 形状：全圆角 `BorderRadius.circular(999)`
///   - 高度 32，横向 padding 14，chip 间距 8
///   - 选中态：浅蓝底 `primarySurface`(`#F2F3FF`) + 1px 品牌蓝边 + 蓝字(加粗 w500)
///   - 未选中态：灰底 `surface`(`#F3F3F3`) + 副文字色 `textSecondary`(`#A6A6A6`)
///   - 点击带 M3 水波纹（[InkWell] + [Ink]）
///
/// ── 宽度自适应（关键）──
/// 容器默认 `width: double.infinity`，强制占满屏幕 100% 宽，
/// 避免选项较少时下方露出页面灰色背景。
/// 内部按可用宽度自适应布局：
///   - 选项能在一屏内放下 → [Row] 以 `spaceBetween` 沿行铺满，两侧不留白；
///   - 选项超出一屏（如接听类型 6 项）→ [SingleChildScrollView] 横向滚动。
///
/// ── 使用示例 ──
/// ```dart
/// AppFilterChips(
///   items: const [
///     FilterChipItem(code: null, label: '全部'),
///     FilterChipItem(code: 'vip', label: 'VIP'),
///   ],
///   selectedCode: _selected,
///   onChanged: (code) => _onChanged(code),
/// )
/// ```
library;

import 'package:flutter/material.dart';
import '../theme/color_scheme.dart';

/// 筛选条选项（[code] 为 `null` 表示「全部」）
class FilterChipItem {
  /// 选项编码（null = 全部）
  final String? code;

  /// 展示文案
  final String label;

  const FilterChipItem({this.code, required this.label});
}

/// 横滚胶囊筛选条（单选）
///
/// [items] 为筛选项列表，[selectedCode] 为当前选中项编码（null = 全部），
/// [onChanged] 在点击某选项时回调其 [FilterChipItem.code]。
class AppFilterChips extends StatelessWidget {
  /// 筛选项
  final List<FilterChipItem> items;

  /// 当前选中项的 code（null = 全部）
  final String? selectedCode;

  /// 切换筛选回调，传入被点击项的 code
  final ValueChanged<String?> onChanged;

  /// 横滚模式下 chip 之间的间距
  final double spacing;

  const AppFilterChips({
    super.key,
    required this.items,
    required this.selectedCode,
    required this.onChanged,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // 强制占满屏幕 100% 宽，避免选项少时容器收缩露出底色
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      // Material 提供水波纹绘制面（InkWell 需要 Material 祖先）
      child: Material(
        color: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final chips = items
                .map(
                  (item) => _chip(
                    label: item.label,
                    selected: item.code == selectedCode,
                    onTap: () => onChanged(item.code),
                  ),
                )
                .toList();

            // 选项能在一屏内放下 → Row 沿行铺满（spaceBetween 消除两侧留白）
            final totalChipsWidth = _measureChipsWidth(context);
            final totalWithSpacing =
                totalChipsWidth + spacing * (items.length - 1);
            if (items.isEmpty || totalWithSpacing <= constraints.maxWidth) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: chips,
              );
            }

            // 选项超出一屏 → 横向滚动
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < chips.length; i++) ...[
                    if (i > 0) SizedBox(width: spacing),
                    chips[i],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 估算所有 chip 的总宽度（文字宽 + 横向 padding 14*2）
  ///
  /// 用选中态字重 w500 近似（偏保守，避免低估导致窄屏溢出）。
  double _measureChipsWidth(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    var total = 0.0;
    for (final item in items) {
      final painter = TextPainter(
        text: TextSpan(
          text: item.label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      );
      painter.layout();
      total += painter.width + 28;
    }
    return total;
  }

  /// 单个胶囊
  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? BrandColors.primarySurface
              : BrandColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: selected
              ? Border.all(color: BrandColors.primary, width: 1)
              : null,
        ),
        child: Container(
          height: 32,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
              color: selected
                  ? BrandColors.primary
                  : BrandColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
