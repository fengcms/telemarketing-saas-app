/// 详情页信息行（图标 + 标签 + 值）
///
/// ── 使用示例 ──
/// ```dart
/// AppInfoRow(
///   icon: Icons.business,
///   label: '公司',
///   value: '某某科技有限公司',
/// )
/// ```
library;

import 'package:flutter/material.dart';
import '../theme/color_scheme.dart';

/// 详情页信息行
class AppInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const AppInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: BrandColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: BrandColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: BrandColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
