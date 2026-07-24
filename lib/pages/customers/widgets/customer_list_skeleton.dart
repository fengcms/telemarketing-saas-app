/// 客户列表骨架屏
///
/// 复用日程模块既有 [ShimmerBlock]，渲染 5 条与真实卡片等高的占位，
/// 避免「闪现白屏」。布局对齐 [CustomerCard]。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/pages/schedules/widgets/schedule_skeleton.dart';

/// 客户列表加载骨架屏
class CustomerListSkeleton extends StatefulWidget {
  /// 骨架行数（默认 5）
  final int count;

  const CustomerListSkeleton({super.key, this.count = 5});

  @override
  State<CustomerListSkeleton> createState() => _CustomerListSkeletonState();
}

class _CustomerListSkeletonState extends State<CustomerListSkeleton>
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
      padding: EdgeInsets.zero,
      itemCount: widget.count,
      itemBuilder: (_, index) => _SkeletonCard(ctrl: _ctrl),
    );
  }
}

/// 单条骨架卡（布局对齐 [CustomerCard]：第一行 姓名+标签 / 电话 / 公司 / 日期）
class _SkeletonCard extends StatelessWidget {
  final AnimationController ctrl;

  const _SkeletonCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerBlock(ctrl: ctrl, width: 120, height: 16),
              const SizedBox(width: 8),
              ShimmerBlock(ctrl: ctrl, width: 44, height: 20),
            ],
          ),
          const SizedBox(height: 6),
          ShimmerBlock(ctrl: ctrl, width: 120, height: 14),
          const SizedBox(height: 4),
          ShimmerBlock(ctrl: ctrl, width: 100, height: 14),
          const SizedBox(height: 8),
          ShimmerBlock(ctrl: ctrl, width: 140, height: 13),
        ],
      ),
    );
  }
}
