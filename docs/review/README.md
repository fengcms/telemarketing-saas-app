# 电销工作台 APP — 代码审查索引

> 审查人：Mobile App Builder（移动端小组组长）
> 机制：**一次提交，一次审核**；阶段/批次结果汇总为 `PHASE-REVIEW-*` / `SPRINT-REVIEW-*`

## 当前进行中：第三轮 Sprint 2（2026-07-23 晚）
| 文档 | 说明 |
|------|------|
| [SPRINT-REVIEW-2-2026-07-23.md](SPRINT-REVIEW-2-2026-07-23.md) | 第三轮审阅（提交 `be70e78`→`2388faa`，TagChip 统一 + 巨型文件收敛） |
| [RESPONSE-SPRINT-2026-07-23.md](RESPONSE-SPRINT-2026-07-23.md) | 开发团队整改回复（日程/编辑抽屉） |
| [RESPONSE-TAGCHIP-UNIFY.md](RESPONSE-TAGCHIP-UNIFY.md) | 开发团队整改回复（TagChipRow 统一 + 筛选布局修复） |

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
