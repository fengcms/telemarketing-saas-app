# 进度文档：顶栏统一整改（4 处）

> 日期：2026-07-28
> 计划：`docs/dev/SCHEDULE_LIST_REPLAN-2026-07-28.md`（日程顶栏重组）+ 用户口头追加 4 项顶栏调整
> 范围：仅顶栏 UI，业务逻辑零改动

## 完成内容

| 调整 | 文件 | 说明 |
|------|------|------|
| ① 员工视角日程页标题居中「日程」 | `schedule_list_page.dart` | 员工（`canTeam=false`）改用标准 `AppBar(centerTitle:true, title:'日程', backgroundColor:BrandColors.primary, foregroundColor:white, elevation:0)`，与「我的」页风格一致；不再使用蓝块自定义顶栏 |
| ② 经理/管理员视角日程页去统计徽标 | `schedule_top_bar.dart` + `schedule_list_page.dart` | 去掉顶栏 `[今日待办][逾期]` 统计簇；保留左侧「我的日程\|团队日程」白底胶囊 + 右侧成员选择图标（选中显示成员色圆点）；删除 `_barStats()` 及 `_countTodayPending` / `_countOverdue` 两个本地统计方法 |
| ③ 线索页关闭公海时标题居中「线索」+ 保留筛选/排序 | `leads_top_bar.dart` | 关闭公海可领（`showPublicTab=false`）：`Stack(alignment:center)` 居中「线索」标题，右侧叠加筛选/排序按钮（按用户确认**保留**）；开启公海时维持原「我的线索\|公海线索」双 Tab + 右侧筛选/排序 |
| ④ 首页顶栏去「退出」图标 +「团队看板」文字 | `home_page.dart` | 删除 `appBar.actions`（团队看板 `Text` + 退出 `Icons.logout`）；移除对应 `import` 与 `_onLogout()`；退出登录功能仍保留在「设置」页，未丢失 |

## 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 员工视角日程顶栏 | 标准 `AppBar` 而非蓝块 | 员工无团队视角，不需胶囊/成员选择；与「我的」页一致更协调 |
| 统计徽标 | 移除 | 用户确认标题栏显示 `[今日待办][逾期]` 过于拥挤 |
| 线索页关闭公海 | 居中「线索」+ 保留筛选/排序 | 用户确认筛选/排序保留（推荐），居中标题用 `Stack` 叠加不影响右侧按钮布局 |
| 退出登录 | 从首页移除、保留设置页 | 功能不丢失，首页顶栏更清爽 |

## 关联文件（本次一并提交，保证可编译 / 干净）

- 新增 `lib/widgets/app_scope_segmented.dart`：白底胶囊切换公共组件，`schedule_top_bar` 依赖，必须随提交，否则 `import` 缺失编译失败
- 删除 `lib/pages/schedules/widgets/team_schedule_header.dart`：日程顶栏重组后的遗留死代码（`git rm`）
- 删除 `lib/widgets/app_scope_toggle.dart`：被 `AppScopeSegmented` 取代，已无引用（`git rm`）

## 验证

- `flutter analyze`：4 处相关文件 **0 error 0 warning**（分项分析通过）；全仓仅余 `lib/services/token_storage.dart` 11 个 `unnecessary_non_null_assertion` warning（预存，非本次改动，待后续单独清理）
- 真机实测通过（用户确认）：
  1. 员工登录 → 日程页标题**居中**「日程」
  2. 经理/管理员登录 → 日程页保留胶囊 + 成员图标，但**无** `[今日待办][逾期]`
  3. 关闭公海可领 → 线索页标题**居中**「线索」，右侧筛选/排序仍在
  4. 首页顶栏 → 无「退出」图标、无「团队看板」文字

## 踩坑与注意

- 日程顶栏依赖新建公共组件 `app_scope_segmented.dart`：若只提交 `schedule_top_bar.dart` 不带它，仓库会编译失败。本次已一并提交。
- 员工视角用标准 `AppBar`、经理/管理员用自定义蓝块，两种顶栏形态并存：后续若统一顶栏风格，需注意角色判断 `canTeam` 的边界。
- 移除统计徽标时同步删除了本地统计方法（`_countTodayPending` / `_countOverdue`），避免死代码；若未来要在别处显示待办/逾期统计，需从 notifier 重新取数。
- `token_storage.dart` 的 11 条 warning 与本次无关，建议后续单独清理（纯删多余 `!`）。

## 未提交（本次范围外，待分别验证）

工作区其余改动属其他功能，本次按「仅顶栏 4 处」范围未提交：
- 线索/客户编辑相关（`lead_constants` / `lead*.dart` / `edit_lead_dialog` / `edit_customer_dialog` / `customer_detail` / `customer_list_page` / `lead_service` 等）
- 日程负责人修复（`schedule_form_fields` / `schedule_form_sheet` 及对应计划文档）
- 相关计划文档（`PLAN_MANAGER_EDIT_SPLIT` / `PLAN_SCHEDULE_OWNER_FIX` / `LEAD_CUSTOMER_EDIT_API`）
