/// 密码安全提示 + 密码规则说明组件
library;

import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 安全提示卡片（零状态）
class SecurityHint extends StatelessWidget {
  const SecurityHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  size: 24, color: Color(0xFF0052D9)),
              const SizedBox(width: 8),
              const Text(
                '安全提示',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00287A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '为了您的账号安全，请重新设置密码。设置完成后，请使用新密码重新登录。',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xB3003CAB),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// 密码规则说明
class PasswordRuleHint extends StatelessWidget {
  const PasswordRuleHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(TDIcons.info_circle,
            size: 14, color: Color(0xFFA6A6A6)),
        const SizedBox(width: 4),
        const Expanded(
          child: Text(
            '密码至少 8 位，且须同时包含字母和数字；'
            '建议包含大小写字母、数字和特殊字符',
            style: TextStyle(fontSize: 12, color: Color(0xFFA6A6A6)),
          ),
        ),
      ],
    );
  }
}
