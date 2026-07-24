# 电销工作台 APP — 开发节点记录

> 记录项目的关键开发节点，用于追溯里程碑和决策历史。
> 所有节点以「可运行 + 可演示」为完成标志。

---

## 节点 v0.1 — 项目初始化与登录页 UI（2026-07-22）

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| Flutter 项目初始化 | ✅ | 在当前目录创建 Flutter 项目 `telemarketing_app` |
| 开发环境搭建 | ✅ | macOS + Flutter 3.44.7 + JDK 26 + Android SDK 36 |
| TDesign Flutter 集成 | ✅ | 版本 0.2.7，含本地兼容性 patch |
| 登录页 UI 实现 | ✅ | 邮箱（前缀+后缀选择器/含@自动切换）、密码、复选框、登录按钮 |
| 真机验证 | ✅ | Android 16 真机 USB 部署验证通过 |
| Web 预览验证 | ✅ | Chrome 浏览器实时预览 |

### 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 技术栈 | Flutter + TDesign Flutter | 企业级组件库，中文友好，设计令牌完善 |
| 目标平台 | 仅 Android（API 36） | 坐席统一使用安卓设备 |
| 复选框 | Material 原生（非 TDCheckbox） | TDCheckbox 在 Android 上导致白屏 |
| 邮箱输入 | 单一 TextEditingController | 双 Controller 切换导致 IME 文本错乱 |
| 域名下拉 | Stack 覆盖层（非 inline） | inline 导致页面 bottom overflow |

### 踩坑记录

详见 `docs/dev/DEVELOPMENT_PITFALLS.md`，主要问题：

1. `tdesign_flutter` 0.2.7 与 Dart 3.12 不兼容（`IconData final class`）
2. `image_picker_android` 嵌套类导致 D8 编译失败
3. `TDCheckbox` Android 白屏
4. IME 焦点错乱导致 @ 输入文本重复

---

## 节点 v0.2 — 网络层与认证打通（2026-07-22）

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 网络层（dio） | ✅ | ApiClient + Token 注入/自动刷新/错误解析 |
| Token 安全存储 | ✅ | flutter_secure_storage（Android Keystore） |
| 认证 API 对接 | ✅ | login/logout/refresh 全部接入 |
| 状态管理（Riverpod） | ✅ | AuthNotifier + AuthGate 登录守卫 |
| 登录页对接真实 API | ✅ | 替代模拟逻辑，接入线上测试环境 |

### 技术架构

```
main.dart
  └─ ProviderScope
      └─ TelemarketingApp (ConsumerWidget)
          └─ AuthGate
              ├─ 初始态 → CircularProgressIndicator
              ├─ 未登录 → LoginPage
              └─ 已登录 → HomePage（占位）
```

### 依赖清单

| 包 | 版本 | 用途 |
|----|------|------|
| `flutter_riverpod` | ^2.6.1 | 状态管理 |
| `dio` | ^5.7.0 | HTTP 网络层 |
| `go_router` | ^14.8.0 | 路由管理（已添加待使用） |
| `flutter_secure_storage` | ^9.2.0 | Token 安全存储 |
| `package_info_plus` | ^8.3.1 | 版本号读取 |

### API 对接

| 端点 | 方法 | 状态 |
|------|------|:----:|
| `/api/auth/login` | POST | ✅ 已对接，登录成功跳转首页 |
| `/api/auth/refresh` | POST | ✅ 已对接，拦截器自动换发 |
| `/api/auth/logout` | POST | ✅ 已对接 |
| `/api/tenant/profile` | GET | 📋 待对接 |
| `/api/tenant/stats/mine` | GET | 📋 待对接（首页用） |

### 测试账号

线上测试环境：`https://tm-api-test.kao9.com`

> 实际账号由 TA 在后台创建，APP 端使用邮箱+密码登录。

---

