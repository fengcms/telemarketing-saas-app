# UI 升级交接文档：TDesign → Material 3

> 交接日期：2026-07-25
> 合并提交：`e5b8f6c`（master）
> 移交人：Mobile App Builder AI 助手
> 接收人：主力开发

---

## 一、本次变更全景

本次将项目 UI 层从 **TDesign Flutter 0.2.7** 全面迁移到 **Material 3**，同时剥离出 7 个公共 UI 组件。

### 关键数据

| 指标 | 数值 |
|------|:----:|
| 修改文件数 | 63 个 |
| 新增代码行 | +4,996 |
| 删除代码行 | −1,879 |
| 新增公共组件 | 7 个 |
| 删除废弃文件 | 5 个 |
| TDesign 依赖 | **已移除**（`pubspec.yaml` 中删除） |
| `flutter analyze` | **0 issues**（九轮守住） |

---

## 二、主题架构（`lib/theme/`）

```
lib/theme/
├── color_scheme.dart      # 品牌色 #0052D9 → M3 ColorScheme + BrandColors 常量
├── text_theme.dart        # 自定义字号/字重（对齐项目设计规范）
├── component_tokens.dart  # 各组件主题覆写（按钮/输入框/卡片/SnackBar）
└── app_theme.dart         # 三部合一入口函数 buildBrandTheme()
```

### 使用方式

在 `lib/app.dart` 中：
```dart
MaterialApp(
  theme: buildBrandTheme(),   // ← 直接引用
  locale: const Locale('zh'), // ← 日期选择器中文化
  localizationsDelegates: AppLocalizations.localizationsDelegates, // ← flutter_localizations
)
```

### 关键设计决策

| 维度 | 值 | 备注 |
|------|:----:|------|
| 主色 | `#0052D9` | 品牌色，作为 `ColorScheme.fromSeed` 的种子色 |
| 按钮圆角 | 大圆角（`radius: 100`） | FilledButton / FilledButton.tonal / TextButton |
| 输入框 | 白底 + `#E7E7E7` 灰边框 + 6px 圆角 | 聚焦时蓝色边框 1.5px |
| Light 按钮 | 浅蓝底 `#F2F3FF` + 蓝字 `#0052D9` | 用 `FilledButton.tonal()` |
| 视觉密度 | 紧凑 | 通过 `visualDensity` 控制 |
| SnackBar | 浮动 + 8px 圆角 | 替代 TDToast |

---

## 三、公共组件手册（`lib/widgets/`）

所有组件用法见 `docs/dev/COMPONENT_GUIDE.md`，组件文件顶部的 `///` Dart Doc 注释是最新权威参考。

### 组件清单

| 组件 | 文件 | 用途 | 关键参数 |
|------|------|------|----------|
| `AppSearchBar` | `app_search_bar.dart` | 统一搜索栏 | `controller` / `onSearch` / `hintText` / `keyboardType` |
| `AppFormSection` | `app_form_section.dart` | 表单标签区块 | `label` / `required` / `child` / `spacing` |
| `AppActionBar` | `app_action_bar.dart` | 底部操作栏 | `submit(text,onPressed)` / `bar(actions)` |
| `AppDialog` | `app_dialog.dart` | 确认/提示弹窗 | `confirm()` / `alert()` 静态方法 |
| `AppBottomSheet` | `app_bottom_sheet.dart` | 统一底部抽屉 | `show(title,child,onClose?)` |
| `AppTextarea` | `app_textarea.dart` | 多行文本域 | `controller` / `hintText` / `maxLength` / `quickNotes?` |
| `AppToast` | `app_toast.dart` | 统一提示 | `show(context, message)` 静态方法 |

### 快速参考

```dart
// 搜索栏
AppSearchBar(
  controller: _searchCtrl,
  hintText: '搜索线索姓名/电话',
  onSearch: _doSearch,
)

// 表单区块（标签 + 内容）
AppFormSection(
  label: '跟进内容',
  required: true,
  child: AppTextarea(controller: _ctrl, hintText: '请输入...'),
)

// 底部操作栏
AppActionBar.submit(text: '保存', loading: _loading, onPressed: _submit)
// 或多按钮
AppActionBar(actions: [
  ActionItem(text: '取消', type: ActionType.light, onTap: _cancel),
  ActionItem(text: '确认', type: ActionType.primary, onTap: _confirm),
])

// 确认弹窗
final ok = await AppDialog.confirm(
  context: context,
  title: '确认删除',
  content: '确定要删除吗？',
  confirmColor: Colors.red,
  onConfirm: _delete,
)

// 底部抽屉
final result = await AppBottomSheet.show<bool>(
  context: context,
  title: '新增跟进记录',
  child: Column(children: [...]),
)

// 多行文本域（带快捷备注）
AppTextarea(
  controller: _ctrl,
  hintText: '请输入跟进内容...',
  maxLength: 100,
  quickNotes: ['有意向', '需跟进', '已加微信'],
)

// Toast 提示
AppToast.show(context, '保存成功')
```

---

## 四、旧组件替换对照表

