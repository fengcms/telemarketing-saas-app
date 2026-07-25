/// 统一底部抽屉
///
/// 封装 [showModalBottomSheet] 的重复样板，提供标准布局：
/// 拖拽手柄（居中） + 标题行 + 关闭按钮 + 可滚动内容区 + 键盘适配。
///
/// 样式对齐跟进面板/日程表单等现有底部抽屉。
///
/// ── 使用示例 ──
/// ```dart
/// // 基本用法
/// final result = await AppBottomSheet.show<bool>(
///   context: context,
///   title: '新增跟进记录',
///   child: Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       AppFormSection(
///         label: '跟进内容',
///         required: true,
///         child: TextField(maxLines: 4, ...),
///       ),
///       const SizedBox(height: 24),
///       AppActionBar.submit(
///         text: '提交跟进',
///         onPressed: _submit,
///       ),
///     ],
///   ),
/// );
///
/// // 返回结果
/// if (result == true) {
///   ScaffoldMessenger.of(context).showSnackBar(...);
/// }
/// ```
///
/// ── 布局结构 ──
/// showModalBottomSheet(backgroundColor: transparent)
///   └── Container(white, rounded top)
///       └── Column(mainAxisSize: min)
///           ├── SizedBox(height: 12)
///           ├── ━━━━━ 拖拽手柄（居中，32x4, 圆角2）
///           ├── SizedBox(height: 16)
///           ├── Row
///           │   ├── Text(title, 18px, w600)
///           │   └── ✕ 关闭按钮
///           ├── Divider (浅灰)
///           └── Flexible → SingleChildScrollView
///               └── child + 键盘底部间距
library;

import 'package:flutter/material.dart';

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

/// 抽屉内部内容（分离为 StatefulWidget 以获取底部安全区）
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCDCDC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Spacer(),
                // 标题（居中）
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181818),
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
                      color: Color(0xFFA6A6A6),
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
                // 键盘弹起时自动增加底部间距，避免被键盘遮挡
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
