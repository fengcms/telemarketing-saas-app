# 计划：个人统计页（v0.32）

> 入口：个人中心 → 统计概览区（ProfileStatsCard）点击，及「个人统计」菜单项（当前 ComingSoon）。
> 设计文档：`docs/design/page-design/14-个人统计.md`（v1.1，2026-07-22，已按评审整改）。
> 接口：`GET /api/tenant/stats/mine?dateFrom=&dateTo=`（常量 `ApiConstants.statsMine` 已存在）。

## 1. 页面目标

展示当前用户个人业绩，支持日期范围筛选（今日/本周/本月/自定义）。两个**相互独立**的数据区：

- **今日概况**：固定展示 `myToday` 实时数据（今日跟进 / 今日接通），**不随日期 Tab 变化**。
- **数据详情 + 转化率环**：展示当前日期区间的 `myLeadsTotal/myFollowed/myAnswered/myNoAnswer/myConverted/myConversionRate`，**随 Tab 切换重新请求**。

## 2. 接口契约（来自 api.md §GET /api/tenant/stats/mine）

请求：`dateFrom` + `dateTo`（YYYY-MM-DD，必传，缺失后端返 VALIDATION）。
响应 `data` 字段：

| 字段 | 含义 | 用途 |
|------|------|------|
| `myLeadsTotal` | 名下线索总量 | 数据详情卡 + 转化率分母 |
| `myFollowed` | 累计跟进数 | 数据详情卡 |
| `myAnswered` | 累计接通数 | 数据详情卡 |
| `myNoAnswer` | 累计未接数 | 数据详情卡 |
| `myConverted` | 累计转化数 | 数据详情卡 + 转化率分子 |
| `myConversionRate` | 转化率 %（后端算，分母 0 返 0） | 直接展示，前端**不二次计算** |
| `myToday.followupCount` | 今日跟进数（实时） | 今日概况 |
| `myToday.answeredCount` | 今日接通数（实时） | 今日概况 |

> ⚠️ **接口待核实点（真机实测门禁）**：现有 `HomeStats.fromMyStats` 仅解析 `myToday` 子集 + `myLeadsTotal`，从未读取 `myFollowed/myAnswered/myNoAnswer/myConverted/myConversionRate`。这几字段由 api.md 文档声明，但本地代码未消费。本计划按文档建，待真机 Alice 抓包核对；若字段名/结构有出入，以实测为准微调模型解析。

## 3. 复用与新建

### 复用

- `ApiConstants.statsMine`（已存在，无需新增）
- `lib/pages/team_stats/widgets/date_range_selector.dart` 的日期选择交互模式（ChoiceChip 行 + 自定义范围选择），**改造复用**
- 公共组件：`AppErrorBody` / `AppEmptyBody`（空/错态）、`BrandColors`（primary #0052D9 / primarySurface #F2F3FF / textPrimary / textSecondary / success）

### 新建

| 文件 | 说明 |
|------|------|
| `lib/models/personal_stats.dart` | `PersonalStats`（8 字段 + 嵌套 `myToday`）+ `get conversionRateDisplay`；`_int` 安全转换 |
| `lib/services/home_service.dart`（扩展） | 加 `fetchPersonalStats({required from, required to})`，复用 `dio` + `statsMine`（与 `fetchMyStats` 同端点） |
| `lib/providers/personal_stats_provider.dart` | `PersonalStatsNotifier` + 日期范围状态（今日/本周/本月/自定义）+ 5 分钟按范围 key 缓存 |
| `lib/pages/personal_stats/personal_stats_page.dart` | `PersonalStatsPage`（ConsumerWidget）：AppBar「个人统计」+ 吸顶日期选择 + 滚动区 |
| `lib/pages/personal_stats/widgets/today_overview.dart` | 今日概况 2 卡（myToday） |
| `lib/pages/personal_stats/widgets/detail_grid.dart` | 数据详情 6 卡（区间字段） |
| `lib/pages/personal_stats/widgets/conversion_ring.dart` | 转化率环形（`CircularProgressIndicator` strokeWidth 12 + 中心 % + "转化 X / 线索 Y"） |
| `lib/pages/personal_stats/widgets/date_range_selector.dart` | 改造自 team stats 版本，放宽 90 天上限（设计允许超 1 年） |

