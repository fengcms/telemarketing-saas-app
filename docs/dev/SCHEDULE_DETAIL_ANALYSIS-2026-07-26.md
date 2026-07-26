# 日程详情页 UI 分析

> 分析日期：2026-07-26
> 关联：列表页清洗（4f37afd / 7b2b672 / 3bbc02d）、筛选条统一（f058760）
> 规范基线：`docs/dev/UI_STYLE_GUIDE.md` v2.0、线索详情页（`lib/pages/leads/`）
> 结论：详情页是本轮 UI 整改中**唯一未被清洗的展示页**，存在「emoji 离群」「卡片圆角/阴影三处不一致」「漏复用公共组件」「约 34 处硬编码色」四类问题。用户体感上的「不满意」大概率来自前两类。

---

## 一、结论速览

| 级别 | 类别 | 问题 | 影响 |
|:----:|------|------|------|
| **P0** | 视觉离群 | 分区标题/字段用 emoji 图标（📅👤📝📞 + 🔄），全仓仅此处 | 跨平台渲染不一致、与全 app 风格割裂 |
| **P0** | 视觉跳变 | 详情卡片圆角=12 无阴影；列表卡=10+阴影；骨架屏=10+阴影 | 加载完成时卡片「变平+缩角」明显闪跳 |
| **P1** | 跨页不一致 | 状态标签手写 `statusTag`，未复用 `AppTag`（线索详情/列表都用 AppTag） | 同一状态两处渲染逻辑分叉 |
| **P1** | 跨页不一致 | 信息卡手写 `_infoRow`，未复用 `AppInfoRow`（线索详情用 AppInfoRow） | 信息行版式与线索详情不同 |
| **P1** | 跨页不一致 | 错误态手写 `_buildErrorState`，未复用 `AppErrorBody`（列表页已复用） | 错误态样式与列表页/线索详情不同 |
| **P2** | 主题合规 | 约 34 处硬编码 `Color(0xFF...)`，未收敛到 `BrandColors.*` | 维护风险（列表页已清洗，此处漏掉） |
| **P2** | 主题合规 | Scaffold 背景 `Color(0xFFF3F3F3)` 未用 `BrandColors.surface` | 全 app 普遍，低优先 |

> 说明：完成态绿色存在「双绿」——列表 `_statusColor` 用 `#00A870`，详情 `statusTag` 用 `#2BA471`（恰好等于 `BrandColors.success`）。**详情页才是与主题常量一致的那一侧**，列表是离群方。故详情页不改动该绿，双绿统一建议放到列表页侧评估（不在本页范围）。

---

## 二、详细问题

### 2.1 P0-1：emoji 图标离群（最显眼的视觉问题）

**现状**（`schedule_detail_cards.dart`）：

```dart
'📅 计划时间'      // line 191
'👤 关联线索'      // line 236 / 257
'📞 ${lead.phone}' // line 275
'📝 日程内容'      // line 291
'🔄 重新打开'      // schedule_detail_actions.dart line 46
```

**证据**：全仓 `lib/` 仅 `schedule_detail_*` 两文件出现 emoji；线索详情、列表页、表单页全部使用 Material `Icons`（如列表卡 `Icons.access_time` / `Icons.badge_outlined`，线索详情 `Icons.business` 等）。emoji 源自 TDesign 时代设计稿（`docs/design/page-design/11-日程详情.md` 的 ASCII 稿里就是 emoji），迁移 M3 时被原样保留，成为唯一遗漏点。

**风险**：emoji 在不同系统/字体下字形与基线不一致（iOS 彩色、Android 单色/不同字号），与全 app 的线性 `Icons` 视觉语言割裂，显得不专业。

**建议**：emoji → Material `Icons`，并改为「前导图标 + 文字」的 `Row`（对齐 `AppInfoRow` 风格）：

| 原 emoji | 替换为 | 用途 |
|---------|--------|------|
| 📅 | `Icons.event` | 计划时间 |
| 👤 | `Icons.person` / `Icons.contact_page` | 关联线索 |
| 📝 | `Icons.description` | 日程内容 |
| 📞 | `Icons.phone` | 线索电话 |
| 🔄 | `Icons.replay` | 重新打开 |

例：

