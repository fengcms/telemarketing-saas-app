# 日程表单抽屉 UI 优化计划（v0.15）

> 日期：2026-07-24
> 关联设计：docs/design/page-design/12-新建-编辑日程.md
> 范围：纯 UI 优化 — `lib/pages/schedules/widgets/schedule_form_sheet.dart`
> 参考组件：跟进面板(`follow_up_panel`)、登录页输入框(`login_page`)、TagChip 组件(`tag_chip`)、编辑线索对话框(`edit_lead_dialog`)

---

## 用户需求逐条对应方案

| # | 需求 | 现状 | 方案 |
|---|------|------|------|
| 1 | **白背景** | `follow_up_panel` 已是白底+圆角顶 | 抽屉容器改白底(已白)，边框/圆角对齐 `SheetHeader`+4px 灰拖动手柄 |
| 2 | **卡片无背景/圆角** | `_card()` 用 `Color(0xFFF3F3F3)` + 圆角 + 16px 内边距 | 完全移除 `_card()` 方法，每节直接用 `Padding(EdgeInsets.symmetric(horizontal:16, vertical:12))` 包 Column，左上角灰色标签 `Text('标题', style: 12px #A6A6A6)` → SizedBox(8) → 内容 |
| 3 | **关联线索一行** | 两行："👤 姓名" + "📞 手机号" | 去掉图标，一行 `Text('$name - $phone')` 16px #181818；创建模式右侧灰色"(只读)" |
| 4 | **计划时间标题去图标** | `📅 计划时间 *` | 改为 `计划时间 *`（纯文字，12px #A6A6A6），后跟红色 `*` |
| 5 | **输入框白底灰边框圆角** | 灰底 `#F3F3F3` + `#E7E7E7` 边框 + 12px 圆角 | 改白底 `Colors.white` + 灰边框 `#E7E7E7` + 12px 圆角（参照登录页输入框：Container 56px、`InputBorder.none`、`contentPadding vertical:16`） |
| 6 | **快捷按钮用 TagChip** | `ChoiceChip` 自定义样式 | 改用 `TagChipRow` + `TagChipData`（参照 `edit_lead_dialog` 的分类选择器、`follow_up_panel` 的快捷备注/接听类型）；非滚动 `Wrap` 模式自动换行 |
| 7 | **删除标题文本框** | `_titleCtrl` + TextField + counter | **删除整个标题区块**（原有标题创建模式从线索名自动生成、编辑模式回填后不可改——与用户"标题不允许删除"语义一致） |
| 8 | **备注(原来叫"内容")用 TDTextarea** | 普通 TextField + OutlineInputBorder | 换用 `TDTextarea`（参照 `follow_up_panel._buildContentField`：`minLines:2, maxLength:100, showBottomDivider:false, indicator:true`，灰边框 8px 圆角）；标题改为「备注」 |

## 附带影响

- **字段上移**：删除标题区块后，表单从上到下变为：关联线索 → 计划时间(日期+快捷) → 计划时间(时分+快捷) → 备注 → 归属人(仅TM/TA)
- **`_titleCtrl` 全清理**：dispose、_initFields、_submit 中的 title 引用全部删除；`patchSchedule` 不再传 title（编辑只改 time + content）；创建模式标题预填逻辑写入 `ScheduleFormContent` 参数中但仍然传 `createSchedule(title: '🏷️ $name - $phone')`
- **`_dirty` 判定调整**：标题删除后，编辑模式 dirty 判定仅靠时间 + 内容
- **`_dateChip`/`_timeChip`** 改为用 `TagChipRow` + `TagChipData`（移除 `_isSameDay`/`ChoiceChip`）

## 文件改动

| 文件 | 动作 | 说明 |
|------|------|------|
| `lib/pages/schedules/widgets/schedule_form_sheet.dart` | 改 | 全书 UI 重写：去 `_card`、去标题框、`TagChipRow` 替代 `ChoiceChip`、`TDTextarea` 替代 TextField |
| `lib/widgets/tag_chip.dart` | 不改 | 已有能力完全覆盖（`TagChipRow` + Wrap 模式） |

## 验证检查项

- [ ] `flutter analyze` 全仓零问题
- [ ] 创建模式：关联线索显示 "姓名 - 手机号"
- [ ] 编辑模式：关联线索一行显示
- [ ] 计划时间输入框白底灰边框，点选正确
- [ ] 日期/时间快捷按钮用胶囊式 TagChip，选中蓝底白字
- [ ] 没有标题输入框
- [ ] 备注用 TDTextarea，灰边框 8px 圆角
- [ ] 提交时创建带 title 预填、编辑不带 title 变更
