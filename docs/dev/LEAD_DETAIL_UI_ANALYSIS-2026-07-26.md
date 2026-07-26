# 线索详情页 UI 分析报告

> 分析日期：2026-07-26
> 分析目标：可抽取组件 + 风格不适配项

---

## 一、页面结构

```
LeadDetailPage
├── AppBar (线索详情)
├── CustomScrollView
│   ├── LeadHeaderSection     → 姓名+标签、电话+拨号、公司/职位/归属
│   ├── _buildActionBar       → 跟进 / 日程 / 编辑 按钮行（内联）
│   ├── ScheduleSection       → 相关日程列表（外部 widget）
│   ├── FollowUpTimeline      → 跟进时间线
│   └── CallRecordsSection    → 通话记录摘要
├── LeadBottomNav              → 底部导航条（listContext 非空时）
```

---

## 二、可抽取的公共组件

### 🔴 高优先级

#### 1. `AppActionBar` → 已存在，但容器可抽取

`_buildActionBar`（`lead_detail_page.dart:196`）已经使用了 `AppActionBar` 组件，这是好的。但包裹它的容器：

```dart
Container(
  height: 44,
  decoration: const BoxDecoration(
    color: Colors.white,
    border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
  ),
)
```

**建议**：如果多个页面都有相同的"白底 + 顶部灰线 0.5px"的容器需求，把这个容器封装到 `AppActionBar` 里，或者创建一个 `AppActionBarContainer`。

**日程详情页**（`schedule_detail_page.dart`）也有完全相同的容器模式（虽然用了不同的 actionBar 实现）。

#### 2. `AppErrorBody` — 统一错误态

`_buildErrorBody`（`lead_detail_page.dart:168`）模式：
- 居中图标（64px）
- 错误文字（14px）
- 操作按钮（FilledButton）

首页的 `_buildErrorRetry` 也是类似模式（cloud_off + 文字 + 重试按钮）。
线索列表页也有错误态。

可以统一成：

```dart
AppErrorBody(
  icon: Icons.info,
  message: '该线索已删除或不存在',
  action: ActionItem(text: '返回列表', type: ActionType.primary, onTap: () => pop()),
)
```

### 🟡 中优先级

#### 3. `AppInfoRow` — 图标 + 标签 + 值

`lead_header_section.dart` 的 `_infoRow`（line 223）模式：
```dart
Icon(16px) + '$label: '(13px灰色) + value(13px黑色)
```

在详情页的公司/职位/归属行出现，也在其他详情页中可能复用。

#### 4. `AppTagChip` — 标签徽章

`_buildStatusTag` 和 `_buildCategoryTag` 都是自绘的 `Container` + 圆角 4px 方块标签。项目虽有 `TagChipData`（胶囊圆角 14px），但 4px 圆角方块标签是另一种视觉风格。

建议统一为 `AppTag` 组件，支持两种模式：

```dart
AppTag(
  label: '跟进中',
  type: TagType.status,        // 用 LeadConstants.statusColorStyle 配色
)
AppTag(
  label: '新客户',
  color: TagColor.primary,     // 蓝底蓝字
)
```

**现状**：`lead_header_section.dart:75` 和 `:103` 两处自绘，且颜色分别来自 `LeadConstants` 和硬编码，不统一。

### 🟢 低优先级

#### 5. 骨架屏容器 + ShimmerBlock

`_buildSkeleton`（line 259）和 `_skeletonBlock`（line 318）是纯静态灰块，没有 shimmer 动画。其他骨架屏（如 `home_skeletons.dart`）有 shimmer 动画。建议统一使用带 shimmer 的骨架屏组件。

---

## 三、风格不适配问题

### 3.1 硬编码颜色绕过 BrandColors

