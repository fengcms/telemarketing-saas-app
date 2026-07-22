# 电销工作台 APP — 开发交接文档

> 本文档用于向后继开发者移交项目信息，涵盖项目概况、技术栈、项目结构、环境搭建、开发流程、后续规划。
> 版本：v3.0（2026-07-22）

---

## 1. 项目概览

### 1.1 产品定位

电销坐席的**工作手机工具**——坐席每天打开、用来完成「看线索 → 打电话 → 记结果 → 约下次」全流程的专用 Android 客户端。

### 1.2 目标用户

| 角色 | 英文 | 说明 |
|------|------|------|
| 坐席（员工） | TE | **核心用户**。自己的线索、拨号、跟进、日程、统计 |
| 经理 | TM | 辅助用户。可查看团队数据 |
| 管理员 | TA | 同上，管理功能在后台 Web 完成 |

> **重要**：平台超管（PSA）不在 APP 覆盖范围。

### 1.3 核心功能范围（v1.0）

| 模块 | 功能 | 状态 |
|------|------|------|
| 认证 | 登录（邮箱+密码）、Token 管理、强制改密、登出 | ✅ v0.2~v0.4 |
| 首页 | 今日概况卡片、待办日程预览、10 分钟轮询、快捷入口 | ✅ v0.5 |
| 线索 | 列表（搜索/筛选/排序/分页/无限滚动/下拉刷新/卡片） | ✅ v0.6 |
| 线索详情 | 信息区、跟进时间线、操作面板 | 📋 待开发 |
| 通话 | 调系统拨号盘、半自动回传、反馈面板 | 📋 待开发 |
| 跟进 | 时间线、提交（接听类型/备注/分类）、编辑/删除 | 📋 待开发 |
| 日程 | 待办列表、Badge、完成/取消/新建/一键拨号/到期提醒 | 📋 待开发 |
| 个人 | 统计概览、修改密码、登出、通话记录 | 📋 待开发 |

---

## 2. 技术栈

| 项目 | 选型 | 版本 | 说明 |
|------|------|------|------|
| 框架 | **Flutter** | 3.44.7 | 声明式 UI，仅 Android 目标 |
| Dart | Dart SDK | 3.12.2 | |
| UI 组件库 | **TDesign Flutter** | 0.2.7（已本地 patch） | 腾讯开源，中文友好 |
| 状态管理 | **Riverpod** | 2.6.1 | `flutter_riverpod` |
| 网络层 | **dio** | 5.7.0 | Token 注入、自动刷新、错误码解析 |
| 路由 | **GoRouter** | 14.8.0 | 已添加待使用（当前用 AuthGate 状态驱动） |
| 安全存储 | **flutter_secure_storage** | 9.2.0 | Token/密码加密存储 |
| 本地存储 | **shared_preferences** | 2.3.0 | 邮箱、复选框状态、Options 缓存 |
| 版本号 | **package_info_plus** | 8.3.1 | |
| 网络状态 | **connectivity_plus** | 6.x | 离线检测 |
| Android | compileSdk/Target | 36（API 36） | Android 16 |
| Gradle | Gradle | 9.1.0 | |
| JDK | Eclipse Temurin | 26.0.1 | OpenJDK |

