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

## 下一步节点规划

### P0 - 核心流程（下一节点 v0.3）

| 模块 | 优先级 | 估算 |
|------|:------:|:----:|
| 首页看板（今日概况 + 待办预览） | P0 | 2d |
| 线索列表页（搜索/筛选/分页） | P0 | 2d |
| 线索详情页（拨号/跟进/时间线） | P0 | 3d |
| 拨号回传 + 反馈面板 | P0 | 3d |
| 日程列表 + 操作（完成/取消/新建） | P0 | 2d |

### P1 - 辅助功能

| 模块 | 优先级 | 估算 |
|------|:------:|:----:|
| 跟进记录编辑/删除 | P1 | 1d |
| 个人统计概览 | P1 | 1d |
| 修改密码 | P1 | 0.5d |
| 公海自领（allowSelfClaim） | P1 | 1d |

---

> 本文档与 `docs/dev/HANDOVER.md`（交接文档）配套使用。
> 节点版本：v0.3 | 更新日期：2026-07-22
