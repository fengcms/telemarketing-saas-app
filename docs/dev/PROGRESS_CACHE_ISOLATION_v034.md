# 进度文档：跨账号缓存隔离 + 登录时序 + 日程 Tab 数字（v0.34）

> 关联计划：`docs/dev/PLAN_34_CACHE_ISOLATION.md`
> 关联分析日志：`.workbuddy/memory/2026-07-27.md`
> 版本：v0.34　日期：2026-07-27　真机：Redmi K60（3e06fd6d）

---

## 一、背景与动机（三个连续问题）

1. **跨账号私有数据残留**：A 退出换 B 登录后，线索 / 日程 / 通话 / 客户等私有数据疑似残留前一个账号。根因是登出只清 token、IndexedStack 保活 4 个 Tab 不重建、缓存 key 普遍不含 `userId`。
2. **两层用户模型修正**：App 存在两层用户含义——**同租户不同用户**（options / profile 属租户共享公共数据，应缓存复用以加速）与**不同租户不同用户**（一切缓存应全清）。原方案"一刀切全清"不对，需按租户边界分层。
3. **登录时序缺陷**：用户质疑登录后并行请求公司 + 首页数据。审查发现两个真实 bug（见 §三）。
4. **日程 Tab 数字口径错位**：经理 / 管理员在「我的」与「团队」间切换时，待办 / 已完成 Tab 数字与列表条目不一致。

---

## 二、修复 1：跨账号缓存隔离（CacheCoordinator + 纵深防御）

### 2.1 新增 `lib/providers/cache_coordinator.dart`
统一收口"账号 / 租户切换"时的缓存清退，**不再让各数据 provider 各自 listen auth**：

- `onLogout()`：仅清**用户私有**缓存（同租户换人保留共享，加速）。
  - `invalidate` 线索 / 日程列表 / 个人统计 / 日程统计 / 通话记录 / 客户详情预载等内存 provider
  - `callService.clear()`（内存）
  - `scheduleDetailCache.invalidateAll()` / `leadDetailCache.invalidateAll()`
- `onSessionChanged(crossTenant)`：
  - 任何切换都先跑 `_clearUserPrivate`
  - 仅当 `crossTenant == true` 再跑 `_clearTenantShared`：
    - `optionsCacheService.clearAll()`（**内存 + 磁盘**，key 加 `tenantId` 前缀）
    - `invalidate(teamStatsProvider)`（团队统计纯租户聚合）

### 2.2 缓存 key 加维度（纵深防御，P1）
即使清退逻辑漏网，错误 key 也命中不了别人数据：

| 文件 | 改动 |
|------|------|
| `schedule_list_provider.dart` | `_cacheKey` 拼 `${userId}:${scope}:${tab}:${ownerId}` |
| `personal_stats_provider.dart` | key 拼 `${userId}~${from}~${to}` |
| `team_stats_provider.dart` | 团队统计纯租户聚合，跨租户 `invalidate`（无 owner 字段） |
| `call_service.dart` | `_buildKey` 拼 `userId`；新增 `clear()` 清空缓存态 |
| `options_cache_service.dart` | 磁盘 key 改 `cache_options_{tenantId}_*` 前缀；新增 `clearAll()`（内存 + 删新旧磁盘 key） |

### 2.3 租户 ID 采集
`tenant_service.dart`：`fetchTenantId()` 采集并持久化 `GET /api/tenant/profile` 的 `data.id`（即租户 UUID）为 `_cachedTenantId`，供登录时比对"上次 / 本次"租户。

---

## 三、修复 2：登录时序优化（force tenantId，修 2 个 bug）

### Bug A（体验 + 白费请求）
原 `_clearTenantShared` 调 `tenantService.clearAll()`，把登录阶段刚预热好的公司数据全清了 → 首页公司名必"空白 → 重拉"闪烁，且那次 profile 请求白费。
**修法**：`_clearTenantShared` 去掉 `tenantService.clearAll()`（`fetchTenantId` 已刷新为正确新值，无需清）。

