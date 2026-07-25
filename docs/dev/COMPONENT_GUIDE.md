# 公共组件使用说明

> 日期：2026-07-25
> 说明：本文档列出项目中已抽离的公共 UI 组件，供开发者在编写新页面或重构旧页面时参考。
> 所有组件位于 `lib/widgets/` 目录，详细用法见各组件文件顶部的 `///` Dart Doc 注释。

---

## 1. AppSearchBar — 统一搜索栏

**文件**：`lib/widgets/app_search_bar.dart`

**用途**：带搜索图标、输入框、一键清空和搜索按钮的复合搜索栏。

**参数**：

| 参数 | 类型 | 必需 | 默认 | 说明 |
|------|------|:----:|:----:|------|
| `controller` | `TextEditingController` | ✅ | — | 外部持有的输入框控制器 |
| `onSearch` | `ValueChanged<String>` | ✅ | — | 搜索回调，清空时传 `''` |
| `hintText` | `String` | ✅ | — | 占位提示文字 |
| `keyboardType` | `TextInputType?` | ❌ | `text` | 手机号搜索传 `phone` |
| `searchButtonText` | `String` | ❌ | `'搜索'` | 搜索按钮文字 |

**示例**：
```dart
AppSearchBar(
  controller: _searchCtrl,
  onSearch: _doSearch,
  hintText: '搜索线索姓名/电话/公司',
)
```

**替代旧组件**：`leads_search_bar` / `call_search_bar` / `customer_search_bar`

---

## 2. AppFormSection — 表单区块

**文件**：`lib/widgets/app_form_section.dart`

**用途**：表单页面中「标签 + 内容」的标准区块布局，统一标签样式、必填标记和间距。

**参数**：

| 参数 | 类型 | 必需 | 默认 | 说明 |
|------|------|:----:|:----:|------|
| `label` | `String` | ✅ | — | 区块标签文字 |
| `child` | `Widget` | ✅ | — | 区块内容（可以是 Column 组合多个元素） |
| `required` | `bool` | ❌ | `false` | 是否显示红色 `*` |
| `spacing` | `double` | ❌ | `8` | 标签与内容间距 |

**示例**：
```dart
AppFormSection(
  label: '跟进内容',
  required: true,
  child: Column(
    children: [
      TextField(maxLines: 4, ...),       // 文本域
      SizedBox(height: 12),
      TagChipRow(...),                   // 快捷备注
    ],
  ),
)
```

**替代旧组件**：各处手动拼装的 `Column + Text('标题') + SizedBox + 内容`

---

## 3. AppActionBar — 底部操作栏

**文件**：`lib/widgets/app_action_bar.dart`

**用途**：底部操作栏，支持两种模式：单按钮提交和多按钮操作行。

**数据模型**：

```dart
enum ActionType { primary, light, text }

class ActionItem {
  final String text;
  final IconData? icon;
  final ActionType type;
  final VoidCallback? onTap;   // null 时按钮禁用
  final bool loading;
}
```

**模式 1 — 提交按钮**：

| 参数 | 类型 | 必需 | 默认 | 说明 |
|------|------|:----:|:----:|------|
| `text` | `String` | ✅ | — | 按钮文字 |
| `onPressed` | `VoidCallback?` | ✅ | — | 点击回调 |
| `loading` | `bool` | ❌ | `false` | 显示 loading 转圈 |
| `enabled` | `bool` | ❌ | `true` | 是否可点击 |

```dart
AppActionBar.submit(
  text: _isEdit ? '保存' : '创建日程',
  loading: _isSubmitting,
  onPressed: _submit,
)
```

**模式 2 — 操作行**：

```dart
// 文字图标按钮（线索详情风格）
AppActionBar(
  actions: [
    ActionItem(text: '跟进', type: ActionType.text, icon: Icons.replay, onTap: _onFollow),
    ActionItem(text: '日程', type: ActionType.text, icon: Icons.calendar_today, onTap: _onSchedule),
    ActionItem(text: '编辑', type: ActionType.text, icon: Icons.edit, onTap: _onEdit),
  ],
)

// 填充按钮（日程详情风格，主次层级）
AppActionBar(
  actions: [
    ActionItem(text: '取消日程', type: ActionType.light, onTap: _onCancel),
    ActionItem(text: '拨号', type: ActionType.light, icon: Icons.call, onTap: _onDial),
    ActionItem(text: '标记完成', type: ActionType.primary, onTap: _onComplete),
  ],
)
```

**替代旧组件**：
- `_buildSubmitButton()` → `AppActionBar.submit`
- `LeadActionBar` → `AppActionBar(actions: [ActionItem(type: text, ...)])`
- `schedule_detail_actions.actionBar` → `AppActionBar(actions: [ActionItem(type: light/primary, ...)])`

---

## 4. AppDialog — 统一弹窗

**文件**：`lib/widgets/app_dialog.dart`

**用途**：确认/提示弹窗，静态方法直接调用，无需 `showDialog + builder` 样板。

**方法**：

```dart
// 确认弹窗（两个按钮）
Future<bool?> AppDialog.confirm({
  required BuildContext context,
  required String title,
  required String content,
  String cancelText = '取消',
  String confirmText = '确认',
  Color? confirmColor,        // 危险操作传红色
  required VoidCallback onConfirm,
})

// 提示弹窗（一个按钮）
Future<bool?> AppDialog.alert({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = '知道了',
})
```

**示例**：
```dart
// 退出登录
AppDialog.confirm(
  context: context,
  title: '确认退出',
  content: '确定要退出登录吗？',
  confirmText: '退出',
  onConfirm: () => logout(),
)

// 删除记录（红色确认按钮）
AppDialog.confirm(
  context: context,
  title: '确认删除',
  content: '确定要删除吗？此操作不可恢复。',
  confirmText: '删除',
  confirmColor: Colors.red,
  onConfirm: () => delete(id),
)

// 提示
AppDialog.alert(
  context: context,
  title: '密码修改成功',
  content: '请使用新密码重新登录。',
)
```

**替代旧组件**：各处 `showDialog + AlertDialog` 样板代码

---

## 5. AppBottomSheet — 统一底部抽屉

**文件**：`lib/widgets/app_bottom_sheet.dart`

**用途**：统一底部抽屉样式，提供拖拽手柄、标题、关闭按钮、可滚动内容和键盘适配。

**方法**：

```dart
Future<T?> AppBottomSheet.show<T>({
  required BuildContext context,
  required String title,
  required Widget child,
})
```

**示例**：
```dart
final result = await AppBottomSheet.show<bool>(
  context: context,
  title: '新增跟进记录',
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppFormSection(label: '跟进内容', required: true, child: TextField(...)),
      const SizedBox(height: 24),
      AppActionBar.submit(text: '提交跟进', onPressed: _submit),
    ],
  ),
);
```

**替代旧组件**：各处 `showModalBottomSheet + Container(white, rounded) + SheetHeader` 样板

---

## 6. 替换优先级建议

| 优先级 | 组件 | 影响文件数 | 替换难度 |
|:------:|------|:----------:|:--------:|
| 🔴 P0 | `AppDialog` | 8 | 🟢 简单（函数替换函数） |
| 🔴 P0 | `AppSearchBar` | 3 | 🟢 简单（参数对齐） |
| 🟡 P1 | `AppActionBar.submit` | 4 | 🟢 简单 |
| 🟡 P1 | `AppFormSection` | 3 | 🟢 简单 |
| 🟢 P2 | `AppActionBar`（多按钮） | 2 | 🟡 中等 |
| 🟢 P2 | `AppBottomSheet` | 2 | 🟡 中等 |
