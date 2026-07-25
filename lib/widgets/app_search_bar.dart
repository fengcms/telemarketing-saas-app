/// 统一搜索栏组件
///
/// 一个带搜索图标、输入框、一键清空按钮和搜索按钮的复合搜索栏。
/// 与项目 M3 主题（lib/theme/）绑定，颜色/字体自动跟随主题配置，
/// 不硬编码色值，确保全局改主题时搜索栏风格自动统一。
///
/// ── 布局结构 ──
/// 白色背景容器 → 灰底药丸形输入区（40px 高、20px 圆角）
///   └── GestureDetector（点击任意位置聚焦输入框）
///       └── Row
///           ├── 🔍 搜索图标（Icons.search, 20px, 灰色）
///           ├── TextField（14px, 无边框, isDense）
///           ├── [×] 清空按钮（有文字时显示，点击清空并触发 onSearch('')）
///           └── [搜索] 按钮（品牌色底 + 白色文字，12px）
///
/// ── 聚焦/失焦行为 ──
/// - 点击搜索图标区 / 输入框两侧留白 → 自动聚焦 TextField
/// - 聚焦时：整个灰底药丸形区域显示品牌色圆角边框（1.5px）
/// - 失焦时：边框消失，恢复原灰底
///
/// ── 搜索交互约定 ──
/// - 按回车 / 点搜索按钮 → 调用 onSearch(当前输入内容)
/// - 点清空按钮 → 清空输入并调用 onSearch('')（区别于只清空不搜索）
/// - 输入内容变化 → 仅切换清空按钮显隐，不自动触发搜索（避免每字请求）
/// - 外部可通过 controller 读写输入值
///
/// ── 使用示例 ──
/// ```dart
/// // 线索列表搜索
/// AppSearchBar(
///   controller: _searchCtrl,
///   onSearch: _doSearch,
///   hintText: '搜索线索姓名/电话/公司',
/// )
///
/// // 通话记录手机号搜索
/// AppSearchBar(
///   controller: _searchCtrl,
///   onSearch: _doSearch,
///   hintText: '搜索手机号',
///   keyboardType: TextInputType.phone,
/// )
///
/// // 带自定义按钮文字的搜索
/// AppSearchBar(
///   controller: _searchCtrl,
///   onSearch: _onSearch,
///   hintText: '搜索客户',
///   searchButtonText: '查找',
/// )
/// ```
///
/// ── 替换旧组件说明 ──
/// 本组件意在统一线索/通话记录/客户列表三处搜索栏。
/// 旧搜索栏共性问题（本组件已修复）：
/// - 颜色硬编码（改主题需改多处）
/// - 清空按钮图标不一致（close vs close_circle）
/// - 清空后未触发搜索回调（留了旧数据不刷新）
/// - 点击图标/留白处不聚焦输入框
/// - 聚焦无视觉反馈
/// - TDIcons 引用（需一并迁移到 Icons）
library;

import 'package:flutter/material.dart';
import '../theme/color_scheme.dart';

/// 统一搜索栏
class AppSearchBar extends StatefulWidget {
  /// 输入框控制器（外部持有，用于读取输入值或在外部清空）
  final TextEditingController controller;

  /// 触发搜索回调
  ///
  /// - 用户按回车或点搜索按钮时：传入当前输入内容
  /// - 用户点清空按钮时：传空字符串 `''`
  /// - 外部需根据传入值决定发请求与否（传空串应复位列表到初始态）
  final ValueChanged<String> onSearch;

  /// 输入框占位提示文字
  ///
  /// 如 `'搜索线索姓名/电话/公司'`、`'搜索手机号'`。
  final String hintText;

  /// 键盘类型（默认为普通文本）
  ///
  /// - 手机号搜索 → `TextInputType.phone`
  /// - 常规搜索 → `TextInputType.text`（默认）
  final TextInputType? keyboardType;

  /// 搜索按钮文字（默认 `'搜索'`）
  final String searchButtonText;

  const AppSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.hintText,
    this.keyboardType,
    this.searchButtonText = '搜索',
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  /// 用于跟踪 TextField 聚焦状态，控制整块灰底圆角的聚焦边框
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});
  void _onFocusChanged() => setState(() {});

  /// 点击灰底区的任意位置（图标/留白）都聚焦到 TextField
  void _requestFocus() => _focusNode.requestFocus();

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    final isFocused = _focusNode.hasFocus;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: GestureDetector(
        onTap: _requestFocus,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: BrandColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: isFocused
                ? Border.all(color: BrandColors.primary, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              // ── 搜索图标 ──
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(
                  Icons.search,
                  size: 20,
                  color: BrandColors.textSecondary,
                ),
              ),
              const SizedBox(width: 2),

              // ── 输入框 ──
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  onSubmitted: widget.onSearch,
                  textInputAction: TextInputAction.search,
                  keyboardType: widget.keyboardType ?? TextInputType.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: BrandColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: BrandColors.textDisabled,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),

              // ── 清空按钮（有文字时显示）──
              if (hasText)
                GestureDetector(
                  onTap: () {
                    widget.controller.clear();
                    widget.onSearch('');
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: BrandColors.textSecondary,
                    ),
                  ),
                ),

              // ── 搜索按钮 ──
              GestureDetector(
                onTap: () => widget.onSearch(widget.controller.text),
                child: Container(
                  height: 34,
                  margin: const EdgeInsets.only(top: 3, right: 3, bottom: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: BrandColors.primary,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.searchButtonText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
