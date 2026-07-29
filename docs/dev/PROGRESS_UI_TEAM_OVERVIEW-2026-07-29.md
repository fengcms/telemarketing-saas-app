# 团队概览 UI 修复进度

> 日期：2026-07-29
> 范围：首页「团队今日概览」+ 我的页「团队业绩概览」两处 UI 问题（审查报告 P0~P3 全量修复）
> 关联文档：`docs/dev/REVIEW_UI_TEAM_OVERVIEW-2026-07-29.md`

## 一、完成内容

### P0 — 用户发现的 3 个问题（全部修复）

1. **首页团队卡不等高**
   - 根因：`_buildTeamGrid` 两个 `Row` 默认 `CrossAxisAlignment.start`，而「团队今日待办」无环比小标（仅 2 行内容），其余 3 张有（3 行），导致待办卡矮一截。
   - 修复：两个 `Row` 各用 `IntrinsicHeight` 包裹并加 `crossAxisAlignment: CrossAxisAlignment.stretch`，4 张卡等高；Column 内容均从顶部排布，数字/标签天然对齐，待办卡底部留白。
   - ⚠️ 等高**必须**用 `IntrinsicHeight` 包裹 Row：裸用 `stretch` 在垂直无界约束容器（Column/ListView）内会传播无限高度导致整页崩溃（见第七节「回归 Bug 修复」）。

2. **我的页标签冗余「团队」**
   - 区块标题已是「团队业绩概览」，每列又写「团队今日跟进…」重复。
   - 修复：`team_stats_overview_card.dart` 4 项标签改为 `今日跟进 / 今日接通 / 今日转化 / 今日待办`。

3. **我的页「查看我的业绩」独占一行**
   - 原实现在卡片下方单独占一行 `Align(centerRight, TextButton)`。
   - 修复：并入区块标题行 —— `Row(spaceBetween)` 左标题、右 `TextButton`（仅 TM/TA 显示），删除原独立按钮行。TE 分支不受影响。

### P1 — 双负号 bug（顺手修复）

- `team_stats_overview_card.dart` 环比 `diff < 0` 原显示「↘ -3」（箭头+负数字），改为 `diff.abs()` → 「↘ 3」，与首页 `_diffBadge` 行为一致。

### P2 — 视觉统一 + BrandColors token 化

