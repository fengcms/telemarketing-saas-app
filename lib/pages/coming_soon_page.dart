/// 功能开发中占位页面
///
/// 用于尚未完成的页面路由占位，显示"功能开发中"提示。
/// 当对应功能页面开发完成后，替换此占位。
///
/// 当前使用场景：
/// - 快捷入口"通话记录"跳转目标
library;

import 'package:flutter/material.dart';

/// 功能开发中占位页面
///
/// 用于尚未完成的页面路由占位，显示"功能开发中"提示。
/// 当对应功能页面开发完成后，替换此占位。
///
/// 当前使用场景：
/// - 快捷入口"通话记录"跳转目标
class ComingSoonPage extends StatelessWidget {
  final String featureName;

  const ComingSoonPage({super.key, this.featureName = '该功能'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(featureName),
        backgroundColor: const Color(0xFF0052D9),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction,
                size: 64, color: Color(0xFFA6A6A6)),
            const SizedBox(height: 16),
            Text(
              '功能开发中',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4E5969),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              featureName,
              style: const TextStyle(fontSize: 14, color: Color(0xFFA6A6A6)),
            ),
          ],
        ),
      ),
    );
  }
}
