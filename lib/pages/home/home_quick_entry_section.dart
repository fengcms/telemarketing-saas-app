/// 首页快捷入口 Section
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/providers/home_provider.dart';
import 'package:telemarketing_app/widgets/app_card_section.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';
import 'package:telemarketing_app/pages/coming_soon_page.dart';

/// 快捷入口卡片 Section
class HomeQuickEntrySection extends ConsumerWidget {
  final HomePageState state;
  final VoidCallback? onSwitchToLeads;

  const HomeQuickEntrySection({
    super.key,
    required this.state,
    this.onSwitchToLeads,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCardSection(
      title: '快捷入口',
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _buildQuickEntryCard(
                icon: Icons.assignment,
                title: '我的线索',
                subtitle:
                    state.stats != null ? '${state.stats!.myLeadsTotal} 条' : null,
                onTap: () => onSwitchToLeads?.call(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickEntryCard(
                icon: Icons.call,
                title: '通话记录',
                subtitle: null,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const ComingSoonPage(featureName: '通话记录'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickEntryCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: BrandColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: BrandColors.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3C3C3C),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: BrandColors.textDisabled,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
