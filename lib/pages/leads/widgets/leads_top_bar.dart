/// 线索列表顶部栏：左侧 Tab 切换 + 右侧筛选/排序按钮
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';
import 'package:telemarketing_app/providers/lead_list_provider.dart';

/// 线索列表顶部导航栏
///
/// 布局：
/// - 开启公海可领（showPublicTab=true）：左侧「我的线索 / 公海线索」双 Tab + 右侧筛选/排序
/// - 关闭公海可领（showPublicTab=false）：居中标题「线索」+ 右侧筛选/排序
///   （与「我的」页标题居中风格一致，但保留筛选/排序功能，经理/管理员仍可筛选排序）
class LeadsTopBar extends StatelessWidget {
  final LeadListState state;
  final int activeTab;
  final bool showPublicTab;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onShowSort;
  final VoidCallback onShowFilter;

  const LeadsTopBar({
    super.key,
    required this.state,
    required this.activeTab,
    this.showPublicTab = false,
    required this.onTabChanged,
    required this.onShowSort,
    required this.onShowFilter,
  });

  bool get _isPublic => activeTab == 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: BrandColors.primary,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showPublicTab) ...[
            _buildTabItem('我的线索', 0),
            _buildTabItem('公海线索', 1),
            const Spacer(),
            _buildFilterButton(),
            _buildSortButton(),
          ] else
            // 关闭公海可领：居中标题「线索」+ 右侧筛选/排序（叠加布局，标题真正居中）
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Center(
                    child: Text(
                      '线索',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildFilterButton(),
                      _buildSortButton(),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int tabIndex) {
    final selected = activeTab == tabIndex;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: GestureDetector(
          onTap: () => onTabChanged(tabIndex),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.white24,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? BrandColors.primary : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: _isPublic ? null : onShowFilter,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 4),
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.filter_list,
              size: 22,
              color: _isPublic ? Colors.white38 : Colors.white,
            ),
            if (!_isPublic && state.hasActiveFilters)
              Positioned(
                right: -4,
                top: -2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: BrandColors.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${state.activeFilterCount}',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return GestureDetector(
      onTap: onShowSort,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 8),
        alignment: Alignment.center,
        child: const Icon(Icons.sort_rounded, size: 22, color: Colors.white),
      ),
    );
  }
}