## 节点 v0.3 — 本地凭据持久化与登录流程打磨（2026-07-22）

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 保存登录邮箱 | ✅ | SharedPreferences 持久化，退出重开自动填充 |
| 保存登录密码 | ✅ | flutter_secure_storage 加密存储，退出重开自动填充 |
| 复选框状态独立持久化 | ✅ | 勾选/取消立即保存，与数据存储分离 |
| 首页退出按钮 | ✅ | 添加退出按钮 + 确认弹窗，方便反复测试登录流程 |
| `TokenStorage.clearAll()` 修复 | ✅ | 从 `deleteAll()` 改为只删除自身管理的 key，避免误删密码 |

### 修复的坑

详见 `docs/dev/DEVELOPMENT_PITFALLS.md §5.4`：

> `TokenStorage.clearAll()` 使用 `_storage.deleteAll()` 清空了整个 FlutterSecureStorage，连带删除了 `LocalStorageService` 已保存的密码。修复为逐一删除已知 key。

### 本地存储架构

```
SharedPreferences
  ├── saved_login_email              ← 保存的邮箱（明文）
  ├── saved_login_save_email_checked ← 复选框状态
  └── saved_login_save_password_checked ← 复选框状态

FlutterSecureStorage (Android Keystore)
  ├── access_token              ← TokenStorage 管理
  ├── refresh_token             ← TokenStorage 管理
  ├── user_id / user_name / ... ← TokenStorage 管理
  └── saved_login_password      ← LocalStorageService 管理（加密）
```

---

## 节点 v0.4 — 强制改密页（2026-07-22）

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| User 模型扩展 | ✅ | 新增 `mustResetPassword` 字段，登录响应自动读取 |
| AuthService 新增强制改密 | ✅ | `forceChangePassword()` 无旧密码版本 |
| ApiClient 423 兜底拦截 | ✅ | 捕获 `FORCE_CHANGE_PASSWORD` 状态码，不走 refresh→retry |
| AuthNotifier 状态扩展 | ✅ | 新增 `forceChangePassword` 状态，登录检测自动跳转改密页 |
| 改密页完整 UI | ✅ | 安全提示卡片 + 密码强度指示器(8段) + 双密码框 + 返回确认弹窗 |
| 密码强度计算 | ✅ | 弱(2段)/中(5段)/强(8段)，实时动画切换 |
| 前端表单校验 | ✅ | 长度≥8、含字母+数字、两次一致，实时校验 |
| 返回确认弹窗 | ✅ | Material AlertDialog，"确定退出"清空 Token 跳转登录页 |
| 系统返回键拦截 | ✅ | PopScope 阻止直接返回 |

### 技术架构变动

```
AuthGate 路由新增分支：
  AuthStatus.forceChangePassword → ForceChangePasswordPage

ApiClient 拦截器链：
  onError → 423 FORCE_CHANGE_PASSWORD
    └─ onForceChangePassword callback
        └─ AuthNotifier.forceRedirect()
            └─ state = AuthStatus.forceChangePassword
                └─ AuthGate → ForceChangePasswordPage

完整认证流程（含强制改密）：
  登录 → mustResetPassword==1
    → 改密页 → POST /api/auth/change-password { newPassword }
      → 成功 → 清空 Token → 跳转登录页 → 新密码重新登录 → 首页
```

### 涉及文件

| 文件 | 改动类型 |
|------|---------|
| `lib/models/user.dart` | ✅ 修改 |
| `lib/services/auth_service.dart` | ✅ 修改 |
| `lib/services/api_client.dart` | ✅ 修改 |
| `lib/providers/auth_provider.dart` | ✅ 修改 |
| `lib/app.dart` | ✅ 修改 |
| `lib/pages/force_change_password/force_change_password_page.dart` | 🆕 新建 |

---

