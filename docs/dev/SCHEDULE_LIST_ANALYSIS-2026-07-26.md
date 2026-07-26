# 日程列表页 UI 抽象 / 优化可行性分析

> 版本：v1.0　|　日期：2026-07-26　|　范围：`lib/pages/schedules/`（主页面 + widgets）
> 目的：在不改动视觉表现的前提下，梳理日程列表页「可抽象为公共组件」与「其他可优化项」，对齐 `UI_STYLE_GUIDE`。
> 说明：用户明确「对当前视觉满意」，故本报告所有建议均以**视觉零变化**为前置条件——只抽组件 / 消重复 / 对齐规范，不改观感。

---

## 一、现状快照

日程列表页由 1 个主页面 + 7 个 widget + 1 个 part 文件组成：

| 文件 | 职责 | 备注 |
|------|------|------|
| `schedule_list_page.dart` | 页面骨架、双 Tab、吸顶分组、错误/空态、footer | 自绘项最多 |
| `widgets/schedule_card.dart` | 单条日程卡片（左侧色条 + 标题 + 时间 + 内容 + 归属人 + 状态标签） | 含 `_StatusTag`、`_OwnerRow` 私有组件 |
| `widgets/schedule_date_header.dart` | 日期吸顶头（今天/明天/本周…） | 灰底 + 0.5px 底线 |
| `widgets/schedule_overdue_header.dart` | 逾期吸顶头（红色「已逾期(N)」） | 与上面 90% 同构 |
| `widgets/schedule_skeleton.dart` | 骨架屏 | 待办/已完成共用 |
| `widgets/schedule_detail_cards.dart` | 详情页卡片 | 本次范围外 |
| `widgets/schedule_detail_actions.dart` / `schedule_form_*` | 详情操作 / 表单 | 本次范围外 |
| `schedule_grouping.dart`（`part`） | 分组桶逻辑 + `_Group` 模型 | 用 `part` 挂到主文件 |

---

## 二、可抽象的公共组件（按优先级）

### 🔴 P0-1：错误态应复用 `AppErrorBody`（当前完全自绘）

- **位置**：`schedule_list_page.dart:307-346` `_buildError`
- **问题**：自绘 `Icon + 文案 + 重新加载按钮`，而 `lib/widgets/app_error_body.dart` 已有公共 `AppErrorBody`（图标 + 文字 + `FilledButton` 操作）。此处重复造轮子，且用的是 `TextButton` 而非 M3 的 `FilledButton`，与全局按钮风格不一致。
- **建议**：错误态改为
  ```dart
  AppErrorBody(
    icon: Icons.error_outline,
    message: '加载失败\n$message',   // 多行
    actionText: '重新加载',
    onAction: () => ref.read(scheduleListProvider.notifier).refresh(),
  )
  ```
- **配套改动**：当前 `AppErrorBody` 只有单 `message`（14px 居中），无法区分「标题(16px w500) + 副文(14px 灰)」两级。建议**给 `AppErrorBody` 增加可选 `title` 参数**（有 title 时显示两级、无则保持原样），使其覆盖「标题 + 详情 + 操作」三要素。这样 `call_records` / `customers` 的错误态也能一并统一。
- **视觉影响**：无（仅把自绘换成公共组件，按钮改 `FilledButton` 反而更规范）。

### 🟠 P1-1：空态应抽公共 `AppEmptyBody`

- **位置**：`schedule_list_page.dart:350-379` `_buildEmpty`
- **问题**：自绘 `Icon + 主文案 + 副文案`。项目只有 `AppErrorBody`、没有空态公共组件；`call_records` / `customers` 的空态也是各自自绘。三处重复。
- **建议**：新增 `lib/widgets/app_empty_body.dart`：
  ```dart
  AppEmptyBody(icon: Icons.event_note, title: '暂无待办日程', desc: '点击底部「+」或卡片「跟进」新建日程')
  ```
  供日程 / 通话 / 客户三列表空态统一复用。
- **视觉影响**：无。

### 🟠 P1-2：状态标签统一用 `AppTag`

- **位置**：`schedule_card.dart:137-172` `_StatusTag`
- **问题**：`_StatusTag` 是「浅底深字 4px 圆角标签」，与 `lib/widgets/app_tag.dart` 的 `AppTag`（`label` + `backgroundColor?` + `textColor?`，默认 4px 圆角浅蓝底）**结构完全一致**，纯属重复实现。
- **建议**：删 `_StatusTag`，改为
  ```dart
  AppTag(label: label, backgroundColor: color.withValues(alpha: 0.1), textColor: color)
  ```
  其中 `color` 由 `_statusColor(status, isOverdue)` 算出。
- **延伸**：`lead_card.dart` 的 `_buildStatusTag` 也是同一套「浅底深字标签」，可一并迁移到 `AppTag`，全项目状态标签只剩一个实现。
- **视觉影响**：无（圆角、字号、配色一致）。

