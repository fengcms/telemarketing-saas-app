# API 接口文档

> 项目：telemarketing-saas-be（Cloudflare Workers + Hono + D1 + Drizzle ORM）
> 基准版本：v0.26（2026-07-19）

---

## 基础约定

### 通用

| 项目 | 值 |
|------|-----|
| 本地开发地址 | `https://tm-api-test.kao9.com` |
| JSON 请求头 | `Content-Type: application/json` |
| 认证请求头 | `Authorization: Bearer <accessToken>` |
| AccessToken 有效期 | 15 分钟（JWT） |
| RefreshToken 有效期 | 7 天（JWT，版本号 `tv` 机制控制吊销） |

### 角色枚举

| 角色 | 标识 | 说明 |
|------|------|------|
| 平台超管 | `platform_super_admin` | 跨租户管理，走 `/api/platform/*` |
| 租户管理员 | `tenant_admin` | 本租户全部权限 |
| 租户经理 | `tenant_manager` | 团队管理（分配、转化、批量操作） |
| 租户员工 | `tenant_employee` | 仅操作自己归属的线索 |

### 线索状态枚举

| 状态 | 说明 |
|------|------|
| `pending` | 待处理（公海） |
| `assigned` | 已分配 |
| `following` | 跟进中 |
| `converted` | 已转化（硬终态，不可回退） |
| `invalid` | 无效/流失 |

### 日程状态枚举

| 状态 | 说明 |
|------|------|
| `pending` | 待办 |
| `completed` | 已完成 |
| `cancelled` | 已取消 |

### 通话接听类型

| 类型 | 说明 |
|------|------|
| `answered` | 已接听 |
| `no_answer` | 无人接听 |
| `rejected` | 拒接 |
| `empty_number` | 空号 |
| `suspended` | 停机 |

### 响应格式

成功：

```json
{
  "success": true,
  "data": { ... },
  "error": null
}
```

分页列表：

```json
{
  "success": true,
  "data": {
    "items": [ ... ],
    "total": 42,
    "page": 1,
    "size": 20,
    "pages": 3
  },
  "error": null
}
```

错误：

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "AUTH_INVALID",
    "message": "邮箱或密码错误"
  }
}
```

### 常见错误码

| HTTP 状态码 | `error.code` | 说明 |
|:--:|-------------|------|
| 400 | `VALIDATION` | 请求参数校验失败 |
| 400 | `STATUS_ROLLBACK_FORBIDDEN` | 状态回退被拒（converted 硬终态、Manager 正向校验拦截、日程状态非法流转） |
| 401 | `AUTH_INVALID` | 账号或密码错误 |
| 401 | `AUTH_EXPIRED` | Token 过期或已吊销 |
| 403 | `AUTH_FORBIDDEN` | 权限不足 |
| 403 | `TENANT_EXPIRED` | 租户已锁定，请联系平台超管 |
| 403 | `TENANT_IN_GRACE` | 租户已到期，宽限期内仅可导出数据 |
| 404 | `NOT_FOUND` | 资源不存在 |
| 409 | `LEAD_DUPLICATE` | 同项目+手机号线索已存在 |
| 413 | `BATCH_TOO_LARGE` | 批量操作超量 |
| 423 | `ACCOUNT_LOCKED` | 账号已锁定，请稍后重试 |
| 429 | `RATE_LIMITED` | 请求频率超限 |

### 通用查询参数

列表接口支持通用查询 DSL，通过查询参数自由组合筛选、排序、分页：

| 参数 | 示例 | 说明 |
|------|------|------|
| `page` | `page=1` | 页码，默认 1 |
| `size` | `size=20` | 每页条数，默认 20，最大 100 |
| `sortBy` | `sortBy=createdAt` | 排序字段 |
| `sortDir` | `sortDir=desc` | 排序方向：asc / desc |
| `field__op` | `createdAt__gte=1700000000` | 字段筛选，`__gte`/`__lte`/`__like` 等 |
| `status__in` | `status__in=pending,completed` | 多值枚举筛选 |

---

## 健康检查

### GET /health

确认 Worker 可用。

**响应：**

```json
{
  "success": true,
  "data": { "ok": true, "ts": 1700000000000, "version": "0.1.0" },
  "error": null
}
```

**curl：**

```bash
curl https://tm-api-test.kao9.com/health
```

---

## 认证接口

### POST /api/auth/login

登录，返回 JWT 双 Token。

**请求：**

```json
{
  "email": "admin@dev.local",
  "password": "Dev@123456"
}
```

**响应：**

```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "user": { "id": "...", "email": "admin@dev.local", "name": "管理员", "role": "tenant_admin" }
  },
  "error": null
}
```

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@dev.local","password":"Dev@123456"}'
```

### POST /api/auth/refresh

换发 Token（旧 refreshToken 的黑名单 `jti` 会失效）。

**请求：**

```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

**响应：**

```json
{
  "success": true,
  "data": { "accessToken": "...", "refreshToken": "..." },
  "error": null
}
```

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/auth/refresh \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <refreshToken>' \
  -d '{"refreshToken":"<refreshToken>"}'
```

### POST /api/auth/logout

登出（当前 Token 加入黑名单 `jti`）。

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/auth/logout \
  -H 'Authorization: Bearer <accessToken>'
```

### POST /api/auth/change-password

修改密码（要求提供旧密码复核）。

**请求：**

```json
{
  "oldPassword": "Dev@123456",
  "newPassword": "NewP@ss123"
}
```

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/auth/change-password \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <accessToken>' \
  -d '{"oldPassword":"Dev@123456","newPassword":"NewP@ss123"}'
```

### POST /api/auth/logout-all

全设备登出（递增 JWT tv 版本号，所有已签发 Token 立即失效）。

```bash
curl -X POST https://tm-api-test.kao9.com/api/auth/logout-all \
  -H 'Authorization: Bearer <accessToken>'
```

---

## 平台管理（仅 PSA）

### GET /api/platform/tenants

平台超管查看所有租户列表（通用查询）。

**curl：**

```bash
curl 'https://tm-api-test.kao9.com/api/platform/tenants?page=1&size=20' \
  -H 'Authorization: Bearer <psa_token>'
```

### POST /api/platform/tenants

创建新租户（自动创建管理员 + 种子分类/项目）。

**请求：**

