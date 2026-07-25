/// 底部操作栏组件
///
/// 统一底部操作栏的布局与样式，支持两种模式：
///   1. [AppActionBar.submit] — 全宽主色提交按钮（弹窗/抽屉底部）
///   2. [AppActionBar] — 横向多按钮操作行（详情页底部）
///
/// 样式对齐：
///   - submit 模式 → 跟进面板提交按钮（48px 高、品牌色、支持 loading）
///   - bar 模式 → 线索详情/日程详情底部操作行
///
/// ── 使用示例 ──
/// ```dart
/// // 单按钮提交（含 loading）
/// AppActionBar.submit(
///   text: _isEdit ? '保存' : '创建日程',
///   loading: _isSubmitting,
///   enabled: isValid,
///   onPressed: _submit,
/// )
///
/// // 多按钮操作行
/// AppActionBar(
///   actions: [
///     ActionItem(text: '跟进', type: ActionType.text, icon: Icons.replay, onTap: _onFollow),
///     ActionItem(text: '日程', type: ActionType.text, icon: Icons.calendar_today, onTap: _onSchedule),
///     ActionItem(text: '编辑', type: ActionType.text, icon: Icons.edit, onTap: _onEdit),
///   ],
/// )
///
/// // 带主次层级的多按钮操作行
/// AppActionBar(
///   actions: [
///     ActionItem(text: '取消日程', type: ActionType.light, onTap: _onCancel),
///     ActionItem(text: '拨号', type: ActionType.light, icon: Icons.call, onTap: _onDial),
///     ActionItem(text: '标记完成', type: ActionType.primary, onTap: _onComplete),
///   ],
/// )
/// ```
library;

import 'package:flutter/material.dart';
import '../theme/color_scheme.dart';

/// 操作项类型
enum ActionType {
  /// 品牌色填充按钮（主操作）
  primary,

  /// 浅色填充按钮（次要操作，浅蓝底）
  light,

  /// 文字按钮（最弱层级，图标+文字）
  text,
}

/// 操作项数据模型
///
/// 用于 [AppActionBar] 的多按钮操作行模式。
class ActionItem {
  /// 按钮文字
  final String text;

  /// 可选图标（仅 light/text 类型显示）
  final IconData? icon;

  /// 按钮类型
  final ActionType type;

  /// 点击回调（为 null 时按钮禁用）
  final VoidCallback? onTap;

  /// 是否加载中（仅 primary 类型支持）
  final bool loading;

  const ActionItem({
    required this.text,
    this.icon,
    this.type = ActionType.text,
    this.onTap,
    this.loading = false,
  });
}

/// 底部操作栏
class AppActionBar extends StatelessWidget {
  /// 多按钮操作行
  ///
  /// [actions] 中的按钮等宽排列，支持 primary / light / text 三种层级。
  final List<ActionItem>? actions;

  /// 提交按钮文字（submit 模式）
  final String? text;

  /// 提交按钮是否加载中（submit 模式）
  final bool loading;

  /// 提交按钮是否可用（submit 模式，默认 true）
  final bool enabled;

  /// 提交按钮点击回调（submit 模式）
  final VoidCallback? onPressed;

  /// 单按钮提交模式
  ///
  /// 全宽主色按钮，48px 高，支持 loading 态。
  /// 用于各种弹窗/抽屉的底部提交按钮。
  const AppActionBar.submit({
    super.key,
    required this.text,
    this.loading = false,
    this.enabled = true,
    required this.onPressed,
  })  : actions = null;

  /// 多按钮操作行模式
  ///
  /// 横向排列多个按钮，等宽，支持图标+文字。
  /// 提供白底 + 顶部细边框容器。
  const AppActionBar({
    super.key,
    required this.actions,
  })  : text = null,
        loading = false,
        enabled = true,
        onPressed = null;

  @override
  Widget build(BuildContext context) {
    if (actions != null) {
      return _buildBar();
    }
    return _buildSubmit();
  }

  /// 全宽提交按钮
  Widget _buildSubmit() {
    final canTap = enabled && !loading && onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: canTap ? onPressed : null,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(text!),
      ),
    );
  }

  /// 多按钮操作行
  Widget _buildBar() {
    return Container(
      height: 44,
      color: BrandColors.surfaceContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: actions!.map(_buildAction).toList(),
      ),
    );
  }

  Widget _buildAction(ActionItem item) {
    final isDisabled = item.onTap == null;

    switch (item.type) {
      case ActionType.primary:
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              height: 36,
              child: FilledButton(
                onPressed: item.onTap,
                child: item.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(item.text, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ),
        );

      case ActionType.light:
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              height: 36,
              child: FilledButton.tonal(
                onPressed: item.onTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.icon != null) ...[
                      Icon(item.icon, size: 18),
                      const SizedBox(width: 4),
                    ],
                    Text(item.text, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        );

      case ActionType.text:
        return GestureDetector(
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null)
                  Icon(
                    item.icon,
                    size: 18,
                    color: isDisabled
                        ? BrandColors.textDisabled
                        : BrandColors.primary,
                  ),
                if (item.icon != null) const SizedBox(width: 6),
                Text(
                  item.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDisabled
                        ? BrandColors.textDisabled
                        : BrandColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}