## 节点 v0.5 — 首页看板与底部导航（2026-07-22）

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 首页 TDNavBar | ✅ | brand-7 蓝色背景，"首页"左对齐，"团队看板"(TM/TA可见)+退出按钮 |
| 今日概况 Section | ✅ | 2×2 四宫格（今日待办/跟进/接通/我的线索），32sp 大字 |
| 待办日程 Section | ✅ | 最多5条 + TDBadge计数 + "已逾期"标记 + 空态 |
| 快捷入口 Section | ✅ | 我的线索(计数) + 通话记录(ComingSoon)，IntrinsicHeight等高 |
| 底部导航栏 | ✅ | 4 Tab（首页/线索/日程/我的），IndexedStack 保持状态 |
| "我的" Tab | ✅ | 用户信息 + 退出登录按钮 |
| 数据层 | ✅ | HomeStats+Schedule 模型，HomeService 4接口封装 |
| 状态管理 | ✅ | HomePageNotifier + 10分钟轮询 + 生命周期监听 |
| 离线检测 | ✅ | connectivity_plus 网络监听 + 离线提示条 |
| 下拉刷新 | ✅ | RefreshIndicator 支持 |
| ComingSoon 占位页 | ✅ | 通话记录/线索列表/日程管理/团队看板 路由占位 |
| 切换账号数据重置 | ✅ | 登出时自动清空首页旧数据，登录后重新请求 |

### 新增/修改文件

| 文件 | 改动类型 |
|------|---------|
| `lib/models/home_stats.dart` | 🆕 新建 |
| `lib/models/schedule.dart` | 🆕 新建 |
| `lib/services/home_service.dart` | 🆕 新建 |
| `lib/providers/home_provider.dart` | 🆕 新建 |
| `lib/pages/main_shell.dart` | 🆕 新建 |
| `lib/pages/coming_soon_page.dart` | 🆕 新建 |
| `lib/pages/home/home_page.dart` | ✅ 全部重写 |
| `lib/app.dart` | ✅ 修改：MainShell 替换 HomePage |
| `pubspec.yaml` | ✅ 添加 connectivity_plus |

---

## 节点 v0.6 — 线索列表页（2026-07-22）

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 顶部导航栏 | ✅ | brand-7 蓝底，"我的线索"左对齐，右侧排序+筛选图标 |
| 搜索栏 | ✅ | 胶囊形搜索框 + 蓝色"搜索"按钮(浮动,3px间距) + 清除按钮 |
| 排序弹窗 | ✅ | 底部弹出，最近更新(默认) / 待跟进优先 |
| 筛选弹窗 | ✅ | 底部弹出，状态/分类/项目多选，确定+重置 |
| 筛选标签栏 | ✅ | Stack 浮层，不占位不顶卡片，带阴影，× 移除单个条件 |
| 线索卡片 | ✅ | 5行完整布局，状态5色(待跟进/已分配/跟进中/已转化/无效) |
| 分类+项目名 | ✅ | 通过 OptionsCacheService 从 categoryId/projectId 解析名称 |
| 跟进徽章 | ✅ | 今日可打(绿) / N天后(橙) / 已逾期(红)，胶囊形 |
| 归属人行(TM/TA) | ✅ | 仅经理/管理员可见 |
| 无限滚动 | ✅ | ScrollController 监听底部 + 加载锁 |
| 下拉刷新 | ✅ | RefreshIndicator |
| 选项缓存 | ✅ | OptionsCacheService + SharedPreferences 持久化(30分钟TTL) |
| 搜索改按钮触发 | ✅ | 去掉500ms防抖自动搜，蓝色搜索按钮手动触发 |

### 新增/修改文件

| 文件 | 改动类型 |
|------|---------|
| `lib/models/lead.dart` | 🆕 新建（含 LeadProject/LeadOwner） |
| `lib/models/option_item.dart` | 🆕 新建 |
| `lib/services/lead_service.dart` | 🆕 新建 |
| `lib/services/options_cache_service.dart` | 🆕 新建（内存+本地持久化缓存） |
| `lib/providers/lead_list_provider.dart` | 🆕 新建 |
| `lib/providers/options_provider.dart` | 🆕 新建 |
| `lib/widgets/lead_card.dart` | 🆕 新建（ConsumerWidget + OptionsCache 查找） |
| `lib/pages/leads/leads_list_page.dart` | 🆕 新建（完整线索列表页） |
| `lib/pages/main_shell.dart` | ✅ 修改：Tab 2 线索替换为 LeadsListPage |
| `lib/services/api_constants.dart` | ✅ 新增 leads/options 端点 + optionsCacheTTL 配置 |