```json
{
  "name": "测试租户",
  "slug": "test-tenant",
  "adminEmail": "admin@test.local",
  "adminPassword": "Dev@123456"
}
```

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/platform/tenants \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <psa_token>' \
  -d '{"name":"测试租户","slug":"test-tenant","adminEmail":"admin@test.local","adminPassword":"Dev@123456"}'
```

### POST /api/platform/tenants/:id/export-backup

导出指定租户全量数据 JSON（leads + customers + users + calls）。

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/platform/tenants/tenant-dev-001/export-backup \
  -H 'Authorization: Bearer <psa_token>'
```

### GET /api/platform/stats

全局跨租户统计。

**curl：**

```bash
curl 'https://tm-api-test.kao9.com/api/platform/stats?dateFrom=2026-07-18&dateTo=2026-07-19' \
  -H 'Authorization: Bearer <psa_token>'
```

### PATCH /api/platform/tenants/:id

编辑租户（名称、状态、配额等）。

```bash
curl -X PATCH https://tm-api-test.kao9.com/api/platform/tenants/tenant-dev-001 \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <psa_token>' \
  -d '{"name":"新名称","maxUsers":100}'
```

### POST /api/platform/tenants/:id/renew

续期或恢复租户（`expireAt` 为未来 unix 秒时间戳）。

```bash
curl -X POST https://tm-api-test.kao9.com/api/platform/tenants/tenant-dev-001/renew \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <psa_token>' \
  -d '{"expireAt":1800000000}'
```

### GET /api/platform/cron-logs

Cron 执行记录（运维可观测）。

> 另有开发测试端点 `POST /api/tenant/_cron/stats-aggregate`（TA 专用，含 requireTA 门禁；上线前移除）。错误信息已脱敏，返回 `{ ok: false, error: "cron task failed" }`。

### GET /api/platform/users

跨租户用户列表。

### GET /api/platform/tenants/:id/users

指定租户内的用户列表。

### POST /api/platform/tenants/:id/users

为指定租户创建用户。

### PATCH /api/platform/tenants/:id/users/:uid

编辑指定租户下的用户（禁用/改角色）。

### DELETE /api/platform/tenants/:id/users/:uid

删除指定租户下的用户。

### GET /api/platform/blocklist

平台级禁拨名单列表（phone 脱敏；每条记录含创建人名称 `createdByName`）。

### POST /api/platform/blocklist

加入平台共享黑名单（适用于全租户屏蔽的号码）。

### DELETE /api/platform/blocklist/:id

解除平台禁拨。

### POST /api/platform/blocklist/batch

批量加入平台共享黑名单（适用于全租户屏蔽的号码）。请求体 `{ phones: string[], reason? }`，逐条标准化 + 去重，**单次上限 500 条**，超出返回 `BATCH_TOO_LARGE`(413)；已存在号码计为 `existed`（幂等）。

---

## 租户用户管理

### GET /api/tenant/users

本租户用户列表。TA 看全部，TM 看团队，TE 仅自己。

**curl：**

```bash
curl 'https://tm-api-test.kao9.com/api/tenant/users?page=1&size=20' \
  -H 'Authorization: Bearer <ta_token>'
```

**响应（分页列表）：**

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "user-uuid",
        "tenantId": "tenant-uuid",
        "email": "staff@qq.com",
        "name": "张伟",
        "role": "tenant_employee",
        "status": "active",
        "mustResetPassword": 0,
        "lastLoginAt": 1700000000,
        "createdBy": "admin-uuid",
        "createdAt": 1699990000,
        "updatedAt": 1700000000,
        "deletedAt": null
      }
    ],
    "total": 15,
    "page": 1,
    "size": 20,
    "pages": 1
  },
  "error": null
}
```

> 角色枚举：`platform_super_admin` / `tenant_admin` / `tenant_manager` / `tenant_employee`。`status` 枚举：`active` / `disabled`。`mustResetPassword` 为 `0/1`，1 表示首次登录需强制改密。

### POST /api/tenant/users

创建用户（仅 TA）。

**请求：**

```json
{
  "email": "staff@dev.local",
  "name": "员工",
  "role": "tenant_employee",
  "password": "Dev@123456"
}
```

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/users \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <ta_token>' \
  -d '{"email":"staff@dev.local","name":"员工","role":"tenant_employee","password":"Dev@123456"}'
```

### PATCH /api/tenant/users/:id

更新用户（禁用/恢复/改角色，仅 TA）。

**curl：**

```bash
curl -X PATCH https://tm-api-test.kao9.com/api/tenant/users/<user_id> \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <ta_token>' \
  -d '{"status":"disabled"}'
```

### POST /api/tenant/users/batch

批量创建用户（TA；max 50）。

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/users/batch \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <ta_token>' \
  -d '{"users":[{"email":"staff1@dev.local","name":"员工1","role":"tenant_employee","password":"Dev@123456"}]}'
```

### POST /api/tenant/users/:id/reset-password

管理员重置用户密码（TA；强制下次登录改密）。

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/users/<user_id>/reset-password \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <ta_token>' \
  -d '{"newPassword":"NewP@ss123"}'
```

---

## 租户信息（Profile）

### GET /api/tenant/profile

返回当前租户的基本信息与配置。全部租户角色（TA/TM/TE）可访问，只读。

**curl：**

```bash
curl https://tm-api-test.kao9.com/api/tenant/profile \
  -H 'Authorization: Bearer <token>'
```

**响应：**

```json
{
  "success": true,
  "data": {
    "id": "租户 UUID",
    "name": "租户名称",
    "slug": "唯一标识",
    "status": "active | suspended",
    "expireAt": 1700000000,
    "maxUsers": 50,
    "maxLeads": 10000,
    "contactName": "联系人姓名",
    "contactPhone": "联系电话",
    "contactEmail": "联系邮箱",
    "industry": "行业",
    "address": "地址",
    "intro": "公司简介",
    "website": "官网",
    "settings": {},
    "createdAt": 1700000000,
    "updatedAt": 1700000000
  }
}
```

> `settings` 为 `settingsJson` 解析后的 JSON 对象；原始 `settingsJson` 字符串不返回。
> PSA 应使用平台端 `GET /api/platform/tenants/:id` 查询租户详情。

### PATCH /api/tenant/profile

