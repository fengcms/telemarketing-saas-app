# 进度文档 — 日程搜索页 / 表单页 硬编码色收尾

> **日期**：2026-07-26
> **分支**：`master`
> **性质**：纯 UI 色值集中化（零业务逻辑改动）
> **前置**：`SCHEDULE_DETAIL_ANALYSIS-2026-07-26.md` 将本项列为「详情页分析范围外的同模块残留」；本节点完成该收尾。

## 一、背景与范围

日程模块 UI 整改已覆盖**列表页**（`4f37afd` / `7b2b672` / `3bbc02d`）与**详情页**（`aeea5e9`）。
同模块的另外两个文件仍残留 TDesign 时期的硬编码 `Color(0xFF...)`，未纳入前两批：

- `lib/pages/schedules/schedule_search_page.dart`（日程搜索页）
- `lib/pages/schedules/widgets/schedule_form_fields.dart`（新建/编辑日程抽屉的表单字段，为 `schedule_form_sheet.dart` 的 `part`）

本节点仅做**色值 → `BrandColors.*` 替换**，消除全模块硬编码色不一致隐患，不改变任何视觉表现与交互逻辑。

## 二、改动清单

### `schedule_search_page.dart`（自身新增 `color_scheme` 导入）

| 原硬编码 | 收敛目标 | 出现处 |
|---------|---------|--------|
| `Color(0xFF0052D9)` | `BrandColors.primary` | AppBar 底色、搜索按钮底色 |
| `Color(0xFFF3F3F3)` | `BrandColors.surface` | 搜索框背景 |
| `Color(0xFF181818)` | `BrandColors.textPrimary` | 输入框文字、清除/「没有更多了」文字、错误态/空态标题 |
| `Color(0xFFA6A6A6)` | `BrandColors.textSecondary` | 搜索/清除图标、空态副文字 |
| `Color(0xFFC5C5C5)` | `BrandColors.textDisabled` | 输入框 hint |

### `schedule_form_fields.dart`（导入在父文件 `schedule_form_sheet.dart` 添加）

| 原硬编码 | 收敛目标 | 出现处 |
|---------|---------|--------|
| `Color(0xFF181818)` | `BrandColors.textPrimary` | 关联线索/日期/时间文字 |
| `Color(0xFFA6A6A6)` | `BrandColors.textSecondary` | 日历/时钟图标 |
| `Color(0xFFE7E7E7)` | `BrandColors.border` | 日期/时间输入框边框 |
| `Color(0xFFD54941)` | `BrandColors.error` | 日期选择错误提示红字 |

> `schedule_form_fields.dart` 为 `part of 'schedule_form_sheet.dart'`，`color_scheme` 导入加在父文件顶部。

## 三、保留内联的硬编码色（无对应 BrandColors 常量）

| 文件 | 值 | 用途 | 处理 |
|------|----|----|------|
| `schedule_search_page.dart` | `0xFFDCDCDC` | 错误态/空态图标（禁用灰） | 保留内联，无对应常量 |

其余潜在硬编码（阴影 `0x14000000`、遮罩等）均非本次范围，本节点未触碰。

## 四、验证结论

- `flutter analyze`：改动 3 文件（search / form_fields / form_sheet）**0 issue**；全仓 **0 新增问题**（既有 11 个 `!` warning 位于 `token_storage.dart`，与本次无关）。
- 业务逻辑（搜索/分页/表单提交/校验/权限显隐）**一行未动**。
- 视觉表现：纯色值等价替换，无像素级变化。

## 五、真机验证清单（已通过）

1. 日程搜索页：搜索栏、列表、错误/空态外观不变
2. 新建/编辑日程抽屉：日期、时间输入框边框、日历/时钟图标、错误红字不变

## 六、提交

- 提交信息：`style(schedules): 收尾日程搜索页/表单页硬编码色 → BrandColors`
- 文件：4 个（3 代码 + 1 工作日志）
- 全模块硬编码色整改至此**全部完成**（列表页 + 详情页 + 搜索页 + 表单页）。

---

> **模块 UI 整改总览（2026-07-22 ~ 07-26）**
> - 筛选条统一（方案 B，占满 100% 宽）：`f058760`
> - 日程列表页（颜色集中化 + 公共组件复用 + 抽组件 + 维护性）：`4f37afd` / `7b2b672` / `3bbc02d`
> - 日程详情页（emoji→Icons、卡片圆角/阴影对齐、复用 AppTag/AppInfoRow/AppErrorBody、色值集中化）：`aeea5e9`
> - 日程搜索页 / 表单页（硬编码色收尾）：本提交