### Bug B（数据正确性 / 跨租户泄漏，更严重）
`fetchTenantId()` 走 `_ensureLoaded` 受 10h TTL 短路——跨租户但缓存有效时不调 API，返回**本地旧 tenantId**；`prevTenantId`（残留旧值）== `newTenantId`（也是旧值）→ `crossTenant=false` 误判同租户 → **不清理 options 缓存** → 新账号看到旧租户的归属人 / 分类下拉。
**修法**：`fetchTenantId({bool force = false})`，登录路径传 `force:true` 绕过 TTL，强制拉 profile 拿真实租户 ID。

### 接线（`auth_provider.dart`）
```dart
final prevTenantId = tenantService.cachedTenantId;        // 必须早于 fetchTenantId
await tenantService.fetchTenantId(force: true);            // 拿本次真实租户 ID
final crossTenant = prevTenantId != null &&
    prevTenantId != tenantService.cachedTenantId;
cacheCoordinator.onSessionChanged(crossTenant);
```
登录链路仍是 `async`，UI 跳首页在 await 链之后——先拿真实租户 ID、比对、判清缓存、完成后再进首页，与用户预期一致。

---

## 四、修复 3：日程 Tab 数字逻辑（Bug A / B / C）

### Bug A：Tab 数字口径与 scope 不一致
`ScheduleStatsState` 原只有单份 `stats`，经理在「我的」视图却显示团队总数。
**修法**：改为 `mineStats` + `teamStats` 双字段；新增 `pendingForScope(scope)` / `completedForScope(scope)` getter，按当前 scope 取对应口径。保留 `todayPending` getter 指向 mine 口径（供 home / 个人中心角标）。日程页 Tab 数字改为 `stats.pendingForScope(state.scope)` / `completedForScope(state.scope)`。

### Bug B：switchTab 缓存 key 拼错
`_switchTab` 原缓存 key 为 `'${state.scope}:$tab'`，漏了 `userId` / `ownerId` 维度，导致切 Tab 命中错误缓存或重拉闪烁。
**修法**：改为完整 `_cacheKey` 格式 `'${_userId ?? ''}:${state.scope}:$tab:${state.selectedOwnerId ?? ''}'`，命中缓存秒显不闪。

### Bug C：scheduleStatsProvider 未跨账号失效
跨账号切换时日程统计 provider 未随 CacheCoordinator 失效，残留旧数据。
**修法**：`_clearUserPrivate` 中补 `_ref.invalidate(scheduleStatsProvider)`。

---

## 五、改动文件清单

**新增**
- `lib/providers/cache_coordinator.dart`
- `docs/dev/PLAN_34_CACHE_ISOLATION.md`

**修改（11 个）**
- `lib/providers/auth_provider.dart`（force 接线 + CacheCoordinator 引用）
- `lib/services/tenant_service.dart`（采集 / 持久化 tenantId + force 参数）
- `lib/providers/options_provider.dart`（去空 listener，接 CacheCoordinator）
- `lib/services/options_cache_service.dart`（磁盘 key 加 tenantId + clearAll）
- `lib/providers/call_service_provider.dart`（注入 Ref + clear）
- `lib/services/call_service.dart`（key 拼 userId + clear）
- `lib/providers/personal_stats_provider.dart`（key 拼 userId）
- `lib/providers/team_stats_provider.dart`（跨租户 invalidate）
- `lib/providers/schedule_stats_provider.dart`（双口径 mine/team + scope getter）
- `lib/providers/schedule_list_provider.dart`（switchTab 完整 cacheKey）
- `lib/pages/schedules/schedule_list_page.dart`（Tab 数字接 scope 口径）

**质量门禁**：全仓 `flutter analyze` 0 error（仅 `token_storage.dart` 11 个 `!` 基线 warning，无关）；`flutter build apk --release --dart-define=DEV_TOOLS=true` 通过。

---

## 六、真机验证结论（Redmi K60）

- ✅ **跨账号隔离**：A 退出 → B（同租户）登录，私有数据清空、options / 归属人下拉为 B 正确值；跨租户切换一切缓存全清无残留。
- ✅ **登录时序**：登录后公司名直接进入就绪态，无"空白 → 重拉"闪烁；跨租户不再误判同租户（options 正确刷新）。
- ✅ **日程 Tab**：经理 / 管理员「我的」↔「团队」切换，待办 / 已完成数字与列表条目一致；切 Tab 无 loading 闪烁；员工无 scope 切换；跨账号无残留。
- 用户 2026-07-27 确认：**测试通过**。

---

**Mobile App Builder**　2026-07-27
