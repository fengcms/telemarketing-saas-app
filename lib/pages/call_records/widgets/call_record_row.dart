/// 通话记录单行组件
///
/// 设计文档 §3.3 + §7。
/// 左侧圆形彩色图标（按接听类型配色）→ 主体两行
/// （姓名/号码 + 拨号时间）→ 右侧时长（未接通显示文案）+ 违规红标。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/models/call_record.dart';

/// 通话记录单行
class CallRecordRow extends StatelessWidget {
  /// 单条通话记录
  final CallRecord record;

  /// 点击整行回调（如跳对应线索详情）；为 null 时不响应点击
  final VoidCallback? onTap;

  const CallRecordRow({super.key, required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(record.answerType);
    final durationLabel = _durationLabel(record);

    return GestureDetector(
      onTap: onTap,
      behavior: onTap == null ? null : HitTestBehavior.opaque,
      child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 左侧圆形彩色图标
              CircleAvatar(
                radius: 18,
                backgroundColor: style.bg,
                child: Icon(style.icon, size: 18, color: style.fg),
              ),
              const SizedBox(width: 12),
              // 主体两行
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          // 姓名（半粗、近黑）
                          TextSpan(
                            text: record.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF181818),
                            ),
                          ),
                          // 手机号：仅当「有姓名且手机号非空」时附在姓名后，
                          // 黑色、常规字重（不加粗），避免无姓名时与 displayName 回退的号码重复。
                          if (record.leadName != null &&
                              record.leadName!.isNotEmpty &&
                              record.phone.isNotEmpty)
                            TextSpan(
                              text: '  ${record.phone}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.normal,
                                color: Color(0xFF181818),
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.shortDateTime,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFA6A6A6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 右侧时长 / 违规
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    durationLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: record.isAnswered
                          ? const Color(0xFF181818)
                          : const Color(0xFFA6A6A6),
                    ),
                  ),
                  if (record.isViolation)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.error_outline,
                        size: 14,
                        color: Color(0xFFD54941),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        // 左缩进分割线（对齐图标右缘）
      const Divider(
        height: 1,
        thickness: 1,
        indent: 56,
        color: Color(0xFFEEEEEE),
      ),
      ],
    ),
  );
  }

  /// 右侧时长文案：已接通且 >0 秒显示 M:SS，否则「未接通」
  String _durationLabel(CallRecord r) {
    if (r.isAnswered && (r.duration ?? 0) > 0) return r.durationText;
    return '未接通';
  }

  /// 接听类型 → (圆形背景色, 图标色, 图标)
  ({Color bg, Color fg, IconData icon}) _styleFor(String? answerType) {
    switch (answerType) {
      case 'answered':
        return (
          bg: const Color(0x332BA471),
          fg: const Color(0xFF2BA471),
          icon: Icons.call,
        );
      case 'no_answer':
        return (
          bg: const Color(0x33D54941),
          fg: const Color(0xFFD54941),
          icon: Icons.call_end,
        );
      case 'rejected':
        return (
          bg: const Color(0x33E37318),
          fg: const Color(0xFFE37318),
          icon: Icons.cancel,
        );
      case 'empty_number':
      case 'suspended':
        return (
          bg: const Color(0x33A6A6A6),
          fg: const Color(0xFFA6A6A6),
          icon: Icons.block,
        );
      default:
        return (
          bg: const Color(0x33A6A6A6),
          fg: const Color(0xFFA6A6A6),
          icon: Icons.call,
        );
    }
  }
}
