# 首页日程数据接口合并需求（独立轻量端点 · 含待办预览列表）

> **背景**：APP 首页每次加载/刷新时，为获取日程相关数据需发起 **4 个并行请求**。其中 2 个请求仅为了获取 2 个整数字段（`dueToday` 和未来 30 分钟到期数），第 1 个请求还额外拉取了首页「待办日程」预览卡片所需的 5 条日程对象。
> **目标**：新增一个轻量独立端点 `GET /api/tenant/schedules/home-summary`，**一次性返回首页日程区所需的全部数据**——统计摘要 + 即将到期提醒数 + 待办预览列表，从而把 3 个冗余/重复请求（#2、#3、#4）合并为 1 个。
> **不修改** `GET /api/tenant/schedules` 的分页响应结构。

---

## 一、当前 4 个并行请求链路

| # | 请求 | 首页用途 | 返回数据量 |
|:-:|------|---------|-----------|
| 1 | `GET /api/tenant/stats/mine?dateFrom=today&dateTo=today` | 四宫格统计（跟进数/接通数/线索数等） | 完整 HomeStats 对象 |
| 2 | `GET /api/tenant/schedules?status=pending&page=1&size=5&sort=scheduledAt` | 待办日程预览卡片（5 条卡片数据） | 日程对象列表 + total |
| 3 | `GET /api/tenant/schedules/stats/mine` | 四宫格「今日待办」数值 → **只取 `dueToday` 一个字段** | 完整 HomeStats |
| 4 | `GET /api/tenant/schedules?status=pending&scheduledAt__gte={now}&scheduledAt__lte={now+1800}&page=1&size=1` | 到期提醒条 → **只取 `total` 一个数字** | 分页体（含 items 空数组） |

**首页日程区实际需要的全部数据**：

| 需要的数据 | 类型 | 来自哪个请求 | 当前 UI 用法 |
|-----------|------|------------|------------|
| 5 条待办日程预览（id, title, scheduledAt, lead.name） | 列表 | #2 | 待办日程 Section 卡片 |
| 今日待办总数（截止当前统计） | int | #3 | 待办日程标题右侧 Badge |
| 未来 30 分钟内到期数 | int | #4 | 到期提醒条 |

→ **实际需要 3 类数据，用了 3 个请求（#2、#3、#4），其中 #3 和 #4 各只取一个 int，#2 还要单独跑一次完整列表查询。**

---

## 二、改造方案

### 2.1 新增接口

```
GET /api/tenant/schedules/home-summary
```

首页专用轻量端点，返回当日日程统计摘要、即将到期提醒数，以及待办日程预览列表。

**角色**：全角色（TE/TM/TA）可读。
**缓存建议**：60 秒（首页 10 分钟轮询周期下足够，避免每次轮询都灌 DB）。

### 2.2 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| — | — | — | 无参数。今日范围由服务端以**服务端当前时区**计算 |

### 2.3 响应体

```json
{
  "success": true,
  "data": {
    "todayPending": 42,
    "todayCompleted": 15,
    "todayCancelled": 3,
    "dueSoonCount": 2,
    "pendingTotal": 56,
    "schedules": [
      {
        "id": "3cb04ac1-58d2-46e2-88b4-7a891e358912",
        "tenantId": "t1000001-0000-0000-0000-000000000001",
        "userId": "u00000004-0000-0000-0000-000000000004",
        "leadId": "25cfa352-0271-448f-99ff-66f6308c27ad",
        "callRecordId": null,
        "title": "确认联系方式",
        "content": "客户说等发工资再聊",
        "scheduledAt": 1785526368,
        "status": "pending",
        "completedAt": null,
        "createdAt": 1784720387,
        "updatedAt": 1784720387,
        "deletedAt": null,
        "lead": { "name": "王磊", "phone": "15500010045" }
      }
    ]
  },
  "error": null
}
```

> `schedules` 数组内每个元素**与现有 `GET /api/tenant/schedules` 列表项的字段结构完全一致**（含 `lead` 快照），前端可直接复用 `Schedule.fromJson` 解析，无需新增模型。

