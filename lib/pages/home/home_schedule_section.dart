/// 首页待办日程 Section（包含日程项、空白态）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/schedule.dart';
import '../../providers/home_provider.dart';
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Text(
                  '待办日程',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181818),
                  ),
                ),
                if ((state.stats?.dueToday ?? 0) > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0052D9),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${state.stats?.dueToday ?? 0}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: onViewAll,
                  child: const Text(
                    '查看全部 >',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0052D9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (state.isLoadingSchedules && state.schedules == null)
            ...List.generate(
              3,
              (_) => const SkeletonScheduleCard(),
            )
          else if (state.schedulesError != null && state.schedules == null)
            _buildErrorRetry(state.schedulesError!, () {
              ref.read(homePageProvider.notifier).retrySchedules();
            })
          else if (state.schedules == null || state.schedules!.isEmpty)
            _buildEmptySchedule()
          else
            ...state.schedules!.asMap().entries.map(
                  (entry) => _buildScheduleItem(
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

  Widget _buildScheduleItem(Schedule schedule,
      {required bool isLast, required int serverTime}) {
    final overdue = schedule.isOverdue(serverTime);
    return GestureDetector(
      onTap: () {
        // 跳转日程详情 — 待开发
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 16),
            SizedBox(
              width: 44,
              child: Text(
                schedule.timeDisplay,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: overdue
                      ? const Color(0xFFD54941)
                      : const Color(0xFF3C3C3C),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.title,
                    style: TextStyle(
                      fontSize: 15,
                      color: overdue
                          ? const Color(0xFFD54941)
                          : const Color(0xFF181818),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '线索：${schedule.leadName ?? "无"}',
                    style: TextStyle(
                      fontSize: 13,
                      color: overdue
                          ? const Color(0xFFF9B1B1)
                          : const Color(0xFFA6A6A6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (overdue)
              Container(
                margin: const EdgeInsets.only(right: 16),
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
                    color: Color(0xFFD54941),
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
            Icon(Icons.event_note, size: 64, color: Color(0xFFDCDCDC)),
            SizedBox(height: 12),
            Text(
              '暂无待办日程',
              style: TextStyle(fontSize: 15, color: Color(0xFFC5C5C5)),
            ),
            SizedBox(height: 4),
            Text(
              '完成当前线索跟进后可预约下次跟进',
              style: TextStyle(fontSize: 13, color: Color(0xFFDCDCDC)),
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
          const Icon(Icons.cloud_off, size: 48, color: Color(0xFFDCDCDC)),
          const SizedBox(height: 8),
          Text(error,
              style: const TextStyle(fontSize: 13, color: Color(0xFFC5C5C5))),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0052D9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('重试',
                  style: TextStyle(fontSize: 13, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
