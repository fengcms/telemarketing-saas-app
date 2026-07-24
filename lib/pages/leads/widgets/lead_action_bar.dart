/// 线索详情页操作按钮区（Section B）
///
/// 设计文档 §3.3 - 操作区
/// 3 个操作按钮：跟进 / 预约 / 编辑
/// 横向：图标 + 文字，间隔 6px
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:telemarketing_app/models/lead_detail.dart';
import 'package:telemarketing_app/providers/schedule_list_provider.dart';
import 'package:telemarketing_app/providers/lead_detail_provider.dart';
import 'follow_up_panel.dart';
import 'package:telemarketing_app/pages/schedules/widgets/schedule_form_sheet.dart';
import 'edit_lead_dialog.dart';

/// 线索详情页操作按钮区（Section B）
///
/// 设计文档 §3.3 - 操作区
/// 3 个操作按钮：跟进 / 预约 / 编辑
/// 横向：图标 + 文字，间隔 6px
class LeadActionBar extends ConsumerWidget {
  final LeadDetail detail;
  final String leadId;

  const LeadActionBar({
    super.key,
    required this.detail,
    required this.leadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 44,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _actionButton(
            icon: TDIcons.rollback,
            label: '跟进',
            onTap: detail.isConverted
                ? null
                : () => showFollowUpPanel(context, leadId: leadId),
          ),
          _actionButton(
            icon: TDIcons.calendar,
            label: '日程',
            onTap: detail.isConverted
                ? null
                : () async {
                    final changed = await showScheduleFormSheet(
                      context,
                      leadId: leadId,
                      leadName: detail.name,
                      leadPhone: detail.phone,
                    );
                    if (changed == true) {
                      // 刷新日程列表聚合 + 本线索下的日程区
                      try {
                        ref.read(scheduleListProvider.notifier).refresh();
                      } catch (_) {}
                      try {
                        ref.read(leadDetailProvider.notifier).refreshBundle();
                      } catch (_) {}
                    }
                  },
          ),
          _actionButton(
            icon: TDIcons.edit,
            label: '编辑',
            onTap: () => showEditLeadDialog(
                  context,
                  leadId: leadId,
                  detail: detail,
                ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDisabled
                  ? const Color(0xFFDCDCDC)
                  : const Color(0xFF0052D9),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDisabled
                    ? const Color(0xFFDCDCDC)
                    : const Color(0xFF181818),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