更新租户基本信息与配置开关（仅 TA）。

**请求：**

```json
{
  "name": "新公司名称",
  "contactName": "李四",
  "contactPhone": "13800001001",
  "settings": {
    "allowSelfClaim": true
  }
}
```

所有字段可选。`settings` 内仅允许 `allowSelfClaim`（开启公海自领），其余 key 被静默忽略。

**curl：**

```bash
curl -X PATCH https://tm-api-test.kao9.com/api/tenant/profile \
  -H 'Authorization: Bearer <ta_token>' \
  -H 'Content-Type: application/json' \
  -d '{"name":"新公司名","settings":{"allowSelfClaim":true}}'
```

**响应：** 同 GET 响应结构，返回更新后的完整租户信息。

---

## 租户配置管理

> 分类、项目、快捷备注是租户内的基础配置数据，由 TA 管理，TA/TM/TE 在业务场景中引用。

### GET /api/tenant/categories

分类列表（扁平，无层级）。

**curl：**

```bash
curl https://tm-api-test.kao9.com/api/tenant/categories \
  -H 'Authorization: Bearer <ta_token>'
```

### POST /api/tenant/categories

新增分类（TA）。

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/categories \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <ta_token>' \
  -d '{"name":"高意向","sort":0}'
```

### PATCH /api/tenant/categories/:id

编辑分类（TA）。

### DELETE /api/tenant/categories/:id

软删分类（TA）。

---

### GET /api/tenant/projects

项目列表；支持通用查询（name、status、createdAt 等）。

**curl：**

```bash
curl 'https://tm-api-test.kao9.com/api/tenant/projects?status=active' \
  -H 'Authorization: Bearer <ta_token>'
```

**响应（分页列表）：**

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "project-uuid",
        "tenantId": "tenant-uuid",
        "name": "凤凰城A区-高层",
        "address": "广东省广州市天河区凤凰路88号",
        "status": "active",
        "isSystem": 0,
        "createdAt": 1699990000,
        "updatedAt": 1699990000,
        "deletedAt": null
      }
    ],
    "total": 4,
    "page": 1,
    "size": 20,
    "pages": 1
  },
  "error": null
}
```

> `isSystem` 为 `0/1`，`1` 表示系统预设"未分类"项目（不可删除）。`status` 枚举 `active` / `archived`。

### POST /api/tenant/projects

新增项目（TA）。

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/projects \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <ta_token>' \
  -d '{"name":"XX小区"}'
```

### PATCH /api/tenant/projects/:id

编辑项目（TA）。

### DELETE /api/tenant/projects/:id

归档项目（`status='archived'`，仅 TA）。系统项目（`is_system=1`，如「未分类」）不可改名、不可删除。

---

### GET /api/tenant/quick-notes

快捷备注列表（TA/TM/TE 都可读，按 sort 升序）。用于跟进时快速选择常用文案。

**curl：**

```bash
curl https://tm-api-test.kao9.com/api/tenant/quick-notes \
  -H 'Authorization: Bearer <ta_token>'
```

### POST /api/tenant/quick-notes

新增快捷备注（仅 TA）。

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/quick-notes \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <ta_token>' \
  -d '{"content":"客户要求改天再联系","sort":1}'
```

> `content` 必填（≤500 字），`sort` 可选（排序权重，默认 0）。无 PATCH 端点，编辑时删后重建即可。

### DELETE /api/tenant/quick-notes/:id

软删快捷备注（仅 TA；不可恢复）。

---

## 下拉选项（Dropdown Options）

前端查询筛选框专用接口，仅返回 `id` + 关键标识字段，**不提供分页/过滤/排序参数**，直接按创建时间倒序取最近 100 条。全体租户角色（TA/TM/TE）可读，PSA 无租户上下文时返回 `TENANT_FORBIDDEN`。

### GET /api/tenant/options/projects

项目下拉选项（`id` + `name`，含归档，仅排除软删）。

**响应：**

```json
{
  "success": true,
  "data": [
    { "id": "uncategorized-tenant-dev-001", "name": "未分类" },
    { "id": "a6642e72-...", "name": "凤凰城A区-高层" }
  ],
  "error": null
}
```

**curl：**

```bash
curl https://tm-api-test.kao9.com/api/tenant/options/projects \
  -H 'Authorization: Bearer <token>'
```

### GET /api/tenant/options/users

员工下拉选项（`id` + `name` + `role`，不含软删）。

**响应：**

```json
{
  "success": true,
  "data": [
    { "id": "2eced69e-...", "name": "租户管理员", "role": "tenant_admin" },
    { "id": "15d4cf53-...", "name": "普通员工", "role": "tenant_employee" }
  ],
  "error": null
}
```

### GET /api/tenant/options/categories

分类下拉选项（`id` + `name`，按 sort 权重排序，不含软删）。

**响应：**

```json
{
  "success": true,
  "data": [
    { "id": "8b0a3392-...", "name": "普通线索" },
    { "id": "1e36c073-...", "name": "高意向客户" }
  ],
  "error": null
}
```

### GET /api/tenant/options/quick-notes

快捷备注下拉选项（`id` + `content`，按 sort 权重排序，不含软删）。

**响应：**

```json
{
  "success": true,
  "data": [
    { "id": "cc14fe7a-...", "content": "客户忙，稍后再联系" },
    { "id": "da41e321-...", "content": "预约看房，周末到访" }
  ],
  "error": null
}
```

**curl：**

```bash
curl https://tm-api-test.kao9.com/api/tenant/options/categories \
  -H 'Authorization: Bearer <token>'
```

---

## 线索管理

### GET /api/tenant/leads

线索列表，支持 `scope` 参数和通用查询。TE 默认 `scope=mine`，TM/TA 默认 `scope=all`。列表手机号脱敏，`raw=1` 返回明文。

**参数：**

| 参数 | 类型 | 说明 |
|------|------|------|
| `scope` | string | `mine` / `public` / `all` / `blocked` |
| `raw` | 1 | 传入 `raw=1` 返回完整手机号（仅 PSA/TA） |
| `erased` | 0/1 | PIPL 擦除过滤：`0`=仅未擦除；`1`=仅已擦除；缺省不过滤 |

> TE 仅 `mine`。若租户开启 `allowSelfClaim`（`GET /profile` 可读），TE 还可使用 `scope=public` 浏览公海（自动过滤禁拨 + 无主线索）。

