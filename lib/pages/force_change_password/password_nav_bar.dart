/// 强改密页导航栏
library;

import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 设置新密码页面顶部导航栏（返回按钮 + 标题）
class PasswordNavBar extends StatelessWidget {
  final VoidCallback onBack;

  const PasswordNavBar({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Icon(TDIcons.chevron_left,
                  size: 24, color: Color(0xFF181818)),
            ),
          ),
          const Expanded(
            child: Text(
              '设置新密码',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF181818),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
