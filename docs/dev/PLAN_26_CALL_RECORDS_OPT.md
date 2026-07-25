# PLAN_26 通话记录列表优化

> 版本：v0.28 | 日期：2026-07-25 | 作者：Mobile App Builder
> 关联需求：通话记录列表缓存（5 分钟）+ TM/TA 卡片显示拨打人

## 1. 背景与现状

- **通话记录列表页** `lib/pages/call_records/call_records_page.dart`
  - 当前每次**进入页面 / 下拉刷新 / 切换筛选**都会调用 `CallService.fetchMyCalls()`，无本地缓存。
  - 页面用 `ConsumerStatefulWidget` + 本地 state 管理，列表数据存在 `_items`（页面销毁即丢失），所以**每次进入必发请求**。
  - `CallRecord` 模型已带 `userId` 字段（`lib/models/call_record.dart:8`），但列表卡片（`call_record_row.dart`）目前**未使用**它。
- **归属人映射**：`OptionsCacheService` 已具备 `getUserName(id)` / `getUsers()`（内存 + 本地 10h 双缓存），可直接把 `userId` 映射成姓名，沿用线索/日程详情的既有模式。
- **角色判定**：`role` 字段由后端原值返回并存储，真实取值为 `'tenant_manager'` / `'tenant_admin'`（用户简称 TM / TA）。下方判定**仅用这两个真实值**，不写缩写。

## 2. 改造目标

### 目标 1：列表数据加 5 分钟缓存
- 首屏（page=1）结果按 `(q, answerType)` 组合缓存，TTL 300 秒。
- **进入页面**时若命中有效缓存（同筛选条件且 5 分钟内）→ 直接套用缓存数据，**不发网络请求**，也无骨架闪烁。
- **切换接听类型筛选** → key 变化 → 缓存未命中 → 走网络（符合预期，不同筛选本来就是不同数据）。
- **下拉刷新** → `force=true` 强制绕过缓存、拉最新；同时刷新缓存时间戳。
- **无限滚动翻页**（page≥2）→ 始终走网络，不进缓存（分页数据无需缓存）。
- 缓存放在 `CallService`（单例 provider），**不依赖页面存活**，确保「退出再进入」能命中。

### 目标 2：TM/TA 卡片显示「拨打人：xx」
- 仅当当前用户角色为 **tenant_manager 或 tenant_admin**（即 TM / TA）时，在卡片**拨打时间同一行、时间之后**追加 `· 拨打人：<姓名>`。
- TE（普通电销）不显示——其通话均为本人拨打，无区分意义。
- 姓名来源：`record.userId` → `optionsCacheService.getUserName(userId)` 映射（未命中时该函数兜底返回原始 id，与全站一致）。
- 颜色/圆点：按需求仅加文字，**不额外加彩色圆点**（保持与需求严格一致）。

## 3. 文件改动明细

| 文件 | 改动 |
|---|---|
| `lib/services/call_service.dart` | `fetchMyCalls` 增加 `bool force=false` 参数；新增首页缓存（私有 `_cache`/`_cacheKey`/`_cacheTime` + `_buildKey`/`_isCacheValid`/`_getCache`/`_putCache`）；公开 `peekCache(q, answerType)` 供页面在发请求前同步判断缓存是否有效（避免骨架闪烁）。TTL 常量 `callListCacheTtl = 300`。 |
| `lib/pages/call_records/call_records_page.dart` | ① 引入 `authProvider`、`optionsCacheProvider`；② `initState` 读取当前角色写入 `_showCaller`（`_isTeamManager(role)` 兼容两套写法）；③ `_loadInitial({bool force=false})`：先 `peekCache` 命中则直接 setState 套用并 `return`（不进 `_isFetching` 锁、不显示骨架），未命中再走原网络流程并透传 `force`；④ 网络/缓存套用后统一调用 `_resolveCallers()` 解析拨打人姓名到 `_callerNames` map；⑤ 行渲染 `CallRecordRow(record: r, onTap: ..., callerName: _showCaller ? _callerNames[r.userId] : null)`；⑥ `_onRefresh` 调 `_loadInitial(force:true)`。 |
| `lib/pages/call_records/widgets/call_record_row.dart` | `CallRecordRow` 增加 `final String? callerName;`；第二行 `Text.rich` 在时间 span 之后，若 `callerName` 非空则追加 `· 拨打人：<姓名>`（"拨打人：" 用次要灰、姓名用近黑色，与时间同处一行）。 |
| `lib/widgets/lead_card.dart`（不改） | 仅参考其 `showOwner` + `_buildOwnerRow` 的 TM/TA 判定范式，不在本计划改动范围。 |