- 两处硬编码颜色全部替换为 `BrandColors` token：
  - `primary` (#0052D9)、`surface` (#F3F3F3)、`textSecondary` (#A6A6A6)、`success` (#2BA471)、`error` (#D54941)、`border` (#E7E7E7)。
- 首页团队卡数字由 `textPrimary`(黑) 改为 `primary`(蓝)，与我的页团队卡一致。
- 环比语义色统一：绿 = `success`、红 = `error`、灰 = `textSecondary`。
- `profile_page.dart` 移除 4 个本地颜色常量（`_brandColor/_pageBg/_textSecondary/_errorColor`），统一改用 `BrandColors`。
- **形状保持差异**（合理）：首页为「白卡内灰底小卡」，我的页为「灰底页上的白卡」，外容器不同，不强求同形；统一聚焦颜色 token 与配色语义。

### P3 — 数字格式策略统一

- 首页团队卡新增 `_formatNum`（>9999 → `9999+`），与我的页 `_format` 策略一致。

## 二、关键决策

- 个人维度卡片（首页「今日工作概况」TE、我的页「我的业绩」TE）**不在本次范围**，保持原样，避免改动扩散。
- 「查看我的业绩」按钮仅在 TM/TA 区块标题右侧显示；TE 的个人业绩卡本身可点击跳转，无需此入口。

## 三、验证项（真机）

- 经理/管理员 · 首页：团队今日概览 4 卡**等高**；数字**蓝色**；环比绿/红语义正确（负值为 `↘ N` 而非 `↘ -N`）。
- 经理/管理员 · 我的页：标题「团队业绩概览」**右侧**显示「查看我的业绩 →」；4 列标签为 `今日跟进/今日接通/今日转化/今日待办`；无独立统计行；数字蓝色、配色与首页一致。
- 大数（>9999）两处均显示 `9999+`。
- 员工（TE）视角：个人维度卡片原样，无任何回归。

## 四、改动文件

| 文件 | 改动 |
|------|------|
| `lib/pages/home/home_stats_section.dart` | Row stretch 等高；团队卡数字改 primary；环比用 success/error；新增 `_formatNum` |
| `lib/pages/profile/profile_page.dart` | 删本地色常量改用 BrandColors；「查看我的业绩」移入标题右侧 Row |
| `lib/pages/profile/widgets/team_stats_overview_card.dart` | 去「团队」前缀；双负号 `abs()`；颜色全 token 化；import color_scheme |

## 五、踩坑记录

- 并行编辑 `team_stats_overview_card.dart` 时，首个 `import` 编辑因文件被外部（linter）改动报 "modified since read"，其余 10 处成功；重读文件后补回 import 即恢复。
- `profile_page.dart` 原 4 个本地颜色常量与引用**同名**（如 `_pageBg` 同时出现在定义与引用），必须先删常量定义、再 `replace_all` 引用，否则 `replace_all` 会误改定义行导致语法错误。本次采用「先删常量块 → 再替换引用」两步规避。

## 六、未提交范围（不混入本次）

- 本次仅提交 UI 团队概览修复（3 文件 + 本进度文档 + 审查报告）。
- 工作区另有：线索列表页顶栏「共 X 条」挪入顶栏改动（待真机验证）、`token_storage.dart` 11 条 `unnecessary_non_null_assertion` warning（待处理），均不混入本次提交。

## 七、回归 Bug 修复（管理员首页灰屏）

- **现象**：用户以**管理员/经理**登录后，首页先骨架屏、随后**整页灰屏**；员工登录首页正常。
- **根因**：本批次 P0-1 给 `_buildTeamGrid` 的 `Row` **裸加** `CrossAxisAlignment.stretch` 引入的回归。该 Section 外层 `AppCardSection`→`Column` 在垂直方向是**无界高度约束（h=Infinity）**；在此约束下，`Row`+`stretch` 会把无限高度沿垂直方向传给子卡内部的 `Column`，触发 `BoxConstraints forces an infinite height` 崩溃。员工分支（`_buildPersonalGrid`）的 Row 未加 stretch，故不受影响——与「员工正常 / 管理员灰屏」现象完全吻合。
- **定位手段**：本地写临时 `widget_test`，用管理员 mock 数据（含负 diff、零 diff、>9999 大数）直接 `pumpWidget(HomeStatsSection)`，**稳定复现**崩溃并拿到堆栈（`RenderFlex ... forces an infinite height`），确认崩溃位于 `_buildTeamGrid` 而非数据/模型层（模型有完整默认值、不会 NPE）。
- **修复**：每个 `Row` 改用 **`IntrinsicHeight`** 包裹（保留 `crossAxisAlignment: stretch`）。`IntrinsicHeight` 会先算出确定的固有高度再约束子项，杜绝无限高度传播，同时保留「同行两卡等高」效果。
- **验证**：重跑临时 test → `All tests passed!`；`flutter analyze` 该文件 `No issues`；临时 test 文件已删除。
- **教训（重要）**：在垂直无界约束容器（Column / ListView / CustomScrollView）内，对 `Row` 使用 `CrossAxisAlignment.stretch` 实现「同行等高」时，**必须用 `IntrinsicHeight` 包裹该 Row**，否则会向下传播无限高度导致整页崩溃。

## 八、提交状态

- **验证结论**：管理员/经理真机验证通过 —— 首页不再灰屏、团队四宫格等高、数字蓝色、环比负值显示 `↘ N`；员工视角无回归。
- **提交范围**：仅本批次（3 源码文件 + 本进度文档 + 审查报告），不混入线索顶栏「共 X 条」等其它未验证改动。
- 详见 `git log` 最新一条 `style(ui): ...`。
