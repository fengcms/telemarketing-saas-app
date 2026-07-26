# 开发规划：团队日程视图（v0.24 落地）

> 设计文档：docs/design/page-design/22-团队日程.md
> 对应 PLAN_24_TEAM_MODULE.md 阶段二
> 可见角色：TM（租户经理）、TA（租户管理员）；TE 不可见切换

---

## 一、现状盘点（已具备，不重复造）

经读代码核对，团队视图的「取数 + 切换」基础设施已在前期节点完成，本次只需补**团队专属 UI 件**：

| 能力 | 位置 | 状态 |
|------|------|:----:|
| 「我的 / 团队」切换控件（仅 TM/TA 可见） | `schedule_list_page.dart` `AppScopeToggle` + `canTeam` | ✅ 已有 |
| 切换 scope 改数据源（team 时 `userId=null` → 后端自动返回全团队） | `schedule_list_provider.dart` `switchScope` / `_userId` | ✅ 已有 |
| 缓存按 `$scope:$tab` 维度（切回不重复请求） | 同文件 `_cache` | ✅ 已有 |
| 团队日程列表接口（`userId:null` 即全团队） | `schedule_service.dart` `fetchSchedules` | ✅ 已有 |
| 团队统计接口（`todayPending` + `overdue`） | `schedule_service.dart` `fetchTeamScheduleStats` | ✅ 已有 |
| 卡片归属人姓名 | `schedule_card.dart` `_OwnerRow`（显示「归属：xxx」） | ✅ 已有（但**无颜色圆点**） |
| 归属人颜色工具 | `lib/theme/user_color.dart` `userColor(userId)`（8 色池，hashCode 取模） | ✅ 已有 |
| 成员列表（员工筛选下拉源） | `options_cache_service.dart` `getUsers()`（缓存 `/options/users`） | ✅ 已有 |
| 统计模型（todayPending + overdue） | `schedule_stats.dart` `ScheduleStats` | ✅ 已有 |

---

## 二、本次新增（团队视图专属 UI 件）

### A. 归属人颜色圆点

- `ScheduleCard` 增 `ownerColor` 参数（`Color?`）；`_OwnerRow` 在圆点前加 **10px 圆形色块**，姓名同行。
- 颜色由列表页在 `items` 循环里统一用 `userColor(item.userId)` 计算后下发（卡片保持纯展示、不持 Riverpod，与现有 `ownerName` 下发方式一致）。

### B. 团队统计摘要条（仅 `scope=='team'` 显示）

- 新组件 `TeamScheduleSummaryBar`：

  ```
  📊 今日待办 12 条    ⚠️ 逾期 3 条
  ```

  - 今日待办：数字 `bold` + `BrandColors.primary`；逾期：数字 `bold` + `BrandColors.error`，逾期为 0 时改灰（`textSecondary`）。
  - 背景 `BrandColors.surface`（#F3F3F3），高 48px，左右 16px 内边距。
- **数据源**：
  - 未选成员 → 读 `state.teamStats`（由 `fetchTeamScheduleStats` 拉取，全团队口径，与首页/home-summary 同源）。
  - 已选成员 → 本地从**该成员当前列表**计算 today-pending / overdue（见 C 方案）。
- **位置**：scope 切换所在 AppBar 下方、现有「待办 / 已完成」Tab 栏上方（仅 team 视图渲染，mine 视图不显示）。

### C. 员工筛选（仅 `scope=='team'`）

- 触发控件：一行显示当前选择（「全部成员」或「● 姓名」带颜色圆点），点击弹出。
- 弹出：`AppBottomSheet.show` 列出成员（`getUsers()` 结果，每项：颜色圆点 + 姓名 + role 标签），顶部含「全部成员」项（圆点灰色）。成员 >20 时 sheet 内滚动。
- 选中后行为（二选一，见第五节待拍板 1）：
  - **方案① 前端过滤**：从已加载 `state.items` 按 `userId` 过滤展示；摘要条切到该成员本地统计。
  - **方案② 后端过滤**：重新请求 `fetchSchedules(status:activeTab, userId:选中id)` 替换团队列表；摘要条从该成员返回结果本地计算。
- 状态存 notifier：`selectedOwnerId`（仅 team 视图有效；切回 `mine` 或切 Tab 时重置为 null）。

---

## 三、数据来源核对（已读 api.md + 现有代码确认，非猜测）

| 接口 | 路径 | 用途 | 字段确认 |
|------|------|------|---------|
| 团队统计 | `GET /api/tenant/schedules/stats` | 摘要条（未选成员） | `byStatus.overdue` + 顶层 `todayPending`（全团队，严格今日窗口）✅ 与 home-summary 同源 |
| 成员列表 | `GET /api/tenant/options/users` | 员工筛选下拉 | `data` 直接数组 `[{id,name,role}]`，无分页，已缓存 ✅ |
| 团队日程列表 | `GET /api/tenant/schedules` | 列表本体 | TM/TA 调用 `userId` 不传 → 后端自动全团队 ✅（`schedule_service.dart` 已实现） |

> 全团队日程数据量（设计文档估算 30~250 条）可控；现有 provider 分页 `size=20` + 滚动加载更多，team 视图沿用，无需改成一次性全量加载。

---

## 四、涉及文件

