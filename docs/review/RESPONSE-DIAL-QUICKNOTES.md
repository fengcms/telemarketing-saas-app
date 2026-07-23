# 拨号功能 + 快捷备注 + UI 优化 — 开发记录

## 一、拨号功能完整实现

### 1.1 Android 包可见性配置
- **文件**: `android/app/src/main/AndroidManifest.xml`
- 新增 `<queries>` 声明 `android.intent.action.DIAL`，解决 Android 11+ `url_launcher` 无法检测拨号盘的问题

### 1.2 系统拨号优化
- **文件**: `lib/pages/leads/widgets/dial_helper.dart`
- `launchUrl` 改用 `mode: LaunchMode.externalApplication`，确保拨号盘以独立任务启动，正确触发 App 生命周期回调

### 1.3 通话返回自动弹出跟进面板
- **文件**: `lib/pages/leads/lead_detail_page.dart`
- `_LeadDetailPageState` 添加 `WidgetsBindingObserver` 监听 `didChangeAppLifecycleState`
- 拨号时设置 `_recentlyDialed = true`，从拨号盘返回 App（`resumed`）后自动调用 `showFollowUpPanel`
- 兼容原始 4 按钮拨号（action bar）和头部大 FAB 拨号两种入口

### 1.4 操作按钮区重构
- **文件**: `lib/pages/leads/widgets/lead_action_bar.dart`
- 4 按钮（拨号/跟进/预约/编辑）→ **3 按钮（跟进/日程/编辑）**，拨号统一走头部大 FAB
- 布局从 `TDButton` 竖向（icon 在上 text 在下）改为横向 Row（icon + 6px + text 水平排列）
- 容器高度从 72px 压缩至 44px

### 1.5 头部拨号按钮回调
- **文件**: `lib/pages/leads/widgets/lead_header_section.dart`
- 头部大 FAB 新增 `onDial` 回调，拨号时通知页面设置 `_recentlyDialed` 标记

---

## 二、快捷备注

### 2.1 数据模型适配
- **文件**: `lib/models/option_item.dart`
- `OptionItem.fromJson` 新增 `content` 字段兜底（API 返回 `{id, content}` 而非 `{id, name}`）

### 2.2 API 端点配置
- **文件**: `lib/services/api_constants.dart`
- 新增 `optionsQuickNotes = '/api/tenant/options/quick-notes'`

### 2.3 缓存服务扩展
- **文件**: `lib/services/options_cache_service.dart`
- 新增 `_quickNotes` 列表 + `_keyQuickNotes` 缓存 key + `_fetchQuickNotes()` + `getQuickNotes()` 方法
- 快捷备注与其他选项（分类/项目/用户）**一次批量请求**，共用 30 分钟 TTL 缓存

### 2.4 跟进面板集成
- **文件**: `lib/pages/leads/widgets/follow_up_panel.dart`
- 文本框下方新增「快捷备注」标题 + `TagChipRow`（多行换行模式）
- 点击备注内容自动插入到文本框光标位置，已有内容时自动换行

---

## 三、变更统计

| 维度 | 数值 |
|------|------|
| 修改文件 | 12 个 |
| 新增/删除行 | +284 / -155 |
| `flutter analyze` | **0 issues** |

## 四、涉及文件清单

- `android/app/src/main/AndroidManifest.xml` — 包可见性声明
- `lib/models/option_item.dart` — content 字段兜底
- `lib/services/api_constants.dart` — quick-notes 端点
- `lib/services/options_cache_service.dart` — 快捷备注缓存
- `lib/pages/leads/lead_detail_page.dart` — onResume 自动弹面板、action bar 高度
- `lib/pages/leads/widgets/dial_helper.dart` — LaunchMode 优化
- `lib/pages/leads/widgets/follow_up_panel.dart` — 快捷备注 UI + 加载
- `lib/pages/leads/widgets/lead_action_bar.dart` — 3 按钮 + 横向布局
- `lib/pages/leads/widgets/lead_header_section.dart` — onDial 回调
