# 个人统计页 — 重新规划改造方案（per UI_STYLE_GUIDE）

> 日期：2026-07-26
> 模块：个人统计页（`lib/pages/personal_stats/`）
> 依据：`docs/dev/UI_STYLE_GUIDE.md`（v2.1）、已落地 leads/schedule 模块惯例
> 范围：**本次仅改造个人统计页**；团队看板（同批业务开发、用户也不满意）按本方案同源改造，列为下一阶段，不在本次范围
> 状态：方案稿，待讨论确认后执行

---

## 〇、前置决策（需在动手前拍板）

### 决策 0.1 卡片圆角：10px 还是 12px？
- 规范内部矛盾：§5.1 写「内容卡 12px + 阴影」；§14 写「日程卡 10px + 阴影」。
- 已落地事实：leads / schedule 全模块统一 **10px + 微阴影**（`0x12000000`），三处一致避免加载闪跳。
- **本方案建议：统一 10px + 阴影**，与全 app 已建立惯例一致；§5.1 的 12px 视为过期文案，改造后回写规范修正。
- （若你坚持「以 §5.1 为准」，则全部改 12px，但会与 leads/schedule 再次割裂，不推荐。）

### 决策 0.2 是否抽公共 `StatCard`？
- 个人/团队两页的统计卡构建器几乎一致（label + value + 可选 accent/badge）。
- **本方案建议：本次就抽 `lib/widgets/stat_card.dart`**，个人页先用；团队页下一阶段直接复用，从根上防两页再次漂移。

### 决策 0.3 日期范围选择器是否换 `AppFilterChips`？
- 规范 §3：「列表页搜索框下方的**单选筛选条**必须使用 `AppFilterChips`，禁止各页自绘 chip」。
- 当前 `DateRangeSelector` 自绘 `ChoiceChip` 组，违规。
- **本方案建议：改用 `AppFilterChips`**（今日/本周/本月/自定义 四选项，单选）。
- 注意点：「自定义」需点选后弹出 `showDateRangePicker`，由 `onChanged` 里对 custom 分支特殊处理（先选中再弹 picker）。行为不变，仅视觉/组件统一。

### 决策 0.4 「今日概况」是否保留蓝底强调？
- 当前 `today_overview` 用 `primarySurface` 蓝底 + 蓝字，作为「今日」刻意强调。
- 选项 A（推荐，统一）：**去掉蓝底，今日概况与其它统计卡同款白卡**，层级仅靠区块顺序/标题表达，全页卡片零歧义。
- 选项 B（保留强调）：保留 `primarySurface` 浅蓝填充，但圆角/阴影与全局一致（仅填充色区分）。
- **本方案默认按 A 规划**，若你想要「今日」更跳，可改 B。

---

## 一、目标页面结构（per 规范）

```
Scaffold(backgroundColor: BrandColors.surface)        // §2.2 页面灰底
├── AppBar(title:'个人统计' + 刷新 IconButton)           // 保持
├── 吸顶 DateRangeSelector  →  AppFilterChips           // §3 单选筛选条
└── Expanded
    └── _body
        ├── errorMessage != null  →  AppErrorBody       // §14 已合规，保持
        ├── stats == null         →  _StatsSkeleton      // 改灰块色/圆角
        └── SingleChildScrollView
            ├── 区块「今日概况」(textSecondary 14/w500)    // §2.3/§13.1
            │   └── Row → 2 × StatCard(今日跟进 / 今日接通)
            ├── 区块「数据详情」
            │   └── 2×3 Grid → 6 × StatCard
            │       (线索总数/跟进数/接通数/未接数/转化数/转化率)
            └── 区块「转化率详情」
                └── StatCard(白卡) 内嵌 ConversionRing
```

> 区块间距 16px（§4.2）；卡片内 padding 16px（§4.1）；左右页边距 16px。

---

## 二、组件级规范（逐条对应规范）

### 2.1 StatCard（新增 `lib/widgets/stat_card.dart`）
统一承载所有统计数字卡，消灭页内/跨页三套风格：

```dart
StatCard(
  label: '线索总数',
  value: formatBigNumber(stats.leadsTotal),
  accent: false,            // 转化率等强调项 true → 数值用 primary
  badge: null,              // 可选角标（团队页环比/预警复用）
)
```

- 容器：`Container` 白底 `BrandColors.surfaceContainer` + 圆角 **10** + 阴影 `0x12000000`（与 leads/schedule 同款，**不用** `elevation:0 + BorderSide` 写法）
- label：`fontSize 13`、`BrandColors.textSecondary`
- value：`fontWeight w700`、`BrandColors.textPrimary`（accent 时 `primary`）
  - 字号分层（见 §2.4）
- 内边距 16；主轴居中
- 加 `library;` 指令（对齐项目 widget 惯例）

