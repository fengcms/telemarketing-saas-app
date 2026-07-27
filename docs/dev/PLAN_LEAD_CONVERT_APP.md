# 实施计划：线索状态流转权限更正 · App 端

> @file docs/dev/PLAN_LEAD_CONVERT_APP.md
> 配套：后端 `docs/dev/LEAD_CONVERT_CHANGE_FRONTEND.md` + 分析 `docs/dev/LEAD_CONVERT_APP_ANALYSIS.md`
> 决策依据：用户已确认 Q1–Q4（2026-07-27）。**本报告待用户确认后进入开发。**

---

## 0. 用户确认决策（Q1–Q4）

| 项 | 决策 | 对实施的影响 |
|---|---|---|
| Q1 环境开关 | 未发版、开发阶段 | 直接按新后端契约实现，**不做环境开关** |
| Q2 重新激活 | 不保留 | `invalid` 无出边，从选项移除 |
| Q3 客户深链 | 转化后停留详情页、刷新数据即可 | 复用 `PATCH status=converted`，**不新增 `/convert` 调用、不做客户深链** |
| Q4 回收能力 | App 不保留 | **无 recycle 入口**（现状已满足，§6.2 天然成立） |

→ 剔除分析报告中 P2-F（客户深链）、recycle 相关项；保留 P0（状态收敛）+ P1（错误透出 + 移除重新激活）+ P2-E（一键转化入口）。

---

## 1. 改动清单（3 文件，同一线索状态功能）

### 1.1 `lib/constants/lead_constants.dart` — 抽权威状态机（P0-B）

新增对齐后端 §1 的常量（所有角色通用），并加辅助函数：

```dart
/// 线索状态合法流转（权威数据源，所有角色通用）
/// 对齐后端 docs/dev/LEAD_CONVERT_CHANGE_FRONTEND.md §1
static const Map<String, List<String>> leadStatusTransitions = {
  'pending':   ['assigned', 'following', 'invalid'],
  'assigned':  ['following', 'invalid'],
  'following': ['invalid', 'converted'],
  'invalid':   [],   // 终态（重新激活不保留，Q2）
  'converted': [],   // 硬终态
};

/// 某状态下可选项（含当前态，保证选中高亮；终态则仅当前态=只读）
static List<String> allowedStatuses(String current) =>
    <String>{current, ...leadStatusTransitions[current] ?? const []}.toList();
```

### 1.2 `lib/pages/leads/widgets/edit_lead_dialog.dart` — 收敛选项 + 错误透出（P0-A / P1-C / P1-D）

- **删除** 硬编码 `_forwardStatusMap`（`edit_lead_dialog.dart:39-45`）。
- `_loadOptions`（`edit_lead_dialog.dart:75-98`）：
  - 去掉 `isManager ? LeadConstants.statusLabels.keys.toList() : forwardStatuses` 分支。
  - 改为 `_availableStatuses = LeadConstants.allowedStatuses(widget.detail.status);`（TE / manager 同源，均按合法目标）。
  - 同步移除 `isManager` 局部变量（若无其他用途）。
- `_submit` catch（`edit_lead_dialog.dart:193-197`）：
  - 由 `AppToast.show(context, '保存失败，请重试')` 改为 `AppToast.show(context, e.message)`。
  - 依据：`lead_service.updateLead` 抛 `ApiClient.parseError(e)` → `ApiException`（含 `message` 已映射中文，如 `STATUS_ROLLBACK_FORBIDDEN` → "状态回退被拒…"）。

### 1.3 `lib/pages/leads/lead_detail_page.dart` — 增加「标记为已转化」入口（P2-E）

- 操作栏 `_buildActionBar`（`lead_detail_page.dart:179-220`）对 `following` 线索（所有角色）增加：
  ```dart
  ActionItem(
    text: '标记为已转化', type: ActionType.text, icon: Icons.check_circle,
    onTap: detail.status == 'following'
        ? () => _markConverted(detail.id)
        : null,
  ),
  ```
- 新增 `_markConverted(String leadId)`：
  - `await ref.read(leadServiceProvider).updateLead(id: leadId, status: 'converted');`
  - 成功：`ref.read(leadDetailProvider.notifier).refreshBundle();` + `AppToast.show(context, '已转化为客户并自动建档');`
  - 失败：`AppToast.show(context, e.message);`
  - 复用现有 `PATCH`（后端自动建档客户），**不调 `/convert`**（Q3）。
  - 转化后详情刷新 → `isConverted` 变 true → 跟进/日程自动禁用（既有逻辑生效）。

---

## 2. 验证

- `flutter analyze` 全仓 0 error。
- 真机（Redmi K60，test 环境）重点验：
  1. **TE 跟进中线索** → 操作栏「标记为已转化」→ 详情刷新为已转化、跟进/日程禁用；客户列表出现自动建档的客户。
  2. **manager 编辑 `converted` 线索** → 状态 chips 仅「已转化」（无回退项），保存不会触发 400。
  3. **manager 编辑 `following` 线索** → 可选「已转化」，保存成功。
  4. **非法回退**（若经其它路径触发）→ Toast 显示中文「状态回退被拒…」而非「保存失败」。
  5. **`invalid` 线索编辑** → 无「待分配/待跟进」等重新激活选项。

---

## 3. 范围边界

- 仅改 3 文件，属同一「线索状态流转」功能，符合一次一焦点。
- 不新增 `/convert`、不做客户深链、不加 recycle（按 Q2/Q3/Q4 已剔除）。
- 不触碰 `schedule_*` / 客户列表等无关模块。

---

## 4. 收尾（开发确认后）

- 真机实测通过 → 进度文档 `PROGRESS_LEAD_CONVERT_APP.md` + 踩坑文档追加（状态机收敛/错误透出/一键转化）。
- 更新 `MILESTONES.md`、记工作日志、`git commit & push`（master）。
