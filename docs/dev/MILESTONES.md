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
| 底部操作栏（跟进/日程/编辑） | d | 日程详情页信息卡片下方追加三按钮；取消拨号反馈面板 |
| 日程详情下拉刷新 | d | `RefreshIndicator` 套 `CustomScrollView`，下拉调 `_load(force:true)` |
| 团队统计视图 | d | TA/TM 优先尝试 `/schedules/stats`，不可用降级为 mine |
| ⋮ 菜单去编辑 | d | 右上角菜单由编辑+删除精简为仅删除，编辑改由底部操作栏提供 |

### 踩坑记录

详见 `docs/dev/DEVELOPMENT_PITFALLS.md`：

- **§11.5**：全屏遮罩 `Stack` + `Center` 需放在最外层 `Scaffold` 的 `Stack` 中，不能放在零高度的子组件内，否则 Center 参考系错误导致 loading 图标跑到左上角。
- **§11.6**：`_ShimmerBlock` 从私有改为公开时需加 `super.key` 构造参数，否则 `use_key_in_widget_constructors` info 级 warning。

### 待开发（本批次未做）

- **跨天自动重算**：日程列表分组标签按本地时间计算，跨天后不自动刷新。
- **详情页拨号返回反馈面板**：已被底部三按钮替代，已取消。
- **团队视图统计**：✅ v0.15d 已实现（TA/TM 优先团队，降级 mine）。

---

## 节点 v0.15d — 三项遗留功能补齐 + 优化（2026-07-24）

> 代码提交：d4f2e82（三项功能）、448c702（移正位置）、871f864（去菜单编辑）

### 完成内容

| 模块 | 说明 |
|------|------|
| 底部操作栏 | 日程详情 `_buildInfoCard` 下方追加跟进/日程/编辑三按钮（白卡片，无权限时灰色不可点）；取消原拨号反馈面板需求 |
| 下拉刷新 | 日程详情页 `CustomScrollView` 外套 `RefreshIndicator`，下拉失效缓存并重拉 |
| 团队统计 | `ScheduleStatsNotifier.load()` 中 TA/TM 角色优先尝试 `fetchTeamScheduleStats`（`/schedules/stats`），接口不可用时静默降级为 `fetchMyScheduleStats`（`/stats/mine`） |
| 菜单精简 | 右上角 ⋮ 菜单移除「编辑」（由底部操作栏替代），仅保留「删除」 |
| 接口确认 | `/api/tenant/schedules/stats` 端点存在但文档未公开，故加 try/catch 降级，不影响现有流程 |

---

## 节点 v0.16 — 个人中心页（doc 13）（2026-07-24）

> 计划：`docs/dev/PLAN_13_PROFILE.md`；进度：`docs/review/history/profile-dev-2026-07-24.md`
> 取代 `main_shell._ProfileTab` 占位页，实现完整个人中心页。

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 个人中心主页 `ProfilePage` | ✅ | 用户信息卡 + 我的业绩 4 列白卡 + 功能菜单 + 团队入口(TM/TA) + 下拉刷新 + 首屏骨架屏 + 退出确认弹窗 |
| 子组件 `profile_user_card` | ✅ | 头像(姓名首字) + 姓名 + 角色标签 + 邮箱 + 租户名 |
| 子组件 `profile_stats_card` | ✅ | 我的业绩 4 列白卡，列间淡灰细线(上下留隙) |
| 子组件 `profile_menu_row` | ✅ | `ProfileMenuGroup` + `ProfileMenuRow`（支持自定义颜色，退出项用红） |
| `tenant_service.fetchTenantName()` | ✅ | 新增，取 `GET /api/tenant/profile` 的 `data.name`，不动原 `fetchProfile()` |
| `main_shell` 接入 | ✅ | 删 `_ProfileTab` 占位，4 号位换 `ProfilePage()` |

### 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 业绩口径 | 真实接口字段（myLeadsTotal/followupCount/answeredCount + dueToday） | doc 13 的 myFollowed/myAnswered/myConverted 接口未返回 |
| 租户名来源 | `profile.data.name`（新接口） | `User` 模型无 `tenantName` 字段 |
| 子页 | 本轮跳 `ComingSoonPage` 占位 | 通话记录/客户列表/设置/团队统计/个人统计 留待后续节点 |
| 控件 | 避开 TDCell/TDAvatar/TDRefreshHeader/TDSkeleton 等零先例组件 | 改用项目已验证模式（CircleAvatar/Container/RefreshIndicator/ShimmerBlock/自定义 Tag） |

### 真机实测后 5 处 UI 调整（纯 UI）

1. 用户卡删「所属租户」前缀；2. 「我的业绩」标题缩小+灰；3. 4 指标收白卡 + 细线分隔；4. 删「功能」标题；5. 退出登录整合进菜单（红色项）。

### 踩坑

- **§11.7**：`VerticalDivider` 放进 `Row` + `Expanded` 内不显示（交叉轴高度塌缩）→ 改手写固定高 `SizedBox`+1px `Container` 细线。

### 待开发（本批次未做）

- 子页（通话记录/客户列表/设置/团队统计/个人统计）均为占位。
- `login_page.dart` 仍 612 行（第三轮审查 P3 观察项）。

---

## 节点 v0.17 — 通话记录列表页（doc 16）（2026-07-24）

