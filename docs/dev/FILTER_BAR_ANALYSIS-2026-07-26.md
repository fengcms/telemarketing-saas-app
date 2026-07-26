# 通话记录 / 客户列表「筛选条」UI 一致性分析报告

> 版本：v1.0　|　日期：2026-07-26　|　范围：通话记录页、客户列表页
> 目的：在不改动代码的前提下，梳理两个列表页「搜索框下方的筛选项」在 UI 层面存在的风格不一致问题，并给出统一方案建议。

---

## 一、背景

两个列表页都在搜索框下方放置了一个「单选筛选条」：

- **通话记录页**（`lib/pages/call_records/`）：接听类型筛选，6 个选项（全部/已接听/无人接听/拒接/空号/停机），横滚胶囊标签。
- **客户列表页**（`lib/pages/customers/`）：等级筛选，5 个选项（全部/普通/重要/VIP/流失），通栏分段控件。

两者承担相同的交互语义（单选 + 切换即重拉列表），但视觉与交互范式并不统一，用户在两个页面会感知到两套不同的「筛选语言」。

---

## 二、现状快照（实现事实对照）

| 维度 | 通话记录 `CallFilterBar` | 客户列表 `CustomerFilterBar` |
|------|--------------------------|------------------------------|
| 交互范式 | 横滚 Choice Chip（标签式） | 通栏 Segmented（分段控件） |
| 容器 | `Container(color: white)` | `Container(color: white)` |
| 内边距 | `fromLTRB(16, 4, 16, 12)` | `fromLTRB(12, 6, 12, 10)` |
| 选项布局 | `SingleChildScrollView + Row` 横滚 | `Row + Expanded` 等宽占满 |
| 选中态背景 | `#F2F3FF` 浅蓝底 + `1px #0052D9` 蓝边 | `#F2F3FF` 浅蓝底，**无边框** |
| 未选中态背景 | `#F3F3F3` 灰底 | `transparent` 透明 |
| 形状 | `BorderRadius.circular(999)` 全圆角药丸 | `BorderRadius.circular(6)` 圆角矩形 |
| 文字字号 | 13px | 13px |
| 选中态字重 | 常规（未加粗） | `FontWeight.w500` |
| 未选中文字色 | `#6B7A90`（硬编码，调色板外） | `#6B7A90`（硬编码，调色板外） |
| 选中文字色 | `#0052D9`（硬编码） | `#0052D9`（硬编码） |
| 点击反馈 | `GestureDetector`（无水波纹） | `GestureDetector`（无水波纹） |
| 与搜索栏间分隔线 | **无**（连续白块） | **有**（`Divider`，`#EEEEEE`） |

> 引用：通话记录 `call_records_page.dart:236`、客户列表 `customer_list_page.dart:218-224`。

---

## 三、一致性问题清单

| # | 问题 | 通话记录 | 客户列表 | 规范期望 |
|:--:|------|----------|----------|----------|
| 1 | 交互范式 | 胶囊标签 | 分段控件 | 同一语义应统一 |
| 2 | 选中态视觉 | 浅蓝底+蓝边 | 仅浅蓝底 | 统一 |
| 3 | 未选中背景 | 灰底 | 透明 | 统一 |
| 4 | 形状语言 | 全圆药丸(999) | 圆角矩形(6) | 统一 |
| 5 | 选中字重 | 常规 | w500 | 统一加粗 |
| 6 | 文字色值 | 硬编码 `#6B7A90` | 硬编码 `#6B7A90` | 用 `BrandColors` |
| 7 | 内边距 | `16/4/12` | `12/6/10` | 统一 16 横向 |
| 8 | 搜索↔筛选分隔线 | 无 | 有 | 统一策略 |
| 9 | 水波纹反馈 | 无 | 无 | M3 应有 ripple |
| 10 | 组件复用 | 独立 widget | 独立 widget | 应抽公共组件 |

---

## 四、逐项分析与影响

### 1. 交互范式不统一（最严重）
通话记录用的是「可横滚的筛选标签（chip）」，客户列表用的是「通栏分段控件（segmented）」。二者暗示的交互心智不同：
- Chip 暗示「从一组标签里挑一个，数量可能很多、可滚动」；
- Segmented 暗示「在少量平级选项间切换视图，等宽平铺」。

