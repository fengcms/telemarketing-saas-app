/// 统一通知提示条
///
/// 36px 高度，带图标 + 文字，可选可关闭 + 可点击。
/// 通过 [NoticeType] 控制配色。
///
/// ── 使用示例 ──
/// ```dart
/// AppNoticeBar.warning(
///   text: '当前处于离线状态，数据可能不及时',
///   closable: true,
///   onClose: () {},
/// )
/// ```
library;

import 'package:flutter/material.dart';

/// 通知类型
enum NoticeType { warning, info, success }

/// 统一通知提示条
class AppNoticeBar extends StatelessWidget {
  final NoticeType type;
  final IconData icon;
  final String text;
  final bool closable;
  final VoidCallback? onClose;
  final VoidCallback? onTap;

  const AppNoticeBar({
    super.key,
    required this.type,
    required this.icon,
    required this.text,
    this.closable = false,
    this.onClose,
    this.onTap,
  });

  /// 橙色警告提示
  factory AppNoticeBar.warning({
    required String text,
    bool closable = false,
    VoidCallback? onClose,
    VoidCallback? onTap,
  }) {
    return AppNoticeBar(
      type: NoticeType.warning,
      icon: Icons.error_outline,
      text: text,
      closable: closable,
      onClose: onClose,
      onTap: onTap,
    );
  }

  /// 蓝色信息提示
  factory AppNoticeBar.info({
    required String text,
    bool closable = false,
    VoidCallback? onClose,
    VoidCallback? onTap,
  }) {
    return AppNoticeBar(
      type: NoticeType.info,
      icon: Icons.access_time,
      text: text,
      closable: closable,
      onClose: onClose,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (Color bgColor, Color fgColor) = switch (type) {
      NoticeType.warning => (const Color(0xFFFFF3E0), const Color(0xFFE37318)),
      NoticeType.info => (const Color(0xFFE0EAFF), const Color(0xFF0052D9)),
      NoticeType.success => (const Color(0xFFE8F8F0), const Color(0xFF00A870)),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: fgColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 13, color: fgColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (closable)
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  child: Icon(Icons.close, size: 16, color: fgColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
