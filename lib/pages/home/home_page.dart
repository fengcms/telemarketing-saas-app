import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

/// 首页（占位版本）
///
/// 当前仅用于验证登录流程是否完整。
/// 功能：显示登录用户信息 + 退出按钮。
///
/// 设计文档参考：docs/design/page-design/对应首页设计文档（待补充）
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('电销工作台'),
        backgroundColor: const Color(0xFF0052D9),
        foregroundColor: Colors.white,
        actions: [
          // 退出按钮
          TextButton.icon(
            onPressed: () => _onLogout(context, ref),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('退出', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_in_talk, size: 64, color: Color(0xFF0052D9)),
            const SizedBox(height: 16),
            Text(
              '欢迎，${user?.name ?? "用户"}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7A90)),
            ),
            const SizedBox(height: 4),
            Text(
              '角色：${_roleName(user?.role ?? "")}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7A90)),
            ),
            const SizedBox(height: 32),
            const Text(
              '首页内容待开发',
              style: TextStyle(fontSize: 16, color: Color(0xFFA6A6A6)),
            ),
          ],
        ),
      ),
    );
  }

  /// 退出登录
  void _onLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('退出', style: TextStyle(color: Color(0xFFD54941))),
          ),
        ],
      ),
    );
  }

  String _roleName(String role) {
    switch (role) {
      case 'platform_super_admin':
        return '平台超管';
      case 'tenant_admin':
        return '租户管理员';
      case 'tenant_manager':
        return '租户经理';
      case 'tenant_employee':
        return '坐席';
      default:
        return role;
    }
  }
}
