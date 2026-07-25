# 设置页 UI 整改意见

> 审阅文件：`lib/pages/settings/settings_page.dart`
> 开发日期：2026-07-25（TDesign→M3 迁移合并后）
> 审阅人：Mobile App Builder AI 助手

---

## 🔴 P0 — 必须整改（主题一致性）

### 1. 删除文件顶部的颜色常量，改用 BrandColors

**当前写法**（第 18-21 行）：
```dart
const Color _brandColor = Color(0xFF0052D9);
const Color _textSecondary = Color(0xFFA6A6A6);
const Color _errorColor = Color(0xFFD54941);
const Color _pageBg = Color(0xFFF3F3F3);
```

**问题**：绕过 `lib/theme/color_scheme.dart` 中已定义好的 `BrandColors`，自己造了一套，未来改主题色要改两处。

**改法**：删除这 4 行，然后替换使用：
- `_brandColor` → `BrandColors.primary`
- `_textSecondary` → `BrandColors.textSecondary`
- `_errorColor` → `BrandColors.error`
- `_pageBg` → `BrandColors.surface`

### 2. 底部版本号文字颜色

**当前写法**（第 280、291 行）：
```dart
color: Color(0x99A6A6A6),
```

**问题**：手写了带透明度的色值，无法通过主题统一管理。

**改法**：
```dart
color: BrandColors.textDisabled,   // #C5C5C5
```

如果想保留更淡的效果，用 `.withOpacity(0.6)` 也比硬编码值好。

---

## 🟡 P1 — 建议整改（组件复用）

### 3. 关于弹窗使用原始 `showDialog` + `AlertDialog`

**当前写法**（第 122-173 行）：
```dart
showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    title: const Text('关于'),
    content: Column(...),
    actions: [FilledButton(...)],
  ),
);
```

**问题**：项目已有 `AppDialog` 统一管理弹窗样式（圆角/按钮/背景）。原始的 `AlertDialog` 样式跟项目风格不一致。

**改法**：使用 `AppDialog`，或者至少将确定按钮改为 `AppActionBar.submit` 风格。

### 4. 卡片容器手动用 Container 拼装

**当前写法**（第 322-332 行）：
```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: Color(0xFFE7E7E7), width: 0.5),
  ),
  child: Column(children: children),
);
```

**问题**：白卡片模式项目中已广泛使用（`Card` + 主题配置）。虽然设置页的卡片是列表式（6px 圆角 + 灰边框），与详情页的浮层卡片（12px 圆角 + 阴影）不同，但至少要统一使用 `Card` 组件。

**改法**（更优：从 `Card` 组件 + 主题覆写）：
```dart
Card(
  margin: const EdgeInsets.symmetric(horizontal: 16),
  elevation: 0,   // 设置页卡片不需要阴影
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(6),
    side: const BorderSide(color: BrandColors.border, width: 0.5),
  ),
  child: Column(children: children),
);
```

---

## 🟡 P1 — 样式细节

### 5. 分区标题颜色用品牌蓝

**当前写法**（第 315 行）：
```dart
color: _brandColor,  // #0052D9 品牌蓝
```

**问题**：设置页的"账户安全""账户操作""关于"是纯装饰性的文本标签，不是可点击操作。品牌蓝色 = 可交互暗示。iOS/Android 设置页的分区标题都是**灰色次要文字**。

**改法**：
```dart
color: BrandColors.textSecondary,   // #A6A6A6
```

### 6. 退出登录加载无反馈

**当前写法**（第 244 行）：
```dart
enabled: !_logouting,
onTap: _logouting ? null : _onLogout,
```

**问题**：点击"退出登录"后 ListTile 直接禁用，没有任何加载动画，用户不知道操作正在进行。

**改法**：在 `trailing` 加 loading：
```dart
trailing: _logouting
    ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
    : const Icon(Icons.chevron_right, size: 20),
```

### 7. Leading 图标尺寸统一

**当前写法**：所有 `leading` 的 `Icon` 都用了 `size: 20`。

**问题**：Material ListTile 的 leading 区域默认是 40×40，放 20px 的图标偏小偏左。建议统一为 22-24px，或不指定大小让系统默认处理。

---

## 🟢 P2 — 建议改进

### 8. 引入 `import 'package:telemarketing_app/theme/color_scheme.dart'`

当前没有引用 `BrandColors` 的导入。加上后全文件就能用 `BrandColors.textSecondary` 等。

### 9. `_sectionTitle` 方法名建议改为 `_buildSectionTitle`

虽然是内部细节，但项目约定 `_buildXxx()` 命名模式。

---

## 修改后预期效果

```
┌─────────────────────────────┐
│          设置                │  ← AppBar
├─────────────────────────────┤
│                             │
│   账户安全                   │  ← 灰色 14px，非蓝色
│   ┌─────────────────────┐   │
│   │ 🔒  修改密码      ›  │   │  ← 白卡片+灰边框
│   └─────────────────────┘   │
│                             │
│   账户操作                   │  ← 灰色
│   ┌─────────────────────┐   │
│   │ 🚪  退出登录      ○  │   │  ← 红色，loading 时转圈
│   │ ─────────────────── │   │
│   │ 💻  全设备退出     ›  │   │
│   └─────────────────────┘   │
│                             │
│   关于                       │
│   ┌─────────────────────┐   │
│   │ ℹ️  关于          ›  │   │
│   └─────────────────────┘   │
│                             │
│       电销工作台 v1.0.0      │  ← BrandColors.textDisabled
│       后端版本: v2.3.1      │
│                             │
└─────────────────────────────┘
```

---

## 总结

| 优先级 | 数量 | 性质 |
|:------:|:----:|------|
| 🔴 P0 | 2 处 | 绕过主题系统（颜色常量 + 底部色值） |
| 🟡 P1 | 5 处 | 组件复用缺失 + 样式细节（弹窗/卡片/标题色/loading/图标） |
| 🟢 P2 | 2 处 | 命名建议 |

**核心问题**：页面功能逻辑正确，但 UI 层完全没走我们刚搭好的主题和组件体系。整改不伤筋骨，主要是替换常量和组件引用。
