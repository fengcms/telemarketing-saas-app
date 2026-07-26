/// 列表底部加载状态组件
///
/// 统一「加载更多转圈 / 已加载全部提示 / 底部留白」三段式 footer，
/// 供日程 / 通话 / 客户等列表复用。返回普通 [Widget]，外层用
/// [SliverToBoxAdapter] 包裹即可。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 列表底部加载状态
class AppListFooter extends StatelessWidget {
  /// 是否正在加载更多（显示转圈）
  final bool isLoadingMore;

  /// 是否还有更多（false 且非加载中显示「已加载全部」）
  final bool hasMore;

  /// 加载中转圈区高度，默认 56
  final double loadingHeight;

  /// 「已加载全部」区高度，默认 48
  final double endHeight;

  const AppListFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasMore,
    this.loadingHeight = 56,
    this.endHeight = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return SizedBox(
        height: loadingHeight,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!hasMore) {
      return SizedBox(
        height: endHeight,
        child: Center(
          child: Text(
            '— 已加载全部 —',
            style: TextStyle(
              fontSize: 12,
              color: BrandColors.textDisabled.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }
}
