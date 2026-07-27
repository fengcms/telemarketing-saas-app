# 计划（PLAN_34 v2）：按「租户」隔离的跨账号缓存修复

- **版本**：v0.34（bug 修复，非新页面）
- **日期**：2026-07-27（修订：从「每次切换全清」改为「按租户分层」）
- **前置**：已完成两轮分析（见对话 + 今日工作日志 `.workbuddy/memory/2026-07-27.md`）
- **目标**：
  - **同租户换人**（A→B，同 tenant）：私有数据清空；**租户共享数据（options / 租户 profile）保留缓存**，加快访问。
  - **跨租户换人**（tenant X → tenant Y）：**一切缓存全部清空**（私有 + 共享，含磁盘）。

---

## 一、用户两层含义与缓存分级（本方案核心）

| 数据 | 隔离层级 | 同租户换人 | 跨租户换人 |
|------|-----------|------------|------------|
| 线索列表 `leadListProvider` | 用户私有 | **清** | **清** |
| 日程列表 `scheduleListProvider`（mine） | 用户私有 | **清** | **清** |
| 通话 `CallService` 缓存 | 用户私有 | **清** | **清** |
| 个人统计 `personalStatsProvider` | 用户私有 | **清** | **清** |
| 线索/日程详情缓存 `Lead/ScheduleDetailCache` | 用户私有（id key） | **清** | **清** |
| 团队统计 `teamStatsProvider`（聚合） | 租户共享 | **保留**（仅重置归属人筛选） | **清** |
| 选项 `OptionsCacheService`（分类/项目/归属人/快捷备注） | 租户共享 | **保留** | **清（内存+磁盘）** |
| 租户配置/名称 `TenantService` | 租户共享 | **保留** | **清（内存+磁盘）** |
| 客户列表 `CustomerListPage` | 用户私有（页内 State） | 无需处理（push 路由，打开即重载，无单例缓存） | 同左 |

> 原则：**用户私有 = 任何切换都清**（同租户也清，因为 A 的数据 B 不能看）；
> **租户共享 = 仅跨租户清**（同租户内所有用户看到的数据一致，缓存有意义）。

---

## 二、关键事实（已核实，文档可证）

1. **登录响应 `POST /api/auth/login` 的 `body.user` 不含 `tenantId`**（api.md:177 仅 `{id,email,name,role}`）。
2. **`GET /api/tenant/profile` 的 `data.id` 就是租户 UUID**（api.md:529 `"id": "租户 UUID"`）。`TenantService` 已在调该接口，只是把 `id` 丢掉了。
3. **`TokenStorage.clearAll()` 只删自己的 6 个 key**（access/refresh/userId/userName/userEmail/userRole），**不碰** `TenantService` 的 `cache_tenant_*` SharedPreferences key → 跨登出租户 ID 可持久留存，用于「对比上一次登录的租户」。
4. `User` 模型无 `tenantId`；`api_client` 无租户请求头（后端纯靠 token 服务端判定）。→ **前端没有现成 tenantId，必须新增采集 + 持久化**。
5. `OptionsCacheService` 磁盘 key 是**全局写死**（`cache_options_categories` 等），未带租户维度 → 跨租户会泄漏，必须 `clearAll()` 清磁盘。

---

## 三、租户 ID 采集与持久化方案

在 `TenantService` 内补齐（改动最小、复用既有 profile 调用）：

- `_refreshFromApi()`：`_cachedTenantId = profile['id']?.toString();`
- 新增字段 `_cachedTenantId`；SharedPreferences key `_keyTenantId = 'cache_tenant_id'`，纳入 `_loadFromLocal` / `_saveToLocal`。
- 暴露：
  - `String? get cachedTenantId` —— 返回**内存中当前值**（注意：在 `fetchTenantId()` 刷新前读取，即为「上一次登录的租户」）。
  - `Future<String?> fetchTenantId()` —— `_ensureLoaded()` 后返回 `_cachedTenantId`（首次/过期会拉 profile 并写盘）。
- **判定顺序（在 `auth_provider.login` 内）**：
  ```dart
  final tenantService = _ref.read(tenantServiceProvider);
  final prevTenantId = tenantService.cachedTenantId;        // 先读「上次」
  final newTenantId = await tenantService.fetchTenantId();  // 再刷新拿「本次」
  final crossTenant = prevTenantId != null && prevTenantId != newTenantId;
  _ref.read(cacheCoordinatorProvider).onSessionChanged(crossTenant: crossTenant);
  ```
  - 首次登录：`prevTenantId == null` → `crossTenant = false` → 当作「新装」，仅清私有（无副作用），随后写盘新 tenantId。
  - 同租户换人：`prev == new` → `crossTenant = false` → 保留租户共享缓存。
  - 跨租户换人：`prev != new` → `crossTenant = true` → 全清。

---

## 四、协调器与登入/登出钩子

新增 `lib/providers/cache_coordinator.dart`：

