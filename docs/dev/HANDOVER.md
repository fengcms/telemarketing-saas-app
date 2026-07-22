# 电销工作台 APP — 开发交接文档

> 本文档用于向后继开发者移交项目信息，涵盖项目概况、技术栈、项目结构、环境搭建、开发流程、后续规划。
> 版本：v1.0（2026-07-22）

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

| 模块 | 功能 |
|------|------|
| 认证 | 登录（邮箱+密码）、Token 管理、强制改密、登出 |
| 首页 | 今日概况卡片、待办日程预览、10 分钟轮询 |
| 线索 | 列表（搜索/筛选/排序）、详情、拨号、**公海自领** |
| 通话 | 调系统拨号盘、半自动回传、反馈面板、draft 持久化 |
| 跟进 | 时间线、提交（接听类型/备注/分类）、编辑/删除 |
| 日程 | 待办列表、Badge、完成/取消/新建/一键拨号/到期提醒 |
| 个人 | 统计概览、修改密码、登出、通话记录 |
| TM/TA | 团队线索池、团队日程、团队统计（v1.1） |

---

## 2. 技术栈

| 项目 | 选型 | 版本 | 说明 |
|------|------|------|------|
| 框架 | **Flutter** | 3.44.7 | 声明式 UI，Platform Channel 访问原生权限 |
| Dart | Dart SDK | 3.12.2 | |
| UI 组件库 | **TDesign Flutter** | 0.2.7（已本地 patch） | 腾讯开源，中文友好 |
| 状态管理 | 待定 | — | 推荐 Riverpod 或 Bloc |
| 网络层 | `dio` | 待接入 | Token 注入、全局错误码处理 |
| 安全存储 | `flutter_secure_storage` | 待接入 | Token/密码加密存储 |
| 版本号 | `package_info_plus` | 8.3.1 | — |
| Android | compileSdk/Target | 36（API 36） | Android 16 |
| Gradle | Gradle | 9.1.0 | |
| JDK | Eclipse Temurin | 26.0.1 | OpenJDK |

