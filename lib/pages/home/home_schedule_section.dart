/// 首页待办日程 Section（包含日程项、空白态）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/schedule.dart';
import 'package:telemarketing_app/providers/home_provider.dart';
import 'package:telemarketing_app/widgets/app_card_section.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';
import 'package:telemarketing_app/pages/schedules/schedule_detail_page.dart';
import 'home_skeletons.dart';

/// 待办日程卡片 Section
class HomeScheduleSection extends ConsumerWidget {
  final HomePageState state;
  final VoidCallback? onViewAll;

  const HomeScheduleSection({
    super.key,
    required this.state,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCardSection(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      header: _buildHeader(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.isLoadingSchedules && state.schedules == null)
            ...List.generate(3, (_) => const SkeletonScheduleCard())
          else if (state.schedulesError != null && state.schedules == null)
            _buildErrorRetry(state.schedulesError!, () {
              ref.read(homePageProvider.notifier).retrySchedules();
            })
          else if (state.schedules == null || state.schedules!.isEmpty)
            _buildEmptySchedule()
          else
            ...state.schedules!.asMap().entries.map(
                  (entry) => _buildScheduleItem(
                    context,
                    entry.value,
                    isLast: entry.key == state.schedules!.length - 1,
                    serverTime: state.serverTime > 0
                        ? state.serverTime
                        : DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  ),
                ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          '待办日程',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: BrandColors.textPrimary,
          ),
        ),
        if (state.todayPending > 0) ...[
          const SizedBox(width: 6),
          Badge(
            label: Text(
              '${state.todayPending}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ),
        ],
        const Spacer(),
        TextButton(
          onPressed: onViewAll,
          child: const Text('查看全部 >'),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(
      BuildContext context, Schedule schedule,
      {required bool isLast, required int serverTime}) {
    final overdue = schedule.isOverdue(serverTime);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ScheduleDetailPage(scheduleId: schedule.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 日期（月/日）+ 时间（时:分） ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.dateShortDisplay,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: overdue
                        ? BrandColors.error
                        : BrandColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  schedule.timeDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: overdue
                        ? BrandColors.error
                        : const Color(0xFF3C3C3C),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 日程标题 ──
                  Text(
                    schedule.title,
                    style: TextStyle(
                      fontSize: 15,
                      color: overdue
                          ? BrandColors.error
                          : BrandColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // ── 线索名称 ──
                  Text(
                    '线索：${schedule.leadName ?? "无"}',
                    style: TextStyle(
                      fontSize: 13,
                      color: overdue
                          ? const Color(0xFFF9B1B1)
                          : BrandColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // ── 日程备注 ──
                  if (schedule.content != null &&
                      schedule.content!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      schedule.content!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: BrandColors.textDisabled,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (overdue)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '已逾期',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: BrandColors.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySchedule() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_note, size: 64, color: BrandColors.textDisabled),
            SizedBox(height: 12),
            Text(
              '暂无待办日程',
              style: TextStyle(fontSize: 15, color: BrandColors.textDisabled),
            ),
            SizedBox(height: 4),
            Text(
              '完成当前线索跟进后可预约下次跟进',
              style: TextStyle(fontSize: 13, color: BrandColors.textDisabled),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorRetry(String error, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 48, color: BrandColors.textDisabled),
          const SizedBox(height: 8),
          Text(error,
              style: const TextStyle(
                  fontSize: 13, color: BrandColors.textSecondary)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onRetry,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