```dart
class CacheCoordinator {
  final Ref _ref;
  CacheCoordinator(this._ref);

  /// 登出（即将切换账号，租户可能不变）：只清用户私有
  void onLogout() => _clearUserPrivate();

  /// 登录成功后：私有必清；跨租户再清共享
  void onSessionChanged({required bool crossTenant}) {
    _clearUserPrivate();
    if (crossTenant) _clearTenantShared();
  }

  void _clearUserPrivate() {
    _ref.invalidate(leadListProvider);
    _ref.invalidate(scheduleListProvider);
    _ref.invalidate(personalStatsProvider);
    _ref.read(callServiceProvider).clear();
    _ref.read(leadDetailCacheProvider).invalidateAll();
    _ref.read(scheduleDetailCacheProvider).invalidateAll();
    _ref.read(teamStatsProvider.notifier).resetOwnerFilter(); // 仅重置归属人筛选，保留聚合缓存
  }

  void _clearTenantShared() {
    _ref.read(optionsCacheServiceProvider).clearAll(); // 内存 + 磁盘
    _ref.read(tenantServiceProvider).clearAll();        // 内存 + 磁盘（含 tenantId）
    _ref.invalidate(teamStatsProvider);                // 团队聚合是租户级，跨租户必清
  }
}
```

钩子接入：

| 位置 | 改动 |
|------|------|
| `auth_provider.login()` | 登录成功后、`state = authenticated` 前，调 `onSessionChanged(crossTenant:)`（见第三节顺序）。 |
| `auth_provider.logout()` | `authService.logout()` 之后、置未登录前，调 `onLogout()`（只清私有；租户共享保留供同租户换人加速）。 |
| `auth_provider.logoutAll()` | 成功后同样调 `onLogout()`。 |
| `auth_provider.tryAutoLogin()` | **不调** clearing（恢复的是同一 token/租户，prevTenantId 持久值本就一致）。 |

> 不再沿用「每个 provider 各自 `ref.listen(authProvider)`」的旧方案（v1 写法），改为**单一协调器 + 登录时一次性按租户判定**，逻辑集中、无「登出瞬间构造器误发请求」风险，且天然支持「同租户保留共享」。

---

## 五、各缓存 holder 改动清单

### P0 — 必须（实现两层隔离）

| # | 文件 | 改动 |
|---|------|------|
| 1 | `lib/services/tenant_service.dart` | 采集并持久化 `tenantId`（见第三节）；新增 `clearAll()`（清内存 `_cachedSettings/_cachedName/_cachedTenantId/_lastFetchTime` + `prefs.remove` 三个 `cache_tenant_*` key）。 |
| 2 | `lib/providers/cache_coordinator.dart` | **新建**；实现上节 `_clearUserPrivate` / `_clearTenantShared` / `onLogout` / `onSessionChanged`。 |
| 3 | `lib/providers/auth_provider.dart` | `login()` 接入租户判定 + `onSessionChanged`；`logout()` / `logoutAll()` 接入 `onLogout()`。 |
| 4 | `lib/services/call_service.dart` | 新增 `void clear()`（置空 `_cache` / `_cacheKey` / `_cacheTime`）。 |
| 5 | `lib/providers/team_stats_provider.dart` | 新增 `void resetOwnerFilter()`（仅把归属人筛选 state 复位，不动聚合缓存）；跨租户由协调器 `invalidate` 整提供者。 |
| 6 | `lib/services/options_cache_service.dart` | 新增 `Future<void> clearAll()`（清内存 4 列表 + `_lastFetchTime`，并 `prefs.remove` 5 个 `cache_options_*` key，含旧全局 key 与新租户前缀 key 两种形态以兼容迁移）。 |

> 说明：`leadListProvider` / `scheduleListProvider` / `personalStatsProvider` 通过协调器 `ref.invalidate(...)` 重建（构造器 `_loadInitial()` / `load()` 自动按新用户重载），**无需各自加 listener**，改动更小、更不易漏。

### P1 — 纵深防御（推荐一并做，成本低）

给缓存 key 拼 `tenantId`（租户共享）或 `userId`（用户私有），即使未来某条失效路径遗漏也不会串号；同时让「同租户保留」自动成立：

| # | 文件 | 改动 |
|---|------|------|
| 7 | `options_cache_service.dart` | 磁盘 key 加租户前缀：`cache_options_{tenantId}_categories` 等（tenantId 取自 `tenantService.cachedTenantId`）。 |
| 8 | `tenant_service.dart` | 其自身 `cache_tenant_*` key 已含 tenantId 语义（本身就是按当前租户），无需再改。 |
| 9 | `schedule_list_provider.dart` | `_cacheKey` 前缀 `${userId}:`。 |
| 10 | `call_service.dart` | `_buildKey` 前缀 `${userId}|`。 |
| 11 | `personal_stats_provider.dart` / `team_stats_provider.dart` | key 前缀 `${userId}~` / `${tenantId}~`（个人按用户、团队按租户）。 |

