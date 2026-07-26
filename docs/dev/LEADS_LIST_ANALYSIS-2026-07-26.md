# 分析报告 — 线索列表页 / 公海线索列表页 UI 状况

> **日期**：2026-07-26
> **分析师**：Mobile App Builder
> **性质**：纯 UI 现状分析（不改码）
> **范围**：`leads_list_page` 框架 + `LeadCard` / `PublicLeadCard` + `LeadsTopBar` + `LeadsSkeletons` + 空/错/footer

## 一、TL;DR（核心结论）

线索模块是比日程模块**更早建立**的页面（TDesign 迁移后首批实现），本轮日程模块已做标准化（卡片 `10px + 阴影`、复用 `AppEmptyBody`/`AppErrorBody`/`AppListFooter`、色值集中化），**线索模块未跟上**，呈现三类肉眼可见问题：

1. **P0 卡片圆角/阴影跨模块不一致 + 骨架屏无阴影导致加载闪跳**
2. **P1 空态/错误态/footer 手写，未复用已建公共组件**（与日程列表页不一致）
3. **P2 大量硬编码 `Color(0xFF...)` 未集中化到 `BrandColors.*`**

> ⚠️ **额外发现一处功能性 bug**（非纯 UI，需业务授权才能改）：`PublicLeadCard` 的分类标签**写死 `'商铺'`**，未像 `LeadCard` 那样解析 `categoryId` 显示真实分类名 —— 任何公海线索都会显示"商铺"。

emoji 检查：**线索目录 0 命中**，已合规（全仓 emoji 仅原日程详情页，已整改）。

---

## 二、问题分级

### P0 — 跨模块视觉不一致 / 加载闪跳

| # | 问题 | 位置 | 影响 |
|---|------|------|------|
| P0-1 | 卡片圆角 `12` vs 日程模块 `10` | `LeadCard` L47、`PublicLeadCard` L44 | 两模块卡片视觉语言不一致（圆角差 2px 肉眼可辨） |
| P0-2 | 真实卡片有阴影（`0x12000000` blur8），骨架屏**无阴影** | `_buildSkeleton` L682、`_buildPublicSkeleton` L548 | 加载完成时卡片"长出阴影"，与日程详情页同样的闪跳 pattern |
| P0-3 | 骨架灰块 `0xFFEEEEEE` vs 日程骨架 `0xFFE7E7E7`(=border) | `LeadsSkeletons` L18 | 骨架与全 app 灰块基准不一致 |

### P1 — 公共组件未复用（与日程列表页不一致）

| # | 手写位置 | 应复用的公共组件 | 备注 |
|---|---------|----------------|------|
| P1-1 | `_buildEmpty` / `_buildPublicEmpty` | `AppEmptyBody(icon,title,desc?)` | 双行文案 + 图标，签名完全匹配 |
| P1-2 | `_buildError` / `_buildPublicError` | `AppErrorBody` | 图标 + 标题 + 副文 + 重试按钮 |
| P1-3 | `_buildFooter` / `_buildPublicFooter` | `AppListFooter(isLoadingMore,hasMore)` | ⚠️ 文案差异：本页是"已加载全部**线索**/公海线索"，公共组件固定"已加载全部" |
| P1-4 | `_buildFilterTags`（已激活筛选 chip） | 无直接对应组件 | 与日程 `AppFilterChips` 语义不同（删除式 vs 选项式），可后续抽"已选条件 chip"组件，非必须 |

### P2 — 硬编码色未集中化

| 文件 | 数量 | 典型值 | 对应 `BrandColors` |
|------|-----|--------|-------------------|
| `leads_list_page.dart` | ~21 | `0052D9`/`F3F3F3`/`181818`/`A6A6A6`/`DCDCDC`/`C5C5C5`/`F2F3FF`/`4E5969` | primary/surface/textPrimary/textSecondary/(DCDCDC 保留)/textDisabled/primarySurface |
| `lead_card.dart` | ~12 | 同上 + 状态/徽章色 `D54941`/`2BA471`/`E37318` + 分类色 `D9E1FF`/`003CAB` | error/success/(橙系无常量)/分类色无常量 |
| `public_lead_card.dart` | ~9 | 同上 + 状态橙 `ED7B2F` + 分割线 `EEEEEE` | 分类色/状态橙无常量 |
| `leads_top_bar.dart` | 2 | `0052D9`(已 import 未用)/`D54941` | primary/error |
| `leads_skeletons.dart` | 1 | `EEEEEE` | border |

