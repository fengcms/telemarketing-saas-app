# 个人统计页 UI 整改进度

> 分支：`master` ｜ 日期：2026-07-26 ｜ 性质：纯 UI 整改，业务逻辑零改动
> 前置文档：`PERSONAL_STATS_ANALYSIS-2026-07-26.md`(问题报告) / `PERSONAL_STATS_REPLAN-2026-07-26.md`(改造方案)

## 一、背景

业务开发推送了「个人统计」页面（`lib/pages/personal_stats/`），实测 UI 不达标：

- 卡片 **三套风格混排**：今日概况蓝底/无边框/圆角8、数据详情白底/描边/圆角8、转化率卡白底/描边/圆角12
- 与兄弟页「团队看板」风格割裂
- 大数字字号跳变（32/24/28），无层级
- 分区标题未用 `textSecondary`、字重与团队看板不一致
- 骨架屏灰块 `surface@0.6` 叠在灰底上几乎不可见
- 日期选择器自绘 `ChoiceChip`，违反设计规范 §3 硬规则
- 切换时间范围无骨架过渡（直接显示旧数据，接口返回后瞬间替换）

## 二、设计决策（用户拍板）

| 决策点 | 结论 |
|--------|------|
| 卡片圆角 | **10px**（与已落地全 app 一致，§5.1 的 12 判为过期） |
| 是否抽公共组件 | **现在抽** `StatCard`，个人/团队两页复用 |
| 日期选择器 | **换 `AppFilterChips`**（合规） |
| 今日概况 | **统一白卡**（不保留蓝底强调） |

## 三、改动清单（按落地批次）

### 1. 新增 `StatCard` 公共组件（`lib/widgets/stat_card.dart`）
- 白底 + 圆角 **10** + 标准微阴影（`0x12000000`/`blur 8`/`offset(0,2)`，与 `LeadCard` 同源），无边框
- 简版：`label`(textSecondary 13) + `value`(24/bold，`accent` 时品牌蓝)；自定义：`child` 模式包任意内容
- `valueFontSize` 可传（概况卡用 30）
- 默认内边距后期调为 横14/纵12、标签-值间距 8→6（释放垂直空间、修溢出）

### 2. `TodayOverview` / `DetailGrid` 改用 `StatCard`
- `today_overview`：蓝底圆角8 → 白卡 `StatCard`，value 30，去蓝字；去掉自身上下 padding（只留左右16，与详情卡对齐）；网格 `childAspectRatio` 调小（1.6）给足高度
- `detail_grid`：6 张手写卡 → `StatCard`，转化率卡 `accent` 蓝字；删掉 `ColorScheme` 混用依赖

### 3. 分区标题灰字（`personal_stats_page._sectionTitle`）
- 16/w500 黑字 → **14/w500 `textSecondary`**（§2.3 禁用品牌色）
- 顶部留白 24→16（更贴吸顶日期条）

### 4. 转化率卡重构（多次迭代）
- 旧圆角12描边 `Card` → `StatCard`(child: 自定义内容)
- 布局：用户要求**左环右数据**（非上下）
- 环状图因自适应尺寸导致"占据空间过大"，最终 **删环状图、改 fl_chart 实心饼图**：
  - `conversion_ring.dart` 重命名为 `conversion_pie.dart`，类 `ConversionRing`→`ConversionPie`
  - 左 `SizedBox(150×150)` 固定饼图（已转化=`primary` / 未转化=`line`，直接取 model 原始值 `converted`/`leadsTotal`）
  - 右 `Expanded` 百分比大字(30/bold/primary) + 两行图例（已转化/未转化 + 数值）
  - `startDegreeOffset: -90`：起始线从圆心**向上**（12 点钟）起笔，即用户要求的逆时针转 90°
  - 兜底：`leadsTotal==0` 显示灰色实心圆 + "暂无"
- 骨架转换块高度同步镜像（150）

### 5. 日期选择器换 `AppFilterChips`（`date_range_selector.dart`）
- 自绘 `ChoiceChip` → 公共 `AppFilterChips`（选中浅蓝底+蓝边+蓝字，与列表页一致）
- `DateRangeKind` 映射 code 字符串（today/thisWeek/thisMonth/custom）；custom 仍弹日期范围选择器

### 6. 骨架屏修复（`personal_stats_page`）
- 灰块 `surface@0.6` 实色化 → `BrandColors.border` 实色 + 圆角10（呼吸动画可见）
- **切换范围也显骨架**：`_body` 判定 `stats==null` → `isLoading || stats==null`（命中 5 分钟缓存的瞬间切换不置 `isLoading`，不会误闪骨架）

### 7. 溢出修复（数字靠下 / `Bottom overflowed`）
- 根因：网格 `childAspectRatio` 强制压矮 + `StatCard` 内容比格子高
- 修复：`StatCard` 内边距 `16→横14/纵12`、标签-值间距 `8→6`；`DetailGrid ratio 2.0→1.85`、`TodayOverview ratio 2.0→1.6`

## 四、真机验证结果（用户逐轮实测）

- ✅ 卡片风格统一：白底 + 圆角10 + 微阴影
- ✅ 数字层级清晰（30/24/28）、不溢出、不靠下
- ✅ 分区标题灰字（textSecondary 14/w500）
- ✅ 日期选择器统一药丸筛选条，选中态蓝边
- ✅ 切换时间范围出现骨架过渡
- ✅ 饼图起始线在 12 点钟方向，左右分区不重叠
- **用户最终确认满意，可提交**

## 五、涉及文件

**新增**
- `lib/widgets/stat_card.dart`
- `lib/pages/personal_stats/widgets/conversion_pie.dart`（由 `conversion_ring.dart` 重命名）

**修改**
- `lib/pages/personal_stats/personal_stats_page.dart`
- `lib/pages/personal_stats/widgets/date_range_selector.dart`
- `lib/pages/personal_stats/widgets/detail_grid.dart`
- `lib/pages/personal_stats/widgets/today_overview.dart`
- `.workbuddy/memory/2026-07-26.md`

**文档**
- `PERSONAL_STATS_ANALYSIS-2026-07-26.md`（问题报告）
- `PERSONAL_STATS_REPLAN-2026-07-26.md`（改造方案）
- 本进度文档

## 六、后续

- **团队统计页**：按相同规范统一（下一阶段），直接复用 `StatCard`
- **规范校正**：`UI_STYLE_GUIDE.md` §5.1 仍写「圆角12」，实际全 app 已落地 10，需校正防止后人踩坑
- 全仓「卡片圆角 10 vs 12」终局统一：stats 模块用 10、线索/日程用 10，§5.1 过期条目应改 10

`flutter analyze` 全量 **0 error**，纯 UI、业务逻辑零改动。
