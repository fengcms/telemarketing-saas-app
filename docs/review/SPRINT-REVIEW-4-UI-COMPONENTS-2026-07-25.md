# 电销工作台 APP — UI 组件质量审计

> 审阅分支：`feat/m3-theme-migration-preview`
> 基线版本：`08e876d`（master HEAD）
> 审查目的：对组件质量把关——**质量过关才能进入替换流程，不过关不替换**。
> 审查人：Mobile App Builder（移动端小组组长）
> 审查日期：2026-07-25

## 一、审查范围与客观门禁

### 本次变动概览
| 维度 | 数量 |
|------|:----:|
| 涉及 Dart 文件 | 40 |
| 新增/修改行（净） | 5,363 新增 / 121 删除 |
| 公共组件（`lib/widgets/` 新增） | 5 个（AppSearchBar / AppFormSection / AppActionBar / AppDialog / AppBottomSheet） |
| 主题系统（`lib/theme/` 新增） | 4 个文件（`color_scheme.dart` / `text_theme.dart` / `component_tokens.dart` / `app_theme.dart`） |
| 新建业务页面 | 通话记录 / 客户列表 / 个人中心 / 日程搜索 4 页 + 对应的 widget 文件 |
| 主题预览页 | `lib/pages/theme_preview_page.dart`（899 行） |

### 客观门禁
| 手段 | 结果 |
|------|------|
| `flutter analyze` | **No issues found!（exit 0，0 issue）** ✅ 连续六轮守住 |
| 全库非预览文件 ≤ 560 行 | ✅ 仅 `login_page.dart` 612（已知观察项），**无新增超限文件** |
| 组件文件行数 | 5 个组件均 ≤ 253 行，体量可控 ✅ |
| 文件头 `///` 文档注释 | 全部新文件合规 ✅ |
| 主题是否接入 `app.dart` | ✅ `lib/app.dart:47` 使用 `theme: buildBrandTheme()` |
| 颜色是否通过 `BrandColors` 引用 | ⚠️ 见下文（AppBottomSheet 未通过） |

---

## 二、逐组件质量评估

> 每个组件从 **API 设计、生命周期管理、主题一致性、边界情况** 四个维度评分。

### 2.1 AppSearchBar — 统一搜索栏（247 行）
**`lib/widgets/app_search_bar.dart`**

| 维度 | 评分 | 评语 |
|------|:----:|------|
| API 设计 | **A** | 4 个参数：`controller`/`onSearch`/`hintText` 必须、`keyboardType`/`searchButtonText` 可选；职责单一 |
| 生命周期 | **A** | `initState` 注册 listener → `didUpdateWidget` 处理 controller 替换 → `dispose` 解绑；`FocusNode` 同生命周期管理 ✅ |
| 主题一致性 | **A** | 全部颜色通过 `BrandColors` 引用（`surface`/`textSecondary`/`textPrimary`/`primary`），无硬编码 |
| 边界情况 | **A** | `GestureDetector` 包裹整块灰底区实现点击任意位置聚焦；清空按钮仅在有文字时渲染；清空时触发 `onSearch('')`（区别于只清空不搜索）✅ |

**结论**：✅ 通过。组件质量优秀，可直接进入替换流程。

### 2.2 AppFormSection — 表单区块（105 行）
**`lib/widgets/app_form_section.dart`**

| 维度 | 评分 | 评语 |
|------|:----:|------|
| API 设计 | **A** | 4 参数：`label`/`child` 必须、`required`/`spacing` 可选；`StatelessWidget` 无状态开销 |
| 生命周期 | **A** | `StatelessWidget`，无生命期问题 |
| 主题一致性 | **A** | 全部通过 `BrandColors` 引用（`textPrimary`/`error`） |
| 边界情况 | **A** | 必填 `*` 标志用 `Row` 紧贴标签尾部；间距通过 `SizedBox(height: spacing)` 参数化 |

**结论**：✅ 通过。简单且正确，可直接进入替换流程。

### 2.3 AppActionBar — 底部操作栏（253 行）
**`lib/widgets/app_action_bar.dart`**

