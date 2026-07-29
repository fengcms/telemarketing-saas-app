# 经理/管理员 首页与「我的」页 · 团队视角需求文档（定稿）

> 文档状态：✅ **已定稿** —— 后端按路径 B 实现并部署 test 环境（Version `9803a418`，2026-07-29）
> 本文档为本期需求**唯一真源**，取代前期《可行性确认文档》与《分析文档》中的待决策内容
> 关联文档：
> - 后端对接文档：`docs/dev/MANAGER_DASHBOARD_TODAY.md`（接口契约与实测样例，以该文档为准）
> - 前期文档（已归档，仅供参考）：`ANALYSIS_MANAGER_DASHBOARD.md`、`BACKEND_REQ_MANAGER_DASHBOARD.md`

---

## 1. Why · 背景与问题

当前 App 首页「今日工作概况」四宫格与「我的」页「我的业绩」卡片，**所有角色（TE / TM / TA）读取的内容完全一致**，均来自个人维度接口 `GET /api/tenant/stats/mine`。

但实际管理诉求是：

- **经理（TM）/ 管理员（TA）** 进入首页，想一眼看到 **全团队当日** 的跟进 / 接通 / 转化 / 待办，而不是只看到自己一个人的数据。
- **经理 / 管理员** 在「我的」页，也应看到「团队业绩概览」，而非与员工相同的个人业绩。

员工（TE）的体验保持不变，仍看个人数据。

> 这与早期设计文档 §7.4「TM/TA 首页仍展示个人数据」的旧约定冲突 —— **本期推翻该约定**。

---

## 2. Goal · 目标

仅对 **TM / TA** 改变两处的数据口径为「团队当日」，**TE 完全不变**：

1. 首页「今日工作概况」四宫格 → 团队当日数据
2. 「我的」页业绩卡片 → 「团队业绩概览」卡

---

## 3. Non-goals · 非目标

明确本期**不做**的事，防止范围蔓延：

- 不改 TE 任何展示与取数。
- 不改动 / 新增「团队统计」页（已存在，职责是坐席排行与明细，本期不受影响）。
- 不改动 `GET /api/tenant/stats/mine` 个人接口。
- 不区分「经理」与「管理员」的差异视图（后端角色无差异，前端合并为「管理视角」）。
- 不在首页做坐席排行 / 转化漏斗等重内容（那是团队统计页的职责）。
- 不新增后端字段或接口（后端已实现 `stats/today`，本期仅前端对接）。

---

## 4. 用户故事

- 作为**经理**，我希望进入首页一眼看到团队今日的跟进 / 接通 / 转化 / 待办，以便随时掌握全局进展。
- 作为**管理员**，我希望「我的」页展示团队业绩概览，以便快速了解团队产出。
- 作为**经理 / 管理员**，我仍希望一键查看「我自己的业绩」，以便了解个人贡献（保留个人入口）。

---

## 5. 范围（角色 × 页面）

| 角色 | 首页四宫格 | 「我的」页业绩卡 | 说明 |
|------|-----------|----------------|------|
| TE（员工） | 个人（现状不变） | 个人（现状不变） | 保持现状，不调用 `stats/today` |
| TM（经理） | **团队当日** | **团队业绩概览** | 本期调整对象 |
| TA（管理员） | **团队当日** | **团队业绩概览** | 本期调整对象 |

> 角色判定：`tenant_manager` 与 `tenant_admin` 合并为「管理视角」，前端已统一处理（`role_label.dart` + `isManager`）。后端接口权限保持现状：TM/TA 可调团队接口，TE 调 `stats/today` 返回 403（前端不会误调）。

---

## 6. 方案决策（已定稿）

**最终方案：路径 B —— 后端新增轻量接口 `GET /api/tenant/stats/today`，前端由该接口一次取全团队当日数据。**

后端已于 2026-07-29 在 test 环境实现并部署（Version `9803a418`）。前端不再复用 `GET /api/tenant/stats` 的 `dailyTrend`，也不依赖 `schedules/stats` 拼装。

### ⚠️ 关键语义修正（务必阅读，避免前端踩坑）

前期《可行性确认文档》§5.2 曾把字段注释为「= `dailyTrend[].followup` 当日增量」。后端在实现中明确纠正：

