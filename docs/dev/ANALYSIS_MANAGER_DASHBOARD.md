# 首页 & "我的"页面 · 经理/管理员视角调整分析

> 文档类型：产品/技术可行性分析（不改代码，仅方案设计）
> 版本：v0.1（2026-07-29）
> 作者：产品通（结合现有接口 + 已开发团队统计）
> 关联文档：`03-首页看板.md`、`13-个人中心.md`、`21-团队统计.md`、`20-团队入口.md`、`00-全局API约定.md`

---

## 0. 一句话结论

员工视角已经完善，**经理/管理员当前在首页和"我的"页看到的内容与员工完全一致**，这是设计文档 §7.4 明确写下的"TM/TA 首页仍展示个人数据（团队数据在独立页面）"——现在认为不合理。

两个调整点都可以**完全复用现有接口 + 已开发的团队统计**，不需要改后端：

1. **首页"今日工作概况"四宫格**：经理/管理员从"个人今日"切换为"团队今日"，数据来自 `GET /api/tenant/stats`（今日范围）+ 已存在的 `scheduleStatsProvider.teamStats`。
2. **"我的"页"我的业绩"栏**：经理/管理员从"个人业绩"切换为"团队业绩概览"卡，复用同一份团队今日数据，并保留"个人业绩"入口。

唯一的代价是首页高频场景会多拉一次团队全量统计（含坐席列表），有性能冗余，**建议后续由后端补一个轻量今日概览接口**（见 §6 路径 B）。

---

## 1. 问题陈述

| # | 现状（员工视角合理，经理/管理员不合理） | 期望（经理/管理员） |
|---|----------------------------------------|---------------------|
| P1 | 首页"今日工作概况"四宫格 = 个人今日数据（`stats/mine`） | 看到**全部人员**的今日统计 |
| P2 | "我的"页"我的业绩"栏 = 个人业绩卡（`myLeadsTotal/followupCount/answeredCount/todayPending`），经理/管理员与员工完全一致 | 看到**团队业绩概览**，而非个人 |

> 设计文档 §7.4 现状原文：
> "TM/TA 角色 | TDNavBar 显示'团队看板'按钮；**首页仍展示个人数据（团队数据在独立页面）**"
> 这正是本次要推翻的约定。

---

## 2. 现有接口与 Provider 能力盘点（事实基础）

### 2.1 关键接口

| 接口 | 路径 | 维度 | 当前用途 | 能否复用 |
|------|------|------|---------|---------|
| `stats/mine` | `/api/tenant/stats/mine` | **个人** | 首页四宫格（员工）、个人业绩卡 | 员工视角仍用；经理/管理员"个人业绩"入口复用 |
| `stats` | `/api/tenant/stats` | **团队全量**（按 dateFrom/dateTo 区间聚合） | 团队看板页（tm/ta） | ✅ 经理/管理员首页+我的页核心数据源（传今日范围） |
| `schedules/stats/mine` | `/api/tenant/schedules/stats/mine` | 个人日程统计 | 今日待办角标 | 员工视角 |
| `schedules/stats` | `/api/tenant/schedules/stats` | **团队日程统计**（含团队 `dueToday`） | 日程 Tab"团队"视图、`scheduleStatsProvider.teamStats` | ✅ 经理/管理员"今日待办"直接复用（已拉取） |
| `schedules/home-summary` | `/api/tenant/schedules/home-summary` | 个人首页聚合 | 首页今日待办+预览 | 员工视角；**无团队参数** |

### 2.2 `stats` 接口（团队全量）返回结构（来自 `21-团队统计.md` + `team_stats.dart`）