### 2.4 字段说明

| 字段 | 类型 | 计算规则 |
|------|------|---------|
| `todayPending` | int | **必返**。截止当前时间，当日 00:00:00 ~ 23:59:59 之间 `status=pending` 的日程总数。首页「今日待办」Badge 数据来源（对应原 `schedules/stats/mine` 的 `dueToday`）。 |
| `dueSoonCount` | int | **必返**。当前时间起未来 30 分钟内 `status=pending` 且 `scheduledAt` 在此区间内的日程数。首页到期提醒条数据来源。 |
| `schedules` | array | **必返**。待办日程预览，`status=pending` 按 `scheduledAt` 升序取**前 5 条**（无日期范围限制，与原 `fetchPendingSchedules` 行为一致）。元素结构同 `GET /api/tenant/schedules` 列表项（含 `lead` 快照）。总数不足 5 条时返回实际条数，无待办时返回空数组 `[]`。 |
| `pendingTotal` | int | 可选返回。全量待办（跨日期）总数，对应原列表查询的 `total`。_当前 UI 未直接使用，预留「查看全部」入口的未读提示_ |
| `todayCompleted` | int | 可选返回。当日完成的日程数。_当前 APP 未使用，预留未来版本_ |
| `todayCancelled` | int | 可选返回。当日取消的日程数。_当前 APP 未使用，预留未来版本_ |

### 2.5 边界情况

| 场景 | 后端返回 |
|------|---------|
| 今日无待办 | `todayPending: 0`，`schedules: []` |
| 无即将到期 | `dueSoonCount: 0` |
| 待办不足 5 条 | `schedules` 返回实际条数 |
| 日期变更临界点（23:59→00:00） | 以服务端时区为准 |
| 数据库无任何日程 | 计数全部返回 0，`schedules: []` |

---

## 三、前端改动

接口上线后，APP 端：

1. **删除** `HomeService.fetchMyScheduleStats()` — 不再调 `GET /api/tenant/schedules/stats/mine`
2. **删除** `HomeService.fetchDueSoonCount()` — 不再调时间范围查询
3. **删除** `HomeService.fetchPendingSchedules()` — 不再调 `GET /api/tenant/schedules?status=pending&size=5`
4. **新增** `HomeService.fetchHomeSummary()` — 调 `GET /api/tenant/schedules/home-summary`，返回含 `todayPending` / `dueSoonCount` / `schedules` / `pendingTotal` 的聚合对象；`schedules` 直接 `Schedule.fromJson` 解析
5. **`HomePageNotifier.loadData()`** 中 `Future.wait` 从 4 个并行请求减为 **2 个**（保留 `fetchMyStats` 四宫格统计 + 新增 `fetchHomeSummary`）

**改动量估算**：约删 70 行旧代码（3 个请求方法 + 合并逻辑）+ 增 35 行新代码（1 个聚合方法 + 字段映射）= 净减约 35 行。

---

## 四、收益

| 指标 | 改造前 | 改造后 |
|------|--------|--------|
| 首页总并行请求数 | **4 次** | **2 次** |
| 其中「只取一个 int」的浪费请求 | 2 次（#3、#4） | 0 次 |
| 单独拉取待办列表的请求 | 1 次（#2） | 0 次（并入摘要） |
| 新增后端端点 | — | 1 个轻量端点（含 5 条预览） |
| 修改既有接口 | 不变 | 不变 |
| 减少的无效查询（DB 侧） | 3 次（2 聚合 + 1 完整列表）/次 | 1 次聚合查询/次 |

> 首页 4 个请求 → 仅剩 `GET /api/tenant/stats/mine`（四宫格业务统计）与 `GET /api/tenant/schedules/home-summary`（全部日程区数据），职责清晰、互不耦合。

---

> 文档状态：**定案**
> 选用独立端点方案，不改分页接口；待办预览列表与统计摘要合并返回。
