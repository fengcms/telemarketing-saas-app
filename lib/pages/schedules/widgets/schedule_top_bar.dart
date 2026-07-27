/// 日程列表顶部蓝块（仅 TM/TA 视角渲染；员工视角由页面用 AppBar 居中标题）
///
/// 对齐线索页 `LeadsTopBar`：
/// - 左侧：视角切换胶囊「我的日程 | 团队日程」(AppScopeSegmented)
/// - 右侧：团队视角下「成员选择」图标按钮（点开抽屉选人，含角色）
///
/// 按需求：统计徽标（今日待办/逾期）已移除；成员选择态由列表页下发。
library;

import 'package:flutter/material.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';
import 'package:telemarketing_app/widgets/app_scope_segmented.dart';

/// 日程列表顶部导航栏（TM/TA 视角）
class ScheduleTopBar extends StatelessWidget {
  /// 是否可切换团队视角（TM/TA 为 true，员工为 false）
  final bool canTeam;

  /// 当前视角 value（'mine' / 'team'）
  final String currentScope;

  /// 视角切换回调
  final ValueChanged<String> onScopeChanged;

  /// 团队视角下当前选中的成员 id（null = 全部成员）；非团队视角传 null
  final String? selectedOwnerId;

  /// 选中成员的颜色圆点（null 表示"全部成员"）
  final Color? selectedOwnerColor;

  /// 团队视角下打开成员选择抽屉的回调；非团队视角传 null
  final VoidCallback? onPickOwner;

  const ScheduleTopBar({
    super.key,
    required this.canTeam,
    required this.currentScope,
    required this.onScopeChanged,
    this.selectedOwnerId,
    this.selectedOwnerColor,
    this.onPickOwner,
  });

  bool get _isTeam => currentScope == 'team';

  @override
  Widget build(BuildContext context) {
    final showPicker = _isTeam && onPickOwner != null;
    return Container(
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
      child: Column(
        children: [
          // 填满状态栏高度
          SizedBox(height: MediaQuery.of(context).padding.top),
          SizedBox(
            height: 56,
            child: Row(
              children: [
                if (canTeam)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: AppScopeSegmented(
                      options: const [
                        ScopeOption('mine', '我的日程'),
                        ScopeOption('team', '团队日程'),
                      ],
                      currentValue: currentScope,
                      onChanged: onScopeChanged,
                    ),
                  ),
                const Spacer(),
                if (showPicker)
                  _OwnerIconButton(
                    onTap: onPickOwner!,
                    selected: selectedOwnerId != null,
                    selectedColor: selectedOwnerColor,
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 成员选择图标按钮（团队视角专用，对齐线索页筛选/排序按钮样式）
class _OwnerIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool selected;
  final Color? selectedColor;

  const _OwnerIconButton({
    required this.onTap,
    this.selected = false,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(
              selected ? Icons.person : Icons.person_outline,
              size: 22,
              color: Colors.white,
            ),
            if (selected && selectedColor != null)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: BrandColors.primary, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