> 每条记录返回 `erasedAt` 字段（`null`=未擦除，非 `null` 的 unix 秒=擦除时间）。正常列表建议传 `?erased=0` 以隐藏已擦除记录。

**curl：**

```bash
# TA 查看全部
curl 'https://tm-api-test.kao9.com/api/tenant/leads?scope=all&page=1&size=20' \
  -H 'Authorization: Bearer <ta_token>'

# TE 仅看自己、含原始号码
curl 'https://tm-api-test.kao9.com/api/tenant/leads?scope=mine&raw=1' \
  -H 'Authorization: Bearer <ta_token>'

# 按状态筛选
curl 'https://tm-api-test.kao9.com/api/tenant/leads?status__in=pending,assigned' \
  -H 'Authorization: Bearer <ta_token>'

# 仅显示未擦除（推荐正常业务列表）
curl 'https://tm-api-test.kao9.com/api/tenant/leads?scope=all&erased=0' \
  -H 'Authorization: Bearer <ta_token>'
```

**响应（分页列表）：**

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "lead-uuid",
        "tenantId": "tenant-uuid",
        "projectId": "project-uuid",
        "name": "张三",
        "phone": "138****5678",
        "company": "碧桂园集团",
        "position": "经理",
        "gender": "男",
        "age": 35,
        "wechat": "wx_****5678",
        "address": "广东省广州市天河区",
        "source": "电话咨询",
        "intention": "投资自住",
        "remark": "客户关注A户型",
        "status": "following",
        "ownerId": "user-uuid",
        "categoryId": "category-uuid",
        "isBlocked": 0,
        "customFields": {},
        "importBatchId": null,
        "assignedAt": 1700000000,
        "lastFollowupAt": 1700001000,
        "nextFollowupAt": 1700080000,
        "pooledAt": 1699990000,
        "consentAt": 1699900000,
        "createdAt": 1699990000,
        "updatedAt": 1700001000,
        "deletedAt": null,
        "erasedAt": null
      }
    ],
    "total": 120,
    "page": 1,
    "size": 20,
    "pages": 6
  },
  "error": null
}
```

> 字段说明：`status` 枚举 `pending/assigned/following/converted/invalid`；`isBlocked` 为 `0/1`；所有时间戳为 unix 秒；`erasedAt` 非 null 表示 PIPL 擦除；手机号/微信号列表默认脱敏，`raw=1` 返回明文。

### POST /api/tenant/leads

创建单条线索（TA/TM，电话会标准化 + 禁拨校验 + 去重）。

**请求：**

```json
{
  "phone": "13800138000",
  "name": "张三",
  "projectId": "<project_id>"
}
```

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/leads \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <ta_token>' \
  -d '{"phone":"13800138000","name":"张三"}'
```

### GET /api/tenant/leads/:id

线索详情（含跟进时间线）。返回对象含 `erasedAt` 字段（`null`=未擦除，非 `null`=擦除时间）。

**curl：**

```bash
curl https://tm-api-test.kao9.com/api/tenant/leads/<lead_id> \
  -H 'Authorization: Bearer <ta_token>'
```

**响应：**

```json
{
  "success": true,
  "data": {
    "id": "lead-uuid",
    "tenantId": "tenant-uuid",
    "projectId": "project-uuid",
    "name": "张三",
    "phone": "13800138000",
    "company": "碧桂园集团",
    "position": "经理",
    "gender": "男",
    "age": 35,
    "wechat": "wx_abcd1234",
    "address": "广东省广州市天河区",
    "source": "电话咨询",
    "intention": "投资自住",
    "remark": "客户关注A户型",
    "status": "following",
    "ownerId": "user-uuid",
    "categoryId": "category-uuid",
    "isBlocked": 0,
    "customFields": {},
    "importBatchId": null,
    "assignedAt": 1700000000,
    "lastFollowupAt": 1700001000,
    "nextFollowupAt": 1700080000,
    "pooledAt": 1699990000,
    "consentAt": 1699900000,
    "createdAt": 1699990000,
    "updatedAt": 1700001000,
    "deletedAt": null,
    "erasedAt": null,
    "timeline": [
      {
        "id": "followup-uuid",
        "type": "followup",
        "content": "客户表示需要和家里人商量",
        "answerType": "answered",
        "duration": 120,
        "categoryId": "category-uuid",
        "userId": "user-uuid",
        "userName": "张伟",
        "createdAt": 1700000000
      },
      {
        "id": "call-uuid",
        "type": "call",
        "answerType": "answered",
        "duration": 90,
        "userId": "user-uuid",
        "userName": "张伟",
        "startedAt": 1699990000
      }
    ]
  },
  "error": null
}
```

> 详情返回完整手机号（不脱敏）。`timeline` 为跟进记录 + 通话记录的合并时间线，按 `createdAt`/`startedAt` 倒序。`type` 区分 `followup` 与 `call`。

### PATCH /api/tenant/leads/:id

更新线索（角色门控字段）。`converted` 线索不可修改。`nextFollowupAt` 为系统只读字段。

**curl：**

```bash
curl -X PATCH https://tm-api-test.kao9.com/api/tenant/leads/<lead_id> \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <ta_token>' \
  -d '{"status":"following","categoryId":"<category_id>"}'
```

### POST /api/tenant/leads/:id/followups

添加跟进记录。

**请求：**

```json
{
  "content": "客户表示有兴趣",
  "answerType": "answered",
  "duration": 120
}
```

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/leads/<lead_id>/followups \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <ta_token>' \
  -d '{"content":"客户表示有兴趣","answerType":"answered","duration":120}'
```

### PATCH /api/tenant/leads/:id/followups/:fid

（REQ-01）编辑跟进备注。仅允许修改 `content`。TE 限 5 分钟内编辑自己的记录，TM/TA 不限。

**请求：**

```json
{
  "content": "修正后的备注内容"
}
```

**curl：**

```bash
curl -X PATCH https://tm-api-test.kao9.com/api/tenant/leads/<lead_id>/followups/<fid> \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <te_token>' \
  -d '{"content":"修正后的备注内容"}'
