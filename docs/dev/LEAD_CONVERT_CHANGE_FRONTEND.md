# 线索状态流转权限更正 · 前端对接指南

> @file docs/LEAD_CONVERT_CHANGE_FRONTEND.md
> 说明「员工可在跟进中标记为已转化、已转化设为全员硬终态」这轮后端改动的接口契约与 App 端调整点。
> 适用环境：测试环境（test）已部署；生产（prod）暂未动。

---

## 0. 背景（为什么改）

原设计中，员工（TE）被禁止将线索从「跟进中 `following`」直接改为「已转化 `converted`」。经复核这是**设计错误**：员工应当在跟进过程中把成交线索标记为已转化。

本次后端已修正，并同步把「已转化」设为**全员硬终态**（含管理员经 `recycle` 也改不回），以杜绝「已转化被改回 → 客户记录变孤儿」的数据质量问题。

---

## 1. 状态机权威定义（前端以此为准，勿再翻旧 design.md 描述）

状态枚举：`pending`(公海待领) / `assigned`(已分配) / `following`(跟进中) / `converted`(已转化) / `invalid`(无效)

合法流转（所有角色通用）：

| 当前状态 | 允许目标 |
|---|---|
| `pending` | `assigned` \| `following` \| `invalid` |
| `assigned` | `following` \| `invalid` |
| `following` | `invalid` **\| `converted`（新增：员工可用）** |
| `invalid` | （无出边） |
| `converted` | （**无出边，硬终态**） |

---

## 2. 角色权限矩阵（变更点高亮）

| 操作 | 员工 TE | 管理员 TM / TA |
|---|---|---|
| `following` → `converted` | ✅ **现在允许（限本人线索）** | ✅（原已允许） |
| `converted` → 任何状态（含 `following` / `pending`） | ❌ 硬终态 | ❌ **硬终态（新增：recycle 也被拦）** |
| `converted` → `converted`（重复） | ❌ `VALIDATION` 校验 | ❌ `VALIDATION` 校验 |
| `following` → `invalid` | ✅ | ✅ |
| 置 `converted` 时自动建客户记录 | ✅ 自动 | ✅ 自动 |

---

## 3. 接口契约变化

### 3.1 `PATCH /api/tenant/leads/:id`
- TE 现在允许的目标 `status`：`following` **或** `converted`（之前仅 `following`）。
- 当 TE 把 `status` 设为 `converted` 时，后端**自动生成一条客户记录**（同步姓名 / 电话 / 公司 / 来源项目等），客户 `leadId` 回指该线索。
- 若 TE 试图把 `status` 设为 `invalid` 之外的其它值（如 `pending`），返回 `STATUS_ROLLBACK_FORBIDDEN`(400)。

### 3.2 `POST /api/tenant/leads/:id/convert`
- **权限放开**：TE 现在可调用（之前仅 manager）。
- 约束：线索须属于本人（`requireOwned`）且状态为 `following`。
- 已 `converted` 再调返回 `VALIDATION "lead already converted"`。
- 成功响应：`{ id, customerId, status: "converted" }`。

### 3.3 `POST /api/tenant/leads/:id/recycle`（退回公海）
- 若线索已是 `converted`，返回 `400` + `error.code = "STATUS_ROLLBACK_FORBIDDEN"`（之前 manager 可经此改回，现已堵死）。
- 这是本次新增的拦截，请 App 端对 `recycle` 失败做好提示。

---

## 4. 错误码速查

| code | HTTP | 触发场景 |
|---|---|---|
| `STATUS_ROLLBACK_FORBIDDEN` | **400** | 试图变更 `converted` 状态（PATCH 改 `converted` 出边 / `recycle` 已转化线索） |
| `AUTH_FORBIDDEN` | 403 | TE 试图设 `invalid` 或越权状态 |
| `VALIDATION` | 400 | 已 `converted` 重复调用 `/convert` |

> ⚠️ 注意：`STATUS_ROLLBACK_FORBIDDEN` 映射为 **400（非 403）**，与既有 PATCH 全局拦截一致。App 端按 400 捕获即可。

---

## 5. 客户记录（转化副作用）

- 任一角色将线索置 `converted`，后端在 `customers` 表建一条记录：复制姓名 / 电话 / 公司 / 来源项目，`level=normal`，`leadId` 回指线索。
- `doConvert` 已做**幂等**：同一未删除线索不会重复建客户（历史脏数据 / 并发双提交兜底复用）。
- 客户记录一旦生成，线索改不回、客户也不会被级联删除——这是「已转化 = 资产沉淀」的语义。前端可在客户列表按 `leadId` 关联回溯来源线索。

