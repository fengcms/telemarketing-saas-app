/// 底部抽屉通用标题行（拖拽手柄 + 标题 + 关闭按钮）
library;

import 'package:flutter/material.dart';

/// 底部抽屉通用标题行
class SheetHeader extends StatelessWidget {
  final String title;

  const SheetHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFDCDCDC),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF181818),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.close, size: 20, color: Color(0xFFA6A6A6)),
        ),
      ],
    );
  }
}
