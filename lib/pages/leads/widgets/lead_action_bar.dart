import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../models/lead_detail.dart';
import 'follow_up_panel.dart';
import 'schedule_dialog.dart';
import 'edit_lead_dialog.dart';
import 'dial_helper.dart';

/// 线索详情页操作按钮区（Section B）
///
/// 设计文档 §3.3 - 操作区
/// 4 个操作按钮：拨号 / 跟进 / 预约 / 编辑
/// 等分 4 列，TDButton(text) 竖向布局
class LeadActionBar extends StatelessWidget {
  final LeadDetail detail;
  final String leadId;

  const LeadActionBar({
    super.key,
    required this.detail,
    required this.leadId,
  });

  @override
  Widget build(BuildContext context) {
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
                : () => _onDial(context),
          ),
          _actionButton(
            icon: TDIcons.edit,
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

  void _onDial(BuildContext context) {
    handleDial(
      phone: detail.phone,
      context: context,
      // noCallWindow: from tenant profile (TODO: add from auth/settings)
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