> 说明：不新增独立的「拨打人映射」缓存——直接复用 `OptionsCacheService` 已有的 `getUserName`（10h 双缓存），避免重复造轮子。5 分钟缓存仅针对「通话列表首页」这一请求本身。

## 4. 关键实现要点

### 4.1 CallService 缓存（服务层、随 App 存活）
```dart
static const int callListCacheTtl = 300; // 5 分钟

({List<CallRecord> items, int total, int pages})? _cache;
String? _cacheKey;
DateTime? _cacheTime;

String _buildKey(String? q, String? answerType) =>
    '${q ?? ''}|${answerType ?? ''}';

bool _isCacheValid(String key) =>
    _cache != null &&
    _cacheKey == key &&
    _cacheTime != null &&
    DateTime.now().difference(_cacheTime!).inSeconds < callListCacheTtl;

/// 供页面在发请求前同步判断是否命中（避免骨架闪烁）
({List<CallRecord> items, int total, int pages})? peekCache(String? q, String? answerType) =>
    _isCacheValid(_buildKey(q, answerType)) ? _cache : null;
```
`fetchMyCalls` 内：`page==1 && !force` 时先 `peekCache` 命中即返回；网络成功后仅 `page==1` 写入 `_putCache`。

### 4.2 角色判定（真实值）
```dart
bool _isTeamManager(String? role) {
  if (role == null || role.isEmpty) return false;
  // 真实取值为 tenant_manager / tenant_admin（TM / TA 为用户简称）
  return role == 'tenant_manager' || role == 'tenant_admin';
}
```

### 4.3 拨打人解析（页面层）
```dart
Future<void> _resolveCallers() async {
  if (!_showCaller) return;
  final svc = ref.read(optionsCacheProvider);
  final names = <String, String>{};
  final ids = _items.map((e) => e.userId).where((id) => id.isNotEmpty).toSet();
  for (final id in ids) {
    final name = await svc.getUserName(id); // 已预热则无网络
    if (name != null && name.isNotEmpty) names[id] = name;
  }
  if (!mounted) return;
  setState(() => _callerNames = names);
}
```

## 5. 验证

1. `flutter analyze` 全量 0 issue。
2. release + `DEV_TOOLS=true` 构建 APK，装 Redmi K60。
3. **真机实测（需你确认）**：
   - 进入通话记录 → Alice 浮标确认**发了 1 次** `/api/tenant/calls`；
   - 退出页面再进入（5 分钟内、同筛选）→ Alice 确认**不再发** calls 请求，列表秒出；
   - 下拉刷新 → 确认又发了 1 次（force 生效），且缓存时间刷新；
   - 超过 5 分钟后再进入 → 重新发请求；
   - 用 **tenant_manager / tenant_admin 账号**进入 → 卡片时间行后出现 `· 拨打人：<姓名>`；用 **TE 账号**进入 → 不显示拨打人；
   - 切换接听类型筛选 → 正常重新请求并渲染；翻页正常。

## 6. 备注 / 待确认
- 下拉刷新强制绕过缓存（取最新）是常规行为，已按此实现；如你希望「刷新也走缓存」请告知。
- 拨打人显示为纯文字、不加彩色圆点（严格按需求）；如需像归属人那样配色可后续追加。
