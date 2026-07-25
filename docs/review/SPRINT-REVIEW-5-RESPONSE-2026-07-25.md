# TDesign → Material 3 全量替换 — 回复文档

> 对应审阅：`docs/review/SPRINT-REVIEW-5-MIGRATION-2026-07-25.md`
> 修复分支：`feat/m3-theme-migration-preview`（`HEAD`)
> 修复日期：2026-07-25

---

## 修复清单

| 优先级 | 问题 | 状态 | 改动 |
|:------:|------|:----:|------|
| ⚠️ P2 | `leads_list_page.dart` 619 行超 560 红线 | **✅ 已修** | 筛选/排序面板抽出为独立文件 `leads_filter_sheet.dart` → 主文件 **396 行** |
| 🟡 P3 | `app_textarea.dart:127-128` 计数器颜色硬编码 | **✅ 已修** | `Color(0xFFD54941)` → `BrandColors.error`，`Color(0xFFA6A6A6)` → `BrandColors.textSecondary` |
| 🟡 P3 | `pubspec.yaml` 移除 `tdesign_flutter` | ⚪ 待组长放行后执行 | 无代码依赖后即可删除 |

---

## 修复详情

### P2：leads_list_page 行数超限

**问题**：619 行 > 560 红线（524→619，增 95 行）

**方案**：将筛选面板（`LeadsFilterSheet`）和排序面板（`LeadsSortSheet`）抽离为独立文件 `lib/pages/leads/widgets/leads_filter_sheet.dart`。

**效果**：

| 文件 | 修复前 | 修复后 | 红线 |
|------|:------:|:------:|:----:|
| `leads_list_page.dart` | 619 | **396** | ≤560 ✅ |
| `leads_filter_sheet.dart`（新增） | — | 161 | 独立文件无限制 |

**提取内容**：
- `_showSortSheet` + `_sortOption` → `LeadsSortSheet`（`ConsumerWidget`）
- `_showFilterSheet` + `_buildFilterSheetTitle` + `_buildStatusSection` + `_buildCategorySection` + `_buildProjectSection` + `_buildStatusChips` + `_buildOptionChips` → `LeadsFilterSheet`（`ConsumerStatefulWidget`）

**设计要点**：
- `LeadsSortSheet` 通过 `ConsumerWidget` 的 `ref` 参数访问 `leadListProvider`
- `LeadsFilterSheet` 通过 `ConsumerStatefulWidget` 的 `ref` 属性访问 Provider，内部 `setState` 管理临时筛选状态
- 主文件保留 `_buildFilterTags`/`_buildTag`/`_findOptionName`（~55 行，与 build 方法紧密耦合）

### P3：AppTextarea 计数器颜色硬编码

**问题**：行 127-128 直接写了 `Color(0xFFD54941)` 和 `Color(0xFFA6A6A6)`，语义上应引用 `BrandColors` 常量。

**修复**：
```dart
// 修改前
color: isOver ? const Color(0xFFD54941) : const Color(0xFFA6A6A6),

// 修改后
color: isOver ? BrandColors.error : BrandColors.textSecondary,
```

**影响**：值不变（`#D54941` = `BrandColors.error`，`#A6A6A6` = `BrandColors.textSecondary`），仅从字面量改为命名常量，便于未来主题统一调整。

---

## 客观门禁

| 手段 | 结果 |
|------|------|
| `flutter analyze` | **No issues found!（exit 0，0 issue）** ✅ |
| `leads_list_page` 行数 | **396 行**（< 560）✅ |
| `grep -r "TDIcons\|TDToast\|TDButton\|TDTextarea\|TDPicker\|TDStepper\|TDNavBar" lib/` | **零**（含注释）✅ |

---

— Mobile App Builder AI 助手，2026-07-25
