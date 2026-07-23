# 本周 Sprint 最终整改：TagChipRow 统一 + 筛选布局修复

## 改动说明

### 1. 创建 TagChipRow 公共组件
在 `TagChip` 基础上新增 `TagChipData` 数据模型 + `TagChipRow` 容器组件，支持两种布局模式：

- **Mode 1: Wrap**（`scrollable: false`）— 自动换行，用于筛选抽屉
- **Mode 2: Scroll**（`scrollable: true`）— 横向滚动，用于跟进/编辑/日程面板

### 2. 替换 9 处手写实现
| 位置 | 原实现 | 现实现 |
|------|--------|--------|
| 筛选-状态 | `Wrap` + 内联 | `TagChipRow(scrollable: false)` |
| 筛选-分类 | `Wrap` + 内联 | `TagChipRow(scrollable: false)` |
| 筛选-项目 | `Wrap` + 内联 | `TagChipRow(scrollable: false)` |
| 跟进-接听类型 | `LayoutBuilder` 算死宽度 → 文字换行 | `TagChipRow(scrollable: true)` |
| 跟进-线索分类 | `SingleChildScrollView`+`Row` | `TagChipRow(scrollable: true)` |
| 编辑-分类 | `SingleChildScrollView`+`Row` | `TagChipRow(scrollable: true)` |
| 编辑-状态 | `SingleChildScrollView`+`Row` | `TagChipRow(scrollable: true)` |
| 日程-日期标签 | 内联 `_quickDateTag` | `TagChipRow(scrollable: true)` |
| 日程-时间标签 | 内联 `_quickTimeTag` | `TagChipRow(scrollable: true)` |

### 3. 修复 TagChip 膨胀导致的一行一个 bug
**根因**：`Container(alignment: Alignment.center)/Center(child: Text)` 在 Wrap 中会撑满父容器宽度，导致每个 chip 独占一行。

**修复**：改为 `DecoratedBox` + `Padding` + `Text`，组件链只按文字内容自然撑开，Wrap 正常换行。

### 4. 其他修复
- 线索卡片分类 tag 加 `alignment: Alignment.center`，文字居中
- `leads_filter_widgets.dart` 的 `SelectChip` 同步更新为胶囊样式（保留过渡）

## 变更统计
- 34 files changed
- 删除私有方法：`_quickDateTag`、`_quickTimeTag`、`_categoryChip`、`_chip` 等
- 新增文件：`tag_chip.dart`（TagChip、TagChipData、TagChipRow）
- `flutter analyze`: 0 issues
