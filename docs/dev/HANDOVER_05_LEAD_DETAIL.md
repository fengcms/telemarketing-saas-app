# 线索详情页 — 交接文档

> 设计文档：`docs/design/page-design/05-线索详情.md`  
> 接口文档：`docs/api.md`  
> 开发计划：`docs/dev/PLAN_05_LEAD_DETAIL.md`  
> 日期：2026-07-23

---

## 一、已完成功能

### 数据层（Node 1）
- [x] `LeadDetail` 模型（`lead_detail.dart`）
- [x] `FollowUpRecord` 模型（`follow_up_record.dart`）
- [x] `CallRecord` 模型（`call_record.dart`）
- [x] `LeadListContext` 模型（`lead_list_context.dart`）— 底部导航条上下文
- [x] `lead_service.dart` — 8 个方法（详情/跟进列表/通话列表/编辑线索/创建跟进/编辑跟进/删除跟进/创建日程/补正通话）
- [x] `LeadDetailProvider` 状态管理 — 3 个并行请求、底部导航切换、局部刷新

### 页面骨架 + 头部 + 操作按钮（Node 2）
- [x] `LeadDetailPage` — TDNavBar + CustomScrollView 布局
- [x] `LeadHeaderSection` — 姓名、状态标签、分类标签、电话号码（3-4-4 / 脱敏格式）、详细信息
- [x] `LeadActionBar` — 拨号/跟进/预约/编辑 4 按钮
- [x] 骨架屏加载态（`_buildSkeleton`）
- [x] 错误态（线索已删除/404）

### 跟进时间线（Node 3）
- [x] `FollowUpTimeline` — 圆点+连线布局、加载更多（本地切片）
- [x] `FollowUpCard` — 时间/跟进人/接听类型标签+时长/内容/分类变更/编辑删除按钮
- [x] 编辑/删除按钮可见性计算（TE=本人+≤5min；TM/TA=全部）
- [x] 跟进人姓名通过 `userNameProvider` 解析
- [x] 分类名称通过 `categoryNameProvider` 解析

### 通话记录 + 底部导航（Node 4）
- [x] `CallRecordsSection` — 标题"最近通话"+"查看全部"、3 行记录、补正按钮（TM/TA）
- [x] `LeadBottomNav` — 上一个/计数/下一个、禁用态样式

### 弹窗/面板（Node 5）
- [x] `FollowUpPanel`（底部弹出）：内容输入+5选1接听类型+通话时长+分类+提交
- [x] `EditFollowUpDialog`：编辑跟进内容
- [x] `ScheduleDialog`：日期时间选择+备注+校验
- [x] `EditLeadDialog`：分类+状态下拉（TE 前向流转限制）
- [x] `CorrectCallDialog`（TM/TA）：接听类型+通话时长补正
- [x] `DeleteConfirmDialog`：删除确认
- [x] `DialHelper`：夜间禁呼检查+拨号盘（url_launcher）

### 新增 Provider
- [x] `categoryNameProvider(id)` — 分类 UUID → 分类名称
- [x] `userNameProvider(id)` — 用户 UUID → 用户姓名

---

## 二、未完成 / 待优化项

### 🔴 P0 — 功能缺失

| # | 问题 | 位置 | 说明 |
|---|------|------|------|
| 1 | 通话反馈面板未接入 | `lead_header_section.dart` / `lead_action_bar.dart` | 拨号返回后，设计文档要求弹出通话结果反馈面板（07-通话结果反馈面板.md），当前拨号后无任何反应 |
| 2 | 拨号后自动弹出反馈面板回调 | `lead_detail_page.dart` | 需要监听 AppLifecycle（onResume），拨号返回后自动弹出反馈面板 |
| 3 | "查看全部"通话记录跳转 | `call_records_section.dart:77` | 点击"查看全部"应跳转至 `/lead/:id/calls` 页面，当前只有 TODO 注释 |
| 4 | 跟进面板分类选择器未接入 | `follow_up_panel.dart:307` | 分类下拉选择器只有 UI 占位，没有接入 `OptionsCacheService` 加载分类列表 |
| 5 | 夜间禁呼时段配置读取 | `lead_action_bar.dart:75` | 夜间禁呼时段应从 `GET /api/tenant/profile` 的 `noCallWindow` 读取并传入 `handleDial` |

### 🟡 P1 — UI/UX 问题