| 维度 | 评分 | 评语 |
|------|:----:|------|
| API 设计 | **A+** | **命名构造器 `submit` vs 无名构造器 `bar`** 区分两种模式；`ActionItem` 数据模型 + `ActionType` 枚举（primary/light/text）覆盖全场景；哨兵构造器初始化保证类型安全（`actions = null` vs `text = null`）⚠️ 此模式可作为 Flutter 组件 API 范本 |
| 生命周期 | **A** | `StatelessWidget`，无生命期问题 |
| 主题一致性 | **B+** | 大部分颜色引用 `BrandColors`，但 **text 类型禁用态颜色硬编码**（行 234/243 `const Color(0xFFDCDCDC)`）→ 应改为 `BrandColors.textDisabled`。值虽相同，但语义应通过常量引用。 |
| 边界情况 | **A** | `onTap == null` → 禁用；`loading` 态支持（仅 primary 类型显示 `CircularProgressIndicator`）；loading 时 `onPressed` 为 null 防止重复提交 |

**问题（待修）**：
1. ⚠️ text 类型禁用色硬编码（行 234/243）：`0xFFDCDCDC` → 改 `BrandColors.textDisabled`（值相同，但语义引用常量）。修复耗时约 2 分钟。

**结论**：✅ 通过（修复上述硬编码后）。API 设计是本轮最佳实践，哨兵构造器初始化值得作为 Flutter 组件 API 范本推广。

### 2.4 AppDialog — 统一弹窗（111 行）
**`lib/widgets/app_dialog.dart`**

| 维度 | 评分 | 评语 |
|------|:----:|------|
| API 设计 | **A+** | **`abstract final class` + 静态方法** 完美封装 `showDialog + AlertDialog` 样板；`confirm`/`alert` 语义区分清晰；`confirmColor` 支持红色危险操作 |
| 生命周期 | **A** | 静态方法无内部状态；`onConfirm` 在 `Navigator.pop(true)` 后执行（比 pop 前执行安全），调用方需确保 context 在回调中仍可用 |
| 主题一致性 | **A** | 无自定义颜色，样式继承自 `DialogTheme`（`component_tokens.dart` 已配置）✅ |
| 边界情况 | **A** | `barrierDismissible: true` 允许点遮罩关闭；`confirmColor` 通过 `FilledButton.styleFrom(backgroundColor)` 覆写；返回 `bool?` 符合 `showDialog` 惯例 |

**结论**：✅ 通过。组件质量顶尖，可比《Flutter in Production》推荐模式。可直接进入替换流程。

### 2.5 AppBottomSheet — 统一底部抽屉（163 行）
**`lib/widgets/app_bottom_sheet.dart`**

| 维度 | 评分 | 评语 |
|------|:----:|------|
| API 设计 | **A** | `AppBottomSheet.show<T>()` 泛型方法，`title`/`child` 双必须参数，简洁 |
| 生命周期 | **A** | `_AppBottomSheetContent` 内部通过 `MediaQuery.of(context).viewInsets.bottom` 动态获取键盘高度；
`Flexible → SingleChildScrollView` 确保键盘弹出时不溢出 |
| 主题一致性 | **C** | **全部颜色硬编码**（行 96 `Colors.white`、行 114 `0xFFDCDCDC`、行 125 `0xFF181818`、行 136 `0xFFA6A6A6`、行 97-98 圆角 `Radius.circular(12)` 未用 `TdRadius.sheet`）。作为"M3 主题迁移"的一部分，此组件完全不应跟随主题变化。 |
| 边界情况 | **B+** | 标题 `Row([手柄, Spacer, 标题, Spacer, 关闭])` 在宽屏偏右（手柄 32px ≠ 关闭按钮 ~28px），手机无影响。拖拽手柄 32×4 硬编码未抽常量。 |

