# 修复：清除缓存后重新登录列表卡骨架屏（401 刷新拦截器死锁）

> 日期：2026-07-28 | 关联节点：v0.38 之后补丁 | 状态：已构建装真机待实测

## 现象

设置页「清除缓存」→ 跳登录页 → 直接重新登录（**不杀 App**）→ 进线索列表**一直骨架屏**，
下拉刷新也不行；**杀掉 App 重开** → 重新登录 → 列表正常。稳定复现。

## 根因

### 1. `api_client.dart` 401 自动刷新拦截器存在队列死锁

`_refreshAndRetry` 处理并发 401：
- 第一个请求进入刷新流程，`_isRefreshing = true`；
- 其余并发 401 请求被塞进 `_refreshQueue` 并 `return completer.future`（挂起等待刷新完成）。

刷新流程中：

```dart
final refreshToken = await _tokenStorage.getRefreshToken();
if (refreshToken == null) return null;     // ← 提前返回
...
} finally {
  _isRefreshing = false;                   // ← finally 只复位 _isRefreshing
}                                           // ❌ _refreshQueue 里的请求从未 complete
```

`refreshToken == null`（清除缓存瞬间 token 已空）提前 return 时，`finally` 只把
`_isRefreshing` 复位，**没有清空 `_refreshQueue`** → 队列里那些请求
（含 `options.getCategories`）的 `completer.future` 永不 resolve。

### 2. 死锁跨「清除缓存 → 重新登录」存活，且波及 options 缓存

- `apiClient` 是单例 Provider，清除缓存时**未重建**，其 `_isRefreshing` / `_refreshQueue`
  是实例级脏状态，跨重新登录全程存活。
- 清除缓存那一刻，`cacheCoordinator.clearAllData()` 调 `invalidate(leadListProvider)`
  触发后台 `_loadInitial`，此时 token 已空 → `fetchLeads` + 3 个 options 请求**几乎同时 401**
  → 并发进入 `_refreshAndRetry` → 第一个 `refreshToken == null` 返回、队列未清 → 死锁。
- 该死锁让 `optionsCacheService._loadingFuture` 永久挂起（`Future.wait` 永不返回）。
  `_loadingFuture` 同样是 `optionsCacheService` 实例级状态，跨 `leadListProvider` 重建存活
  → 重新登录后新建的 `_loadInitial` 调 `_loadOptions()` 仍复用这个永不完成的 future
  → 列表骨架屏一直卡、下拉刷新也不行。

### 3. 为什么「杀 App 重开」正常

杀 App 重建整个 `apiClient`（`_isRefreshing=false`、队列空、`_loadingFuture=null`）
→ 全新状态 → 正常。这是定位的关键线索：**不杀 App 复用脏实例 = 卡；重建 = 正常**。

## 修复方案（双保险）

### 修复 A（治本，任何并发 401 + refreshToken 缺失场景都受益）

`api_client.dart` 的 `_refreshAndRetry` 在 `finally` 里兜底清空 `_refreshQueue`
并 complete 所有 completer 为 null：

```dart
} finally {
  _isRefreshing = false;
  // 兜底：任何提前 return（如 refreshToken 缺失）都不应让队列请求永久挂起，
  // 否则会拖死依赖该 future 的 options 缓存加载，表现为列表长期骨架屏。
  for (final pending in _refreshQueue) {
    pending.completer.complete(null);
  }
  _refreshQueue.clear();
}
```

### 修复 B（对齐「杀 App 正常」）

`auth_provider.dart` 的 `clearLocalCache` 末尾 `invalidate(apiClientProvider)`，
让 `apiClient` 及其派生 service（tenantService / optionsCacheService / leadService 等）
重建，彻底清除 `_isRefreshing` / `_refreshQueue` / `options._loadingFuture` 等
跨清除缓存存活的脏状态——等价于「杀 App 重开」效果：

```dart
Future<void> clearLocalCache() async {
  final tokenStorage = _ref.read(tokenStorageProvider);
  await tokenStorage.clearAll();
  await _ref.read(cacheCoordinatorProvider).clearAllData();
  state = const AuthState(status: AuthStatus.unauthenticated);
  // 重建 API 层：清除 _isRefreshing / 刷新队列 / options._loadingFuture 等
  // 跨清除缓存存活的脏状态，等价于「杀 App 重开」，避免重新登录后列表卡骨架屏。
  _ref.invalidate(apiClientProvider);
}
```

> 注：`invalidate(apiClientProvider)` 会级联重建依赖它的 service 与 `authProvider`，
> 重建的 `AuthNotifier._tryAutoLogin()` 读空 token → `unauthenticated`，与当前目标态一致，安全。

## 验证清单

1. 设置页「清除缓存」→ 跳登录页
2. **不杀 App** 直接重新登录 → 进「我的线索」→ 列表**正常加载**（不再骨架屏）
3. 下拉刷新正常
4. 杀 App 重开重新登录仍正常（回归）
5. Alice 抓包：重新登录后列表/options 请求正常返回，无挂起请求