> 计划：`docs/dev/PLAN_16_CALL_RECORDS.md`；进度：本节点实测通过。
> 取代个人中心「通话记录」菜单项的 `ComingSoonPage` 占位，实现完整列表页。
> **关键决策变更（实测后拍板）**：① 不开发通话详情页，行点击直接跳对应线索详情；② 移除 TDesign 日历控件（弹层 `Null is not a subtype of type 'String'` 崩溃，静态分析 tdesign 0.2.7 日历链路无 null→String 路径，推断为 patch 后 pub cache 运行时代码/混淆所致），改用手机号搜索（`GET /api/tenant/calls` 的 `q` 模糊搜索）。

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 列表页 `CallRecordsPage` | ✅ | 手机号搜索栏 + 接听类型筛选 + 下拉刷新 + 无限滚动 + 骨架/空态/错误态 |
| 搜索栏 `CallSearchBar` | ✅ | 圆角灰底 + 搜索图标 + 手机号键盘 + 清空 + 蓝色「搜索」按钮；回车/点按钮才触发（参考线索列表搜索） |
| 接听类型 `CallFilterBar` | ✅ | 全部/已接听/无人接听/拒接/空号/停机 横滚 Chip |
| 单行 `CallRecordRow` | ✅ | 彩色圆图标(按接听类型) + 姓名(半粗) + **手机号(黑/不加粗)紧跟其后** + 时间 + 右侧时长/违规 |
| 接口 `CallService.fetchMyCalls` | ✅ | `GET /api/tenant/calls`，支持 `q`(非空才传) + `answerType` + `page`/`size=20` |
| 模型 `CallRecord` 补字段 | ✅ | 补 `violation`(0/1) + `leadName`(后端已补)；`displayName` 优先 leadName→phone→未知号码 |
| 行点击跳线索详情 | ✅ | `LeadDetailPage(leadId:)`；仅 `leadId` 非空才跳，空号/停机无关联线索不跳 |
| 个人中心接入 | ✅ | 「通话记录」菜单项由 `ComingSoonPage` 改为 push `CallRecordsPage` |

### 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 详情页 | **不开发**，行点击跳线索详情 | 列表已呈现关键信息（姓名/号码/时间/时长/违规），详情页价值低 |
| 时间筛选 | 移除 TDesign 日历，改用手机号搜索 | 日历弹层崩溃（见 `DEVELOPMENT_PITFALLS.md §2.5`），且接口 `q` 支持号码模糊搜 |
| 搜索触发 | 回车/点按钮，非逐字 | 对齐线索列表搜索交互，避免每字符打接口（`§7.1`） |
| 跳转参数 | 仅传 `leadId`，不传 `listContext` | 通话记录无「上/下一个」语义，线索详情底部导航条自动隐藏 |

### 踩坑

- **§2.5**：TDesign `TDCalendarPopup` 弹层崩溃 `Null is not a subtype of type 'String'`，静态分析 tdesign 0.2.7 日历链路无该路径，推断 patch 后 pub cache 运行时代码/混淆所致；决策移除日历改用搜索。
- **§12.1**：首屏 `_isLoading=true` 同时作骨架标志与请求守卫，致 `_loadInitial` 被自身短路、永不发请求；拆为 `_isLoading`(仅骨架) + `_isFetching`(重入锁)。

---

## 节点 v0.18 — 客户列表页（doc 17）（2026-07-24）

> 计划：`docs/dev/PLAN_17_CUSTOMER_LIST.md`；进度：本节点实测通过。
> 取代个人中心「客户列表」菜单项的 `ComingSoonPage` 占位。
> 用户拍板：不开发客户详情页（doc18），点卡片直接跳对应线索详情（同通话记录决策）。

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 列表页 `CustomerListPage` | ✅ | 手机号搜索 + 等级通栏筛选 + scope 切换 + 下拉刷新 + 无限滚动 + 骨架/空态/错误态 |
| 搜索栏 `CustomerSearchBar` | ✅ | 手机号键盘 + 清空 + 蓝色「搜索」按钮；回车/点按钮才触发（对齐线索/通话记录搜索交互） |
| 等级筛选 `CustomerFilterBar` | ✅ | **通栏分段控件**（全部/普通/重要/VIP/流失），5 项等宽 `Expanded` 占满 100%，选中浅蓝底 |
| 客户卡片 `CustomerCard` | ✅ | 4 行：姓名(半粗) + 右对齐等级标签(success/brand/warning/error) / 电话 / 公司(空则隐藏) / 转化日期 |
| 接口 `CustomerService.fetchCustomers` | ✅ | `GET /api/tenant/customers`，支持 `scope` + `q`(非空才传) + `level` + `sort=-convertedAt` 分页 |
| 模型 `Customer` | ✅ | 解析后端真实返回字段（`leadId`/`name`/`phone`/`company`/`level`/`convertedAt`/`erasedAt` 等）；等级映射、日期解析 `YYYY-MM-DD` |
| 卡片点击跳线索详情 | ✅ | `_openCustomer(c)` → `LeadDetailPage(leadId: c.leadId)`；仅 `leadId` 非空才跳 |
| scope 切换（TM/TA） | ✅ | 原生 `PopupMenuButton` 切「我的/全部」；TE 固定 mine 隐藏按钮 |
| 个人中心接入 | ✅ | 「客户列表」菜单项由 `ComingSoonPage` 改为 push `CustomerListPage()` |