同一类「列表筛选」出现两种范式，是用户感知不一致的首要来源。**且通话记录有 6 个选项、含「无人接听/空号/停机」等长标签，分段控件在窄屏会拥挤**，本身就更适合 chip 方案。

### 2 & 3. 选中/未选中态视觉不一致
- 通话记录选中态有「浅蓝底 + 1px 蓝边」双重信号；客户列表只有「浅蓝底」，无边框，信号更弱。
- 未选中态：通话记录是灰底 `#F3F3F3`（像实体标签），客户列表是透明（像分段按钮）。

同一「已选中」在两个页面看起来重量不同，用户难以建立稳定预期。

### 4. 形状语言冲突
全圆药丸(999) vs 圆角矩形(6)。项目内 `AppSearchBar`(20px 药丸)、`TagChip`(14px 药丸) 均以药丸为主语言；分段控件的 6px 圆角是另一套。建议统一为药丸。

### 5. 选中字重不一致
客户列表选中加粗 `w500`，通话记录未加粗。加粗能强化「当前选中」反馈，应两页统一加粗。

### 6. 离谱的硬编码色值（违反 UI 规范）
两处都把未选中文字写成 `#6B7A90`，**这不是 `BrandColors` 中定义的任何常量**（调色板里最接近的 `textSecondary` 是 `#A6A6A6`，明显更浅）。属于「调色板外自定义色」，违反 `UI_STYLE_GUIDE.md` §1.2「禁止在文件内硬编码色值，使用 `BrandColors.*`」。
同时选中的 `#0052D9`、`#F2F3FF`、`#F3F3F3` 也均为硬编码字面量，应分别替换为 `BrandColors.primary` / `primarySurface`(或 `surfaceLight`) / `surface`。

### 7. 内边距不一致
通话记录横向 16、客户列表横向 12，与规范 §4.1「列表页左右 16px」冲突（客户列表的 12 偏窄、未对齐页面边距）。纵向 padding 两页也不同（4/12 vs 6/10），导致筛选条高度观感不一致。

### 8. 搜索栏与筛选条的分隔线
通话记录：搜索栏白块与筛选条白块直接相连，无分隔；客户列表：中间插了一条 `Divider(#EEEEEE)`。两种处理让用户对「搜索」和「筛选」是否为同一组的认知不一致。**建议两页统一：都在搜索栏与筛选条之间加 1px `BrandColors.line` 分隔线**（客户页保留、通话记录补上），语义更清晰，且只动一处。

### 9. 缺少 M3 水波纹反馈
两者均用 `GestureDetector` 直接包 `Container`，点击无 ripple。M3 强调有形的触摸反馈，应改为 `InkWell`（或直接使用原生 `ChoiceChip` / `SegmentedButton`）以获得免费的水波纹与无障碍语义。

### 10. 重复实现、无公共组件
两个 widget 逻辑高度雷同（遍历 `({code,label})` 列表、选中高亮、回调），却各自实现一遍，差异就是上面 1–9 的全部来源。**根因是缺一个共享的筛选条组件**，每个页面各自造轮子，自然越造越不像。

---

## 五、根因分析

1. **缺少统一筛选条组件**：过滤 UI 的「单选高亮条」没有被抽成公共组件，导致各页自行实现。
2. **早于既有规范与组件**：`TagChip`（胶囊选择器，见 `lib/widgets/tag_chip.dart`）与 `UI_STYLE_GUIDE` 是在这两个筛选条之后才确立的，二者未对齐到新规范。
3. **范式选择随意**：一个作者选了 chip、一个选了 segmented，无统一约定。

> 延伸：本应用实际上存在 **三种** 筛选范式 —— 线索列表用「筛选按钮 → 底部抽屉」(`LeadsTopBar` + `leads_filter_sheet`)，通话记录用「内联 chip 条」，客户列表用「内联分段条」。本报告聚焦用户指定的后两者；建议后续把「简单单选」统一为内联条，「多字段复合筛选」才用底部抽屉。

---

## 六、统一方案建议

### 推荐方案：统一为「可横滚药丸筛选条」+ 共享组件

**理由**：选项数量可变、窄屏不拥挤、与项目药丸语言（`AppSearchBar`/`TagChip`）一致，且能同时覆盖通话记录(6 项)与客户列表(5 项)。

