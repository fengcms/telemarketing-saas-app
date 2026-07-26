/// 统计数字卡片（公共组件）
///
/// 白底 + 圆角 10 + 标准微阴影，用于个人/团队统计页的数据卡。
/// 两种渲染模式：
///   - 简版：传 [label] + [value]，渲染 label(textSecondary 13) + value(默认 24/bold)
///   - 自定义：传 [child]，渲染任意内容（如转化率环形图）
/// [accent] 为 true 时 value 用品牌主色 [BrandColors.primary]（如转化率）。
library;

import 'package:flutter/material.dart';
import '../theme/color_scheme.dart';

/// 统计数字卡片
class StatCard extends StatelessWidget {
  /// 标签（副文字色，13）
  final String? label;

  /// 数值（主文字色，默认 24/bold；[accent] 时品牌色）
  final String? value;

  /// 是否强调（数值用品牌主色）
  final bool accent;

  /// 数值字号（默认 24；概况卡可传 30）
  final double valueFontSize;

  /// 自定义内容模式（优先级高于 [label]/[value]）
  final Widget? child;

  /// 附加徽标（如环比、超期提醒），显示在数值下方
  final Widget? badge;

  /// 内边距（默认 横14/纵12，收紧垂直空间避免卡片溢出）
  final EdgeInsetsGeometry padding;

  const StatCard({
    super.key,
    this.label,
    this.value,
    this.accent = false,
    this.valueFontSize = 24,
    this.child,
    this.badge,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: BrandColors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: BrandColors.textSecondary,
                  ),
                ),
              if (label != null) const SizedBox(height: 6),
              if (value != null)
                Text(
                  value!,
                  style: TextStyle(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.bold,
                    color: accent ? BrandColors.primary : BrandColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (badge != null) ...[
                const SizedBox(height: 4),
                badge!,
              ],
            ],
          ),
    );
  }
}