| 字段 | 含义 | 首页/我的页可提取 |
|------|------|------------------|
| `total` | 总线索数（快照口径，待确认） | 团队线索总数 |
| `byStatus` | { pending, assigned, following, converted, invalid } 当前状态分布 | 跟进中=`following` |
| `poolTotal` | 公海线索数 | 公海数 |
| `staleInPool` | 呆滞数 | 公海告警 |
| `funnel` | { pending, assigned, following, converted } 区间转化漏斗 | — |
| `agentPerf[]` | 各坐席 { ownedLeads, followupCount, answeredCount, convertedCount, ... } | 累加可得团队今日汇总（兜底） |
| `dailyTrend[]` | 区间按天明细 { date, added, followup, converted, answered, total } | **今日范围只有 1 天，`dailyTrend[0]` 即团队今日增量** ✅ |
| `compareYesterday` | { addedDiff, followupDiff, convertedDiff } | 仅"今日"范围有意义 |

> **核心取法**：经理/管理员首页拉 `stats(dateFrom=今天, dateTo=今天)`，`dailyTrend` 仅含当天一条，`dailyTrend[0].followup / .answered / .converted` 即团队今日跟进/接通/转化。无需累加 `agentPerf`（更轻）。

### 2.3 关键事实：团队今日待办"已存在"

`schedule_stats_provider.dart` 启动即同时拉取 `mineStats`（个人）与 `teamStats`（团队，仅 TM/TA），`teamStats.todayPending` 就是**团队今日待办数**。

```dart
// schedule_stats_provider.dart 已存在
ScheduleStatsState get teamStats => state.teamStats;  // 含 todayPending（团队口径）
```

→ 首页经理/管理员版"今日待办"无需新接口、无额外请求，直接 watch 现有 provider。

### 2.4 角色判定（已统一）

```dart
// role_label.dart
String roleLabel(String? role) {
  case 'tenant_employee': return '电销专员';
  case 'tenant_manager':  return '团队经理';
  case 'tenant_admin':    return '管理员';
}

// 判定（profile_page / schedule_stats_provider 已用）
bool isManager = role == 'tenant_manager' || role == 'tenant_admin';
```

> 当前实现中**经理与管理员合并处理**（后端团队统计接口对两者无差异）。文档统一称"经理/管理员"，如需差异化需后端支持且本期不建议。

---

## 3. 首页"今日工作概况"调整方案（P1）

### 3.1 设计目标

- 经理/管理员首屏一眼看到**团队今日运转全貌**，而不是自己那一份。
- 指标口径与团队看板页保持一致（同一 `stats` 接口），避免数字对不上。
- 员工视角**零改动**。

### 3.2 四宫格指标映射（推荐版：今日增量语义）

| 位置 | 员工（现状） | 经理/管理员（推荐） | 数据来源 |
|------|------------|-------------------|---------|
| 左上 | 今日跟进 | **团队今日跟进** | `stats(today).dailyTrend[0].followup` |
| 右上 | 今日接通 | **团队今日接通** | `stats(today).dailyTrend[0].answered` |
| 左下 | 我的线索 | **团队今日转化** | `stats(today).dailyTrend[0].converted` |
| 右下 | 今日到期（个人） | **团队今日待办** | `scheduleStatsProvider.teamStats.todayPending` |

> 为什么左下从"我的线索"换成"团队今日转化"：经理/管理员看"我的线索"无管理意义；"团队今日转化"是更值得管理者盯的指标。原员工四宫格没有"今日转化"是因为 `stats/mine.myToday` 缺 `convertedCount`，但团队 `stats` 的 `dailyTrend` 有 `converted`，补齐合理。

### 3.3 备选版（团队快照语义，可选）

若更想看"当前团队状态"而非"今日增量"，可替换为：

| 位置 | 指标 | 来源 |
|------|------|------|
| 左上 | 团队总线索 | `total` |
| 右上 | 公海线索 | `poolTotal` |
| 左下 | 跟进中 | `byStatus.following` |
| 右下 | 团队转化率 | `teamConversionRate`（前端按 `Σconverted/ΣownedLeads` 算） |

> **推荐"今日增量版"**：与"今日工作概况"标题语义一致、与团队看板"今日"范围环比（`compareYesterday`）可呼应。

