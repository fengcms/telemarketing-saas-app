# 首页日程聚合接口对接指南（APP / 前端）

> 适用版本：v2026-07-25 起（已部署测试环境）。本文档仅聚焦 `GET /api/tenant/schedules/home-summary`，供 APP 与前端以**最小改动**完成首页请求合并。
>
> **背景**：原首页需并行请求 3 个接口（`stats/mine` 之外的 `fetchMyScheduleStats` + `fetchDueSoonCount` + `fetchPendingSchedules`）才能拼出首页日程区。本次新增一个聚合端点，首页并行请求由 **4 → 2**（`stats/mine` + `home-summary`），后端数据由约 4 次查询在 `Promise.all` 内并发完成。

## 一、新端点一览

| 项 | 内容 |
|----|------|
| 方法 & 路径 | `GET /api/tenant/schedules/home-summary` |
| 鉴权 | `Authorization: Bearer <accessToken>`（与列表一致） |
| 角色范围 | 全部角色可读；**返回数据按角色收敛**（TE 仅本人，TM/TA 全团队） |
| 查询参数 | 无（无需传 `dateFrom`/`dateTo` 等） |
| 缓存建议 | 首页轮询即可，无需客户端强缓存；服务端未加缓存 |

## 二、请求示例

**curl**

```bash
curl 'https://tm-api-test.kao9.com/api/tenant/schedules/home-summary' \
  -H 'Authorization: Bearer <accessToken>'
```

> 无请求体、无查询参数。直接 GET 即可。

## 三、响应结构（真实示例，TM 角色）

```json
{
  "success": true,
  "data": {
    "todayPending": 1,
    "dueSoonCount": 0,
    "pendingTotal": 9,
    "schedules": [
      {
        "id": "62af2542-0fe5-4f5e-9aa0-080975f9b84d",
        "tenantId": "t1000001-0000-0000-0000-000000000001",
        "userId": "u00000007-0000-0000-0000-000000000007",
        "leadId": "005fe35b-d22a-489b-a478-3d5692d47a80",
        "callRecordId": null,
        "title": "预约看房",
        "content": "客户在外地需要电话沟通",
        "scheduledAt": 1784744984,
        "status": "pending",
        "completedAt": null,
        "createdAt": 1784720387,
        "updatedAt": 1784720387,
        "deletedAt": null,
        "lead": {
          "name": "陈磊",
          "phone": "13000010016"
        }
      }
    ]
  },
  "error": null
}
```

> `schedules` 数组**最多返回 5 条**（按 `scheduledAt` 升序、优先最近的待办）。`pendingTotal` 才是全量待办总数，用于「查看全部」红点判断。

## 四、字段语义（务必看）

| 字段 | 类型 | 含义 | 口径说明 |
|------|------|------|----------|
| `todayPending` | number | **今天**待办数 | `scheduledAt` 落在**北京时间当天 00:00:00 ~ 23:59:59** 且 `status=pending`。**不含历史逾期未办**（严格今日窗口）。 |
| `dueSoonCount` | number | 即将到期数 | `scheduledAt` 落在 `[now, now + 30 分钟]` 内且 `status=pending`（北京时间）。用于「30 分钟内到期」提醒。 |
| `pendingTotal` | number | 待办总数 | 当前用户/团队所有 `status=pending` 的日程条数（`deleted_at IS NULL`）。**必返**，前端可直接用作「我的待办」未读角标。 |
| `schedules` | array | 待办预览列表 | 取 `pending` 中前 5 条，结构与列表项**完全一致**（见下）。 |

### 🔴 时区红线
所有时间计算**服务端统一用北京时间（Asia/Shanghai, UTC+8）**，与旧 `schedules/stats/mine` 的 `dueToday` 边界一致。前端**不要**再用本地时区换算「今天」，直接用服务端返回的 `todayPending` 即可。

### 🔴 与旧 `dueToday` 的差异（产品需知）
旧 `dueToday` 口径是「`scheduledAt <= 今天 23:59:59`（无下限，含历史逾期）」。新 `todayPending` 是「严格今日窗口，不含逾期」。两者数值在「存在逾期待办」时**会不同**，新值更小、更精确。这是评审时与后端确认过的预期行为，不是 Bug。

