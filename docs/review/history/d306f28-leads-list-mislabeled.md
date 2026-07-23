# 代码审查：更新 MILESTONES/PITFALLS/HANDOVER 开发文档  ⚠️ 实际为「线索列表页」功能提交

- 提交：`d306f28`
- 类型：`docs`（**严重误标**）
- 作者 / 日期：FungLeo / 2026-07-22
- 审查人：Mobile App Builder（移动端小组组长）
- 审查日期：2026-07-23
- 审查基准：已提交代码（干净基线 flutter analyze：21 issues / 0 error；**本提交独占 12 个 issue**）

## 一、改动概览（与 commit message 严重不符！）

commit message 写的是 `docs: 更新 MILESTONES/PITFALLS/HANDOVER 开发文档`，但 `git show --stat` 显示本提交实际合入了 **+2230 行业务代码**：

| 文件 | 说明 | 行数 |
|------|------|------|
| lib/pages/leads/leads_list_page.dart | **线索列表页（全新）** | +800 |
| lib/providers/lead_list_provider.dart | 线索列表状态机（全新） | +361 |
| lib/services/options_cache_service.dart | 选项缓存服务（全新） | +168 |
| lib/services/lead_service.dart | 线索 API 服务（全新） | +110 |
| lib/widgets/lead_card.dart | 线索卡片（全新） | +259 |
| lib/providers/options_provider.dart | 选项 Provider（全新） | +23 |
| lib/models/lead.dart / option_item.dart | 模型（全新） | +91 / +16 |
| lib/services/api_constants.dart | 端点常量 | +16 |
| lib/pages/main_shell.dart | Tab 壳微调 | +3 |

> 结论：这是一个**被 `docs:` 前缀掩盖的大型 feature 提交**，违反 STYLE_GUIDE §8 提交规范，且单提交体量过大（应拆分为「列表页 + provider + service + model」多个 feat）。

## 二、客观质量门禁（flutter analyze）

本提交**独占 12 个 issue**（全仓 21 个中的 12 个），无 error，但 warning/info 集中：

| 级别 | 位置 | 规则 | 说明 |
|------|------|------|------|
| warning | leads_list_page.dart:25 | unused_field + prefer_final_fields | `_showFilterPopup` 未使用且应为 final |
| warning | leads_list_page.dart:425 | unused_local_variable | `cache` 变量未使用 |
| info | leads_list_page.dart:700 | unnecessary_underscores | 多余下划线，改用 `_` |
| warning | lead_list_provider.dart:5 | unused_import | 未使用的 `api_client` 导入 |
| warning | lead_list_provider.dart:186-187 | unnecessary_cast | 冗余强转 ×2 |
| info | lead_list_provider.dart:359 | unnecessary_overrides | 空 override，应删除 |
| warning | options_provider.dart:2 | unused_import | 未使用的 `api_client` 导入 |
| info | lead_service.dart:14 / options_cache_service.dart:26 | prefer_initializing_formals | 建议 `this.x` 形式 |
| warning | widgets/lead_card.dart:105 | unnecessary_non_null_assertion | `!` 对非空接收者无效 |

## 三、规范与质量评估

### 3.1 结构（严重）
- ❌ `leads_list_page.dart` **807 行单文件**，且 `_showFilterSheet` 方法高达 **137 行**（上帝方法，违反 §4.2「build 别堆超 100 行」）。
- ❌ `widgets/lead_card.dart` 的 `build()` **144 行**（上帝方法）。
- ⚠️ 两文件均远超限，列表页同时承担「列表 + 筛选弹层 + 卡片」多职责，应拆分。

### 3.2 注释（严重）
- ❌ `leads_list_page.dart`（807 行）**全文件仅 2 行 `///` 注释** —— 几乎是「裸代码」，严重违反 §1（文件头 + 类 + 方法注释）。
- ❌ `widgets/lead_card.dart`（246 行）仅 4 行 `///`，文档密度极低。
- 全文件文件头均位于 import 之后（§2.2）。

### 3.3 健壮性
- ⚠️ `lead_card.dart:105` 的 `!` 非空断言无效（`unnecessary_non_null_assertion`），说明此处变量已确定为非空，断言是噪音，可能掩盖真实可空逻辑。

## 四、问题清单（按优先级）

| 级别 | 位置 | 问题 | 建议 |
|------|------|------|------|
| 🔴 严重 | 提交本身 | commit message `docs:` 误标 + 单提交 2230 行 | 改为 `feat(leads): 线索列表页` 并拆分多提交 |
| 🔴 高 | leads_list_page.dart:25/425/700 | 未用字段/变量/下划线 | 清理 3 处 |
| 🔴 高 | leads_list_page.dart `_showFilterSheet` 137 行 | 上帝方法 | 拆为「筛选条件选择 / 确认栏」子组件 |
| 🔴 高 | leads_list_page.dart（807 行，仅 2 `///`） | 近乎无注释 | 补文件头/类/关键方法 `///` |
| 🟠 中 | lead_card.dart build 144 行 | 上帝方法 | 拆分卡片内部区块 |
| 🟠 中 | lead_list_provider.dart:5/186-187/359 | 未用导入 + 冗余强转 + 空 override | 清理 |
| 🟠 中 | options_provider.dart:2 | 未用导入 | 删除 |
| 🟡 低 | lead_card.dart:105 | 无效 `!` 断言 | 移除 |
| 🟡 低 | lead_service / options_cache_service | prefer_initializing_formals | 改 `this.x` 形式 |

## 五、审查结论

**❌ 需返工（质量 + 规范双问题）。** 本提交是 13 个提交中问题最集中者：
1. **提交规范违规**：`docs:` 前缀掩盖 2230 行功能代码，且单提交过大；
2. **12 个 lint issue** 待清理；
3. **结构性缺陷**：`leads_list_page` 807 行 + 137 行上帝方法、`lead_card` 144 行上帝方法；
4. **注释严重缺失**：807 行文件仅 2 行 `///`。

> 注：该提交已成历史无法改写，但**应在后续迭代优先重构 `leads_list_page`/`lead_card`**，并补充注释；同时团队须杜绝「功能代码挂 docs 名号」与「巨型单提交」。