### 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 详情页 | **不开发**，点卡片跳线索详情 | 用户拍板（同通话记录决策），列表已呈现姓名/电话/公司/等级/转化日期等关键信息 |
| level 枚举 | `normal`/`important`/`vip`/`lost` | 以 api.md 为准（实测确认），非 doc17 的 A/B/C/D |
| convertedAt 类型 | Unix 秒 | 实测确认，前端 `fromMillisecondsSinceEpoch(sec*1000)` 解析 |
| 搜索参数 | `q` | 对齐线索/通话记录搜索，非空才传避 400 坑 |
| 等级筛选 UI | **通栏分段控件** | 实测后用户要求改，5 项等宽占满 100% |
| scope 切换 | 原生 `PopupMenuButton`，不用 TDesign | 规避此前 TDesign 弹层崩溃风险 |
| company 字段 | 后端**确实返回**（实测真机抓包确认），但多为 null | 空则隐藏公司行，容错如前所述 |

### 搜索栏与筛选栏间分隔线

实测后用户要求加 `Divider(height:1, thickness:1, color:#EEEEEE)`，分隔搜索栏与通栏筛选，视觉上更清晰。

---

## 节点 v0.19 — 线索详情查看全部跳转 + 日程搜索页（2026-07-24 末）

> 本节点是对 v0.7 线索详情页与 v0.12 日程列表页的补全：从线索详情跳转日程列表/通话记录时，按手机号预填充搜索词。

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 线索详情「最近日程」查看全部 | ✅ | 跳 `ScheduleSearchPage(initialQuery: detail.phone)`，按手机号预填搜索 |
| 线索详情「最近通话」查看全部 | ✅ | 跳 `CallRecordsPage(initialQuery: detail.phone)`，按手机号预填搜索 |
| 线索详情删除重复底部操作栏 | ✅ | 删 `_buildBottomActionBar`（上方已有跟进/日程/编辑按钮） |
| 日程搜索页 `ScheduleSearchPage` | ✅ | 独立页面（局部 state，不碰全局 `scheduleListProvider`），搜索栏预填手机号，`status__in=pending,completed,cancelled` |
| `CallRecordsPage` 加 `initialQuery` | ✅ | 构造参数预填搜索框 + 查询词，复用原有搜索逻辑 |
| `ScheduleService.fetchSchedules` 加 `q` + `statusIn` | ✅ | `q` 手机号搜索；`statusIn` 传 `status__in` 查全部状态 |
| 日程搜索框文字偏移修复 | ✅ | `InputDecoration.prefixIcon` 改为 `Row` 手动布局 + `isDense:true` + `contentPadding` |
| 日程搜索 status__in 修复 | ✅ | `status: null` 后端只返回 pending → 改 `statusIn: 'pending,completed,cancelled'` |

### 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 日程搜索页 vs 改造现有列表页 | **新建独立页面** | 日程列表页用全局共享 `scheduleListProvider`（底部 Tab 也用它），改造会污染底部 Tab 状态；通话记录页本就是局部 state → 加参数即可 |
| `status__in` vs 不传 status | **显式传三个状态** | 后端不传 status 默认只返回 pending，传 `status: null` 无效；须 `status__in=pending,completed,cancelled` 才拿到全部 |
| 搜索框 UI | `Row` 手动布局 | 统一对齐线索/通话记录搜索栏，解决 prefixIcon 文字偏移问题 |

---

## 节点 v0.20 — 设置页（doc 19）（2026-07-25）

> 设计文档：`docs/design/page-design/19-设置页.md`；计划：`docs/dev/PLAN_19_SETTINGS.md`。
> 入口：个人中心 → 设置（替换 ComingSoonPage 占位）。

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 设置页 | ✅ | 三段列表（账户安全/账户操作/关于）+ 退出/全设备退出确认弹窗 + 关于弹窗 + 底部版本信息 |
| `HealthService` | ✅ | GET /health 获取后端版本号，用于关于弹窗和底部版本信息 |
| 退出登录 API 修复 | ✅ | `AuthService.logout()` 按 LOGOUT_GUIDE.md 要求，POST 时带 `{"refreshToken": "..."}` body |
| 退出登录导航修复 | ✅ | 修复退出登录 spinner 不停止 + 不跳转登录页的 bug：显式弹出导航栈并还原 spinner |
| 退出登录去重 | ✅ | 删除「我的」页面退出登录菜单项，退出仅保留在设置页 |
| 全设备退出登录 | ✅ | `AuthNotifier.logoutAll()` + `AuthService.logoutAll()` |

### 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 退出登录去重 | 仅保留设置页 | 账户管理天然归属设置页；「我的」聚焦个人信息和页面入口导航 |
| 退出导航策略 | `popUntil` + AuthGate 状态切换 | API 成功后显式弹出导航栈到根路由，配合 `AuthStatus.unauthenticated` 状态由 AuthGate 切换显示登录页 |

---

## 节点 v0.21 — 修改密码页（doc 15）（2026-07-25）

