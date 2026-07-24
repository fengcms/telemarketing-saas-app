# 电销工作台 APP — UI/UX 风格指南

> 本文档记录项目中已落地并验证的**视觉与交互模式**，供后续页面开发时参考。
> 新页面应遵循本指南中的风格约定，确保全应用视觉一致。
> 版本：v1.0（2026-07-24）

---

## 目录

1. [色板](#1-色板)
2. [页面布局](#2-页面布局)
3. [详情页卡片风格](#3-详情页卡片风格)
4. [底部抽屉（BottomSheet）](#4-底部抽屉bottomsheet)
5. [表单输入控件](#5-表单输入控件)
6. [标签选择器（TagChip）](#6-标签选择器tagchip)
7. [骨架屏（Skeleton）](#7-骨架屏skeleton)
8. [按钮](#8-按钮)
9. [顶栏（TopBar）](#9-顶栏topbar)
10. [列表样式](#10-列表样式)

---

## 1. 色板

### 1.1 品牌色

| 用途 | 色值 | 示例 |
|------|------|------|
| 品牌色 / 主色 | `#0052D9` | 顶栏、主按钮、选中态 |
| 选中态浅底 | `#F2F3FF` | TagChip 选中背景（旧 ChoiceChip） |
| 错误 / 危险 | `#D54941` | 删除操作、逾期标签 |
| 成功 | `#00A870` | 已完成态（待定） |

### 1.2 中性色

| 用途 | 色值 | 示例 |
|------|------|------|
| 页面背景 | `#F3F3F3` | 所有列表/详情页灰底 |
| 卡片背景 | `#FFFFFF` | 详情页白卡片、白色抽屉 |
| 主文字 | `#181818` | 标题、正文 |
| 副文字 | `#A6A6A6` | 标签标题、提示文字、占位符 |
| 输入框边框 | `#E7E7E7` | 输入框、分隔线 |
| 不可用 / 极浅 | `#DCDCDC` | 禁用文字、占位图标 |
| 分割线 | `#EEEEEE` | Divider |

### 1.3 骨架屏

| 用途 | 色值 | 说明 |
|------|------|------|
| 扫光底色 | `#E7E7E7` | shimmer 渐变起点/终点 |
| 扫光高亮 | `#F4F4F4` | shimmer 渐变中间（高亮带） |

---

## 2. 页面布局

### 2.1 页面背景

所有列表页 / 详情页的背景统一为灰色 `#F3F3F3`。

```dart
Scaffold(
  backgroundColor: const Color(0xFFF3F3F3),
)
```

### 2.2 区块间距

区块之间用 8px（紧凑）或 16px（宽松）的 `SizedBox` 分隔：

```dart
const SizedBox(height: 8)   // 卡片间
const SizedBox(height: 16)  // 章节间
```

### 2.3 标准化边距

| 场景 | 边距值 |
|------|--------|
| 列表页左右 | 16px |
| 详情页卡片左右 | 16px |
| 底部抽屉左右 | 24px |
| 底部抽屉底部 | 32px |
| 卡片 padding | 16px |

---

## 3. 详情页卡片风格

### 3.1 白卡片容器

详情页的每个区块用**白底卡片**浮在灰底上，圆角 12px：

```dart
/// 通用卡片容器（白底 + 圆角 + 可选点击）
Widget _card({required Widget child, VoidCallback? onTap}) {
  final inner = Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );
  if (onTap == null) return inner;
  return GestureDetector(onTap: onTap, child: inner);
}
```

**参考页面**：`lead_detail_page.dart`（线索详情）、`schedule_detail_page.dart`（日程详情）的 `_card()` 方法。

### 3.2 区块标题

每张白卡片的标题位于左上角，灰色小字 12px：

```dart
const Text(
  '区块标题',
  style: TextStyle(fontSize: 12, color: Color(0xFFA6A6A6)),
),
const SizedBox(height: 8),
// 内容区域...
```

### 3.3 点击卡片跳转

当卡片可点击跳转时，用 `_card(onTap: …)` 包裹：

```dart
_card(
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => TargetPage(id: x)),
  ),
  child: Column(…),
)
```

---

## 4. 底部抽屉（BottomSheet）

### 4.1 基础结构

底部抽屉用于创建 / 编辑表单，参考 `edit_lead_dialog.dart` 和 `follow_up_panel.dart`：

```dart
void showMySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,  // 透明，让内层容器处理白底圆角
    builder: (_) => _MySheetContent(),
  );
}
```

内层容器（在 `_MySheetContent` 的 `build()` 中）：

```dart
final bottom = MediaQuery.of(context).viewInsets.bottom;

return Container(
  padding: EdgeInsets.only(bottom: bottom),  // 键盘抬起不挡内容
  decoration: const BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  child: SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,  // 高度自适应
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(title: '弹窗标题'),
          const SizedBox(height: 20),
          // ...表单内容...
          const SizedBox(height: 24),
          _buildSubmitButton(),  // 全宽按钮
        ],
      ),
    ),
  ),
);
```

### 4.2 SheetHeader

顶部标题行使用统一的 `SheetHeader` 组件（`lib/widgets/sheet_header.dart`）：

```
┌─────────────────────────────┐
│  ━━      标题         ✕    │
└─────────────────────────────┘
```

- 手柄条（32×4px，`#DCDCDC`）居左
- 标题居中，16px，`FontWeight.w500`，`#181818`
- 关闭图标在右侧，18px，`#A6A6A6`，点击 `Navigator.pop()`
- 如果关闭前需要**脏检查确认弹窗**，需内联自定义标题行，关闭接脏检查方法

### 4.3 表单区块

抽屉内表单每区块直接 `Padding`（无卡片背景/圆角）：

```dart
Padding(
  padding: const EdgeInsets.only(bottom: 16),  // 块间距
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle('字段名'),
      const SizedBox(height: 8),
      // 控件...
    ],
  ),
)
```

区块标题辅助方法：

```dart
Text(
  text,
  style: const TextStyle(fontSize: 12, color: Color(0xFFA6A6A6)),
)
```

### 4.4 全宽提交按钮

底部按钮为通栏 `SizedBox(width: double.infinity)`，参考 `follow_up_panel.dart`：

```dart
Widget _buildSubmitButton() {
  return SizedBox(
    width: double.infinity,
    height: 48,
    child: TDButton(
      text: _isSubmitting ? '' : '提交',
      theme: TDButtonTheme.primary,
      shape: TDButtonShape.round,
      disabled: _isSubmitting || !_isValid,
      onTap: _submit,
      iconWidget: _isSubmitting
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : null,
    ),
  );
}
```

---

## 5. 表单输入控件

### 5.1 单行输入框

参照登录页输入框风格：白底 + 灰边框 + 圆角，TextField 内无边框：

```dart
Container(
  height: 44,  // 常规 56，紧凑 44
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: const Color(0xFFE7E7E7), width: 1),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [
      Expanded(
        child: TextField(
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      // 可选：右侧图标
    ],
  ),
)
```

高度规格：
- **标准**：56px（登录页、列表页搜索）
- **紧凑**：44px（底部抽屉内日期/时间选择器）

### 5.2 多行文本域（备注 / 内容）

使用 TDesign 的 `TDTextarea`，参照 `follow_up_panel.dart` 的跟进内容输入：

```dart
TDTextarea(
  controller: _controller,
  hintText: '补充说明...',
  minLines: 2,
  maxLength: 200,
  showBottomDivider: false,
  indicator: true,
  margin: EdgeInsets.zero,
  padding: EdgeInsets.zero,
  inputDecoration: const InputDecoration(
    contentPadding: EdgeInsets.fromLTRB(12, 10, 12, 10),
    border: InputBorder.none,
  ),
  textareaDecoration: BoxDecoration(
    border: Border.all(color: Color(0xFFE7E7E7), width: 1),
    borderRadius: BorderRadius.circular(8),
  ),
  onChanged: (_) => setState(() => _dirty = true),
);
```

- 灰边框 `#E7E7E7`，圆角 8px
- `indicator: true` 显示字数指示器
- `showBottomDivider: false` 不显示底线

### 5.3 日期/时间选择器

用 TDPicker，注意 `onConfirm` 回调参数是 `Map<String,int>` 而非 `DateTime`，且需手动 `Navigator.pop()`：

```dart
TDPicker.showDatePicker(
  context,
  title: '选择日期',
  dateStart: [today.year, today.month, today.day],
  dateEnd: [today.year + 1, today.month, today.day],
  initialDate: [year, month, day],
  onConfirm: (selected) {
    final map = selected as Map<String, int>;
    setState(() {
      _date = DateTime(map['year']!, map['month']!, map['day']!);
    });
    Navigator.of(context).pop();  // 必须手动 pop
  },
);
```

---

## 6. 标签选择器（TagChip）

胶囊式选择标签，用于快捷选项、分类、状态选择等场景。

### 6.1 组件

`lib/widgets/tag_chip.dart` 提供 `TagChipRow` + `TagChipData`：

```dart
TagChipRow(
  scrollable: true,  // true=横向滚动，false=Wrap自动换行
  chips: [
    TagChipData(
      label: '选项A',
      selected: _selected == 'A',
      onTap: () => setState(() => _selected = 'A'),
    ),
    TagChipData(
      label: '选项B',
      selected: _selected == 'B',
      onTap: () => setState(() => _selected = 'B'),
    ),
  ],
)
```

### 6.2 视觉规格

| 状态 | 背景 | 文字 | 圆角 |
|------|------|------|------|
| 未选中 | `#F3F3F3` | `#181818` | 14px（胶囊） |
| 选中 | `#0052D9` | `#FFFFFF` | 14px（胶囊） |

- 字体大小：12px
- 内边距：`horizontal: 10, vertical: 5`
- 高度约 28px

### 6.3 使用场景

| 场景 | 模式 | 参考文件 |
|------|------|---------|
| 快捷日期/时间 | `scrollable: true` | `schedule_form_sheet.dart` |
| 接听类型选择 | `scrollable: true` | `follow_up_panel.dart` |
| 线索分类选择 | `scrollable: true` | `edit_lead_dialog.dart`、`follow_up_panel.dart` |
| 快捷备注 | `scrollable: false` (Wrap) | `follow_up_panel.dart` |

---

## 7. 骨架屏（Skeleton）

### 7.1 列表骨架屏

使用 `ScheduleSkeleton` 组件（`lib/pages/schedules/widgets/schedule_skeleton.dart`）：

```dart
ScheduleSkeleton(count: 4)  // 4 张骨架卡片
```

白卡片（`Colors.white`）圆角 10px，带微阴影。内部灰块有 shimmer 扫光动画（1200ms、reverse repeat）。

### 7.2 详情骨架屏

使用 `ShimmerBlock` 搭配 `AnimationController` 构建自定义布局：

```dart
// 在 State 类中添加：
late final AnimationController _skeletonCtrl;

@override
void initState() {
  super.initState();
  _skeletonCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);
}

@override
void dispose() {
  _skeletonCtrl.dispose();
  super.dispose();
}

// 骨架卡片容器
Widget _skeletonCard({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

// 用法
_skeletonCard(
  child: Column(
    children: [
      ShimmerBlock(ctrl: _skeletonCtrl, width: 120, height: 14),
      const SizedBox(height: 8),
      ShimmerBlock(ctrl: _skeletonCtrl, width: 200, height: 18),
    ],
  ),
)
```

`ShimmerBlock` 参数：

| 参数 | 类型 | 说明 |
|------|------|------|
| `ctrl` | `AnimationController` | shimmer 动画驱动 |
| `width` | `double` | 灰块宽度（默认 `infinity`） |
| `height` | `double` | 灰块高度（默认 14px） |

---

## 8. 按钮

### 8.1 主按钮

```dart
TDButton(
  text: '提交',
  theme: TDButtonTheme.primary,
  shape: TDButtonShape.round,  // 圆角
  disabled: _isLoading,
  onTap: _submit,
)
```

### 8.2 次要（浅色）按钮

```dart
TDButton(
  text: '取消',
  theme: TDButtonTheme.light,
  shape: TDButtonShape.round,
  onTap: _onCancel,
)
```

> ⚠️ **注意**：tdesign_flutter 0.2.7 的 `TDButtonTheme` 枚举**仅四个值**：`defaultTheme`、`primary`、`danger`、`light`。没有 `secondary`、`text`。从其他组件库迁移时务必先 grep 确认实际枚举值。

### 8.3 全宽按钮

底部提交按钮统一使用 `SizedBox(width: double.infinity)`：

```dart
SizedBox(
  width: double.infinity,
  height: 48,
  child: TDButton(...),
)
```

---

## 9. 顶栏（TopBar）

### 9.1 页面级顶栏

```dart
Container(
  height: 56,
  decoration: const BoxDecoration(
    color: Color(0xFF0052D9),
    boxShadow: [
      BoxShadow(
        color: Color(0x1A000000),
        blurRadius: 4,
      ),
    ],
  ),
  child: Row(
    children: [
      IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      const Spacer(),
      const Text(
        '页面标题',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      const Spacer(),
      // 可选：⋮ 菜单按钮
    ],
  ),
)
```

- 背景：品牌蓝 `#0052D9`
- 高度：56px
- 标题：17px bold 白色居中
- 返回按钮：白色箭头在左
- 右上角可放 `PopupMenuButton` 或留空以保持对称

### 9.2 抽屉顶栏

参见 §4.2 SheetHeader。

---

## 10. 列表样式

### 10.1 列表卡片

每项用白底圆角卡片（10px），微阴影：

```dart
Container(
  margin: const EdgeInsets.only(bottom: 8),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0D000000),
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: // 卡片内容
)
```

### 10.2 列表骨架屏

参见 §7.1 使用 `ScheduleSkeleton`。

---

> 本文档应与 `docs/dev/STYLE_GUIDE.md`（代码风格规范）配合阅读。
> 版本：v1.0 | 最后更新：2026-07-24
