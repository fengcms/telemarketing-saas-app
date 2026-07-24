# 电销工作台 APP — 代码审查索引

> 审查人：Mobile App Builder（移动端小组组长）
> 机制：**一次提交，一次审核**；阶段/批次结果汇总为 `PHASE-REVIEW-*` / `SPRINT-REVIEW-*`

## 已完成：第四轮 Sprint 复审（2026-07-24，日程模块整改闭环）
| 文档 | 说明 |
|------|------|
| [SPRINT-REVIEW-3-REAUDIT.md](SPRINT-REVIEW-3-REAUDIT.md) | **第四轮复审**：团队整改逐项核验（代码实测，非看声明），评级 A-→**A** |
| [SPRINT-REVIEW-3-REMEDIATION.md](SPRINT-REVIEW-3-REMEDIATION.md) | 开发团队整改跟踪（3 轮：日期校验/详情拆/表单拆/列表收/拨号反馈；已就地更正 1 处事实夸大） |
| [SPRINT-REVIEW-3-2026-07-24.md](SPRINT-REVIEW-3-2026-07-24.md) | 第四轮原审阅（提交 `2388faa`→`024f8f4`，18 个：INTERNET 根因修复 / 日程列表·详情·表单 / 拨号 / 线索详情重构） |
| [SPRINT-REVIEW-2-2026-07-23.md](SPRINT-REVIEW-2-2026-07-23.md) | 第三轮审阅（提交 `be70e78`→`2388faa`，TagChip 统一 + 巨型文件收敛） |
| [RESPONSE-SPRINT-2026-07-23.md](RESPONSE-SPRINT-2026-07-23.md) | 开发团队整改回复（日程/编辑抽屉） |
| [RESPONSE-TAGCHIP-UNIFY.md](RESPONSE-TAGCHIP-UNIFY.md) | 开发团队整改回复（TagChipRow 统一 + 筛选布局修复） |

**第四轮复审评级：A（趋势 A+）** — 两个放行条件（P1 表单过去时间校验、P1 详情页 1024→543 拆分）实测全通过；P2 两超大文件拆分（表单 361/列表 433）+ handler 去重 + P3 拨号 `TDToast` 反馈全部真实落地；`flutter analyze` 五轮 0 issue；日程模块 560 红线纪律恢复。遗留：`login_page.dart` 612 行（已知观察项、601→612 又涨，非日程模块）、`SelectChip` 合并未做（均 P3 非阻塞）。整改提交 `08e876d` message 如实，新硬化规则 §8.2 首次被实测遵守。

## 已完成：第三轮 Sprint 2（2026-07-23 晚）
| 文档 | 说明 |
|------|------|
| [SPRINT-REVIEW-2-2026-07-23.md](SPRINT-REVIEW-2-2026-07-23.md) | 第三轮审阅（提交 `be70e78`→`2388faa`，TagChip 统一 + 巨型文件收敛） |

**第三轮评级：A（强，趋势 A+）** — 4 个巨型文件全部降至 560 以下、P2 开放项闭环、新增 TagChip/SheetHeader/duration_format 三个共享抽象、9 处重复统一；唯一短板为提交 message「全部/统一」类夸大。

## 已完成：第二轮 Sprint（2026-07-23 下午）
| 文档 | 说明 |
|------|------|
| [SPRINT-REVIEW-2026-07-23.md](SPRINT-REVIEW-2026-07-23.md) | 第二轮 Sprint 审阅（提交 `d138ead`→`be70e78`） |

**第二轮评级：A（较第一轮 A- 提升）** — 0 issue 守住、被关 lint 规则重新启用、新文件修正文件头通病、对话框功能范本级。

## 已归档：第一轮全量审阅（2026-07-23，已验收通过）
见 [`history/`](history/) 目录，含 13 个提交审查 + `PHASE-REVIEW` + `RESPONSE` + `fix-follow-up-panel-ui`，整体评级 **A-**，已验收归档。

## 目录约定
- `docs/review/history/` — 已完成验收的历史批次
- `docs/review/SPRINT-REVIEW-*.md` / `PHASE-REVIEW-*.md` — 当期批次审阅
- `docs/review/RESPONSE-*.md` — 开发团队整改回复（输入）
