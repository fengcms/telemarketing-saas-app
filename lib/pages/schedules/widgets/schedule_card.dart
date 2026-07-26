/// 日程卡片
///
/// 展示单条日程：左侧状态色条 + 标题 + 时间 + 关联线索 +
/// 状态标签 + 归属人。根据状态呈现 常规/逾期/已完成/已取消 四态。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/schedule.dart';
import 'package:telemarketing_app/providers/options_provider.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';
import 'package:telemarketing_app/widgets/app_tag.dart';

/// 日程卡片
class ScheduleCard extends ConsumerWidget {
  /// 日程数据
  final Schedule schedule;

  /// 服务端时间（逾期判定用）
  final int serverTime;

  /// 点击回调（跳转详情，v0.13）
  final VoidCallback? onTap;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.serverTime,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = schedule;
    final isOverdue = s.status == 'pending' && s.isOverdue(serverTime);
    final isCancelled = s.status == 'cancelled';
    final isCompleted = s.status == 'completed';

    final Color barColor = isOverdue
        ? BrandColors.error
        : isCompleted
            ? BrandColors.textDisabled
            : BrandColors.primary;

    final Color titleColor =
        isCancelled ? BrandColors.textSecondary : BrandColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: barColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                                decoration: isCancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppTag(
                            label: _statusLabel(s.status, isOverdue),
                            backgroundColor: _statusColor(s.status, isOverdue)
                                .withValues(alpha: 0.1),
                            textColor: _statusColor(s.status, isOverdue),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: BrandColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            s.dateTimeDisplay,
                            style: const TextStyle(
                              fontSize: 13,
                              color: BrandColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (s.content != null && s.content!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          s.content!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: BrandColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      _OwnerRow(userId: s.userId),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 状态标签文案
String _statusLabel(String status, bool isOverdue) {
  if (isOverdue) return '逾期';
  switch (status) {
    case 'completed':
      return '已完成';
    case 'cancelled':
      return '已取消';
    default:
      return '待办';
  }
}

/// 状态标签色（与品牌色对齐；完成绿沿用设计系统既有 #00A870）
Color _statusColor(String status, bool isOverdue) {
  if (isOverdue) return BrandColors.error;
  switch (status) {
    case 'completed':
      return const Color(0xFF00A870);
    case 'cancelled':
      return BrandColors.textSecondary;
    default:
      return BrandColors.primary;
  }
}

/// 归属人（异步解析 userName）
class _OwnerRow extends ConsumerWidget {
  final String? userId;

  const _OwnerRow({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null || userId!.isEmpty) return const SizedBox();
    final name = ref.watch(userNameProvider(userId!));
    return Row(
      children: [
        const Icon(Icons.badge_outlined,
            size: 14, color: BrandColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '归属：${name.value ?? userId}',
            style: const TextStyle(
              fontSize: 13,
              color: BrandColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
