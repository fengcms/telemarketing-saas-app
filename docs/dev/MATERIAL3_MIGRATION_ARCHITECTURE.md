# TDesign → Material 3 UI 替换方案

> 作者：掌中灵（Mobile App Builder）
> 日期：2026-07-24
> 状态：待实施

---

## 1. 目标与策略

### 1.1 总体目标

用 Material 3 组件逐步替换 TDesign Flutter 组件，消除第三方组件库带来的兼容性风险，同时通过深度主题定制使应用保持自身品牌调性，而非「一眼 Material」。

### 1.2 核心策略：渐进替换

**不一次性全部推翻重写**，而是分批次、逐页面替换：

```
批次 1：主题搭建 + 测试页面 → 确定视觉基调
批次 2：零/低风险组件替换   → 消除编译兼容性隐患
批次 3：中等风险组件替换   → 减少对 TDesign 的依赖
批次 4：高风险/独家组件攻坚 → 手写替代，彻底脱离
```

这种策略的好处：
- 每个批次有明确定义的可交付物
- 允许中途回退单个页面，不影响全局
- 业务开发不阻塞，可与替换并行进行

---

## 2. 项目扫描：TDesign 组件使用全景

### 2.1 引用分布

共 **25 个文件** 引入了 `package:tdesign_flutter/tdesign_flutter.dart`：

| 模块 | 文件数 | 主要使用组件 |
|------|--------|------------|
| `leads/` | 14 | TDIcons, TDButton, TDTextarea, TDStepper, TDToast, TDNavBar |
| `schedules/` | 4 | TDButton, TDTextarea, TDPicker, TDToast |
| `force_change_password/` | 3 | TDIcons, TDButton, TDToast |
| `login/` | 1 | TDButton, TDToast, TDIcons |
| `home/` | 2 | TDIcons |
| `main_shell.dart` | 1 | TDIcons（底部导航栏图标） |
| `widgets/lead_card.dart` | 1 | TDIcons |

### 2.2 完整组件清单

#### 🔴 独占组件（TDesign 有，Material 无直接对应）

| 组件 | 使用次数 | 使用位置 | M3 替代方案 | 风险 |
|------|---------|---------|------------|:--:|
| `TDTextarea` | 3 次 | `schedule_form_fields.dart`, `follow_up_panel.dart`, `edit_follow_up_dialog.dart` | `TextField(maxLines: 2..10)` + 自定义边框 | 🟡 |
| `TDStepper` | 2 次 | `correct_call_dialog.dart`（分秒输入） | 自绘 `Row(IconButton+Text+IconButton)` | 🟡 |
| `TDPicker` | 2 次 | `schedule_form_fields.dart`（日期+时间选择） | Material `showDatePicker()` + `showTimePicker()` | 🟢 |
| `TDNavBar` + `TDNavBarItem` | 1 次 | `lead_detail_page.dart` | Material `AppBar` | 🟢 |

#### 🟡 半兼容组件（功能可替代，但有样式差异）

| 组件 | 使用次数 | 使用位置 | M3 替代方案 | 风险 |
|------|---------|---------|------------|:--:|
| `TDButton` | ~15 次 | 7 个文件 | `FilledButton` / `OutlinedButton` / `TextButton` | 🟢 |
| `TDToast` | ~20 次 | 10 个文件 | `SnackBar`（`ScaffoldMessenger.showSnackBar()`） | 🟢 |

#### 🟢 图标组件（直接映射）

| TDesign 图标 | 使用次数 | Material 等效图标 | 备注 |
|-------------|---------|------------------|------|
| `TDIcons.call` | 8 | `Icons.phone` | 已有直接对应的 Material 图标 |
| `TDIcons.home` | 3 | `Icons.home` | |
| `TDIcons.view_list` | 2 | `Icons.view_list` | |
| `TDIcons.user` | 3 | `Icons.person` | |
| `TDIcons.calendar` | 4 | `Icons.calendar_today` | |
| `TDIcons.search` | 1 | `Icons.search` | |
| `TDIcons.edit` | 3 | `Icons.edit` | |
| `TDIcons.close` | 2 | `Icons.close` | |
| `TDIcons.close_circle` | 1 | `Icons.cancel` | |
| `TDIcons.chevron_left` | 2 | `Icons.chevron_left` | |
| `TDIcons.chevron_down` | 1 | `Icons.keyboard_arrow_down` | |
| `TDIcons.rollback` | 3 | `Icons.replay` | 更接近「回转」语义 |
| `TDIcons.error_circle` | 3 | `Icons.error_outline` | |
| `TDIcons.info_circle` | 3 | `Icons.info_outline` | |
| `TDIcons.info_circle_filled` | 1 | `Icons.info` | |
| `TDIcons.lock_on` | 1 | `Icons.lock` | |
| `TDIcons.mail` | 1 | `Icons.email` | |
| `TDIcons.key` | 2 | `Icons.vpn_key` | |
| `TDIcons.filter` | 1 | `Icons.filter_list` | |
| `TDIcons.task` | 1 | `Icons.task_alt` | |
| `TDIcons.time` | 1 | `Icons.access_time` | |

