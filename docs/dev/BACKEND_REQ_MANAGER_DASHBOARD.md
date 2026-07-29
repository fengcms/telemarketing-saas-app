# 后端需求 / 可行性确认文档

## 经理（TM）· 管理员（TA）首页与「我的」页团队视角

> 文档用途：本期**优先路径 B**——请后端按 §5 新增一个轻量接口 `GET /api/tenant/stats/today`。
> 若后端评估后认为**无需新增接口**（现有接口性能完全可接受），则退而走 **路径 A**（复用现有接口，零新增），并需逐项确认 §4.4。
> **最终以本页 §6 决策请求中后端的回复为准。**

---

## 1. 背景与业务诉求

当前 App 首页「今日工作概况」四宫格与「我的」页「我的业绩」卡片，**所有角色（TE/TM/TA）读取的内容完全一致**，均来自个人维度接口 `GET /api/tenant/stats/mine`。

但实际管理诉求是：

- **经理（TM）/ 管理员（TA）** 进入首页，想一眼看到 **全团队当日** 的跟进 / 接通 / 转化 / 待办，而不是只看到自己一个人的数据。
- **经理 / 管理员** 在「我的」页，也应看到「团队业绩概览」而不是与员工相同的个人业绩。

员工（TE）的体验保持不变，仍看个人数据。

**目标**：仅对 TM/TA 改变首页四宫格与「我的」页业绩卡片的数据口径，复用现有团队统计能力；**推荐后端新增一个轻量接口**以兼顾首页热路径的性能与响应速度。

---

## 2. 范围（角色与页面）

| 角色 | 首页四宫格 | 「我的」页业绩卡 | 说明 |
|------|-----------|----------------|------|
| TE（员工） | 个人（现状不变） | 个人（现状不变） | 保持现状 |
| TM（经理） | **团队当日** | **团队业绩概览** | 本期调整对象 |
| TA（管理员） | **团队当日** | **团队业绩概览** | 本期调整对象 |

> 角色判定：`tenant_manager` 与 `tenant_admin` 合并为「管理视角」，前端已统一处理；**后端接口权限保持现状**（TM/TA 可调团队接口，TE 调团队接口返回 403）。

---

## 3. 方案决策：路径 B（优先）

**路径 B = 后端新增轻量接口 `GET /api/tenant/stats/today`，前端首页热路径只取几个数字。**

- 首页团队版四宫格（团队今日跟进 / 接通 / 转化 / 待办）与「我的」页团队业绩卡，**统一由这一个接口返回**，无需前端拼接多个现有接口。
- 响应体**仅含当日几个统计数字 + 环比**，不含 `agentPerf` / `funnel` / `byStatus` / `dailyTrend` 全量，体积小、首页进入即取即渲染，性能最优。

**为何优先走 B**：首页是 TM/TA 每次启动 / 切回都命中（IndexedStack 常驻）的热路径。现有 `GET /api/tenant/stats` 即便传今日范围，响应体仍带完整坐席列表等大块数据，首页仅需要其中 4 个数字。新增一个专用轻量接口，既避免首页拉全量、又让前端取数逻辑更清晰，是更稳妥的默认选择。

**路径 A（备选）**：若后端评估认为现有 `GET /api/tenant/stats` 在今日范围下性能完全可接受、且不愿新增接口，则退而复用现有接口（详见 §4），后端零改动。

---

## 4. 路径 A：备选复用方案（仅当后端选择不新增接口时）

若后端在 §6 决定不走 B，则前端复用现有接口，需后端逐项确认以下事项。

### 4.1 复用的现有接口清单

| 接口 | 路径 | 现状 | 本次用法 |
|------|------|------|---------|
| 团队统计 | `GET /api/tenant/stats` | 已在「团队统计」页使用 | 首页传 `dateFrom=dateTo=今日` 取 `dailyTrend[0]` |
| 团队日程统计 | `GET /api/tenant/schedules/stats` | 已在启动期拉取（TM/TA） | 复用其 `todayPending`（团队今日待办） |

### 4.2 首页四宫格（TM/TA）字段映射

| 宫格 | 展示标签 | 取数字段 | 来源 |
|------|---------|---------|------|
| 左上 | 团队今日跟进 | `dailyTrend[0].followup` | `stats`（今日范围） |
| 右上 | 团队今日接通 | `dailyTrend[0].answered` | `stats`（今日范围） |
| 左下 | 团队今日转化 | `dailyTrend[0].converted` | `stats`（今日范围） |
| 右下 | 团队今日待办 | `todayPending` | `schedules/stats`（团队版，已拉取） |

### 4.3 「我的」页团队业绩卡（TM/TA）字段映射

复用 §4.2 同一份「团队当日」数据（4 个数字），卡片标题改为「团队业绩概览」，并保留「查看我的业绩 →」个人入口。

### 4.4 需后端确认的问题（走 A 时逐条回复 ✅/❌ + 说明）

> **Q1 — 单日范围 `dailyTrend` 行为**
> 当 `dateFrom == dateTo`（同一天，如 `2026-07-29`）时，`GET /api/tenant/stats` 的 `dailyTrend` 是否：
> - (a) 返回且仅返回该 1 天的数据点？
> - (b) `dailyTrend[0].date` 等于该日，且 `dailyTrend[0]` 对应该日？
>
> 前端依赖 `dailyTrend[0]` 即为「今日」数据点。

> **Q2 — `dailyTrend` 字段语义（关键）**
> `dailyTrend[].followup / answered / converted / added` 的语义是 **「当日发生的事件计数（增量）」** 还是 **「截至当日累计」**？
> 首页四宫格需要的是 **当日增量**（如「今天团队跟进了多少次」）。请确认当前实现为增量口径；若不是，请说明实际口径。