- `GET /api/tenant/stats` 读的是预聚合宽表 `lead_stats_daily`，而每日 `stats-aggregate` cron **只聚合「昨天」**；
- 因此若复用 `dailyTrend`，**当天几乎全天返回空数据**，首页四宫格会整天空白；
- 故 `stats/today` 改为 **实时 COUNT（北京时间今日窗口）**，今天任意时刻都能拿到真实当日进度。

**结论：前端不得假设 `stats/today` 的字段与 `dailyTrend` 存在任何映射 / 同源关系，仅按下方 §7 契约取数。**

---

## 7. 接口契约（定稿 · 唯一真源）

> 以下以 `docs/dev/MANAGER_DASHBOARD_TODAY.md` 为准。

### 7.1 接口

```
GET /api/tenant/stats/today
```

- **用途**：首页四宫格（团队今日跟进 / 接通 / 转化 / 待办）+「我的」页「团队业绩概览」卡，统一一次取全。
- **鉴权**：`Authorization: Bearer <accessToken>`；仅 `tenant_manager` / `tenant_admin` 可访问；`tenant_employee` 调用返回 **403**。
- **Query 参数**：无（时区固定北京时间；不传 `dateFrom/dateTo`）。
- **定位**：首页 /「我的」页团队视角热路径专用，响应体仅含几个数字，**不含** `agentPerf` / `funnel` / `byStatus` / `dailyTrend` 全量。

### 7.2 响应体（`data` 内）

统一信封 `{ "success": true, "data": { ... }, "error": null }`。

```json
{
  "todayFollowup": 128,   // 团队当日跟进次数
  "todayAnswered": 95,    // 团队当日接通数
  "todayConverted": 23,   // 团队当日转化数
  "todayAdded": 60,       // 团队当日新增线索
  "todayPending": 12,     // 团队今日待办
  "compareYesterday": {
    "followupDiff": 12,   // 较昨日同时段跟进差（正=增，负=减，0=持平）
    "answeredDiff": 5,    // 较昨日接通差
    "convertedDiff": 3    // 较昨日转化差
  }
}
```

### 7.3 字段精确口径

| 字段 | 含义 | 实时口径（tenant_id = 当前租户） |
|------|------|----------------------------------|
| `todayFollowup` | 团队今日跟进次数 | `COUNT(lead_followups)` WHERE `created_at ∈ [今日 00:00:00, 当前]` BJT |
| `todayAnswered` | 团队今日接通数 | `COUNT(call_records)` WHERE `answer_type='answered'` AND `started_at ∈ [今日 BJT 起, 当前]` AND `deleted_at IS NULL` |
| `todayConverted` | 团队今日转化数 | `COUNT(leads)` WHERE `status='converted'` AND `updated_at ∈ [今日 BJT 起, 当前]` AND `deleted_at IS NULL` |
| `todayAdded` | 团队今日新增线索 | `COUNT(leads)` WHERE `created_at ∈ [今日 BJT 起, 当前]` AND `deleted_at IS NULL` |
| `todayPending` | 团队今日待办 | `schedules`：`status='pending'` AND `deleted_at IS NULL` AND `scheduled_at ∈ [今日 00:00:00, 23:59:59]` BJT，**不含历史逾期**（与 `home-summary.todayPending` / `schedules/stats.todayPending` **同源同值**） |
| `compareYesterday.*` | 较昨日同时段差值 | 今日值 − 昨日实时值（昨日窗口 `[昨日 00:00:00, 23:59:59]` BJT）；正=增、负=减、0=持平 |

> `compareYesterday` 仅含 `followup/answered/converted` 三项（未含 `addedDiff`）。
> `todayPending` 与现有 `home-summary.todayPending` / `schedules/stats.todayPending` **同源同值**，已确认。

### 7.4 时区

全部「今日 / 昨日」边界以 **北京时间（Asia/Shanghai, UTC+8）** 计算，**不使用 Worker 运行时 UTC**。与 `schedules` 系列口径一致；刻意不沾 `lead_stats_daily` 宽表的 UTC 日期口径。

### 7.5 错误码