---

## 3. 分批实施计划

### 批次 1：主题搭建 + 测试页面（第 0 步）

**目标**：建立 Material 3 完整主题配置，创建测试页面一次性验证所有组件样式。

#### 交付物 A：M3 主题层（新建文件）

```
lib/theme/
├── app_theme.dart          ← ThemeData 主入口
├── color_scheme.dart       ← 品牌色 → ColorScheme 映射
├── text_theme.dart         ← 字体族/字号自定义
└── component_tokens.dart   ← 各组件主题覆写
```

**核心配置思路**：

```dart
// color_scheme.dart
// 基于当前品牌色 #0052D9（深蓝）生成色板
// 目前全站硬编码色值：
//   - 主色: 0xFF0052D9
//   - 文字: 0xFF181818
//   - 次要: 0xFFA6A6A6
//   - 边框: 0xFFE7E7E7
//   - 背景: 0xFFF3F3F3
//   - 错误: 0xFFD54941

final brandColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF0052D9),
  brightness: Brightness.light,
  // 可以进一步微调：
  // - primary: 品牌色
  // - onPrimary: 白色文字
  // - surface: 0xFFF7F8FA
);
```

```dart
// component_tokens.dart
// 每个组件族的覆写，目标是「不 Material」
final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: brandColorScheme,

  // 按钮：直角 + 品牌色填充 + 14px 字号
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // 圆角 vs TDesign round
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),

  // 卡片：白色背景 + 无投影（或轻微投影）
  cardTheme: CardTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: const Color(0xFFE7E7E7)),
    ),
  ),

  // 输入框：灰底 + 圆角
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF3F3F3),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  ),

  // 导航栏：品牌色底 + 白色标题
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0052D9),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
);
```

#### 交付物 B：组件预览测试页

新建 `lib/pages/theme_preview_page.dart`，按以下分类自上而下展示所有 M3 组件：

```
┌──────────────────────────────────┐
│  AppBar（品牌色深蓝底）            │
├──────────────────────────────────┤
│  📝 按钮变体                      │
│  [Filled] [Outlined] [Text]      │
│  [带 loading]  [禁用]            │
├──────────────────────────────────┤
│  📝 输入组件                      │
│  [TextField 单行]                │
│  [TextField 多行/textarea]       │
│  [日期选择器]  [时间选择器]       │
├──────────────────────────────────┤
│  📝 选择组件                      │
│  [Checkbox] Label               │
│  [Radio] Label                  │
│  Stepper [-] 12 [+]             │
├──────────────────────────────────┤
│  📝 导航组件                      │
│  AppBar（带返回箭头 + 标题）      │
│  BottomNavigationBar（4 tab）    │
├──────────────────────────────────┤
│  📝 反馈组件                      │
│  [Snackbar 触发]                │
│  [Dialog 触发]                  │
│  [BottomSheet 触发]             │
├──────────────────────────────────┤
│  📝 容器组件                      │
│  Card（白色圆角 + 内容）           │
│  ListTile（带图标 + 文字 + 箭头） │
└──────────────────────────────────┘
```

> **调试方式**：在 MaterialApp 外部 `uid` 参数切换 `useMaterial3: true`，热重载即刷新所有组件。

---

### 批次 2：低风险替换 → 消除 TDesign 依赖（预计 1-2 天）

#### 2a. 图标替换（纯文本替换，零 UI 风险）

将 `TDIcons.xxx` 全部替换为 `Icons.xxx`（映射表见 §2.2）。
完成后可删除 `import 'package:tdesign_flutter/tdesign_flutter.dart'` 中的图标相关依赖。

**影响文件**：约 18 个文件，全部只是导入 + 使用图标，无其他 TDesign 组件逻辑。

