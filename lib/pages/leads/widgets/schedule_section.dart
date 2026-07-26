/// 最近日程区块（Section E）
///
/// 设计文档 §3.6 - 最近日程
/// 展示详情接口返回的最近 5 条日程；"查看全部"跳日程列表页（待开发）。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/models/schedule.dart';
import 'package:telemarketing_app/widgets/app_card_section.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';

/// 最近日程区块
class ScheduleSection extends StatelessWidget {
  final List<Schedule> schedules;
  final VoidCallback? onViewAll;

  const ScheduleSection({super.key, required this.schedules, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return AppCardSection(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          const Divider(height: 1, color: BrandColors.border),
          const SizedBox(height: 8),
          if (schedules.isEmpty) _buildEmptyState() else _buildList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          '最近日程',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: BrandColors.textPrimary,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onViewAll,
          child: const Text('查看全部'),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      width: double.infinity,
      child: const Column(
        children: [
          Icon(Icons.calendar_today, size: 40, color: BrandColors.textDisabled),
          SizedBox(height: 8),
          Text(
            '暂无日程',
            style: TextStyle(fontSize: 14, color: BrandColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return Column(
      children: schedules.map(_buildRow).toList(),
    );
  }

  Widget _buildRow(Schedule s) {
    final dt = DateTime.fromMillisecondsSinceEpoch(s.scheduledAt * 1000);
    final dateStr =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: BrandColors.border, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 13, color: BrandColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 12, color: BrandColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.title,
                  style: const TextStyle(fontSize: 14, color: BrandColors.textPrimary),
                ),
                if (s.content != null && s.content!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    s.content!,
                    style: const TextStyle(fontSize: 12, color: BrandColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusTag(s.status),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    final (label, bg, fg) = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 12, color: fg)),
    );
  }

  (String, Color, Color) _statusStyle(String status) {
    switch (status) {
      case 'completed':
        return ('已完成', const Color(0x1A2BA471), BrandColors.success);
      case 'cancelled':
        return ('已取消', const Color(0x1AD54941), BrandColors.error);
      default:
        return ('待办', const Color(0x1A0052D9), BrandColors.primary);
    }
  }
}
