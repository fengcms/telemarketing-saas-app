/// 通话记录列表骨架屏
///
/// 复用日程模块既有 [ShimmerBlock]，渲染 5 条与真实行等高的占位，
/// 避免「闪现白屏」。布局对齐 [CallRecordRow]：左圆 + 两行 + 右时长。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/pages/schedules/widgets/schedule_skeleton.dart';

/// 通话记录列表加载骨架屏
class CallListSkeleton extends StatefulWidget {
  /// 骨架行数（默认 5）
  final int count;

  const CallListSkeleton({super.key, this.count = 5});

  @override
  State<CallListSkeleton> createState() => _CallListSkeletonState();
}

class _CallListSkeletonState extends State<CallListSkeleton>
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
      itemBuilder: (_, index) => _SkeletonRow(ctrl: _ctrl),
    );
  }
}

/// 单条骨架行（布局对齐 [CallRecordRow]）
class _SkeletonRow extends StatelessWidget {
  final AnimationController ctrl;

  const _SkeletonRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // 左圆占位
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFE7E7E7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBlock(ctrl: ctrl, width: 140, height: 15),
                const SizedBox(height: 8),
                ShimmerBlock(ctrl: ctrl, width: 90, height: 13),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ShimmerBlock(ctrl: ctrl, width: 40, height: 13),
        ],
      ),
    );
  }
}
