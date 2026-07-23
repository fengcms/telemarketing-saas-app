# 开发计划：05-线索详情页

> 设计文档：`docs/design/page-design/05-线索详情.md`  
> 接口文档：`docs/api.md`  
> 预计工时：5 个节点，各 0.5~1d

---

## 节点拆分

| 节点 | 内容 | 预计 |
|:----:|------|:----:|
| **Node 1** | 数据层：Model + Service + Provider | 0.5d |
| **Node 2** | 页面骨架 + 头部信息区 + 操作按钮 | 1d |
| **Node 3** | 跟进时间线（Section C） | 1d |
| **Node 4** | 通话记录摘要 + 底部导航条 | 1d |
| **Node 5** | 全部弹窗/面板交互 | 1d |

---

## Node 1 — 数据层

### 涉及接口

| # | 端点 | 方法 | 用途 |
|---|------|------|------|
| 1 | `GET /api/tenant/leads/:id` | GET | 线索详情 |
| 2 | `GET /api/tenant/leads/:id/followups` | GET | 跟进时间线（全量，不分页） |
| 3 | `GET /api/tenant/calls?leadId=&size=N` | GET | 通话记录（摘要 size=3 / 全部 size=20） |
| 4 | `PATCH /api/tenant/leads/:id` | PATCH | 编辑线索（categoryId, status） |
| 5 | `POST /api/tenant/leads/:id/followups` | POST | 创建跟进记录 |
| 6 | `PATCH /api/tenant/leads/:id/followups/:fid` | PATCH | 编辑跟进记录（仅 content） |
| 7 | `DELETE /api/tenant/leads/:id/followups/:fid` | DELETE | 删除跟进记录 |
| 8 | `POST /api/tenant/schedules` | POST | 新建日程（预约跟进） |
| 9 | `PATCH /api/tenant/calls/:id` | PATCH | 补正通话记录（TM/TA） |

### 新增/修改文件

| 文件 | 说明 |
|------|------|
| `lib/models/lead_detail.dart` | 🆕 线索详情模型（含 project/owner 内嵌对象） |
| `lib/models/follow_up_record.dart` | 🆕 跟进记录模型 |
| `lib/models/call_record.dart` | 🆕 通话记录模型 |
| `lib/services/lead_service.dart` | ✅ 修改：新增 detail/followups/calls/update/schedule/callCorrect 方法 |
| `lib/services/api_constants.dart` | ✅ 修改：新增 calls/patchFollowup/deleteFollowup/schedules 端点常量 |
| `lib/providers/lead_detail_provider.dart` | 🆕 线索详情状态管理 |
| `lib/providers/lead_list_provider.dart` | ✅ 修改：新增 listContext 支持（用于导航条） |

---

## Node 2 — 页面骨架 + 头部 + 操作区

### UI 区域

- `LeadDetailPage` — `CustomScrollView` + `SliverAppBar` 可折叠 TDNavBar
- Section A：姓名（脱敏）、状态 TDTag、分类 TDTag、电话号码（3-4-4 分段）、详细信息（公司/职位/归属）
- Section B：4 个操作按钮（拨号/跟进/预约/编辑），TDButton(text) 竖向布局
- TDSkeleton 首屏加载态
- 异常态处理（404 线索已删除 / 网络错误 + 重试）

### 新增文件

| 文件 | 说明 |
|------|------|
| `lib/pages/leads/lead_detail_page.dart` | 🆕 线索详情页 |
| `lib/pages/leads/widgets/lead_header_section.dart` | 🆕 头部信息区组件 |
| `lib/pages/leads/widgets/lead_action_bar.dart` | 🆕 操作按钮区组件 |

---

## Node 3 — 跟进时间线（Section C）

### UI 区域

- 时间线标题 + 总计数
- 圆点+连线布局（已接听=实心 brand-7，未接听=空心 gray-4，最新=加大 16px）
- 单条跟进卡片（时间/跟进人/接听类型标签/时长/内容/分类变更）
- 编辑/删除按钮（TE：本人+≤5分钟；TM/TA：全部）
- 加载更多（从全量数据中本地切片）
- 空态 TDEmpty

### 新增文件

| 文件 | 说明 |
|------|------|
| `lib/pages/leads/widgets/follow_up_timeline.dart` | 🆕 跟进时间线组件 |
| `lib/pages/leads/widgets/follow_up_card.dart` | 🆕 单条跟进卡片 |

---

## Node 4 — 通话记录摘要 + 底部导航条

### UI 区域

- Section D：标题"最近通话" + "查看全部" 跳转
- 3 条通话记录行（图标 + 时间 + 接听类型 + 时长 + 补正按钮（TM/TA））
- 底部线索切换导航条（上一个/计数/下一个，仅 listContext 存在时显示）
- 预加载 + 异常跳过

### 新增/修改文件

| 文件 | 说明 |
|------|------|
| `lib/pages/leads/widgets/call_records_section.dart` | 🆕 通话记录摘要组件 |
| `lib/pages/leads/widgets/lead_bottom_nav.dart` | 🆕 底部导航条组件 |

