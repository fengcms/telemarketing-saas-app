# 日程详情页 / 表单 开发计划与记录（v0.13 + v0.14）

> 日期：2026-07-24
> 对应设计文档：`docs/design/page-design/11-日程详情.md`、`docs/design/page-design/12-新建-编辑日程.md`
> 范围：v0.13 落地详情页（doc 11）+ 列表项操作 + 新建/编辑表单（doc 12）；v0.14 四项 UX/性能打磨
> 计划文档：`docs/dev/PLAN_11_12_SCHEDULE.md`、`docs/dev/PLAN_14_SCHEDULE_POLISH.md`

---

## 一、v0.13 决策确认（用户拍板）

| 决策 | 内容 |
|------|------|
| **范围** | doc 11 详情页 + doc 12 新建/编辑表单**一起做**（不拆回合） |
| **拨号行为** | 详情页「拨号」**仅调起拨号盘**（复用 `handleDial`），拨号返回后弹反馈面板留待后续 |
| **标题策略** | 新建日程时把「线索姓名 + 手机号」写进标题（`🏷️ 姓名 - 手机号`），卡片不再单独展示该行（已在 v0.12 末尾执行） |

## 二、v0.13 接口核对结论

**当前接口完全满足设计文档，无需后端改动。**

| 设计需求（doc 11/12） | api.md 现状 | 结论 |
|------|------|------|
| 详情 `GET /api/tenant/schedules/:id` | §1474 | ✅ `lead.phone` **不脱敏（明文）**；`lead` 仅 `{name, phone}`（无 project/id） |
| 完成 / 取消 / 重开 | §1490+ | ✅ `POST .../:id/complete` / `/cancel` / `/reopen` |
| 删除 | §1506 | ✅ `DELETE .../:id` |
| 编辑 `PATCH .../:id` | §1518 | ✅ body 支持 `scheduledAt` / `title` / `content` |
| 新建 `POST /api/tenant/schedules` | §1528 | ✅ body 支持 `leadId` / `scheduledAt` / `title` / `content` / `userId` / `callRecordId` |
| 归属映射 `options/users` | §729 | ✅ `OptionsCacheService.getUserName(id)` 复用（含兜底返回 id） |

> ⚠️ **api.md §1474 示例里 `138****1234` 为过时脱敏示例**，以"明文电话"为准；doc 11 §6.1 的同款示例亦过时。

## 三、v0.13 实现要点

### 1. 数据层（新增 / 改）
- `lib/models/schedule_detail.dart`：`ScheduleDetail`（全字段）+ `LeadSnapshot{name, phone}` + `CallSummary{id, answerType, duration, startedAt}`；`isOverdue(serverTime)`、`scheduledDisplay`（年月日时分星期）、静态 `formatTs(ts)`（YYYY-MM-DD HH:mm）。
- `lib/services/schedule_service.dart` 新增 7 个方法：
  - `fetchScheduleDetail(id)` → `ScheduleDetail.fromJson`
  - `completeSchedule/cancelSchedule/reopenSchedule(id)` → 私有 `_postAction(id, action)` 封装 `POST .../:id/$action`
  - `deleteSchedule(id)` → `DELETE .../:id`
  - `patchSchedule(id, {scheduledAt, title, content})` → `PATCH .../:id`
  - `createSchedule({leadId, scheduledAt, title, content, userId, callRecordId})` → `POST ApiConstants.schedules`
- `lib/services/lead_service.dart`：删除已无调用方的旧 `createSchedule(...)`（旧抽屉专属）。
- `lib/services/options_cache_service.dart`：新增 `getUsers()`（供 TM/TA 指派归属人）。

### 2. 详情页（新增 `schedule_detail_page.dart`）
- 状态：`_detail` / `_ownerName` / `_isLoading` / `_errorCode` / `_errorMessage` / `_actionLoading` / `_isDeleting`。
- 顶栏：返回 + "日程详情" + `PopupMenuButton`（编辑/删除按 `_canEdit` / `_canDelete` 显隐，皆无则隐藏整个图标）。
- 主体：`CustomScrollView` 五区块——标题 + 状态标签 / 计划时间卡（逾期红字 + 标签）/ 关联线索卡（tap → `LeadDetailPage`，`lead==null` 显"该线索已被删除"且不可点、不渲染拨号）/ 内容卡（空显"暂无内容"）/ 其他信息卡（创建人 / 归属人 / 更新时间）。
- 底部操作栏：`_pendingActions`（取消 / 📞 / ✅ 标记完成，拨号仅 `lead!=null`）/ `_doneActions`（🔄 重新打开）。
- 操作：`_onComplete / _onCancel`（确认弹窗）/ `_onReopen / _onDelete`（确认弹窗 + 全屏 loading → 返回列表并刷新）/ `_onDial`（走 `handleDial`）。
- 权限矩阵：编辑 `userId==当前用户.id || role∈{TM,TA}`；删除 `userId==当前用户.id || role==TA`。
- 加载失败态区分 404 / 403 / 通用。

