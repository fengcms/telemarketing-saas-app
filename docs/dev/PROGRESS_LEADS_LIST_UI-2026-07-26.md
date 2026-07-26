# 进度文档 — 线索列表页 / 公海线索列表页 UI 整改

> **日期**：2026-07-26
> **执行**：Mobile App Builder
> **性质**：纯 UI 整改（不破坏业务逻辑）
> **分析报告**：`docs/dev/LEADS_LIST_ANALYSIS-2026-07-26.md`

## 一、完成情况

### 1. 跨模块视觉一致 + 消除加载闪跳（P0）
- `LeadCard` / `PublicLeadCard` 卡片圆角 `12 → 10`，保留原阴影（对齐已整改的日程模块 `10 + 阴影`）
- `leads_list_page` 两个骨架屏容器：`12 无阴影 → 10 + 补阴影`，加载完成时不再"长出阴影"
- `leads_skeletons` 灰块基色 `EEEEEE → BrandColors.border`（=E7E7E7，对齐日程骨架）

### 2. 复用公共组件（P1）
- 空态 `_buildEmpty` / `_buildPublicEmpty` → `AppEmptyBody`
- 错误态 `_buildError` / `_buildPublicError` → `AppErrorBody`
- footer `_buildFooter` / `_buildPublicFooter` → `AppListFooter`（文案统一为"已加载全部"）

### 3. 硬编码色集中化（P2）
| 文件 | 映射 |
|------|------|
| `leads_list_page.dart` | `F2F3FF→primarySurface`、`0052D9→primary`×3、`F3F3F3→surface` |
| `lib/widgets/lead_card.dart` | `181818→textPrimary`、`A6A6A6→textSecondary`×5、`D54941→error`、`2BA471→success` |
| `public_lead_card.dart` | `181818→textPrimary`、`ED7B2F→warning`、`A6A6A6→textSecondary`×5、`EEEEEE→line` |
| `leads_top_bar.dart` | `0052D9→primary`、`D54941→error` |
| `leads_skeletons.dart` | `EEEEEE→border` |

## 二、保留内联的色（无对应常量 / 模块内已一致，按计划不动）
- `4E5969` 摘要条文字
- `DCDCDC` 空/错态图标（AppEmptyBody/AppErrorBody 默认值，无常量）
- `D9E1FF` / `003CAB` 分类标签靛蓝（LeadCard / PublicLeadCard）
- `E37318` 跟进倒计时橙（LeadCard，无常量）
- 各 `0x1Axxxxxx` 半透明叠色（状态徽章底）
- `0x1A000000` 筛选标签栏阴影（功能性）

## 三、明确未改动项
1. **公海分类 bug**：`PublicLeadCard` 分类标签写死 `'商铺'`（L193）未修 —— 属功能性 bug，需改 `ConsumerWidget` 接 `OptionsCacheService` 解析 `categoryId`，超出纯 UI 范围，**待单独授权后处理**。
2. **线索模块其他子页**（报告 §六 延伸范围）：`leads_filter_sheet` / `leads_filter_widgets` / `edit_lead_dialog` / `follow_up_*` / `lead_detail_page` / `lead_bottom_nav` / `dial_helper` / `correct_call_dialog` 等的硬编码色未纳入本轮，可后续同类整改。
3. **双绿**：本模块未涉及 `#00A870` 双绿问题（该问题在日程列表页，已在前面轮次标注为"列表侧离群项"）。

## 四、校验结论
- `flutter analyze` 5 目标文件：No issues
- 全仓：0 新增问题（仅 `token_storage.dart` 既有 11 个 `unnecessary_non_null_assertion` warning，与本次无关）
- 业务逻辑（双 Tab 切换 / 搜索 / 分页 / 领取 / 筛选 / 排序 / 错误重试）零改动

## 五、真机验证清单
1. 线索列表 / 公海列表卡片圆角与日程模块一致（10px + 阴影）
2. 首次进入（骨架屏）→ 数据加载完成，卡片无"缩角/长阴影"闪跳
3. 空态（无线索 / 公海为空 / 搜索无结果）图标与文案正常
4. 错误态（断网/加载失败）图标 + "加载失败" + 重试按钮（变为 FilledButton 蓝底）可点
5. 滚动到底 footer 显示"已加载全部"
6. 顶栏蓝底、筛选角标红点正常
7. 公海卡片"待跟进"橙标签、领取按钮正常；**分类仍显示"商铺"（bug 未修，符合预期）**

## 六、提交
- 待真机验证通过后 `commit & push`