### 3.4 数据获取与复用

- **前 3 项**：需 `stats` 今日范围。
  - 复用已开发的 `TeamStatsService`（`team_stats_service.dart`，无需改）。
  - 新增一个 `teamTodayStatsProvider`（today 范围，5 分钟缓存，与看板页 thisWeek 不同 key 共存）；或扩展 `teamStatsProvider` 支持 today 共享。**首页与"我的"页共 watch 这一个 provider**，避免重复请求。
- **第 4 项**：复用 `scheduleStatsProvider.teamStats.todayPending`（**零新增请求**，该 provider 每次启动/刷新已拉）。

### 3.5 性能考量（重要，用户高度重视）

| 风险 | 说明 | 缓解 |
|------|------|------|
| 首页拉全量团队统计 | `stats` 返回 `agentPerf[]`（全坐席）+ `funnel` + `dailyTrend` + `byStatus`，比 `stats/mine` 重 | 团队规模通常几十人，JSON 几十 KB，可接受 |
| 与看板页缓存重复 | 首页 today 与看板 thisWeek 是不同缓存 key | 共用 `TeamStatsService` + 5 分钟缓存；首页轮询 10 分钟 > 缓存 5 分钟，基本不额外增请求 |
| 前后台切频繁请求 | 首页已有 60 秒节流（`onResume` 节流） | 团队今日数据纳入同一节流，必要时用 `teamTodayStatsProvider` 的本地缓存秒开 |

---

## 4. "我的"页面"我的业绩"调整方案（P2）

### 4.1 当前

`ProfileStatsCard` 取 `myLeadsTotal / followupCount / answeredCount / todayPending`（个人），经理/管理员与员工一致 → 不合理。

### 4.2 经理/管理员版：改为"团队业绩概览"卡

| 位置 | 指标 | 数据来源（复用 §3） |
|------|------|-------------------|
| 1 | 团队今日跟进 | `teamTodayStatsProvider.dailyTrend[0].followup` |
| 2 | 团队今日接通 | `teamTodayStatsProvider.dailyTrend[0].answered` |
| 3 | 团队今日转化 | `teamTodayStatsProvider.dailyTrend[0].converted` |
| 4 | 团队今日待办 | `scheduleStatsProvider.teamStats.todayPending` |

卡标题由"我的业绩"改为"**团队业绩**"（或"团队今日概览"）。

### 4.3 保留个人视角入口

经理/管理员**既是管理者也是坐席**，应保留看自己业绩的入口：

- 在团队业绩卡下方加一行小字/按钮"查看我的业绩 →"，跳转现有 `PersonalStatsPage`（`stats/mine` 区间，已开发）。
- 满足"我也要看自己今天打了多少通"的诉求，不与团队视角冲突。

### 4.4 数据复用

- 与首页共 watch `teamTodayStatsProvider`（today 范围），**同一份数据不重复拉**。
- 个人业绩入口走 `homeService.fetchPersonalStats`（`stats/mine` 区间），已有。

---

## 5. 关联影响（需同步评估，非本期必做）

首页与"我的"页不止四宫格/业绩卡，其他区块对经理/管理员也存在"个人 vs 团队"错位，建议一并评估：

| 区块 | 现状（个人） | 经理/管理员建议 | 接口依赖 |
|------|------------|----------------|---------|
| 首页待办日程预览（5 条） | `home-summary.schedules`（个人） | 切团队日程预览 | `home-summary` 无团队参数，需后端加 `?scope=team` 或团队日程列表前 5 条 |
| 首页快捷入口"我的线索" | 副标题 `myLeadsTotal`（个人） | 文案改"团队线索"，副标题取团队线索总数（leads `scope=all` 的 total / `stats.total`） | 线索 Tab 已 `scope=all`，仅取数口径调整 |
| 首页即将到期提醒条 | 个人 `home-summary.dueSoonCount` | 是否看团队即将到期？可复用团队日程统计 | 待决策 |
| 底部 Tab 角标 | 个人 `todayPending` | 经理/管理员是否显示团队待办角标 | `scheduleStatsProvider.teamStats` 已具备 |