**安全策略**：项目中已有多处混用 TDIcons 和 Material Icons（如 `password_rules_hint.dart:32` 用了 `Icons.shield_outlined`），说明图标替换是安全的。

#### 2b. TDToast → SnackBar 替换

| 原写法 | 替换写法 |
|--------|---------|
| `TDToast.showText('消息', context: context)` | `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('消息')))` |

**影响文件**：10 个文件，约 20 处调用。

**SnackBar 样式对齐**：
```dart
// 在 theme 中统一配置
snackBarTheme: SnackBarThemeData(
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  duration: Duration(seconds: 2),
),
```

#### 2c. TDButton → M3 FilledButton 替换

**常见模式映射**：

| TDesign 写法 | M3 替代 |
|-------------|---------|
| `TDButton(text: '登录', theme: TDButtonTheme.primary, shape: TDButtonShape.round)` | `FilledButton(child: Text('登录'), onPressed: ...)` |
| `TDButton(text: '取消', theme: TDButtonTheme.light)` | `OutlinedButton(child: Text('取消'), onPressed: ...)` |
| `TDButton(text: '链接', type: TDButtonType.text)` | `TextButton(child: Text('链接'), onPressed: ...)` |
| `TDButton(disabled: true, ...)` | `FilledButton(onPressed: null, ...)` |
| `TDButton(iconWidget: loadingWidget, text: '')` | `FilledButton(onPressed: ..., child: loadingWidget)` |

**影响文件**：7 个文件，约 15 处调用。

---

### 批次 3：中等风险替换（预计 1-2 天）

#### 3a. TDNavBar → AppBar

`lead_detail_page.dart` 中唯一一处使用。直接映射：

```dart
// 原写法
TDNavBar(
  title: '线索详情',
  backgroundColor: Colors.white,
  useDefaultBack: false,
  leftBarItems: [TDNavBarItem(icon: TDIcons.chevron_left, action: () => pop())],
)

// M3 替代
AppBar(
  title: const Text('线索详情'),
  backgroundColor: Colors.white,
  elevation: 0,
  leading: IconButton(
    icon: const Icon(Icons.chevron_left),
    onPressed: () => Navigator.of(context).pop(),
  ),
)
```

#### 3b. TDTextarea → TextField 多行

```dart
// 原写法
TDTextarea(
  controller: _ctrl,
  hintText: '补充说明...',
  minLines: 2,
  maxLength: 200,
  indicator: true,
  textareaDecoration: BoxDecoration(...),
)

// M3 替代
TextField(
  controller: _ctrl,
  decoration: InputDecoration(
    hintText: '补充说明...',
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  ),
  maxLines: 5,
  minLines: 2,
  maxLength: 200,
  buildCounter: (ctx, {currentLength, maxLength, isFocused}) =>
    Text('$currentLength/$maxLength', style: ...),
)
```

**影响文件**：3 个文件（`schedule_form_fields.dart`, `follow_up_panel.dart`, `edit_follow_up_dialog.dart`）

#### 3c. TDPicker → Material DatePicker/TimePicker

```dart
// 原写法
TDPicker.showDatePicker(context,
  format: DateFormat('yyyy-MM-dd'),
  onConfirm: (map) => onConfirm(map),
)

// M3 替代
final date = await showDatePicker(
  context: context,
  initialDate: DateTime.now(),
  firstDate: DateTime(2020),
  lastDate: DateTime(2030),
);
```

**影响文件**：1 个文件（`schedule_form_fields.dart`）

---

### 批次 4：TDStepper 自绘替代（风险最高，但影响最小）

`correct_call_dialog.dart` 中用 TDStepper 做了分钟/秒的分步输入。

**自绘方案**：

```dart
Widget _buildStepper({required int value, required int min, required int max, required ValueChanged<int> onChange}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: value > min ? () => onChange(value - 1) : null,
      ),
      SizedBox(
        width: 32,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: value < max ? () => onChange(value + 1) : null,
      ),
    ],
  );
}
```

---

## 4. 文件修改影响总表

