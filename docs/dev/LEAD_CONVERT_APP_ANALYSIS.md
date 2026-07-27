# 线索状态流转权限更正 · App 端对接分析报告

> @file docs/dev/LEAD_CONVERT_APP_ANALYSIS.md
> 配合后端文档 `docs/dev/LEAD_CONVERT_CHANGE_FRONTEND.md`（2026-07-27）
> 目的：盘点 App 现状，对照后端新契约，给出 App 端需调整项。**本报告不含代码改动。**

---

## 0. 后端变更要点（复述，便于对照）

1. **员工（TE）`following → converted` 放开**：原设计禁止，已修正为允许（限本人线索）。
2. **`converted` 设为全员硬终态**：任何角色（含管理员经 `recycle`）都无法改回，杜绝客户记录变孤儿。
3. **接口契约**：
   - `PATCH /leads/:id`：TE 现在允许 `following` 或 `converted`；置 `converted` 时后端自动建客户记录。
   - `POST /leads/:id/convert`：TE 现在可调用（原仅 manager）；要求本人 + `following` 态；成功返 `{id, customerId, status}`。
   - `POST /leads/:id/recycle`：已 `converted` 时返 `400 + STATUS_ROLLBACK_FORBIDDEN`。
4. **错误码**：`STATUS_ROLLBACK_FORBIDDEN`(400) / `AUTH_FORBIDDEN`(403) / `VALIDATION`(400)。
5. **环境**：仅测试环境（test）部署，生产（prod）暂未动。

---

## 1. App 现状盘点（基于实际代码）

| 维度 | 现状 | 落点 |
|---|---|---|
| 状态流转入口 | 仅「编辑线索」抽屉的状态 chips，**无独立转化 / 退回公海 / 分配按钮** | `edit_lead_dialog.dart` |
| TE 状态机 | `_forwardStatusMap` 硬编：`following→[following,converted]`、`converted→[converted]`、`assigned→[assigned,following]`、`invalid→[invalid,pending]` | `edit_lead_dialog.dart:39-45` |
| Manager 状态机 | 直接用全量 `LeadConstants.statusLabels.keys`（5 个状态全显示，含回退项） | `edit_lead_dialog.dart:75-98` |
| 详情页操作栏 | 「跟进 / 日程」对 `isConverted` 已置灰禁用；「编辑」始终可用 | `lead_detail_page.dart:179-220` |
| PATCH 提交 | `updateLead` 仅返 `bool`，**不返回 customerId** | `lead_service.dart:115-133` |
| 错误映射 | `STATUS_ROLLBACK_FORBIDDEN` 已有中文「状态回退被拒…」 | `error_messages.dart:12-13` |
| 转化错误展示 | 编辑弹窗 catch 统一吞成「保存失败，请重试」，**未用解析后的中文** | `edit_lead_dialog.dart:193-197` |
| 客户反向链 | 客户列表有 customer→lead 跳转，**无按 customerId 进客户详情的路由** | `customer_list_page.dart:170-174` |
| `/convert` 调用 | **App 完全没有**该端点调用 | grep 无命中 |
| `recycle` 调用 | **App 完全没有**（manager 也无退回公海入口） | grep 无命中 |

---

## 2. 差异分析（逐条对照后端 §1–§6）

### 2.1 已天然对齐（无需改，记录备查）
- ✅ TE `following → converted` 选项已存在（`_forwardStatusMap`）。
- ✅ `converted` 在编辑抽屉已是 `['converted']`（终态，无回退项）。
- ✅ 详情页「跟进 / 日程」对 converted 已禁用。
- ✅ `STATUS_ROLLBACK_FORBIDDEN` 中文文案已就绪。
- ✅ App 无 `recycle` 按钮 → 后端 §6.2「隐藏退回入口」天然满足。

### 2.2 主要缺口（需调整）

**缺口 A（P0，正确性）— manager 编辑可触发 400**
Manager 编辑 `converted` 线索时，状态 chips 显示全量 5 态，可选 `following`/`pending`/`assigned`，提交后后端返 `STATUS_ROLLBACK_FORBIDDEN`(400)。这正是后台 §8.2 在管理后台修掉的问题，App 未同步。
→ 应与管理后台一致：manager 也只列「当前状态的合法目标」。