### 踩坑记录

详见 `docs/dev/DEVELOPMENT_PITFALLS.md`，新增：

1. **API 返回 ID 而非名称**：接口返回 `categoryId`/`projectId`（字符串ID），不是 `category`/`project`（对象）。需通过下拉选项接口获取映射表，再用 OptionsCacheService 解析显示名。
2. **筛选标签引起页面溢出**：筛选标签作为 Column 内联元素会顶推卡片内容。改为 Stack + Positioned 浮层，不参与布局流。
3. **`Future.wait` 混合类型**：多个异步类型不同的 future 同时等待时，返回 `List<dynamic>` 需要显式类型转换。
4. **Options 数据持久化**：下拉选项应首次加载后缓存到 SharedPreferences，后续 APP 启动先读本地再后台刷新。
5. **搜索自动触发浪费带宽**：500ms 防抖搜索每个字符都请求 API。改为按钮触发 + 键盘回车触发。

---

---

## 节点 v0.7 — 线索详情页完整开发（2026-07-22）

> 提交：`82e6ec9 feat: 线索详情页完整开发`

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 详情页框架 | ✅ | 头部信息 / 操作栏 / 跟进时间线 / 通话摘要 / 日程 / 底部导航 / 各弹窗 |
| 跟进时间线 | ✅ | 全量跟进记录时间线展示（含接听类型、分类、时长） |
| 跟进面板 FollowUpPanel | ✅ | 内容 + 接听类型 + 分类 + 系统通话记录查询 |
| 编辑/删除/拨号补正弹窗 | ✅ | `EditFollowUpDialog` / `DeleteConfirmDialog` / `CorrectCallDialog`（TM/TA） |
| 日程 / 编辑线索弹窗 | ✅ | `ScheduleDialog` / `EditLeadDialog` |
| 底部导航 | ✅ | 上一个 / 下一个 切换（`goToPrev` / `goToNext`） |

---

## 节点 v0.8 — TagChipRow 统一组件（2026-07-23 前后）

> 提交：`2388faa feat(tag-chip): TagChipRow统一组件 + 9处替换 + 筛选布局修复`

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 公共组件 `TagChip` / `TagChipRow` | ✅ | 高 28 / 圆角 14；Wrap 换行（scrollable:false）与横滚（scrollable:true）两种模式 |
| 全仓统一替换 | ✅ | 9 处 chip 实现统一改用 `TagChipRow` |
| 筛选抽屉布局修复 | ✅ | 修复一行一个、接听类型文字换行（DecoratedBox+Padding+Text 自然撑开） |

---

## 节点 v0.9 — 拨号功能完整实现 + 快捷备注（2026-07-23）

> 提交：`7f8d8b4 feat(dial): 拨号功能完整实现 + onResume自动弹面板 + 快捷备注`

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 拨号功能（大按钮 + 操作栏三按钮） | ✅ | 头部大 FAB 拨号；操作栏收敛为 跟进 / 日程 / 编辑 三按钮（图标+文字横向 6px，高 44） |
| Android 11+ 包可见性 | ✅ | `AndroidManifest.xml` 加 `<queries>` 声明 `ACTION_DIAL` / tel 协议 |
| 返回自动弹跟进面板 | ✅ | `WidgetsBindingObserver` 监听 `resumed`，无论拨号成功与否都弹出（`fromDial: true`） |
| 快捷备注 | ✅ | 跟进面板文本框下方接入 `/api/tenant/options/quick-notes`，`OptionsCacheService` 批量缓存 30min TTL |

---

## 节点 v0.10 — 详情数据层重构：聚合 + 缓存 + 预加载（2026-07-23）

