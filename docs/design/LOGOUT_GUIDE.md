# 退出登录接口对接指南（APP / 前端）

> 适用版本：v2026-07-25 起。本文档仅聚焦「退出登录」相关接口，供 APP 与前端以**最小改动**完成对接。
>
> **背景**：APP 调用 `POST /api/auth/logout` 返回 `400`，原因是该接口要求请求体携带 `refreshToken`（单设备吊销语义），旧文档示例漏写 body，导致未传而校验失败。本文档即为此纠正。

## 一、两个退出接口的区别

| 接口 | 请求体 | 语义 | 适用场景 |
|------|--------|------|----------|
| `POST /api/auth/logout` | **必填** `refreshToken` | 单设备吊销：仅使当前设备的刷新能力失效，其他设备保持登录 | 用户在某台设备点「退出登录」，希望其他设备不掉线 |
| `POST /api/auth/logout-all` | 不需要 | 全设备登出：递增 token 版本（tv），所有已签发 token 立即失效 | 用户主动「退出所有设备」/ 安全退出 |

## 二、`POST /api/auth/logout`（单设备）

**请求头**

- `Authorization: Bearer <accessToken>`
- `Content-Type: application/json`

**请求体（必填）**

```json
{ "refreshToken": "<当前设备的 refreshToken>" }
```

**响应**

- `200`：`{ "success": true }`（该 refreshToken 的 jti 已进入黑名单）
- `400`：`VALIDATION` —— 未传 `refreshToken` 或值为空
- `403`：`AUTH_FORBIDDEN` —— `refreshToken` 不属于当前登录用户

**curl 示例**

```bash
curl -X POST https://tm-api-test.kao9.com/api/auth/logout \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <accessToken>' \
  -d '{"refreshToken":"<refreshToken>"}'
```

## 三、`POST /api/auth/logout-all`（全设备）

无需请求体。

```bash
curl -X POST https://tm-api-test.kao9.com/api/auth/logout-all \
  -H 'Authorization: Bearer <accessToken>'
```

## 四、APP 端最小改动建议

**方案 A（推荐，保留单设备退出能力）**
登录时本地已持有 `accessToken` + `refreshToken`，登出时把存的 `refreshToken` 一并 POST 到 `/api/auth/logout` 即可。改动仅 1 处：登出请求补上 body。

**方案 B（最简单，接受全设备退出）**
若产品允许「退出即全设备失效」，直接把登出请求从 `/logout` 改为 `/api/auth/logout-all`（去掉 body 要求）。零 body 改动。

## 五、前端（Web 管理后台）处理

与 APP 同理：

- 单设备退出：调 `/api/auth/logout` 带 `refreshToken`（前端登录后通常也存了 refreshToken）。
- 全设备退出：调 `/api/auth/logout-all`（无需 body）。

> 注意：`logout` / `logout-all` 均在「强制改密拦截」豁免名单内，即使 `mrp=1` 也能调用（design.md §5.22）。

## 六、一句话结论

- 想「只退当前设备」→ `POST /api/auth/logout` + body `{ "refreshToken": "..." }`
- 想「全设备退出」→ `POST /api/auth/logout-all`（无需 body）
- 旧调用（不带 body 的 `/api/auth/logout`）会返回 `400`，**必须改**
