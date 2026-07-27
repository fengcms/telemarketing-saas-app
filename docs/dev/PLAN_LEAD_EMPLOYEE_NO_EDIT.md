# 员工详情页「编辑」→「转化」实施计划

> **背景**：员工（TE）不应在无通话依据下编辑线索（改分类/状态等），分类的合理入口是"跟进记录"时顺带选；但员工在跟进确认成交后需将线索标记为转化的能力应保留。后端已在提交跟进记录时自动 `assigned→following`，且 `following→converted` 已对 TE 放开。

## 一、改动范围

仅 1 个文件 + 1 个文案涉及引用：

| 文件 | 改动 |
|---|---|
| `lib/pages/leads/lead_detail_page.dart` | 操作栏按角色分流 |
| `lib/pages/leads/widgets/edit_lead_dialog.dart` | 不改（经理仍可用） |
| `lib/pages/leads/widgets/follow_up_panel.dart` | 不改（后端自动推进状态） |

## 二、具体改动

### 2.1 `_buildActionBar` 按角色分流

当前操作栏无条件显示 4 个按钮：跟进、日程、标记为已转化、编辑。

改为：

**员工（`tenant_employee`）：**
- 跟进 ✅（不变）
- 日程 ✅（不变）
- **转化** ✅（`following` 态可点，点击弹确认框；文案改为"转化"）
- 编辑 ❌ **移除**

**经理/管理员（`tenant_manager` / `tenant_admin`）：**
- 跟进 ✅
- 日程 ✅
- **标记为已转化** ✅（`following` 态可点，统一加确认框）
- 编辑 ✅（保留，可在编辑弹窗改分类/状态做数据治理）

### 2.2 统一的确认框 + PATCH

`_markConverted` 第 1 步改为弹 `AppDialog.confirm`：

```
标题：确认转化线索
内容：确认将该线索转化为客户？系统将自动为客户建档。
确定 → PATCH status=converted；取消 → 关闭
```

确认后逻辑与当前一致：`updateLead(id, status:'converted')` → `refreshBundle()` → toast「已转化为客户并自动建档」。

## 三、状态机保证（方案已闭环）

```
员工 assigned → 跟进记录（后端自动 → following）
员工 following → 「转化」按钮 → 确认框 → PATCH converted（后端建档客户）
经理 following → 「标记为已转化」→ 确认框 → PATCH converted
经理 assigned → 跟进记录（后端自动 → following）→ 同上
```

无死路、无 400 风险。

## 四、验证项

1. 员工角色打开 **`following` 线索** → 操作栏显示「跟进 / 日程 / 转化」→ 点「转化」弹确认框 → 确认 → toast + 详情刷新为 `converted`
2. 员工角色打开 **`assigned` 线索** → 操作栏显示「跟进 / 日程」→ **无「转化」按钮**（因后端要求 `following` 前置且当前是 assigned）
3. 员工角色打开 **`converted` 或 `invalid` 线索** → 操作栏显示「跟进/日程」禁用态、「编辑」「转化」均无
4. 管理员角色打开 **`following` 线索** → 操作栏显示「跟进 / 日程 / **标记为已转化** / 编辑」
5. 全仓 `flutter analyze` 0 error

## 五、开发步骤

1. `lead_detail_page.dart`：
   - `build()` 中通过 `ref.read(authProvider).user?.role` 获取角色
   - `_buildActionBar` 按 `isEmployee` 条件编译 action 列表
   - `_markConverted` 统一改为 `AppDialog.confirm` 前置
2. 静态分析
3. 构建 release APK 并安装到 Redmi K60
4. 真机实测
5. 实测通过后写进度/踩坑文档 + commit

---

**预计改动量**：~10 行逻辑 + 确认框调用，纯前端，无新增依赖。