**无对应常量、按计划保留内联**（与全 app 一致）：`DCDCDC`(空/错图标)、`4E5969`(摘要条文字)、`ED7B2F`(公海状态橙)、`D9E1FF`/`003CAB`(分类标签靛蓝)、`EEEEEE`(分割线/灰块)、`E37318`(跟进橙)、各 `0x1Axxxxxx` 半透明叠色。

---

## 三、逐文件详细映射

### `leads_list_page.dart`

| 行 | 原硬编码 | 建议 |
|----|---------|------|
| 211 | `0x1A000000` 筛选栏阴影 | 保留（功能性阴影） |
| 265 | `0xFFF2F3FF` 筛选 chip 底 | `BrandColors.primarySurface` |
| 275/285 | `0xFF0052D9` chip 字/图标 | `BrandColors.primary` |
| 375 | `0xFFF3F3F3` 摘要条底 | `BrandColors.surface` |
| 380 | `0xFF4E5969` 摘要文字 | 保留内联（无常量） |
| 387 | `0xFF0052D9` 摘要数字 | `BrandColors.primary` |
| 578/603/713/741 | `0xFFDCDCDC` 空/错图标 | 保留内联 |
| 585/721/748 | `0xFF181818` 标题 | `BrandColors.textPrimary` |
| 591/607/727/754 | `0xFFA6A6A6` 副文 | `BrandColors.textSecondary` |
| 614/762 | `0xFF0052D9` 重试按钮 | `BrandColors.primary` |
| 635/664 | `0x99C5C5C5` footer 文字 | `BrandColors.textDisabled.withValues(alpha:0.6)`（对齐 `AppListFooter`） |

### `lead_card.dart`（圆角 12→10、阴影保持）

| 行 | 原硬编码 | 建议 |
|----|---------|------|
| 88 | `0xFF181818` 姓名 | `BrandColors.textPrimary` |
| 102/108/150/165/171 | `0xFFA6A6A6` 多处 | `BrandColors.textSecondary` |
| 138/143 | `0xFFD9E1FF`/`003CAB` 分类 | 保留内联（模块内一致，非必须） |
| 245/246 | `0x1AD54941`/`D54941` 逾期徽章 | `BrandColors.error`(fg) + 叠色保留 |
| 249/250 | `0x1A2BA471`/`2BA471` 今日可打 | `BrandColors.success`(fg) + 叠色保留 |
| 253/254/257/258 | `0x1AE37318`/`E37318` 跟进橙 | 保留内联（无常量） |
| 47 | 圆角 `12` | `10`（对齐日程模块） |

### `public_lead_card.dart`（圆角 12→10、阴影保持）

| 行 | 原硬编码 | 建议 |
|----|---------|------|
| 129 | `0xFF181818` 姓名 | `BrandColors.textPrimary` |
| 138/147 | `0x1AED7B2F`/`ED7B2F` 状态橙 | 保留内联（无常量） |
| 160/166/202/216/220 | `0xFFA6A6A6` 多处 | `BrandColors.textSecondary` |
| 189/194 | `0xFFD9E1FF`/`003CAB` 分类 | 保留内联 |
| 74 | `0xFFEEEEEE` 分割线 | `BrandColors.line`(若已定义) 或 `border` |
| 44 | 圆角 `12` | `10` |

> 🐞 **P-bug**：L193 `const Text('商铺', ...)` 写死。应解析 `lead.categoryId` 显示真实分类（参考 `LeadCard._buildCategoryRow` 走 `OptionsCacheService`）。需改为 `ConsumerWidget` 接入 cache —— **超出纯 UI 范围，需业务授权**。

### `leads_top_bar.dart`

| 行 | 原硬编码 | 建议 |
|----|---------|------|
| 38 | `0xFF0052D9` 顶栏底（已 `import color_scheme` 未用） | `BrandColors.primary` |
| 97 | `0xFFD54941` 筛选角标 | `BrandColors.error` |

### `leads_skeletons.dart`

| 行 | 原硬编码 | 建议 |
|----|---------|------|
| 18 | `0xFFEEEEEE` 灰块 | `BrandColors.border` |
| 骨架容器 | `12` 无阴影 | `10` + 加 `0x12000000` 阴影（对齐真实卡片） |

---

## 四、整改批次建议（待确认后执行）