**问题（必须修复后方可进入替换流程）**：
1. 🔴 4 处颜色全部硬编码 → 应改为 `BrandColors.surfaceContainer` / `BrandColors.textSecondary` / `BrandColors.textPrimary` 等
2. 🟡 圆角 `12` → 改 `TdRadius.sheet`
3. 🟡 拖拽手柄尺寸 → 抽为 `_kDragHandleSize` 等命名常量

**结论**：🟡 **条件通过** — 修复颜色硬编码后方可进入替换。此组件是当前唯一在"主题一致性"维度有硬伤的文件。

---

## 三、主题系统评估

### 3.1 `color_scheme.dart` — 品牌色 + ColorScheme（104 行）
- `BrandColors` 常量类完整（主色 #0052D9 / 灰阶 gray-0~12 / 语义色）
- `brandColorScheme` 常量覆盖所有 M3 必要色槽
- 颜色来源标注清晰（TD brand-N / gray-N / error-N）

**🟡 观察**：`surfaceContainer` 命名与 M3 约定相反（M3 中 `surface` 为主背景、`surfaceContainer` 为容器背景；此处 `surface = #F3F3F3` 灰、`surfaceContainer = #FFFFFF` 白）。这不是 bug（因为是自定义常量名），但易混淆。建议加注释注明"本项目约定：surface=灰底、surfaceContainer=白底"。

### 3.2 `text_theme.dart` — 文字主题（101 行）
- `BrandTextStyle` 字号/字重常量，映射表清晰 ✅
- `brandTextTheme` 覆盖了项目中实际用到的 10 个样式，未覆盖的保持 M3 默认 ✅

### 3.3 `component_tokens.dart` — 组件主题覆写（291 行）
- `ThemeData.copyWith()` 的 `mergeInto` 模式干净（集中一处合并所有组件覆写）✅
- 覆盖 14 个组件主题，注释标明对应 TDesign 组件名 ✅
- 圆角集中定义为 `TdRadius` 常量 ✅
- `CheckboxThemeData` 的 `WidgetStateProperty.resolveWith` 正确处理选中态 ✅
- `AppBarTheme`/`BottomNavigationBarThemeData` 等全局配置完整 ✅

**🟡 观察**：
- `TdRadius.button = 100` 产生药丸形。TDesign 默认按钮圆角是 `6px`，药丸是 `TDButtonShape.round`。**确认一下这是有意的品牌特征，还是笔误？**

### 3.4 `app_theme.dart` — 主题入口（43 行）
- `useMaterial3: true` ✅
- `splashColor/highlightColor: Colors.transparent` 去除水波纹（TDesign 特色）✅
- `VisualDensity.compact` ✅
- `componentTokens.mergeInto(theme)` 模式清晰 ✅

---

## 四、预览页评估

**`theme_preview_page.dart`（899 行）**

**优点**：展示覆盖 11 个分类（按钮/输入/选择/导航/反馈/容器/搜索栏/表单/操作栏/弹窗/底部抽屉）；实际使用项目中新组件（AppSearchBar / AppFormSection / AppActionBar / AppDialog / AppBottomSheet）；包含组合练习场景（底部抽屉嵌套 AppFormSection + AppActionBar.submit）；`dispose()` 清除 3 个 Controller ✅

**问题**：
1. 🟡 898 行偏大。`_ButtonShowcase`/`_InputShowcase`/`_SelectionShowcase` 三个私有 widget 可抽为独立文件，各约 100-150 行。不过预览页定位特殊，行数红线可以适度放宽。建议抽但非必须。
2. 🟡 `_buildFeedbackShowcase()` 使用原生 `showDialog` + `showModalBottomSheet` 而非项目新组件 `AppDialog`/`AppBottomSheet`——预览页应尽可能使用自身组件，否则无法展示弹窗/抽屉的真实效果。

---

## 五、组件质量总结

| 组件 | 质量判定 | 放行条件 |
|------|:--------:|----------|
| AppSearchBar | **✅ 通过** | 无 |
| AppFormSection | **✅ 通过** | 无 |
| AppActionBar | **✅ 条件通过** | 修复 text 禁用态色值硬编码（`0xFFDCDCDC` → `BrandColors.textDisabled`） |
| AppDialog | **✅ 通过** | 无 |
| AppBottomSheet | **🟡 暂不通过** | **必须修复**：7 处颜色硬编码 → 改 `BrandColors.*`；圆角 `12` → `TdRadius.sheet` |