```dart
Row(children: [
  Icon(Icons.event, size: 16, color: BrandColors.textSecondary),
  const SizedBox(width: 8),
  const Text('计划时间', style: TextStyle(fontSize: 12, color: BrandColors.textSecondary)),
]),
```

---

### 2.2 P0-2：卡片圆角/阴影三处不一致 → 加载闪跳

| 来源 | 圆角 | 阴影 | 位置 |
|------|:----:|------|------|
| 详情 `detailCard()` | **12** | **无** | `schedule_detail_cards.dart:13` |
| 列表 `ScheduleCard` | **10** | `0x0D000000` 6/2 | `schedule_card.dart:59` |
| 详情骨架 `_skeletonCard` | **10** | `0x0D000000` 6/2 | `schedule_skeleton.dart:111` |

**问题**：同一「日程」实体，列表卡是 10+阴影，详情卡却是 12 无阴影；而骨架屏（loading 态）是 10+阴影。**加载完成时**：卡片从「10+阴影」瞬间变成「12 无阴影」——既缩角又掉阴影，肉眼可见的「啪」一下跳变。

> 注：`UI_STYLE_GUIDE.md` §5.1 写的是详情卡「圆角 12 + 阴影」，但**当前线上列表卡与骨架都是 10+阴影**，是 app 内日程类卡片的主导现实样式。为保持「列表 ↔ 详情 ↔ 骨架」三处一致，建议详情卡向列表卡对齐为 **10 + 阴影**，而非反向改列表。

**建议**：`detailCard()` 改为圆角 10 + `BoxShadow(color: 0x0D000000, blur:6, offset:0/2)`，与列表卡/骨架屏完全一致。骨架屏本身已合规，无需动。

---

### 2.3 P1-1：状态标签手写 `statusTag` 未复用 `AppTag`

**现状**（`schedule_detail_cards.dart:153`）：手写 `Container`+`Text` 实现三态标签。
**对照**：列表卡 `ScheduleCard` 用 `AppTag`（颜色经 `_statusColor` 取 10% alpha 作底）；线索详情 `LeadHeaderSection` 也用 `AppTag`。

**建议**：`statusTag(d)` 重构为返回 `AppTag`，颜色映射复用列表同款 `_statusColor`（如需共享，可把 `_statusColor`/`_statusLabel` 提到 `schedule_card.dart` 对外或抽公共 util）。Padding 对齐 `AppTag` 默认 `6×2`（现状 `8×3` 略大，可顺带收敛）。

---

### 2.4 P1-2：信息卡手写 `_infoRow` 未复用 `AppInfoRow`

**现状**（`schedule_detail_cards.dart:327`）：`_infoRow` 为「左标签(宽80)/右值」两列布局，纯文字无图标。
**对照**：线索详情 `lead_header_section.dart` 用 `AppInfoRow`（图标 + `label: value` 内联）。

**建议二选一**：
- **A（推荐）**：改用 `AppInfoRow(icon, label, value)`，与线索详情一致，且加图标更耐看；版式变为「图标 + 标签: 值」内联。
- B：保留「左标签/右值」版式，仅把 `_infoRow` 内硬编码色迁移到 `BrandColors`，不动布局。

> 若选 A，信息卡三行（创建时间/归属人/更新时间）分别配 `Icons.schedule` / `Icons.badge_outlined` / `Icons.update`。

---

### 2.5 P1-3：错误态手写 `_buildErrorState` 未复用 `AppErrorBody`

**现状**（`schedule_detail_page.dart:269`）：手绘 `Icons.event_busy`(80) + 两级文字 + `TextButton`(品牌色)。
**对照**：列表页已清洗为 `AppErrorBody`；线索详情也用 `AppErrorBody`。

**建议**：改为 `AppErrorBody`，错误码映射到合适图标/文案：

```dart
AppErrorBody(
  icon: Icons.event_busy,
  title: is404 ? '该日程不存在或已被删除'
       : is403 ? '无权查看该日程' : '加载失败',
  message: (is404 || is403) ? '' : (_errorMessage ?? ''),
  actionText: is404 || is403 ? '返回列表' : '重新加载',
  onAction: () => is404 || is403
      ? Navigator.of(context).pop()
      : _load(force: true),
)
```

