/// 线索列表页顶部导航栏
library;

import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:telemarketing_app/providers/lead_list_provider.dart';

/// 线索列表顶部导航栏：标题 + 排序按钮 + 筛选按钮
class LeadsTopBar extends StatelessWidget {
  final LeadListState state;
  final VoidCallback onShowSort;
  final VoidCallback onShowFilter;

  const LeadsTopBar({
    super.key,
    required this.state,
    required this.onShowSort,
    required this.onShowFilter,
  });

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
          const Spacer(),
          // 排序按钮
          GestureDetector(
            onTap: onShowSort,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 4),
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
          // 筛选按钮
          GestureDetector(
            onTap: onShowFilter,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              alignment: Alignment.center,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    TDIcons.filter,
                    size: 22,
                    color: state.hasActiveFilters
                        ? Colors.white70
                        : Colors.white,
                  ),
                  if (state.hasActiveFilters)
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
        ],
      ),
    );
  }
}