| 文件 | 涉及组件 | 替换批次 | 风险 |
|------|---------|---------|:---:|
| `lib/pages/main_shell.dart` | TDIcons | 2a | 🟢 |
| `lib/pages/login/login_page.dart` | TDButton, TDToast, TDIcons | 2a+2b+2c | 🟢 |
| `lib/pages/home/home_page.dart` | TDIcons | 2a | 🟢 |
| `lib/pages/home/home_quick_entry_section.dart` | TDIcons | 2a | 🟢 |
| `lib/pages/leads/lead_detail_page.dart` | TDNavBar, TDButton, TDIcons | 2a+2c+3a | 🟡 |
| `lib/pages/leads/widgets/lead_header_section.dart` | TDIcons | 2a | 🟢 |
| `lib/pages/leads/widgets/lead_action_bar.dart` | TDIcons | 2a | 🟢 |
| `lib/pages/leads/widgets/call_records_section.dart` | TDIcons | 2a | 🟢 |
| `lib/pages/leads/widgets/leads_search_bar.dart` | TDIcons | 2a | 🟢 |
| `lib/pages/leads/widgets/leads_top_bar.dart` | TDIcons | 2a | 🟢 |
| `lib/pages/leads/widgets/follow_up_card.dart` | TDIcons | 2a | 🟢 |
| `lib/pages/leads/widgets/follow_up_timeline.dart` | TDButton, TDIcons | 2a+2c | 🟢 |
| `lib/pages/leads/widgets/edit_lead_dialog.dart` | TDButton, TDToast | 2b+2c | 🟢 |
| `lib/pages/leads/widgets/edit_follow_up_dialog.dart` | TDTextarea, TDToast | 2b+3b | 🟡 |
| `lib/pages/leads/widgets/delete_confirm_dialog.dart` | TDToast | 2b | 🟢 |
| `lib/pages/leads/widgets/correct_call_dialog.dart` | TDStepper, TDToast | 2b+4 | 🟡 |
| `lib/pages/leads/widgets/follow_up_panel.dart` | TDTextarea, TDButton, TDToast | 2b+2c+3b | 🟡 |
| `lib/pages/leads/widgets/dial_helper.dart` | TDToast | 2b | 🟢 |
| `lib/pages/schedules/widgets/schedule_form_sheet.dart` | TDToast | 2b | 🟢 |
| `lib/pages/schedules/widgets/schedule_form_fields.dart` | TDTextarea, TDButton, TDPicker | 2c+3b+3c | 🟡 |
| `lib/pages/schedules/widgets/schedule_detail_actions.dart` | TDButton | 2c | 🟢 |
| `lib/pages/schedules/schedule_detail_page.dart` | TDIcons, TDToast | 2a+2b | 🟢 |
| `lib/pages/force_change_password/password_nav_bar.dart` | TDIcons | 2a | 🟢 |
| `lib/pages/force_change_password/password_rules_hint.dart` | TDIcons | 2a | 🟢 |
| `lib/pages/force_change_password/force_change_password_page.dart` | TDButton, TDToast, TDIcons | 2a+2b+2c | 🟢 |
| `lib/widgets/lead_card.dart` | TDIcons | 2a | 🟢 |

---

## 5. 最终状态

全部替换完成后：

| 指标 | 目标 |
|------|------|
| TDesign 依赖 | 完全移除（删除 `pubspec.yaml` 中 `tdesign_flutter`） |
| 主题维护成本 | 一个 `lib/theme/` 目录，一套配置 |
| 组件兼容性 | 零外部依赖导致的编译问题 |
| 品牌感 | 深蓝色板 + 直角卡片 + 自定义字体，看不出是 Material |
| 页面数 | 全部页面用 M3 组件实现 |
| 迁移耗时估计 | 3-5 个工作日（含测试验证） |

---

## 6. 风险与应对

| 风险 | 概率 | 应对 |
|------|:---:|------|
| 部分组件样式差异导致 UI 走样 | 中 | 批次 1 的测试页面就是给这个准备的——提前调好，后面只管替换 |
| 替换过程中影响业务开发 | 低 | 逐页替换 + 可逆，每个页面替换完才进入下一页面 |
| TDesign 特有功能（如 TDPicker 的某些参数）丢失 | 低 | 已分析所有使用处，均在 M3 能力范围内 |
| 主题配置工作量大 | 中 | 但**一次性**——配置完成后再无额外主题维护成本 |

---

## 7. 后续步骤建议

1. **确认本方案** → 评估是否接受分批计划与时间预估
2. **开始批次 1** → 搭建 `lib/theme/` 主题目录 + 创建 `theme_preview_page.dart`
3. **迭代调试** → 在测试页面上反复调主题参数，直到所有组件样式满意
4. **批次 2-4** → 按逐页原则逐个文件替换
5. **收尾** → 删除 TDesign 依赖，清理多余 import
