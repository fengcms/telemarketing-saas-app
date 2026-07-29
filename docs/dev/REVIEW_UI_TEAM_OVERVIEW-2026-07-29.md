# UI 审查报告：首页「团队今日概览」& 「我的」页「团队业绩概览」

> 日期：2026-07-29
> 审查范围：`lib/pages/home/home_stats_section.dart`、`lib/pages/profile/profile_page.dart`、`lib/pages/profile/widgets/team_stats_overview_card.dart`
> 结论：**3 个用户已发现问题均确认属实**；复审另发现 **5 类** 附加 UI / 一致性问题，其中 1 处为显示 bug。

---

## 一、用户已发现的问题（确认属实）

### 1.1 首页团队卡「不一样大」—— 高度不齐（确认）
- **位置**：`home_stats_section.dart` `_buildTeamGrid`（L63-89）
- **根因**：2×2 网格中，第 2 行「团队今日转化」带环比小标（3 行内容），而「团队今日待办」无 diff（2 行内容）。`Row` 默认 `crossAxisAlignment.center`，短卡片**不拉伸**，导致「待办」卡片比其它 3 张矮一截。
- **修复**：两个 `Row`（L66、L78）加 `crossAxisAlignment: CrossAxisAlignment.stretch`，让同行卡片等高；4 张即全部一致。
- **附带**：即便拉平高度，「待办」列仍只有 2 行内容、底部留白，视觉重量略轻。可接受；若要完全对齐，可给待办也加一个占位的环比标（如「—」）。

### 1.2 「我的」页团队卡标签冗余「团队」（确认）
- **位置**：`team_stats_overview_card.dart` L38/44/50/55 —— `团队今日跟进/接通/转化/待办`
- **根因**：该卡片已位于「团队业绩概览」区块标题之下，每列再加「团队」前缀属重复。
- **修复**：去掉「团队」前缀 → `今日跟进 / 今日接通 / 今日转化 / 今日待办`。
- 备注：首页那 4 张是独立灰卡，「团队今日X」作为单卡标签尚可接受；但为统一，**建议首页也一并去掉「团队」**（可选）。

### 1.3 「查看我的业绩」按钮独占一行（确认）
- **位置**：`profile_page.dart` L214-224（manager 分支）：`TeamStatsOverviewCard` 下方 `Align(centerRight, TextButton('查看我的业绩 →'))`
- **修复**：把按钮并入区块标题右侧，做成 `Row(spaceBetween, [Text('团队业绩概览'), TextButton(...)])`；删除原独立按钮块（L216-223）。TE 分支无需此按钮（整卡可点）。

---

## 二、复审发现的附加问题

### 2.1 🐞 环比小标「双负号」显示 bug（profile）
- **位置**：`team_stats_overview_card.dart` `_compareBadge`（L111-112）
- **现象**：`diff < 0` 时 `text = '$arrow $diff'` → 例如 `diff = -3` 显示 **「↘ -3」**（箭头 + 负号，双负）。
- **对比**：首页 `_diffBadge`（L135）正确用了 `diff.abs()` → 「↘ 3」。
- **修复**：统一用 `diff.abs()`，即 `diff < 0 ? '$arrow ${diff.abs()}' : ...`。

### 2.2 跨功能视觉语言不统一（首页 vs 我的）
两个功能都是「团队今日概览」，但视觉语言完全不同：

| 维度 | 首页 `团队今日概览` | 我的 `团队业绩概览` |
|------|--------------------|--------------------|
| 卡片底色 | 灰色 `BrandColors.surface`，无阴影 | 白色 + 阴影 |
| 数字颜色 | 深色 `BrandColors.textPrimary` | 品牌蓝 `0xFF0052D9` |
| 数字字号 | 24 / w600 | 20 / bold |
| 环比色板 | Material `Colors.green/red.shade` | 自定义 `0xFF2BA471` / `0xFFD54941` |
| 标签色 | `BrandColors.textSecondary` | 硬编码 `0xFFA6A6A6` |

- **建议**：既然语义一致，建议统一。推荐以「我的」页（白卡+蓝字+自定义色板）为基准，首页对齐；或至少把颜色/字号抽成 `BrandColors` token。优先级：**中**（不影响功能，但同 App 内同类卡片观感割裂）。

### 2.3 硬编码颜色未走主题 token（维护性）
- `team_stats_overview_card.dart`：多处硬编码 `0xFF0052D9` / `0xFFA6A6A6` / `0xFFE7E7E7` / `0xFF2BA471` / `0xFFD54941`。
- `home_stats_section.dart`：`Colors.green.shade600` / `Colors.red.shade500`（Material 色，非品牌）。
- 与项目约定「公共/业务组件统一用 `BrandColors` token」不符（见项目记忆）。建议回归 `BrandColors.primary` / `BrandColors.textSecondary`，并新增「环比涨/跌」两个 token（`BrandColors.up` / `BrandColors.down`）。优先级：**中**。

### 2.4 文案/数字格式细节
- 首页团队卡数字直接 `'$value'`，无上限；「我的」页 `_format` 超 9999 显示「9999+」。首页是 2×2 布局空间更足，冲突风险低，但建议两处统一格式策略。优先级：**低**。

---

## 三、修复优先级与建议顺序

| 优先级 | 项 | 说明 |
|--------|----|------|
| P0（必改） | 1.1 卡片等高 | 用户明确反馈，stretch 一行解决 |
| P0（必改） | 1.2 去「团队」前缀 | 用户明确反馈 |
| P0（必改） | 1.3 按钮移入标题右侧 | 用户明确反馈 |
| P1（建议改） | 2.1 环比双负号 bug | 真实显示缺陷，改动极小 |
| P2（可后续） | 2.2 / 2.3 统一视觉与 token | 一致性/维护性，建议本次一并处理 |
| P3（可选） | 2.4 数字格式统一 | 低优先级 |

---

## 四、下一步

本审查仅输出报告，**未改动任何代码**。请确认：
1. P0 三项是否按上述方案修复；
2. P1（双负号 bug）是否一并修；
3. P2（视觉统一 / token 化）是否纳入本次，还是另开一轮。

确认后我按项目流程：写改动 → 真机验证 → 写 PROGRESS + 提交。
