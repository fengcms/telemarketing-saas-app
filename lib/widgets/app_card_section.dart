/// 统一白卡片 Section
///
/// 带标题的可选内容卡片，12px 圆角白底 + 阴影，用于首页/详情页等区块。
///
/// ── 使用示例 ──
/// ```dart
/// AppCardSection(
///   title: '今日工作概况',
///   trailing: '7月26日 周日',
///   child: _buildStatsGrid(),
/// )
/// ```
library;

import 'package:flutter/material.dart';
import '../theme/color_scheme.dart';

/// 白卡片 Section
class AppCardSection extends StatelessWidget {
  final String? title;
  final String? trailing;
  final Widget? header;
  final Widget? child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const AppCardSection({
    super.key,
    this.title,
    this.trailing,
    this.header,
    this.child,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (header != null)
              header!
            else if (title != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: BrandColors.textPrimary,
                    ),
                  ),
                  if (trailing != null)
                    Text(
                      trailing!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: BrandColors.textSecondary,
                      ),
                    ),
                ],
              ),
            if (child != null) ...[
              const SizedBox(height: 16),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}
