/// 线索列表顶部栏：左侧 Tab 切换 + 右侧筛选/排序按钮
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';
import 'package:telemarketing_app/providers/lead_list_provider.dart';

/// 线索列表顶部导航栏
///
/// 布局：
/// - 开启公海可领（showPublicTab=true）：左侧「我的线索 / 公海线索」双 Tab + 右侧筛选/排序
/// - 关闭公海可领（showPublicTab=false）：
///   - 员工视角：居中标题「线索」+ 右侧筛选/排序
///   - 经理/管理员视角：左侧「共 X 条」统计 + 居中标题「线索」+ 右侧筛选/排序
///     （「共 X 条」原在标题栏下方独立占一行，现移入顶栏左上角，节省一行空间）
class LeadsTopBar extends StatelessWidget {
  final LeadListState state;
  final int activeTab;
  final bool showPublicTab;
  final bool isManager;
  final int total;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onShowSort;
  final VoidCallback onShowFilter;

  const LeadsTopBar({
    super.key,
    required this.state,
    required this.activeTab,
    this.showPublicTab = false,
    this.isManager = false,
    this.total = 0,
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
            // 经理/管理员额外在左侧显示「共 X 条」统计
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
                    children: [
                      if (isManager)
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            '共 ${_formatNum(total)} 条',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xB3FFFFFF),
                            ),
                          ),
                        ),
                      const Spacer(),
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

  /// 数字格式化：>=1万 显示「x.x万」，否则每三位加逗号
  String _formatNum(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}万';
    final str = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}
