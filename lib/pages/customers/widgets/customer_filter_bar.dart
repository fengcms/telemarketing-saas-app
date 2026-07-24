/// 客户列表「等级」筛选条
///
/// 设计文档 §3.3（按 api.md 实际枚举 normal/important/vip/lost）。
/// 等级通栏分段控件（全部/普通/重要/VIP/流失），5 项等宽占满 100%。
library;

import 'package:flutter/material.dart';

/// 等级筛选项（code 为 null 表示「全部」）
const List<({String? code, String label})> _levelFilters = [
  (code: null, label: '全部'),
  (code: 'normal', label: '普通'),
  (code: 'important', label: '重要'),
  (code: 'vip', label: 'VIP'),
  (code: 'lost', label: '流失'),
];

/// 等级横滚筛选条
class CustomerFilterBar extends StatelessWidget {
  /// 当前选中的等级（null = 全部）
  final String? selectedLevel;

  /// 切换等级筛选
  final ValueChanged<String?> onLevelChanged;

  const CustomerFilterBar({
    super.key,
    required this.selectedLevel,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(
        children: _levelFilters.map((f) {
          final selected = f.code == selectedLevel;
          return Expanded(
            child: GestureDetector(
              onTap: () => onLevelChanged(f.code),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFF2F3FF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  f.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w500 : FontWeight.normal,
                    color: selected
                        ? const Color(0xFF0052D9)
                        : const Color(0xFF6B7A90),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
