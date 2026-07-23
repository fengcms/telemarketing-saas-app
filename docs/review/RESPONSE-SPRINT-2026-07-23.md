# 本批次整改回复总结（2026-07-23 下午）

## 改动清单

### 1. schedule_dialog.dart — 新建日程面板
- **弹窗→抽屉**：`AlertDialog` 改为 `showModalBottomSheet` 底部抽屉样式（跟进面板同款）
- **标题**：改为 `新建日程（线索名字）`
- **文本框**：去掉 `SizedBox(height:80)` → `minLines:2` 自适应 + 圆角灰边框 + 内填充
- **日期选择器**：修复日期范围（`dateStart` 改为今天，只能选未来日期）
- **日期快捷项**：新增「明天 / 后天 / 大后天 / 五天后 / 七天后」小 tag 一行横向滚动
- **时间选择器**：`Material showTimePicker` → `TDesign showDatePicker(useHour+useMinute)`，天然中文
- **时间快捷项**：新增「上午10点 / 下午2点 / 下午5点 / 晚上7点 / 晚上9点」小 tag
- **提交按钮**：改为蓝色圆角按钮 + 提交时白色转圈

### 2. edit_lead_dialog.dart — 编辑线索面板
- **弹窗→抽屉**：`AlertDialog` 改为 `showModalBottomSheet` 底部抽屉样式
- **标题**：改为 `编辑 xx 线索`（带名字）
- **分类标签**：`分类` → `线索分类`
- **分类选择器**：下拉列表 → 横向平铺 chips（跟进面板同款样式），默认选中当前值
- **状态选择器**：下拉列表 → 横向平铺 chips，默认选中当前值
- **提交按钮**：改为蓝色圆角按钮 + 提交时白色转圈

### 3. leads_filter_widgets.dart — 筛选面板修复
- **SelectChip**：去掉固定 `height:36`，改回 `padding: vertical:6` 自适应
- 修复筛选面板子项从"一行一个"恢复为"一行多个、自动换行"

## 文件改动
| 文件 | 状态 |
|------|------|
| `lib/pages/leads/widgets/schedule_dialog.dart` | 重写 |
| `lib/pages/leads/widgets/edit_lead_dialog.dart` | 重写 |
| `lib/pages/leads/widgets/leads_filter_widgets.dart` | 修改 |
| `.workbuddy/memory/2026-07-23.md` | 追加日志 |

## flutter analyze
- **0 issue** 保持