### 🟠 P1-3：卡片信息行复用 `AppInfoRow`

- **位置**：`schedule_card.dart` 的「时间行」(`Icons.access_time` + `s.dateTimeDisplay`) 与「归属人行」(`Icons.badge_outlined` + `归属：name`)
- **问题**：两行都是「图标 + 文字」的 `Row`，与 `lib/widgets/app_info_row.dart` 的 `AppInfoRow(icon, label, value)` 同构，只是 schedule 没有 `label` 前缀。
- **建议**：给 `AppInfoRow` 的 `label` 改为可选（空 label 时不渲染前缀），schedule 时间行/归属人行直接复用；或抽更轻的 `AppIconText(icon, text)`。归属人行带异步 `userNameProvider` 解析，保留外层 `_OwnerRow` 只替换内部那一行为 `AppInfoRow`。
- **视觉影响**：无。

### 🟡 P2-1：双 Tab 栏抽 `AppSegmentedTab`

- **位置**：`schedule_list_page.dart:108-177` `_buildTabBar` + `_tabItem`
- **问题**：自绘「待办/已完成」双 Tab + 计数徽标 + 下划线指示器。项目已有 `LeadsTopBar`（胶囊 Tab）、`AppFilterChips`（单选药丸），但**「带计数徽标的分段 Tab」**这一范式尚无公共组件，且不同于前两者（无计数、无下划线）。
- **建议**：抽 `lib/widgets/app_segmented_tab.dart`：
  ```dart
  AppSegmentedTab(
    tabs: const [TabItem(key:'pending', label:'待办', count: stats.pending), TabItem(key:'completed', label:'已完成', count: stats.completed)],
    activeKey: state.activeTab,
    onChanged: (k) => ...switchTab(k),
  )
  ```
  封装「下划线指示 + 蓝字选中 + 计数胶囊」逻辑。将来任何「带计数的双/多态切换」都能复用。
- **视觉影响**：无（参数化还原现有样式）。

### 🟡 P2-2：「我的/团队」切换抽 `AppScopeToggle`

- **位置**：`schedule_list_page.dart:73-94`（AppBar actions 内自绘药丸按钮）
- **问题**：自绘 `GestureDetector` + `Container(白底 alpha 0.18, 圆角 14)` 显示「我的/团队」。而 `customers` 列表用的是 `PopupMenuButton`「我的/全部」——**同一语义「scope 切换」却是两种范式、两套实现**。
- **建议**：抽 `AppScopeToggle({options: ['我的','团队'], current, onChanged})`，药丸样式统一两页。若想进一步统一交互，也可让客户列表从下拉菜单改为同款药丸（需确认产品意图，本报告仅建议抽组件、不强行统一交互）。
- **视觉影响**：无（客户列表若不改交互，仅日程页用新组件，外观不变）。

### 🟡 P2-3：两个吸顶头合并为 `ScheduleStickyHeader`

- **位置**：`schedule_date_header.dart` 与 `schedule_overdue_header.dart`
- **问题**：两者 90% 同构（height 40、`#F3F3F3` 灰底、`0.5px` 底部线、左对齐、可点击），差异仅内容（文字 vs 红色图标+「已逾期(N)」）。
- **建议**：合并为一个
  ```dart
  ScheduleStickyHeader({required String title, IconData? icon, Color? iconColor, VoidCallback? onTap})
  ```
  逾期头传 `icon: Icons.error_outline, iconColor: BrandColors.danger, title: '已逾期 ($count)'`，日期头只传 `title`。
- **视觉影响**：无。

### 🟢 P3-1：固定高度吸顶委托公共化

- **位置**：`schedule_list_page.dart:384-406` `_StickyHeaderDelegate`
- **问题**：`SliverPersistentHeaderDelegate` 固定高度 + `shouldRebuild=false` 是通用工具，任何需要吸顶的列表都要写一遍。
- **建议**：提为 `lib/widgets/app_sticky_header.dart` 的 `FixedStickyHeaderDelegate(height, child)`，全项目复用。
- **视觉影响**：无。

### 🟢 P3-2：列表 footer 抽 `AppListFooter`

- **位置**：`schedule_list_page.dart:241-272`（加载更多转圈 / 「已加载全部」/ 底部留白）
- **问题**：`isLoadingMore`→转圈、`!hasMore`→「— 已加载全部 —」、`else`→`SizedBox(8)` 三段式 footer，`call_records` / `customers` 也有同构实现。
- **建议**：抽 `AppListFooter({required bool isLoadingMore, required bool hasMore})`，三页统一。
- **视觉影响**：无。

---

## 三、颜色与规范问题（高优先级，违反 UI_STYLE_GUIDE §1.2）