```

### DELETE /api/tenant/leads/:id/followups/:fid

（REQ-01）软删跟进记录。TE 仅删除自己的记录，TM/TA 可删除全部。不影响 `leads.status`/`lastFollowupAt`。

**curl：**

```bash
curl -X DELETE https://tm-api-test.kao9.com/api/tenant/leads/<lead_id>/followups/<fid> \
  -H 'Authorization: Bearer <te_token>'
```

**响应：**

```json
{
  "success": true,
  "data": { "id": "<fid>", "deleted": true }
}
```

### POST /api/tenant/leads/:id/assign

分配线索（TA/TM）。自动迁移该线索下 `pending` 日程到新归属人。

**请求：**

```json
{
  "ownerId": "<target_user_id>"
}
```

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/leads/<lead_id>/assign \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <tm_token>' \
  -d '{"ownerId":"<target_user_id>"}'
```

### POST /api/tenant/leads/:id/convert

转化线索为客户（TA/TM，硬终态不可逆）。自动取消该线索下所有 `pending` 日程。

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/leads/<lead_id>/convert \
  -H 'Authorization: Bearer <tm_token>'
```

### POST /api/tenant/leads/batch-assign

批量分配（≤100 条，TA/TM）。自动迁移所有命中线索的 pending 日程归属。

**请求：**

```json
{
  "leadIds": ["<id1>", "<id2>"],
  "ownerId": "<target_user_id>"
}
```

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/leads/batch-assign \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <tm_token>' \
  -d '{"leadIds":["<id1>","<id2>"],"ownerId":"<target_user_id>"}'
```

### POST /api/tenant/leads/import

批量导入线索（TA，≤500 条/次，解析 → 禁拨 → 去重 → 自定义字段校验）。

**请求：**

```json
{
  "rows": [
    { "phone": "13800138001", "name": "客户A", "customFields": {} },
    { "phone": "13800138002", "name": "客户B" }
  ],
  "projectId": "<project_id>",
  "label": "20260719批次"
}
```

**响应：**

```json
{
  "success": true,
  "data": {
    "importId": "<uuid>",
    "total": 500,
    "success": 498,
    "failed": 0,
    "blocked": 1,
    "duplicates": 1
  }
}
```

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/leads/import \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <ta_token>' \
  -d '{"rows":[{"phone":"13800138001","name":"客户A"}],"label":"测试导入"}'
```

### GET /api/tenant/leads/imports

导入历史列表。

**curl：**

```bash
curl https://tm-api-test.kao9.com/api/tenant/leads/imports \
  -H 'Authorization: Bearer <ta_token>'
```

### GET /api/tenant/leads/imports/:id

导入批次详情（含成功/失败条数明细）。

```bash
curl https://tm-api-test.kao9.com/api/tenant/leads/imports/<import_id> \
  -H 'Authorization: Bearer <ta_token>'
```

### POST /api/tenant/leads/:id/recycle

退回公海（TA/TM，`note` 可选）。

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/leads/<lead_id>/recycle \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <ta_token>' \
  -d '{"note":"客户暂时不考虑"}'
```

### POST /api/tenant/leads/:id/claim

员工自领公海线索（需租户开启 `allowSelfClaim`）。

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/leads/<lead_id>/claim \
  -H 'Authorization: Bearer <te_token>'
```

### POST /api/tenant/leads/:id/reactivate

激活已失效线索（`invalid` → `pending`，回到公海；TA/TM）。

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/leads/<lead_id>/reactivate \
  -H 'Authorization: Bearer <ta_token>'
```

### GET /api/tenant/leads/:id/assignments

单条线索的分配/回收/认领历史（读 `lead_assignments` 明细，不受批次头表改造影响）。

```bash
curl https://tm-api-test.kao9.com/api/tenant/leads/<lead_id>/assignments \
  -H 'Authorization: Bearer <ta_token>'
```

### GET /api/tenant/assignments

分配批次历史（TA/TM，分页列表）。**每次操作 1 行**（如批量分配 1000 条线索 = 1 行），读 `lead_assignment_batches` 头表，聚合展示本次操作的 `total/success/failed/skipped` 与跳过原因分布 `skipDetail`。

支持通用查询 DSL（§9.4）过滤：`action`（assign/reassign/recycle/claim/status-change）、`operatorId`、`fromUserId`、`toUserId`、`toStatus`、`createdAt`，默认按 `createdAt` 倒序。

**响应示例：**

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "batch-uuid",
        "action": "assign",
        "operatorId": "op-uuid",
        "operatorRole": "tenant_admin",
        "fromUserId": null,
        "toUserId": "emp-uuid",
        "toStatus": null,
        "total": 1000,
        "success": 980,
        "failed": 0,
        "skipped": 20,
        "skipDetail": { "alreadyOwned": 5, "notStale": 12, "blocklisted": 3 },
        "note": null,
        "createdAt": 1753000000
      }
    ],
    "total": 1, "page": 1, "size": 20, "pages": 1
  }
}
```

> `skipDetail` 字段含义：`alreadyOwned`=已属本人跳过、`notStale`=公海未超冷却期跳过、`notInvalid`=非失效线索跳过（批量激活）、`blocklisted`=黑名单线索跳过。详见 design.md §5。

### GET /api/tenant/assignments/:batchId

批次明细下钻（TA/TM）。返回该批次对应的 `lead_assignments` 逐条线索记录（成功/失败/跳过），用于从批次汇总展开到线索级溯源。**支持分页**，适配批量分配产生大量明细的场景（如批量分配 1000 条 = 1000 行明细）。

支持通用查询 DSL（§9.4）过滤与分页：`action`（assign/reassign/recycle/claim）、`leadId`、`toUserId`、`page`、`size`（默认 `page=1`、`size=20`、上限 `size=200`），默认按 `createdAt` 倒序。

```bash
curl 'https://tm-api-test.kao9.com/api/tenant/assignments/<batch_id>?page=1&size=20' \
  -H 'Authorization: Bearer <ta_token>'
