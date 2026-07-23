/// 底部线索导航条
///
/// 设计文档 §2.9 - 底部线索导航条（上下文相关）
/// 仅从线索列表页/公海列表页进入详情页时显示。
/// [← 上一个] [3 / 28] [下一个 →]
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/lead_list_context.dart';
import 'package:telemarketing_app/providers/lead_detail_provider.dart';

/// 底部线索导航条
///
/// 设计文档 §2.9 - 底部线索导航条（上下文相关）
/// 仅从线索列表页/公海列表页进入详情页时显示。
/// [← 上一个] [3 / 28] [下一个 →]
class LeadBottomNav extends ConsumerWidget {
  final LeadListContext listContext;

  const LeadBottomNav({super.key, required this.listContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFirst = !listContext.hasPrev;
    final isLast = !listContext.hasNext;

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 上一个按钮
            Expanded(
              child: GestureDetector(
                onTap: isFirst
                    ? null
                    : () {
                        ref
                            .read(leadDetailProvider.notifier)
                            .goToPrev();
                      },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chevron_left,
                        size: 18,
                        color: isFirst
                            ? const Color(0xFFDCDCDC)
                            : const Color(0xFF0052D9),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '上一个',
                        style: TextStyle(
                          fontSize: 13,
                          color: isFirst
                              ? const Color(0xFFDCDCDC)
                              : const Color(0xFF0052D9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 中间计数
            Text(
              listContext.displayText,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFA6A6A6),
              ),
            ),
            // 下一个按钮
            Expanded(
              child: GestureDetector(
                onTap: isLast
                    ? null
                    : () {
                        ref
                            .read(leadDetailProvider.notifier)
                            .goToNext();
                      },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '下一个',
                        style: TextStyle(
                          fontSize: 13,
                          color: isLast
                              ? const Color(0xFFDCDCDC)
                              : const Color(0xFF0052D9),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: isLast
                            ? const Color(0xFFDCDCDC)
                            : const Color(0xFF0052D9),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
