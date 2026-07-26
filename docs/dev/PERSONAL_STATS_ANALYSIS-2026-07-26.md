# 个人统计页 UI 分析 — 报告

> 日期：2026-07-26
> 模块：个人统计页（`lib/pages/personal_stats/`）
> 对比基准：兄弟页 `团队看板`（`lib/pages/team_stats/`，同批业务开发）、`UI_STYLE_GUIDE.md`、线索/日程模块已落地规范

## 一、问题概览

个人统计页自身视觉「三套卡片风格混排」，且与兄弟页 `团队看板` 的卡片语言不一致：

| 区块 | 当前样式 | 问题 |
|------|----------|------|
| 今日概况 `today_overview` | 蓝底 `primarySurface` + **无边框** + 圆角 **8** + 蓝字 | 异类①：填充色、圆角、有无边框三项都与其它不同 |
| 数据详情 `detail_grid` | 白底 `surfaceContainer` + **描边** + 圆角 **8** + 中性字 | 圆角 8，与转化率卡（12）不一致 |
| 转化率 `conversion_ring` 外卡 | 白底 + **描边** + 圆角 **12** + 环 | 圆角 12，与上方两张卡（8）不一致 |
| 兄弟页 `team_stats` 概览卡 | 白底 + **描边** + 圆角 **12** + 中性字 | 个人统计页整体未对齐此语言 |

**核心矛盾**：同一页内圆角 8/12 并存、填充/描边并存；而 `团队看板` 已统一为「白底 + 圆角 12 + `outlineVariant@0.3` 描边」。两页应视觉同源。

## 二、逐项问题

### P0 卡片视觉不统一（页内 + 跨页）
- 三类卡片底色/边框/圆角三套参数，用户第一眼就能感知「拼凑感」。
- 圆角 8（今日/详情）vs 12（转化率卡、团队看板）不一致。

### P1 数字字号跳变
- 今日概况数值 `fontSize 32`、数据详情数值 `24`、转化率环中心 `28`、团队概览 `30` —— 同类型「大数字」字号在 24~32 间游走，缺乏层级规范。

### P1 区块标题未走规范色
- `_sectionTitle` 用默认文字色（非 `BrandColors.textPrimary`）；团队看板模块标题用 `w600` 而个人用 `w500`，两页标题字重也不一致。

### P2 骨架屏灰块过淡（几乎不可见）
- `_StatsSkeleton._box` 用 `BrandColors.surface.withValues(alpha:0.6)`。
- `BrandColors.surface = #F3F3F3` 正是页面灰底，0.6 透明度叠在灰底上 → 灰块与原背景几乎同色，**骨架呼吸动画几乎看不出来**。
- 团队看板骨架同样问题（`surfaceContainerHighest@0.6`，本质也是灰底 0.6），两页一致但都偏弱。
- 全仓其余骨架（leads/schedule）用 `BrandColors.border(#E7E7E7)` 实色，对比明显。

### P2 颜色来源混用（BrandColors vs ColorScheme）
- 个人统计页混用 `BrandColors.primary/textSecondary/textPrimary/line/primarySurface/surfaceContainer` 与 `Theme.colorScheme.outlineVariant`。
- 项目约定优先用 `BrandColors` 常量；`outlineVariant` 实际映射到 `BrandColors.border`，建议统一为 `BrandColors.border` 以消除来源分歧。

## 三、处理方案（推荐 A：低改动、与团队看板同源）

### A1 卡片统一为「白底 + 圆角 12 + 描边」语言（对齐团队看板）
- `today_overview`：保留 `primarySurface` 蓝底作为「今日概况」刻意强调，但 **圆角 8→12** 并 **加 `BrandColors.border@0.3` 描边**，使其与详情/转化率卡同属一个卡片家族（仅填充色区分，圆角/边框一致）。
- `detail_grid`：**圆角 8→12**（描边/白底/中性字已符合）。
- `conversion_ring` 外卡：已是圆角 12 + 描边，保持不变。
- 效果：页内三卡圆角统一 12、均有描边；与团队看板视觉同源。

### A2 数字字号规范化
- 概况/概览大数字：`fontSize 30`（对齐团队看板 30；今日概况 32→30）。
- 详情网格数字：`fontSize 24`（保持）。
- 转化率环中心：`fontSize 28`（保持，环形中心略大合理）。

### A3 区块标题走规范
- `_sectionTitle` 文字色改 `BrandColors.textPrimary`，字重与团队看板模块标题对齐（`w600`）；字号 16 保持不变。
- 同步把团队看板模块标题确认一致（已 `w600`，无需改）。

### A4 骨架屏灰块提对比
- `_StatsSkeleton._box` 底色 `BrandColors.surface@0.6` → `BrandColors.border`（实色 #E7E7E7），与全仓骨架一致、呼吸动画可见。
- 圆角保持 12（与真实卡片一致）。
- 备注：团队看板骨架同问题，建议一并改（见 §四可选）。

### A5 颜色来源收口
- 页内 `scheme.outlineVariant.withValues(alpha:0.3)` → `BrandColors.border.withValues(alpha:0.3)`（语义等价，符合项目常量约定）。

## 四、可选增强（不在本次必做范围）
- **抽公共 `StatCard`**：个人/团队两页的 `_card` 构建器几乎一致（label + value + 可选 badge），可抽到 `lib/widgets/stat_card.dart` 复用，从根上杜绝两页再次漂移。
- **团队看板骨架同步提对比**（A4 的对称修复）。
- **全仓卡片圆角 12 vs 10 的终局决策**：stats 模块用 12、线索/日程用 10，属跨模块不一致，建议单独立项统一（不阻塞本次）。

## 五、业务逻辑影响
| 项 | 状态 |
|----|------|
| 统计接口 / 数据模型 | 不变 |
| 日期范围选择 / 刷新 | 不变 |
| 领取 / 跳转 | 不变 |
| 仅视觉层（卡片样式、字号、骨架色） | 零业务改动 |

## 六、真机验证清单（执行后）
1. 个人统计页三块卡片圆角一致（均 12）、均有细描边
2. 今日概况为蓝底强调卡，但与详情/转化率卡「同家族」
3. 大数字字号有层级（概况 30 / 详情 24 / 环 28）
4. 骨架屏灰块明显、呼吸动画可见
5. 与团队看板视觉同源，无「拼凑感」