```

**响应示例：**

```json
{
  "success": true,
  "data": {
    "batch": {
      "id": "batch-uuid", "action": "assign", "operatorId": "op-uuid",
      "toUserId": "emp-uuid", "total": 1000, "success": 980, "failed": 0,
      "skipped": 20, "skipDetail": { "alreadyOwned": 5, "notStale": 12, "blocklisted": 3 },
      "createdAt": 1753000000
    },
    "items": [
      { "id": "detail-uuid", "leadId": "lead-uuid", "action": "assign", "fromUserId": null, "toUserId": "emp-uuid", "operatorId": "op-uuid", "operatorRole": "tenant_admin", "note": null, "batchId": "batch-uuid", "createdAt": 1753000000 }
    ],
    "total": 1000, "page": 1, "size": 20, "pages": 50
  }
}
```

> `batch.skipDetail` 已解析为对象（与列表契约一致）；`items` 为当前页明细，`total/page/size/pages` 用于前端分页或虚拟滚动。

### POST /api/tenant/leads/batch-status

批量改状态（max 100）。

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/leads/batch-status \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <ta_token>' \
  -d '{"leadIds":["id1","id2"],"status":"following","note":"批量跟进"}'
```

### POST /api/tenant/leads/batch-reactivate

批量激活无效线索（max 100；TA/TM）。

### POST /api/tenant/leads/batch-delete

批量软删线索（max 100；仅 TA）。

### POST /api/tenant/leads/:id/erase

PIPL 擦除（TA 专用）。置空全部 PII 字段（name/phone/wechat/company/address/position/gender/age/source/intention/remark/customFields），级联清理 followups 内容、通话记录 `phone` 脱敏并置空 leadId、审计 `detail` 脱敏。**级联擦除该线索转化的客户记录**（同字段集）。响应返回 `{ id, erased: true, erasedAt }`（unix 秒）。

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/leads/<lead_id>/erase \
  -H 'Authorization: Bearer <ta_token>'
```

---

## 日程管理

### GET /api/tenant/schedules

日程列表。默认 `status=pending`，`status__in=pending,completed` 多值。JOIN leads 返回 `name`+`phone`（**不脱敏。TE 仅自己，TM/TA 全团队，所有合法查看者均有拨号需求**）。LEFT JOIN 已过滤软删除线索。

**参数：**

| 参数 | 类型 | 说明 |
|------|------|------|
| `dateFrom` | string | 筛选 `scheduledAt ≥ 00:00` |
| `dateTo` | string | 筛选 `scheduledAt ≤ 23:59` |
| `status` | string | `pending`/`completed`/`cancelled` |
| `status__in` | string | 多值如 `pending,completed` |

**响应：**

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "<uuid>",
        "userId": "<user_id>",
        "leadId": "<lead_id>",
        "title": "回访确认意向",
        "content": "客户说周三下午方便接电话",
        "scheduledAt": 1700000000,
        "status": "pending",
        "lead": { "name": "张三", "phone": "13800138000" }
      }
    ],
    "total": 1, "page": 1, "size": 20, "pages": 1
  }
}
```

**curl：**

```bash
# 查看今日待办
curl 'https://tm-api-test.kao9.com/api/tenant/schedules' \
  -H 'Authorization: Bearer <te_token>'

# TM/TA 按日期查看
curl 'https://tm-api-test.kao9.com/api/tenant/schedules?dateFrom=2026-07-19&dateTo=2026-07-19' \
  -H 'Authorization: Bearer <tm_token>'

# 查看已完成
curl 'https://tm-api-test.kao9.com/api/tenant/schedules?status__in=pending,completed' \
  -H 'Authorization: Bearer <ta_token>'
```

### GET /api/tenant/schedules/:id

日程详情（含 `lead` 快照 + `call` 通话摘要）。

**curl：**

```bash
curl https://tm-api-test.kao9.com/api/tenant/schedules/<schedule_id> \
  -H 'Authorization: Bearer <ta_token>'
```

**响应：**

```json
{
  "success": true,
  "data": {
    "id": "schedule-uuid",
    "tenantId": "tenant-uuid",
    "userId": "user-uuid",
    "leadId": "lead-uuid",
    "callRecordId": null,
    "title": "回访确认意向",
    "content": "客户说周三下午方便接电话",
    "scheduledAt": 1700000000,
    "status": "pending",
    "completedAt": null,
    "createdAt": 1699990000,
    "updatedAt": 1699990000,
    "deletedAt": null,
    "lead": {
      "name": "张三",
      "phone": "13800138000"
    },
    "call": null
  },
  "error": null
}
```

> `status` 枚举 `pending` / `completed` / `cancelled`。`lead` 为线索快照（含姓名+手机号）。`call` 为关联通话摘要（含 `answerType` / `duration`），无关联则为 `null`。

### POST /api/tenant/schedules

创建日程。

**请求：**

```json
{
  "leadId": "<lead_id>",
  "scheduledAt": 1700000000,
  "title": "回访确认意向",
  "content": "客户说周三下午方便接电话",
  "callRecordId": "<可选:关联的通话>",
  "userId": "<可选:TM/TA替员工创建的归属人>"
}
```

**约束：**
- TE 仅可为自己归属的线索创建（`owner_id === 自己`）
- TM/TA 可传 `userId` 替其他员工创建

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/schedules \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <te_token>' \
  -d '{"leadId":"<lead_id>","scheduledAt":1700000000,"title":"回访确认意向"}'
```

### PATCH /api/tenant/schedules/:id

编辑日程（仅可改 `scheduledAt` / `title` / `content`）。改期后联动更新 `leads.nextFollowupAt`。

**curl：**

```bash
curl -X PATCH https://tm-api-test.kao9.com/api/tenant/schedules/<schedule_id> \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <ta_token>' \
  -d '{"scheduledAt":1700003600,"title":"改期至周三下午"}'
```

### POST /api/tenant/schedules/:id/complete

标记完成（仅 `pending` 状态可执行）。

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/schedules/<schedule_id>/complete \
  -H 'Authorization: Bearer <te_token>'
```

### POST /api/tenant/schedules/:id/cancel

取消（仅 `pending` 状态可执行）。

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/schedules/<schedule_id>/cancel \
  -H 'Authorization: Bearer <te_token>'
```

### POST /api/tenant/schedules/:id/reopen

重新打开（`completed`/`cancelled` → `pending`）。

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/schedules/<schedule_id>/reopen \
  -H 'Authorization: Bearer <ta_token>'
```

### DELETE /api/tenant/schedules/:id

软删（本人或 TA）。

**curl：**

```bash
curl -X DELETE https://tm-api-test.kao9.com/api/tenant/schedules/<schedule_id> \
  -H 'Authorization: Bearer <ta_token>'
```