> 提交：`3ba2f01 refactor(lead-detail): 详情数据层聚合为 LeadDetailBundle，新增缓存与预加载`
> 修复：`_fetchBundle` 写回 UI 前加 `_currentLeadId` 守卫，根治翻页闪跳竞态（详见 `DEVELOPMENT_PITFALLS.md §8`）

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| `LeadDetailBundle` 聚合 | ✅ | 后端升级后 `GET /api/tenant/leads/:id` 一次返回 `lead + followups(全量) + calls(≤5) + schedules(≤5)`，由新模型一次解析 |
| `LeadDetailCache` 内存缓存 | ✅ | 10 分钟 TTL（`get`/`put`/`invalidate`/`invalidateAll`） |
| 预加载下一个 | ✅ | 缓存命中即渲染 + 后台静默刷新；`hasNext` 时后台预取下一条；翻页竞态已修复 |
| `refreshBundle()` 合并 | ✅ | 合并原 `refreshFollowUps` / `refreshCalls` / `refreshAll`，写操作后统一刷新四区块 |
| `ScheduleSection` 新增 | ✅ | 详情页新增「最近日程」区块 |
| 顺手修旧 bug | ✅ | `schedule_dialog` 建日程后原本不刷新详情，已补 `refreshBundle()` |

### 效果对比

| 指标 | 重构前 | 重构后 |
|------|------|------|
| 进详情页请求数 | 3 个并行 | 1 个 |
| 有缓存时渲染 | 骨架屏等待 | 秒开 + 后台静默刷新 |
| 点「下一个」 | 重新请求 | 预加载命中，秒开 |
| 翻页反复切换 | 迟到的旧请求覆盖当前页（闪跳） | 守卫拦截，不再闪跳 |

---

## 节点 v0.11 — 详情页 UI 调整 + 项目级交接文档（2026-07-23/24）

> 提交：`2e2503f docs(ui): 线索详情页 UI 调整 + 项目级交接文档`；`a9e9a0c docs: update api documentation`

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 板块顺序调整 | ✅ | 详情页板块顺序改为 **最近日程 → 跟进记录 → 最近通话**（日程提升至跟进上方） |
| 三区块空态统一缩小 | ✅ | 跟进 / 通话 / 日程 空态 padding 24/32 → 16、图标 64/48 → 40，高度一致 |
| 跟进空态图标对齐 | ✅ | 由 `TDIcons.edit` 改为与线索卡片「跟进」按钮一致的 `TDIcons.rollback` |
| 项目级交接文档 | ✅ | 新建 `docs/dev/HANDOVER.md`（环境搭建/架构/完成度/坑/接手清单） |
| API 文档维护 | ✅ | `docs/api.md` 补充 tenant / leads 接口说明（纯文档，未混入业务提交） |

### 附：维护性提交（2026-07-22~24）

- 巨型文件拆分：全部文件降至 560 行以下，`SheetHeader` 共享组件，`leads_list_page` / `home_page` / `lead_detail_page` 提取子组件
- Lint 清零：`prefer_initializing_formals` 等规则修复、`flutter analyze` 维持 0 issue
- 相对引用统一改为 `package:` 绝对引用；文件头 `///` 说明批量补齐

---

## 节点 v0.12 — 日程列表页 + 调试基建（2026-07-24）

> 提交：feat(schedule): 日程列表页 + 共享统计 Provider + 底部 Tab 角标；fix: 移除日程接口多余 `order` 参数（api.md 笔误）；feat(dev): Alice 网络浮窗 + 登录预填（dev-only）

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 日程列表页 `ScheduleListPage` | ✅ | 待办/已完成 双 Tab（计数来自共享 `scheduleStatsProvider`）；TM/TA 可切「我的/团队」 |
| 分组与吸顶 | ✅ | 纯前端按日期分桶（今天/明天/后天/本周/更早）+ 逾期置顶；日期头与逾期头 `SliverPersistentHeader` 吸顶 |
| 四态卡片 `ScheduleCard` | ✅ | 常规/逾期/已完成/已取消 四态（左侧色条+状态标签）；归属人经 `optionsCacheService.getUserName` 映射 |
| 共享统计 `ScheduleStatsProvider` | ✅ | 单一拉取 `/schedules/stats/mine`，底部 Tab 角标（dueToday）与列表 Tab 计数同源（决策 c） |
| 底部 Tab 角标 | ✅ | 日程入口接入 `dueToday` 角标（复用 `scheduleStatsProvider`） |
| `users` 缓存 | ✅（已具备） | `OptionsCacheService` 的 `getUserName`/缓存经核对已存在，本节点直接复用（决策 d） |

