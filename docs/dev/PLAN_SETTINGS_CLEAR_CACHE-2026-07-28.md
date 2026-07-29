# 计划：设置页新增「清除缓存」功能

**日期**：2026-07-28
**提出**：用户（设置页新增「清除缓存」菜单，清除本地全部接口数据后跳登录页重新登录）

## 一、需求

设置页新增菜单「清除缓存」，点击后：
- 清除本机所有接口缓存数据（含登录凭据）
- 清除完成后跳转到登录页，让用户重新登录

## 二、决策点（已与用户确认）

1. **纯本地清除**：不调后端 `/api/auth/logout` 接口，不吊销后端会话、不影响其他设备。
   重新登录即获新 token。更符合「清除缓存」字面语义。
2. **保留账号预填**：不清 `LocalStorageService` 的 `saved_login_email` / `saved_login_password`
   及复选框状态，下次登录仍可自动填充。

## 三、清除范围

| 层级 | 方法 | 说明 |
|------|------|------|
| 登录凭据 | `tokenStorage.clearAll()` | access/refresh token、userId、name、email、role |
| 用户私有缓存 | `CacheCoordinator._clearUserPrivate()` | leads/schedules/通话/个人统计/详情 invalidate |
| 租户共享 options | `optionsCacheProvider.clearAll()` | 内存 + 磁盘 |
| 租户 profile/settings | `tenantServiceProvider.clearAll()` | 内存 + 磁盘 |
| 首页状态 | `homePageProvider.reset()` | 停轮询 + 清状态 |
| 团队聚合统计 | `teamStatsProvider` invalidate | 随 tenant 清理 |

> 不调 `authService.logout()`（不吊销后端 token）；不清 `LocalStorageService`（保留账号预填）。

## 四、实现

### 1. `CacheCoordinator.clearAllData()`（集中清除）

```dart
/// 清除所有本地缓存数据（含租户共享），用于「清除缓存」功能。
/// 与 onLogout 区别：额外清 options / tenant profile / home / team 聚合。
Future<void> clearAllData() async {
  _clearUserPrivate();
  await _ref.read(optionsCacheProvider).clearAll();
  await _ref.read(tenantServiceProvider).clearAll();
  _ref.read(homePageProvider).reset();
  _ref.invalidate(teamStatsProvider);
}
```
需 import `home_provider` 与 `tenant_service_provider`。

### 2. `AuthNotifier.clearLocalCache()`

```dart
/// 清除本地所有缓存数据（含登录凭据）并跳登录页重新登录。
/// 与 logout() 区别：清所有本地数据（含租户共享），且不调后端登出接口；
/// 保留 LocalStorageService 的登录预填。
Future<void> clearLocalCache() async {
  await _ref.read(tokenStorageProvider).clearAll();
  await _ref.read(cacheCoordinatorProvider).clearAllData();
  state = const AuthState(status: AuthStatus.unauthenticated);
}
```

### 3. `settings_page.dart` 新增菜单

「账户操作」区新增「清除缓存」ListTile（`Icons.cleaning_services`）：
```dart
ListTile(
  leading: const Icon(Icons.cleaning_services, size: 22),
  title: const Text('清除缓存'),
  enabled: !_clearing,
  onTap: _clearing ? null : _onClearCache,
  trailing: _clearing ? const CircularProgressIndicator(strokeWidth: 2.5) : null,
),
```
`_onClearCache()`：`AppDialog.confirm` 二次确认 → `await ref.read(authProvider.notifier).clearLocalCache()` → `Navigator.popUntil((route) => route.isFirst)`（AuthGate 监听 unauthenticated 自动跳登录页）。

## 五、验证（真机）

1. 设置页点「清除缓存」→ 二次确认框出现
2. 确认后：本地缓存清空，跳转到登录页
3. 登录页：邮箱/密码预填仍在（保留账号预填），重新登录成功
4. 登录后首页正常加载（options/profile 重新拉取，无旧数据残留）
5. 其他设备登录态不受影响（纯本地清除）

## 六、改动文件

- `lib/providers/cache_coordinator.dart`（加 clearAllData + import）
- `lib/providers/auth_provider.dart`（加 clearLocalCache）
- `lib/pages/settings/settings_page.dart`（加菜单 + 方法 + 状态变量）
