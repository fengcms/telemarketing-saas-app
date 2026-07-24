/// 日程详情页 — 内容区块组件（独立库，顶层构建函数）
///
/// 将详情页的「纯展示」区块（骨架屏 / 标题 / 状态 / 计划时间 / 关联线索 /
/// 内容 / 其他信息 / 通用卡片容器）抽为顶层函数，数据通过参数传入，
/// 不依赖页面 State。目的：将 1024 行的 schedule_detail_page 收至 560 行红线以下。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/models/schedule_detail.dart';
import 'schedule_skeleton.dart';

/// 通用卡片容器（左右 16、上 8、圆角 12、白底；灰底背景透出即板块间隔）
Widget detailCard({required Widget child, VoidCallback? onTap}) {
  final inner = Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );
  if (onTap == null) return inner;
  return GestureDetector(onTap: onTap, child: inner);
}

/// 首屏骨架屏（白卡片 + shimmer 扫光，对齐列表页风格）
Widget scheduleDetailSkeleton(AnimationController ctrl) {
  return ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
    children: [
      _skeletonCard(
        ctrl: ctrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBlock(ctrl: ctrl, width: 180, height: 22),
                const Spacer(),
                ShimmerBlock(ctrl: ctrl, width: 44, height: 20),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      _skeletonCard(
        ctrl: ctrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBlock(ctrl: ctrl, width: 72, height: 13),
            const SizedBox(height: 8),
            ShimmerBlock(ctrl: ctrl, width: 200, height: 18),
          ],
        ),
      ),
      const SizedBox(height: 8),
      _skeletonCard(
        ctrl: ctrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBlock(ctrl: ctrl, width: 72, height: 13),
            const SizedBox(height: 8),
            ShimmerBlock(ctrl: ctrl, width: 140, height: 18),
          ],
        ),
      ),
      const SizedBox(height: 8),
      _skeletonCard(
        ctrl: ctrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBlock(ctrl: ctrl, width: 48, height: 13),
            const SizedBox(height: 8),
            ShimmerBlock(ctrl: ctrl, width: 280, height: 14),
            const SizedBox(height: 6),
            ShimmerBlock(ctrl: ctrl, width: 240, height: 14),
          ],
        ),
      ),
      const SizedBox(height: 8),
      _skeletonCard(
        ctrl: ctrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBlock(ctrl: ctrl, width: 64, height: 13),
            const SizedBox(height: 8),
            ShimmerBlock(ctrl: ctrl, width: 120, height: 16),
            const SizedBox(height: 6),
            ShimmerBlock(ctrl: ctrl, width: 100, height: 16),
            const SizedBox(height: 6),
            ShimmerBlock(ctrl: ctrl, width: 160, height: 16),
          ],
        ),
      ),
    ],
  );
}

/// 骨架屏白卡片容器（对齐列表页卡片圆角与阴影）
Widget _skeletonCard({required AnimationController ctrl, required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
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
    child: child,
  );
}

/// 标题 + 状态标签
Widget titleSection(ScheduleDetail d) {
  return detailCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            d.title.isEmpty ? '未命名日程' : d.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: d.status == 'completed' || d.status == 'cancelled'
                  ? const Color(0xFFA6A6A6)
                  : const Color(0xFF181818),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        statusTag(d),
      ],
    ),
  );
}

/// 状态标签（待办/已完成/已取消）
Widget statusTag(ScheduleDetail d) {
  late final Color bg;
  late final Color fg;
  late final String label;
  if (d.status == 'completed') {
    bg = const Color(0xFFE3F3EA);
    fg = const Color(0xFF2BA471);
    label = '已完成';
  } else if (d.status == 'cancelled') {
    bg = const Color(0xFFF3F3F3);
    fg = const Color(0xFFA6A6A6);
    label = '已取消';
  } else {
    bg = const Color(0xFFF2F3FF);
    fg = const Color(0xFF0052D9);
    label = '待办';
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 12, color: fg),
    ),
  );
}

/// 计划时间卡（逾期显红字 + 已逾期标签）
Widget timeCard(ScheduleDetail d) {
  final overdue = d.isOverdue(DateTime.now().millisecondsSinceEpoch ~/ 1000);
  return detailCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📅 计划时间',
          style: TextStyle(fontSize: 12, color: Color(0xFFA6A6A6)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                d.scheduledDisplay,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: overdue
                      ? const Color(0xFFD54941)
                      : const Color(0xFF181818),
                ),
              ),
            ),
            if (overdue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD54941),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '已逾期',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

/// 关联线索卡（擦除显「已删除」；[onTap] 为点按跳转线索详情回调）
Widget leadCard(ScheduleDetail d, VoidCallback? onTap) {
  if (d.lead == null) {
    return detailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '👤 关联线索',
            style: TextStyle(fontSize: 12, color: Color(0xFFA6A6A6)),
          ),
          SizedBox(height: 8),
          Text(
            '该线索已被删除',
            style: TextStyle(fontSize: 16, color: Color(0xFFA6A6A6)),
          ),
        ],
      ),
    );
  }
  final lead = d.lead!;
  return detailCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text(
              '👤 关联线索',
              style: TextStyle(fontSize: 12, color: Color(0xFFA6A6A6)),
            ),
            Spacer(),
            Icon(Icons.chevron_right, size: 20, color: Color(0xFFA6A6A6)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          lead.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF181818),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '📞 ${lead.phone}',
          style: const TextStyle(fontSize: 14, color: Color(0xFFA6A6A6)),
        ),
      ],
    ),
  );
}

/// 日程内容卡（空显「暂无内容」）
Widget contentCard(ScheduleDetail d) {
  final empty = d.content == null || d.content!.isEmpty;
  return detailCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📝 日程内容',
          style: TextStyle(fontSize: 12, color: Color(0xFFA6A6A6)),
        ),
        const SizedBox(height: 8),
        Text(
          empty ? '暂无内容' : d.content!,
          style: TextStyle(
            fontSize: 14,
            fontStyle: empty ? FontStyle.italic : FontStyle.normal,
            color: empty
                ? const Color(0xFFA6A6A6)
                : const Color(0xFF181818),
          ),
        ),
      ],
    ),
  );
}

/// 其他信息卡（创建时间 / 归属人 / 更新时间）
Widget infoCard(ScheduleDetail d, String? ownerName) {
  final owner = ownerName ?? d.userId;
  return detailCard(
    child: Column(
      children: [
        _infoRow('创建时间', ScheduleDetail.formatTs(d.createdAt)),
        const SizedBox(height: 12),
        _infoRow('归属人', owner.isEmpty ? '未知' : owner),
        const SizedBox(height: 12),
        _infoRow('更新时间', ScheduleDetail.formatTs(d.updatedAt)),
      ],
    ),
  );
}

/// 其他信息卡内的两列行（标签 + 值）
Widget _infoRow(String label, String value) {
  return SizedBox(
    height: 28,
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFFA6A6A6)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF181818)),
          ),
        ),
      ],
    ),
  );
}
