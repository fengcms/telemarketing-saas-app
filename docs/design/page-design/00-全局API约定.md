# 00 - 全局 API 约定（APP 与后端接口事实来源）

> **版本**：v1.0 | **更新日期**：2026-07-22 | **适用范围**：`docs/app/page-design/` 全部页面文档
>
> **本文档是所有页面文档接口章节的唯一事实来源**。页面文档中的接口描述如与本文档冲突，以本文档为准。
> 本文档内容逐项核验自后端源码（`src/`），非推断。后端实现如有调整，须先更新本文档，再联动页面文档。

---

## 1. 响应信封（所有接口统一）

后端不使用 `{code, data}` 或 `{code: 200, ...}`，统一信封如下（`src/lib/response.ts`）：

**成功：**

```json
{ "success": true, "data": { ... }, "error": null }
```

**失败：**

```json
{ "success": false, "data": null, "error": { "code": "AUTH_INVALID", "message": "邮箱或密码错误" } }
```

> ⚠️ 页面文档中出现的 `{"code": 0, ...}`、`{"code": 200, ...}`、`{"data": [...], "pagination": {...}}` 等写法**均为错误**，整改时一律改为上述信封。

---

## 2. 分页约定（所有列表接口统一）

**请求参数**：`page`（页码，从 1 起，默认 1）、`size`（每页条数，默认 20，最大 200）。**不使用** `offset/limit`、`pageSize`。

**响应体**（`data` 内）：

```json
{
  "items": [ ... ],
  "total": 128,
  "page": 1,
  "size": 20,
  "pages": 7
}
```

> 依据：`src/lib/constants.ts:66-71`（DEFAULT_PAGE/DEFAULT_SIZE/MAX_SIZE）、`src/lib/response.ts:27-41`（paginate）。

---

## 3. 列表过滤与排序约定

**过滤**：驼峰字段名。裸字段即等值匹配（`status=pending`），或加操作符后缀（`status__ne=disabled`、`createdAt__isNull`、`name__like=张`）。**不使用** snake_case 字段名（如 `updated_at`、`category__eq`）。

**排序**：`sort=-createdAt,name`（`-` 前缀为降序，逗号分隔多字段，驼峰命名）。

> 依据：`src/lib/query.ts`（buildListQuery）。线索列表允许的过滤/排序字段见 `leads.ts` 的 `LEAD_ALLOWED`。

---

## 4. 核心枚举值（与后端 schema 一致）

### 4.1 answerType（接听类型）

| 枚举值 | 中文 |
|--------|------|
| `answered` | 已接听 |
| `no_answer` | 无人接听 |
| `rejected` | 拒接 |
| `empty_number` | 空号 |
| `suspended` | 停机 |

> 依据：`src/db/schema.ts:144,232`。**页面文档中的 `connected`、`noAnswer`、`empty`、`stopped`、"已接通"、"未接"、"外呼" 等写法均为错误**，一律改为本表枚举值。
> 例外：「未接通」可作为 `no_answer / rejected / empty_number / suspended` 四类的**统称**使用（如"未接通场景按钮文案变化"、通话时长列显示"未接通"），但不得作为任一枚举值的单独中文标签。

### 4.2 lead status（线索状态）

`pending`（待跟进）/ `assigned`（已分配）/ `following`（跟进中）/ `converted`（已转化）/ `invalid`（无效）。

> 依据：`src/lib/constants.ts:74-80`。**不存在** `intentional`（有意向）、`lost`（已流失）——`lost` 是客户等级（customers.level），与线索状态无关。

### 4.3 direction（通话方向）

`outbound`（外呼）/ `inbound`（呼入）。

### 4.4 schedule status（日程状态）

`pending`（待办）/ `completed`（已完成）/ `cancelled`（已取消）。逾期（overdue）不是独立状态，是 `pending` 且 `scheduledAt ≤ now` 的派生标记。

---

## 5. 关键接口速查（页面文档高频引用）