**核心缺陷（仅一处必须修复）**：
- `AppBottomSheet` 颜色全部硬编码，违背"M3 主题迁移"的基本前提。修复后方可进入替换。
- `app_action_bar` text 禁用色硬编码（2 行），建议顺手修复。

> 其余 3 个组件（AppSearchBar / AppFormSection / AppDialog）质量过硬，可直接进入替换流程。

---

## 六、建议的替换优先级（仅供后续参考）

以下基于 COMPONENT_GUIDE.md 和实际替换价值，在质量通过后建议按此顺序推进替换：

| 优先级 | 组件 | 价值（消除重复行数） | 影响点数 | 替换难度 |
|:------:|------|:-------------------:|:--------:|:--------:|
| P0 | `AppDialog` | 8 处 `showDialog+AlertDialog` 样板 | 8 | 🟢 简单 |
| P0 | `AppSearchBar` | 432 行（3 个旧搜索栏） | 3 | 🟢 简单 |
| P1 | `AppActionBar.submit` | 4 处 `_buildSubmitButton` | 4 | 🟢 简单 |
| P2 | `AppFormSection` | 3 处手动拼装 | 3 | 🟢 简单 |
| P2 | `AppActionBar`（多按钮） | 2 处（LeadActionBar + schedule_detail_actions） | 2 | 🟡 中等 |
| P2 | `AppBottomSheet` | 2 处 `showModalBottomSheet` | 2 | 🟡 中等 |

---

## 七、综合评级

| 维度 | 评级 | 评语 |
|------|:----:|------|
| 组件 API 设计 | **A** | `ActionItem` 数据模型 + 命名构造器 + 哨兵初始化，教科书级；`AppDialog` 的 `abstract final class` 模式可比《Flutter in Production》 |
| 主题系统完整性 | **A−** | 颜色/字体/组件三层完整、`mergeInto` 模式干净；唯 `AppBottomSheet` 颜色硬编码拖分 |
| 文档 | **A** | `COMPONENT_GUIDE.md` 含参数表 + 示例 + 替换关系表；各组件 `///` Dart Doc 详尽 |
| 预览页 | **B+** | 展示分类全面，但 898 行偏大、反馈展示未用自身新组件 |
| `flutter analyze` | **✅** | 六轮守住 0 issue |

**综合评级：A−（条件通过）**

> 主题架构方向正确、组件 API 设计水平高、文档充分。**仅需修复 `AppBottomSheet` 颜色硬编码 + `app_action_bar` 禁用色常量引用**，即可全部进入替换流程。建议修复后给「可以替换」放行。

---

## 八、开放项

| 优先级 | 事项 | 状态 |
|--------|------|:----:|
| 🔴 **必须修** | `AppBottomSheet` 7 处颜色硬编码 → 改 `BrandColors.*`；圆角 → `TdRadius.sheet` | ❌ 待修 |
| 🟡 建议修 | `app_action_bar` text 禁用色 `0xFFDCDCDC` → `BrandColors.textDisabled` | ❌ 待修 |
| 🟡 建议 | `preview_page.dart` 898 行偏大，`_*Showcase` 可抽独立文件 | ✅ 非阻塞 |
| 🟡 建议 | `preview_page` 反馈展示改用 `AppDialog`/`AppBottomSheet` | ✅ 非阻塞 |
| 🟡 观察 | `TdRadius.button = 100` → 确认设计意图（药丸形 vs TDesign 默认 6px） | ⚪ 待确认 |
| 🟡 观察 | `surfaceContainer` 命名倒置 → 建议加注释说明 | ⚪ 建议 |
| 🟢 观察 | `login_page.dart` 612 行（已知，非组件域） | ⚪ 观察 |

— Mobile App Builder（移动端小组组长），2026-07-25
