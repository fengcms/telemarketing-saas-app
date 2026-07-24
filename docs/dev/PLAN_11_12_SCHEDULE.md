# 开发计划：日程详情页（doc 11）+ 新建/编辑日程表单页（doc 12）

> 版本：v0.13 | 制定日期：2026-07-24 | 平台：Flutter
> 设计文档：[11-日程详情](../../design/page-design/11-日程详情.md)、[12-新建日程](../../design/page-design/12-新建日程.md)
> 接口契约：[api.md](../../api.md) § GET/POST/PATCH/DELETE /api/tenant/schedules/...

---

## 1. 范围确认（已与用户确认）

| 决策点 | 结论 |
|--------|------|
| 本次范围 | **doc 11 + doc 12 一起做**（详情页 + 全屏表单页），契合 v0.13 里程碑；列表卡片→详情→编辑出口齐全 |
| 拨号行为 | **仅调起拨号盘**（复用 `handleDial`，含夜间禁呼判断），拨号返回后弹"通话反馈面板"留待后续回合 |
| 表单形态 | 采用 doc 12 的**全屏 Push 页**（产品决策：不沿用旧的 BottomSheet 抽屉）；旧 `schedule_dialog.dart` 删除 |

## 2. 接口契约（取自 api.md，已核对无歧义）

- `GET /api/tenant/schedules/:id` → 详情（含 `lead{name,phone}` 快照 + `call` 摘要）
  - **关键**：`lead.phone` **不脱敏（明文）**，拨号可直接用。doc 11 §6.1 示例里的 `138****1234` 是过时示例，以 api.md 第 1474 行为准。
  - `lead` 仅 `{name, phone}`，**无 `project`/`id`** → 关联线索卡片的"🏠 项目"行不显示；跳线索详情用顶层 `leadId`。
  - 归属人只回 `userId`，"归属人"姓名用 `optionsCacheService.getUserName(id)` 本地映射（已有兜底）。
- `POST /:id/complete` / `POST /:id/cancel` / `POST /:id/reopen` → 改状态（body 空或 `{}`）
- `PATCH /:id` → 改 `scheduledAt`/`title`/`content`（至少传一个）
- `DELETE /:id` → 软删
- `POST /api/tenant/schedules` → 新建（`leadId`+`scheduledAt`+`title`+可选 `content`/`userId`/`callRecordId`）
- 错误码：403 `AUTH_FORBIDDEN`（无权限）、400 `VALIDATION`（状态不符/字段超限）、404 `NOT_FOUND`、500。

## 3. 复用资产（不重复造轮子）

| 资产 | 位置 | 用途 |
|------|------|------|
| `handleDial(phone, context)` | `pages/leads/widgets/dial_helper.dart` | 拨号按钮（夜间禁呼判断 + `tel:` 调起） |
| `optionsCacheService.getUserName(id)` | `services/options_cache_service.dart` | 详情页"归属人"姓名映射 |
| `TDPicker.showDatePicker(...)` 调用范式 | `pages/leads/widgets/schedule_dialog.dart`（已修好的 `Map<String,int>` 回调 + 手动 `pop`） | 表单页日期/时间选择器，**直接复用**，避免重踩 tdesign 0.2.7 回调类型坑 |
| 标题格式 `🏷️ 姓名 - 手机号` | `schedule_dialog.dart _submit` | 表单页 title 沿用此约定（用户 2026-07-24 决策：线索姓名/手机号写进标题） |
| `TDToast` / `TDButton` / `TDTextarea` | tdesign_flutter | 通用 UI |
| 列表页顶栏样式 | `schedule_list_page.dart`（品牌色 #0052D9、56dp） | 详情页顶栏对齐 |

## 4. 待开发文件清单

### 4.1 数据层
- **`lib/models/schedule_detail.dart`**（新）
  - `ScheduleDetail`：`id`/`tenantId`/`userId`/`leadId`/`callRecordId`/`title`/`content`/`scheduledAt`/`status`/`completedAt`/`createdAt`/`updatedAt`/`deletedAt`/`lead`/`call`
  - 嵌套 `LeadSnapshot {name, phone}`、`CallSummary {id, answerType, duration, startedAt}`
  - 辅助：`isOverdue(serverTime)`、计划时间中文展示（年月日 + 星期）、createdAt/updatedAt 格式化
- **`lib/services/schedule_service.dart`**（改）新增：
  - `fetchScheduleDetail(id)`
  - `completeSchedule(id)` / `cancelSchedule(id)` / `reopenSchedule(id)`
  - `patchSchedule(id, {scheduledAt?, title?, content?})`
  - `deleteSchedule(id)`
  - `createSchedule({leadId, scheduledAt, title, content?, userId?, callRecordId?})`（从 `lead_service.createSchedule` 收敛过来，签名一致 + 额外可选字段）
  - URL 拼 `${ApiConstants.schedules}/$id` 等（参考 `lead_service` 的 `calls/$id` 写法）