| TDesign 旧写法 | Material 3 新写法 |
|---------------|------------------|
| `TDButton(theme: primary)` | `FilledButton` |
| `TDButton(theme: light)` | `FilledButton.tonal()` |
| `TDButton(type: text)` | `TextButton` |
| `TDToast.showText(msg, context: ctx)` | `AppToast.show(ctx, msg)` |
| `TDTextarea(...)` | `AppTextarea(...)` |
| `TDIcons.xxx` | `Icons.xxx`（见映射表） |
| `TDPicker.showDatePicker(...)` | `showDatePicker(...)`（Material 原生） |
| `TDNavBar(...)` | `AppBar(...)`（Material 原生） |
| `TDStepper(...)` | 自绘 `_buildStepper(...)` |

### TDIcons → Material Icons 映射表

| TDIcons | Material Icons |
|---------|----------------|
| `call` | `Icons.call` |
| `close` | `Icons.close` |
| `chevron_left` | `Icons.chevron_left` |
| `chevron_down` | `Icons.keyboard_arrow_down` |
| `edit` | `Icons.edit` |
| `home` | `Icons.home` |
| `view_list` | `Icons.view_list` |
| `user` | `Icons.person_outline` |
| `calendar` | `Icons.event` |
| `time` | `Icons.access_time` |
| `rollback` | `Icons.undo` |
| `filter` | `Icons.filter_list` |
| `task` | `Icons.assignment` |
| `key` | `Icons.vpn_key` |
| `lock_on` | `Icons.lock` |
| `mail` | `Icons.mail_outline` |
| `info_circle` | `Icons.info_outline` |
| `info_circle_filled` | `Icons.info` |
| `error_circle` | `Icons.error_outline` |

---

## 五、设计规范要点

### 5.1 页面背景
- 主背景：`#F3F3F3`（`BrandColors.surface`）
- 白色卡片：`#FFFFFF`（`BrandColors.surfaceContainer`）

### 5.2 文字色阶
| 层级 | 色值 | 常量 |
|:----:|:----:|------|
| 主文字 | `#181818` | `BrandColors.textPrimary` |
| 次要文字 | `#A6A6A6` | `BrandColors.textSecondary` |
| 禁用文字 | `#C5C5C5` | `BrandColors.textDisabled` |

### 5.3 间距
- 区块之间：16px
- 标签与内容：8px（`AppFormSection.spacing` 默认值）
- 提交按钮前：24px

### 5.4 快捷备注（AppTextarea）
- `quickNotes` 参数传入 `List<String>?`
- 内部用 `TagChipRow`（多行换行模式 `scrollable: false`）
- 点击后空格追加到文本域末尾
- 跟进面板仅加载 `type == 'followup'` 的数据

---

## 六、快捷备注 type 字段

`OptionItem` 模型新增 `type` 字段：

```dart
class OptionItem {
  final String id;
  final String name;
  final String? type;     // 新增，如 'followup' / 'schedule'
}
```

API `GET /api/tenant/options/quick-notes` 返回 `{id, content, type}`。
本地缓存已更新序列化逻辑（`_encodeList` 保存 `type`，`fromJson` 读取 `type`）。

跟进面板加载后过滤 `type == 'followup'`。其他 type（如 `schedule`）留给未来其他页面使用。

---

## 七、组件预览页

路径：**「我的」→「主题预览」**（仅 `DEV_TOOLS=true` 时显示）

所有 7 个公共组件 + 基础 Material 组件铺在同一页面，供热重载调试主题。
调整 `lib/theme/` 下的配置后按 `r` 热重载即可实时预览。

---

## 八、后续建议

| 优先级 | 事项 | 说明 |
|:------:|------|------|
| 🟡 | 统一 DatePicker/TimePicker 主题色 | 当前使用 Material 默认蓝色，建议通过 `ThemeData.datePickerTheme` 对齐品牌色 |
| 🟢 | 替换 `main_shell.dart` 底部导航图标 | 当前使用 `Icons.home` / `Icons.view_list` 等，可微调语义 |
| 🟢 | 清理旧缓存 | 用户真机安装新版本后，快捷备注旧缓存不含 `type` 字段，刷新即可 |

---

## 九、相关文档索引

| 文档 | 内容 |
|------|------|
| `docs/dev/COMPONENT_GUIDE.md` | 公共组件使用说明与替换优先级 |
| `docs/dev/MATERIAL3_MIGRATION_ARCHITECTURE.md` | 迁移整体架构方案 |
| `docs/dev/PENDING_DIALOG_REPLACEMENT.md` | 未替换弹窗待办 |
| `docs/review/TDESIGN_MIGRATION_REPORT-2026-07-25.md` | 全量替换报告 |
| `docs/review/SPRINT-REVIEW-4-UI-COMPONENTS-2026-07-25.md` | 组件质量审计 |
| `docs/review/SPRINT-REVIEW-5-MIGRATION-2026-07-25.md` | 替换审阅 |
| `docs/review/SPRINT-REVIEW-5-REAUDIT-2026-07-25.md` | 最终放行确认 |