### 调试基建（dev-only，本批次一并提交）

| 模块 | 状态 | 说明 |
|------|:----:|------|
| Alice 网络浮窗 | ✅ | `alice` + `alice_dio` 适配器注入共用的 Dio 实例；右下角自定义浮标调 `showInspector()`。详见 `DEVELOPMENT_PITFALLS.md §8.2` |
| 登录预填测试账号 | ✅ | dev 构建自动填 `lina@qq.com` / `Dev@123456`，正式包编译期消除。详见 §8.4 |
| dev-only 编译开关 | ✅ | `--dart-define=DEV_TOOLS=true` 同时管浮窗 + 预填；不传则正式包零残留。详见 §8.3 |
| Android desugaring | ✅ | `android/app/build.gradle.kts` 开 `isCoreLibraryDesugaringEnabled`（alice 链依赖要求）。详见 §8.2 |

### 待开发（本节点未做，已记入 `docs/review/history/schedule-list-dev-2026-07-24.md`）

- **跨天重算**：日期分组标签按设备本地时间计算，跨天后不自动刷新；需回前台/切 Tab 重算（决策 b，机制待定）。
- **日程详情页（doc 11）/ 列表项完成·取消 / 新建日程（doc 12）**：拆为下一节点 v0.13。
- **团队视图统计**：`/schedules/stats`（团队）未接入，当前角标取「我的」`dueToday`。

---

### 修复追加（2026-07-24 后续实测修复）

| 模块 | 说明 |
|------|------|
| 灰屏修复 | `_dateKey` 补零，避免 `DateTime.parse` 抛 `FormatException` 致 release 整页灰屏 |
| Tab/范围缓存 | `schedule_list_provider` 加 `_TabCache`，切 Tab/范围命中缓存不重加载 |
| 归属映射 | `options_cache_service` 改 `await` 共享 Future，首查不再落空被 FutureProvider 缓存 |
| 卡片时间 | `schedule.dart` 新增 `dateTimeDisplay`（年月日时分），卡片改用 |
| Alice 浮标 | `app.dart` 浮标改可拖拽，避免挡测试控件 |
| 自然周分组 | `_dateTitle` 改用自然周（周一起点），消除两个「本周」 |
| 新建日程确定 | `schedule_dialog` 修正 `TDPicker.onConfirm` 为 `Map<String,int>` + 手动 pop |
| 语义桶分组 | 重写 `_group` 为语义桶，消除同周多天重复头 |
| 骨架屏/吸顶 | `isRefreshing` + 公共 `ScheduleSkeleton` + 吸顶头分割线/点击滚动 |
| 卡片精简 | 移除「线索姓名+手机号」行（改写入标题） |

踩坑详见 `docs/dev/DEVELOPMENT_PITFALLS.md` §2.4 / §5.7 / §5.8 / §8.12。

---

