# 电销工作台 APP — 代码审查总览（全量检测）

> ## ✅ 状态标记：第一轮 · 已验收通过 · 2026-07-23 归档
> 本目录（含 13 个提交审查、PHASE-REVIEW、RESPONSE、fix-follow-up-panel-ui）为**第一轮全量审阅**产出，
> 已于 2026-07-23 由组长确认 **验收通过（评级 A-）**，整体归档至 `docs/review/history/`。
> 后续新开发内容的审阅见上级目录 `docs/review/` 的 `SPRINT-REVIEW-*` 与 `RESPONSE-SPRINT-*`。

> 审查人：Mobile App Builder（移动端小组组长）
> 审查日期：2026-07-23
> 范围：全部 13 个提交（首次全量检测）
> 后续机制：**一次提交，一次审核**（每个新提交产出独立文档，见下方清单）
> 审查基准：已提交代码（干净基线 `flutter analyze`，已用 `git stash` 排除未提交改动）

## 一、审查方法（客观 + 人工，避免空口评测）

| 手段 | 用途 | 结果 |
|------|------|------|
| `flutter analyze`（干净基线） | 客观 lint 门禁 | **21 issues / 0 error**（12 warning + 9 info） |
| 注释密度扫描 | 文件头/方法 `///` 合规 | 除 `main.dart` 外均有注释，但**位置普遍在 import 之后** |
| 结构扫描（括号配对） | 上帝方法 / 巨型文件 | 5 处 build >120 行；4 个文件 >560 行 |
| 调试输出 / TODO 扫描 | §8.2 禁留 debug print | `dial_helper` debugPrint；2 处 TODO |
| 逐文件人工抽读 | 错误处理 / const / 安全 | 网络层、存储、首页、线索详情等核心文件 |

## 二、各提交审查结论速览

| 提交 | 主题 | 类型 | lint | 结论 |
|------|------|------|------|------|
| [b94c524](b94c524-init.md) | init（仅文档） | init | – | ➖ 无代码 |
| [9bc6710](9bc6710-init-scaffold.md) | 初始化脚手架 | chore | 0 | ✅ 通过 |
| [98bb432](98bb432-docs-style-guide.md) | 开发规范文档 | docs | – | ➖ 无代码 |
| [e5c7ac2](e5c7ac2-docs-api-address.md) | API 地址更新 | docs | – | ➖ 无代码 |
| [bc59aae](bc59aae-v02-network-auth.md) | v0.2 网络层+认证 | feat | 3 info | ✅ 通过（标杆） |
| [f9a0bea](f9a0bea-v03-credential-persist.md) | v0.3 凭据持久化 | feat | 0 | ✅ 通过 |
| [ad6ec0a](ad6ec0a-v04-force-change-pwd.md) | v0.4 强制改密 | feat | 0 | ✅ 通过（文件偏大） |
| [7bb07ad](7bb07ad-v05-home-dashboard.md) | v0.5 首页看板 | feat | 6 | ✅ 通过（标杆） |
| [d306f28](d306f28-leads-list-mislabeled.md) | ⚠️ docs 名号实为线索列表页 | feat(误标) | 12 | ❌ 需返工 |
| [2198923](2198923-fix-copywith.md) | fix copyWith 筛选丢失 | fix | 0 | ✅ 通过（缺测试） |
| [c2cdec5](c2cdec5-shared-constants.md) | 共享常量 LeadConstants | feat | 0 | ✅ 通过（范本） |
| [84495b1](84495b1-docs-memo.md) | 工作备忘录 | docs | – | ➖ 无代码 |
| [82e6ec9](82e6ec9-lead-detail.md) | 线索详情页（HEAD） | feat | 0 | ✅ 通过（有条件） |

## 三、系统性问题（跨提交，需统一整改）

### 🔴 P0 — 提交规范
1. **`d306f28` 误标**：commit message 写 `docs:`，实际合入 +2230 行功能代码（线索列表页）。属规范 §8 严重违规，且单提交过大。
2. 多数功能提交缺 `scope`（`feat: 线索详情页` 应为 `feat(leads): ...`），建议补全。

### 🟠 P1 — 结构与拆分
3. **上帝方法**（build >120 行，违反 §4.2）：
   - `lead_card.dart` build **144**、`correct_call_dialog.dart` build **141**、`lead_detail_page.dart` build **140**、`follow_up_card.dart` build **128**、`leads_list_page.dart` `_showFilterSheet` **137**。
4. **巨型文件**：`home_page.dart` 927、`leads_list_page.dart` 807、`force_change_password_page.dart` 624、`follow_up_panel.dart` 563 行。

### 🟡 P2 — 注释规范（§1/§2，全仓通病）
5. **文件头位置**：几乎所有 page/widget/provider/service 把 `///` 描述放在 import 之后，违反 §2.2；仅 `models/`、`constants/lead_constants.dart` 等少数放对。
6. **`_build*` 辅助方法普遍缺 `///`**（§1.3），`leads_list_page.dart`（807 行）仅 2 行 `///` 最严重。
7. **命名**：常量 `_keyXxx` 与规范 §3「`k` 前缀」建议不一致，需规范定稿后统一。

### 🟡 P2 — 健壮性 / 调试残留
8. `dial_helper.dart:104` `debugPrint(...)` 违反 §8.2；`app.dart:13` 的 `debugPrint` 属错误兜底，建议改日志框架。
9. 2 处 TODO 滞留：`lead_detail_provider.dart:226`、`lead_action_bar.dart:75`，建议建 issue 跟踪。
10. `api_client.dart:99-101` 刷新响应字段强转缺判空，异常结构会抛 `TypeError`。

## 四、⚠️ 当前工作树告警（非提交问题）

审查期间发现**工作树存在未提交修改**（`follow_up_panel.dart`、`lead_action_bar.dart`、`api_client.dart`、`MainActivity.kt` 等），其中 `follow_up_panel.dart` 的 WIP 重构**误删了 `_durationMinutes`/`_durationSeconds` 字段声明，导致当前工作树 `flutter analyze` 报 2 个 `error`（`undefined_identifier`）**。

- 这 **不是任何已合入提交的问题**（干净基线 0 error 已证实）。
- 请相关同事尽快完成或暂存该 WIP，避免把无法编译的状态当作可运行产物。

## 五、改进优先级建议

1. **立即**：清理 `d306f28` 遗留的 12 个 lint；修复工作树 WIP 编译错误。
2. **本迭代**：拆分 5 处上帝方法 + 4 个巨型文件；`lead_detail_page` 3 个超 120 行 build 拆分；移除 `dial_helper` debugPrint；处理 2 处 TODO。
3. **规范落地**：修订 `STYLE_GUIDE` 明确「私有 `_build` 辅助方法是否强制注释」「常量命名统一风格」；CI 加 `flutter analyze` 卡点（warning 不让合入）。
4. **测试**：建立 `test/` 基线，至少为 `copyWith`、状态机 `copyWith` 补单测。

## 六、整体评价

已提交代码**编译健康（0 error）**，网络层/存储/认证等基础设施质量高、注释规范；首页与线索详情页结构合理、用户体验完整。主要短板集中在**早期 `d306f28` 线索列表页**（误标 + 12 lint + 上帝方法 + 近乎无注释）以及**全仓注释位置/巨型文件**的系统性技术债。后期提交（82e6ec9）零 lint，趋势向好。
