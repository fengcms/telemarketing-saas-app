# 代码审查：v0.2 网络层 + 认证打通，登录页对接真实 API

- 提交：`bc59aae`
- 类型：`feat`
- 作者 / 日期：FungLeo / 2026-07-22
- 审查人：Mobile App Builder（移动端小组组长）
- 审查日期：2026-07-23
- 审查基准：已提交代码（干净基线 flutter analyze：21 issues / 0 error；本提交贡献 3 个 info）

## 一、改动概览

| 文件 | 说明 |
|------|------|
| lib/services/api_client.dart | Dio 单例 + Token 注入 + 401 静默刷新 + 423 兜底（**核心基础设施**） |
| lib/services/api_constants.dart | 基础 URL、登录/刷新端点、超时 |
| lib/services/api_exception.dart | 统一异常 `ApiException` |
| lib/services/auth_service.dart | 登录 / 自动登录 / 刷新 / 登出 |
| lib/services/token_storage.dart | Token 安全存储（flutter_secure_storage） |
| lib/providers/auth_provider.dart | Riverpod 认证状态机 `AuthNotifier` |
| lib/models/user.dart | 用户模型 |
| lib/pages/login/login_page.dart | 登录页初版（后续多次迭代） |

## 二、客观质量门禁（flutter analyze）

本提交贡献 **3 个 info（无 error/warning）**，均为 `prefer_initializing_formals`（建议用 `this.x` 初始化形式）：

| 位置 | 规则 | 说明 |
|------|------|------|
| lib/services/api_client.dart:27 | prefer_initializing_formals | `ApiClient({required TokenStorage tokenStorage}) : _tokenStorage = tokenStorage` |
| lib/services/auth_service.dart:18 | prefer_initializing_formals | 同上模式 |
| lib/services/auth_service.dart:19 | prefer_initializing_formals | 同上模式 |

## 三、规范与质量评估

### 3.1 注释与结构 ✅（优于后续多数提交）
- `api_client.dart`、`token_storage.dart`、`auth_service.dart`、`auth_provider.dart` 均带 `///` 文件头、类注释、方法注释，且**注释位于 import 之前**（符合 §2.2，属早期正确示范）。
- `api_client.dart` 的 token 刷新「并发锁 + 请求队列」设计成熟，401 重试逻辑完整，错误处理清晰（§7 达标）。
- `auth_provider.dart` 用 `StateNotifier` + `copyWith`，`login/forceChangePassword/logout` 均有 `ApiException` 捕获 + 兜底 `catch`，符合 §7.1。

### 3.2 健壮性（需关注）
- ⚠️ `api_client.dart:99-101`：`data['data']['accessToken'] as String` 直接强转，未做 `data['data'] is Map` / 字段非空判空。若后端返回结构异常会抛 `TypeError` 而非转成 `ApiException`。
  - 建议：`final d = data['data']; if (d is! Map) return null;` 再取值，与下方 `parseError` 的防御风格保持一致。

### 3.3 命名
- ⚠️ `token_storage.dart` / `local_storage_service.dart` 常量用 `_keyXxx` 前缀（如 `_keyAccessToken`），与规范 §3「建议 `k` 前缀」不一致；属项目内部统一风格，低优先级。

## 四、问题清单

| 级别 | 位置 | 问题 | 建议 |
|------|------|------|------|
| 提示 | api_client.dart:27 / auth_service.dart:18-19 | prefer_initializing_formals | 改 `this.tokenStorage` 形式 |
| 中 | api_client.dart:99-101 | 刷新响应字段强转缺判空 | 增加 `is Map` 与空值保护 |
| 低 | token_storage / local_storage_service | 常量命名 `_keyXxx` 与 §3 不符 | 规范二选一后统一（或维持现状并修订规范） |

## 五、审查结论

**✅ 通过（有条件）。** 网络层与认证是质量最高的模块之一：注释规范、错误处理完整、并发刷新设计成熟。仅 3 个 info 级 lint 与 1 处强转判空建议，不阻塞合入，建议下个迭代顺手清理。
