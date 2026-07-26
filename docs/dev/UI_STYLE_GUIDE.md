# 电销工作台 APP — UI/UX 风格指南

> 本文档记录项目中已落地并验证的**视觉与交互模式**，供后续页面开发时参考。
> **新页面应遵循本指南中的组件和约定，确保全应用视觉一致。**
> 版本：v2.0（2026-07-25）— TDesign 全量迁移到 Material 3 后重写。

---

## 目录

1. [主题系统](#1-主题系统)
2. [色板与 BrandColors](#2-色板与-brandcolors)
3. [公共组件速查](#3-公共组件速查)
4. [页面布局](#4-页面布局)
5. [白卡片容器](#5-白卡片容器)
6. [表单与输入](#6-表单与输入)
7. [底部抽屉（AppBottomSheet）](#7-底部抽屉appbottomsheet)
8. [弹窗（AppDialog）](#8-弹窗appdialog)
9. [按钮](#9-按钮)
10. [底部操作栏（AppActionBar）](#10-底部操作栏appactionbar)
11. [标签选择器（TagChip）](#11-标签选择器tagchip)
12. [列表样式](#12-列表样式)
13. [设置页风格规范](#13-设置页风格规范)
14. [常用模式速记](#14-常用模式速记)

---

## 1. 主题系统

主题配置位于 `lib/theme/` 目录，入口函数 `buildBrandTheme()`。

### 1.1 使用方式

```dart
MaterialApp(
  theme: buildBrandTheme(),        // ← lib/theme/app_theme.dart
  locale: const Locale('zh'),      // ← showDatePicker 中文化
  localizationsDelegates: AppLocalizations.localizationsDelegates,
)
```

### 1.2 文件结构

```dart
lib/theme/
├── color_scheme.dart       // BrandColors 常量 + M3 ColorScheme
├── text_theme.dart         // 自定义字号/字重
├── component_tokens.dart   // FilledButton / Input / SnackBar / Card 等主题覆写
└── app_theme.dart          // 三部合一入口
```

> **规则**：任何页面**禁止**在文件顶部定义自己的颜色常量。使用 `BrandColors.*` 或 `Theme.of(context).colorScheme.*`。

---

## 2. 色板与 BrandColors

### 2.1 BrandColors 常量

`lib/theme/color_scheme.dart` 中定义的只读常量，全项目所有页面共用：

| 常量 | 色值 | 用途 | 替代旧硬编码 |
|------|:----:|------|:-----------:|
| `BrandColors.primary` | `#0052D9` | 品牌蓝：主按钮/链接/选中态 | `Color(0xFF0052D9)` |
| `BrandColors.surface` | `#F3F3F3` | 页面背景灰 | `Color(0xFFF3F3F3)` |
| `BrandColors.surfaceContainer` | `#FFFFFF` | 卡片/抽屉/输入框底白 | `Colors.white` |
| `BrandColors.textPrimary` | `#181818` | 主文字：标题、正文 | `Color(0xFF181818)` |
| `BrandColors.textSecondary` | `#A6A6A6` | 副文字：标签标题、占位符、提示 | `Color(0xFFA6A6A6)` |
| `BrandColors.textDisabled` | `#C5C5C5` | 禁用文字/图标 | `Color(0xFFC5C5C5)` |
| `BrandColors.border` | `#E7E7E7` | 输入框边框、分隔线 | `Color(0xFFE7E7E7)` |
| `BrandColors.error` | `#D54941` | 错误/删除/危险操作 | `Color(0xFFD54941)` |
| `BrandColors.line` | `#EEEEEE` | Divider 分割线 | `Color(0xFFEEEEEE)` |
| `BrandColors.success` | `#00A870` | 成功/已完成态 | — |
| `BrandColors.surfaceLight` | `#F2F3FF` | 选中态浅底、tonal 按钮底 | `Color(0xFFF2F3FF)` |

### 2.2 页面背景

所有列表页/详情页/设置页的背景统一：
```dart
Scaffold(
  backgroundColor: BrandColors.surface,   // #F3F3F3
)
```

### 2.3 文字色阶

| 层级 | 色值 | 使用场景 |
|:----:|:----:|----------|
| 主文字 | `BrandColors.textPrimary`（`#181818`） | 标题、正文内容 |
| 次要文字 | `BrandColors.textSecondary`（`#A6A6A6`） | 标签标题、提示文字、占位符、**分区标题** |
| 禁用文字 | `BrandColors.textDisabled`（`#C5C5C5`） | 禁用状态、版本信息等弱化文字 |

> **注意**：**分区标题（Section Title）必须用 `BrandColors.textSecondary`，不得使用品牌色。** 品牌色会给用户"可点击"的暗示，而分区标题只是装饰性标签。

---

## 3. 公共组件速查

所有组件位于 `lib/widgets/`，详细用法见文件顶部 `///` 注释和 `docs/dev/COMPONENT_GUIDE.md`。

| 组件 | 文件 | 一句话用法 |
|------|------|-----------|
| `AppSearchBar` | `app_search_bar.dart` | 搜索栏，`controller` + `onSearch` |
| `AppFormSection` | `app_form_section.dart` | 表单标签块，`label` + `required` + `child` |
| `AppActionBar` | `app_action_bar.dart` | 底部操作栏，`.submit()` 单按钮 / `bar()` 多按钮 |
| `AppDialog` | `app_dialog.dart` | 弹窗，`.confirm()` / `.alert()` 静态方法 |
| `AppBottomSheet` | `app_bottom_sheet.dart` | 底部抽屉，`.show(title, child)` |
| `AppTextarea` | `app_textarea.dart` | 多行文本域，`controller` + `hintText` + `quickNotes?` |
| `AppToast` | `app_toast.dart` | 提示，`.show(context, msg)` |
| `AppFilterChips` | `app_filter_chips.dart` | 列表页搜索框下方的单选筛选条（横滚药丸，**默认占满 100% 宽**，选项少时沿行铺满、选项多时横滚），`items` + `selectedCode` + `onChanged` |
| `AppEmptyBody` | `app_empty_body.dart` | 空状态展示（图标 + 主文案 + 副文案），`icon` + `title` + `desc?` |
| `AppSegmentedTab` | `app_segmented_tab.dart` | 带计数徽标的分段 Tab 栏（下划线 + 选中蓝字），`tabs` + `activeKey` + `onChanged` |
| `AppScopeToggle` | `app_scope_toggle.dart` | 作用域切换药丸（我的 / 团队等），`options` + `currentValue` + `onChanged` |
| `AppStickyHeader` | `app_sticky_header.dart` | 固定高度吸顶委托 `FixedStickyHeaderDelegate(height, child)` |
| `AppListFooter` | `app_list_footer.dart` | 列表底部加载状态（加载更多 / 已加载全部 / 留白），`isLoadingMore` + `hasMore` |

> **规则**：凡上述组件对应的场景，必须使用公共组件，不得手动拼装替代品。
> 列表页「搜索框下方的单选筛选条」必须使用 `AppFilterChips`，禁止各页自绘 chip / 分段控件。
> 列表页「空态」「带计数的分段 Tab」「作用域切换」「吸顶头委托」「列表 footer」必须使用对应公共组件，禁止各页自绘。

---

## 4. 页面布局

### 4.1 边距

| 场景 | 边距值 |
|------|--------|
| 列表页左右 | 16px |
| 卡片内 padding | 16px |
| 底部抽屉左右 | 24px（由 AppBottomSheet 自动处理） |
| 底部抽屉底部 | 16px + bottomInset（由 AppBottomSheet 自动处理） |

### 4.2 区块间距

| 间距 | 场景 |
|:----:|------|
| 16px | 不同区块/卡片之间 |
| 24px | 提交按钮前 |
| 8px | 标签与内容之间（AppFormSection 默认处理） |

---

## 5. 白卡片容器

### 5.1 内容详情卡（圆角 12px，阴影）

```dart
Card(
  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(children: [...]),
  ),
)
```

主题已配置 `CardTheme`（`component_tokens.dart`）：白底 `Colors.white` + 圆角 12px + 微阴影。直接用 `Card` 组件即可。

### 5.2 设置页卡片（列表式，6px 圆角，灰边框）

```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: BrandColors.border, width: 0.5),
  ),
  child: Column(children: [...]),
)
```

---

## 6. 表单与输入

### 6.1 表单区块（AppFormSection）

表单抽屉中的每区块使用 `AppFormSection`，自带标签 + 可选红色 * + 8px 间距：

```dart
AppFormSection(
  label: '跟进内容',
  required: true,          // 可选，显示红色 *
  child: TextField(...),
)
```

> **规则**：禁止手动拼装 `Text('标签') + SizedBox(height: 8) + 控件` 模式。

### 6.2 单行输入框

样式由主题 `InputDecorationTheme` 统一控制（白底 + 灰边框 + 6px 圆角）。
直接用 `TextField` 即可获得统一样式，不需额外 Container 包装：

```dart
TextField(
  decoration: InputDecoration(
    hintText: '占位文字',
  ),
)
```

### 6.3 多行文本域（AppTextarea）

带字数指示器 + 快捷备注，不可用手动 TextField：

```dart
// 纯文本域
AppTextarea(
  controller: _ctrl,
  hintText: '补充说明...',
  maxLength: 200,          // 默认 200，可调
)

// 带快捷备注（跟进面板风格）
AppTextarea(
  controller: _ctrl,
  hintText: '请输入跟进内容...',
  maxLength: 100,
  quickNotes: ['有意向', '需跟进', '已加微信'],
)
```

字数指示器浮在文本框内部右下角，超限变红且不可继续输入。

### 6.4 日期/时间选择器

使用 Material 原生 picker，**不允许**使用已移除的 TDPicker：

```dart
// 日期
final picked = await showDatePicker(
  context: context,
  initialDate: _selectedDate,
  firstDate: today,
  lastDate: today.add(const Duration(days: 365)),
);
if (picked != null) setState(() => _selectedDate = picked);

// 时间
final picked = await showTimePicker(
  context: context,
  initialTime: _selectedTime,
);
if (picked != null) setState(() => _selectedTime = picked);
```

---

## 7. 底部抽屉（AppBottomSheet）

### 7.1 基础用法

```dart
final result = await AppBottomSheet.show<bool>(
  context: context,
  title: '新增跟进记录',
  onClose: onCloseCallback,   // 可选：脏检查等自定义关闭行为
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppFormSection(label: '内容', child: TextField(...)),
      const SizedBox(height: 24),
      AppActionBar.submit(text: '提交', onPressed: _submit),
    ],
  ),
);
```

AppBottomSheet 自动提供：
- 拖拽手柄（左侧）
- 居中标题
- 关闭按钮（右侧）
- 可滚动内容
- 键盘适配（`viewInsets.bottom`）
- 白底 + 顶部 16px 圆角

### 7.2 带脏检查的关闭

在 `onClose` 回调中处理：

```dart
AppBottomSheet.show<bool>(
  context: context,
  title: '编辑日程',
  onClose: () {
    // 在 state 中定义 _onBack 进行脏检查
    state._onBack();
  },
  child: MyFormContent(),
);
```

> **规则**：禁止使用 `showModalBottomSheet` + 手动拼装 Container/标题栏/关闭按钮。

---

## 8. 弹窗（AppDialog）

### 8.1 确认弹窗

```dart
final ok = await AppDialog.confirm(
  context: context,
  title: '确认删除',
  content: '确定要删除吗？此操作不可恢复。',
  confirmText: '删除',
  confirmColor: BrandColors.error,   // 可选，默认品牌色
  cancelText: '取消',
  onConfirm: () => delete(id),
);
```

### 8.2 提示弹窗

```dart
AppDialog.alert(
  context: context,
  title: '密码修改成功',
  content: '请使用新密码重新登录。',
);
```

> **规则**：禁止使用 `showDialog` + `AlertDialog`。所有弹窗走 `AppDialog`。

---

## 9. 按钮

样式由主题统一控制（大圆角药丸形），组件名即用法：

| 旧 TDesign | 新 M3 | 使用场景 |
|------------|-------|----------|
| `TDButton(theme: primary)` | **`FilledButton`** | 主操作：提交、保存 |
| `TDButton(theme: light)` | **`FilledButton.tonal()`** | 次要操作：取消、返回 |
| `TDButton(type: text)` | **`TextButton`** | 文字按钮：编辑、查看全部 |

```dart
FilledButton(
  onPressed: _submit,
  child: const Text('提交'),
)

FilledButton.tonal(
  onPressed: _cancel,
  child: const Text('取消'),
)

TextButton(
  onPressed: _edit,
  child: const Text('编辑'),
)
```

> **规则**：禁止使用 `TDButton`（已移除）。

---

## 10. 底部操作栏（AppActionBar）

```dart
// 单提交按钮模式（最常用）
AppActionBar.submit(
  text: '保存',
  loading: _isSubmitting,
  onPressed: _isSubmitting ? null : _submit,
)

// 多按钮模式
AppActionBar(
  actions: [
    ActionItem(text: '取消', type: ActionType.light, onTap: _cancel),
    ActionItem(text: '确认', type: ActionType.primary, onTap: _confirm),
  ],
)
```

> **规则**：底部通栏按钮必须用 `AppActionBar`，禁止手动 `SizedBox(width: double.infinity) + FilledButton`。

---

## 11. 标签选择器（TagChip）

`lib/widgets/tag_chip.dart` 提供 `TagChipRow` + `TagChipData`：

| 属性 | scrollable: true | scrollable: false |
|------|:----------------:|:-----------------:|
| 布局 | 横向滚动 `SingleChildScrollView+Row` | 自动换行 `Wrap` |
| 场景 | 快捷日期/时间/分类 | 快捷备注 |

```dart
TagChipRow(
  scrollable: false,
  chips: quickNotes.map((n) => TagChipData(
    label: n.name,
    selected: false,
    onTap: () { /* 追加到文本域 */ },
  )).toList(),
)
```

**视觉规格**：

| 状态 | 背景 | 文字 | 圆角 |
|------|------|------|:----:|
| 未选中 | `#F3F3F3` | `#181818` | 14px |
| 选中 | `#0052D9` | `#FFFFFF` | 14px |

---

## 12. 列表样式

### 12.1 列表项卡片

```dart
Card(
  margin: const EdgeInsets.only(bottom: 8),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(children: [...]),
  ),
)
```

主题已配置 `CardTheme`，无需手动设置圆角和阴影。

### 12.2 设置页 ListTile

设置页通常用 `ListTile` + 白卡片容器，图标统一大小 20-22px：

```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: BrandColors.border, width: 0.5),
  ),
  child: Column(children: [
    ListTile(
      leading: const Icon(Icons.lock, size: 20),
      title: const Text('修改密码'),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => navigateTo(),
    ),
    const Divider(height: 0, indent: 52),
    ListTile(
      leading: Icon(Icons.logout, size: 20, color: BrandColors.error),
      title: Text('退出登录', style: TextStyle(color: BrandColors.error)),
      onTap: _onLogout,
    ),
  ]),
)
```

**规则**：
- 分区标题用灰色 `BrandColors.textSecondary`，**不用品牌蓝**
- 退出/删除操作图标和文字用 `BrandColors.error`
- 加载中时在 `trailing` 显示 `CircularProgressIndicator`

---

## 13. 设置页风格规范

### 13.1 分区标题

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
  child: Text(
    '账户安全',          // 灰色，非蓝色
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: BrandColors.textSecondary,
    ),
  ),
)
```

### 13.2 关于弹窗

使用 `AppDialog` 而非原始 `showDialog` + `AlertDialog`。如需自定义内容布局，在弹窗内放 Column：

```dart
// 推荐：用 AppDialog 的 content 扩展
// 或自定义 showDialog 但至少按钮要走 FilledButton
```

### 13.3 底部版本信息

```dart
Text(
  '电销工作台 v1.0.0',
  style: const TextStyle(
    fontSize: 12,
    color: BrandColors.textDisabled,     // #C5C5C5
  ),
)
```

---

## 14. 常用模式速记

| 场景 | 代码 | 禁止写法 |
|------|------|----------|
| 表单标签 | `AppFormSection(label: '标题', child: ...)` | `Text('标题') + SizedBox + 控件` |
| 提交按钮 | `AppActionBar.submit(text: '保存', ...)` | `SizedBox + FilledButton` |
| 底部抽屉 | `AppBottomSheet.show(title: '标题', child: ...)` | `showModalBottomSheet + 手动包装` |
| 确认弹窗 | `AppDialog.confirm(...)` | `showDialog + AlertDialog` |
| 提示文字 | `ScaffoldMessenger.showSnackBar` 或 `AppToast.show()` | `TDToast.showText()` |
| 品牌色 | `BrandColors.primary` | `Color(0xFF0052D9)` |
| 页面背景 | `BrandColors.surface` | `Color(0xFFF3F3F3)` |
| 提示灰色 | `BrandColors.textSecondary` | `Color(0xFFA6A6A6)` |
| 多行文本 | `AppTextarea(controller: _, hintText: _)` | `TextField + 手动计数器` |
| 日期选择 | `showDatePicker(...)` | `TDPicker.showDatePicker(...)` |
| 图标 | `Icon(Icons.xxx, size: 20, color: ...)` | **emoji**（📅👤📝📞🔄⏰🏠 等，跨平台字形不一致、与线性图标风格割裂） |
| 状态标签 | `AppTag(label: _, color: _)` | 手写 `Container` 标签（会出现两套颜色逻辑） |
| 信息行 | `AppInfoRow(icon: _, label: _, value: _)` | 手写 `_infoRow`（左标签右值） |
| 错误/空态 | `AppErrorBody(...)` / `AppEmptyBody(...)` | 手写错误/空布局 |
| 日程卡片 | `detailCard` / 列表卡（圆角 10px + 微阴影，三处一致避免加载闪跳） | 圆角 12 无阴影 |

> ⚠️ **硬规则**：全 app 图标一律用 Material `Icons.*`，**禁止任何 emoji**。emoji 仅在日程详情页历史遗留中出现过（已整改），属 M3 迁移遗漏，不允许新增。

---

> **版本**：v2.1 | **最后更新**：2026-07-26（补充图标禁令、组件复用与日程卡片规范）
> **相关文档**：`docs/dev/COMPONENT_GUIDE.md`（组件使用说明）、`docs/dev/UI_MIGRATION_HANDOVER-2026-07-25.md`（交接文档）