### 3. 表单页（v0.13 为全屏页，v0.14 已改成抽屉，见第四节）
- 命名构造：`ScheduleFormPage.create({leadId, leadName, leadPhone, prefillContent})` / `ScheduleFormPage.edit({scheduleId, initial})`。
- 创建模式：计划时间默认 `now+1h`（分钟取整 5），标题预填 `🏷️ $name - $phone`；TM/TA 可指派归属人（`getUsers()`），否则默认当前用户。
- 编辑模式：从 `initial` 回填；`patchSchedule` 无变更则 Toast "内容未变更"。
- 日期/时间选择复用 `TDPicker.showDatePicker`（`onConfirm` 为 `Map<String,int>` + 手动 `pop`，坑见 PITFALLS）。

### 4. 接线
- `schedule_list_page.dart`：卡片点击 → `Navigator.push(ScheduleDetailPage(scheduleId:))`（去掉 `ComingSoonPage`）。
- `lead_action_bar.dart`：「预约」按钮 → `Navigator.push(ScheduleFormPage.create(...))`（原 `schedule_dialog` 抽屉删除）。
- 删除 `lib/pages/leads/widgets/schedule_dialog.dart`。

## 四、v0.14 四项打磨（用户实测基础可用后提出）

| # | 优化 | 实现 |
|---|------|------|
| 1 | **风格统一** | `_card` 底色由灰改白 `Colors.white`，灰背景 `0xFFF3F3F3` 透出 8px 板块间隔，对齐线索详情（`LeadHeaderSection` 白底）；标题块也套 `_card` |
| 2 | **详情缓存** | 新增 `lib/services/schedule_detail_cache.dart`（`ScheduleDetailCache`，严格照 `LeadDetailCache`：get/put/invalidate/invalidateAll + 10 分钟 TTL，纯内存）；`schedule_stats_provider.dart` 注册 `scheduleDetailCacheProvider`。详情页 `_load({force})` 改缓存优先（命中秒开 + 后台静默刷新；有数据时后台刷新失败不覆盖）；写操作（完成/取消/重开/删除/编辑保存）后 `invalidate` 再拉取 |
| 3 | **底部按钮统一** | 取消 / 拨号 / 标记完成 改为等宽一排 `TDButton`（round 形状）：取消=light、拨号=light+图标、完成=primary（保留主次层级，用户确认此方案） |
| 4 | **恢复抽屉 + 公共组件** | 删除全屏 `schedule_form_page.dart`；新建 `lib/pages/schedules/widgets/schedule_form_sheet.dart`（`ScheduleFormContent` 承载表单逻辑 + 抽屉头部拖动把手 / 标题 / 关闭× + 底部取消保存；`showScheduleFormSheet(...)` 用 `showModalBottomSheet(isScrollControlled, maxHeight 0.92sh)` 包裹，返回 `bool?`）。线索详情「日程」与详情页「编辑」**两处共用**；创建成功额外 `leadDetailProvider.refreshBundle()` 刷新线索下日程区 |

## 五、校验

- `flutter analyze`：**No issues found**（全量 0 issue，v0.13 修 35 处、v0.14 修 2 处）
- **启动崩溃修复（重要）**：用计划命令 `flutter build apk --dart-define=DEV_TOOLS=true --release` 构建后，真机启动即红屏崩溃。根因不在 v0.13/v0.14 代码，而是 `app.dart` 的 DEV_TOOLS 浮标按钮：首帧 `MediaQuery.size` 为 0，`clamp(0, screen.width - _size)` 上界变负 → `ArgumentError(0.0)`。修法：4 处 clamp 上界用 `max(0, …)` 兜底（加 `import 'dart:math'`）。重构建 + 重装后 logcat 仅 Impeller 提示，**无 error / 无 fatal / 启动正常**。
- ✅ **真机实测通过（2026-07-24，Redmi K60 / 3e06fd6d）**：
  - 列表 → 详情（计划时间 / 逾期红字 / 关联线索跳转 / 内容 / 归属人映射）
  - 详情操作：标记完成 / 取消 / 重新打开 / 删除（带确认弹窗）
  - 详情页 ⋮ → 编辑（回填 + 改期 / 标题 / 内容）
  - 线索详情「预约」→ 新建日程（标题预填「🏷️ 姓名 - 手机号」）
  - v0.14 四项：白卡片观感对齐线索详情 / 10 分钟内再进秒开 / 底部按钮统一 / 两处抽屉一致且键盘不挡底部按钮

## 六、最终文件清单（v0.13 + v0.14 合批）