> 视觉差异：AppErrorBody 默认图标 64、`actionText` 渲染为 `FilledButton`；现状是 80 + `TextButton`。统一后更规范，但按钮由文字蓝变为实色蓝药丸——属预期内改善。

---

### 2.6 P2：硬编码色集中化（约 34 处）

分布（grep `Color(0xFF` 于 `lib/pages/schedules`）：

| 文件 | 处数 | 主要可迁移到 BrandColors |
|------|:----:|------|
| `schedule_detail_cards.dart` | 23 | `textPrimary`/`textSecondary`/`primary`/`error`/`primarySurface`/`line` |
| `schedule_detail_page.dart` | 7 | `surface`/`textPrimary`/`textSecondary`/`primary`/`error` |
| `schedule_detail_actions.dart` | 4 | `line`/`primary`/`textPrimary` |
| `schedule_skeleton.dart` | 4 | 多为 shimmer 渐变/shadow，部分保留 |

**可直接替换**（与 BrandColors 等价）：
- `0xFFF3F3F3` → `BrandColors.surface`（Scaffold 背景，page:180）
- `0xFF181818` → `BrandColors.textPrimary`（多处）
- `0xFFA6A6A6` → `BrandColors.textSecondary`（多处）
- `0xFF0052D9` → `BrandColors.primary`（page:308、actions:88）
- `0xFFD54941` → `BrandColors.error`（page:201/457、cards:204/213）
- `0xFFF2F3FF` → `BrandColors.primarySurface`（cards:166，pending 标签底）
- `0xFFEEEEEE` → `BrandColors.line`（actions:58 顶部分隔线）

**无 BrandColors 对应、保留内联**（与列表卡/骨架屏既有写法一致，可接受）：
- `0xFFE3F3EA`（完成标签浅绿底——若选 P1-1 复用 AppTag，则底由 `_statusColor(success).withAlpha(26)` 派生，此值自然消失）
- `0xFFDCDCDC`（禁用图标灰 / 空态图标灰——全 app 通用占位灰，无常量）
- `0x0D000000` / `0x14000000`（卡片/操作栏阴影——列表卡同样内联 `0x0D000000`）
- `0x66000000` / `0x52000000`（删除遮罩 / 主题 scrim——标准遮罩值）
- `0xFFF4F4F4`（shimmer 中段灰，骨架屏内部）

> 说明：列表卡阴影也是 `0x0D000000` 内联，故详情页保留同值内联与全局保持一致，无需新增 BrandColors 常量。

---

## 三、已合规项（不改动）

- ✅ 分区标题用 `textSecondary`（非品牌蓝），符合 §2.3 规则。
- ✅ AppBar 用 `BrandColors.primary` 底 + 白色前景，符合品牌规范。
- ✅ 底部操作栏用 `AppActionBar`（外层仅包 Container 做顶边/阴影），主体合规。
- ✅ 标题字号 24 与线索详情头部（24/w600）一致，类型尺度对齐。
- ✅ 详情页已拆分 `cards`/`actions` 独立库，结构清晰（不在本次整改范围）。
- ✅ 逾期红字 + 「已逾期」标签逻辑正确，颜色用 `error`。

---

## 四、建议整改批次（待确认）

| 批次 | 内容 | 风险 | 是否纯视觉 |
|------|------|:----:|:----------:|
| **Batch 1** | emoji→Material Icons；`detailCard` 圆角 10+阴影统一 | 低 | 是 |
| **Batch 2** | 复用 `AppTag`(状态标签) / `AppInfoRow`(信息卡) / `AppErrorBody`(错误态) | 低-中 | 否（含版式微调） |
| **Batch 3** | 硬编码色集中化到 `BrandColors.*`（约 34 处） | 低 | 否（不动外观） |
| 单列 | 完成态双绿（#00A870 vs #2BA471）统一到列表侧评估 | — | 涉及列表改动，不属本页 |

**推荐执行顺序**：Batch 1 → 2 → 3（与列表页清洗顺序一致，每批真机验证后再进下一批）。

---

## 五、待你确认的问题

