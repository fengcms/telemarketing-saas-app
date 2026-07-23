/// 线索列表页骨架屏组件
library;

import 'package:flutter/material.dart';

/// 骨架屏灰块
class LeadSkBlock extends StatelessWidget {
  final double width;
  final double height;
  const LeadSkBlock({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