> 设计文档：`docs/design/page-design/15-修改密码.md`；计划：`docs/dev/PLAN_21_CHANGE_PASSWORD.md`。
> 入口：设置页 → 修改密码（替换 ComingSoonPage 占位）。

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 修改密码页面 | ✅ | 3 个 TextField（旧/新/确认新密码）+ 4 段密码强度指示器 + 6 步前端校验 + 返回脏检查 |
| 密码强度检测 | ✅ | 弱/中/强/非常强四级，实时计算，颜色对齐 BrandColors（error/warning/primary/success） |
| 表单校验 | ✅ | 6 步（旧密码空→新密码空→不足8位→新旧相同→确认空→确认不一致），错误以 errorText + 红边框展示 |
| 成功 Toast + 跳转 | ✅ | 显示 Toast "密码已修改，请重新登录" 2s 后自动跳转登录页（设计文档 §4.4 / §5.5） |
| `AuthNotifier.changePassword` | ✅ | 解耦 Token 清除与状态切换，新增 `notifyPasswordChanged()` 由页面控制跳转时机 |
| 设置页入口接入 | ✅ | 修改密码 ComingSoonPage→ChangePasswordPage() |

### 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 成功 Toast 展示时机 | 调 API 成功后先展示 Toast 2s，再跳转 | AuthGate 会在状态变为 unauthenticated 时立即切换页面，Toast 来不及显示；需分两步：清 Token → Toast → 2s → 切状态 |
| 确认密码错误展示 | `errorText` 属性（TextField 原生） | 标准 Flutter 做法，自带红色边框 + 错误文字，比外部 `_buildError` 更可靠 |
| 密码强度颜色 | `BrandColors.*` 常量 | 遵守 `UI_STYLE_GUIDE.md`，避免硬编码色值 |

---

## v0.22 公海线索池 + 顶部栏布局重构（2026-07-25）

> 开发文档：`docs/dev/PLAN_22_PUBLIC_LEADS.md` + `docs/dev/PLAN_23_PUBLIC_LEADS_LAYOUT.md`

### 功能概要

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 公海线索列表 | ✅ | `scope=public` 加载公海线索，独立分页/状态/骨架/空错态 |
| 领取线索 | ✅ | 一键领取 + 移除卡片 + 失败分类提示（已被领/禁拨名单/网络异常） |
| PublicLeadCard | ✅ | 新建组件：姓名/电话/分类/更新时间的 4 行布局 + 底部"领取该线索"按钮 |
| LeadsTopBar 合并 Tab | ✅ | 顶部栏改为左侧 Tab 切换（Expanded 均分）+ 右侧筛选/排序按钮 |
| 公海 Tab 筛选置灰 | ✅ | `onTap: null` + `Colors.white30`，不做隐藏/移除，红点隐藏 |
| 筛选/排序按钮对调 | ✅ | 筛选左、排序右 |
| 搜索状态独立 | ✅ | 双 `TextEditingController`，切换 Tab 不丢失搜索词 |

### 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| Tab 颜色方案 | 蓝底白字，选中=白色下划线+加粗，未选中=white70 | 蓝色背景上用 BrandColors.primary 不可见 |
| 双搜索控制器 | `_mineSearchCtrl` + `_publicSearchCtrl` | 保持搜索状态，切换 Tab 不丢失已输入文字 |
| 公海筛选禁用手法 | 置灰禁用（onTap: null + white30） | 不隐藏，避免图标闪烁 |
| Tab 布局 | Expanded 均分 + Spacer 推按钮 | 各屏幕宽度下按钮位置稳定 |

---

## 节点 v0.24 — 团队日程视图 + 角色标签修复（2026-07-26）
> 计划：`docs/dev/PLAN_28_TEAM_SCHEDULE_VIEW.md`；进度：`docs/dev/PROGRESS_TEAM_SCHEDULE_VIEW-2026-07-26.md`
> 团队模块阶段二（阶段一为团队线索池 v0.22）。TM/TA 在「日程」Tab 内可切「我的/团队」；本节点补全团队日程视图与一处角色解析 bug。
### 完成内容
| 模块 | 状态 | 说明 |
|------|:----:|------|
| 归属人颜色圆点 | ✅ | 团队日程卡片按归属人显示固定色圆点，区分不同成员 |
| 团队统计摘要条 | ✅ | 团队视图顶部摘要条（团队待办/逾期等聚合） |
| 员工筛选方案② | ✅ | 选成员时 `selectOwner(id)` 重新请求 `fetchSchedules(userId:选中id)` 替换团队列表（成员维度独立缓存键），后端按 userId 过滤 |
| Provider 改造 | ✅ | `schedule_list_provider` 支持成员维度缓存与切换 |
| 角色标签修复 | ✅ | **根因修复**：`OptionItem.fromJson` 此前只解析 `id/name/type`，静默丢弃 `role` → 员工筛选不显示角色。补 `role` 字段并解析（nullable，避免非 user 接口无 role 时报错） |
| 共享角色文案 | ✅ | 抽 `lib/theme/role_label.dart` 的 `roleLabel()`，个人中心与日程筛选统一复用，杜绝术语漂移 |
| 团队日程头组件 | ✅ | 新建 `widgets/team_schedule_header.dart` 承载团队切换/摘要 |
### 关键决策
| 决策 | 选择 | 原因 |
|------|------|------|
| 员工筛选方案 | 方案② 选成员重请求后端过滤 | 后端按 userId 过滤更可靠，成员维度独立缓存键避免污染「我的」列表 |
| 日期筛选 | 放弃本节点 | 范围控制，留待后续 |
| 角色文案 | 抽共享 `roleLabel()` | 全端术语一致，`tenant_employee→电销专员`/`tenant_manager→团队经理`/`tenant_admin→管理员` 单一配置点 |
### 验证
| 验证项 | 结果 |
|------|------|
| `flutter analyze` | 0 issue（role 相关 4 文件 + 新建 3 文件均 0 error 0 warning） |
| 构建装 Redmi K60 实测 | 通过（后台构建 `app-release.apk` 60.4MB，旧版自动卸载替换） |
### 待开发
- v0.25 团队统计独立页（需引入 `fl_chart`）
- 团队视图日期筛选（本节点放弃）
---