**落地方式（二选一）**：
- **A. 复用 `TagChipRow(scrollable: true)`**（零新组件，最省力）：直接用它渲染筛选项，选中态即 `TagChip` 规范的「蓝底白字实心胶囊」。代价：当前「浅蓝底+蓝字」的轻盈风格要改成像素对齐 `TagChip`。
- **B. 新建共享 `AppFilterChips` 组件**（推荐）：抽一个 `AppFilterChips({items, selectedCode, onChanged})`，**保留「浅蓝底 `#F2F3FF` + 蓝字 `#0052D9` + 1px 蓝边」的轻盈选中风格**（即采用通话记录现有观感，让客户列表改过去），内部用 `InkWell` 提供水波纹。视觉最贴合现有设计语言，且不破坏已上线的通话记录观感。

> 倾向 **方案 B**：改动小、风格最贴近现状、解决全部 10 项不一致，同时消除重复代码。

### 统一后视觉规格（建议值）

| 维度 | 统一规格 |
|------|----------|
| 交互范式 | 横滚药丸 chip（两页一致） |
| 容器背景 | `Colors.white` |
| 内边距 | `fromLTRB(16, 8, 16, 8)`（横向对齐 16 页面边距） |
| 形状 | `BorderRadius.circular(999)` 全圆药丸 |
| 高度 | 32 |
| 横向 padding | 14 |
| 选中背景 | `BrandColors.primarySurface`(`#F2F3FF`) |
| 未选中背景 | `BrandColors.surface`(`#F3F3F3`)（两页统一为灰底，不用透明） |
| 选中边框 | `Border.all(BrandColors.primary, 1)` |
| 选中文字 | `BrandColors.primary`，`FontWeight.w500` |
| 未选中文字 | `BrandColors.textSecondary`(`#A6A6A6`)（替换离谱的 `#6B7A90`） |
| 点击反馈 | `InkWell`（水波纹） |
| 搜索↔筛选分隔 | 两页均加 1px `BrandColors.line` 分隔线 |
| 与列表间距 | 保持 `SizedBox(height: 8)` |

> 说明：未选中文字改用 `textSecondary`（`#A6A6A6`）而非原 `#6B7A90`，是为了回到调色板内；若你认为原 `#6B7A90` 的对比度更合适，可在 `BrandColors` 中**新增一个具名常量**（如 `textLabel`）而不是继续硬编码。

---

## 七、落地步骤（待确认后执行）

1. 新建 `lib/widgets/app_filter_chips.dart`，实现 `AppFilterChips`（按第六节规格 B）。
2. `CallFilterBar`：内部改用 `AppFilterChips`，删除 `_chip` 自绘逻辑；保留选项列表与回调签名。
3. `CustomerFilterBar`：从「分段控件」改为「横滚药丸」，内部改用 `AppFilterChips`；删除 `Expanded` 等宽逻辑。
4. 两页 `build` 中：搜索栏与筛选条之间统一补/留 1px `BrandColors.line` 分隔线。
5. 全局替换硬编码色值为 `BrandColors.*`（含客户页 `Divider` 的 `#EEEEEE` → `BrandColors.line`）。
6. `flutter analyze` 0 issue 后真机热重启核对。

---

## 八、延伸观察（非本次范围，供参考）

- **客户列表的 scope 切换**（`PopupMenuButton`「我的/全部」在 AppBar 右侧）是第三种筛选控制，与内联筛选条并存。若后续追求极致一致，可考虑把 scope 也做成筛选条里的一个 chip 组，但属较大改动，本次不纳入。
- **线索列表**走「筛选按钮 → 底部抽屉」复合筛选，与内联条是不同复杂度层级，建议保留其范式，仅统一「简单单选」类场景。

---

## 九、结论

两个筛选条在**交互范式、选中/未选中视觉、形状、字重、色值、内边距、分隔线、点击反馈** 8 个维度上均不一致，且各自硬编码了调色板外的颜色（`#6B7A90`），违反 `UI_STYLE_GUIDE`。根因是缺少共享筛选条组件。

建议抽公共 `AppFilterChips`、统一为「横滚药丸 + 浅蓝选中」风格、全量改用 `BrandColors`，即可一次性消除不一致并降低后续维护成本。本报告仅作分析，**未改动任何代码**，待你确认方案后进入执行。

---