> P0 已能**完整交付**用户的两层模型（同租户保留 options 是因为「根本不清它」，跨租户由 `clearAll` 清）。P1 仅作防御：万一将来新增 holder 漏接协调器，key 维度也能拦住串号。userId/tenantId 取空时退化为原 key，无破坏性。

### P2 — 收尾（非阻塞）

- 在 `MILESTONES` / `DEVELOPMENT_PITFALLS` 沉淀「跨账号缓存必须按租户分层失效；新增数据 holder 须接入 `CacheCoordinator`」规范，防后人重犯。
- 客户列表若未来抽成 Riverpod provider，须纳入 `_clearUserPrivate`。

---

## 六、关键实现细节（示意，非最终代码）

`auth_provider.login()` 片段：
```dart
final result = await authService.login(email: email, password: password);

// ── 跨租户判定（必须在 fetchTenantId 前读 prev）──
final tenantService = _ref.read(tenantServiceProvider);
final prevTenantId = tenantService.cachedTenantId;
final newTenantId = await tenantService.fetchTenantId();
final crossTenant = prevTenantId != null && prevTenantId != newTenantId;
_ref.read(cacheCoordinatorProvider).onSessionChanged(crossTenant: crossTenant);

if (result.mustResetPassword) {
  state = AuthState(status: AuthStatus.forceChangePassword, user: result.user);
} else {
  state = AuthState(status: AuthStatus.authenticated, user: result.user);
}
```

`tenant_service.dart` 片段：
```dart
String? _cachedTenantId;
static const _keyTenantId = 'cache_tenant_id';

// _refreshFromApi 内：
_cachedTenantId = profile['id']?.toString();

// 新增：
String? get cachedTenantId => _cachedTenantId;
Future<String?> fetchTenantId() async {
  await _ensureLoaded();
  return _cachedTenantId;
}
Future<void> clearAll() async {
  _cachedSettings = null;
  _cachedName = null;
  _cachedTenantId = null;
  _lastFetchTime = null;
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keySettings);
  await prefs.remove(_keyName);
  await prefs.remove(_keyTenantId);
  await prefs.remove(_keyTime);
}
```

---

## 七、验证方案

1. **`flutter analyze`**：改动文件 0 issue（全仓仅 `token_storage.dart` 11 个 `!` 基线 warning，无关）。
2. **构建带调试浮标 release APK**（`flutter build apk --release --dart-define=DEV_TOOLS=true`）+ `adb install -r` 到 Redmi K60（`3e06fd6d`）。
3. **真机实测（你执行）**：
   - **场景一 · 同租户换人**：用工号 A 登录，进 线索/日程/通话/我的业绩/团队看板，确认有数据；退出 A，用工号 B（同租户不同人）登录；**不先下拉刷新**即进上述各页，确认：
     - 线索/日程/通话/我的业绩 **已是 B 的数据**（私有清空生效）；
     - 归属人姓名、分类名等下拉映射 **正确且无需重新拉取**（options 缓存保留加速生效）；
     - 团队看板数字为 B 视角（聚合租户共享保留）。
   - **场景二 · 跨租户换人**：登 tenant X 的账号 A，进各页有数据；退出，登录 tenant Y 的账号 C；确认：
     - 所有私有数据为 C 的；
     - **options 下拉项、租户名称均为 tenant Y 的**（磁盘 `cache_options_*` / `cache_tenant_*` 已清，无 X 残留）。
   - 极端：登录 A → 进详情（触发 DetailCache）→ 退出 → 登录 B → 进详情，确认 B 不命中 A 的详情缓存。
4. 下拉刷新后数据正常为当前账号（验证重载链路）。

---

## 八、风险与回滚

- **风险低**：纯「清空 + 重建 + 按租户判定」，不改任何接口/字段/UI 结构；登录时多一次 profile 调用（本就常被触发，可忽略）。
- **IndexedStack 不受影响**：`invalidate` 让常驻页重建为空态/骨架，无旧数据闪现。
- **回滚**：单 commit，出问题 `git revert` 即可；不影响数据层与后端。

---

## 九、范围外（本次不做）

- 不改动任何后端接口、不新增接口。
- iOS/Web 部署（仅 Android 真机验证，与历史节点一致）。

---

## 十、待确认（见对话提问）

1. **options 是否对同租户所有角色返回一致数据？**
   - 若「是」→ options 归租户共享，同租户换人保留（本计划默认）。
   - 若「否」（如归属人列表员工只看到自己、管理员看到全部）→ options 必须**每次切换都清**，否则员工登录会看到管理员的越权数据；届时把 options 从「租户共享」移至「用户私有」桶。
2. **修复范围**：P0 + P1 一并做（推荐，纵深防御）？还是只做 P0（最小改动）？

确认后进入开发，按铁律：开发完成 → analyze → 构建装真机 → **你真机实测通过** → 写进度/踩坑文档 → 更新 MILESTONES → commit & push。
