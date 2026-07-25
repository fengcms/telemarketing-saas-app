# AppDialog 替换待处理项

> 日期：2026-07-25
> 说明：第一轮 AppDialog 替换中跳过的 4 处复杂弹窗，记录其原因和后续处理方案。

---

## 1. dial_helper.dart — 夜间禁呼弹窗

**文件**：`lib/pages/leads/widgets/dial_helper.dart`

**原因**：弹窗标题非纯文字，包含警告图标 `Icons.warning_amber_rounded` + 「非工作时段提醒」文字组合。

**当前代码（约 30 行）**：
```dart
AlertDialog(
  title: Row(
    children: [
      Icon(Icons.warning_amber_rounded, color: Color(0xFFE37318), size: 20),
      SizedBox(width: 8),
      Text('非工作时段提醒', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    ],
  ),
  content: Text('当前为非工作时段（$start - $end），是否仍要拨号？'),
  actions: [
    TextButton(onPressed: () => pop(false), child: Text('取消')),
    TextButton(onPressed: () => pop(true), child: Text('继续拨号')),
  ],
)
```

**处理方案**：为 `AppDialog.confirm` 增加可选的 `icon` 参数，支持标题前加图标。

---

## 2. delete_confirm_dialog.dart — 删除跟进弹窗

**文件**：`lib/pages/leads/widgets/delete_confirm_dialog.dart`

**原因**：这是一个完整的 `ConsumerStatefulWidget`，内部有 `_isDeleting` 状态控制 loading 动画，删除按钮在点击后显示 `CircularProgressIndicator` 并调用接口。`AppDialog.confirm` 不支持异步 loading 态确认按钮。

**当前代码（约 60 行）**：
```dart
class DeleteConfirmDialog extends ConsumerStatefulWidget { ... }
class _DeleteConfirmDialogState extends ConsumerState<DeleteConfirmDialog> {
  bool _isDeleting = false;
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('删除跟进记录'),
      content: Text('确定要删除该跟进记录吗？\n删除后将无法恢复。'),
      actions: [
        TextButton(onPressed: () => pop(), child: Text('取消')),
        TextButton(
          onPressed: _isDeleting ? null : _delete,
          child: _isDeleting ? CircularProgressIndicator(...) : Text('确定删除'),
        ),
      ],
    );
  }
  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    try { /* 调用接口删除 */ } catch (_) { /* 错误处理 */ }
  }
}
```

**处理方案**：为 `AppDialog.confirm` 增加 `confirmLoading` 参数，loading 时按钮显示 `CircularProgressIndicator` 并禁用。替换后可直接内联为函数调用，无需独立 StatefulWidget。

---

## 3. edit_follow_up_dialog.dart — 编辑跟进弹窗

**文件**：`lib/pages/leads/widgets/edit_follow_up_dialog.dart`

**原因**：`AlertDialog` 作为表单容器使用，内嵌完整的表单输入（文本域 + 提交按钮），不是简单的确认弹窗。不适配 `AppDialog.confirm` 模式。

**当前代码（约 90 行）**：
```dart
return AlertDialog(
  title: Text('编辑跟进记录'),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppFormSection(label: '跟进内容', child: TDTextarea(...)),
      SizedBox(height: 24),
      AppActionBar.submit(text: '保存', ...),
    ],
  ),
);
```

**处理方案**：保留独立文件，后续迁移到 `AppBottomSheet` 展示表单（抽屉比弹窗更适合表单编辑场景）。

---

## 4. correct_call_dialog.dart — 通话补正弹窗

**文件**：`lib/pages/leads/widgets/correct_call_dialog.dart`

**原因**：同 edit_follow_up_dialog，`AlertDialog` 作为表单容器，内嵌接听类型选择 + 通话时长步进器 + 提交按钮，不适用 `AppDialog.confirm`。

**当前代码**：与 edit_follow_up_dialog 类似，AlertDialog 作为表单容器。

**处理方案**：同 edit_follow_up_dialog，后续迁移到 `AppBottomSheet`。

---

## 替换总结

| 优先级 | 文件 | 方案 | 预计耗时 |
|:------:|------|------|:--------:|
| 🟢 P3 | `dial_helper.dart` | 给 AppDialog 加 `icon` 参数 | 15 分钟 |
| 🟡 P2 | `delete_confirm_dialog.dart` | 给 AppDialog 加 `confirmLoading` 参数 | 20 分钟 |
| 🟢 P3 | `edit_follow_up_dialog.dart` | 迁移到 AppBottomSheet | 30 分钟 |
| 🟢 P3 | `correct_call_dialog.dart` | 迁移到 AppBottomSheet | 30 分钟 |

> 注：4 个待处理项均不影响现有功能，可在后续迭代中按优先级逐一处理。