| 文件 | 改动 |
|------|------|
| `lib/pages/schedules/schedule_list_page.dart` | ① team 视图下在 Tab 栏上方插入「摘要条 + 员工筛选」头部；② 列表循环里计算并下发 `ownerColor`；③ 接 `selectedOwnerId` 过滤后的 items |
| `lib/pages/schedules/widgets/schedule_card.dart` | 增 `ownerColor` 参数，`_OwnerRow` 加 10px 颜色圆点 |
| `lib/providers/schedule_list_provider.dart` | ① 增 `teamStats` 字段（scope==team 时拉取 `fetchTeamScheduleStats`）；② 增 `selectedOwnerId` 字段 + `selectOwner(id)` 方法；③ scope 切换 / mine 时重置；④ 摘要条 per-member 本地统计计算 |
| `lib/pages/schedules/widgets/team_schedule_header.dart`（新建） | 封装「摘要条 + 员工筛选」头部（仅 team 显示），含成员 sheet 逻辑 |
| `lib/widgets/app_*` 公共组件 | 复用 `AppBottomSheet` / `AppTag` 等，不新增通用组件 |

---

## 五、待你拍板（不猜，确认后再写代码）

### 1. 员工筛选的实现方式

- **方案① 前端过滤已加载数据**：切成员不重新请求，瞬间过滤。
  - ⚠️ 隐患：provider 分页加载，若用户未滚动到底，该成员日程可能只加载了部分 → 过滤后的列表与「逾期/今日待办」统计**可能不全**。
- **方案② 后端 `userId` 过滤（推荐）**：选成员时重新请求 `fetchSchedules(userId:选中id)`，列表与统计均准确；代价是多一次请求（与 design §4.2「无需重新请求」假设冲突，但该假设基于「数据已全部加载」，本 APP 实际分页，故②更准）。

### 2. 日期筛选（今天 / 明天 / 本周 / 自定义）

- 设计 §3.3 / §4.3 要求团队视图有日期筛选，**仅滚动定位、不改数据**（列表已按日期分组 + 吸顶头，点头已可滚动定位）。
- 本次**做**还是**延后**？（建议延后——现有按日期分组 + 吸顶 + 点击滚动已覆盖核心诉求，避免一次塞太多。）

---

## 六、明确不做（本次）

- 团队统计独立页（阶段三 v0.25，需引入 `fl_chart`）——独立节点。
- 搜索框（设计 §7.1 标注可选）——本次不做。
- 归属人颜色图例（设计 §3.6 可选）——本次不做。

---

## 七、验证清单（真机，TM/TA 账号）

1. 日程 Tab 顶部出现「我的 / 团队」切换；切到「团队」→ 列表显示全团队日程、每条带归属人**颜色圆点 + 姓名**。
2. 团队视图顶部出现摘要条：今日待办 N · 逾期 M（与首页四宫格 todayPending 同源一致）。
3. 员工筛选：选某成员 → 列表仅该成员日程、摘要条同步该成员统计；选「全部成员」恢复。
4. 切回「我的」→ 摘要条/筛选消失，恢复个人视图；底部 Tab 始终保留。
5. `flutter analyze` 0 issue；release + DEV_TOOLS 构建装 Redmi K60 验证。

---

## 八、执行记录（2026-07-26）

### 已落地（全部按计划，方案② + 日期筛选放弃；开发中发现 role 漏解析一并修复）

| 模块 | 文件 | 说明 |
|------|------|------|
| 归属人颜色圆点 | `schedule_card.dart` + `schedule_list_page.dart` | `ScheduleCard` 增 `ownerColor`；列表循环 `userColor(id)` 下发；`_OwnerRow` 圆点前加 10px 圆形色块 |
| 团队统计摘要条 | `team_schedule_header.dart`（新建） | 仅 team 渲染：`今日待办 N`（brand）+ `逾期 M`（error，0 转灰）；未选成员读 `teamStats`，已选成员从本地列表算 |
| 员工筛选 | `schedule_list_page.dart` + `schedule_list_provider.dart` | 方案② 后端 `userId` 过滤；`selectOwner(id)` 重置+重拉，成员维度独立缓存键；sheet 列成员（颜色圆点+姓名+角色） |
| Provider 改造 | `schedule_list_provider.dart` | 增 `teamStats`/`selectedOwnerId` 字段；`_cacheKey` 含 owner；`_loadTeamStats()`；`switchScope`/`refresh` 同步 |
| 角色标签修复（连带） | `option_item.dart` / `role_label.dart`（新建）/ `profile_page.dart` / `schedule_list_page.dart` | `OptionItem.role` 补字段+解析；抽共享 `roleLabel()`；筛选成员项现显「姓名 · 角色」 |

### 验证（真机，用户确认通过）

1. 日程 Tab「我的 / 团队」切换；团队视图每条带归属人颜色圆点 + 姓名 ✅
2. 团队视图摘要条：今日待办 N · 逾期 M（与首页 home-summary 同源）✅
3. 员工筛选选成员 → 列表仅该成员、摘要条同步；选「全部成员」恢复 ✅
4. 切回「我的」→ 摘要条 / 筛选消失，底部 Tab 保留 ✅
5. `flutter analyze` 本次 5 改动文件 + 新建 3 文件 0 issue（全仓仅 `token_storage.dart` 11 个预存 warning 无关）✅；release + DEV_TOOLS 构建装 Redmi K60 实测通过 ✅

> 文档状态：已开发完成 + 真机实测通过 | 进度见 `PROGRESS_TEAM_SCHEDULE_VIEW-2026-07-26.md`
