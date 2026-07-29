# 开发计划 · 经理/管理员首页 & 「我的」页团队视角

> 需求定稿：`docs/dev/REQ_MANAGER_DASHBOARD.md`（v1.0）
> 后端接口：`GET /api/tenant/stats/today`（已实现，test 环境 Version `9803a418`）
> 设计文档：`docs/design/page-design/03-首页看板.md`、`docs/design/page-design/13-我的.md`
> 本计划分两个页面推进，本期先完成 **页面 1（首页四宫格）**，真机验证后再做页面 2（「我的」页）。

---

## 一、目标

仅对 **TM / TA** 改变两处数据口径为「团队当日」，TE 完全不变：

1. 首页「今日工作概况」四宫格 → 团队当日（跟进 / 接通 / 转化 / 待办）
2. 「我的」页业绩卡 → 「团队业绩概览」卡（下一轮）

已确认的两点决策：
- 四宫格用 **4 项**（跟进/接通/转化/待办），`todayAdded` 不进四宫格
- 展示 `compareYesterday` **环比小标**（跟进/接通/转化三项；待办无环比）

---

## 二、接口与字段（契约真源：`MANAGER_DASHBOARD_TODAY.md`）

```
GET /api/tenant/stats/today   // 无参，Bearer 鉴权，仅 TM/TA，TE 调返回 403
```

| 字段 | 首页四宫格 | 含义 |
|------|-----------|------|
| `todayFollowup` | 团队今日跟进 | 实时 COUNT，北京时间今日窗口 |
| `todayAnswered` | 团队今日接通 | 实时 COUNT |
| `todayConverted` | 团队今日转化 | 实时 COUNT |
| `todayPending` | 团队今日待办 | 与 `home-summary.todayPending` 同源同值 |
| `compareYesterday.followupDiff` | 跟进环比 | 较昨日同时段，正增/负减/0 持平 |
| `compareYesterday.answeredDiff` | 接通环比 | 同上 |
| `compareYesterday.convertedDiff` | 转化环比 | 同上 |

> ⚠️ 该接口为**实时 COUNT**，**非** `dailyTrend` 宽表（今天整天为空）。前端不得关联宽表口径。

---

## 三、页面 1：首页四宫格（本期实现）

### 3.1 新增文件

- `lib/models/manager_today_stats.dart`
  - `ManagerTodayStats`：`todayFollowup/todayAnswered/todayConverted/todayAdded/todayPending`（int）+ `compareYesterday`（嵌套）
  - `CompareYesterday`：`followupDiff/answeredDiff/convertedDiff`（int）
  - `fromJson` 统一从 `data` 解析，含 `_toInt` 兜底

### 3.2 修改文件

- `lib/services/api_constants.dart`
  - 新增 `static const String statsToday = '/api/tenant/stats/today';`
- `lib/services/home_service.dart`
  - 新增 `fetchManagerTodayStats()`：GET `statsToday`，解析 `ManagerTodayStats`；失败 `ApiException`
- `lib/providers/home_provider.dart`
  - `HomePageState` 新增：`isManager`(bool)、`managerTodayStats`(ManagerTodayStats?)、`managerStatsError`(String?)
  - `copyWith` 同步新增字段
  - `loadData()`：读当前用户角色算 `isManager`；TM/TA 时并行多拉一次 `fetchManagerTodayStats()`，合并进 state
  - `_silentRefresh()`：同步刷新 manager today 数据
  - `retryStats()`：复用 `loadData()`（已覆盖）
- `lib/pages/home/home_stats_section.dart`
  - 区块标题：`isManager ? '团队今日概览' : '今日工作概况'`
  - 渲染分流：`isManager` 用 `managerTodayStats` 渲染团队四宫格；否则走原个人四宫格
  - 团队卡片：值 + 标签 + 环比小标（`followup/answered/converted` 三项带 ↗/↘ 差分色；待办无）
  - 加载/错误态：manager 分支复用 `isLoadingStats` / `managerStatsError`，错误显示重试（回调 `retryStats`）

### 3.3 取数与刷新

- 复用现有 `HomePageNotifier` 的 `loadData` / `refresh` / `_silentRefresh` / `onResume` 体系，manager 数据随首页整体刷新一起更新（IndexedStack 常驻、切回前台、10 分钟轮询均覆盖）。
- TE 不调用 `stats/today`（角色前置判断），避免 403。

---

## 四、页面 2：「我的」页团队业绩卡（下一轮，本期不实现）

- `lib/pages/profile/profile_page.dart` 的「我的业绩」卡：TM/TA 改为「团队业绩概览」卡，复用 `managerTodayStats` 同 4 数字；保留「查看我的业绩 →」跳 `PersonalStatsPage`（取 `stats/mine`）。
- 复用本期新增的 `managerTodayStatsProvider` **式数据源**（页面 1 落地后抽取为独立 provider 供两页共享，避免重复请求）。
- 本期计划单列，待页面 1 真机验证通过后再写实现。

---

## 五、影响范围

- 仅 TM/TA 首页四宫格变化；TE 首页无任何改动。
- 不影响团队统计页、日程 Tab、`stats/mine`、"我的"页（页面 2 下一轮）。
- 不新增后端接口（后端已实现）。

---

## 六、真机验证要点（页面 1）

1. 用 **TM/TA 账号**登录：首页四宫格显示「团队今日概览」，4 项均为团队当日数据（非个人）。
2. 用 **TE 账号**登录：首页四宫格仍为个人「今日工作概况」，行为不变。
3. 上午刚上班等任意时刻，TM/TA 四宫格有数据（验证实时 COUNT，非空白）。
4. 四宫格下方显示环比小标（↗ 绿 / ↘ 红 / — 灰）。
5. 下拉刷新、切后台再回前台、静置 10 分钟，TM/TA 四宫格正确刷新。
6. 断网/弱网时错误态 + 重试可用。

---

*计划版本：v1.0 · 2026-07-29 · 页面 1（首页四宫格）本期实现，页面 2 下一轮*