| 文件 | 位置 | 当前值 | 应为 |
|------|------|:------:|:----:|
| `lead_header_section.dart:58` | 姓名 24px | `Color(0xFF181818)` | `BrandColors.textPrimary` |
| `lead_header_section.dart:88` | 状态标签文字 | `textColor`（来自常量） | 通过 LeadConstants |
| `lead_header_section.dart:112` | 分类标签文字 | `Color(0xFF0052D9)` | `BrandColors.primary` |
| `lead_header_section.dart:129` | 电话图标选中 | `Color(0xFF0052D9)` | `BrandColors.primary` |
| `lead_header_section.dart:130` | 电话图标禁用 | `Color(0xFFDCDCDC)` | `BrandColors.textDisabled` |
| `lead_header_section.dart:140-141` | 电话文字 | `Color(0xFF0052D9)` / `(0xFFA6A6A6)` | `BrandColors.primary` / `textSecondary` |
| `lead_header_section.dart:232` | infoRow 图标 | `Color(0xFFA6A6A6)` | `BrandColors.textSecondary` |
| `lead_header_section.dart:238` | infoRow 标签 | `Color(0xFFA6A6A6)` | `BrandColors.textSecondary` |
| `lead_header_section.dart:246` | infoRow 值 | `Color(0xFF181818)` | `BrandColors.textPrimary` |
| `lead_detail_page.dart:177` | 错误图标 | `Color(0xFFA6A6A6)` | `BrandColors.textSecondary` |
| `lead_detail_page.dart:183,185` | 错误文字 | `Color(0xFF181818)` | `BrandColors.textPrimary` |
| `lead_detail_page.dart:199-202` | actionBar 容器 | `Color(0xFFEEEEEE)` | `BrandColors.line` |
| `lead_detail_page.dart:327` | 骨架块 | `Color(0xFFEEEEEE)` | `BrandColors.border` |
| `call_records_section.dart` | 多处 | 白色背景 + 硬编码灰 | 统一走主题 |
| `follow_up_timeline.dart` | 多处 | 硬编码 | 待查 |

### 3.2 容器风格不统一

详情页各 section 的白卡片风格不一致：

| Section | 实现 | 圆角 | 阴影 | 间距 |
|---------|------|:----:|:----:|:----:|
| LeadHeaderSection | `Container(color: white)` | ❌ 无 | ❌ 无 | padding 16 |
| ActionBar | `Container(color: white, top border)` | ❌ 无 | ❌ 无 | 固定高度 44 |
| ScheduleSection | `Container(color: white)` | ❌ 无 | ❌ 无 | margin 8 |
| FollowUpTimeline | `Container(color: white)` | ❌ 无 | ❌ 无 | 待查 |
| CallRecordsSection | `Container(color: white)` | ❌ 无 | ❌ 无 | margin 8 |

而**首页**（刚刚整改过的）和**线索列表页**用的是 **12px 圆角白卡片 + 阴影**。同一 App 内，详情页和列表页的卡片风格不一致。

**建议**：详情页的各 section 统一用 `AppCardSection`（或至少统一用白底 + 间距 + 可选圆角），消除"白块叠在一起分不清边界"的感觉。

### 3.3 拨号 FAB 风格

`lead_header_section.dart:149-166` 的拨号按钮是一个手写的 `SizedBox(width: 56, height: 56) + FloatingActionButton`。FAB 的样式没有走到 `FloatingActionButtonTheme`，硬写了 `backgroundColor: Color(0xFF0052D9)`。

### 3.4 骨架屏无 shimmer

首页骨架屏有 shimmer 扫光动画（`home_skeletons.dart`），但线索详情页的骨架屏是静态灰块 `_skeletonBlock`（line 318），没有动画，看起来死板。

---

## 四、总结

| 类别 | 内容 | 影响 |
|:----:|------|:----:|
| 🔴 可抽取 | `AppErrorBody` | 各页面错误态统一，消除重复代码 |
| 🔴 可抽取 | `AppInfoRow` | 详情页 icon+label+value 模式 |
| 🟡 可抽取 | `AppTag`（方块标签） | 统一状态/分类标签视觉 |
| 🟢 可抽取 | `AppActionBarContainer` | 统一 action bar 外框 |
| 🔴 风格问题 | 15+ 处硬编码颜色 | 违反 BrandColors 规范 |
| 🔴 风格问题 | 详情页无圆角卡片 | 与首页/列表页卡片风格不一致 |
| 🟡 风格问题 | 拨号 FAB 硬编码 | 未走 FAB 主题 |
| 🟢 风格问题 | 骨架屏无 shimmer | 视觉活力不足，与其他页不一致 |
