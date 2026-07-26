/// 空状态展示组件
///
/// 列表无数据时的统一占位（图标 + 主文案 + 可选副文案）。
/// 与 [AppErrorBody] 区分：错误态是「加载失败需重试」，空态是「无数据但正常」。
/// 页面通常在外层包 [RefreshIndicator] + 顶部留白，本组件只负责核心内容。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 空状态展示
class AppEmptyBody extends StatelessWidget {
  /// 主图标
  final IconData icon;

  /// 主文案（16px / w500 / 主文字色）
  final String title;

  /// 副文案（14px / 副文字色），为空则不渲染
  final String? desc;

  /// 图标尺寸，默认 80
  final double iconSize;

  /// 图标颜色，默认灰 `#DCDCDC`（暂无对应调色板常量，保留字面量）
  final Color? iconColor;

  const AppEmptyBody({
    super.key,
    required this.icon,
    required this.title,
    this.desc,
    this.iconSize = 80,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: iconSize, color: iconColor ?? const Color(0xFFDCDCDC)),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: BrandColors.textPrimary,
          ),
        ),
        if (desc != null) ...[
          const SizedBox(height: 8),
          Text(
            desc!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: BrandColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