- **`lib/services/options_cache_service.dart`**（改）新增 `Future<List<OptionItem>> getUsers()`（供表单页归属人下拉）
- **`lib/services/lead_service.dart`**（改）删除已无调用方的 `createSchedule`（旧抽屉删后成为死代码）

### 4.2 页面层
- **`lib/pages/schedules/schedule_detail_page.dart`**（新，doc 11）
  - 顶栏：返回 + 标题"日程详情" + 右侧 `⋯` 菜单（编辑/删除，按权限显隐；两者皆无则隐藏整个图标）
  - 状态：加载骨架屏 / 错误重试 / 404"不存在或已删除" / 403"无权查看"
  - 区块：标题+状态标签 → 计划时间卡（逾期红字+标签） → 关联线索卡（tap→线索详情；`lead==null` 显"该线索已被删除"不可点、且不渲染拨号按钮） → 日程内容卡（空显"暂无内容"） → 其他信息卡（创建时间/归属人姓名/更新时间）
  - 底部操作栏（Sticky Footer，顶部分割线）：
    - pending（含逾期）：`[取消日程] [📞] [✅ 标记完成]`（拨号仅 `lead!=null` 渲染）
    - completed/cancelled：`[🔄 重新打开]`
  - 操作：完成/取消（确认弹窗）/重开 走接口后刷新详情；删除（确认弹窗 + 全屏 loading）→ 返回列表并触发列表刷新；拨号走 `handleDial`
- **`lib/pages/schedules/schedule_form_page.dart`**（新，doc 12）
  - 双模式：`create`（入参 `leadId`+可选 `leadName`/`leadPhone`/`prefillContent`）/ `edit`（入参 `scheduleId`+ 已加载 `ScheduleDetail` 回填）
  - 字段：关联线索（只读，从入参展示） / 计划时间（必填，复用 `TDPicker` 两级选择 + 快捷 chip） / 标题（可选，≤200） / 内容（可选，≤2000，入口 2 可预填） / 归属人（仅 TM/TA，`getUsers()` 下拉，默认当前用户）
  - 提交：create→`createSchedule`；edit→`patchSchedule`；loading 防重复；返回上一页并触发刷新
  - 取消/返回：有未保存内容→放弃确认弹窗
- **`lib/pages/schedules/schedule_list_page.dart`**（改）卡片 `onTap` 从 `ComingSoonPage` 改为 `Navigator.push(ScheduleDetailPage(scheduleId: s.id))`
- **`lib/pages/leads/widgets/lead_action_bar.dart`**（改）"预约"按钮从 `showScheduleDialog` 改为 `Navigator.push(ScheduleFormPage(leadId:, leadName:, leadPhone:))`；移除 `schedule_dialog.dart` 导入
- **`lib/pages/leads/widgets/schedule_dialog.dart`**（删）被全屏表单页取代

## 5. 权限矩阵实现（doc 11 §3.9）

当前用户取自 `authProvider` 的 `User(id, role)`：
- **编辑**显示条件：`userId == 当前用户.id` 或 `role ∈ {TM, TA}`
- **删除**显示条件：`userId == 当前用户.id` 或 `role == TA`
- 两者皆不满足 → 隐藏 `⋯` 图标
- 后端仍会对越权返回 403，前端 `catch` 后 `TDToast` 提示"无权…"

## 6. 已知限制 / 留待后续

- 拨号返回后**不弹**通话反馈面板（doc 11 §4.6 完整版），仅调起拨号盘；后续回合抽取 `lead_detail_page` 的 `WidgetsBindingObserver` 复用。
- 关联线索卡**不显示项目行**（后端 `lead` 未返回 `project`）。
- 表单页归属人下拉仅显示姓名（`OptionItem` 无 `role` 字段），角色辅助标识留待后续。
- 跨天分组重算机制（列表页已标记待开发）不在本回合。

## 7. 验证清单（真机）

- [ ] 列表点卡片进入详情，骨架屏→内容淡入
- [ ] pending 显 [取消][📞][完成]；overdue 时间红字+标签
- [ ] completed/cancelled 显 [重新打开]，标题变灰
- [ ] 归属人显示姓名（非 id）；线索卡 tap 跳线索详情；`lead==null` 显"已删除"不可点且无拨号键
- [ ] 完成/取消/重开 后状态与按钮随刷新更新；取消/删除有确认弹窗；删除后回列表并刷新
- [ ] 拨号键走 `handleDial`（非禁呼时段直接调起 `tel:`）
- [ ] 详情 ⋮ 编辑 → 进表单页回填，保存后详情更新；TM/TA 才见归属人下拉
- [ ] 线索详情"预约" → 全屏表单页，创建成功后返回并刷新；旧 BottomSheet 不再出现
- [ ] `flutter analyze` 零错误；无遗留 debug print/TODO
