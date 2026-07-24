/// 个人中心 - 用户信息卡片
///
/// 展示头像（姓名首字）、姓名、角色标签、邮箱、所属租户。
/// 头像/姓名/角色/邮箱/租户均来自本地登录缓存或 profile 接口，无独立统计依赖。
library;

import 'package:flutter/material.dart';

/// 个人中心用户信息卡片
///
/// [name] 姓名（空时显示默认图标 + "未设置姓名"）
/// [roleLabel] 角色中文标签（空时隐藏标签）
/// [email] 邮箱（空时隐藏该行）
/// [tenantName] 所属租户名（空时隐藏该行）
class ProfileUserCard extends StatelessWidget {
  final String name;
  final String roleLabel;
  final String email;
  final String tenantName;

  const ProfileUserCard({
    super.key,
    required this.name,
    required this.roleLabel,
    required this.email,
    required this.tenantName,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.isNotEmpty ? name : '未设置姓名';
    final initial = name.isNotEmpty ? name[0] : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF0052D9),
            child: initial.isNotEmpty
                ? Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.person, size: 32, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF181818),
                        ),
                      ),
                    ),
                    if (roleLabel.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _roleTag(roleLabel),
                    ],
                  ],
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFA6A6A6),
                    ),
                  ),
                ],
                if (tenantName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    tenantName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFA6A6A6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 角色标签（圆角小标签，brand-1 底 brand-7 字）
  Widget _roleTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0052D9),
        ),
      ),
    );
  }
}
