# 代码审查：v0.5 首页看板 + 底部 Tab 导航

- 提交：`7bb07ad`
- 类型：`feat`
- 作者 / 日期：FungLeo / 2026-07-22
- 审查人：Mobile App Builder（移动端小组组长）
- 审查日期：2026-07-23
- 审查基准：已提交代码（干净基线 flutter analyze：21 issues / 0 error；本提交贡献 6 个：5 warning + 1 info）

## 一、改动概览

| 文件 | 说明 |
|------|------|
| lib/pages/home/home_page.dart | **新增（927 行）**：首页看板（统计四宫格 + 日程 + 快捷入口 + 骨架屏） |
| lib/pages/main_shell.dart | 新增：底部 Tab 导航壳 |
| lib/providers/home_provider.dart | **新增（350 行）**：首页数据状态机 |
| lib/services/home_service.dart | 新增：看板/日程 API |
| lib/models/home_stats.dart / schedule.dart | 模型 |
| lib/pages/coming_soon_page.dart | 占位页 |

## 二、客观质量门禁（flutter analyze）

本提交贡献 **6 个 issue**（0 error，5 warning + 1 info）：

| 级别 | 位置 | 规则 | 说明 |
|------|------|------|------|
| warning | lib/pages/home/home_page.dart:34 | unused_field | `_hasInitialized` 赋值后从未读取 |
| warning | lib/providers/home_provider.dart:5 | unused_import | 未使用的 `api_client.dart` 导入 |
| warning | lib/providers/home_provider.dart:178 | unnecessary_cast | 冗余 `as` 强转 |
| warning | lib/providers/home_provider.dart:186 | unnecessary_cast | 冗余 `as` 强转 |
| warning | lib/providers/home_provider.dart:199 | unnecessary_cast | 冗余 `as` 强转 |
| info | lib/services/home_service.dart:18 | prefer_initializing_formals | 建议 `this._apiClient` 形式 |

## 三、规范与质量评估

### 3.1 结构与拆分 ✅（仓内质量标杆）
- `home_page.dart` 的 `build()` 仅 ~20 行，拆成 ~15 个 `_build*` 辅助方法 + 5 个独立 `StatelessWidget`（_StatCard / 骨架屏系列），**方法级无超 120 行上帝方法**（最大 `_buildScheduleSection` 96 行，临界但可接受）。
- 大量使用 `const` 构造函数（§4.1 达标）。
- 生命周期/网络监听在 `initState`/`dispose` 中正确配对（`WidgetsBinding` observer、`Connectivity` 订阅 `cancel`），异步回调均有 `if (mounted)` 检查（§4.4 达标）。
- 具备错误重试 UI 与骨架屏加载态，用户体验完整（§性能/UX 达标）。

### 3.2 需清理项
- ⚠️ `_hasInitialized` 字段（home_page:34）定义了却从未读取 → `unused_field`。应删除或真正用于「仅初始化一次」守卫。
- ⚠️ `home_provider.dart` 三处 `unnecessary_cast`：对已确定类型的变量做冗余 `as` 强转，应直接去掉。
- ⚠️ `home_provider.dart:5` 未使用的 `api_client` 导入。

### 3.3 注释
- `home_page.dart` 文件头注释位于 import 之后（§2.2）。
- ⚠️ 约 15 个 `_build*` 辅助方法**几乎均无 `///` 注释**（§1.3 违反）。这是全仓页面的通病，本文件是典型代表。
- ⚠️ 单文件 927 行（含多个骨架屏 StatelessWidget），建议将骨架屏系列抽到 `home_widgets.dart` 或 `skeletons.dart`，降低单文件体量。

## 四、问题清单

| 级别 | 位置 | 问题 | 建议 |
|------|------|------|------|
| 中 | home_page.dart:34 | `_hasInitialized` 未使用 | 删除或用于初始化守卫 |
| 中 | home_provider.dart:5/178/186/199 | 未用导入 + 3 处冗余强转 | 清理 |
| 提示 | home_service.dart:18 | prefer_initializing_formals | 改 `this._apiClient` |
| 低 | home_page.dart 全部 `_build*` | 缺 `///` 注释 | 补关键辅助方法注释 |
| 低 | home_page.dart（927 行） | 单文件过大 | 抽离骨架屏组件 |

## 五、审查结论

**✅ 通过（有条件）。** 首页是结构与用户体验的标杆实现（合理拆分、const 到位、mounted 检查、骨架屏/重试齐全）。需清理 6 个 lint（多为机械性冗余），并补充 `_build*` 方法注释、考虑拆分骨架屏文件。不阻塞合入，建议本迭代内清理。