## v0.25 团队统计独立页（2026-07-26）
> 计划：`docs/dev/PLAN_29_TEAM_STATS.md`；进度：`docs/dev/PROGRESS_TEAM_STATS-2026-07-26.md`
> 团队模块阶段三（阶段一=线索池 v0.22，阶段二=日程视图 v0.24）。TM/TA 在「我的」页可见「团队统计」入口，TE 不可见。

### 完成内容
| 模块 | 状态 | 说明 |
|------|:----:|------|
| 数据模型 `team_stats.dart` | ✅ | 映射 `GET /api/tenant/stats`（pending 单键契约）：状态分布/漏斗/Agent 绩效/逐日趋势/环比；`teamConversionRate`=Σconverted/ΣownedLeads 前端算 |
| 服务层 `team_stats_service.dart` | ✅ | `fetchTeamStats`；区间无数据抛 `NoDataInRangeException` |
| 状态管理 `team_stats_provider.dart` | ✅ | `TeamStatsNotifier` + 日期范围（今日/本周/本月/自定义≤90天）+ 5 分钟按范围 key 缓存 |
| 图表 `chart_colors.dart` + 5 组件 | ✅ | fl_chart 环形（状态分布）+ 折线（逐日趋势）+ 漏斗进度条 + 概述 2×2 + 坐席排行 Top3 金银铜 |
| 入口 `profile_page.dart` | ✅ | 「团队统计」由 ComingSoon 改为直推 `TeamStatsPage()` |
| 依赖 `pubspec.yaml` | ✅ | 引入 `fl_chart: ^0.70.0` |

### 关键决策
| 决策 | 选择 | 原因 |
|------|------|------|
| 后端契约 | 统一 `pending` 单键 | 公海权威定义 `status=pending && ownerId IS NULL`；seed 曾误写 `pool` 致漏斗恒 0，已全链路修正，客户端不再兼容 `pool` |
| 图表库 | fl_chart ^0.70.0 | 轻量声明式，环形+折线都满足；注意 0.70 破坏性 API（见 `DEVELOPMENT_PITFALLS.md` §14） |
| 日期格式化 | 本地 `_fmt`，不引 intl | pubspec 无 intl，避免额外 pub get |

### 验证
| 验证项 | 结果 |
|------|------|
| `flutter analyze` | 本次 13 文件 0 error 0 warning |
| 构建 + 装真机 | `app-release.apk` 59MB，`adb install -r` 到 Redmi K60(`3e06fd6d`) Success |
| 真机实测 | 通过（用户确认无明显问题） |

### 待开发（团队模块三阶段已全完成）
- KGP 警告（`package_info_plus`/`sensors_plus`/`share_plus`）按方案 A 暂接受。
- 团队视图日期筛选（v0.24 放弃项）留待后续。
---

## v0.27 首页日程接口合并（2026-07-25）

> 开发文档：`docs/dev/PLAN_25_HOME_SCHEDULE_MERGE.md`
> 需求文档：`docs/dev/API_HOME_SCHEDULE_MERGE.md`
> 后端对接指引：`docs/dev/HOME_SCHEDULE_MERGE_FRONTEND_GUIDE.md`

### 功能概要

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 聚合端点接入 | ✅ | 新增 `GET /api/tenant/schedules/home-summary`（无参），一次返回今日待办数 + 即将到期数 + 预览列表（≤5） |
| 首屏请求合并 | ✅ | 首页并行请求由 4 → 2（`stats/mine` + `home-summary`），删除 3 个冗余方法 |
| HomeSummary 模型 | ✅ | 新建 `lib/models/home_summary.dart`，`schedules` 复用 `Schedule.fromJson`，前端零模型改动 |
| 今日待办口径 | ✅ | 首页「今日到期」四宫格 + 待办 Badge 改读 `todayPending`（严格今日窗口，排除历史逾期） |
| 到期提醒条 | ✅ | 沿用 `dueSoonCount`（未来 30 分钟），逻辑不变 |

### 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 改造范围 | 仅首页 6 文件 | Tab 角标 / 个人中心仍读旧 `dueToday`（`schedules/stats/mine`），不在此次范围，避免误删共享 provider |
| `pendingTotal` | 接收但暂不渲染 | 后端提升为必返，预留「查看全部」 |
| 口径收窄 | 接受 `todayPending` < 旧 `dueToday` | 需求文档明确定义的预期行为，更精确 |

### 已知差异（待产品决策，不阻塞）

- 首页 Badge/四宫格（今日待办）与底部 Tab「日程」角标 / 个人中心「今日待办」可能**数值不一致**（前者严格今日、后者含逾期）。是否统一口径需产品拍板 + 后端在 `schedules/stats/mine` 也返回 `todayPending`。

---