## 节点 v0.13 — 日程详情页（doc 11）+ 操作 + 新建/编辑表单（doc 12）（2026-07-24）

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 日程详情页 `ScheduleDetailPage` | ✅ | 五区块（标题+状态 / 计划时间(逾期红字) / 关联线索跳转 / 内容 / 其他信息）；404/403/通用错误态 |
| 详情操作（完成/取消/重开/删除） | ✅ | 均带确认弹窗；删除走全屏 loading → 返回列表并刷新；权限矩阵 `userId==当前用户.id \|\| role∈{TM,TA}`(编辑) / `==TA`(删除) |
| 关联线索跳转 | ✅ | `lead!=null` 跳 `LeadDetailPage`；`lead==null` 显"该线索已被删除"且不可点、不渲染拨号 |
| 拨号 | ✅（仅调起） | 详情页「拨号」复用 `handleDial` 调起拨号盘，返回后弹反馈面板留待后续 |
| 新建/编辑表单 | ✅（v0.14 改为抽屉） | `ScheduleFormPage.create/edit`；标题预填 `🏷️ 姓名 - 手机号`；TM/TA 可指派归属人 |
| 数据层 | ✅ | `schedule_service` 新增 7 方法（detail/complete/cancel/reopen/delete/patch/create）；`options_cache_service` 新增 `getUsers`；删旧 `lead_service.createSchedule` |
| 接口契约 | ✅ | `GET /api/tenant/schedules/:id` 的 `lead.phone` **明文不脱敏**（api.md §1474 示例脱敏为过时）；无后端改动 |

### 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 范围 | doc 11 + doc 12 一起做 | 用户拍板不拆回合 |
| 拨号 | 仅调起拨号盘 | 反馈面板留待后续 |
| 标题策略 | 线索姓名+手机号写进标题 | 卡片不再单独展示该行（v0.12 末尾已执行） |

---

## 节点 v0.14 — 日程详情页四项 UX/性能打磨（2026-07-24）

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 风格统一 | ✅ | 详情页 `_card` 改白底 + 灰背景透出 8px 间隔，对齐线索详情白卡片 |
| 详情缓存 | ✅ | 新增 `ScheduleDetailCache`（照 `LeadDetailCache`：get/put/invalidate/invalidateAll + 10min TTL，纯内存）；命中秒开 + 后台静默刷新 |
| 底部按钮统一 | ✅ | 取消/拨号/完成 等宽一排 `TDButton`（round）：取消=light、拨号=light+图标、完成=primary（主次层级） |
| 抽屉公共组件 | ✅ | 删全屏 `schedule_form_page`；新建 `widgets/schedule_form_sheet.dart`（`ScheduleFormContent` + `showScheduleFormSheet`，maxHeight 0.92sh）；线索「预约」与详情「编辑」两处共用 |
| 启动崩溃修复 | ✅ | `app.dart` DEV_TOOLS 浮标首帧 `clamp` 负上界致启动 `ArgumentError`，4 处 `max(0, …)` 兜底 |

### 待开发（本批次未做）

- **拨号返回反馈面板**：详情页拨号后弹快捷备注/接通结果面板（v0.13 决议留待后续）。
- **详情页下拉刷新**：当前依赖缓存 + 操作后 invalidate；未接入下拉手动刷新手势。
- **团队视图统计**：`/schedules/stats`（团队）未接入，角标仍取「我的」`dueToday`。

---

## 节点 v0.15 — 日程模块统一视觉风格（2026-07-24）

> 用户实测基础功能可用后，统一日程相关页面的视觉风格，对齐线索详情的白卡片/底部抽屉/输入框/TagChip/骨架屏模式。
> 拆为三小轮：v0.15a 表单抽屉 8 项优化 → v0.15b 抽屉第二批 5 项 → v0.15c 两项修复（删除 loading + 骨架屏）。

### 完成内容