### 2.2 区块标题（分区标题）
- 必须 `BrandColors.textSecondary`（§2.3 硬规则：**禁用品牌色**，避免「可点击」错觉）
- `fontSize 14`、`fontWeight w500`（§13.1 设置页分区标题规格）
- 当前 `_sectionTitle` 用默认色 + 16 字号 → 不合规，改之
- 内边距 `fromLTRB(16, 16, 16, 8)`（§13.1）

### 2.3 颜色来源收口
- 全页仅用 `BrandColors.*`，删除 `Theme.of(context).colorScheme.*` 混用
- `scheme.outlineVariant.withValues(alpha:0.3)` → 彻底消失（不再用描边卡）
- `primarySurface` 蓝底：默认弃用（决策 0.4 A）；若选 B 仅今日概况用

### 2.4 数字字号分层（规范未定义，本方案建议）
| 层级 | 字号 | 用途 |
|------|:----:|------|
| 概况大数字 | 30 | 今日跟进 / 今日接通 |
| 详情网格数字 | 24 | 线索总数等六项 |
| 转化率环中心 | 28 | 环形中心百分比 |
| label | 13 | 所有卡片标签 |
- 统一 `w700` 字重；转化率 accent 用 `primary`

### 2.5 日期范围选择器 → AppFilterChips
- 替换 `ChoiceChip` 自绘组
- `items`: 今日/本周/本月/自定义；`selectedCode` 绑定 `rangeKind`
- `onChanged`: today/thisWeek/thisMonth → notifier 对应 set；custom → 先 set 再 `showDateRangePicker`
- 视觉自动获得：横滚药丸、浅蓝选中底+蓝边+蓝字、未选中灰底（与全 app 筛选条一致）

### 2.6 骨架屏 `_StatsSkeleton`
- 灰块底色 `BrandColors.surface.withValues(alpha:0.6)` → **`BrandColors.border`** 实色（#E7E7E7，与 leads/schedule 骨架一致，呼吸/占位可见）
- 圆角统一 **10**（与真实卡片一致）
- 布局保持：2 卡 + 6 网格 + 1 高块，比例微调对齐新卡片网格

### 2.7 错误 / 空态
- 错误：`AppErrorBody`（已合规，保持）
- 空态（范围无数据）：当前无；**建议** stats 全零/空时包 `AppEmptyBody`（icon: Icons.inbox_outlined, title:'当前范围暂无数据'），与团队页空态同源。可选，列入执行。

---

## 三、需改/新增文件清单

| 文件 | 改动 |
|------|------|
| `lib/widgets/stat_card.dart` | **新增** 公共 StatCard（白卡 10+阴影，label/value/accent/badge） |
| `lib/pages/personal_stats/personal_stats_page.dart` | 区块标题规范、ConversionRing 用 StatCard 包裹、骨架灰块色/圆角 |
| `widgets/date_range_selector.dart` | `ChoiceChip` → `AppFilterChips` |
| `widgets/today_overview.dart` | 改写为 2 × `StatCard`（去蓝底，决策 0.4 A） |
| `widgets/detail_grid.dart` | 改写为 6 × `StatCard`；`formatBigNumber` 保留或上移到 stat_card |
| `widgets/conversion_ring.dart` | 仅中心数字/环，卡片外壳移除（由外层 StatCard 提供） |
| `docs/dev/UI_STYLE_GUIDE.md` | §5.1 圆角 12→10 修正（决策 0.1），补 StatCard 条目 |

> 业务逻辑（`personal_stats_provider` / 模型 / 接口）**零改动**。

---

## 四、与团队看板的衔接（下一阶段）
- 团队页 `OverviewCards._card` / `team_stats_page._module` 同样改写为 `StatCard` + 默认 Card 容器
- 团队页 `ConversionFunnel` / `StatusDonut` / `TrendLineChart` / `AgentRanking` 模块卡统一为 10px+阴影白卡（去 `elevation:0+border`）
- 团队页错误/空态手写（`Colors.grey`/手动 Column）→ 改 `AppErrorBody` / `AppEmptyBody`
- 团队页骨架灰块同 §2.6 提对比
- 抽 `StatCard` 后两页共享，避免再次漂移

---

## 五、执行后真机验证清单
1. 全页统计卡统一白底 + 圆角 10 + 微阴影，无「蓝底/描边」混排
2. 区块标题为灰色 14/w500（非蓝、非默认黑）
3. 日期范围切换为药丸筛选条，选中态浅蓝底+蓝边，与全 app 一致；自定义仍可弹区间选择器
4. 大数字有层级（30/24/28），无 32 跳变
5. 骨架屏灰块明显可见
6. 与团队看板视觉同源（下一阶段达成）
