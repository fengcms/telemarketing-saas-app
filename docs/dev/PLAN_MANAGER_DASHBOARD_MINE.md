# 开发计划 · 「我的」页团队业绩概览卡（页面 2 / TM-TA 视角）

> 关联需求：`docs/dev/REQ_MANAGER_DASHBOARD.md`（v1.0 定稿）
> 关联计划：`docs/dev/PLAN_MANAGER_DASHBOARD.md`（整体计划，首页为页面 1，本文件为页面 2）
> 后端接口：`GET /api/tenant/stats/today`（test 环境 Version `9803a418`，已实现部署）
> 日期：2026-07-29

---

## 1. 目标

仅对 **TM / TA** 调整「我的」页业绩区块：
- 区块标题由「我的业绩」→「团队业绩概览」
- 卡片由个人 4 项（我的线索 / 今日跟进 / 今日接通 / 今日待办，来自 `stats/mine`）→ 团队 4 项（团队今日跟进 / 接通 / 转化 / 待办，来自 `stats/today`）+ 环比小标
- 保留「查看我的业绩 →」个人入口（跳 `PersonalStatsPage`，取 `stats/mine`）

**TE 完全不变**：仍显示「我的业绩」+ `ProfileStatsCard`（个人数据）。

---

## 2. 涉及文件

| 文件 | 改动 |
|------|------|
| `lib/pages/profile/profile_page.dart` | 「我的业绩」区块按 `isManager` 分支：TM/TA 渲染新团队卡 + 标题改「团队业绩概览」+ 标题右侧「查看我的业绩 →」入口；`_load()` 按角色拉 `fetchManagerTodayStats()`（TM/TA）或 `fetchMyStats()`（TE）；新增 `_ManagerStatsCardSkeleton` / 团队错误态复用现有 `_statsErrorWidget` |
| `lib/pages/profile/widgets/team_stats_overview_card.dart` | **新建**：团队业绩概览卡片。4 列（跟进/接通/转化/待办），每列 数字(20px bold 品牌色) + 环比小标(11px 绿↗/红↘/灰—) + 标签(12px 灰)；风格对齐 `ProfileStatsCard` |
| `lib/models/manager_today_stats.dart` | 复用（页面 1 已建，无需改） |
| `lib/services/home_service.dart` | 复用 `fetchManagerTodayStats()`（页面 1 已加，无需改） |
| `lib/services/api_constants.dart` | 复用 `statsToday`（页面 1 已加，无需改） |

> 说明：本期 `profile_page` 对 TM/TA **独立调用** `fetchManagerTodayStats()`，不依赖 `home_provider` 内联的 `managerTodayStats`，保持页面解耦、可被 IndexedStack 独立刷新。代价是 TM/TA 进入「我的」Tab 时比首页多 1 次轻量请求（接口仅几行 COUNT，单租户 <50ms），可接受。后续若需消除重复，可统一抽到独立 `managerTodayStatsProvider` 让两页共享，非本期必须。

---

## 3. 字段映射（团队卡）

| 列 | 标签 | 数据 | 环比 |
|----|------|------|------|
| 1 | 团队今日跟进 | `todayFollowup` | `compareYesterday.followupDiff` |
| 2 | 团队今日接通 | `todayAnswered` | `compareYesterday.answeredDiff` |
| 3 | 团队今日转化 | `todayConverted` | `compareYesterday.convertedDiff` |
| 4 | 团队今日待办 | `todayPending` | 不显示（接口未返回对应 diff） |

- 环比规则：diff > 0 → `↗ +N`（绿 `#2BA471`）；diff < 0 → `↘ N`（红 `#D54941`）；diff == 0 → `—`（灰）；null → 不显示
- 数字格式化沿用 `ProfileStatsCard` 的 `>9999 → '9999+'`
- 团队待办 `todayPending` 直接取 `ManagerTodayStats.todayPending`（与 `schedules/stats.todayPending` 同源，无需额外取 `scheduleStatsProvider`）

---

## 4. 角色判定

复用 `profile_page.dart` 现有 `isManager`（已定义）：
```dart
final isManager = role == 'tenant_manager' || role == 'tenant_admin';
```
TE 走原 `ProfileStatsCard` 分支，不调用 `stats/today`（避免 403）。

---

## 5. 刷新与状态

- 首屏 `_load()` 按角色并行拉：TE 拉 `fetchMyStats`；TM/TA 拉 `fetchManagerTodayStats`
- 下拉刷新 `_load` 复用同一逻辑
- 骨架屏：`_isLoading` 时显示 `_ManagerStatsCardSkeleton`（4 列占位，对齐新卡布局）
- 错误态：加载失败显示 `_statsErrorWidget()`（点击重试，与现有一致）
- `todayPending` 团队待办已包含在 `ManagerTodayStats`，无需 watch `scheduleStatsProvider`

---

## 6. 验收标准（真机，TM/TA 账号）

1. 「我的」页区块标题显示「团队业绩概览」，卡片 4 项为团队当日数据（非个人）
2. 卡片 4 列下方显示环比小标（跟进/接通/转化），待办列无小标
3. 区块标题右侧「查看我的业绩 →」点击跳 `PersonalStatsPage`，展示**个人**业绩
4. TE 账号登录：「我的」页仍显示「我的业绩」+ 个人 4 项，行为完全不变
5. 任意时刻数据非空（实时 COUNT，上午刚上班也有值）
6. 下拉刷新 / 进入页面正确加载；失败可点重试

---

## 7. 风险与开放点

- **环境**：后端仅 test 环境部署 `stats/today`，联调用 test；上线前确认生产已发
- **重复请求**：TM/TA 进入「我的」Tab 会多拉 1 次 `stats/today`（见 §2 说明），可接受
- **非目标**：不改 `PersonalStatsPage` 本身、不改 TE 任何逻辑、不区分经理/管理员差异

---

## 8. 不在本期范围

- 首页（页面 1）已在上轮完成，本计划仅覆盖「我的」页
- 团队统计页 / 日程 Tab 不受影响

---

*计划版本：v1.0 · 2026-07-29 · 页面 2（「我的」页团队业绩卡）*