1. **信息卡版式**：采用 A（复用 `AppInfoRow`，加图标「标签: 值」内联，对齐线索详情）还是 B（保留左标签/右值，仅迁移色）？
2. **卡片圆角**：确认「详情向列表对齐为 10+阴影」（而非反向把列表改为 12）？
3. **状态标签**：确认复用 `AppTag` 并把 `_statusColor` 与列表共享（消除两套状态色逻辑）？

> 确认后我会按批次出开发计划文档，逐批改造 + 真机验证 + 提交。

---

## 六、执行记录（2026-07-26，已改码未提交，待真机验证）

用户确认「按你的计划推进，仅 UI 调整，不破坏业务」，三批全部落地，`flutter analyze` 全仓 0 错误（仅 token_storage.dart 既有 11 个 `!` warning，无关）。

### 6.1 Batch 1 — emoji→Icons + 卡片圆角/阴影统一
- `schedule_detail_cards.dart`：新增 `_sectionLabel(icon, text)` 助手（图标 16 + textSecondary）；
  分区标题 📅👤📝 改为 `Icons.event`/`Icons.person`/`Icons.description`，线索电话 📞 改为 `Icons.phone` 前导；
  `detailCard` 圆角 12→**10** + 加 `BoxShadow(0x0D000000,6,2)`，与列表卡/骨架屏一致（消除加载闪跳）。
- `schedule_detail_actions.dart`：操作栏「🔄 重新打开」改为 `Icons.replay` 图标 + 文字「重新打开」。
- 全仓 emoji 扫描：日程页 emoji 已清零。

### 6.2 Batch 2 — 复用公共组件
- `statusTag` → 复用 `AppTag`（颜色映射保持原值：完成 `#E3F3EA`+`success`、取消 `surface`+`textSecondary`、待办 `primarySurface`+`primary`，padding 8×3），不再手写 Container。
- `infoCard` 的 `_infoRow` → 复用 `AppInfoRow`（图标 `Icons.schedule`/`badge_outlined`/`update` + 「标签: 值」内联，对齐线索详情）；删除 `_infoRow` 函数。
- `schedule_detail_page._buildErrorState` → 复用 `AppErrorBody`（`event_busy`/80/`DCDCDC`，action 返回列表或重新加载 `_load(force)`）。

### 6.3 Batch 3 — 硬编码色集中化
- `schedule_detail_page`：`F3F3F3`→`surface`、`D54941`(删除菜单/确认)→`error`。
- `schedule_detail_cards`：`A6A6A6`→`textSecondary`、`181818`→`textPrimary`、完成 fg→`success`、取消/待办 bg→`surface`/`primarySurface`、fg→`textSecondary`/`primary`、`D54941`(逾期)→`error`。
- `schedule_detail_actions`：`EEEEEE`→`line`、`0052D9`→`primary`、`181818`→`textPrimary`（`DCDCDC` 禁用灰保留内联）。
- `schedule_skeleton`（共享，影响列表）：`E7E7E7`×4→`BrandColors.border`（精确等值，零视觉变化）。
- **保留内联**（无 BrandColors 对应，按计划）：`0xFFE3F3EA`(完成标签浅绿底)、`0xFFDCDCDC`(禁用/空态灰)、`0xFFF4F4F4`(shimmer 中段)、阴影/遮罩 `0x0D/0x14/0x66/0x52...`。
- **未动**（属报告明确的「列表侧/其他页」范围）：`schedule_card._statusColor` 的 `#00A870` 双绿、以及 `schedule_search_page`/`schedule_form_fields` 的硬编码色。

### 6.4 验证要点（真机热重启核对）
1. 详情页各区块标题前导图标正常（事件/人/文档/电话/时钟/徽章/刷新），无 emoji。
2. 列表→详情→骨架 三处卡片圆角均为 10 + 同款微阴影，加载无「缩角+掉阴影」跳变。
3. 状态标签（待办蓝 / 已完成绿 / 已取消灰）外观与改动前一致（仅换 AppTag 容器）。
4. 信息卡变为「图标 + 创建时间: … / 归属人: … / 更新时间: …」内联格式。
5. 错误态（404/403/网络）走 AppErrorBody，按钮为实色蓝药丸，文案与跳转不变。
6. 业务回归：编辑/删除/取消/完成/重开/拨号/跟进/日程 全部入口与回调正常，权限显隐不变。