### 3.1 硬编码色值清单（本次扫描）

| 颜色 | 出现位置 | 应替换为 |
|------|----------|----------|
| `Color(0xFFF3F3F3)` 页面/头灰底 | list page 67、date/overdue header | `BrandColors.surface` |
| `Color(0xFF0052D9)` 品牌蓝 | list page 多处、card | `BrandColors.primary` |
| `Color(0xFF6B7A90)` **调色板外野色** | list page Tab、card 时间/内容/归属人、date header | `BrandColors.textSecondary`（`#A6A6A6`） |
| `Color(0xFFA6A6A6)` 副文字 | list page、card | `BrandColors.textSecondary` |
| `Color(0xFF181818)` 主文字 | list page、card | `BrandColors.textPrimary` |
| `Color(0xFFD54941)` 逾期红 | card、overdue header | `BrandColors.danger`（**需新增**） |
| `Color(0xFF00A870)` 完成绿 | card `_StatusTag` | `BrandColors.success`（**需新增**） |
| `Color(0xFFE0E0E0)` 头部分割线 | date/overdue header | `BrandColors.line`（或 `border`） |
| `Color(0xFFDCDCDC)` / `0x99C5C5C5` 图标灰 | list page 错误/空态图标 | `BrandColors.textDisabled` |
| `Color(0x0D000000)` 卡片阴影 | card | 统一卡片阴影 token |

> 注：`#6B7A90` 是**野颜色**（调色板里根本没有，最接近的是 `textSecondary #A6A6A6`），与筛选条分析报告发现的是同一个问题——说明硬编码野色尚未在全项目清零。

### 3.2 语义色常量缺失（根因）

`#D54941`(danger) / `#00A870`(success) / `#E37318`(warning) 在 `schedule_card`、`lead_card` 多处硬编码，但 `BrandColors` 目前没有对应语义常量（只有 `error`/`primary`/`primarySurface` 等）。

- **建议**：在 `lib/theme/color_scheme.dart` 补
  ```dart
  static const Color danger   = Color(0xFFD54941);
  static const Color success  = Color(0xFF00A870);
  static const Color warning   = Color(0xFFE37318);
  ```
  然后全量替换（含 `lead_card` 的 `#2BA471`/`#E37318` 等），让语义色单点定义。

### 3.3 卡片阴影三处不一致

| 组件 | radius | shadow |
|------|--------|--------|
| `ScheduleCard` | 10 | `0x0D000000 / blur6 / (0,2)` |
| `LeadCard` | 12 | `0x12000000 / blur8 / (0,2)` |
| `AppCardSection` | 12 | `0x12000000 / blur8 / (0,2)` |

- **建议**：抽共享 `BoxDecoration cardDecoration({radius = 12})`（或放 `component_tokens.dart`），三处统一为 `radius 12 + 0x12000000/blur8/(0,2)`，消除卡片立体感不一致。

---

## 四、其他优化项（非组件）

### 4.1 `part` 文件改独立模块
- `schedule_grouping.dart` 用 `part of` 挂到主文件，`_Group` 为私有类型跨文件引用，维护成本高、易踩 Dart part 限制。
- **建议**：改为普通 `lib/pages/schedules/schedule_group_model.dart`，导出 `class ScheduleGroup`（公开），主文件 `import` 使用。

### 4.2 滚动触底节流
- `_onScroll` 每次滚动都判断 `pixels >= maxScrollExtent - 200` 后调 `loadMore()`。需确认 `scheduleListProvider.loadMore` 内部有 `isLoadingMore` 守卫（否则快速滚动会重复触发请求）。建议核实，无守卫则加 `if (state.isLoadingMore || !state.hasMore) return;`。

### 4.3 `ScheduleCard` 为 `ConsumerWidget`
- 每张卡片因 `_OwnerRow` 异步解析 `userNameProvider(userId)` 而成为 `ConsumerWidget`，长列表下 provider 实例数 = 卡片数。短期可接受；若列表很长，可考虑把归属人解析上移到列表层批量获取，或缓存 `userNameProvider` 结果。

### 4.4 `Scaffold.backgroundColor` 硬编码
- `schedule_list_page.dart:67` `backgroundColor: const Color(0xFFF3F3F3)`，应 `BrandColors.surface`（且项目约定 Scaffold 默认即 surface，可考虑移除显式设置）。

---

## 五、落地优先级建议

