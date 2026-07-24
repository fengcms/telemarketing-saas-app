/// 客户卡片
///
/// 设计文档 §3.4。四行：姓名(半粗) + 右对齐等级标签 /
/// 电话 / 公司(空则隐藏) / 转化日期。
/// 等级标签配色：normal=success(#2BA471) / important=brand(#0052D9) /
/// vip=warning(#E37318) / lost=error(#D54941)，背景 10% 透明度。
/// 点击时跳对应线索详情（不单独开发客户详情页）。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/models/customer.dart';

/// 客户卡片
class CustomerCard extends StatelessWidget {
  /// 客户数据
  final Customer customer;

  /// 点击回调（跳对应线索详情）
  final VoidCallback? onTap;

  const CustomerCard({super.key, required this.customer, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final hasCompany = (c.company ?? '').isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：姓名 + 等级标签
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF181818),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (c.hasLevel) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.levelBgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      c.levelLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: c.levelTextColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            // 第二行：电话
            Text(
              c.displayPhone,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7A90)),
            ),
            if (hasCompany) ...[
              const SizedBox(height: 4),
              // 第三行：公司
              Text(
                c.company!,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7A90)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            // 第四行：转化日期（60% 透明度）
            Text(
              c.convertedAtLabel,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0x996B7A90),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