## 十、落地记录（2026-07-26，方案 B 已执行）

### 改动清单
1. **新增** `lib/widgets/app_filter_chips.dart`
   - `AppFilterChips`：统一横滚药丸筛选条组件。
   - `FilterChipItem({code, label})`：筛选项数据模型。
   - 规格按第六节：全圆药丸(999)、浅蓝底 `primarySurface`+1px 蓝边+蓝字选中、灰底 `surface` 未选中、13px、选中 `w500`、未选中 `textSecondary`、高 32、横向 padding 14、容器白、内边距 `fromLTRB(16,8,16,8)`、`InkWell`+`Ink` 水波纹。
2. **重写** `lib/pages/call_records/widgets/call_filter_bar.dart`
   - 删除自绘 `_chip`，选项列表改 `FilterChipItem`，`build` 直接返回 `AppFilterChips`。回调签名不变。
3. **重写** `lib/pages/customers/widgets/customer_filter_bar.dart`
   - 从「分段控件(Expanded 等宽)」改为「横滚药丸」，删除自绘逻辑，`build` 直接返回 `AppFilterChips`。回调签名不变。
4. **两页分隔线统一**
   - 通话记录页：搜索栏与筛选条之间**补** 1px `BrandColors.line` 分隔线（原无）。
   - 客户列表页：原硬编码 `#EEEEEE` 分隔线改为 `BrandColors.line`。
   - 两页新增 `theme/color_scheme.dart` 导入。
5. **修复文档漂移** `lib/theme/color_scheme.dart`
   - 新增 `BrandColors.line = #EEEEEE`（UI_STYLE_GUIDE §2.1 已记录但代码缺失）。

### 校验
- `flutter analyze`：**本次改动 6 个文件 0 issue**。
- 全仓仅余 `token_storage.dart` 11 个 `!` 误报 warning（今日早些时候 web 存储修复遗留，与本次无关）。
- 待真机热重启核对：两页筛选条均为横滚药丸、选中态浅蓝底+蓝边+蓝字、未选中灰底、点击有水波纹、搜索与筛选间均有 1px 分隔线。

### 一致性闭环
原报告的 8 项不一致（交互范式 / 选中视觉 / 未选中背景 / 形状 / 选中字重 / 硬编码色值 / 内边距 / 分隔线）+ 水波纹缺失，已全部收敛到 `AppFilterChips` 单点，后续新增列表页筛选直接用该组件即可避免回归。

---

## 十一、补充修复：默认占据 100% 宽度（2026-07-26）

### 问题
方案 B 落地后用户反馈：筛选栏在选项较少时未占据屏幕 100% 宽度，两侧露出页面灰色背景（留白），期望默认占满 100%。

### 根因
`AppFilterChips` 原实现为 `Container(color: white)` + `SingleChildScrollView + Row`：
1. 容器虽在 `Column(stretch)` 下理论上占满，但未显式强制宽度；一旦父级布局非 stretch 或被 `Align` 包裹就会收缩，露出底色。
2. 更关键：`SingleChildScrollView` 给子 `Row` 无界主轴宽度，`Row` 按内容左对齐排布，选项少时右侧大片空白——即用户感知的「未占满」。

### 修复（仅改 `lib/widgets/app_filter_chips.dart`）
- `Container` 显式加 `width: double.infinity`，强制白底占满屏幕 100% 宽，杜绝底色透出。
- 内部改用 `LayoutBuilder` 测可用宽度自适应：
  - 选项总宽（文字宽 + 横向 padding×2 + 间距×(n−1)）≤ 可用宽 → `Row(mainAxisAlignment: spaceBetween)` 沿行铺满，首尾贴边、两侧无留白；
  - 超出可用宽 → 退回 `SingleChildScrollView` 横向滚动（如通话记录 6 项在窄屏）。
- 文字宽度用 `TextPainter` 实测（按 w500 最大字重近似，偏保守防窄屏溢出），尊重 `textScaler`。

### 效果
- 客户列表（5 项，估算总宽 ≈ 316px）：小屏即可铺满整行，无两侧灰留白；
- 通话记录（6 项，估算总宽 ≈ 403px）：窄屏仍横滚，宽屏铺满；
- 两页自动适配，无需各页单独处理。

### 校验
`flutter analyze lib/widgets/app_filter_chips.dart` 等 **0 issue**。
