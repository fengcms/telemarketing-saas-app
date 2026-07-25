# TDesign → Material 3 全量替换报告

> 日期：2026-07-25
> 分支：`feat/m3-theme-migration-preview`
> 范围：全项目 44 个 Dart 文件，零 TDesign 残留

---

## 一、替换总览

| 组件 | 替换方案 | 替换数 | 涉及文件 |
|:----:|----------|:------:|:--------:|
| `TDIcons` | → `Icons.*`（19 个映射） | 35 处 | 15 个 |
| `TDToast` | → `AppToast.show`（封装 SnackBar） | 26 处 | 10 个 |
| `TDButton` | → `FilledButton` / `TextButton` | 5 处 | 3 个 |
| `TDTextarea` | → `AppTextarea`（内置计数器 + 快捷备注） | 2 处 | 2 个 |
| `TDPicker` | → Material `showDatePicker` / `showTimePicker` | 2 处 | 1 个 |
| `TDStepper` | → 自绘 `_buildStepper` ± 按钮 | 2 处 | 1 个 |
| `TDNavBar` | → 原生 `AppBar` | 1 处 | 1 个 |
| `TDCheckbox` | → Material `Checkbox`（前期已替换） | — | — |

**删除组件**：`SheetHeader`（被 `AppBottomSheet` 替代）

---

## 二、新增公共组件

| 组件 | 文件 | 用途 |
|------|------|------|
| `AppSearchBar` | `lib/widgets/app_search_bar.dart` | 统一搜索栏（聚焦边框 + 清空回调） |
| `AppFormSection` | `lib/widgets/app_form_section.dart` | 表单标签区块（必填红 *，8px 间距） |
| `AppActionBar` | `lib/widgets/app_action_bar.dart` | 底部操作栏（submit/多按钮双模式） |
| `AppDialog` | `lib/widgets/app_dialog.dart` | 确认/提示弹窗（静态方法，无 builder 样板） |
| `AppBottomSheet` | `lib/widgets/app_bottom_sheet.dart` | 统一底部抽屉（拖拽手柄 + 关闭 + 键盘适配） |
| `AppTextarea` | `lib/widgets/app_textarea.dart` | 多行文本域（内置字计数 + 快捷备注 TagChip） |
| `AppToast` | `lib/widgets/app_toast.dart` | 统一提示（封装 SnackBar，主题控制样式） |

---

## 三、主题架构

`lib/theme/` 目录：

| 文件 | 职责 |
|------|------|
| `color_scheme.dart` | 品牌色 `#0052D9` → M3 ColorScheme + BrandColors 常量 |
| `text_theme.dart` | 自定义字号/字重映射 |
| `component_tokens.dart` | 按钮大圆角/输入框白底灰边框/SnackBar/卡片等 token |
| `app_theme.dart` | 三部合一 `buildBrandTheme()` 入口函数 |

---

## 四、关键设计决策

### 4.1 按钮风格
- 主按钮：`FilledButton` → 大圆角药丸形（`radius: 100`）
- 次要按钮：`FilledButton.tonal` → 浅蓝底 `#F2F3FF` + 蓝字 `#0052D9`
- 文字按钮：`TextButton` → 透明底蓝字

### 4.2 输入框风格
- 白底 `#FFFFFF` + 灰边框 `#E7E7E7` + 6px 圆角
- 聚焦时：品牌色边框 `#0052D9`（1.5px）

### 4.3 计数器位置
- 不再用 `buildCounter`（边框外）
- 改用 `Stack` + `Positioned` 浮在边框内右下角
- 超限后不可输入（`LengthLimitingTextInputFormatter`）

### 4.4 快捷备注
- `AppTextarea` 可选 `quickNotes` 参数
- 自动显示多行换行 TagChipRow
- 点击后空格追加到文本框末尾
- 跟进面板仅展示 `type == 'followup'` 的数据

### 4.5 快捷备注 type 字段
- `OptionItem` 新增 `type` 字段，`fromJson` 解析
- 本地缓存序列化新增 `type` 保留
- 跟进面板加载后按 `type == 'followup'` 过滤

---

## 五、删除的废弃文件

| 文件 | 替代 |
|------|------|
| `lib/widgets/sheet_header.dart` | `AppBottomSheet` 内置标题栏 |
| `lib/pages/leads/widgets/leads_search_bar.dart` | `AppSearchBar` |
| `lib/pages/call_records/widgets/call_search_bar.dart` | `AppSearchBar` |
| `lib/pages/customers/widgets/customer_search_bar.dart` | `AppSearchBar` |
| `lib/pages/leads/widgets/lead_action_bar.dart` | `AppActionBar` |

---

## 六、质量门禁

- `flutter analyze`：**No issues found**（零警告/零错误）
- 构建验证：Release APK 编译通过（56.6MB）
- 审计记录：
  - `docs/review/SPRINT-REVIEW-4-UI-COMPONENTS-2026-07-25.md` — 组长首次审计
  - `docs/review/SPRINT-REVIEW-4-RESPONSE-2026-07-25.md` — 修复回复
  - `docs/review/SIGN-OFF-UI-COMPONENTS-2026-07-25.md` — 放行确认

---

## 七、后续计划

| 优先级 | 事项 | 说明 |
|:------:|------|------|
| 🟡 | 从 `pubspec.yaml` 移除 `tdesign_flutter` 依赖 | 无代码残留后删除 |
| 🟢 | 将分支合并到 `master` | 等组长审阅通过后合并 |

---

**报告人**：Mobile App Builder AI 助手
**提交 ID**：`e36ac09`（主题层）→ `ae42234`（图标）→ `6b12386`（Toast）→ 本次（剩余组件）
