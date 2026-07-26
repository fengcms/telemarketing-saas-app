# 进度文档：团队统计独立页（v0.25）

> 日期：2026-07-26
> 计划：`docs/dev/PLAN_29_TEAM_STATS.md`
> 对应 `PLAN_24_TEAM_MODULE.md` 阶段三；可见角色：TM（租户经理）/ TA（租户管理员），TE 不可见。

## 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 数据模型 `team_stats.dart` | ✅ | 映射 `GET /api/tenant/stats` 响应（pending 单键契约）。`TeamStatusBreakdown{pending,assigned,following,converted,invalid}`+sum；`TeamFunnel{pending,assigned,following,converted}`；`AgentPerf{...}`+`conversionRate`(后端不返，前端算)；`DailyTrend{...}`+`mmdd`；`TeamCompare`；`TeamStats{...}`+`teamConversionRate`(Σconverted/ΣownedLeads)。各 `fromJson` 用 `_int()` 防 int/double/字符串/null。 |
| 服务层 `team_stats_service.dart` | ✅ | `fetchTeamStats({dateFrom,dateTo})` → `GET ApiConstants.statsTeam`；`success!=true` 抛 `ApiException`；body 含 `message` 且无 `total` → 抛 `NoDataInRangeException`（区间无数据）；其余 `TeamStats.fromJson`。 |
| 状态管理 `team_stats_provider.dart` | ✅ | `TeamStatsNotifier` + `TeamStatsState`（sentinel `_Unset`/`_unset` 区分未传/传 null，定义前移避免前向引用）；`DateRangeKind{today,thisWeek,thisMonth,custom}`；5 分钟按范围 key 缓存；`setRangeToday/ThisWeek/ThisMonth`、`setCustomRange`（from>to 静默忽略、>90天由 UI 拦截）、`refresh()`=force reload。不引 intl，日期格式化走本地 `formatRangeDate`(yyyy-MM-dd)。 |
| 图表主题 `chart_colors.dart` | ✅ | `BrandColors` 同源配色：brand/brandLight/success/successDeep/warning/invalid + `statusPalette`；趋势三色 followup/answered/converted。 |
| `date_range_selector.dart` | ✅ | 吸顶 `ChoiceChip` 行（今日/本周/本月/自定义）；`showDateRangePicker` 选自定义，跨度 >90 天 `AppToast` 拦截；`notifier` 非空断言调用。 |
| `overview_cards.dart` | ✅ | `GridView.count` 2×2（总线索/公海线索/转化率/跟进中）；`formatBigNumber`（≥1万转「万」）；今日范围显环比 `compareYesterday`；公海呆滞 `staleInPool>0` 橙色 warning。 |
| `conversion_funnel.dart` | ✅ | 4 阶段进度条，base=`funnel.pending`（>0 算占比，≤0 防御 0%）；`AnimatedContainer` 500ms。 |
| `status_donut.dart` | ✅ | fl_chart `PieChart` 环形（centerSpaceRadius 28 / 环半径 46 / sectionsSpace 2）+ 中心叠 total/总计 + 右排 5 图例（公海=byStatus.pending / 已分配 / 跟进中 / 已转化 / 无效）；`duration`/`curve` 新版 API。 |
| `trend_line_chart.dart` | ✅ | fl_chart `LineChart` 3 系列（跟进/接通/转化），X=mmdd，动画 800ms，`belowBarData` 用 `withValues(alpha:0.1)`。 |
| `agent_ranking.dart` | ✅ | 排序 `ChoiceChip`（转化率/转化数/跟进数/接通数）；前 10 + 「查看全部 N 名」；Top3 金/银/铜 `CircleAvatar` 徽标；`selectedColor`=`brand.withValues(alpha:0.15)`。 |
| 入口 `profile_page.dart` | ✅ | 团队统计「敬请期待」→ 直推 `TeamStatsPage()`（沿用既有 `if(isManager)` 门禁；全仓用 `Navigator.push`，不经 go_router）。 |
| 依赖 `pubspec.yaml` | ✅ | 加 `fl_chart: ^0.70.0`。 |
| 计划 `PLAN_29_TEAM_STATS.md` | ✅ | 同步后端契约修正：种子聚合键 `pool`→`pending` 全链路修正，客户端统一 `pending` 单键，不写 `pool` 兼容。 |

## 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 图表库 | fl_chart ^0.70.0 | 轻量、声明式、环形+折线都满足；注意 0.70 改了 API（见踩坑 §14） |
| 后端契约 | 统一 `pending` 单键 | 公海权威定义 `status=pending && ownerId IS NULL`；seed 曾误写 `pool` 致 `funnel.pool` 恒 0，已全链路修正，客户端不再兼容 `pool` |
| 日期格式化 | 本地 `_fmt`/`formatRangeDate`，不引 intl | pubspec 无 intl，避免多一次 pub get 风险 |
| 缓存 | 5 分钟按范围 key（`dateFrom\|dateTo`） | 快速切日期不重复请求；同一范围复用 |
| 入口导航 | `Navigator.push` 不经 go_router | 对齐全仓既有「我的」页跳转写法 |

## 验证

- `flutter analyze`：本次 13 个改动/新建文件 **0 error 0 warning**；全仓仅余 `token_storage.dart` 11 个 `unnecessary_non_null_assertion` warning（web 存储修复遗留，无关）。
- 构建 `flutter build apk --release --dart-define=DEV_TOOLS=true` 成功（59MB），`adb install -r` 装到 Redmi K60（`3e06fd6d`，Streamed Install / Success）。
- 真机实测通过（用户确认无明显问题），验证清单：入口直通、漏斗基数 `funnel.pending` 真实非零、状态分布「公海」=byStatus.pending、趋势 3 线有数据、M3 风格与 4 模块展开、坐席排行 Top3 徽标。

## 待开发（本节点未做 / 后续）

- 团队模块三阶段（v0.22 线索池 / v0.24 日程视图 / v0.25 统计页）**全部完成**。
- KGP 警告（`package_info_plus`/`sensors_plus`/`share_plus`）按方案 A 暂接受，未来 Flutter 版本可能阻断构建。
- `MILESTONES.md` 补 v0.25 节点（v0.23 节点仍待补）。
