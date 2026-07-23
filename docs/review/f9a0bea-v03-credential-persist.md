# 代码审查：v0.3 本地凭据持久化与登录流程打磨

- 提交：`f9a0bea`
- 类型：`feat`
- 作者 / 日期：FungLeo / 2026-07-22
- 审查人：Mobile App Builder（移动端小组组长）
- 审查日期：2026-07-23
- 审查基准：已提交代码（干净基线 flutter analyze：21 issues / 0 error；本提交贡献 0）

## 一、改动概览

| 文件 | 说明 |
|------|------|
| lib/services/local_storage_service.dart | **新增**：本地凭据存储（邮箱明文 / 密码加密） |
| lib/services/token_storage.dart | 微调（沿用 flutter_secure_storage） |
| lib/pages/login/login_page.dart | 登录页增量（+128 行：记住密码、自动填充） |
| lib/pages/home/home_page.dart | +102 行（首页占位初版，后续 7bb07ad 重写） |
| lib/providers/auth_provider.dart | +6 行 |

## 二、客观质量门禁（flutter analyze）

**本提交贡献 0 issue**（无 error/warning/info）。✅

## 三、规范与质量评估

### 3.1 安全性（重点）
- ✅ `local_storage_service.dart` 安全设计合理：
  - 密码 → `flutter_secure_storage`（Android Keystore / iOS Keychain 加密），符合移动安全基线。
  - 邮箱 → `SharedPreferences` 明文，但已在文件头注释明确「非敏感信息」，决策有交代。
- ✅ `token_storage.dart` 的 `clearAll()` 仅删 Token/用户相关 key，注释说明「避免误伤 LocalStorageService 保存的密码」，边界清晰。

### 3.2 注释与结构
- `local_storage_service.dart` 带 `///` 文件头、方法注释，结构清晰（按「邮箱 / 密码 / 复选框」分组，符合 §5.2 状态分组思想）。
- ⚠️ 文件头注释位于 import 之后（违反 §2.2，与全仓普遍写法一致）。

### 3.3 命名
- ⚠️ 常量 `_keySavedEmail` 等用 `_keyXxx` 前缀（与 §3「`k` 前缀」建议不符，属项目内部统一风格，低优先级）。

## 四、问题清单

| 级别 | 位置 | 问题 | 建议 |
|------|------|------|------|
| 提示 | local_storage_service.dart | 文件头在 import 之后 | 调整至顶部（§2.2） |
| 低 | 常量命名 `_keyXxx` | 与 §3 不符 | 规范定稿后统一 |

## 五、审查结论

**✅ 通过。** 凭据持久化是安全敏感模块，本提交处理得当：敏感数据加密存储、非敏感数据明文但有注释说明、清理边界清晰。无 lint 问题。仅低优先级文档位置/命名项。