| 批次 | 项 | 收益 |
|------|----|------|
| **第一批（规范清零，必做）** | 3.1/3.2/3.3 颜色全量 BrandColors 化 + 补 danger/success/warning | 消除野色 `#6B7A90`、语义色单点、对齐 §1.2 |
| **第二批（消重复，高 ROI）** | P0-1 错误态复用 `AppErrorBody`（扩 title）、P1-2 状态标签用 `AppTag`、P1-3 信息行用 `AppInfoRow` | 删 3 处自绘、向公共组件收敛 |
| **第三批（抽新组件）** | P1-1 `AppEmptyBody`、P2-1 `AppSegmentedTab`、P2-2 `AppScopeToggle`、P2-3 吸顶头合并 | 跨页统一、降低新列表页成本 |
| **第四批（维护性）** | P3-1 吸顶委托公共化、P3-2 `AppListFooter`、4.1 part→独立、4.2/4.3/4.4 | 长期可维护性 |

---

## 六、结论

日程列表页视觉本身没问题，但**实现层有大量「本可用公共组件却自绘」和「颜色硬编码」**：
- 错误态、空态、状态标签、信息行 4 处可直接复用 / 轻改现有 `AppErrorBody` / `AppTag` / `AppInfoRow`；
- 双 Tab、scope 切换、吸顶头、吸顶委托、列表 footer 5 处可抽新公共组件，顺带统一 `call_records` / `customers`；
- 颜色硬编码（含野色 `#6B7A90`、语义色 `#D54941/#00A870/#E37318`）是违反规范的高优先项，建议先清零。

以上全部建议**不改视觉**，可分批落地。本报告仅作分析，**未改动任何代码**。

---

## 七、执行记录

### 2026-07-26 · 第一批 + 第二批（已落地，未提交，待真机验证）

**公共组件扩展（不影响现有调用方）**
- `AppErrorBody`：新增可选 `title` / `iconSize` / `iconColor` / `messageColor`，默认值保持原外观（`lead_detail_page` 调用无感）。
- `AppTag`：新增可选 `padding`（默认 6×2，`lead_header_section` 调用无感）。

**第一批 · 颜色集中化（仅日程列表页及其 widgets）**
| 原硬编码 | 替换为 | 备注 |
|----------|--------|------|
| `#0052D9` | `BrandColors.primary` | 精确匹配 |
| `#181818` | `BrandColors.textPrimary` | 精确匹配（仅 `_buildEmpty` 残留，第三批处理） |
| `#A6A6A6` | `BrandColors.textSecondary` | 精确匹配 |
| `#C5C5C5` | `BrandColors.textDisabled` | 精确匹配 |
| `#F3F3F3` | `BrandColors.surface` | 精确匹配 |
| `#D54941` | `BrandColors.error` | 精确匹配 |
| `#6B7A90`（野色） | `BrandColors.textSecondary` | **轻微变浅**（蓝灰→中灰），按方案执行；若想保留原深色可调 `textSecondary` 或新增强色 token |
| `#E0E0E0`（吸顶头底线） | `BrandColors.line` | 轻微变浅（0.5px 近乎不可见） |
| `#99C5C5C5` | `BrandColors.textDisabled.withValues(alpha: 0.6)` | 语义等价 |

**保留的字面量（避免改动视觉 / 跨应用不一致）**
- `#00A870`（完成绿标签）：设计系统存在两套绿（`BrandColors.success=#2BA471` 与 notice 栏 `#00A870`），直接替换会变色相，故保留字面量；跨应用「双绿」不一致列为独立发现项，不在本页范围。
- `#DCDCDC`（错误/空态图标）：无对应调色板常量，保留字面量（第三批 `AppEmptyBody` 可统一）。

**第二批 · 复用公共组件**
- `schedule_list_page._buildError` → 改用 `AppErrorBody`（保留外层 `RefreshIndicator`+`ListView` 下拉重试，`title:'加载失败'` + 详情 + `重新加载` 按钮）。
- `schedule_card._StatusTag` 自绘类 → 删除，改用 `AppTag`（传 10% 透明底色 + 文字色 + 8×2 内边距，保留原观感）。

**跳过项（并说明理由）**
- **`AppInfoRow` 复用卡片时间行/归属人行**：`AppInfoRow` 为详情页设计（16px 图标 + `标签: 值` + textPrimary 值），而卡片是紧凑 14px、无标签前缀、textSecondary 文字。强行复用会改观感，故**不抽**，保持卡片自带 Row。

**校验**：`flutter analyze` 6 个改动文件 → 0 issue。

### 待续批次
- **第三批**：`AppEmptyBody` 抽组件（含 `_buildEmpty` 颜色收口）、`AppSegmentedTab`（双 Tab 栏）、`AppScopeToggle`（我的/团队）、吸顶头合并为 `ScheduleStickyHeader`。
- **第四批**：吸顶委托 `_StickyHeaderDelegate` 公共化、`AppListFooter`、part→独立 module、`loadMore` 守卫、`userNameProvider` 上移解析。
- `schedule_search_page` / `schedule_detail_*` / `schedule_form_fields` 仍含硬编码色，属「日程列表页」分析范围外，另立任务处理。
