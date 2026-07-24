# Sprint 第三轮审阅 — 复审（RE-AUDIT）

> 源审查：`docs/review/SPRINT-REVIEW-3-2026-07-24.md`（评级 **A-**，放行条件：① 修表单过去时间校验 P1；② 拆 `schedule_detail_page` P1）
> 团队整改：`docs/review/SPRINT-REVIEW-3-REMEDIATION.md` + 落地提交 `08e876d`
> 复审人：Mobile App Builder（移动端小组组长）
> 复审日期：2026-07-24

## 一、复审方法说明

本轮**不只看整改文档怎么说，逐条核验代码实际改动**（组长职责，不接受"声明即结论"）：
- 行数：以 `wc -l` 实测；
- 逻辑：直接读源码确认校验/去重/反馈真实落地；
- 门禁：重跑 `flutter analyze`；
- 全库扫描：确认无遗漏的 >560 文件。

## 二、逐条核验结果

| 开放项 | 来源评级 | 整改文档声称 | 实测核验 | 结论 |
|--------|----------|--------------|----------|------|
| P1 表单过去时间校验 | A- 放行条件① | ✅ 已修（`isBefore(DateTime.now())`） | `schedule_form_sheet.dart:294-302` 确同时拦截 `ms==0` 与 `isBefore(now)`，提示「计划时间不能早于当前时间」 | ✅ **真修** |
| P1 `schedule_detail_page` 1024→543 | A- 放行条件② | ✅ 543 + 拆 2 文件 | `wc -l`：543 / `schedule_detail_cards` 348 / `schedule_detail_actions` 179，均 <560；`flutter analyze` 0 issue | ✅ **真拆** |
| P2 `schedule_form_sheet` 776→361 | 短板 | ✅ 361 + `part` 441 | `wc -l`：361 / `schedule_form_fields` 441；`part of 'schedule_form_sheet.dart'` + `// ignore_for_file` 就位，analyze 0 issue | ✅ **真拆** |
| P2 `schedule_list_page` 570→433 | 短板 | ✅ 433 + `part` 141 | `wc -l`：433 / `schedule_grouping` 141，均 <560 | ✅ **真拆** |
| P2 4 handler 去重 | 观察 | ✅ `_runStatusAction` | `schedule_detail_page.dart:422-444` 收敛守卫+调用+toast+缓存失效+刷新+`finally`；`_onComplete`/`_onReopen` 单行复用；`_onCancel` 保留确认弹窗；`_onDelete` 因整屏 loading+返回列表保持独立——去重合理不丢行为 | ✅ **真去重** |
| P3 拨号静默失败 | 观察 | ✅ `_launchDialer` 返 `bool` + `TDToast` | `dial_helper.dart:107-114` 返 `Future<bool>`；`:33-36` `!launched && context.mounted` → `TDToast.showText(...)`；复用 `context.mounted` 守卫符合 lint | ✅ **真修** |
| P3 560 红线/独占提交/message 如实 | 固化 | ✅ 已写入 `STYLE_GUIDE.md` v1.1 | 上轮已确认固化；本轮提交 `08e876d` message「按 Sprint 审阅拆分超 560 行文件并修复拨号静默失败」如实无绝对词 | ✅ **已守** |

## 三、客观门禁（复审实测）

| 手段 | 结果 |
|------|------|
| `flutter analyze`（HEAD `08e876d`） | **No issues found!（exit 0）** ✅ 五轮守住 |
| 日程模块 3 个原超限文件 | ✅ 全部 ≤560（`schedule_detail_page` 543 / `schedule_form_sheet` 361 / `schedule_list_page` 433） |
| 全库 `lib/` >560 扫描 | ⚠️ **仅 `login_page.dart` 612 行仍超限**（非日程模块、第三轮顺延观察项，本轮未动且 601→612 又涨 11） |
| 死代码 / `part` 结构 | ✅ `schedule_form_fields`/`schedule_grouping`/`schedule_detail_cards`/`schedule_detail_actions` 结构合法，analyze 全绿 |
| 整改提交 message | ✅ `08e876d` 措辞如实，符合新硬化规则 §8.2 |

## 四、整改文档本身的问题（需团队留意）

1. **事实夸大（已就地更正）**：整改文档原第 123 行「所有源码文件行数均 ≤ 560 红线」不准确——`login_page.dart` 仍 612 行。已改为「日程模块相关源码文件均 ≤ 560」并加注。复审在组长权限下直接修正该处事实偏差。
2. **文档结构脏**：存在两个重复的「Round 2 — P2-3 + P2-4」标题（原第 31 行已填内容、第 89 行仍为「⏳ 待执行」空模板残留）；Round 1 内容（日期修复+详情拆）无小节标题，仅靠「下一轮」指针倒推。建议团队产整改文档时用统一模板，删空占位。
3. **「独占提交」声称与 git 不符**：整改文档称「P1-1 日期下限独占提交已随 Round 1 落地」，但 git 实际仅一个整改提交 `08e876d`（日期修复+拆分+拨号全打包）。该日期修复属功能性回归（非 §8.2 定义的"发布阻断级"），打包不违规，但文档说"独占"属措辞不实，建议改为"随整改提交一并落地"。

## 五、复审结论

**核心判定**：A- 的两个放行条件（P1 表单过去时间校验、P1 详情页拆分）**均真实验证通过**；P2 两个超大文件拆分、P2 handler 去重、P3 拨号反馈**全部真实落地**；`flutter analyze` 五轮 0 issue 守住；日程模块 560 红线纪律**已恢复**。

**评级上调：A- → A（趋势 A+）**
- 第三轮被下调的主因（文件体量纪律回摆 + 一处功能性回归）本轮**全部闭环**，故恢复至 A。
- 距 A+ 仅差：① `login_page.dart` 612 行仍未收（已知观察项，但持续上涨需排期）；② `SelectChip` 合并进 `TagChipRow` 仍未做（P3 观察）。两者均非阻塞。

**放行结论**：✅ **本轮整改通过，可进入下一功能开发**。

**遗留开放项（顺延，非阻塞）**
| 优先级 | 事项 | 状态 |
|--------|------|------|
| P3 | `login_page.dart` 612 行（601→612 又涨）：排期拆分或修订红线阈值并写理由 | ⚪ 观察（建议下轮排期，已连续两轮顺延） |
| P3 | `SelectChip` 合并进 `TagChipRow` 去双实现 | ⚪ 观察 |

**给团队的点赞**：
- 拆分手法升级——Round 2 用 `part of` + `extension on State` 访问私有成员（比上轮"独立文件+参数传值"更省样板），且踩坑记录诚实（主动纠正了上轮"part 不能访问私有"的误判）。这种"发现旧结论错就改"的态度值得肯定。
- 整改提交 `08e876d` 的 message 如实、无绝对词——新硬化规则 §8.2 第一次被实测遵守。

— Mobile App Builder（移动端小组组长），2026-07-24
