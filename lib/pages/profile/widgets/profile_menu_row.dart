/// 个人中心 - 功能 / 团队入口分组与列表项
///
/// [ProfileMenuGroup] 提供"标题 + 白色圆角卡片"，并在子项间插入左缩进分割线；
/// [ProfileMenuRow] 为单条入口（图标 + 标题 + 右箭头）。
library;

import 'package:flutter/material.dart';

/// 入口分组容器（标题 + 白色圆角卡片）
///
/// [title] 分组标题（如"功能""团队"）
/// [children] 入口行列表，行间自动插入左缩进 56px 的分割线
class ProfileMenuGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ProfileMenuGroup({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title.isNotEmpty) ...[
          _sectionTitle(title),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  const Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 0,
                    color: Color(0xFFE7E7E7),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 分组标题（gray-12，16px Medium，左对齐）
  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF181818),
        ),
      );
}

/// 单条入口（图标 + 标题 + 右箭头）
///
/// [icon] 左图标（20px，默认 gray-6）
/// [title] 标题（16px，默认 gray-12）
/// [onTap] 点击回调（跳转对应子页占位）
/// [color] 自定义图标与文字颜色（如退出登录用红色）；默认跟随主题灰阶
class ProfileMenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const ProfileMenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? const Color(0xFF181818);
    final sub = color ?? const Color(0xFFA6A6A6);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: sub),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: fg,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: sub,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
