# 线索与客户编辑接口 · 后端真实契约（可直接转发 App 开发）

> 根据 App 开发需求清单，核实后端已具备的接口。**两个接口都已存在，无需新建**。

---

## 1. `PATCH /api/tenant/leads/:id` — 编辑线索

### 已支持的请求体字段（全部可选，缺省不修改）

```json
{
  "name": "新姓名",           // string, max60
  "phone": "13800138000",   // string, max40（TE 不传，因只能看到脱敏号）
  "wechat": "wx123",        // string, max60
  "company": "公司名",       // string, max120
  "position": "职位",        // string, max60
  "gender": "男",           // string, max10
  "age": 30,                // number, int
  "address": "地址",         // string, max255
  "source": "来源",          // string, max60
  "intention": "意向描述",    // string, max255
  "remark": "线索备注",       // string, max500
  "projectId": "p001",       // string, max64（更换项目 → 触发去重校验）
  "categoryId": "cat001",    // string, max64
  "customFields": { ... },   // object，自定义字段
  "status": "following"      // enum: pending|assigned|following|converted|invalid
}
```

### ✅ App 需求对照

| App 需要的字段 | 是否支持 |
|---|---|
| `name` | ✅ 支持 |
| `remark` | ✅ 支持（max500） |
| `categoryId` | ✅ 支持 |
| `status` | ✅ 支持 |

### ⚠️ 角色权限（重要）

| 操作 | TM / TA（管理员） | TE（员工） |
|---|---|---|
| 改 name / remark / phone / company 等资料字段 | ✅ **可以** | ❌ **不可**，仅限于 status 和 categoryId |
| 改 status / categoryId | ✅ 可以 | ✅ 可以 |

也就是说，**TE 目前只能改自己的线索的 `status` 和 `categoryId`**，不能改 `name`、`remark` 等字段。如果需要 TE 也能改 `name` 和 `remark`，需要后端调整一处权限配置（一行代码），您看要不要放开？

### 约束说明

- 已转化（`converted`）线索：**任何角色不可修改**，返回 `400 + STATUS_ROLLBACK_FORBIDDEN`
- TE 改 `status`：仅限 `following` 或 `converted`（设 `invalid` 被拒）
- `phone` 变更：自动触发标准化 + 禁拨校验 + 排重校验

### 成功响应（200）

```json
{
  "success": true,
  "data": {
    "id": "lead-uuid",
    "updated": ["name", "remark", "status"]
  }
}
```

---

## 2. `PATCH /api/tenant/customers/:id` — 编辑客户

### 已支持的请求体字段（全部可选）

```json
{
  "name": "客户姓名",           // string, max100
  "phone": "13800138000",     // string, max40
  "company": "公司",           // string, max200
  "position": "职位",          // string, max100
  "gender": "男",             // string, max20
  "age": 30,                  // number, int
  "wechat": "wx123",          // string, max100
  "address": "地址",           // string, max500
  "ownerId": "user-uuid",     // string，归属人
  "projectId": "p001",        // string
  "categoryId": "cat001",     // string
  "level": "important",       // enum: normal | important | vip | lost
  "remark": "客户备注",         // string, max1000
  "customFields": { ... },    // object
  "consentAt": 1700000000     // number, int（授权获取时间）
}
```

### ✅ App 需求对照

| App 需要的字段 | 是否支持 |
|---|---|
| `name` | ✅ 支持（max100） |
| `level` | ✅ 支持（枚举：normal / important / vip / lost） |
| `remark` | ✅ 支持（max1000，比线索的 500 更宽） |

### 权限说明

| 操作 | TM / TA | TE |
|---|---|---|
| 改本人归属的客户 | ✅ | ✅ **可以** |
| 改他人归属的客户 | ✅ | ❌ AUTH_FORBIDDEN |

⚠️ 注意：`level` 是一个有限枚举，传值必须是 `normal` / `important` / `vip` / `lost` 之一，传错返回 VALIDATION（400）。

### 成功响应（200）

```json
{
  "success": true,
  "data": {
    "id": "customer-uuid",
    "updated": ["name", "level", "remark"]
  }
}
```

---

## 总结

| App 开发的需求 | 后端现状 | 需要后端调整？ |
|---|---|---|
| `PATCH /leads/:id` 支持 name + remark | ✅ **已支持**（TM/TA 可用） | 如需 TE 也可改 → 需放开 TE_FIELDS（1 行） |
| `PATCH /customers/:id` 新接口 | ✅ **已存在**，支持 name / level / remark | 不需要 |