| 模块 | 轮次 | 说明 |
|------|:----:|------|
| 表单抽屉去白卡片/背景 | a | 删 `_card()`，每节仅留间距，无背景色圆角 |
| 关联线索一行 | a | 去图标，显示"姓名-手机号" |
| 计划时间去图标 | a | 标题纯文字 |
| 输入框白底灰边框 | a | `#F3F3F3` → `Colors.white`，对齐登录页 |
| 快捷按钮 TagChip | a | `ChoiceChip` → `TagChipRow` + `TagChipData` |
| 删标题输入框 | a | 标题自动生成，用户不可见不可改 |
| 备注换 TDTextarea | a | TextField → TDTextarea，灰边框 8px 圆角 |
| 抽屉自适应+全宽按钮 | b | 去 `maxHeight`；`SheetHeader` 标题+小关闭；全宽 TDButton；去底部操作栏 |
| 去（只读）文字 | b | 删除关联线索后的灰色"（只读）" |
| 输入框高度缩小 | b | 56px → 44px；快捷 TagChip `scrollable:true` |
| 备注字数 200 | b | `maxLength:2000` → `200` |
| 删除 loading 居中 | c | 从零高度 ActionBar 移至 `Scaffold` 外层 `Stack`，`Center` 以全屏为参考系 |
| 骨架屏统一 shimmer | c | 详情 `_buildSkeleton` 从静态灰块改白卡片+`ShimmerBlock` 扫光；`_ShimmerBlock`→公开 `ShimmerBlock` |
| UI 风格文档 | — | 新建 `docs/dev/UI_STYLE_GUIDE.md`，固化已完成视觉模式 |

### 踩坑记录

详见 `docs/dev/DEVELOPMENT_PITFALLS.md`：

- **§11.5**：全屏遮罩 `Stack` + `Center` 需放在最外层 `Scaffold` 的 `Stack` 中，不能放在零高度的子组件内，否则 Center 参考系错误导致 loading 图标跑到左上角。
- **§11.6**：`_ShimmerBlock` 从私有改为公开时需加 `super.key` 构造参数，否则 `use_key_in_widget_constructors` info 级 warning。

### 待开发（本批次未做）

- **拨号返回反馈面板**：详情页拨号后弹快捷备注/接通结果面板（v0.13 决议留待后续）。
- **详情页下拉刷新**：当前依赖缓存 + 操作后 invalidate；未接入下拉手动刷新手势。
- **团队视图统计**：`/schedules/stats`（团队）未接入，角标仍取「我的」`dueToday`。

---

## 下一步节点规划

> ⚠️ 下方 P0 核心流程**实际已完成**，见 v0.1~v0.11。剩余工作均为 P1 及以后。

### P0 - 核心流程（已全部完成 ✅）

| 模块 | 对应节点 | 状态 |
|------|---------|:----:|
| 登录 / 强制改密 | v0.1 / v0.4 | ✅ |
| 首页看板 + 底部导航 | v0.5 | ✅ |
| 线索列表（搜索/筛选/分页） | v0.6 | ✅ |
| 线索详情页（拨号/跟进/时间线） | v0.7 | ✅ |
| 拨号回传 + 反馈面板 | v0.9 | ✅ |
| 详情数据层聚合 + 缓存 + 预加载 | v0.10 | ✅ |

### P1 - 待开发（下一建议节点）

| 模块 | 设计文档 | 优先级 | 现状 |
|------|---------|:------:|------|
| 通话记录列表页（补全「查看全部」跳转目标） | 16 | P1 | `ComingSoonPage` 占位，详情页「查看全部」无目标页 |
| 日程列表页 | 10 | P1 | ✅ v0.12（双 Tab/范围/分组吸顶/共享统计+角标） |
| 日程详情页（doc 11）+ 操作（完成/取消/新建） | 11/12 | P1 | ✅ v0.13 / v0.14 打磨 |
| 公海线索池 | 06 | P1 | 未开发 |
| 客户列表 / 客户详情 | 17/18 | P1 | 未开发 |
| 个人中心 / 个人统计 | 13/14 | P1 | 「我的」Tab 仅含用户信息 + 退出 |
| 修改密码页 | 15 | P1 | 未开发（与强制改密不同） |
| 设置页 | 19 | P1 | 未开发 |
| 团队模块（入口/统计/日程/线索池） | 20/21/22/23 | P1 | 均未开发 |

---

> 本文档与 `docs/dev/HANDOVER.md`（交接文档）配套使用。
> ⚠️ 旧 `HANDOVER_05_LEAD_DETAIL.md` 中"3 个并行请求""拨号后弹面板未做"等描述已过时，以本表与代码现状为准。
> 节点版本：v0.15 | 更新日期：2026-07-24
