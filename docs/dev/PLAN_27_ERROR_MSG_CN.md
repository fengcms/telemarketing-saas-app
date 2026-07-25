# PLAN_27 登录 / 全端错误码中文文案映射方案

> 状态：**方案待确认，未改动任何代码**（用户要求本步只出方案）。

## 一、问题现象

登录失败时界面提示为英文（如账号密码错误时显示后端返回的英文 `message`），应显示对应的中文文案。

## 二、根因定位（现状链路）

登录报错信息的完整传递链路：

1. 后端返回 `{success:false, error:{code:'AUTH_INVALID', message:'Invalid account or password'}}`
2. `lib/services/api_client.dart` 的 `parseError()`（第 153–159 行）解析出 `code` 与 `message`，其中 `message` **直接取自后端英文 `error.message`**（`err['message']`）。
3. `lib/services/auth_service.dart` 的 `login()` 把 `ApiClient.parseError(e)` 作为 `ApiException` 抛出。
4. `lib/providers/auth_provider.dart` 的 `login()`（第 130–134 行）`on ApiException catch (e)` 将 `e.message` 赋给 `state.errorMessage`。
5. `lib/pages/login/login_page.dart`（第 564、574 行）读取 `errorMessage` 并 `Text(...)` 展示。

**结论**：前端对后端 `error.message` 做了原样透传，没有按 `error.code` 做中文映射。
`parseError` 是**全端唯一**的结构化错误解析入口，所有接口报错都经过它——因此这是全局性问题，不只是登录页。

## 三、配置位置（方案核心）

### 1. 新增错误码 → 中文映射表（唯一配置点）

新建文件 `lib/services/error_messages.dart`（与 `api_client.dart` / `api_exception.dart` 同目录，属于 service 层）：

```dart
/// 后端错误码 → 中文用户文案映射
///
/// 集中维护，便于统一文案。所有接口报错经 [ApiClient.parseError] 统一替换为中文。
class ErrorMessages {
  static const Map<String, String> _map = {
    'VALIDATION': '请求参数校验失败',
    'STATUS_ROLLBACK_FORBIDDEN':
        '状态回退被拒（converted 硬终态、Manager 正向校验拦截、日程状态非法流转）',
    'AUTH_INVALID': '账号或密码错误',
    'AUTH_EXPIRED': 'Token 过期或已吊销',
    'AUTH_FORBIDDEN': '权限不足',
    'TENANT_EXPIRED': '租户已锁定，请联系平台超管',
    'TENANT_IN_GRACE': '租户已到期，宽限期内仅可导出数据',
    'NOT_FOUND': '资源不存在',
    'LEAD_DUPLICATE': '同项目+手机号线索已存在',
    'BATCH_TOO_LARGE': '批量操作超量',
    'ACCOUNT_LOCKED': '账号已锁定，请稍后重试',
    'RATE_LIMITED': '请求频率超限',
  };

  /// 解析用户可见文案：命中映射返回中文，否则回退 [fallback]（后端 message）。
  static String resolve(String code, [String? fallback]) {
    return _map[code] ?? fallback ?? '未知错误，请稍后再试';
  }
}
```

### 2. 接入点（全局唯一）

修改 `lib/services/api_client.dart` 的 `parseError()`，第 155–159 行：

```dart
// ── 改前 ──
return ApiException(
  statusCode: statusCode,
  code: err['code']?.toString() ?? 'UNKNOWN',
  message: err['message']?.toString() ?? '未知错误',
);

// ── 改后 ──
return ApiException(
  statusCode: statusCode,
  code: err['code']?.toString() ?? 'UNKNOWN',
  message: ErrorMessages.resolve(
    err['code']?.toString() ?? 'UNKNOWN',
    err['message']?.toString(),
  ),
);
```

**效果**：
- 登录页 `errorMessage` 自动变为中文，**无需改动登录页、auth_provider**。
- 全端（改密、线索、日程、通话记录等所有 `ApiException` 展示处）一并受益，文案统一。
- 未命中映射的 code 仍回退后端 `message`，不影响现有逻辑。

## 四、改动文件清单（方案，暂不执行）

| 文件 | 改动 | 说明 |
|---|---|---|
| `lib/services/error_messages.dart` | 新增 | 错误码中文映射表（**唯一配置点**） |
| `lib/services/api_client.dart` | 改 3 行 | `parseError` 的 `message` 改走 `ErrorMessages.resolve` |

**不改动**：`auth_provider.dart`、`login_page.dart`、`api_exception.dart`（经核对 `AUTH_FORBIDDEN` 拼写与后端一致，无需修正）——UI 层零改动。

## 五、待确认事项（落地前拍板）

1. ~~`AUTH_FORBIDDEN` 拼写核对~~ ✅ **已确认，无需修正**
   用户确认后端真实 code = `AUTH_FORBIDDEN`（403 权限不足）。
   经复核 `lib/services/api_exception.dart:23` 现有判断 `code == 'AUTH_FORBIDDEN'` 与后端**完全一致**（之前"少一个 I"系本人误读，特此更正），`isAuthForbidden` 判断正常，无需改动。
   映射表 key 即采用 `AUTH_FORBIDDEN`。

2. **替换范围**
   我建议**全局统一替换**（只改 `parseError` 一处，覆盖全端）。
   若你只想改登录页（不在其它接口显示中文），也可只在 `auth_provider.login` 的 catch 里调用 `ErrorMessages.resolve`——但那样其它接口报错仍可能为英文。
   **推荐全局方案。**

## 六、验证方式（落地后）

- 错误账号密码登录 → 提示「账号或密码错误」（不再英文）。
- Token 过期 → 「Token 过期或已吊销」。
- 账号锁定（423 `ACCOUNT_LOCKED`）→ 「账号已锁定，请稍后重试」。
- `flutter analyze` 0 issue；release 装包真机验证。

---

**Mobile App Builder**：掌中灵
**日期**：2026-07-25
**备注**：仅出方案，未改动代码；待用户确认「拼写核对」与「替换范围」后进入开发。
