# 团队统计页 UI 整改进度（PROGRESS_TEAM_STATS_UI）

> 日期：2026-07-26
> 关联方案：`TEAM_STATS_REPLAN-2026-07-26.md`
> 前置：个人统计页整改已合并 `c08823c`（`PROGRESS_PERSONAL_STATS_UI-2026-07-26.md`）
> 范围：**仅 UI 整改，业务逻辑零改动**；`flutter analyze` 全量 `No issues found`

---

## 一、背景与目标

团队统计页与个人统计页同批由业务开发，但卡片风格未对齐：
- 概览 4 卡 / 模块 5 卡仍「白底 + 描边 + 圆角 12」，未用新规范
- 日期选择器、坐席排序均自绘 `ChoiceChip`，与个人页 `AppFilterChips` 割裂
- 骨架屏灰块叠灰底几乎不可见、切范围无骨架过渡
- 错误/空态手绘，未复用 `AppErrorBody` / `AppEmptyBody`
- 状态分布环起始角默认 0（向右），与个人转化率饼图（-90）不一致

目标：将团队统计整体对齐个人统计新规范（白底圆角 10 + 微阴影、`StatCard`、分区标题灰字、`AppFilterChips`、骨架过渡），并修复两个视觉缺陷（状态环顶部裁剪、趋势线图不可读）。

---

## 二、决策点（与用户确认）

| # | 决策 | 结论 |
|---|------|------|
| 1 | 状态分布图类型 | **保留环形图**（5 类分布 + 中心总计），仅加 `startDegreeOffset: -90` 与个人饼图统一；不改实心饼图 |
| 2 | 概览卡 badge | **扩展 `StatCard` 加 `badge` 插槽**（环比 / 超 48h 标签透传），公共组件更通用 |
| 3 | 整改范围 | **仅风格统一**，保留 `ColorScheme` 引用（M3 合理），不强制收口 `BrandColors` |

---

## 三、改动清单

### 3.1 公共组件 `lib/widgets/stat_card.dart`
- 新增可选 `badge` 参数（`Widget?`），渲染在 `value` 下方，供概览卡透传小标签
- 个人页 `StatCard` 仍可用，不影响既有调用

### 3.2 概览卡片 `lib/pages/team_stats/widgets/overview_cards.dart`
- 4 张手写卡 → `StatCard`（白底 + 圆角 10 + 标准微阴影 `0x12000000/blur8/offset(0,2)`）
- 转化率卡 `accent: true` 蓝字；环比 / 超 48h 标签经 `badge` 透传
- 删除 `colorScheme.outlineVariant` 描边写法

### 3.3 模块卡 `lib/pages/team_stats/team_stats_page.dart`（`_module`）
- 外 `Card`：圆角 12 描边 → 白底圆角 10 + 微阴影
- 标题：黑字 → `BrandColors.textSecondary` 14/w500（§2.3 禁用品牌色）
- 保留 `ExpansionTile` 折叠交互

### 3.4 两个选择器换 `AppFilterChips`
- `date_range_selector.dart`：自绘 `ChoiceChip` → `AppFilterChips`（`DateRangeKind` 映射 `today/thisWeek/thisMonth/custom`，自定义项仍弹日期选择器）
- `agent_ranking.dart`：自绘 `ChoiceChip` → `AppFilterChips`（`single` 模式，选中蓝边）

### 3.5 骨架屏 + 错误/空态 `team_stats_page.dart`
- 骨架灰块：`surfaceContainerHighest@0.6`（叠灰底不可见）→ `BrandColors.border` 实色 + 圆角 10
- 骨架判定：`stats == null` → `isLoading || stats == null`，切范围出现骨架过渡（命中 5 分钟缓存的瞬间切换不会误闪）
- 错误态 `_error` → `AppErrorBody`（含重试按钮）；空态 `_empty` → `AppEmptyBody`

### 3.6 状态分布环 `status_donut.dart`
- 起始角：`startDegreeOffset: -90`（从圆心向上，12 点钟），与个人转化率饼图统一
- **顶部裁剪修复**：`SizedBox` 132→150、`radius 46→44`、`centerSpaceRadius 28→30`，四周余量 20px→31px，吸收 fl_chart 内部弧线帽 / 间隔的亚像素溢出

### 3.7 趋势线图 → 分组柱状图
- 删除 `trend_line_chart.dart`，新增 `trend_bar_chart.dart`（类 `TrendBarChart`，git 改名保留历史）
- fl_chart `BarChart`：每日一组 3 柱（跟进 `brandLight` / 接通 `success` / 转化 `successDeep`，沿用状态语义色），柱宽 10、顶部微圆角
- 顶部 3 色图例（跟进 / 接通 / 转化），颜色自解释
- 点按 tooltip：深色底白字，显示「日期 + 指标 + 数值」
- 自适应宽度：天数 ≤10 铺满屏宽；>10（如本月 30 天）横向滚动，每格固定 46px
- X 轴 `MM-DD` 疏化（约每 8 个显示一个），Y 轴整数刻度

---

## 四、真机验证结论（用户确认 OK）

1. ✅ 概览 4 卡与个人统计风格一致（白底圆角 10 微阴影），转化率卡蓝字、有环比 / 超期标签
2. ✅ 4 个模块卡白底圆角 10 + 标题灰字，可展开折叠
3. ✅ 顶部日期选择器 + 坐席排序是统一药丸筛选条，选中蓝边
4. ✅ 切换时间范围出现骨架屏过渡
5. ✅ 加载失败显示统一错误态（重试按钮）、无数据显示统一空态
6. ✅ 状态分布环起始线在 12 点钟方向
7. ✅ 状态分布环顶部完整、不再被切
8. ✅ 逐日趋势是分组柱状图，顶部有图例、柱子清晰；点按有 tooltip；切本月可横向滑动

---

## 五、规范同步

`UI_STYLE_GUIDE.md` §5.1 原写「圆角 12px」已过期，本次校正为 **圆角 10px + 微阴影**（与 `LeadCard` / `StatCard` / 日程卡片实际落地一致）。

---

## 六、提交

- 提交哈希：`（待 push 后补充）`
- 涉及文件：`stat_card.dart`、`overview_cards.dart`、`team_stats_page.dart`、`date_range_selector.dart`、`agent_ranking.dart`、`status_donut.dart`、`trend_bar_chart.dart`（由 `trend_line_chart.dart` 重命名）、`UI_STYLE_GUIDE.md`、进度 / 方案文档
- 纯 UI 整改，业务逻辑零改动；`flutter analyze` 全量 0 error