### GET /api/tenant/schedules/stats

团队日程统计（TA/TM）。返回按状态分布 + 逾期数。

**响应：**

```json
{
  "success": true,
  "data": {
    "byStatus": { "pending": 12, "completed": 45, "cancelled": 3, "overdue": 2 }
  }
}
```

**curl：**

```bash
curl https://tm-api-test.kao9.com/api/tenant/schedules/stats \
  -H 'Authorization: Bearer <tm_token>'
```

### GET /api/tenant/schedules/stats/mine

个人日程统计（TE）。返回状态分布 + `overdue`（已逾期）+ `dueToday`（今日待办，按北京时间）。

**curl：**

```bash
curl https://tm-api-test.kao9.com/api/tenant/schedules/stats/mine \
  -H 'Authorization: Bearer <te_token>'
```

**响应：**

```json
{
  "success": true,
  "data": {
    "byStatus": { "pending": 5, "completed": 3, "cancelled": 1, "overdue": 2, "dueToday": 7 }
  }
}
```

**curl：**

```bash
curl https://tm-api-test.kao9.com/api/tenant/schedules/stats/mine \
  -H 'Authorization: Bearer <te_token>'
```

---

## 客户管理

### GET /api/tenant/customers

客户列表（`scope=mine`/`all`）。脱敏。

**参数：**

| 参数 | 类型 | 说明 |
|------|------|------|
| `scope` | string | `mine` / `all` |
| `erased` | 0/1 | **新增** PIPL 擦除过滤：`0`=仅未擦除（推荐正常列表）；`1`=仅已擦除（回收站）；**缺省不过滤，已擦除空记录混在列表中** |

> 客户擦除**不清除 `deletedAt`**，已擦除记录仍会留在列表（PII 置空为 null）。每条记录返回 `erasedAt` 字段（`null`=未擦除，非 `null`=擦除时间）。正常列表建议传 `?erased=0`。

**curl：**

```bash
curl 'https://tm-api-test.kao9.com/api/tenant/customers?scope=all' \
  -H 'Authorization: Bearer <ta_token>'

# 仅显示未擦除（推荐正常业务列表）
curl 'https://tm-api-test.kao9.com/api/tenant/customers?scope=all&erased=0' \
  -H 'Authorization: Bearer <ta_token>'
```

**响应（分页列表）：**

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "customer-uuid",
        "tenantId": "tenant-uuid",
        "leadId": "lead-uuid",
        "name": "张三",
        "phone": "138****5678",
        "ownerId": "user-uuid",
        "level": "normal",
        "convertedAt": 1700000000,
        "createdAt": 1700000000,
        "updatedAt": 1700001000,
        "deletedAt": null,
        "erasedAt": null
      }
    ],
    "total": 15,
    "page": 1,
    "size": 20,
    "pages": 1
  },
  "error": null
}
```

> `level` 枚举 `normal` / `important` / `vip` / `lost`。手机号列表默认脱敏。`leadId` 为来源线索 ID。

### POST /api/tenant/customers

手动创建客户（TA/TM）。

**请求：**

```json
{
  "name": "李四",
  "phone": "13900139000",
  "company": "某某科技"
}
```

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/customers \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <tm_token>' \
  -d '{"name":"李四","phone":"13900139000"}'
```

### GET /api/tenant/customers/:id

客户详情（含来源线索 + 跟进时间线）。返回对象含 `erasedAt` 字段（`null`=未擦除，非 `null`=擦除时间）。

**curl：**

```bash
curl https://tm-api-test.kao9.com/api/tenant/customers/<customer_id> \
  -H 'Authorization: Bearer <ta_token>'
```

**响应：**

```json
{
  "success": true,
  "data": {
    "id": "customer-uuid",
    "tenantId": "tenant-uuid",
    "leadId": "lead-uuid",
    "name": "张三",
    "phone": "13800138000",
    "company": "碧桂园集团",
    "address": "广东省广州市天河区",
    "position": "经理",
    "gender": "男",
    "age": 35,
    "wechat": "wx_abcd1234",
    "source": "电话咨询",
    "remark": "客户关注A户型",
    "ownerId": "user-uuid",
    "level": "normal",
    "customFields": {},
    "convertedAt": 1700000000,
    "createdAt": 1700000000,
    "updatedAt": 1700001000,
    "deletedAt": null,
    "erasedAt": null
  },
  "error": null
}
```

> 详情返回完整手机号（不脱敏）。`level` 枚举 `normal` / `important` / `vip` / `lost`。

### DELETE /api/tenant/customers/:id

软删单条客户（TA）。`deletedAt` 设值后从列表消失。

**curl：**

```bash
curl -X DELETE https://tm-api-test.kao9.com/api/tenant/customers/<customer_id> \
  -H 'Authorization: Bearer <ta_token>'
```

### POST /api/tenant/customers/:id/erase

PIPL 擦除客户（TA）。置空全部 PII 字段（name/phone/wechat/company/address/position/gender/age/remark/customFields），级联清理来源线索的 followups 内容、通话记录 `phone` 脱敏、审计 `detail` 脱敏（客户本身 **不清除 `deletedAt`**，记录仍留在列表）。响应返回 `{ id, erased: true, erasedAt }`。

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/customers/<customer_id>/erase \
  -H 'Authorization: Bearer <ta_token>'
```

已擦除客户可用 `GET /api/tenant/customers?erased=1` 查询（回收站视图）。

### POST /api/tenant/customers/:id/assign

分配客户给员工（TA/TM）。

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/customers/<customer_id>/assign \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <ta_token>' \
  -d '{"ownerId":"<target_user_id>"}'
```

### POST /api/tenant/customers/batch-delete

批量软删客户（TA；max 100）。

---

## 通话记录

### GET /api/tenant/calls

通话记录列表。TE 强制 `user_id` 等于自己。`dateFrom`/`dateTo` 筛选 `startedAt`。

**curl：**

```bash
curl 'https://tm-api-test.kao9.com/api/tenant/calls?dateFrom=2026-07-18&dateTo=2026-07-19' \
  -H 'Authorization: Bearer <ta_token>'
```

