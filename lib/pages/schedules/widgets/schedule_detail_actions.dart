/// 日程详情页 — 底部操作栏展示组件（独立库，顶层构建函数）
///
/// 将底部操作栏（取消/拨号/完成 / 重新打开）的纯展示部分抽为顶层函数，
/// 操作回调通过参数注入；状态类逻辑（_onComplete/_onCancel/_onReopen 等）
/// 留在页面 State。目的：配合 cards 拆分，将 schedule_detail_page 收至 560 行以下。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';
import 'package:telemarketing_app/widgets/app_action_bar.dart';

/// 底部操作栏（pending：取消/拨号/完成；其余：重新打开）
Widget actionBar({
  required bool isPending,
  required bool hasLead,
  required bool actionLoading,
  required VoidCallback? onCancel,
  required VoidCallback? onDial,
  required VoidCallback? onComplete,
  required VoidCallback? onReopen,
}) {
  final actions = <ActionItem>[];
  if (isPending) {
    actions.addAll([
      ActionItem(
        text: '取消日程',
        type: ActionType.light,
        onTap: actionLoading ? null : onCancel,
      ),
      if (hasLead)
        ActionItem(
          text: '拨号',
          type: ActionType.light,
          icon: Icons.call,
          onTap: actionLoading ? null : onDial,
        ),
      ActionItem(
        text: '标记完成',
        type: ActionType.primary,
        loading: actionLoading,
        onTap: actionLoading ? null : onComplete,
      ),
    ]);
  } else {
    actions.add(
      ActionItem(
        icon: Icons.replay,
        text: '重新打开',
        type: ActionType.primary,
        loading: actionLoading,
        onTap: actionLoading ? null : onReopen,
      ),
    );
  }
  return Container(
    height: 64,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: BrandColors.line, width: 1)),
      boxShadow: [
        BoxShadow(
          color: Color(0x14000000),
          offset: Offset(0, -1),
          blurRadius: 4,
        ),
      ],
    ),
    child: AppActionBar(actions: actions),
  );
}

/// 信息卡片下方内联操作行的单个按钮（跟进 / 日程 / 编辑）
Widget actionButton({
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
          Icon(icon, size: 18,
              color: isDisabled
                  ? const Color(0xFFDCDCDC)
                  : BrandColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: BrandColors.textPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}
