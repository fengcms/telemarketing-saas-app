/// 统一底部抽屉
///
/// 封装 [showModalBottomSheet] 的重复样板，提供标准布局：
/// 拖拽手柄（左侧） + 标题（居中） + 关闭按钮（右侧） + 可滚动内容 + 键盘适配。
///
/// 样式跟随 M3 主题（[BrandColors]/[TdRadius]），不硬编码色值。
///
/// ── 使用示例 ──
/// ```dart
/// final result = await AppBottomSheet.show<bool>(
///   context: context,
///   title: '新增跟进记录',
///   child: Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       AppFormSection(label: '跟进内容', required: true, child: TextField(...)),
///       const SizedBox(height: 24),
///       AppActionBar.submit(text: '提交跟进', onPressed: _submit),
///     ],
///   ),
/// );
/// ```
library;

import 'package:flutter/material.dart';
import '../theme/color_scheme.dart';
import '../theme/component_tokens.dart';

/// 拖拽手柄尺寸常数
const double _kDragHandleWidth = 32;
const double _kDragHandleHeight = 4;
const double _kDragHandleRadius = 2;

/// 统一底部抽屉
abstract final class AppBottomSheet {
  AppBottomSheet._();

  /// 显示统一底部抽屉
  ///
  /// [context] 用于 [showModalBottomSheet]
  /// [title] 抽屉标题文字
  /// [child] 抽屉主体内容（自动处理滚动与键盘适配）
  ///
  /// 返回类型 [T] 由 child 内部通过 [Navigator.pop] 传入。
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AppBottomSheetContent<T>(
        title: title,
        child: child,
      ),
    );
  }
}

/// 抽屉内部内容
class _AppBottomSheetContent<T> extends StatelessWidget {
  final String title;
  final Widget child;

  const _AppBottomSheetContent({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: BrandColors.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(TdRadius.sheet)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 标题栏（拖拽手柄 + 标题 + 关闭按钮，一行紧凑） ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                // 拖拽手柄（左侧）
                Container(
                  width: _kDragHandleWidth,
                  height: _kDragHandleHeight,
                  decoration: BoxDecoration(
                    color: BrandColors.textDisabled,
                    borderRadius: BorderRadius.circular(_kDragHandleRadius),
                  ),
                ),
                const Spacer(),
                // 标题（居中）
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // 关闭按钮（靠右）
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: BrandColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 内容（可滚动，带键盘间距，无分割线） ──
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                bottomInset + 16,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