| # | 问题 | 位置 | 说明 |
|---|------|------|------|
| 6 | 跟进卡片底部圆点连线高度固定 | `follow_up_timeline.dart` | `_buildTimelineItem` 中连线高度写死 120px，应根据卡片实际高度自适应 |
| 7 | TDButton 竖向布局按钮文字异常 | `lead_action_bar.dart` | 设计文档要求图标在上、文字在下竖向布局，当前 TDButton 不支持全自定义 |
| 8 | 跟进面板接听类型选中色 | `follow_up_panel.dart` | 设计文档要求 TDCheckTag 样式（选中 brand-7 背景白色文字），当前虽然实现了但未使用 TDesign 官方组件 |
| 9 | 操作栏分割线 | `lead_detail_page.dart` | 操作栏上方应有 TDDivider 0.5px 分割线，当前放在 `_buildActionBar` 的 Container border 中 |
| 10 | "补正"弹窗缺少结束时间 | `correct_call_dialog.dart` | 设计文档要求可选输入结束时间（TDDatePicker），当前未实现 |
| 11 | 跟进面板缺少"提交失败"错误提示位置 | `follow_up_panel.dart` | 设计文档要求校验不通过时字段下方显示红色错误提示，当前只用了 TDToast |
| 12 | 跟进面板文本内容 maxLength 限制 | `follow_up_panel.dart` | TDTextarea 未设置最大字节限制，虽然计数器显示 0/2000 |

### 🟢 P2 — 优化项

| # | 问题 | 位置 | 说明 |
|---|------|------|------|
| 13 | `listContext.skipRemoved` 未调用 | `lead_detail_provider.dart` | 底部导航切换时 404/403 自动跳过逻辑已实现方法但未被使用 |
| 14 | 预加载策略 | `lead_detail_provider.dart` | 设计文档要求在底部导航切换时预加载下一条数据 |
| 15 | 反馈提交后"查看下一个"提示条 | `lead_detail_page.dart` | 设计文档要求在反馈提交成功后显示临时提示条"查看下一个" |
| 16 | 拨号返回时更新列表状态 | `lead_detail_page.dart` | 拨号返回后应刷新跟进时间线和通话记录摘要 |
| 17 | 骨架屏缺乏动画 | `lead_detail_page.dart` | 设计文档要求从左到右 shimmer 动画，当前为静态灰色块 |

---

## 三、API 注意事项

### 真实 API 与设计文档差异

| 差异点 | 设计文档 | 真实 API |
|--------|---------|---------|
| 详情数据路径 | `data` 直接包含字段 | `data.lead` 嵌套对象 |
| 跟进记录 | 独立接口 `GET /followups` | 既可在详情 `data.followups` 获取，也有独立接口 |
| 分类/项目/归属 | `category`, `project: {id,name}`, `owner: {id,name}` | `categoryId`, `projectId`, `ownerId` 扁平 UUID |
| 响应字段 | 使用 int ID | 使用 UUID 字符串 |

### 已处理
- `LeadService.fetchLeadDetail` 已兼容 `data.lead` 嵌套格式
- `categoryNameProvider` / `userNameProvider` 通过 `OptionsCacheService` 解析 UUID → 显示名

---

## 四、文件清单

### 新增文件（18 个）

```
lib/
├── models/
│   ├── lead_detail.dart             线索详情模型
│   ├── follow_up_record.dart        跟进记录模型
│   ├── call_record.dart             通话记录模型
│   └── lead_list_context.dart       列表上下文模型
├── providers/
│   └── lead_detail_provider.dart    线索详情状态管理
└── pages/leads/
    ├── lead_detail_page.dart        线索详情页
    └── widgets/
        ├── lead_header_section.dart   头部信息区
        ├── lead_action_bar.dart       操作按钮区
        ├── follow_up_timeline.dart    跟进时间线
        ├── follow_up_card.dart        跟进卡片
        ├── call_records_section.dart  通话记录摘要
        ├── lead_bottom_nav.dart       底部导航条
        ├── follow_up_panel.dart       跟进面板（底部弹出）
        ├── schedule_dialog.dart       预约弹窗
        ├── edit_lead_dialog.dart      编辑线索弹窗
        ├── edit_follow_up_dialog.dart 编辑跟进弹窗
        ├── correct_call_dialog.dart   通话补正弹窗（TM/TA）
        ├── delete_confirm_dialog.dart 删除确认弹窗
        └── dial_helper.dart           拨号辅助工具
```

### 修改文件（6 个）

```
lib/services/api_constants.dart         新增 calls 端点
lib/services/lead_service.dart          新增 8 个 API 方法
lib/constants/lead_constants.dart       新增 answerTypeLabels
lib/providers/options_provider.dart     新增 categoryNameProvider, userNameProvider
lib/pages/leads/leads_list_page.dart    卡片点击跳转详情页
pubspec.yaml                            添加 url_launcher 依赖
```