---

## 6. App 端 UI 调整建议

1. **跟进中线索**：操作区给 TE 增加「标记为已转化」按钮（调 `POST /:id/convert` 或 `PATCH /:id` 设 `status=converted`）。
2. **已转化线索**：隐藏一切「退回公海 / 改回跟进」入口——任何回退请求都会被后端 400 拒绝，前端提前禁用更友好。
3. **recycle 失败处理**：捕获 `STATUS_ROLLBACK_FORBIDDEN`，Toast 提示「已转化线索不可退回 / 变更」。
4. **转化成功反馈**：拿到 `customerId` 后，可引导用户前往客户详情（客户已自动建档）。
5. **权限分层 UI**：若 App 对 TE / TM 展示不同操作集，TE 的「转化」入口直接可用；TM 行为不变。

---

## 7. 验证情况（测试环境）

- 员工本人 `following → converted` 成功并生成客户记录（集成测试已覆盖）。
- `recycle` 已转化线索被拒（400 + `STATUS_ROLLBACK_FORBIDDEN`）。
- manager 转化建客户无回归。
- 类型检查 / 单测 / 集成测试全绿。

---

## 8. 前端落地记录（管理后台，2026-07-27）

> 本次仅调整**管理后台**（地址 `tm-api-test.kao9.com` 测试环境，已由用户验证通过；`tm-api.kao9.com` 生产暂未部署）。
> App 端（TE）的 UI 调整见 §6，不在本仓库范围。

### 8.1 状态机收敛为前端唯一数据源

`src/types/lead.ts` 新增权威映射与辅助函数，所有状态约束统一从这里取，不再散落布尔判断：

```ts
export const LEAD_STATUS_TRANSITIONS: Record<LeadStatus, LeadStatus[]> = {
  pending:   ['assigned', 'following', 'invalid'],
  assigned:  ['following', 'invalid'],
  following: ['invalid', 'converted'],
  invalid:   [],
  converted: [], // 硬终态，无出边
}
export const getAllowedStatusTargets = (current: LeadStatus): LeadStatus[] =>
  LEAD_STATUS_TRANSITIONS[current] ?? []
```

### 8.2 编辑弹窗状态下拉按当前状态收敛

`lead-edit-modal.tsx` 原为全量 `Object.keys(LEAD_STATUS_LABEL)` 选项，TA/TM 可自由把线索设成任意状态（含 `converted`/`pending`），会触发后端 `STATUS_ROLLBACK_FORBIDDEN`(400)。
现改为**仅列出当前状态的合法目标**（默认项「不修改」）；`invalid`/`converted` 无可出边时仅显示「不修改」。非法流转被前置禁用。

### 8.3 「转客户」入口收为仅 `following`

权威状态机下 `assigned` 不能直达 `converted`（`/convert` 接口亦要求状态为 `following`）。
`lead-table.tsx` 与 `lead-detail-content.tsx` 两处 `canConvert` 统一改为 `isManager && lead.status === 'following'`。

### 8.4 「退回公海」从管理后台彻底移除（按产品决策）

原列表「更多 ▼」中的「退回公海」是点击无反应的死代码，且新后端对 `recycle` 已转化线索返回 400。
已彻底移除：列表菜单项、沿途 `onRecycle` prop（两处 `onRecycle={() => {}}` 死代码）、`api/leads.ts` 的 `recycleLead`、`useLeads.ts` 的 `useRecycleLead`。
（分配流水页 `assignment-list-page.tsx` 中的 `Undo2`/「回收」是分配动作图标，与此无关，保留。）

### 8.5 转化成功体验增强

- `api/leads.ts` 的 `convertLead` 改为返回 `{ id, customerId, status }`（对齐 §3.2 成功响应）。
- `lead-list-page.tsx` 的 `handleConvertConfirm` 在拿到 `customerId` 后，Toast 提示「已转化为客户，并自动建档」，并附带「查看客户」跳转至 `/customers`（对 `customerId` 做空值守卫，生产未部署前不会出现该按钮）。

### 8.6 验证

- `./node_modules/.bin/tsc -b` 零错误；`./node_modules/.bin/vite build` 构建通过。
- 测试环境（`tm-api-test.kao9.com`）行为已由用户验证通过。
- 已合规、无需改的点：`converted` 硬终态（列表/详情已隐藏编辑·分配·转客户）、批量改状态已正确排除 `converted`、`invalid → pending` 走专用 `reactivate` 接口不在 PATCH 状态机内。

---

（完）
