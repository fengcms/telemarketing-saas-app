# 代码审查：线索详情页完整开发（HEAD）

- 提交：`82e6ec9`
- 类型：`feat`
- 作者 / 日期：fungleo / 2026-07-23
- 审查人：Mobile App Builder（移动端小组组长）
- 审查日期：2026-07-23
- 审查基准：已提交代码（干净基线 flutter analyze：21 issues / 0 error；**本提交贡献 0 issue**）

## 一、改动概览

本提交是体量最大者：**27 个文件，+4747 行**，覆盖线索详情页全链路：

| 类别 | 文件 | 行数 |
|------|------|------|
| 页面 | lib/pages/leads/lead_detail_page.dart | 288 |
| 12 个组件 widget | follow_up_panel(563) / follow_up_timeline(355) / edit_lead_dialog(291) / call_records_section(261) / schedule_dialog(264) / correct_call_dialog(236) / lead_header_section(247) / follow_up_card(277) / edit_follow_up_dialog(153) / delete_confirm_dialog(102) / dial_helper(106) / lead_action_bar(95) / lead_bottom_nav(122) | 共 ~3473 |
| Provider | lead_detail_provider(281) / options_provider(+14) | — |
| Model | call_record / follow_up_record / lead_detail / lead_list_context | — |
| Service | lead_service(+257) / api_constants(+4) / lead_constants(+13) | — |

## 二、客观质量门禁（flutter analyze）

**🎉 本提交贡献 0 issue（无 error/warning/info）。** 作为 13 个提交中文件最多、行数最大的一个，却零 lint 问题，说明后期代码质量明显提升（对比早期 `d306f28` 独占 12 个 issue）。

## 三、规范与质量评估

### 3.1 结构（需关注：上帝方法）
- ❌ 部分 widget 的 `build()` 仍超 120 行（违反 §4.2）：
  - `lead_detail_page.dart` build **140 行**
  - `correct_call_dialog.dart` build **141 行**
  - `follow_up_card.dart` build **128 行**
  - `lead_bottom_nav.dart` build **105 行**（临界）
- ✅ 其余 widget（follow_up_panel / edit_lead_dialog / schedule_dialog 等）拆分较好（最大方法 ≤ 79 行）。
- ⚠️ `follow_up_panel.dart` 单文件 563 行（含 `MethodChannel` 通话记录查询），体量偏大，建议后续拆分「通话记录查询」逻辑。

### 3.2 健壮性 / 调试输出
- ❌ `lib/pages/leads/widgets/dial_helper.dart:104` 使用 `debugPrint('无法启动拨号盘: $uri')` —— 违反 STYLE_GUIDE §8.2「不得遗留 debug print」。应移除或改为日志框架。
- ⚠️ 两处 TODO 未处理：
  - `lib/providers/lead_detail_provider.dart:226` `// TODO: 从 auth 获取 TA 角色`
  - `lib/pages/leads/widgets/lead_action_bar.dart:75` `// noCallWindow: from tenant profile (TODO: add from auth/settings)`
  - 建议：建 issue 跟踪，避免 TODO 长期滞留代码。

### 3.3 注释
- ✅ 组件级 `///` 文档密度尚可（follow_up_panel 12 行、follow_up_timeline 11 行等）。
- ⚠️ 文件头均位于 import 之后（§2.2，全仓通病）；各 `_build*` 辅助方法普遍缺 `///`（§1.3）。

### 3.4 正确性
- ✅ `follow_up_panel.dart` 中 `MethodChannel` 通话记录查询做了 `mounted` 检查、try-catch 兜底（§4.4 / §7.2 达标），见已读源码。
- ✅ `lead_detail_provider` 刷新/提交均有异常处理。

## 四、问题清单

| 级别 | 位置 | 问题 | 建议 |
|------|------|------|------|
| 🟠 中 | lead_detail_page.dart build 140 行 | 上帝方法 | 拆分详情区块为子组件 |
| 🟠 中 | correct_call_dialog.dart build 141 行 | 上帝方法 | 拆分表单/按钮区块 |
| 🟠 中 | follow_up_card.dart build 128 行 | 上帝方法 | 拆分卡片内部区块 |
| 🟠 中 | dial_helper.dart:104 | `debugPrint` 违反 §8.2 | 移除 / 改日志框架 |
| 🟡 低 | lead_detail_provider.dart:226 / lead_action_bar.dart:75 | 遗留 TODO | 建 issue 跟踪 |
| 🟡 低 | 全部文件头 | 位于 import 之后 | 调整至顶部（§2.2） |
| 🟡 低 | 各 `_build*` | 缺 `///` | 补关键方法注释 |

## 五、审查结论

**✅ 通过（有条件）。** 作为最大提交却**零 lint 问题**，整体质量优于早期提交，组件拆分、mounted 检查、异常处理基本到位。主要待办：
1. 拆分 3 个超 120 行 `build()`（lead_detail_page / correct_call_dialog / follow_up_card）；
2. 移除 `dial_helper` 的 `debugPrint`；
3. 处理 2 处 TODO（建 issue）。

不阻塞合入，建议下个迭代清理。
