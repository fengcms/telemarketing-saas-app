/// 日程详情页 — 底部操作栏展示组件（独立库，顶层构建函数）
///
/// 将底部操作栏（取消/拨号/完成 / 重新打开）的纯展示部分抽为顶层函数，
/// 操作回调通过参数注入；状态类逻辑（_onComplete/_onCancel/_onReopen 等）
/// 留在页面 State。目的：配合 cards 拆分，将 schedule_detail_page 收至 560 行以下。
library;

import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

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
  return _actionBarInner(
    isPending: isPending,
    hasLead: hasLead,
    actionLoading: actionLoading,
    onCancel: onCancel,
    onDial: onDial,
    onComplete: onComplete,
    onReopen: onReopen,
  );
}

Widget _actionBarInner({
  required bool isPending,
  required bool hasLead,
  required bool actionLoading,
  required VoidCallback? onCancel,
  required VoidCallback? onDial,
  required VoidCallback? onComplete,
  required VoidCallback? onReopen,
}) {
  return Container(
    height: 64,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      boxShadow: [
        BoxShadow(
          color: Color(0x14000000),
          offset: Offset(0, -1),
          blurRadius: 4,
        ),
      ],
    ),
    child: isPending
        ? _pendingActions(
            hasLead: hasLead,
            actionLoading: actionLoading,
            onCancel: onCancel,
            onDial: onDial,
            onComplete: onComplete,
          )
        : _doneActions(actionLoading: actionLoading, onReopen: onReopen),
  );
}

/// pending（含逾期）：[取消日程] [📞] [✅ 标记完成]
/// 三者等宽、形状统一（round）；取消/拨号为浅色、完成为主色（保留主次层级）
Widget _pendingActions({
  required bool hasLead,
  required bool actionLoading,
  required VoidCallback? onCancel,
  required VoidCallback? onDial,
  required VoidCallback? onComplete,
}) {
  return Row(
    children: [
      Expanded(
        child: TDButton(
          text: '取消日程',
          theme: TDButtonTheme.light,
          shape: TDButtonShape.round,
          onTap: actionLoading ? null : onCancel,
        ),
      ),
      if (hasLead) const SizedBox(width: 12),
      if (hasLead)
        Expanded(
          child: TDButton(
            text: '拨号',
            theme: TDButtonTheme.light,
            shape: TDButtonShape.round,
            iconWidget:
                const Icon(Icons.call, size: 18, color: Color(0xFF0052D9)),
            onTap: actionLoading ? null : onDial,
          ),
        ),
      const SizedBox(width: 12),
      Expanded(
        child: TDButton(
          text: actionLoading ? '' : '标记完成',
          theme: TDButtonTheme.primary,
          shape: TDButtonShape.round,
          iconWidget: actionLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : null,
          onTap: actionLoading ? null : onComplete,
        ),
      ),
    ],
  );
}

/// completed / cancelled：[🔄 重新打开]
Widget _doneActions({
  required bool actionLoading,
  required VoidCallback? onReopen,
}) {
  return Row(
    children: [
      const Spacer(),
      TDButton(
        text: actionLoading ? '' : '🔄 重新打开',
        theme: TDButtonTheme.primary,
        shape: TDButtonShape.round,
        iconWidget: actionLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : null,
        onTap: actionLoading ? null : onReopen,
      ),
    ],
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
                  : const Color(0xFF0052D9)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF181818),
            ),
          ),
        ],
      ),
    ),
  );
}
