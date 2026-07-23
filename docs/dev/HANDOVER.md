# 电销工作台 APP — 项目交接文档

> 配套文档：`docs/dev/MILESTONES.md`（开发节点）、`docs/dev/STYLE_GUIDE.md`（编码规范）、
> `docs/dev/DEVELOPMENT_PITFALLS.md`（踩坑库）、`docs/dev/HANDOVER_05_LEAD_DETAIL.md`（线索详情单页交接）
> 设计文档：`docs/design/page-design/*.md`　接口文档：`docs/api.md`
> 文档版本：v1.0　更新日期：2026-07-23

---

## 一、项目概览

| 项 | 内容 |
|----|------|
| 项目名称 | 电销工作台 APP（telemarketing_app） |
| 定位 | 电销坐席移动端：线索浏览、拨号、跟进记录、日程管理 |
| 目标平台 | **仅 Android**（API 36 / Android 16），坐席统一安卓设备 |
| 技术栈 | Flutter 3.44.x + Dart 3.12 + TDesign Flutter 0.2.7 |
| 状态管理 | Riverpod 2.6（`StateNotifier` + `AsyncValue`/`State` 模式） |
| 网络层 | dio 5.7（拦截器：Token 注入 / 自动刷新 / 错误解析 / 423 强制改密） |
| 路由 | 当前以 `Navigator.push` 实现；`go_router` 已引入但**尚未接管路由** |
| 仓库性质 | **私有、单人维护**；`.workbuddy/` 有意纳入 git（见 §六约定） |

> 当前完成度：核心 P0 业务闭环（登录 → 首页看板 → 线索列表 → 线索详情 → 拨号 → 跟进）
> 已跑通并真机验证；P1 辅助页面（日程列表、客户、团队、统计等）多数仍为 ComingSoon 占位。

---

## 二、环境搭建（⚠️ 重点）

### 2.1 基础环境
- macOS + Flutter **3.44.x** + JDK **26** + Android SDK **36**（API 36）
- Android 真机调试：USB 连接，`adb` 位于 `~/Library/Android/sdk/platform-tools/`

### 2.2 ⚠️ 必须知道的本地补丁（不进 git！）

`tdesign_flutter 0.2.7` 与 Dart 3.12 存在兼容问题（`extends IconData` 报错），
**当前开发机已对 pub cache 打了本地 patch**。该 patch **不在仓库内、不随 git 提交**：

- 换机器 / 新克隆 / CI 重新 `flutter pub get` 会拉回**有问题的原版**，`flutter analyze` / 构建会失败。
- 处理办法：复用本机已 patch 的 pub cache，或重新对 `tdesign_flutter 0.2.7` 的 `IconData` 子类打相同补丁。
- `pubspec.yaml` 另有 `dependency_overrides: image_picker_android: 0.8.13+13`（修复 Android D8 嵌套类构建失败），此条**已进 git**，无需手动处理。

### 2.3 安装与运行
```bash
# 1. 取依赖（注意 §2.2 的 tdesign 补丁前提）
flutter pub get

# 2. 真机调试运行
flutter run --debug

# 3. 构建 debug APK（交付实测用）
flutter build apk --debug
# 产物：build/app/outputs/flutter-apk/app-debug.apk
# 安装到真机：
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# 4. 静态校验（项目硬指标：0 issue）
flutter analyze
```

### 2.4 测试环境
- 后端测试环境：`https://tm-api-test.kao9.com`
- 账号：由 TA 在后台创建，App 端用**邮箱 + 密码**登录
- 凭据持久化：邮箱明文存 `SharedPreferences`，密码加密存 `FlutterSecureStorage`（Android Keystore）

---

## 三、架构总览

### 3.1 分层结构
```
main.dart
 └─ ProviderScope
     └─ TelemarketingApp
         └─ AuthGate（登录守卫，按 AuthStatus 分流）
             ├─ 初始态      → CircularProgressIndicator
             ├─ 未登录      → LoginPage
             ├─ 强制改密    → ForceChangePasswordPage
             └─ 已登录      → MainShell（底部 4 Tab，IndexedStack 保持状态）
                                   ├─ 首页      → HomePage（看板）
                                   ├─ 线索      → LeadsListPage
                                   ├─ 日程      → ComingSoonPage（占位）
                                   └─ 我的      → 用户信息 + 退出登录
```

