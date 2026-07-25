/// 线索列表顶部栏：左侧 Tab 切换 + 右侧筛选/排序按钮
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/providers/lead_list_provider.dart';

/// 线索列表顶部导航栏
///
/// 布局：左侧「我的线索 / 公海线索」Tab 切换 + 右侧筛选按钮 + 排序按钮。
/// - `showPublicTab=false` 时仅显示"我的线索"标题
/// - 公海 Tab 下筛选按钮置灰禁用
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
        color: Color(0xFF0052D9),
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
            // ── 双 Tab 切换（TE + allowSelfClaim） ──
            _buildTabItem('我的线索', 0),
            _buildTabItem('公海线索', 1),
          ] else ...[
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                '我的线索',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          const Spacer(),
          // ── 筛选按钮（公海时置灰禁用） ──
          GestureDetector(
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
                    color: _isPublic
                        ? Colors.white30
                        : state.hasActiveFilters
                            ? Colors.white70
                            : Colors.white,
                  ),
                  if (!_isPublic && state.hasActiveFilters)
                    Positioned(
                      right: -4,
                      top: -2,
                      child: Container(
                        constraints: const BoxConstraints(
                            minWidth: 16, minHeight: 16),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD54941),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${state.activeFilterCount}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // ── 排序按钮 ──
          GestureDetector(
            onTap: onShowSort,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              alignment: Alignment.center,
              child: Icon(
                Icons.sort_rounded,
                size: 22,
                color: state.sortBy != '-updatedAt'
                    ? Colors.white70
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int tabIndex) {
    final selected = activeTab == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(tabIndex),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
