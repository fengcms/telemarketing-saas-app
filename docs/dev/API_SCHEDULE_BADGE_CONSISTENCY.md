# 日程「待办数」口径一致性评估（给后端）

> 文档目的：前端（APP）发现**同一用户在同一 App 内，不同位置显示的「待办数」不一致**，现把问题、字段语义、候选方案整理清楚，请后端评估可行性并回答文末问题。本文不要求立即改代码，先对齐口径。

---

## 一、现象（用户视角的 Bug）

同一个账号，进入 App 后看到两个不同的「待办数」：

| 位置 | 当前读取字段 | 示例值 |
|------|-------------|--------|
| 首页「今日待办」Badge | `home-summary.todayPending` | **5** |
| 首页四宫格「今日到期」卡 | `home-summary.todayPending` | **5** |
| 底部 Tab「日程」角标 | `schedules/stats/mine.dueToday` | **7** |
| 个人中心「今日待办」 | `schedules/stats/mine.dueToday` | **7** |

首页说「5」，Tab 角标和个人中心说「7」，**用户会认为数据错了**。

---

## 二、两个根因字段的精确语义（带证据）

### 2.1 `home-summary.todayPending`（首页在用）
- 定义来源：`docs/dev/HOME_SCHEDULE_MERGE_FRONTEND_GUIDE.md` 第四节表
- 语义：`scheduledAt` 落在**北京时间当天 00:00:00 ~ 23:59:59** 且 `status=pending`，**不含历史逾期未办**（严格今日窗口）。
- 该端点是 v0.27（2026-07-25）新增，首页并行请求由 4→2。

### 2.2 `schedules/stats/mine.dueToday`（Tab 角标 / 个人中心在用）
- 定义来源：`docs/api.md` 第 1835~1855 行（GET /api/tenant/schedules/stats/mine）
- 响应示例（api.md:1852）：
  ```json
  { "byStatus": { "pending": 5, "completed": 3, "cancelled": 1, "overdue": 2, "dueToday": 7 } }
  ```
- 由示例可反推：`dueToday(7) = pending(5) + overdue(2)`。
- 即 `dueToday` = **所有未完成日程**（`scheduledAt <= 今天 23:59:59`，无下限，**含历史逾期**）。
- 后端在前述指南文档第 78 行也明确写过：「旧 `dueToday` 口径是 `scheduledAt <= 今天 23:59:59`（无下限，含历史逾期）。新 `todayPending` 是「严格今日窗口，不含逾期」。两者数值在『存在逾期待办』时**会不同**，新值更小。」——当时定义为「预期行为，非 Bug」。

### 2.3 一个关键发现（可能免后端改动）
`stats/mine` 已经返回了 `pending`（示例中 =5），且其值与 `home-summary.todayPending`（严格今日）语义几乎等同。
也就是说：**前端之所以出现不一致，是因为 Tab 角标 / 个人中心选了 `dueToday`（含逾期）这个字段，而不是 `pending`（严格今日）。**

---

## 三、候选方案（请后端评估可行性 + 工作量）

### 方案 A：前端只改读取字段（可能零后端改动）
- 把 Tab 角标 + 个人中心的 `dueToday` 改为读 `stats/mine.pending`（严格今日）。
- **前提**：后端需**确认** `stats/mine.pending` 与 `home-summary.todayPending` 语义完全一致（同口径、同时区边界、无 off-by-one）。两者由不同代码路径计算，需核对。
- 风险：逾期（overdue）事项将**不再出现在任何角标**中（首页也不显示 overdue）——逾期任务可能「看不见」了，是否可接受是产品决策（见第四节）。
- 工作量：前端小；后端仅「确认口径」。

### 方案 B：后端在 `stats/mine` / `stats` 显式新增 `todayPending`
- 在 `GET /api/tenant/schedules/stats/mine` 和团队版 `GET /api/tenant/schedules/stats` 的响应里都加上 `todayPending`（= 严格今日窗口），与 `home-summary` 字段名对齐。
- 前端把 Tab 角标 + 个人中心切到 `todayPending`，`dueToday` 保留（向后兼容或标记 deprecated）。
- 优点：字段名统一、语义无歧义，不依赖「两个端点 pending 是否完全等价」的猜测。
- 工作量：后端小（复用 home-summary 的计算逻辑）；前端小。