### 3.2 目录职责
| 目录 | 职责 |
|------|------|
| `lib/models/` | 数据模型（`LeadDetail` / `LeadDetailBundle` / `FollowUpRecord` / `CallRecord` / `Schedule` / `LeadListContext` / `User` / `HomeStats` / `OptionItem` / `Lead`） |
| `lib/services/` | 网络与存储：`ApiClient`（dio 封装）、`AuthService`、`LeadService`、`HomeService`、`OptionsCacheService`、`LeadDetailCache`、`TokenStorage`、`LocalStorageService` |
| `lib/providers/` | 状态管理：`AuthProvider`、`LeadListProvider`、`LeadDetailProvider`、`HomeProvider`、`OptionsProvider` |
| `lib/constants/` | 静态常量（如 `LeadConstants` 接听类型标签） |
| `lib/widgets/` | 跨页公共组件（如 `TagChip` / `TagChipRow` / `SheetHeader`） |
| `lib/pages/` | 页面与页内组件：`login/` `force_change_password/` `home/` `leads/` `coming_soon_page.dart` `main_shell.dart` |
| `lib/utils/` | 工具函数（如 `duration_format`） |

### 3.3 状态管理约定
- 列表 / 详情 / 首页分别由各自 `Provider` 持有 `State`，页面用 `ref.watch` 订阅、`ref.read(...).notifier.xxx()` 触发动作。
- 详情页采用**单请求聚合 + 内存缓存 + 预加载**模式（见 §四.2）。
- 下拉刷新、`WidgetsBindingObserver` 生命周期监听已在首页 / 详情页落地。

---

## 四、功能完成度

### 4.1 已完成（已真机验证）

| 模块 | 关键文件 | 说明 |
|------|---------|------|
| 登录页 | `pages/login/login_page.dart` | 邮箱（前缀+后缀选择器）、密码、记住凭据、登录 |
| 强制改密页 | `pages/force_change_password/*` | 423 拦截自动跳转、密码强度 8 段、双框校验、返回确认 |
| 认证与网络层 | `services/api_client.dart` `auth_service.dart` `providers/auth_provider.dart` | Token 注入/自动刷新/错误解析、安全存储、登录守卫 |
| 首页看板 | `pages/home/*` | 今日概况四宫格、待办日程、快捷入口、4 Tab 底部导航、离线检测、10 分钟轮询 |
| 线索列表 | `pages/leads/leads_list_page.dart` + `widgets/leads_*` | 搜索、排序、筛选、筛选标签浮层、线索卡片、无限滚动、下拉刷新 |
| 线索详情（含拨号） | `pages/leads/lead_detail_page.dart` + `widgets/*` | 头部/操作栏/跟进时间线/通话摘要/日程/底部导航/各弹窗（详见 §4.2） |
| 公共组件 | `widgets/tag_chip.dart` | `TagChip` / `TagChipRow`（Wrap 换行 / 横滚两种模式，全仓 9 处统一） |

### 4.2 线索详情页（核心页，已完成）

- **数据层（已重构）**：`GET /api/tenant/leads/:id` 一次返回 `lead + followups(全量) + calls(≤5) + schedules(≤5)`，
  由 `LeadDetailBundle`（`models/lead_detail_bundle.dart`）一次解析。
  - `LeadDetailCache`（`services/lead_detail_cache.dart`）内存缓存，10 分钟 TTL。
  - `LeadDetailProvider`：缓存命中即渲染 + 后台静默刷新 + **预加载下一条**；写操作后统一 `refreshBundle()`。
  - ⚠️ **已修复翻页竞态**：`_fetchBundle` 写回 UI 前加 `leadId == _currentLeadId` 守卫，避免后台刷新覆盖当前页（详见 `DEVELOPMENT_PITFALLS.md §8`）。
- **UI 板块**（自上而下）：头部信息 → 操作栏（跟进/日程/编辑）→ 最近日程 → 跟进记录 → 最近通话 → 底部导航。
- **拨号闭环**：`dial_helper.dart` 夜间禁呼检查 + 系统拨号盘；拨号返回经 `AppLifecycleState.resumed` 自动弹出跟进面板（`fromDial: true`）。
- **弹窗/面板**：`FollowUpPanel`（内容 + 接听类型 + 系统通话记录查询 + 分类 + 快捷备注）、`EditFollowUpDialog`、`ScheduleDialog`、`EditLeadDialog`、`CorrectCallDialog`（TM/TA）、`DeleteConfirmDialog`。

> 旧 `docs/dev/HANDOVER_05_LEAD_DETAIL.md` 中“3 个并行请求”“拨号后弹面板未做”等描述**已过时**，
> 以本交接文档与代码现状为准。

### 4.3 待开发 / 占位（P1 及以后）