**缺口 B（P0，可维护性）— 状态机散落硬编码**
`_forwardStatusMap` 与 manager 全量列表是两份独立来源，易与后端再次漂移。后台已抽 `LEAD_STATUS_TRANSITIONS` 为唯一数据源。
→ App 应抽权威状态机常量（`lead_constants.dart` 或新文件），TE 用前向表、manager 用「合法目标」表，二者同源。

**缺口 C（P1，错误清晰）— 具体错误被吞**
`edit_lead_dialog._submit` 的 catch 显示「保存失败，请重试」，丢弃了 `ApiClient.parseError` 解析出的中文（含 `STATUS_ROLLBACK_FORBIDDEN`）。
→ 改为展示 `ApiClient.parseError(e)` 文案，让用户看到「状态回退被拒…」。

**缺口 D（P1，既有行为冲突）— invalid→pending 走错通道**
`_forwardStatusMap['invalid'] = ['invalid','pending']` 走 PATCH；但后端该流转走专用 `reactivate` 接口，PATCH 状态机里 `invalid` 无出边。叠加本次「硬终态」语义后必被拒。
→ 需与后端确认 App 的重新激活是否曾生效；建议改为调用 reactivate 接口（若保留该功能）或从选项移除。

**缺口 E（P2，对应 §6.1）— 缺「标记为已转化」一键入口**
TE 只能在「编辑」抽屉里从状态下拉选 converted，无独立一键操作。后台 §6.1 建议补充。
→ 详情页对 `following` 线索（TE 亦可）增加「标记为已转化」操作，可复用 PATCH `status=converted` 或新增 `/convert` 调用。

**缺口 F（P2，对应 §6.4）— 转化后无「查看客户」引导**
后台转化自动建档客户，但 App 无法引导：① `updateLead` 只返 bool 拿不到 `customerId`；② 无 customerId→客户详情路由。
→ 若要做深链：新增 `/convert` 调用拿到 `customerId` + 新增客户详情页（或由客户列表按 `leadId` 反向定位）。否则至少 toast「已转化为客户并自动建档」。

---

## 3. 待确认问题（需用户 / 后端 / 产品拍板）

- **Q1 环境开关**：prod 尚未部署本次改动。App 若先发版并命中 prod，TE 转化会被后端拒（AUTH_FORBIDDEN/400）。是否需要环境开关（仅 test 放开转化能力），还是等 prod 部署后统一发版？
- **Q2 重新激活**：是否保留 `invalid → pending` 重新激活功能？保留则需补 `reactivate` 接口调用；不保留则从选项移除。
- **Q3 客户深链强度**：转化后「查看客户」是强诉求还是可选？决定是否投入缺口 F 的客户详情路由。
- **Q4 回收能力**：当前 App 无任何 `recycle` 入口（manager 也无）。确认 manager 后续是否需要「退回公海」能力——若需要，要新增 recycle 入口并处理 `STATUS_ROLLBACK_FORBIDDEN` 提示。

---

## 4. 建议实施顺序

1. **P0**：抽权威状态机常量（B）→ 替换 `_forwardStatusMap` 并让 manager 收敛到合法目标（A）。
2. **P1**：编辑弹窗 catch 展示解析中文（C）；与后端确认后处理 invalid→pending（D）。
3. **P2（视 Q1/Q3 结论）**：补「标记为已转化」入口（E）；视情况补 `/convert` + 客户深链（F）。
4. 全仓 `flutter analyze` + Redmi K60 真机实测（test 环境），重点验：TE 转化成功并自动建档、manager 编辑 converted 不再出现回退项、非法回退得到中文提示而非「保存失败」。

---

## 5. 一句话结论

App 在「TE 可转化 / converted 硬终态 / 无 recycle」三点已与后台对齐；**真正要改的是 manager 编辑的状态选项收敛（否则必 400）和把错误文案透出**，其余（一键转化、客户深链、重新激活通道）按 Q1–Q4 确认后作为增强项跟进。

