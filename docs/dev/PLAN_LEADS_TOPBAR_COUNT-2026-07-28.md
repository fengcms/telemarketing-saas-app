# 计划文档：线索列表页经理/管理员视角—统计条移入标题栏左上角

> 日期：2026-07-28
> 状态：**已确认并开发完成（待真机验证）**
> 范围：**仅**经理（`tenant_manager`）/管理员（`tenant_admin`）视角的线索列表页顶栏；员工视角完全不动

## 一、现状分析

`lib/pages/leads/leads_list_page.dart` 的 `build()` 在 `LeadsTopBar` 之下、搜索栏之上插入了一行统计条：

- 触发条件：`if (isManager && !isPublic)`（`isManager` = tenant_admin / tenant_manager；`isPublic` = 当前在公海 Tab）。
- 渲染内容：`_buildSummaryBar(state.total)` —— 一条 40px、`surface` 灰底、灰色文字（`0xFF4E5969`）左对齐的「共 X 条」。
- 为何只经理/管理员有：公海 Tab 仅员工（`tenant_employee`）+ `allowSelfClaim` 才显示，经理/管理员**永远不会进入公海 Tab**，故 `!isPublic` 对经理恒为真 → 他们始终多这一行；员工不渲染。
- 经理/管理员的 `LeadsTopBar` 走 `showPublicTab=false` 分支 → **居中「线索」**标题 + 右侧筛选/排序（56px 蓝色顶栏）。

数据来源：`state.total` 来自 `lead_list_provider` 的接口返回总数（随筛选/搜索/刷新/分页更新），格式化走 `_formatNum`（万/千分位）。本次**只搬位置，不改数据语义**。

## 二、目标

把「共 X 条」从独立一行搬进标题栏**左上角**，省掉那 40px 行；员工视角维持原样。

## 三、设计方案（★已确认）

### 3.1 顶栏形态变化（最终确认：左计数 / 中标题 / 右图标）
经理/管理员视角：保留标题**居中**「线索」，但在顶栏**最左侧**显示「共 X 条」统计，**右侧**保持筛选/排序两个图标。三者排布于同一行，文字短、互不重叠。

- 顶栏内 `Row`：`[ 共 X 条(左, padding 16) ]` + `Spacer` + `[ 筛选图标 ]` + `[ 排序图标 ]`；
- 「线索」用居中 `Stack` 叠在 `Row` 之上，确保标题真正居中（与员工视角视觉一致）。
- **员工视角维持居中「线索」+ 右侧筛选/排序不变**，符合「与员工标题栏无关」的要求。

> 说明：最初方案曾提议「线索」改为左对齐以避免重叠风险；用户确认「文字很短，完全可以排布，不必担心重叠」，故采用居中标题 + 左侧计数的布局。

### 3.2 文字样式
- 标题「线索」：`white / 18 / w500`（保持现状，居中）。
- 「共 X 条」：`Color(0xB3FFFFFF)`（white70）整段、`13`，置于顶栏最左侧（padding 16）。
- 颜色从「灰底灰字」改为「蓝底白字」，以保证蓝色顶栏上的对比度可读。

### 3.3 加载态
沿用现状：`state.total` 初始为 0，首屏加载时会短暂显示「共 0 条」（与当前摘要条行为一致）。
如需「首屏加载完成前不显示计数」，可在 `state.isInitialLoading` 时省略——默认不隐藏（保持行为一致），可后续按需调整。

## 四、改动文件

1. `lib/pages/leads/widgets/leads_top_bar.dart`
   - 新增参数 `bool isManager`（默认 false）、`int total`（默认 0）。
   - 在 `!showPublicTab` 分支内：统一用 `Stack(alignment: center)` 居中「线索」，`Row` 内按 `isManager` 条件在左侧插入「共 X 条」。
     - `isManager == true`：`Row[ 共 X 条(左) + Spacer + 筛选 + 排序 ]`。
     - `isManager == false`（员工）：`Row[ Spacer + 筛选 + 排序 ]`（无左侧计数）。
   - 内联 `_formatNum(int)`（从页内 `_formatNum` 迁移，避免跨文件依赖）。
2. `lib/pages/leads/leads_list_page.dart`
   - `LeadsTopBar(...)` 调用处新增 `isManager: isManager, total: state.total`。
   - 删除 `if (isManager && !isPublic) _buildSummaryBar(state.total),` 整行。
   - 删除 `_buildSummaryBar` 方法与 `_formatNum` 方法（逻辑已迁入顶栏）。
   - 搜索栏因上方少一行自动上移，无需其它调整。

## 五、验证

- `flutter analyze lib/pages/leads/`
- 真机：
  - 经理/管理员 → 顶栏左侧「共 X 条」、居中「线索」、右侧筛选/排序、下方**无**独立统计行、搜索栏紧贴顶栏；
  - 员工 → 居中「线索」、无统计、无独立行；
  - 计数随筛选/搜索实时变化，与现状数字一致。

## 六、风险 / 注意

- 仅改布局与样式，不动数据层（`state.total` 语义不变，数字与现在完全一致）。
- 不影响公海 Tab（员工视角），不影响首页/日程等其它页面。
- 标题「居中 → 左对齐」仅作用于经理/管理员；员工保持原样。
- 不涉及其它未提交改动（线索/客户编辑、日程负责人修复等），本计划独立成提交。