- **Batch 1（视觉一致性，纯视觉）**：`LeadCard`/`PublicLeadCard`/骨架屏圆角 `12→10`；骨架屏补阴影消除加载闪跳；顶部栏 `0052D9`→`primary`。
- **Batch 2（组件复用）**：空态/错误态 → `AppEmptyBody`/`AppErrorBody`；footer → `AppListFooter`（⚠️ 确认是否接受文案统一为"已加载全部"）。
- **Batch 3（色值集中化）**：P2 表内所有可映射色 → `BrandColors.*`；保留无对应常量的内联色。
- **（可选）P-bug 修复**：`PublicLeadCard` 分类名写死 → 接入 `OptionsCacheService` 解析（需单独授权，非 UI 整改）。

---

## 五、待确认项

1. **圆角对齐**：确认线索模块向日程模块对齐为 **`10 + 阴影`**（而非反向改日程）？
2. **footer 文案**：复用 `AppListFooter` 后，原"已加载全部**线索**/公海线索"→ 统一"已加载全部"，是否可接受？或给 `AppListFooter` 加 `suffix` 参数保留区分？
3. **公海分类 bug**：是否一并授权修复写死 `'商铺'` 的问题（需改 `ConsumerWidget`）？还是本次仅做 UI、bug 另开任务？
4. **分类标签色**（`D9E1FF`/`003CAB`）与**状态橙**（`ED7B2F`/`E37318`）：是否新增 `BrandColors` 常量（如 `categorySurface`/`categoryText`/`warning`）以彻底消除硬编码？还是保持内联（模块内已一致）？

---

## 六、延伸范围（本次未展开）

`leads_filter_sheet` / `leads_filter_widgets` / `edit_lead_dialog` 等子页同样存在硬编码色，可后续纳入同类整改。本次聚焦"列表页 + 公海列表"框架与卡片。

---

## 七、执行记录（2026-07-26）

按报告推荐默认执行 UI 三批，**公海分类写死 `'商铺'` 的 bug 不在纯 UI 范围，本轮未改**（待单独授权）。

### Batch 1 — 圆角/阴影统一（消除加载闪跳）
- `LeadCard` / `PublicLeadCard` 卡片圆角 `12 → 10`，保留原 `0x12000000` 阴影（与日程模块一致）
- `leads_list_page` 两个骨架屏容器：`12 无阴影 → 10 + 补阴影`，消除加载完成"长出阴影"闪跳
- `leads_skeletons` 灰块 `0xFFEEEEEE → BrandColors.border`（=E7E7E7，对齐日程骨架基色）

### Batch 2 — 复用公共组件
- `_buildEmpty` / `_buildPublicEmpty` → `AppEmptyBody`（图标+主副文案，居中保留）
- `_buildError` / `_buildPublicError` → `AppErrorBody`（图标 size 80 + 默认灰 + 重试按钮）
- `_buildFooter` / `_buildPublicFooter` → `AppListFooter`（文案统一为"已加载全部"）
- ⚠️ 视觉差异：错误重试按钮由 `TextButton`(蓝字) 变为 `AppErrorBody` 标准 `FilledButton`(蓝底)，与日程详情页一致

### Batch 3 — 硬编码色集中化
| 文件 | 映射 |
|------|------|
| `leads_list_page` | `F2F3FF→primarySurface`、`0052D9→primary`×3、`F3F3F3→surface` |
| `lead_card` | `181818→textPrimary`、`A6A6A6→textSecondary`×5、`D54941→error`、`2BA471→success` |
| `public_lead_card` | `181818→textPrimary`、`ED7B2F→warning`、`A6A6A6→textSecondary`×5、`EEEEEE→line` |
| `leads_top_bar` | `0052D9→primary`、`D54941→error` |
| `leads_skeletons` | `EEEEEE→border` |

**保留内联**（无对应常量 / 模块内已一致）：`4E5969`(摘要文字)、`DCDCDC`(空错图标)、`D9E1FF/003CAB`(分类靛蓝)、`E37318`(跟进橙)、各 `0x1Axxxxxx` 半透明叠色、`0x1A000000`(筛选栏阴影)。

### 校验
- `flutter analyze` 5 目标文件 No issues；全仓 0 新增问题（仅 `token_storage.dart` 既有 11 个 `!` warning，与本次无关）
- 业务逻辑（双 Tab 切换 / 搜索 / 分页加载 / 领取 / 筛选 / 排序 / 错误重试）零改动
- 提交：`<待真机验证后 commit>`