> **Q3 — 团队今日待办口径**
> `GET /api/tenant/schedules/stats`（团队版）返回的 `todayPending` 是否确为 **全团队** 今日待办口径（北京时间今日窗口、`status=pending`、不含历史逾期）？
> 是否与前端的 `home-summary.todayPending` 同源、数值一致？

> **Q4 — 性能（最关键）**
> `GET /api/tenant/stats` 即使在「今日」单日范围下，响应体是否仍包含完整 `agentPerf[]`（全坐席列表）、`funnel`、`byStatus` 等大块数据？
> 首页热路径（每次进入首页 TM/TA 都会拉）仅需 `dailyTrend[0]` 的 4 个数字。
> 请确认这份全量响应的体积是否可接受（团队通常几十人，预估几十 KB）？
>
> 若不可接受 → 说明后端倾向走路径 B（新增轻量接口）。

> **Q5 — 时区与参数合法性**
> - `dateFrom` / `dateTo` 同时传 **同一天** 是否为合法请求（不返回 400 `VALIDATION`）？
> - 日期范围以哪个时区为准？是否统一为 **北京时间（Asia/Shanghai）**？（前端传入 `YYYY-MM-DD` 格式，无时分秒）

---

## 5. 路径 B：轻量接口规格（优先落地）

后端新增以下轻量接口，前端首页团队视角与「我的」页团队业绩卡统一由此接口取数（不再调用 `GET /api/tenant/stats` 取首页数据）。

### 5.1 新增接口

```
GET /api/tenant/stats/today
```

- **鉴权**：需登录；`tenant_manager` / `tenant_admin` 返回团队当日数据；`TE` 调用返回 `403 AUTH_FORBIDDEN`（前端 TM/TA 才调用，不会误调）。
- **Query 参数**：无（时区固定北京时间；如需可扩展 `?tz=Asia/Shanghai`，默认即可）。
- **定位**：首页 / 「我的」页团队视角热路径专用，响应体仅含几个数字，**不含** `agentPerf` / `funnel` / `byStatus` / `dailyTrend` 全量。

### 5.2 响应体（`data` 内）

```json
{
  "todayFollowup": 128,   // 团队当日跟进数（= dailyTrend[].followup 当日增量）
  "todayAnswered": 95,    // 团队当日接通数（= dailyTrend[].answered 当日增量）
  "todayConverted": 23,   // 团队当日转化数（= dailyTrend[].converted 当日增量）
  "todayAdded": 60,       // 团队当日新增线索（= dailyTrend[].added，可选，前端暂用可留）
  "todayPending": 12,     // 团队今日待办（= schedules/stats.todayPending，合并进此接口以少一次请求）
  "compareYesterday": {
    "followupDiff": 12,    // 较昨日跟进差（正=增，负=减）
    "answeredDiff": 5,    // 较昨日接通差
    "convertedDiff": 3     // 较昨日转化差
  }
}
```

> 统一信封：`{ "success": true, "data": { ... }, "error": null }`（与全局 API 约定一致）。
> `todayPending` 合并进此接口后，前端首页团队版 4 个数字 **仅 1 次请求**即可拿到，不依赖 `schedules/stats`（但 `schedules/stats` 仍按现状为日程 Tab 提供团队统计，不受影响）。

### 5.3 错误码

| HTTP | 处理 |
|------|------|
| 200 | 正常 |
| 401 | Token 失效，前端跳登录 |
| 403 | 非 TM/TA 角色，前端不应调用（防御性） |
| 500 | 前端显示错误态 + 重试 |

---

## 6. 决策请求（请后端回复）

默认走 **路径 B**。请后端确认：

1. **（推荐）走路径 B**：后端按 §5 新增 `GET /api/tenant/stats/today`。前端首页团队版 4 个数字 + 环比一次请求拿全，性能最优，前端取数逻辑最清晰。
2. **（备选）走路径 A**：若后端认为现有 `GET /api/tenant/stats` 在今日范围下性能完全可接受、且不愿新增接口，请基于 §4.4 逐项确认 Q1~Q5，前端改为复用现有接口。

> 前端已就绪：路径 B 仅新增一个 Service 方法 + Provider，工作量小；路径 A 仅改前端取数逻辑。
> 无论选 B 还是 A，员工（TE）首页与「我的」页均保持不变。

---

## 7. 附录：现有接口契约速查（已确认）

| 项 | 内容 |
|----|------|
| 团队统计 | `GET /api/tenant/stats?dateFrom=YYYY-MM-DD&dateTo=YYYY-MM-DD`（必传两参，缺失 400） |
| 团队统计响应 | `total` / `byStatus{pending,assigned,following,converted,invalid}` / `poolTotal` / `staleInPool` / `funnel{pending,assigned,following,converted}` / `agentPerf[]` / `dailyTrend[]{date,added,followup,converted,answered,total}` / `compareYesterday{addedDiff,followupDiff,convertedDiff}` |
| 团队日程统计 | `GET /api/tenant/schedules/stats`（无 scope 参数，按角色自动全团队；TM/TA 才有值） |
| 团队日程统计响应 | `pending` / `completed` / `cancelled` / `overdue` / `todayPending`（今日待办，北京时间今日窗口） |
| 个人统计 | `GET /api/tenant/stats/mine`（TE/TM/TA 均返回本人维度，本期不改） |
| 首页日程聚合 | `GET /api/tenant/schedules/home-summary`（含 `todayPending` 个人口径，与 `schedules/stats.todayPending` 同源） |

---

*文档版本：v1.1 · 2026-07-29 · 前端 ↔ 后端可行性对齐用（v1.1：主推路径由 A 调整为 B）*
