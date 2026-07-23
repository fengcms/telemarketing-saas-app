/// 线索详情页操作按钮区（Section B）
///
/// 设计文档 §3.3 - 操作区
/// 4 个操作按钮：拨号 / 跟进 / 预约 / 编辑
/// 等分 4 列，TDButton(text) 竖向布局
library;

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../models/lead_detail.dart';
import '../../../providers/auth_provider.dart';
import 'follow_up_panel.dart';
import 'schedule_dialog.dart';
import 'edit_lead_dialog.dart';
import 'dial_helper.dart';

/// 线索详情页操作按钮区（Section B）
///
/// 设计文档 §3.3 - 操作区
/// 4 个操作按钮：拨号 / 跟进 / 预约 / 编辑
/// 等分 4 列，TDButton(text) 竖向布局
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
      height: 72,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionButton(
            icon: TDIcons.call,
            label: '拨号',
            onTap: detail.isConverted || detail.phone.isEmpty
                ? null
                : () => _onDial(context, ref),
          ),
          _actionButton(
            icon: TDIcons.rollback,
            label: '跟进',
            onTap: detail.isConverted
                ? null
                : () => showFollowUpPanel(context, leadId: leadId),
          ),
          _actionButton(
            icon: TDIcons.calendar,
            label: '预约',
            onTap: detail.isConverted
                ? null
                : () => showScheduleDialog(
                      context,
                      leadId: leadId,
                      detail: detail,
                    ),
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

  void _onDial(BuildContext context, WidgetRef ref) async {
    final tenantService = ref.read(tenantServiceProvider);
    final settings = await tenantService.fetchProfile();
    final noCallWindow = settings['noCallWindow'] as Map<String, dynamic>?;
    handleDial(
      phone: detail.phone,
      context: context,
      noCallWindow: noCallWindow,
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 64,
      child: TDButton(
        text: label,
        type: TDButtonType.text,
        icon: icon,
        size: TDButtonSize.small,
        onTap: onTap,
      ),
    );
  }
}
