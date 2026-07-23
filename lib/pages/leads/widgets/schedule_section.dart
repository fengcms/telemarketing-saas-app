/// 最近日程区块（Section E）
///
/// 设计文档 §3.6 - 最近日程
/// 展示详情接口返回的最近 5 条日程；"查看全部"跳日程列表页（待开发）。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/models/schedule.dart';

/// 最近日程区块
class ScheduleSection extends StatelessWidget {
  final List<Schedule> schedules;

  const ScheduleSection({super.key, required this.schedules});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 8),
          if (schedules.isEmpty) _buildEmptyState() else _buildList(),
        ],
      ),
    );
  }

  // ── 标题 ──

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          '最近日程',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF181818),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            // Node：跳转日程列表页（待开发）
          },
          child: const Text(
            '查看全部',
            style: TextStyle(fontSize: 13, color: Color(0xFF0052D9)),
          ),
        ),
      ],
    );
  }

  // ── 空态 ──

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      width: double.infinity,
      child: const Column(
        children: [
          Icon(
            Icons.calendar_today,
            size: 40,
            color: Color(0xFFDCDCDC),
          ),
          SizedBox(height: 8),
          Text(
            '暂无日程',
            style: TextStyle(fontSize: 14, color: Color(0xFF181818)),
          ),
        ],
      ),
    );
  }

  // ── 列表 ──

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
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期+时间
          SizedBox(
            width: 76,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF181818),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFA6A6A6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 标题+备注
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF181818),
                  ),
                ),
                if (s.content != null && s.content!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    s.content!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA6A6A6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 状态标签
          _buildStatusTag(s.status),
        ],
      ),
    );
  }

  // ── 状态标签 ──

  Widget _buildStatusTag(String status) {
    final (label, bg, fg) = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: fg),
      ),
    );
  }

  /// 状态样式：[标签, 背景色, 文字色]
  (String, Color, Color) _statusStyle(String status) {
    switch (status) {
      case 'completed':
        return ('已完成', const Color(0x1A2BA471), const Color(0xFF2BA471));
      case 'cancelled':
        return ('已取消', const Color(0x1AD54941), const Color(0xFFD54941));
      default:
        return ('待办', const Color(0x1A0052D9), const Color(0xFF0052D9));
    }
  }
}