**响应（分页列表）：**

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "call-uuid",
        "tenantId": "tenant-uuid",
        "leadId": "lead-uuid",
        "userId": "user-uuid",
        "projectId": "project-uuid",
        "phone": "13800138000",
        "direction": "outbound",
        "answerType": "answered",
        "startedAt": 1700000000,
        "endedAt": 1700000120,
        "duration": 120,
        "recordingUrl": null,
        "externalCallId": "ext-001",
        "trunk": null,
        "cost": null,
        "violation": 0,
        "createdAt": 1700000000,
        "deletedAt": null
      }
    ],
    "total": 160,
    "page": 1,
    "size": 20,
    "pages": 8
  },
  "error": null
}
```

> `direction` 枚举 `outbound` / `inbound`。`answerType` 枚举 `answered` / `no_answer` / `rejected` / `empty_number` / `suspended`。`violation` 为 `0/1`，`1` 表示命中免打扰时段。

### POST /api/tenant/calls

创建通话记录（幂等：`externalCallId` 同租户唯一，重复则复活已删记录）。支持可选地原子创建跟进：传 `content` 后，后端在同一 batch 内创建通话记录 + 跟进记录 + 更新线索状态为 `following`。

**请求：**

```json
{
  "phone": "13800138000",
  "startedAt": 1700000000,
  "externalCallId": "client-uuid-xxx",
  "leadId": "<lead_id>",
  "answerType": "answered",
  "duration": 120,
  "content": "客户表示有兴趣（选填，非空时原子创建跟进）",
  "categoryId": "<category_id>（选填，同步线索分类）"
}
```

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/calls \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <te_token>' \
  -d '{"phone":"13800138000","startedAt":1700000000,"externalCallId":"ext-001","answerType":"answered","duration":60,"content":"客户说考虑一下"}'
```

**响应（新建时）：**

```json
{
  "success": true,
  "data": { "id": "<call_id>", "updated": false, "violation": 0, "leadId": "<lead_id>", "followupId": "<fid>" , "followupCreated": true }
}
```

**响应（幂等更新时）：**

```json
{
  "success": true,
  "data": { "id": "<call_id>", "updated": true, "violation": 0, "leadId": "<lead_id>", "followupCreated": false }
}
```

### GET /api/tenant/calls/:id

通话详情。

**curl：**

```bash
curl https://tm-api-test.kao9.com/api/tenant/calls/<call_id> \
  -H 'Authorization: Bearer <ta_token>'
```

**响应：**

```json
{
  "success": true,
  "data": {
    "id": "call-uuid",
    "tenantId": "tenant-uuid",
    "leadId": "lead-uuid",
    "userId": "user-uuid",
    "projectId": "project-uuid",
    "phone": "13800138000",
    "direction": "outbound",
    "answerType": "answered",
    "startedAt": 1700000000,
    "endedAt": 1700000120,
    "duration": 120,
    "recordingUrl": "https://...",
    "externalCallId": "ext-001",
    "trunk": null,
    "cost": null,
    "violation": 0,
    "createdAt": 1700000000,
    "deletedAt": null
  },
  "error": null
}
```

> 详情不脱敏。`recordingUrl` 仅在已录音时返回，当前 MVP 恒为 NULL。

### DELETE /api/tenant/calls/:id

删除通话记录（仅 TA；软删）。

```bash
curl -X DELETE https://tm-api-test.kao9.com/api/tenant/calls/<call_id> \
  -H 'Authorization: Bearer <ta_token>'
```

---

## 租户禁拨名单

### GET /api/tenant/blocklist

禁拨列表（脱敏；每条记录含创建人名称 `createdByName`）。TA/TM 管理。

**curl：**

```bash
curl https://tm-api-test.kao9.com/api/tenant/blocklist \
  -H 'Authorization: Bearer <ta_token>'
```

### POST /api/tenant/blocklist

单条加入禁拨（标准化 + 幂等 + 标记线索 `is_blocked=1` + 自动取消 pending 日程）。

**请求：**

```json
{
  "phone": "13800138000",
  "reason": "客户投诉"
}
```

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/blocklist \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <ta_token>' \
  -d '{"phone":"13800138000","reason":"客户投诉"}'
```

### POST /api/tenant/blocklist/batch

批量加入。

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/blocklist/batch \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <ta_token>' \
  -d '{"phones":["13800138001","13800138002"]}'
```

### DELETE /api/tenant/blocklist/:id

解禁（软删，若无平台级屏蔽源则复位线索 `is_blocked=0`）。

**curl：**

```bash
curl -X DELETE https://tm-api-test.kao9.com/api/tenant/blocklist/<entry_id> \
  -H 'Authorization: Bearer <ta_token>'
```

### POST /api/tenant/blocklist/reconcile

手动触发禁拨对账（游标分批扫描线索，按名单刷新 `is_blocked`）。

**curl：**

```bash
curl -X POST https://tm-api-test.kao9.com/api/tenant/blocklist/reconcile \
  -H 'Authorization: Bearer <ta_token>'
```

---

## 统计看板

### GET /api/tenant/stats

租户级统计（TA/TM），读 `lead_stats_daily` 预聚合宽表。

**参数：**

| 参数 | 必填 | 类型 |
|------|:---:|------|
| `dateFrom` | ✅ | YYYY-MM-DD |
| `dateTo` | ✅ | YYYY-MM-DD |
| `projectId` | | 按项目过滤 |

**curl：**

```bash
curl 'https://tm-api-test.kao9.com/api/tenant/stats?dateFrom=2026-07-18&dateTo=2026-07-19' \
  -H 'Authorization: Bearer <ta_token>'
```

### GET /api/tenant/stats/mine

个人统计（TE）。

**curl：**

```bash
curl 'https://tm-api-test.kao9.com/api/tenant/stats/mine?dateFrom=2026-07-18&dateTo=2026-07-19' \
  -H 'Authorization: Bearer <te_token>'
```

---

## 审计日志

### GET /api/tenant/audit

审计日志列表（TA/TM）。

**curl：**

```bash
curl 'https://tm-api-test.kao9.com/api/tenant/audit?dateFrom=2026-01-01&dateTo=2099-12-31&size=20' \
  -H 'Authorization: Bearer <ta_token>'
```

---

## 接口文档

### GET /openapi.json

返回 OpenAPI 3.0 规范 JSON。

### GET /docs

Swagger UI 交互式文档。

**curl：**

```bash
curl https://tm-api-test.kao9.com/openapi.json | head -20
```
