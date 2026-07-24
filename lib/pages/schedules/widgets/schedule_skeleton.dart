/// 日程列表骨架屏组件
///
/// 待办 / 已完成 两个 Tab 共用。外观对齐真实日程卡片
/// （左侧色条 + 标题 + 时间/归属行），并带微光（shimmer）扫光动画，
/// 比早期纯白矩形占位更贴近真实加载态，避免"闪现"。
library;

import 'package:flutter/material.dart';

/// 日程列表加载骨架屏
///
/// [count] 为骨架卡片数量（默认 4）。整体置于灰色页面底上，
/// 卡片为白色圆角，内部灰块以 shimmer 动画扫光。
class ScheduleSkeleton extends StatefulWidget {
  /// 骨架卡片数量
  final int count;

  const ScheduleSkeleton({super.key, this.count = 4});

  @override
  State<ScheduleSkeleton> createState() => _ScheduleSkeletonState();
}

class _ScheduleSkeletonState extends State<ScheduleSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: widget.count,
      itemBuilder: (_, _) => _SkeletonCard(ctrl: _ctrl),
    );
  }
}

/// 单张骨架卡片（布局对齐真实日程卡片）
class _SkeletonCard extends StatelessWidget {
  final AnimationController ctrl;

  const _SkeletonCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左侧状态色条（静态灰）
          const SizedBox(
            width: 4,
            child: ColoredBox(color: Color(0xFFE7E7E7)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 标题占位
                      _ShimmerBlock(ctrl: ctrl, width: 160, height: 16),
                      const Spacer(),
                      // 状态标签占位
                      _ShimmerBlock(ctrl: ctrl, width: 40, height: 18),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // 时间占位
                      _ShimmerBlock(ctrl: ctrl, width: 90, height: 14),
                      const SizedBox(width: 12),
                      // 归属占位
                      _ShimmerBlock(ctrl: ctrl, width: 80, height: 14),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 内容/归属人占位
                  _ShimmerBlock(ctrl: ctrl, width: 120, height: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 带 shimmer 扫光的灰块
///
/// 随 [ctrl] 进度平移渐变高亮区，形成由左向右的微光扫动。
class _ShimmerBlock extends StatelessWidget {
  final AnimationController ctrl;
  final double width;
  final double height;

  const _ShimmerBlock({
    required this.ctrl,
    this.width = double.infinity,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, _) {
        // value ∈ [0,1]，驱动高亮带在块内左右扫动
        final p = ctrl.value;
        final a = (p - 0.4).clamp(0.0, 1.0);
        final b = p.clamp(0.0, 1.0);
        final c = (p + 0.4).clamp(0.0, 1.0);
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [a, b, c],
              colors: const [
                Color(0xFFE7E7E7),
                Color(0xFFF4F4F4),
                Color(0xFFE7E7E7),
              ],
            ),
          ),
        );
      },
    );
  }
}