### 方案 C：修改 `dueToday` 语义为严格今日（破坏性）
- 把 `stats/mine.dueToday` 的计算改成与 `todayPending` 一致。
- **风险**：任何其它消费 `dueToday` 的端（Web 后台 / 其它 App / 报表）会受影响，属于破坏性变更。
- 工作量：后端小，但需先排查全部消费者（见问题 1）。**不推荐**，除非确认无其他消费者。

### 方案 D：反过来，把首页也统一到「含逾期」口径
- 首页「今日待办」改读 `dueToday`（含逾期），与 Tab / 个人中心一致。
- 与 v0.27 的既定设计（首页用严格今日窗口）冲突，且会让首页数字偏大、与「今日待办」字面语义不符。
- **不推荐**。

---

## 四、必须先由产品拍板的一个问题

角标的职责是「吸引用户注意未办事项」。**逾期事项往往比今天新排的更该被看见**。因此：

- 若统一到**严格今日**（`todayPending` / `pending`）：数字变小、干净，但逾期事项从角标消失（需另想办法呈现逾期，如单独红色「逾期 N」角标，或列表内逾期高亮）。
- 若统一到**含逾期**（`dueToday`）：数字大、注意力强，但和首页「今日待办」字面不符。

**这是产品决策，不是技术决策。** 建议产品确认：角标到底想表达「今天该做的」还是「所有没做完的（含逾期）」。

---

## 五、需要后端回答的问题

1. **`dueToday` 还有其它消费者吗？**（Web 后台、报表、其它端）若有，方案 C 直接否决，方案 A/B 也要确认不影响它们。
2. **`stats/mine.pending` 与 `home-summary.todayPending` 是否语义完全一致？** 若一致，方案 A 可零后端改动落地；若不完全一致（如时区边界、是否含 `scheduledAt == 23:59:59`），请指出差异，我们改用方案 B。
3. **团队版 `stats`（TA/TM）是否也返回 `pending` / `dueToday`？** 底部 Tab 角标在 TM/TA 下走的是 `fetchTeamScheduleStats`（见 `lib/providers/schedule_stats_provider.dart:94`），需确认团队端点字段齐备，否则方案 A/B 在管理角色下会取不到数。
4. **如果产品决定角标要「含逾期」，是否接受**：首页维持 `todayPending`（严格今日），而 Tab / 个人中心用 `dueToday`（含逾期）——即**故意保留两个口径但分别标注**（首页标「今日待办」、角标标「待办」）。这样无需改后端，只是 UX 文案区分。请评估这种「双口径 + 不同标签」是否会被用户理解，或仍认为混乱。

---

## 六、现状代码位置（供核对）

| 文件 | 行 | 内容 |
|------|----|----|
| `lib/pages/home/home_schedule_section.dart` | ~51/63 | 首页待办 Badge 读 `state.todayPending` |
| `lib/pages/home/home_stats_section.dart` | ~104 | 四宫格「今日到期」读 `state.todayPending` |
| `lib/pages/main_shell.dart` | 92 | Tab 角标读 `scheduleStatsProvider.dueToday` |
| `lib/pages/profile/profile_page.dart` | 172 | 个人中心读 `scheduleStatsProvider.dueToday` |
| `lib/providers/schedule_stats_provider.dart` | 65 | `dueToday => stats?.dueToday ?? 0` |
| `lib/services/home_service.dart` | — | `fetchHomeSummary()` 解析 `todayPending` |
| `docs/api.md` | 1835~1855 | `stats/mine` 字段定义与示例 |
| `docs/dev/HOME_SCHEDULE_MERGE_FRONTEND_GUIDE.md` | 69 / 78 | `todayPending` 与 `dueToday` 语义差异说明 |

---

## 七、一句话总结

首页用「严格今日」(`todayPending`)，Tab 角标 / 个人中心用「含逾期」(`dueToday`)，二者在有逾期待办时天然不同。技术上**方案 A（前端改读 `pending`，需后端确认等价）或方案 B（后端补 `todayPending` 字段）** 都能消除不一致；但角标是否该包含逾期，需产品先定调，后端据此评估落地路径。