| 用途 | 方法 路径 | 要点 |
|------|----------|------|
| 登录 | `POST /api/auth/login` | 失败码 `AUTH_INVALID`（401） |
| 刷新 Token | `POST /api/auth/refresh` | **不是** `/refresh-token` |
| 退出登录 | `POST /api/auth/logout` | **必须**在 body 传 `refreshToken` |
| 创建通话+跟进 | `POST /api/tenant/calls` | 携 `content` 时原子建通话+跟进（REQ-04，后端开发中）；`externalCallId` 必填做幂等 |
| 独立跟进 | `POST /api/tenant/leads/:id/followups` | 微信跟进等无通话场景；content ≤ 2000 |
| 编辑跟进 | `PATCH /api/tenant/leads/:id/followups/:fid` | 仅 `content`；TE 限 5 分钟内且仅自己 |
| 领取公海 | `POST /api/tenant/leads/:id/claim` | 仅 TE；响应 `{id, ownerId, status}`（**无 claimedAt**） |
| 创建日程 | `POST /api/tenant/schedules` | `scheduledAt` 为 **int Unix 秒**（非 ISO8601）；title ≤ 200、content ≤ 2000；支持 `callRecordId` |
| 我的统计 | `GET /api/tenant/stats/mine` | `dateFrom`/`dateTo` **必传** |
| 我的日程统计 | `GET /api/tenant/schedules/stats/mine` | 返回 `byStatus{pending,completed,cancelled,overdue,dueToday}`；`dueToday` = 今日到期未完成数（首页四宫格/日程Tab角标用） |
| 下拉-用户 | `GET /api/tenant/options/users` | 轻量（id+name+role），全角色可读；**下拉场景必须用它**，不要用 `/users`（TA 专属，TM 调用 403） |
| 下拉-分类 | `GET /api/tenant/options/categories` | 轻量 |
| 下拉-项目 | `GET /api/tenant/options/projects` | 轻量 |
| 快捷备注 | `GET /api/tenant/options/quick-notes` | 轻量 |

> ⚠️ **不存在** `GET /api/tenant/leads/filters` 接口，筛选下拉一律用 `options/*` 端点。

---

## 6. 字段长度限制（与后端校验一致）

| 字段 | 上限 | 依据 |
|------|:----:|------|
| 跟进备注 content | 2000 | `leads-followup.ts:21` |
| 日程标题 title | 200 | `schedules.ts:239` |
| 日程内容 content | 2000 | `schedules.ts:240` |

> 页面文档中"跟进备注 500 字""日程内容 500 字""日程标题 100 字"等写法均为错误，以本表为准。

---

## 7. 时间字段约定

- 后端存储与传输的时间戳（`startedAt`/`endedAt`/`scheduledAt`/`createdAt` 等）为 **int Unix 秒**。
- 页面文档示例中如出现 ISO8601 字符串（如 `"2026-07-15T15:00:00+08:00"`），仅为**展示层格式**，提交时须转为 Unix 秒。
- 展示层统一格式：日期时间 `YYYY-MM-DD HH:mm`，通话时长 `M:SS`。

---

## 8. 错误码速查（页面文档高频引用）

| code | HTTP | 含义 |
|------|:----:|------|
| `AUTH_INVALID` | 401 | 邮箱或密码错误 |
| `AUTH_EXPIRED` | 401 | Token 失效（刷新失败时跳登录页） |
| `AUTH_FORBIDDEN` | 403 | 无权限（如 TE 访问 TA 接口、非本人线索） |
| `NO_CALL_WINDOW` | 403 | 非可呼时段（夜间禁呼） |
| `NOT_FOUND` | 404 | 资源不存在 |
| `VALIDATION` | 400 | 参数校验失败（领取已被他人领走的线索也返回此码） |
| `INVALID_FILTER_FIELD` | 400 | 过滤/排序字段不在白名单 |
| `BLOCKLIST_REJECTED` | 422 | 命中禁拨名单 |
| `RATE_LIMIT` | 429 | 触发限流（`error.message` 目前为码值本身，前端需兜底默认文案） |
| `ACCOUNT_LOCKED` | 423 | 账号锁定（多次失败） |
| `FORCE_CHANGE_PASSWORD` | 423 | 必须改密（`must_reset_password=1` 时禁用所有非改密 API） |

> 依据：`src/lib/errors.ts` 的 `STATUS_BY_CODE`。**不存在** `INVALID_CREDENTIALS`、`PASSWORD_WEAK`、`TOKEN_EXPIRED` 等文档臆造码，整改时以本表为准。