## 节点 v0.28 — 通话记录列表优化（2026-07-25）

> 计划：`docs/dev/PLAN_26_CALL_RECORDS_OPT.md`

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 列表 5 分钟缓存 | ✅ | `CallService.fetchMyCalls` 服务层单例缓存（page==1 写、TTL=300s），进入页面命中直接套用，下拉刷新透传 `force:true` 绕过 |
| TM/TA 卡片拨打人 | ✅ | `call_record_row` 时间行追加「· 拨打人：xx」，姓名经 `OptionsCacheService.getUserName(userId)` 映射 |
| 角色判定修正 | ✅ | 见 v0.29 关联（后端真实值为 `tenant_manager`/`tenant_admin`，非 TM/TA 简称） |

### 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 缓存层级 | 服务层单例（非 provider） | 跨页面/重进共享，避免每次进入都请求 |
| 下拉刷新 | 绕过缓存（`force:true`） | 用户明确要求 |
| 彩色圆点 | 不加 | 用户明确要求 |

---

## 节点 v0.29 — 全端待办角标口径统一 + 角色短写 Bug 修复（2026-07-25）

> 后端对接指引：`docs/dev/HOME_SCHEDULE_MERGE_FRONTEND_GUIDE.md` 第八节

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 角标字段统一 | ✅ | 弃 `dueToday`（含逾期），四位置（首页四宫格/待办 Badge/Tab 角标/个人中心今日待办）统一读 `todayPending`（严格今日、与 home-summary 同源） |
| `ScheduleStats` 模型 | ✅ | 字段 `dueToday→todayPending`；`fromJson` 改从顶层 `data['todayPending']` 解析（旧 `byStatus.dueToday` 弃用） |
| 角色短写 Bug 修复 | ✅ | 6 处 `'TM'`/`'TA'` 判定修正为 `tenant_manager`/`tenant_admin`，TM/TA 现正确请求团队 `stats`、加载归属人、显示角色标签与团队入口、放开详情编辑/删除权限 |

---

## 节点 v0.30 — 登录/全端报错中文映射（2026-07-25）

> 方案：`docs/dev/PLAN_27_ERROR_MSG_CN.md`

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 错误码中文映射表 | ✅ | 新增 `lib/services/error_messages.dart`，`ErrorMessages` 类含 12 条 `error.code → 中文`（取自后端对照表原样），`resolve(code, fallback)` 命中返中文、未命中回退后端 message |
| 全端统一替换 | ✅ | `lib/services/api_client.dart` 的 `parseError()` 构造 `ApiException` 时 `message` 改走 `ErrorMessages.resolve(code, 后端message)`，UI 层零改动 |
| 拼写核对 | ✅ | 后端真实 code=`AUTH_FORBIDDEN`，复核 `api_exception.dart:23` 现有值一致，无需修正 |

### 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 配置位置 | 新增 `error_messages.dart` 映射表（唯一配置点） | 集中维护，新增 code 只改一处 |
| 接入点 | 改 `parseError` 一处 | 它是全端唯一错误解析入口，改一处覆盖登录/改密/线索/日程/通话记录等所有展示 |
| 替换范围 | 全局统一（非仅登录页） | 用户拍板；避免其它接口仍显示英文 |
| 未命中映射 | 回退后端 message | 不掩盖未录入 code 的真实错误 |

### 踩坑

详见 `docs/dev/DEVELOPMENT_PITFALLS.md §11.16`：
1. 映射表 key 必须与后端 `error.code` 逐字符一致（`AUTH_FORBIDDEN` 曾被误写为少 I 版本）。
2. `resolve` 的 fallback 必须传后端 message，否则未录入 code 变成「未知错误」掩盖问题。
3. 不要只改登录页 catch，否则其它接口仍英文；改 `parseError` 一处即全端统一。

---

## 节点 v0.31 — 首页/个人中心 入口接线修复（2026-07-26）

> 快修：修复两处「已建好页面却仍跳 ComingSoon 占位」的漏接线入口。个人中心「我的业绩」按用户选择保持 ComingSoon。

### 完成内容

| 入口 | 位置 | 修复后 |
|------|------|--------|
| 首页快捷入口「通话记录」 | `home_quick_entry_section.dart:49` | 跳 `CallRecordsPage()`（v0.17 已建） |
| 首页 AppBar「团队看板」（TM/TA 可见） | `home_page.dart:133` | 跳 `TeamStatsPage()`（v0.25 已建） |

### 改动文件

| 文件 | 改动类型 |
|------|---------|
| `lib/pages/home/home_quick_entry_section.dart` | ✅ 修改 |
| `lib/pages/home/home_page.dart` | ✅ 修改 |

### 验证

| 验证项 | 结果 |
|------|------|
| `flutter analyze` | 2 文件 0 issue |
| 构建 + 装真机 | `app-release.apk` 59MB，Redmi K60 实测通过 |

### 待开发

- ~~个人中心「个人统计」整页~~ ✅ 已并入 v0.32 完成（设计 `14-个人统计.md`，入口已接线）。
- 团队视图日期筛选（v0.24 放弃项）。

---

## v0.32 个人统计独立页（2026-07-26）
> 计划：`docs/dev/PLAN_32_PERSONAL_STATS.md`；进度：`docs/dev/PROGRESS_PERSONAL_STATS-2026-07-26.md`
> 入口：个人中心 → 「我的业绩」卡 + 「个人统计」菜单项（此前均为 ComingSoon）。

