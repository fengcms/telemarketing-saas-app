# 团队统计页 UI 整改方案

> 分支：`master` ｜ 日期：2026-07-26 ｜ 前置：个人统计页已按本规范整改并验收（commit `c08823c`）
> 目标：团队统计页与个人统计页**视觉同源**（`StatCard` 白底圆角10微阴影、分区标题灰字、`AppFilterChips`、骨架屏规范）

## 一、现状 vs 个人统计新规范对比

| 元素 | 团队统计现状 | 个人统计新规范 | 一致性 |
|------|------------|--------------|--------|
| 概览卡片（4张） | 白底+描边+圆角**12**，值30，有 badge（环比/超48h） | 白底+圆角**10**+微阴影 `StatCard` | ❌ 圆角/描边 |
| 模块卡（5个） | `Card` 圆角**12**描边 包 `ExpansionTile`，标题 15/w600 **黑字** | 白底+圆角**10**微阴影，标题 `textSecondary` 14/w500 | ❌ 圆角/标题色 |
| 日期选择器 | 自绘 `ChoiceChip`×4 | 公共 `AppFilterChips` | ❌ 违规 §3 |
| 坐席排序 | 自绘 `ChoiceChip`×4 | 公共 `AppFilterChips` | ❌ 违规 §3 |
| 骨架屏 | `surfaceContainerHighest@0.6` 灰块圆角12，切范围**无骨架** | `BrandColors.border` 实色圆角10，切范围显骨架 | ❌ 不可见/无过渡 |
| 错误/空态 | 手绘居中图标+文字 | `AppErrorBody`/`AppEmptyBody` | ❌ 不统一 |
| 状态分布环 | `centerSpaceRadius:28` 环形，**起始角0（向右）** | 个人转化率饼图起始角 `-90`（向上） | ❌ 起始角 |
| 转化漏斗 | 进度条，`chart_colors` | 内部图表，已合理 | ✅ |
| 趋势折线 | `fl_chart`，`chart_colors` | 内部图表，已合理 | ✅ |

## 二、问题清单

### P0 风格割裂（必须统一）
1. **概览卡片**：白底+描边+圆角12 → 改用新增的 `StatCard`（白底+圆角10+微阴影）
2. **模块卡**：`Card` 圆角12描边 + 标题黑字 → 改白底+圆角10+微阴影，标题 `textSecondary` 14/w500
3. **日期选择器**：自绘 `ChoiceChip` → 换公共 `AppFilterChips`
4. **坐席排序**：自绘 `ChoiceChip` → 换公共 `AppFilterChips`
5. **骨架屏灰块**：`surfaceContainerHighest@0.6` 叠灰底几乎不可见 → 改 `BrandColors.border` 实色 + 圆角10
6. **切范围无骨架**：`_body` 仅 `stats == null` 显骨架 → 改 `s.isLoading || s.stats == null`
7. **错误/空态**：手绘 → 换 `AppErrorBody` / `AppEmptyBody`

### P1 视觉一致性
8. **状态分布环起始角**：默认0（向右）→ `-90`（向上），与个人转化率饼图统一视觉语言
9. **模块标题字重**：15/w600 → 14/w500（与个人统计分区标题一致）

### P2 可选（不强求）
10. **颜色收口 `BrandColors`**：团队统计当前用 `ColorScheme`（M3 下合理），可保持；仅关键表面/边框与个人页对齐即可

## 三、关键设计决策（待用户拍板，见文末提问）

- **决策1 状态分布图形态**：保留环形（5类分布+中心总计，环形更清晰）还是改实心饼图（与个人转化率完全一致）？
- **决策2 概览卡片 badge**：扩展 `StatCard` 增加 `badge` 插槽（公共组件更通用）还是用 `child` 模式自绘？
- **决策3 本次范围**：仅做风格统一（P0+P1），还是连同 P2 颜色收口一并做？

## 四、推荐改动清单（方案 A：风格统一）

1. **`StatCard` 扩展 `badge` 插槽**（可选 Widget，显示在 value 下方）—— 供概览卡复用
2. **`overview_cards.dart`**：4 张手写卡 → `StatCard`（圆角10微阴影），`badge` 透传环比/超48h 标签，转化率卡 `accent` 蓝字
3. **`team_stats_page._module`**：外 `Card` 改白底+圆角10+微阴影，标题 `textSecondary` 14/w500（保留 `ExpansionTile` 折叠能力）
4. **`date_range_selector.dart`**：`ChoiceChip` → `AppFilterChips`（`DateRangeKind` 映射 code 字符串，custom 仍弹日期选择器）
5. **`agent_ranking.dart`**：排序 `ChoiceChip` → `AppFilterChips`（single 模式）
6. **`team_stats_page._StatsSkeleton`**：灰块 `BrandColors.border` 实色 + 圆角10
7. **`team_stats_page._body`**：骨架判定 `stats == null` → `s.isLoading || s.stats == null`
8. **`team_stats_page._error/_empty`**：手绘 → `AppErrorBody` / `AppEmptyBody`
9. **`status_donut.dart`**：`PieChartData` 加 `startDegreeOffset: -90`（保留环形形态，仅统一起始角）

## 五、涉及文件

- `lib/widgets/stat_card.dart`（扩展 badge）
- `lib/pages/team_stats/team_stats_page.dart`
- `lib/pages/team_stats/widgets/overview_cards.dart`
- `lib/pages/team_stats/widgets/date_range_selector.dart`
- `lib/pages/team_stats/widgets/agent_ranking.dart`
- `lib/pages/team_stats/widgets/status_donut.dart`
- 图表内部（`conversion_funnel.dart` / `trend_line_chart.dart`）**不动**

纯 UI 整改，业务逻辑零改动。