| HTTP | code | 前端处理 |
|------|------|---------|
| 200 | — | 正常渲染 |
| 401 | `AUTH_INVALID` / `AUTH_EXPIRED` | Token 失效，跳登录 |
| 403 | `AUTH_FORBIDDEN` | 非 TM/TA 角色（TE）调用；前端不应触发 |
| 500 | — | 错误态 + 重试 |

---

## 8. 前端实现要点（范围说明 · 本期不改代码，仅描述落地方式）

### 8.1 角色判定与取数分流
- 复用 `role_label.dart` + `isManager`；TM/TA 调用 `stats/today`，TE 继续走 `stats/mine`。
- 新增一个 Service 方法 + Provider（如 `managerTodayStatsProvider`），不改动现有 `teamStats` / `home` provider 的其它用途。

### 8.2 首页四宫格（TM/TA 版）

| 宫格 | 展示标签 | 取数字段 |
|------|---------|---------|
| 左上 | 团队今日跟进 | `todayFollowup` |
| 右上 | 团队今日接通 | `todayAnswered` |
| 左下 | 团队今日转化 | `todayConverted` |
| 右下 | 团队今日待办 | `todayPending` |

- 卡片区块标题建议改为「团队今日概览」。
- 可叠加 `compareYesterday` 环比小标（如 `↗ +12` / `↘ -8`），提升可读性（是否展示由产品确认，不影响接口）。

### 8.3 「我的」页团队业绩概览卡（TM/TA 版）
- 复用 §8.2 同一份 4 个数字，卡片标题改为「团队业绩概览」。
- 保留「查看我的业绩 →」入口，跳转 `PersonalStatsPage`（取 `stats/mine`），满足「我也是坐席」的诉求。

### 8.4 取数与刷新策略
- IndexedStack 常驻首屏进入即拉 `stats/today`；切回前台做轻量刷新（纯读、约 4~6 条索引列 COUNT，单租户 <50ms，开销低）。
- 原 `GET /api/tenant/schedules/stats`（团队日程统计）仍按现状为「日程 Tab」提供 `byStatus/overdue` 等，不受影响。

### 8.5 TE 不变
TE 首页与「我的」页维持现状，不调用 `stats/today`。

---

## 9. 验收标准

1. TM/TA 首页四宫格显示**团队当日**数据（非个人）。
2. TM/TA「我的」页显示「团队业绩概览」卡 + 「查看我的业绩 →」个人入口。
3. TE 的首页与「我的」页**完全不变**。
4. **任意时刻**（含上午刚上班）四宫格数据非空 —— 验证实时 COUNT 已解决路径 A「当天空白」问题。
5. 数据口径为**北京时间**。
6. 接口 401 / 403 / 500 处理正确（401 跳登录、500 错误态+重试、403 前端不触发）。
7. `todayPending` 与「我的待办 / 日程 Tab 今日待办」数值一致（同源确认）。

---

## 10. 风险与开放点

| 项 | 说明 | 处理 |
|----|------|------|
| 环境同步 | 后端当前仅 test 环境（Version `9803a418`）实现，生产需同步部署 | 联调用 test；上线前确认生产已发 |
| 字段语义 | `stats/today` 为实时 COUNT，**非** `dailyTrend` | 已在 §6 强调，前端不得关联宽表 |
| `todayAdded` 是否展示 | 接口已返回，首页四宫格当前用 4 项（不含 added） | 建议本期不放入四宫格；「我的」卡可酌情展示，待产品确认 |
| `compareYesterday` 是否展示 | 接口已返回 3 项差值 | 建议展示环比小标，待产品确认（不影响接口） |
| 经理/管理员差异化 | 后端无角色差异，前端合并处理 | 本期不区分，后续如有需要再评估 |

---

## 11. 关联文档

- 后端对接文档（契约真源）：`docs/dev/MANAGER_DASHBOARD_TODAY.md`
- 前期可行性确认（已归档）：`docs/dev/BACKEND_REQ_MANAGER_DASHBOARD.md`
- 前期分析（已归档）：`docs/dev/ANALYSIS_MANAGER_DASHBOARD.md`

---

*文档版本：v1.0 · 2026-07-29 · 需求定稿（后端已实现路径 B 并部署 test 环境）*