### 完成内容
| 模块 | 状态 | 说明 |
|------|:----:|------|
| 数据模型 `personal_stats.dart` | ✅ | 映射 `GET /api/tenant/stats/mine`：8 字段 + 嵌套 `myToday`；`_int`/`_num` 安全转换；派生 `conversionRateDisplay`/`conversionProgress`/`conversionSummary` |
| 服务层 `home_service.dart` | ✅ | 扩展 `fetchPersonalStats({from,to})`，复用 `dio` + `statsMine`（与 `fetchMyStats` 同端点，不新建 Service） |
| 状态管理 `personal_stats_provider.dart` | ✅ | `PersonalStatsNotifier` + 日期范围（今日/本周/本月/自定义）+ 5 分钟按范围 key 缓存（sentinel `_Unset`/`_unset`，同构 team_stats_provider） |
| 页面 `personal_stats_page.dart` | ✅ | AppBar「个人统计」+ 刷新 + 吸顶日期选择 + 滚动区；错误态 `AppErrorBody` + 骨架屏 `_StatsSkeleton` |
| 今日概况 `today_overview.dart` | ✅ | 2 卡（今日跟进/接通），固定不随 Tab 变 |
| 数据详情 `detail_grid.dart` | ✅ | 2×3 白卡 + `formatBigNumber`（≥10000 转"万"）+ 转化率卡 accent |
| 转化率环 `conversion_ring.dart` | ✅ | `CircularProgressIndicator`(strokeWidth:12) + 中心 % + "转化 X / 线索 Y" |
| 日期选择器 `date_range_selector.dart` | ✅ | 改造自 team stats；放宽 90 天上限，仅拦截 `from>to` |
| 入口接线 `profile_page.dart` + `profile_stats_card.dart` | ✅ | 「我的业绩」卡 + 「个人统计」菜单项由 ComingSoon → `PersonalStatsPage()` |

### 关键决策
| 决策 | 选择 | 原因 |
|------|------|------|
| 接口字段疑云 | 直接按 PLAN_32 建页 | 用户在 AskUserQuestion 直接贴真机抓包 JSON 证实 5 区间字段齐全，风险消除 |
| 转化率口径 | 直接展示后端 `myConversionRate` | 前端不二次计算（团队统计是前端算 `Σconverted/ΣownedLeads`） |
| 日期上限 | 放宽 90 天 | 设计允许超 1 年；仅拦截 `from>to` |
| 缓存 | 5 分钟按范围 key + sentinel | 同构 team_stats_provider，切 Tab/范围命中缓存不重加载 |

### 验证
| 验证项 | 结果 |
|------|------|
| `flutter analyze` | 个人统计相关 6 文件 0 issue；全仓仅 `token_storage.dart` 11 个 `!` 基线 warning（无关） |
| 构建 + 装真机 | `app-release.apk` 62.3MB（DEV_TOOLS 浮标），`adb install -r` 到 Redmi K60(`3e06fd6d`) Success |
| 真机实测 | ✅ 通过（用户确认测试通过） |

### 待开发
- KGP 告警（`package_info_plus`/`sensors_plus`/`share_plus`）按方案 A 暂接受。
- 团队视图日期筛选（v0.24 放弃项）留待后续。

---

## v0.33 线索筛选「归属人」角色可见性修复（2026-07-26）
> 类型：bug 修复（非功能新增）；进度：`docs/dev/PROGRESS_LEADS_OWNER_FILTER_ROLE-2026-07-26.md`

### 问题
| 现象 | 说明 |
|------|------|
| 员工（tenant_employee）登录 | 线索列表 → 筛选抽屉出现「归属人」选项，但后端该角色 scope 固定为 'mine'，只能看自己线索，该筛选无意义 |
| 数据口径不一致 | 员工看不到他人线索，展示「归属人」筛选与列表数据矛盾 |

### 根因
`lib/pages/ads/widgets/ads_filter_sheet.dart` 的 `_buildOwnerSection()` 对所有角色无条件渲染，UI 未与后端 scope 语义（员工=mine / TM·TA=all）对齐。

### 修复
| 文件 | 改动 |
|------|------|
| `lib/pages/ads/widgets/ads_filter_sheet.dart` | `build()` 取 `authProvider.user.role`，仅 `tenant_admin`/`tenant_manager` 渲染「归属人」区块（连同间距包进 `if`） |
| `lib/pages/ads/ads_list_page.dart` | 激活筛选标签栏「归属」标签加 `isManager` 判定，与抽屉一致 |

### 验证
| 验证项 | 结果 |
|------|------|
| `flutter analyze` | 2 文件 0 issue |
| 构建 + 装真机 | `app-release.apk` 59MB（DEV_TOOLS 浮标），Redmi K60 实测通过 |
| 真机实测 | ✅ 员工登录筛选抽屉无「归属人」；TM/TA 正常显示并可按归属人筛选 |

---

## 节点 v0.36 — 待跟进优先专用排序 + 顶栏计数整合（2026-07-28）

> 计划：`docs/dev/PLAN_LEAD_SORT_PENDING_PRIORITY-2026-07-28.md`（排序）、`docs/dev/PLAN_LEADS_TOPBAR_COUNT-2026-07-28.md`（顶栏计数）
> 后端对接：`docs/api.md` 补 `GET /api/tenant/leads` 的 `sort` / `sort=pendingPriority` 说明

