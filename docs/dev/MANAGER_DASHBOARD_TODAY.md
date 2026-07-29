# 经理/管理员 · 首页团队当日概览接口（前端对接文档）

> 关联需求：`docs/BACKEND_REQ_MANAGER_DASHBOARD.md`
> 状态：🟢 已实现并部署 test 环境（Version `9803a418`，2026-07-29）
> 基线：`design.md` v0.37

---

## 1. 接口概览

```
GET /api/tenant/stats/today
```

- **用途**：首页四宫格（团队今日跟进 / 接通 / 转化 / 待办）+「我的」页「团队业绩概览」卡，**统一由这一个接口一次取全**。
- **鉴权**：`Authorization: Bearer <accessToken>`；仅 `tenant_manager`(TM) / `tenant_admin`(TA) 可访问；`tenant_employee`(TE) 调用返回 **403**（前端仅 TM/TA 调用，不会误调）。
- **Query 参数**：无（时区固定北京时间；无需传 `dateFrom/dateTo`）。
- **定位**：首页 /「我的」页团队视角热路径专用，响应体仅含几个数字，**不含** `agentPerf` / `funnel` / `byStatus` / `dailyTrend` 全量，体积小、进入即渲染。

> ⚠️ **与需求文档路径 A 的关键差异（务必阅读 §5）**：本接口**不复用** `GET /api/tenant/stats` 的 `dailyTrend`，也不读 `lead_stats_daily` 预聚合宽表。原因是宽表由每日 cron 仅聚合「昨天」，今天这一行要等次日 cron 跑完才落库，全天为空。本接口改为**实时 COUNT（北京时间今日窗口）**，今天任意时刻都能拿到当日进度。

---

## 2. 响应体（`data` 内）

统一信封 `{ "success": true, "data": { ... }, "error": null }`。

```json
{
  "todayFollowup": 128,   // 团队当日跟进次数（lead_followups 今日 created_at 计数）
  "todayAnswered": 95,    // 团队当日接通数（call_records answer_type=answered 今日 started_at 计数）
  "todayConverted": 23,   // 团队当日转化数（leads status=converted 今日 updated_at 计数）
  "todayAdded": 60,       // 团队当日新增线索（leads 今日 created_at 计数，不含已删）
  "todayPending": 12,     // 团队今日待办（= schedules/stats.todayPending，全团队·北京时间·今日窗口）
  "compareYesterday": {
    "followupDiff": 12,   // 较昨日同时段跟进差（正=增，负=减，0=持平）
    "answeredDiff": 5,    // 较昨日接通差
    "convertedDiff": 3    // 较昨日转化差
  }
}
```

### 字段口径（精确）

| 字段 | 含义 | 实时 SQL 口径（tenant_id = 当前租户） |
|------|------|----------------------------------------|
| `todayFollowup` | 团队今日跟进次数 | `COUNT(lead_followups)` WHERE `created_at ∈ [今日 00:00:00, 当前]` BJT |
| `todayAnswered` | 团队今日接通数 | `COUNT(call_records)` WHERE `answer_type='answered'` AND `started_at ∈ [今日 BJT 起, 当前]` AND `deleted_at IS NULL` |
| `todayConverted` | 团队今日转化数 | `COUNT(leads)` WHERE `status='converted'` AND `updated_at ∈ [今日 BJT 起, 当前]` AND `deleted_at IS NULL` |
| `todayAdded` | 团队今日新增线索 | `COUNT(leads)` WHERE `created_at ∈ [今日 BJT 起, 当前]` AND `deleted_at IS NULL` |
| `todayPending` | 团队今日待办 | 实时 `schedules`：`status='pending'` AND `deleted_at IS NULL` AND `scheduled_at ∈ [今日 00:00:00, 23:59:59]` BJT，**不含历史逾期**（与 `home-summary.todayPending` / `schedules/stats.todayPending` **同源同值**） |
| `compareYesterday.*` | 较昨日同时段差值 | 今日值 − 昨日实时值（昨日窗口 = `[昨日 00:00:00, 23:59:59]` BJT）；正=增、负=减、0=持平 |

> `compareYesterday` 仅含 `followup/answered/converted` 三项（按需求文档 §5.2，未要求 `addedDiff`）。

---

## 3. 时区

- 全部「今日 / 昨日」边界以 **北京时间（Asia/Shanghai, UTC+8）** 计算，**不使用 Worker 运行时 UTC 时间**。
- 这与 `schedules` 系列（`home-summary` / `stats` / `stats/mine` 的 `todayPending`、`myToday`）口径一致；与 `lead_stats_daily` 宽表的 **UTC 日期** 是不同口径，本接口刻意不沾宽表以免混淆。

---

## 4. 错误码

| HTTP | code | 前端处理 |
|------|------|---------|
| 200 | — | 正常渲染 |
| 401 | `AUTH_INVALID` / `AUTH_EXPIRED` | Token 失效，跳登录 |
| 403 | `AUTH_FORBIDDEN` | 非 TM/TA 角色（TE）调用；前端不应触发 |
| 500 | — | 错误态 + 重试 |

---

## 5. 为什么不是「复用 `GET /api/tenant/stats`」（需求文档路径 A 不可行）

- `GET /api/tenant/stats` 读预聚合宽表 `lead_stats_daily`，而每日 `stats-aggregate` cron **只聚合昨天**（`yesterdayStr()`）。
- 因此 `GET /api/tenant/stats?dateFrom=今日&dateTo=今日` 在**当天几乎全天返回「无数据」**，首页四宫格会整天空白。
- 故后端采用需求文档的 **路径 B**，但将字段来源从「`dailyTrend[]`（宽表）」**纠正为「实时 COUNT」**，确保今天任意时刻都有真实当日进度。前端取数字段名（`todayFollowup/answered/converted/added/pending`、`compareYesterday`）与需求文档 §5.2 完全一致，无需改名。

---

## 6. 前端取数建议

- **TM/TA 首页团队版四宫格** + **「我的」页「团队业绩概览」卡**：均调用本接口一次，取 `todayFollowup/todayAnswered/todayConverted/todayPending` 四个数；卡片标题改为「团队业绩概览」，并保留「查看我的业绩 →」个人入口（`GET /api/tenant/stats/mine`）。
- **TE 不受影响**：仍走 `GET /api/tenant/stats/mine`（个人维度），不调用本接口。
- 进首屏（IndexedStack 常驻）即拉本接口；可做轻量轮询或切回前台刷新（纯读、开销低，约 4~6 条索引列 COUNT，单租户 <50ms）。
- 原 `GET /api/tenant/schedules/stats`（团队日程统计）仍按现状为「日程 Tab」提供 `byStatus/overdue` 等，不受影响。

---

## 7. 实测样例（test 环境）

请求：
```bash
curl -H "Authorization: Bearer $TM_TOKEN" \
  https://tm-api-test.kao9.com/api/tenant/stats/today
```

响应（示例，反映实时数据）：
```json
{
  "success": true,
  "data": {
    "todayFollowup": 0,
    "todayAnswered": 0,
    "todayConverted": 0,
    "todayAdded": 0,
    "todayPending": 1,
    "compareYesterday": { "followupDiff": -8, "answeredDiff": -1, "convertedDiff": 0 }
  },
  "error": null
}
```

> 部署信息：test `telemarketing-saas-be-test`（workers.dev 与 `tm-api-test.kao9.com` 同源），Version `9803a418`（2026-07-29）。无 schema 迁移。