> **⚠️ TDesign Flutter 本地 patch 说明**：`tdesign_flutter 0.2.7` 与 Dart 3.12 存在兼容性问题（`IconData final class` 导致 `_TDIconsData extends IconData` 编译失败），已手动修改 pub 缓存中的 `td_icons.dart`。详见 [开发踩坑记录](./DEVELOPMENT_PITFALLS.md#21-_tdiconsdata-extends-icondata--dart-312-不兼容)。

---

## 3. 项目结构

```
telemarketing-saas-app/
├── docs/
│   ├── design/                       # 产品设计文档
│   │   ├── APP_PRODUCT_DESIGN.md     # 产品整体设计
│   │   ├── api.md                    # API 接口文档（必读）
│   │   └── page-design/             # 各页面设计规范
│   │       ├── 00-TDesign-Flutter-设计规范.md
│   │       ├── 01-登录页.md
│   │       ├── 02-强制改密页.md
│   │       ├── 03-首页看板.md
│   │       └── 04-线索列表.md
│   └── dev/                          # 开发文档
│       ├── DEVELOPMENT_PITFALLS.md   # 踩坑记录 ← 新开发者必读
│       ├── HANDOVER.md               # 本文件
│       ├── MILESTONES.md             # 节点记录
│       └── PLAN_*.md                 # 各页面开发计划
│
├── lib/
│   ├── main.dart                     # 入口（ProviderScope 包裹）
│   ├── app.dart                      # App 根组件 + AuthGate 路由守卫
│   │
│   ├── constants/                    # 共享常量
│   │   └── lead_constants.dart       # 线索状态码→中文名映射 + 颜色样式
│   │
│   ├── models/                       # 数据模型
│   │   ├── user.dart                 # 用户（含 mustResetPassword）
│   │   ├── home_stats.dart           # 首页统计（支持两个接口数据 merge）
│   │   ├── schedule.dart             # 日程（含逾期判断）
│   │   ├── lead.dart                 # 线索（含 categoryId/projectId 子模型）
│   │   └── option_item.dart          # 下拉选项通用模型（value/label）
│   │
│   ├── services/                     # 网络/数据服务
│   │   ├── api_constants.dart        # 端点 + 配置（含 optionsCacheTTL 可调）
│   │   ├── api_client.dart           # Dio 单例 + Token 注入 + 423/401 拦截
│   │   ├── api_exception.dart        # 统一错误码模型
│   │   ├── token_storage.dart        # Token 安全存储（KEYS 白名单管理）
│   │   ├── auth_service.dart         # 登录/登出/强制改密
│   │   ├── home_service.dart         # 首页 4 接口
│   │   ├── lead_service.dart         # 线索列表 + 筛选选项
│   │   ├── options_cache_service.dart # 选项缓存（内存+SharedPreferences 持久化）
│   │   └── local_storage_service.dart # 本地凭据存储（邮箱/密码/复选框状态）
│   │
│   ├── providers/                    # Riverpod 状态管理
│   │   ├── auth_provider.dart        # 认证状态（含 423 改密 + cancelForceChange）
│   │   ├── home_provider.dart        # 首页 + 10 分钟轮询 + auth 监听自动重置
│   │   ├── lead_list_provider.dart   # 线索列表 + 搜索/筛选/排序/分页
│   │   └── options_provider.dart     # 选项缓存 Provider
│   │
│   ├── pages/
│   │   ├── login/                    # 登录页（邮箱后缀下拉、保存凭据、模拟错误）
│   │   ├── home/                     # 首页看板（四宫格、日程预览、快捷入口）
│   │   ├── leads/                    # 线索列表页（搜索栏、筛选面板、排序弹窗）
│   │   ├── force_change_password/    # 强制改密页（密码强度指示器）
│   │   ├── main_shell.dart           # 底部 4 Tab 导航壳（IndexedStack）
│   │   └── coming_soon_page.dart     # 占位页（待开发功能路由目标）
│   │
│   └── widgets/
│       └── lead_card.dart            # 线索卡片组件（ConsumerWidget，5 行布局）
│
└── pubspec.yaml                      # 依赖配置 + dependency_overrides
```

---

## 4. 环境搭建

### 4.1 前置条件

| 组件 | 安装方式 | 备注 |
|------|---------|------|
| Flutter SDK | `brew install flutter` | 3.44.7 |
| Java JDK 17+ | `brew install --cask temurin` | 需 sudo 权限 |
| Android SDK | 已安装 `~/Library/Android/sdk/` | |
| Android Build Tools | `sdkmanager "build-tools;36.0.0"` | 已安装 |
| Android NDK | `sdkmanager "ndk;28.2.13676358"` | 已安装 |
| cmdline-tools | `brew install --cask android-commandlinetools` | 已 symlink 到 SDK 目录 |
| VS Code | 可选 | 推荐装 Flutter/Dart 插件 |

### 4.2 环境变量

```bash
# ~/.zshrc
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
```

### 4.3 验证

```bash
flutter doctor
# Android toolchain 应为 [✓]，Xcode/CocoaPods ❌ 可忽略
```

### 4.4 本地补丁说明

每次 `flutter pub upgrade` 后检查 `td_icons.dart` 是否被覆盖：

```bash
# 如果出现 "_TDIconsData extends IconData" 编译错误
# 编辑以下文件，将 _TDIconsData 替换为 IconData
# ~/.pub-cache/hosted/pub.dev/tdesign_flutter-0.2.7/lib/src/components/icon/td_icons.dart
```

---

## 5. 构建与运行

### 5.1 常用命令

```bash
flutter pub get                          # 获取依赖
flutter analyze                          # 代码分析（以零 error 为合格）
flutter build apk --debug                # 构建 APK
adb install -r build/app/outputs/flutter-apk/app-debug.apk  # 安装到真机
```

### 5.2 真机调试

1. 手机开启 **开发者选项** → **USB 调试**
2. `flutter devices` 确认设备已识别
3. `flutter run -d <设备ID>` 或 `flutter build apk --debug` + `adb install`

> `flutter run` 退出时 exit code 2 是调试协议断开，不影响 APP 运行。

### 5.3 开发工作流（重要）

```
读设计文档 → 读 api.md 找接口 → 写开发计划(PLAN_*.md)
  → 用户确认 → 开发 → 真机实测 → 反馈修正
  → 写文档(MILESTONES + PITFALLS) → git commit & push
```

> **API 文档使用原则**：如果 `api.md` 中的接口返回结构不清晰、字段含义不明确，**必须向产品确认**，不能自行猜测。

---

## 6. 当前进度

### ✅ 已完成（v0.1 ~ v0.6）

| 节点 | 内容 | 关键文件 |
|------|------|---------|
| v0.1 | 项目初始化 + 登录页 UI | login_page.dart |
| v0.2 | 网络层(dio) + Riverpod + 登录API对接 + Token管理 | api_client, auth_service, auth_provider |
| v0.3 | 保存邮箱/密码 + 复选框状态持久化 + TokenStorage 修复 | local_storage_service |
| v0.4 | 强制改密页 + 423 兜底拦截 + 密码强度指示器 | force_change_password_page |
| v0.5 | 首页看板 + 底部4Tab导航 + 切换账号自动刷新 | home_page, main_shell, home_provider |
| v0.6 | 线索列表页（搜索/筛选/排序/分页/卡片/状态码映射） | leads_list_page, lead_card, options_cache |

### 📋 待开发优先级

| 优先级 | 模块 | 参考设计文档 |
|:------:|------|-------------|
| P0 | 线索详情页（跟进时间线、拨号入口） | 05-线索详情.md |
| P0 | 拨号回传 + 反馈面板 | （待设计） |
| P0 | 日程列表 + 操作 | 06-日程页.md |
| P1 | 跟进记录编辑/删除 | |
| P1 | 个人中心（统计、设置、修改密码） | |

---

## 7. 架构要点

### 7.1 认证流程

```
AuthGate (app.dart)
  ├─ initial → CircularProgressIndicator（检查本地 Token）
  ├─ unauthenticated → LoginPage
  ├─ authenticating → LoginPage（按钮 loading）
  ├─ authenticated → MainShell（4 Tab）
  └─ forceChangePassword → ForceChangePasswordPage
```

### 7.2 网络层

```
ApiClient (Dio)
  ├─ onRequest: 注入 Authorization header (Bearer token)
  ├─ onError 401: 尝试 refresh → 重试原请求（带队列锁防并发）
  └─ onError 423: → onForceChangePassword callback → 跳转改密页
```

### 7.3 底部导航（MainShell）

```
IndexedStack (保持各 Tab 页面状态)
  ├─ Tab 0: HomePage（首页看板 — 四宫格 + 日程预览 + 快捷入口）
  ├─ Tab 1: LeadsListPage（线索列表 — 搜索/筛选/排序/分页）✅
  ├─ Tab 2: ComingSoonPage（日程管理）📋
  └─ Tab 3: _ProfileTab（我的 — 用户信息 + 退出）
```

### 7.4 选项缓存（OptionsCacheService）

```
APP 启动 → 读 SharedPreferences（本地缓存，即时可用）
         → 后台静默刷新 API → 更新缓存
         → 下次启动优先读本地，跳过请求

TTL: 1800秒（30分钟），可在 api_constants.dart 中调整
用途: 线索卡片显示分类/项目名、筛选面板选项列表
```

### 7.5 数据流模式

```
页面 (ConsumerWidget/ConsumerStatefulWidget)
  → ref.watch(provider) 监听状态
  → ref.read(provider.notifier).action() 触发操作
  → Provider 调用 Service → Service 调用 ApiClient(Dio)
  → 返回结果 → Provider 更新 state → UI 自动重建
```

---

## 8. 关键踩坑速查

| 坑点 | 影响 | 解决方案 |
|------|------|---------|
| `_TDIconsData extends IconData`（Dart 3.12） | 🔴 编译阻断 | 本地 patch pub cache 中的 td_icons.dart |
| `TDCheckbox` Android 白屏 | 🔴 运行崩溃 | 用 Material Checkbox 替代 |
| `image_picker_android` D8 嵌套类 | 🔴 编译阻断 | `dependency_overrides` 锁定版本 |
| `FlutterSecureStorage.deleteAll()` 误删密码 | 🟠 功能异常 | 改用 `delete(key)` 仅删除自己管理的 key |
| `copyWith` 可空参数覆盖筛选条件 | 🟠 功能异常 | 用 sentinel 模式区分"未传"和"传 null" |
| API 返回 `categoryId`/`projectId` 而非名称 | 🟡 数据显示 | 用 OptionsCacheService 查缓存匹配 |
| 搜索自动触发浪费带宽 | 🟡 性能 | 改按钮触发，去掉 debounce |

> 完整踩坑记录请阅读 `docs/dev/DEVELOPMENT_PITFALLS.md`

---

## 9. 依赖版本锁定

```yaml
dependency_overrides:
  image_picker_android: 0.8.13+13
```

---

## 10. 后续开发建议

1. **先读踩坑文档**：`docs/dev/DEVELOPMENT_PITFALLS.md` 记录了当前所有已知坑点
2. **API 文档不明确要问**：`api.md` 中的接口返回结构不清晰时，必须向产品确认字段名和格式
3. **UI 迭代用真机**：TDesign Web 构建有兼容问题，直接用 `flutter build apk --debug` + `adb install`
4. **逐页开发**：每完成一个页面，按流程走（计划→开发→真机测试→文档→commit），最多一次开发一个页面
5. **筛选条件恢复逻辑**：`LeadListState.copyWith` 使用了 sentinel 模式，新增可空筛选字段时必须按此模式处理
6. **复用 `LeadConstants`**：线索状态码→中文名映射已抽取到 `lib/constants/lead_constants.dart`，其他地方直接引用
7. **关注 `tdesign_flutter` 更新**：当前 0.2.7 有多个兼容问题，新版本可能修复，升级后需验证 td_icons.dart 的本地 patch

---

> **项目状态**：v0.6 — 线索列表页开发完成（2026-07-22）
> **更新日期**：2026-07-22