---

## Node 5 — 全部弹窗/面板交互

节点 5 按功能拆分为 3 个子节点：

| 子节点 | 内容 | 预计 |
|:------:|------|:----:|
| **5a** | 跟进面板 + 编辑跟进弹窗 | 0.5d |
| **5b** | 预约弹窗 + 编辑线索弹窗 + 拨号流程 | 0.5d |
| **5c** | 通话补正弹窗 + 删除确认弹窗 + 夜间禁呼弹窗 | 0.5d |

### 弹窗清单

| # | 弹窗 | 子节点 | 触发 | 说明 |
|---|------|:------:|------|------|
| 1 | 跟进面板 TDPopup | **5a** | 点击"跟进"按钮 | 内容+接听类型+时长+分类（可选），底部弹出 |
| 2 | 编辑跟进记录弹窗 TDDialog | **5a** | 跟进卡片"编辑" | 仅 content |
| 3 | 预约弹窗 TDDialog | **5b** | 点击"预约"按钮 | 日期+时间+备注 |
| 4 | 编辑线索弹窗 TDDialog | **5b** | 点击"编辑"按钮 | 分类+状态下拉 |
| 5 | 拨号流程 | **5b** | 点击"拨号"按钮 | url_launcher + 夜间禁呼校验 |
| 6 | 通话补正弹窗 TDDialog | **5c** | 通话记录"补正" | 接听类型+时长+结束时间（TM/TA） |
| 7 | 删除确认弹窗 TDDialog | **5c** | 跟进卡片"删除" | 确认/取消 |
| 8 | 夜间禁呼弹窗 TDDialog | **5c** | 点击拨号且禁呼时段 | 继续/取消 |

### Node 5a — 跟进面板 + 编辑跟进弹窗

#### 新增文件

| 文件 | 说明 |
|------|------|
| `lib/pages/leads/widgets/follow_up_panel.dart` | 跟进面板（TDPopup）：TDTextarea 内容+TDCheckTag 5选1+通话时长+分类修改+提交按钮 |
| `lib/pages/leads/widgets/edit_follow_up_dialog.dart` | 编辑跟进弹窗（TDDialog）：预填内容+TDTextarea+保存 |

#### 修改文件

| 文件 | 说明 |
|------|------|
| `lib/pages/leads/lead_detail_page.dart` | 接入跟进面板、刷新回调 |
| `lib/pages/leads/widgets/lead_action_bar.dart` | "跟进"按钮连接跟进面板 |

#### 涉及接口

| 端点 | 方法 | 用途 |
|------|------|------|
| `POST /api/tenant/leads/:id/followups` | POST | 创建跟进记录 |
| `PATCH /api/tenant/leads/:id/followups/:fid` | PATCH | 编辑跟进记录 |

### Node 5b — 预约 + 编辑线索 + 拨号

#### 新增文件

| 文件 | 说明 |
|------|------|
| `lib/pages/leads/widgets/schedule_dialog.dart` | 预约弹窗（日期选择器+时间选择器+备注+校验） |
| `lib/pages/leads/widgets/edit_lead_dialog.dart` | 编辑线索弹窗（分类+状态下拉，TE前向流转限制） |

#### 修改文件

| 文件 | 说明 |
|------|------|
| `lib/pages/leads/lead_detail_page.dart` | 接入预约/编辑弹窗、刷新回调 |
| `lib/pages/leads/widgets/lead_action_bar.dart` | "预约"和"编辑"按钮连接弹窗 |
| `pubspec.yaml` | 添加 url_launcher 依赖 |

#### 涉及接口

| 端点 | 方法 | 用途 |
|------|------|------|
| `POST /api/tenant/schedules` | POST | 新建日程（预约跟进） |
| `PATCH /api/tenant/leads/:id` | PATCH | 编辑线索 |

### Node 5c — 补正 + 删除 + 夜间禁呼

#### 新增文件

| 文件 | 说明 |
|------|------|
| `lib/pages/leads/widgets/correct_call_dialog.dart` | 通话补正弹窗（接听类型+时长+结束时间） |
| `lib/pages/leads/widgets/delete_confirm_dialog.dart` | 删除确认弹窗 |
| `lib/pages/leads/widgets/night_call_dialog.dart` | 夜间禁呼确认弹窗 |

#### 修改文件

| 文件 | 说明 |
|------|------|
| `lib/pages/leads/widgets/call_records_section.dart` | "补正"按钮连接弹窗 |
| `lib/pages/leads/widgets/follow_up_card.dart` | "删除"按钮连接弹窗 |
| `lib/providers/lead_detail_provider.dart` | 新增 deleteFollowUp / correctCall 操作方法 |
| `lib/pages/leads/lead_detail_page.dart` | 连接各回调 |

#### 涉及接口

| 端点 | 方法 | 用途 |
|------|------|------|
| `PATCH /api/tenant/calls/:id` | PATCH | 补正通话记录（TM/TA） |
| `DELETE /api/tenant/leads/:id/followups/:fid` | DELETE | 删除跟进记录 |