> 本期聚焦 P1+P2（用户明确要求）；上表为后续迭代清单，不阻塞本期。

---

## 6. 两种实现路径对比

| 维度 | 路径 A：纯复用现有接口（零后端） | 路径 B：后端新增轻量今日概览（推荐优化） |
|------|--------------------------------|----------------------------------------|
| 后端改动 | 无 | 新增 `GET /api/tenant/stats/today`（仅返团队今日轻量数字） |
| 前端改动 | 新增 `teamTodayStatsProvider`；`home_stats_section` / `profile_page` / `profile_stats_card` 加角色分支 | 同上 + 对接轻量接口 |
| 性能 | 首页每次拉 `stats` 全量（含 agentPerf） | 首页只拉 4-5 个数字，最优 |
| 数据一致性 | 与团队看板页同源（`stats`） | 同源 |
| 实时性 | 5 分钟缓存 + 10 分钟轮询 | 同 |
| 落地速度 | 快（纯前端） | 需后端排期 |
| 风险 | 团队规模大时首页流量略增 | 低 |

**建议**：路径 A 先落地验证体验；若团队规模大 / 高频轮询出现压力，再推路径 B 作为性能优化。

---

## 7. 待决策点（需产品/用户确认）

1. **四宫格语义**：经理/管理员版用"今日增量"（跟进/接通/转化/待办）还是"团队快照"（总线索/公海/跟进中/转化率）？→ 推荐"今日增量"。
2. **"我的"页与首页是否一致**：两者都用同一套"团队今日"指标，还是"我的"页用快照？→ 推荐一致（今日增量）。
3. **性能路径**：接受路径 A（首页拉 `stats` 全量），还是要求后端补轻量接口（路径 B）？
4. **关联区块**：是否本期一并调整首页日程预览 / 快捷入口文案 / 提醒条（§5）？还是收敛到 P1+P2？
5. **经理 vs 管理员**：是否需差异化（当前后端无差异，建议合并）？

---

## 8. 影响范围（后续开发清单，本期不改代码）

| 层 | 文件 | 改动 |
|----|------|------|
| Provider | 新增 `teamTodayStatsProvider`（today 范围） | 复用 `TeamStatsService` + 5 分钟缓存 |
| Provider | `home_provider.dart` | 按角色分支：经理/管理员取团队今日数据 |
| 首页 | `home_stats_section.dart` | 四宫格指标按角色取团队/个人 |
| 我的页 | `profile_page.dart` | "我的业绩"→"团队业绩概览"卡；加"个人业绩"入口 |
| 我的页 | `profile_stats_card.dart` | 支持团队业绩卡样式（或直接复用于团队数据） |
| 工具 | `role_label.dart` | 抽共享 `isManagerRole(role)`（目前各处内联） |
| 不变 | 员工视角所有行为、`team_stats_page.dart`、`schedule_stats_provider.dart` | 零改动 |

---

## 9. 非目标（Non-goals）

- 不改后端（除非路径 B 决策）。
- 不重做团队统计看板页（已完善，仅复用其数据）。
- 不做经理/管理员差异化（除非决策要求）。
- 不改动员工视角任何行为。
- 不调整首页布局结构（仅换数据源与文案）。

---

## 10. 用户故事（验收视角）

- 作为**团队经理**，我希望打开 App 首页就能看到团队今天的跟进/接通/转化/待办总量，以便我开工即掌握团队进度，而不必点进团队看板。
- 作为**管理员**，我希望在"我的"页看到团队业绩概览，并能一键跳到自己个人业绩，以便我既管理团队也关注自身产出。
- 作为**电销专员**，我希望我的首页和"我的"页保持原样，不受角色调整影响。