### `schedules` 列表项结构（与 `Schedule.fromJson` 同构）
- 字段与普通日程列表项 100% 一致，可直接复用现有的 `Schedule.fromJson` 解析。
- `lead` 快照：`{ "name": string, "phone": string }`。**注意 `phone` 永远是非空字符串**——线索无手机号时后端置为 `""`，前端无需再做 `null` 判断。
- `scheduledAt` 为 **Unix 秒级时间戳**（与列表一致），前端 `new Date(ts * 1000)` 转换。

## 五、前端要删 / 要改的

**删除 3 个旧请求方法（不再调用）：**
- `fetchMyScheduleStats` → 已被 `todayPending` / `pendingTotal` 覆盖
- `fetchDueSoonCount` → 已被 `dueSoonCount` 覆盖
- `fetchPendingSchedules` → 已被 `schedules[]` 覆盖

**新增 1 个请求：**

```ts
async function fetchHomeSummary(token: string) {
  const r = await fetch(`${BASE}/api/tenant/schedules/home-summary`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const j = await r.json();
  if (!j.success) throw new Error(j.error?.code ?? "HOME_SUMMARY_FAIL");
  return j.data; // { todayPending, dueSoonCount, pendingTotal, schedules[] }
}
```

**首页并行请求（示例）：**

```ts
const [mine, home] = await Promise.all([
  fetchStatsMine(token),        // 原有 stats/mine（持有线索数等）
  fetchHomeSummary(token),      // 新增：今日待办/即将到期/预览
]);
```

## 六、APP 端最小改动清单

1. 删除 `fetchMyScheduleStats` / `fetchDueSoonCount` / `fetchPendingSchedules` 三处调用及并发逻辑。
2. 新增 `fetchHomeSummary`，首页加载时与 `stats/mine` 一起 `Promise.all` 并发。
3. 字段映射：
   - 首页「今日待办」Badge ← `home.todayPending`
   - 「30 分钟内到期」提醒 ← `home.dueSoonCount`
   - 「我的待办」入口红点 ← `home.pendingTotal > 0`
   - 首页待办预览列表 ← `home.schedules`（直接 `Schedule.fromJson`）
4. **不要**再本地换算「今天」——时区由服务端保证。

## 七、错误码

- `401` `AUTH_INVALID` / `AUTH_EXPIRED`：token 失效，走重新登录流程（与现有列表接口一致）。
- 无新增业务错误码；参数固定无输入，不存在 400 校验失败。

## 八、全端 Badge 口径统一（避免数字不一致）

同一账号在 App 内不同位置显示的「待办数」必须一致。为此：

- `GET /api/tenant/schedules/stats/mine` 与 `GET /api/tenant/schedules/stats`（团队版）现在**顶层都返回 `todayPending`**，与 `home-summary.todayPending` 由**同一函数**计算（严格今日窗口、北京时间、不含逾期），三者数值逐字节相同。
- **四个位置统一读 `todayPending`**：
  - 首页「今日待办」Badge ← `home-summary.todayPending`
  - 首页四宫格「今日到期」← `home-summary.todayPending`
  - 底部 Tab「日程」角标 ← `stats/mine.todayPending`（TE）或 `stats.todayPending`（TM/TA）
  - 个人中心「今日待办」 ← `stats/mine.todayPending`（TE）或 `stats.todayPending`（TM/TA）
- ⚠️ **不要**再用 `dueToday`（旧字段，含历史逾期，数字会偏大）或 `byStatus.pending`（全量待办，不限日期，数字最大）做 Badge——这两个字段口径与首页不同，正是此前「首页显示 5、Tab 显示 7」不一致的根因。
- 逾期事项若产品希望仍可见，用已有的 `overdue` 字段单独做红色「逾期 N」角标或列表高亮，不要塞进主 Badge。

## 九、一句话结论

首页日程区以后**只调一个** `GET /api/tenant/schedules/home-summary`：
`todayPending`（今日待办）、`dueSoonCount`（即将到期）、`pendingTotal`（待办总数）、`schedules[≤5]`（预览列表）一次性拿到，列表项直接用 `Schedule.fromJson` 解析，时区放心交给服务端。
