# 代码审查：v0.4 强制改密页 + 423 兜底拦截

- 提交：`ad6ec0a`
- 类型：`feat`
- 作者 / 日期：FungLeo / 2026-07-22
- 审查人：Mobile App Builder（移动端小组组长）
- 审查日期：2026-07-23
- 审查基准：已提交代码（干净基线 flutter analyze：21 issues / 0 error；本提交贡献 0）

## 一、改动概览

| 文件 | 说明 |
|------|------|
| lib/pages/force_change_password/force_change_password_page.dart | **新增（624 行）**：强制改密页（表单 + 校验 + 提交） |
| lib/providers/auth_provider.dart | +70 行：`forceChangePassword` / `cancelForceChangePassword` / `forceRedirect` |
| lib/services/api_client.dart | +14 行：423 `FORCE_CHANGE_PASSWORD` 拦截回调 |
| lib/services/auth_service.dart | +21 行：`forceChangePassword` API |
| lib/models/user.dart | +5 行 |

## 二、客观质量门禁（flutter analyze）

**本提交贡献 0 issue**（无 error/warning/info）。✅

## 三、规范与质量评估

### 3.1 设计
- ✅ 423 兜底机制设计优雅：`ApiClient` 拦截器捕获 `FORCE_CHANGE_PASSWORD` → 触发 `onForceChangePassword` 回调 → `AuthNotifier.forceRedirect()` 跳转改密页，网络层与 UI 解耦（§7.1 达标）。
- ✅ `auth_provider` 的 `forceChangePassword` 有 `ApiException` + 兜底 `catch`，改密成功后清空 Token 并回到登录态，流程完整。

### 3.2 结构（需关注）
- ⚠️ `force_change_password_page.dart` **单文件 624 行**，是仓内第三大文件。
  - 方法级拆分尚可：最大方法 `_buildNewPasswordInput` 78 行，含 8 个 `_build*` 辅助方法（§4.2 基本达标，无超 120 行上帝方法）。
  - 但单文件体量过大，维护成本高；密码强度校验、确认密码区块、表单提交区块可抽为独立 widget / mixin。

### 3.3 注释
- `force_change_password_page.dart` 含 16 行 `///`（文件头 + 类注释），但大量 `_build*` 辅助方法无 `///`（与全仓页面普遍情况一致，违反 §1.3）。
- ⚠️ 文件头位于 import 之后（§2.2）。

## 四、问题清单

| 级别 | 位置 | 问题 | 建议 |
|------|------|------|------|
| 中 | force_change_password_page.dart（624 行） | 单文件过大 | 抽离密码强度校验、表单区块为独立组件 |
| 提示 | force_change_password_page.dart | 文件头在 import 之后 | 调整至顶部（§2.2） |
| 低 | 各 `_build*` 辅助方法 | 缺 `///` 注释（§1.3） | 补关键方法注释 |

## 五、审查结论

**✅ 通过（有条件）。** 423 兜底设计与认证流程正确、无 lint 问题。主要改进点是**单文件 624 行偏大**，建议后续按区块拆分，提升可维护性。不阻塞合入。