> **⚠️ TDesign Fluxter 本地 patch 说明**：`tdesign_flutter 0.2.7` 与 Dart 3.12 存在兼容性问题（`IconData final class`），详见 [开发踩坑记录](./DEVELOPMENT_PITFALLS.md#21-_tdiconsdata-extends-icondata--dart-312-不兼容)。

---

## 3. 项目结构

```
telemarketing-saas-app/
├── android/                     # Android 原生配置
│   ├── app/
│   │   ├── build.gradle.kts    # 应用级构建配置
│   │   └── proguard-rules.pro  # 混淆规则
│   └── build.gradle.kts        # 项目级构建配置
│
├── assets/
│   └── images/                  # 图片资源（Logo 等）
│
├── docs/
│   ├── design/                  # 产品设计文档
│   │   ├── APP_PRODUCT_DESIGN.md     # 主设计文档
│   │   └── page-design/              # 各页面设计文档
│   │       ├── 00-TDesign-Flutter-设计规范.md  # 设计令牌
│   │       ├── 01-登录页.md                  # 登录页 UI 规范
│   │       └── ...                          # 其他页面
│   └── dev/
│       ├── DEVELOPMENT_PITFALLS.md  # 踩坑记录 ← 必读
│       └── (本文档)                  # 交接文档
│
├── lib/
│   ├── main.dart                # 入口（竖屏锁定 + runApp）
│   ├── app.dart                 # App 根组件（TDTheme + MaterialApp）
│   ├── pages/                   # 页面目录
│   │   └── login/
│   │       └── login_page.dart  # 登录页（当前唯一实现页）
│   └── widgets/                 # 公共组件（待增长）
│
├── test/
│   └── widget_test.dart         # 简单冒烟测试
│
├── pubspec.yaml                 # 依赖管理
└── analysis_options.yaml        # Lint 规则
```

---

## 4. 环境搭建

### 4.1 前置条件

| 组件 | 安装方式 | 备注 |
|------|---------|------|
| Flutter SDK | `brew install flutter` | 已安装 3.44.7 |
| Java JDK 17+ | `brew install --cask temurin` | 需 sudo 权限 |
| Android SDK | `sdkmanager "platform-tools" "platforms;android-36"` | 已安装 |
| Android Build Tools | `sdkmanager "build-tools;36.0.0"` | 已安装 |
| Android NDK | `sdkmanager "ndk;28.2.13676358"` | 已安装 |
| VS Code | `brew install --cask visual-studio-code` | 可选，推荐 |

### 4.2 环境变量

```bash
# ~/.zshrc 中配置（已验证通过）
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$ANDROID_HOME/emulator"
```

### 4.3 验证安装

```bash
flutter doctor
```

期望输出中 Android toolchain 为 `[✓]`，Xcode 的 ❌ 可忽略（本项目仅 Android）。

---

## 5. 构建与运行

### 5.1 常用命令

```bash
# 获取依赖
flutter pub get

# 代码分析
flutter analyze

# Web 预览（开发 UI 时最方便）
flutter run -d chrome

# 真机运行（USB 连接 + 开启调试）
flutter run -d <device-id>

# 查看已连接设备
flutter devices

# 清理构建缓存
flutter clean

# 构建 APK
flutter build apk --debug
flutter build apk --release    # release 需配置签名
```

### 5.2 真机调试说明

1. 手机开启 **开发者选项** → **USB 调试**
2. USB 连接电脑
3. `flutter devices` 确认设备已识别
4. `flutter run -d <设备ID>` 运行

> **注意**：`flutter run` 在退出后（exit code 2）通常是因为调试协议连接断开，**不影响 APP 在手机上正常运行**。

### 5.3 快速迭代工作流

```bash
# 推荐开发方式
1. 修改代码
2. flutter analyze  # 快速检查
3. flutter run -d chrome  # 浏览器预览（热重载秒级）
4. 确认 UI 后 → flutter run -d <android>  # 真机验证
```

---

## 6. 当前进度

### ✅ 已完成

- [x] Flutter 项目初始化
- [x] TDesign Flutter 集成（含本地兼容性 patch）
- [x] Android SDK 环境配置（Build Tools/NDK）
- [x] 登录页 UI 实现（含邮箱后缀选择器、@自动切换、验证状态）
- [x] 登录页交互逻辑（表单校验、Loading 态、错误态、锁定倒计时）
- [x] Web 预览 + 真机运行双重验证

### 📋 待开发（按优先级）

#### P0 - 核心流程（MVP 必须）

- [ ] **网络层接入（dio）**
  - Token 拦截器（accessToken 注入、refresh 自动换发）
  - 全局错误码映射（401/423/429 等）
  - 基础请求封装
- [ ] **状态管理选型与搭建**
  - 推荐 Riverpod 或 Bloc
  - 统一的状态管理规范
- [ ] **登录 API 对接**
  - POST `/api/auth/login` → 存储 Token
  - Token 有效期管理
  - 强制改密跳转逻辑
- [ ] **首页看板**
  - 今日概况卡片（待办数、跟进数、接通数、线索数）
  - 待办日程预览（最多 5 条）
  - 10 分钟自动轮询

#### P1 - 核心功能

- [ ] **线索列表页**（搜索/筛选/排序/分页）
- [ ] **线索详情页**（信息区、跟进时间线、操作面板）
- [ ] **拨号 + 通话回传**（系统拨号盘、READ_CALL_LOG、反馈面板）
- [ ] **跟进记录**（时间线、提交、编辑/删除）
- [ ] **日程**（列表、完成/取消、新建、一键拨号）

#### P2 - 辅助功能

- [ ] **个人统计**
- [ ] **客户列表**
- [ ] **通话记录列表**
- [ ] **修改密码 / 登出**
- [ ] **设置页面**

#### P3 - 增强功能（v1.1+）

- [ ] **公海自领**（TE 浏览公海并领取）
- [ ] **TM/TA 团队视图**（线索池、团队日程、团队统计）
- [ ] **日程增强**（重开、改期、统计）
- [ ] **通话记录补正**

---

## 7. 页面设计文档索引

所有页面设计文档位于 `docs/design/page-design/` 目录下，基于 TDesign Flutter 组件编写：

| 文档编号 | 页面 | 文件 |
|---------|------|------|
| 00 | TDesign Flutter 设计规范 | `00-TDesign-Flutter-设计规范.md` |
| 01 | 登录页 | `01-登录页.md` |
| 02 | 强制改密页 | (待查看) |
| ... | 其他页面 | (待查看) |

> **注意**：当前实现的登录页（`lib/pages/login/login_page.dart`）与设计文档 `01-登录页.md` 在细节上可能略有出入（如使用 Material 复选框替代 TDCheckbox），以真机可用为前提。UI 一致性可在后续迭代中补全。

---

## 8. 已知问题与风险

### 8.1 TDesign Flutter 兼容性风险

| 问题 | 风险等级 | 应对措施 |
|------|---------|---------|
| `_TDIconsData extends IconData`（Dart 3.12） | 🔴 **高** | 已本地 patch pub cache，官方发布修复版本后需移除 patch |
| `TDCheckbox` Android 白屏 | 🔴 **高** | 已用 Material 替代，官方修复后可切回 |
| `image_picker_android` 嵌套类问题 | 🟡 **中** | 已用 dependency_overrides 规避 |

### 8.2 技术决策待定项

| 待定项 | 建议 | 备注 |
|--------|------|------|
| 状态管理 | **Riverpod**（推荐）或 **Bloc** | 当前无状态管理，页内状态直接用 setState |
| 项目架构 | 推荐 MVVM 模式 | 网络层、数据层、UI 层分离 |
| 路由管理 | **GoRouter** | 需支持鉴权守卫（未登录→登录页） |

### 8.3 移动端独特实现的提醒

- **拨号**：调系统拨号盘（`Intent.ACTION_DIAL`），非 VoIP
- **通话回传**：需 `READ_CALL_LOG` 权限，通过 `Flutter Platform Channel` 调用
- **夜间禁呼**：软提醒，非硬阻断（无法阻止系统拨号盘）
- **无推送通知**：10 分钟轮询 + 下拉刷新替代
- **侧载分发**：不经过应用商店，直接安装 APK

---

## 9. 依赖版本锁定

当前 `pubspec.yaml` 中的关键依赖和 override：

```yaml
dependencies:
  tdesign_flutter: ^0.2.7        # ⚠️ 有已知兼容问题，需保持关注
  package_info_plus: ^8.0.0      # ⚠️ KGP 警告，未来可能不兼容

dependency_overrides:
  image_picker_android: 0.8.13+13  # 修复 D8 嵌套类编译错误
```

**升级前必做**：
1. 确认 `tdesign_flutter` 新版本已修复 `extends IconData` 问题
2. 移除本地 pub cache 中的 patch
3. 验证 Android 真机渲染正常

---

## 10. 后续开发建议

1. **从网络层开始**：先搭好 dio 封装和 Token 管理，后续页面开发才有数据支撑
2. **状态管理先行**：建议使用 Riverpod，与 TDesign 配合良好
3. **UI 开发用 Chrome**：`flutter run -d chrome` 热重载极快，适合快速迭代 UI
4. **真机验证不能省**：Web 正常 ≠ Android 正常（血泪教训）
5. **逐页实现，优先核心流程**：拨号→回传→跟进是最核心的链路，优先打通
6. **设计文档是依据不是圣经**：以设计文档为参考，以真机可用为准
7. **阅读踩坑文档**：`docs/dev/DEVELOPMENT_PITFALLS.md` 记录了所有已知问题

---

> **交接人**：Mobile App Builder  
> **交接日期**：2026-07-22  
> **项目启动里程碑**：Flutter 项目初始化 + 环境搭建 + 登录页 UI 实现  
> **下一阶段**：网络层搭建 → 登录 API 对接 → 首页看板