| 设计文档 | 页面 | 现状 |
|---------|------|------|
| 10-日程列表 / 11-日程详情 | 日程列表页 | `ComingSoonPage` 占位；详情页“查看全部”无目标页 |
| 16-通话记录 | 通话记录列表页（`/lead/:id/calls`） | `ComingSoonPage` 占位；详情页“查看全部”无目标页 |
| 06-公海线索列表 | 公海线索池 | 未开发 |
| 17-客户列表 / 18-客户详情 | 客户模块 | 未开发 |
| 13-个人中心 / 14-个人统计 | 个人中心与统计 | “我的”Tab 仅含用户信息+退出，未完整开发 |
| 15-修改密码 | 修改密码页 | 未开发（与强制改密不同） |
| 19-设置页 | 设置页 | 未开发 |
| 20-团队入口 / 21-团队统计 / 22-团队日程 / 23-团队线索池 | 团队模块 | 均未开发 |

---

## 五、关键约定与已知坑

### 5.1 编码规范（强制）
- 每个 Dart 文件顶部加 `///` 文件说明；公开 / 重要私有方法加 `///` Dart Doc；注释用中文。
- 命名：`snake_case` 文件名、`PascalCase` 类名、`camelCase` 变量/方法（私有加 `_`）。
- 全仓 `flutter analyze` 必须 **0 issue**（当前达标）。

### 5.2 ⚠️ TDesign 兼容性（务必先读 §2.2）
1. `tdesign_flutter 0.2.7` Dart 3.12 不兼容（`IconData final class`）→ **本地 pub-cache patch，不进 git**。
2. `TDCheckbox` 在 Android 上导致**白屏** → 一律用 Material 原生复选框替代。
3. `image_picker_android` D8 嵌套类构建失败 → `dependency_overrides` 锁定 `0.8.13+13`（已进 git）。

### 5.3 API 对接要点
- **接口返回 ID 而非名称**：`categoryId` / `projectId` / `ownerId` 是 UUID 字符串，需经 `OptionsCacheService`（下拉选项接口 + 内存/本地缓存，30 分钟 TTL）解析显示名；`categoryNameProvider` / `userNameProvider` 提供按需查询。
- **详情接口结构**：`data.lead` 嵌套对象（非 `data` 直接平铺），`fetchLeadDetail` 已兼容；`followups`/`calls`/`schedules` 一并返回，无需再补请求。
- 系统通话记录查询：经 `MethodChannel` + `READ_CALL_LOG` 权限读取最近 5 分钟匹配手机号的通话时长（`MainActivity.kt` + `dial_helper.dart`）。

### 5.4 其他历史坑
详见 `docs/dev/DEVELOPMENT_PITFALLS.md`，重点：
- §5 `TokenStorage.clearAll()` 曾误删密码缓存（已修为按 key 逐一删除）。
- §8 unawaited 静默刷新 / 预加载写 `state` 必须带 `目标 id == 当前 id` 守卫（翻页竞态）。
- 筛选标签栏曾引起页面溢出（改用 Stack 浮层，不占布局流）。

---

## 六、仓库与协作约定

- **私有项目、仅单人维护**；开发流程为：读设计文档 + 找接口 → 写计划待确认 → 实现 → **真机实测** → 进度/踩坑文档 → `git commit & push`。
- **`.workbuddy/` 目录有意纳入 git**（用于跨会话记忆与工作日志），审查时**不**作为“误提交 / 整洁度”问题提出。
- 提交信息用中文 `type(范围): 简述`，关联改动文件；`docs/api.md` 的纯格式重排**不混入**业务提交。

---

## 七、交接检查清单（接手第一步）

- [ ] 确认本机 `tdesign_flutter 0.2.7` 已打本地 patch（否则 `flutter pub get` 后构建即失败，见 §2.2）
- [ ] `flutter pub get` → `flutter analyze` 应 **0 issue**
- [ ] `adb` 连接真机，`flutter run --debug` 跑通登录 → 首页 → 线索列表 → 详情 → 拨号返回弹面板
- [ ] 重点复测：详情页反复「下一个 / 上一个」翻页**不闪跳**（竞态修复）
- [ ] 阅读 `docs/dev/MILESTONES.md` 了解节点历史与决策
- [ ] 阅读 `docs/dev/DEVELOPMENT_PITFALLS.md` 了解已踩坑，避免重蹈覆辙
- [ ] 下一建议节点：通话记录列表页（doc16）/ 日程列表页（doc10），补全详情页“查看全部”跳转目标

---

> 本文档为项目级总览；各页面细节见对应 `HANDOVER_XX_*.md`（如线索详情见 `HANDOVER_05_LEAD_DETAIL.md`，
> 注意其部分描述在本项目重构后已过时，以代码与本文档为准）。