### 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 待跟进优先专用排序 | ✅ | 「我的线索」默认排序与排序弹窗「待跟进优先」由 `nextFollowupAt` 改为后端专用 `pendingPriority`（assigned 置顶、其余按 nextFollowupAt 升序、无计划排尾） |
| 顶栏计数整合 | ✅ | 经理/管理员视角原独立的「共 X 条」统计行移入标题栏左上角，省掉一行；员工视角不变 |

### 排序改动文件

| 文件 | 改动 |
|------|------|
| `lib/providers/lead_list_provider.dart` | `sortBy` 默认 `'nextFollowupAt'`→`'pendingPriority'`；`toggleSort()` 切换值同步改 |
| `lib/pages/leads/widgets/leads_filter_sheet.dart` | 排序弹窗「待跟进优先」选项 value `'nextFollowupAt'`→`'pendingPriority'` |

### 顶栏计数改动文件

| 文件 | 改动 |
|------|------|
| `lib/pages/leads/widgets/leads_top_bar.dart` | 新增 `isManager`/`total` 参数；`!showPublicTab` 分支用 `Stack` 居中「线索」+ `Row`（`isManager` 时左侧插「共 X 条」白70 字） |
| `lib/pages/leads/leads_list_page.dart` | `LeadsTopBar` 传 `isManager/total`；删除独立 `_buildSummaryBar`/`_formatNum`（逻辑迁入顶栏） |

### 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 待跟进优先排序 | 用专用 `pendingPriority` 而非 `nextFollowupAt` | 后端确认 `nextFollowupAt` 对无计划线索为 null、语义混乱；专用参数语义正确（assigned 置顶、NULL 排尾） |
| 顶栏计数布局 | 左计数 / 中标题 / 右图标（不采用标题左对齐） | 用户拍板文字短不重叠，保留「线索」居中视觉一致 |

### 验证

| 验证项 | 结果 |
|------|------|
| `flutter analyze lib/pages/leads/` | 0 issue |
| 构建 + 装真机 | `app-release.apk`，Redmi K60(`3e06fd6d`) 实测通过 |
| 真机实测 | 默认即「待跟进优先」顺序；经理/管理员顶栏左侧显示「共 X 条」、无独立统计行；员工视角不变 |

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
| 通话记录列表页 | 16 | P1 | ✅ v0.17（手机号搜索 + 行跳线索详情；详情页/编辑/删除留作下轮） |
| 日程列表页 | 10 | P1 | ✅ v0.12（双 Tab/范围/分组吸顶/共享统计+角标） |
| 日程详情页（doc 11）+ 操作（完成/取消/新建） | 11/12 | P1 | ✅ v0.13 / v0.14 打磨 |
| 客户列表 | 17 | P1 | ✅ v0.18（客户详情拍板不开发，点卡片跳线索详情） |
| 个人中心 | 13 | P1 | ✅ v0.16（个人中心页 + 5 处 UI 调整）+ v0.32（个人统计整页 + 入口接线） |
| 线索详情「查看全部」跳转 + 日程搜索页 | — | P1 | ✅ v0.19（最近日程/通话查看全部跳搜索页 + 删除重复操作栏） |
| 公海线索池 + 顶部栏布局重构 | 06 | P1 | ✅ v0.22（公海列表 + 领取 + Tab 合并到顶部栏 + 双控制器搜索独立） |
| 设置页 | 19 | P1 | ✅ v0.20（三段列表 + 退出/全设备退出 + 关于弹窗 + 后端版本） |
| 修改密码页 | 15 | P1 | ✅ v0.21（三输入框 + 密码强度 + 6 步校验 + 成功 Toast→跳转） |
| 首页日程接口合并 | 09/10 | P1 | ✅ v0.27（home-summary 聚合端点，首屏请求 4→2） |
| 通话记录列表优化 | 04 | P1 | ✅ v0.28（首屏 5 分钟缓存 + TM/TA 卡片拨打人） |
| 团队模块（入口/统计/日程/线索池） | 20/21/22/23 | P1 | 阶段一✅（团队线索池：归属人圆点/统计摘要条/归属人筛选）；阶段二三📋未开发 |
| 全端待办角标口径统一 | 04(续) | P1 | ✅ v0.29（弃 dueToday，统一读 todayPending；stats/mine+stats 顶层已返 todayPending，与 home-summary 同源） |
| 跨账号缓存隔离 + 登录时序 + 日程 Tab 数字 | 34 | P1 | ✅ v0.34（CacheCoordinator 分层清退 + 缓存 key 加 userId/tenantId 维度 + force tenantId 修 2 bug + 日程 mine/team 双口径随 scope） |
| 管理员/经理适配改造 | 35 | P1 | ✅ v0.35（编辑分流/客户编辑抽屉/客户列表全部/归属人过滤/日程归属人默认值+抽屉选择器/标签修正/级别颜色/缓存 role 修复） |

---

> 本文档与 `docs/dev/HANDOVER.md`（交接文档）配套使用。
> ⚠️ 旧 `HANDOVER_05_LEAD_DETAIL.md` 中"3 个并行请求""拨号后弹面板未做"等描述已过时，以本表与代码现状为准。
> 节点版本：v0.33 | 更新日期：2026-07-26