| 文件 | 动作 |
|------|------|
| `lib/models/schedule_detail.dart` | 新增 |
| `lib/services/schedule_detail_cache.dart` | 新增（v0.14） |
| `lib/pages/schedules/schedule_detail_page.dart` | 新增（v0.14 改白卡片/缓存/按钮） |
| `lib/pages/schedules/widgets/schedule_form_sheet.dart` | 新增（v0.14，取代全屏表单页） |
| `lib/services/schedule_service.dart` | 改（7 个详情/写方法） |
| `lib/providers/schedule_stats_provider.dart` | 改（`scheduleServiceProvider` + `scheduleDetailCacheProvider`） |
| `lib/services/options_cache_service.dart` | 改（`getUsers`） |
| `lib/services/lead_service.dart` | 改（删旧 `createSchedule`） |
| `lib/pages/schedules/schedule_list_page.dart` | 改（卡片点击进详情） |
| `lib/pages/leads/widgets/lead_action_bar.dart` | 改（「预约」接抽屉） |
| `lib/app.dart` | 改（DEV_TOOLS 浮标 clamp 启动崩溃修复） |
| `lib/pages/leads/widgets/schedule_dialog.dart` | 删除 |
| `lib/pages/schedules/schedule_form_page.dart` | 删除（v0.14 被抽屉取代） |

## 七、踩坑追加记录

### 7.1 tdesign 0.2.7 无 `TDButtonTheme.secondary` / `.text`
- `TDButtonTheme` 仅 `defaultTheme / primary / danger / light` 四值；原详情页用 `.secondary` / `.text` 编译报错。取消按钮改用 `light`，拨号图标按钮改原生 `IconButton`（v0.14 又统一为 `TDButton` light+图标）。

### 7.2 模型静态方法作用域 + Map 泛型
- `schedule_detail.dart` 原把 `_toInt` / `_toIntOrNull` 写成 `ScheduleDetail` 的静态方法，但 `CallSummary.fromJson` / `LeadSnapshot.fromJson` 是独立类工厂方法，无法访问 → 改为**库级顶层函数**；`lead/call` 的 `Map` cast 显式标注 `Map<String,dynamic>?`。

### 7.3 DEV_TOOLS 浮标首帧 clamp 致启动崩溃
- 见第五节。根因：首帧 `MediaQuery.size=0` 时 `clamp(0, width-_size)` 上界为负 → `ArgumentError`。所有 `clamp` 上界用 `max(0, …)` 兜底。

### 7.4 详情缓存优先模式（复用 LeadDetailCache 范式）
- 进入详情先读 `ScheduleDetailCache`，命中即秒开 + 后台静默刷新；写操作后 `invalidate`（10 分钟 TTL，纯内存）；后台刷新失败且有旧数据时**不覆盖**错误态。该模式与线索详情 `LeadDetailCache` 完全对齐，便于后续维护。

### 7.5 `showModalBottomSheet` 满屏抽屉
- 表单抽屉用 `showModalBottomSheet(isScrollControlled: true, …)` + 容器 `maxHeight: MediaQuery.sizeOf(context).height * 0.92`，键盘弹起时底部「取消/保存」按钮不被遮挡（配合 `Scaffold.resizeToAvoidBottomInset`）。

---

## 八、遗留项补齐记录（v0.15d，2026-07-24）

### 8.1 拨号反馈面板 → 改为底部操作栏
- 原计划「拨号返回弹快捷备注面板」已取消。
- 改为在**日程详情页**的信息卡片（创建时间/更新时间/归属人）下方，新增排操作按钮：跟进 / 日程 / 编辑（白卡片，对齐 `LeadActionBar` 风格）。
- 跟进 → `showFollowUpPanel`；日程 → `showScheduleFormSheet`（创建）；编辑 → `_onEdit()`（含权限检查）。
- 右上角 ⋮ 菜单中「编辑」同步移除（`448c702` / `871f864`）。

### 8.2 详情页下拉刷新
- `_buildBody()` 中 `CustomScrollView` 外套 `RefreshIndicator`，`onRefresh` → `_load(force: true)`（失效缓存 + 从服务器重拉）。
- 要点：骨架屏期间不显示 RefreshIndicator（直接返回骨架屏，不套 RefreshIndicator）。

### 8.3 团队统计视图
- `ScheduleStatsNotifier.load()` 中检查用户角色：TA/TM 优先尝试 `fetchTeamScheduleStats`（`GET /api/tenant/schedules/stats`）。
- 接口不可用时（catch）静默降级为 `fetchMyScheduleStats`（`GET /schedules/stats/mine`）。
- 其他角色始终取 mine。`api.md` 中无 `/schedules/stats` 文档，故加降级保底。
- 代码提交：`d4f2e82`（三项功能合集）、`448c702`（移正底部按钮位置）、`871f864`（去菜单编辑）。
- `flutter analyze`：全仓 0 issues；release+DEV_TOOLS 构建成功（56.8MB），卸载重装 Redmi K60 启动无崩溃。
