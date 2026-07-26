/// 固定高度吸顶头部委托
///
/// 任何需要「固定高度 + 不随滚动收缩」吸顶的列表都能复用，避免重复实现
/// [SliverPersistentHeaderDelegate]。
library;

import 'package:flutter/material.dart';

/// 固定高度吸顶委托
class FixedStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  /// 吸顶高度
  final double height;

  /// 吸顶内容
  final Widget child;

  const FixedStickyHeaderDelegate({
    required this.height,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      child;

  @override
  bool shouldRebuild(FixedStickyHeaderDelegate old) => false;
}
