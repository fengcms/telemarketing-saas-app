# 修复：拨号返回后跟进信息写错线索

**日期**：2026-07-28
**类型**：Bug 修复
**影响角色**：所有通过底部「上一个 / 下一个」在详情页内切换线索、且用拨号返回自动弹出跟进面板的用户（员工最常触发）

## 一、问题现象

员工反馈：在线索列表进入线索 A → 拨打电话 → 填写跟进信息（正常，写到 A）。点「下一个」切到线索 B → 拨打电话 → 填写跟进信息，结果**写到了上一个线索 A**。

## 二、根因分析

`LeadDetailPage` 是一个「常驻」页面实例。底部导航条的「上一个 / 下一个」**不会新开路由页**，而是直接改全局 `leadDetailProvider` 的状态（`goToNext()` / `goToPrev()` → `loadLead()`），页面只是 rebuild。

而 `widget.leadId` 是进入详情页时构造函数传入的**初始线索 ID**，页面实例不销毁就**永远不变**。

拨号返回后自动弹出跟进面板的逻辑（`lead_detail_page.dart` 的 `didChangeAppLifecycleState`）用的是 `widget.leadId`：

```dart
// 修复前（有 bug）
if (lifeState == AppLifecycleState.resumed) {
  if (_recentlyDialed) {
    _recentlyDialed = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showFollowUpPanel(context, leadId: widget.leadId, fromDial: true); // ←  stale!
      }
    });
  }
}
```

链路：
1. 打开 A → `widget.leadId = A`；拨号返回弹面板用 `A` → 写 A ✅（碰巧对，A 即初始线索）
2. 点「下一个」→ provider 切到 B，`widget.leadId` 仍是 A
3. 在 B 拨号返回 → 弹面板仍用 `widget.leadId = A` → 写到了 A ❌

> 手动点「跟进」按钮那条路是好的（`_buildActionBar` 用 `state.detail!.id`，即当前 provider 里的 B），所以只有「拨号返回自动弹出」会写错线索，表现为「偶发」。

## 三、修复方案

在 `didChangeAppLifecycleState` 里改用**当前正在查看的线索 ID**（从实时 provider 读取），而非 `widget.leadId`：

```dart
if (lifeState == AppLifecycleState.resumed) {
  if (_recentlyDialed) {
    _recentlyDialed = false;
    // 修复：用当前实际查看的线索 ID，而非进入页时的初始 widget.leadId
    final currentLeadId = ref.read(leadDetailProvider).detail?.id;
    if (currentLeadId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showFollowUpPanel(context, leadId: currentLeadId, fromDial: true);
        }
      });
    }
  }
}
```

仅改动这一处。`follow_up_panel.dart` 内部读取的 `leadDetailProvider.detail`（手机号、分类）也会随本次修复一并对齐到正确线索。

## 四、验证

- 进入线索 A，拨号返回，填写跟进 → 确认写到 A
- 点「下一个」到 B，拨号返回，填写跟进 → 确认写到 B（不再串到 A）
- 回归：手动「跟进」按钮路径仍正常