### 修改

| 文件 | 说明 |
|------|------|
| `lib/pages/profile/profile_page.dart:200` | 「个人统计」菜单项 `ComingSoon` → `PersonalStatsPage()` |
| `lib/pages/profile/widgets/profile_stats_card.dart` | `onTap` `ComingSoon` → `PersonalStatsPage()`（设计：业绩概览区点击进个人统计） |

## 4. UI 规范（M3 适配，替代设计文档的 TDesign 组件）

| 设计文档（TDesign） | 本项目实现 |
|------|------|
| TDNavBar 品牌蓝 + 白字标题 | `AppBar`（buildBrandTheme 已给品牌色 + 白标题） |
| TDTabBar 4 Tab（今日/本周/本月/自定义） | `ChoiceChip` 行吸顶（复用 team stats 选择器交互） |
| 今日概况卡 brand-1 底 (#F2F3FF) + brand-7 数字 | `BrandColors.primarySurface` 底 + `BrandColors.primary` 32sp Bold 数字 |
| 数据详情 TDGrid 2 列 | `GridView` 2 列，灰底页 + 白卡 |
| 转化率 TDProgress 环形 120px | `CircularProgressIndicator`（strokeWidth 12，primary 填充，gray-2 背景环）+ 中心 28sp Bold % + 下方 "转化 X / 线索 Y" |
| TDSkeleton | 复用项目现有骨架（今日概况 2 块 / 数据详情 6 块 / 环形 1 块） |
| TDEmpty（空/错） | `AppEmptyBody` / `AppErrorBody`（含重试） |

## 5. 交互细节（来自设计文档 §4/§7）

- 默认选中「今日」Tab；首次加载骨架。
- 切 Tab：「今日概况」不变；「数据详情 + 转化率环」显示骨架并重新请求对应区间。
- 自定义范围：`showDateRangePicker`，设计允许超 1 年（本项目放宽 team stats 的 90 天上限，但保留「起 > 止」拦截 Toast）。
- 快速切 Tab：取消前一次请求（dio `CancelToken`），仅保留最新结果。
- 数值 > 9999：`formatBigNumber` 转 "w" 格式（复用 team stats 写法）。
- 转化率 > 100%：进度环上限 100%，文字照常显示。
- 字段为 null：显示 "—"。
- 接口失败：`AppErrorBody` + 重试；网络断开：Toast。
- 页面返回：保留 Tab 选择与日期范围状态。

## 6. 验证

| 项 | 方式 |
|------|------|
| `flutter analyze` | 全仓 0 error（含新增文件） |
| 构建 + 装真机 | `flutter build apk --release --dart-define=DEV_TOOLS=true` + `adb install -r` |
| 真机实测（门禁） | Alice 抓 `GET /api/tenant/stats/mine` 核对 8 字段齐全；两条入口（业绩卡 / 菜单项）跳转正常；4 个 Tab 切换数据正确 |
| 文档 | 写 `PROGRESS_PERSONAL_STATS-<date>.md` + 更新 MILESTONES（v0.32）+ 踩坑（如有） |

## 7. 风险

1. **接口字段未本地证实**（见 §2 ⚠️）：按 api.md 文档建，真机实测核对；若 `myFollowed` 等字段名/结构不符，以实测微调模型解析。
2. **转化率口径**：直接展示后端 `myConversionRate`，前端不二次计算（与团队统计不同，团队是前端算 `Σconverted/ΣownedLeads`）。
3. **KGP 告警**：沿用现状（方案 A 暂接受）。
