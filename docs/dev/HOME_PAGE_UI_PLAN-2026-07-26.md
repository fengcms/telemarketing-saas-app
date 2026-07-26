# 首页 UI 层整改计划

> 分析日期：2026-07-26
> 目标：首页全面适配 M3 主题体系，消除硬编码 + 抽取公共组件

---

## 一、新增公共组件

### 1. `AppCardSection`（`lib/widgets/app_card_section.dart`）
统一白卡片容器，替换首页 3 个 section + 全项目其它白卡片。

```dart
AppCardSection(
  title: '今日工作概况',
  trailing: '7月26日 周日',
  child: _buildStatsGrid(),
)
```

- 12px 圆角白底 + 阴影（走 Card 主题）
- 内置 16px padding
- `title` 必填，`trailing`/`child` 可选

### 2. `AppNoticeBar`（`lib/widgets/app_notice_bar.dart`）
统一通知提示条，替换首页离线/到期提示。

```dart
AppNoticeBar(
  icon: Icons.error_outline,
  text: '当前处于离线状态',
  type: NoticeType.warning,  // warning | info | success
  closable: true,
  onClose: _onClose,
)
```

- 36px 高度，带图标 + 文字 + 可关闭
- type 控制配色（不再每处硬编码）

---

## 二、修复项目

### P0 — 颜色硬编码 → BrandColors
| 文件 | 位置 | 修复量 |
|------|------|:------:|
| `home_stats_section.dart` | 全文 | ~10 处 |
| `home_schedule_section.dart` | 全文 | ~12 处 |
| `home_quick_entry_section.dart` | 全文 | ~6 处 |
| `home_page.dart` | banner/logo 等 | ~4 处 |

### P1 — 自绘组件 → M3 组件
| 位置 | 当前 | 替换为 |
|------|------|--------|
| 重试按钮 × 2 | `GestureDetector + Container` | `FilledButton` |
| "查看全部 >" | `GestureDetector + Text` | `TextButton` |
| 角标 | `Container + BoxDecoration` | `Badge` |
| 三个白卡片 | `Container + BoxShadow` | `AppCardSection` |
| 通知条 | `_buildNoticeBar` 私有方法 | `AppNoticeBar` |

### P2 — 文本色阶规范
| 场景 | 当前 | 应为 |
|------|:----:|:----:|
| 区块标题 16px | `Color(0xFF181818)` | `BrandColors.textPrimary` |
| 正文 15px | `Color(0xFF181818)` | `BrandColors.textPrimary` |
| 标签文字 13px | `Color(0xFFA6A6A6)` | `BrandColors.textSecondary` |
| 禁用/占位 | `Color(0xFFC5C5C5)` | `BrandColors.textDisabled` |

---

## 三、执行顺序

```
1. 创建 AppCardSection        → 消除三段重复卡片容器
2. 创建 AppNoticeBar           → 提取通知条组件
3. 更新 home_stats_section    → 替换颜色 + 按钮 + 卡片
4. 更新 home_schedule_section → 替换颜色 + 按钮 + 角标 + 卡片
5. 更新 home_quick_entry      → 替换颜色 + 卡片
6. 更新 home_page.dart        → 替换通知条 + 颜色
7. flutter analyze 验证
```
