# 电销工作台 APP — 开发交接文档

> 本文档用于向后继开发者移交项目信息，涵盖项目概况、技术栈、项目结构、环境搭建、开发流程、后续规划。
> 版本：v2.0（2026-07-22）

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
| 线索 | 列表（搜索/筛选/排序/分页/无限滚动/下拉刷新） | ✅ v0.6 |
| 线索详情 | 信息区、跟进时间线、操作面板 | 📋 v0.7 |
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
│   │   ├── APP_PRODUCT_DESIGN.md
│   │   ├── api.md                     # API 接口文档（必读）
│   │   └── page-design/              # 各页面设计规范
│   └── dev/                          # 开发文档
│       ├── DEVELOPMENT_PITFALLS.md    # 踩坑记录 ← 新开发者必读
│       ├── HANDOVER.md               # 本文件
│       ├── MILESTONES.md             # 节点记录
│       └── PLAN_*.md                 # 各页面开发计划
│
├── lib/
│   ├── main.dart                     # 入口
│   ├── app.dart                      # App 根组件 + AuthGate 路由守卫
│   │
│   ├── models/                       # 数据模型
│   │   ├── user.dart                 # 用户（含 mustResetPassword）
│   │   ├── home_stats.dart           # 首页统计
│   │   ├── schedule.dart             # 日程
│   │   ├── lead.dart                 # 线索（含 project/owner 子模型）
│   │   └── option_item.dart          # 下拉选项通用模型
│   │
│   ├── services/                     # 网络/数据服务
│   │   ├── api_constants.dart        # 端点 + 配置（含 optionsCacheTTL）
│   │   ├── api_client.dart           # Dio 单例 + 拦截器
│   │   ├── api_exception.dart        # 统一错误码
│   │   ├── token_storage.dart        # Token 安全存储
│   │   ├── auth_service.dart         # 登录/登出/改密
│   │   ├── home_service.dart         # 首页 4 接口
│   │   ├── lead_service.dart         # 线索列表 + 选项
│   │   ├── options_cache_service.dart # 选项缓存（内存+本地持久化）
│   │   └── local_storage_service.dart # 本地凭据存储
│   │
│   ├── providers/                    # Riverpod 状态管理
│   │   ├── auth_provider.dart        # 认证状态（含 423 改密）
│   │   ├── home_provider.dart        # 首页 + 轮询
│   │   ├── lead_list_provider.dart   # 线索列表 + 搜索/筛选/排序
│   │   └── options_provider.dart     # 选项缓存 Provider
│   │
│   ├── pages/
│   │   ├── login/                    # 登录页
│   │   ├── home/                     # 首页看板
│   │   ├── leads/                    # 线索列表页
│   │   ├── force_change_password/    # 强制改密页
│   │   ├── main_shell.dart           # 底部 4 Tab 导航壳
│   │   └── coming_soon_page.dart     # 占位页（待开发功能）
│   │
│   └── widgets/
│       └── lead_card.dart            # 线索卡片组件（ConsumerWidget）
│
└── pubspec.yaml
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
# Android toolchain 应为 [✓]，Xcode ❌ 可忽略
```

---

## 5. 构建与运行

### 5.1 常用命令

```bash
flutter pub get              # 获取依赖
flutter analyze              # 代码分析（零错误零警告为合格）
flutter build apk --debug    # 构建 APK
adb install -r build/app/outputs/flutter-apk/app-debug.apk  # 安装到真机
```

### 5.2 真机调试

1. 手机开启 **开发者选项** → **USB 调试**
2. `flutter devices` 确认设备已识别
3. `flutter run -d <设备ID>` 或 `flutter build apk --debug` + `adb install`

> `flutter run` 退出时 exit code 2 是调试协议断开，不影响 APP 运行。

---

## 6. 当前进度

### ✅ 已完成（v0.1 ~ v0.6）

| 节点 | 内容 | 关键文件 |
|------|------|---------|
| v0.1 | 项目初始化 + 登录页 UI | login_page.dart |
| v0.2 | 网络层(dio) + Riverpod + 登录API对接 + Token管理 | api_client, auth_service, auth_provider |
| v0.3 | 保存邮箱/密码 + 复选框状态持久化 + TokenStorage 修复 | local_storage_service |
| v0.4 | 强制改密页 + 423 兜底拦截 | force_change_password_page |
| v0.5 | 首页看板 + 底部4Tab导航 + 通讯录状态重置 | home_page, main_shell, home_provider |
| v0.6 | 线索列表页（搜索/筛选/排序/分页/卡片） | leads_list_page, lead_card, options_cache |

### 📋 待开发

见 `MILESTONES.md` 中的"下一步节点规划"。

---

## 7. 架构要点

### 认证流程

```
AuthGate (app.dart)
  ├─ initial → CircularProgressIndicator
  ├─ unauthenticated → LoginPage
  ├─ authenticating → LoginPage（按钮 loading）
  ├─ authenticated → MainShell（4 Tab）
  └─ forceChangePassword → ForceChangePasswordPage
```

### 网络层

```
ApiClient (Dio)
  ├─ onRequest: 注入 Authorization header
  └─ onError:
       ├─ 423 FORCE_CHANGE_PASSWORD → onForceChangePassword callback
       └─ 401 → 尝试 refresh → 重试原请求
```

### 底部导航（MainShell）

```
IndexedStack (保持状态)
  ├─ Tab 0: HomePage（首页看板）
  ├─ Tab 1: LeadsListPage（线索列表）✅ 已实现
  ├─ Tab 2: ComingSoonPage（日程管理）📋
  └─ Tab 3: _ProfileTab（我的）
```

---

## 8. 已知问题与风险

| 问题 | 风险 | 状态 |
|------|------|------|
| `_TDIconsData extends IconData`（Dart 3.12） | 🔴 高 | 已本地 patch pub cache |
| `TDCheckbox` Android 白屏 | 🔴 高 | 已用 Material 替代 |
| `image_picker_android` 嵌套类 (D8) | 🟡 中 | dependency_overrides 锁定 |
| `package_info_plus` KGP 警告 | 🟢 低 | 可忽略，未来可能阻断 |

---

## 9. 依赖版本锁定

```yaml
dependency_overrides:
  image_picker_android: 0.8.13+13
```

---

## 10. 后续开发建议

1. **先读踩坑文档**：`docs/dev/DEVELOPMENT_PITFALLS.md`
2. **UI 迭代用真机**：Web 构建有 TDesign 兼容问题，直接用 `flutter build apk --debug` + `adb install`
3. **逐页开发**：每完成一个页面，写计划→开发→真机测试→文档→commit
4. **关注 `tdesign_flutter` 更新**：当前 0.2.7 有多个兼容问题，新版本可能修复
5. **OptionsCacheService 复用**：项目内多处需要选项数据（筛选面板、卡片显示），统一通过该服务获取

---

> **项目状态**：v0.6 — 线索列表页开发完成  
> **更新日期**：2026-07-22
