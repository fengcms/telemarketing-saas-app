/// 各 Material 3 组件的主题覆写
///
/// 目标：在 M3 交互框架下，使组件视觉风格贴近 TDesign Flutter。
/// 从 TDesign 0.2.7 源码中提取的关键设计 token：
///   - 按钮圆角 = 6px（radiusDefault）
///   - Light 按钮 = 浅品牌色底(F2F3FF) + 品牌色文字(0052D9)
///   - 默认按钮 = 灰色底(E8E8E8) + 深色文字(181818)
///   - 文字按钮 = 透明底 + 品牌色文字
///   - 输入框 = 灰底填充(F3F3F3) + 6px 圆角
///   - 视觉密度 = 紧凑
library;

import 'package:flutter/material.dart';
import 'color_scheme.dart';

/// TDesign 设计 token 常数
abstract final class TdRadius {
  TdRadius._();

  /// 默认圆角（按钮、输入框、卡片默认）
  static const double button = 6;
  static const double card = 6;
  static const double dialog = 8;
  static const double input = 6;
  static const double snackbar = 6;
  static const double sheet = 12;
}

/// 组件级主题覆写（与 TDesign 设计对齐）
const ComponentTokens componentTokens = ComponentTokens._();

class ComponentTokens {
  const ComponentTokens._();

  // ── 按钮 ──

  /// FilledButton = TDesign primary 填充按钮
  /// bg: brandColor7(#0052D9), text: white, radius: 6px
  FilledButtonThemeData get filledButton => FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TdRadius.button),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      );

  /// FilledButton.tonal = TDesign light 填充按钮
  /// bg: brandColor1(#F2F3FF), text: brandColor7(#0052D9), radius: 6px
  /// 对应项目中原 `TDButton(theme: TDButtonTheme.light)`
  FilledButtonThemeData get tonalButton => FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BrandColors.primarySurface, // #F2F3FF
          foregroundColor: BrandColors.primary, // #0052D9
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TdRadius.button),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  /// TextButton = TDesign text 文字按钮
  /// 透明底 + 品牌色文字
  TextButtonThemeData get textButton => TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          foregroundColor: BrandColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  // ── 输入框 ──

  /// 输入框 = 白底 + 灰色边框(#E7E7E7) + 6px 圆角
  /// 聚焦时：品牌色边框(#0052D9, 1.5px)
  InputDecorationTheme get inputDecoration => InputDecorationTheme(
        filled: true,
        fillColor: BrandColors.surfaceContainer,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TdRadius.input),
          borderSide: const BorderSide(color: BrandColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TdRadius.input),
          borderSide: const BorderSide(color: BrandColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TdRadius.input),
          borderSide: const BorderSide(color: BrandColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TdRadius.input),
          borderSide: const BorderSide(color: BrandColors.error, width: 1),
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: BrandColors.textDisabled,
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: BrandColors.textSecondary,
        ),
        isDense: true,
      );

  // ── 卡片 ──

  /// 卡片 = TDesign card 白底 + 细边框 + 6px 圆角
  CardThemeData get card => CardThemeData(
        elevation: 0,
        color: BrandColors.surfaceContainer,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TdRadius.card),
          side: const BorderSide(color: BrandColors.border, width: 0.5),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      );

  // ── 列表项 ──

  /// 列表项 = 对齐 TDesign Cell
  /// 左图标 20px + 标题 16px + 右箭头 + 分割线
  ListTileThemeData get listTile => ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        minLeadingWidth: 20,
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: BrandColors.textPrimary,
        ),
        subtitleTextStyle: const TextStyle(
          fontSize: 14,
          color: BrandColors.textSecondary,
        ),
        iconColor: BrandColors.textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      );

  // ── 导航栏 ──

  /// AppBar = TDesign TDNavBar
  /// 品牌色底(#0052D9) + 白色标题(18px Medium) + 居中
  AppBarTheme get appBar => const AppBarTheme(
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 24,
        ),
      );

  /// 底部导航 = TDesign TabBar
  /// 白底 + 品牌色选中 + 灰色未选中 + 11px 字号
  BottomNavigationBarThemeData get bottomNav => BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: BrandColors.surfaceContainer,
        selectedItemColor: BrandColors.primary,
        unselectedItemColor: BrandColors.textSecondary,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        enableFeedback: true,
      );

  // ── 反馈 ──

  /// SnackBar = TDesign TDToast
  /// 浮动 + 6px 圆角
  SnackBarThemeData get snackBar => SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TdRadius.snackbar),
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
      );

  // ── 弹窗 ──

  /// Dialog = TDesign TDDialog
  DialogThemeData get dialog => DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TdRadius.dialog),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: BrandColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: BrandColors.textPrimary,
        ),
      );

  /// BottomSheet = TDesign 底部滑出层
  BottomSheetThemeData get bottomSheet => BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(TdRadius.sheet)),
        ),
        elevation: 2,
        modalBackgroundColor: BrandColors.surfaceContainer,
        modalBarrierColor: const Color(0x52000000),
      );

  // ── 分隔线 ──

  /// Divider = TDesign 细灰线(#E7E7E7)
  DividerThemeData get divider => const DividerThemeData(
        space: 0,
        thickness: 0.5,
        color: BrandColors.border,
        indent: 0,
        endIndent: 0,
      );

  // ── 复选框 ──（项目已用 Material 替代 TDCheckbox）

  CheckboxThemeData get checkbox => CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BrandColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: const BorderSide(color: BrandColors.border),
      );

  // ── 浮动操作按钮 ──

  FloatingActionButtonThemeData get fab => FloatingActionButtonThemeData(
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const CircleBorder(),
      );

  // ── 底部动作条菜单 ──

  PopupMenuThemeData get popupMenu => PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TdRadius.card),
        ),
        elevation: 3,
      );

  // ── 进度指示器 ──

  ProgressIndicatorThemeData get progressIndicator =>
      const ProgressIndicatorThemeData(
        color: BrandColors.primary,
        linearMinHeight: 3,
      );

  /// 将所有组件主题合并到 [ThemeData]
  ThemeData mergeInto(ThemeData theme) {
    return theme.copyWith(
      filledButtonTheme: filledButton,
      textButtonTheme: textButton,
      inputDecorationTheme: inputDecoration,
      cardTheme: card,
      listTileTheme: listTile,
      appBarTheme: appBar,
      bottomNavigationBarTheme: bottomNav,
      snackBarTheme: snackBar,
      dialogTheme: dialog,
      bottomSheetTheme: bottomSheet,
      dividerTheme: divider,
      checkboxTheme: checkbox,
      floatingActionButtonTheme: fab,
      popupMenuTheme: popupMenu,
      progressIndicatorTheme: progressIndicator,
    );
  }
}
