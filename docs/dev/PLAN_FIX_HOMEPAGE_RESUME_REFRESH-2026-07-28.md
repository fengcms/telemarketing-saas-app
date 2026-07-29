# 修复：首页 resume 时无条件请求 home-summary / stats/mine

> 日期：2026-07-28
> 关联：用户在 Alice 抓包发现，每次 App 退回桌面再回到前台（如线索详情拨号返回），都会请求
> `GET /api/tenant/schedules/home-summary` 与 `GET /api/tenant/stats/mine`，即使当时根本不在首页。

## 一、问题现象

- 任何「App 进入后台 → 回到前台」的操作（含线索详情拨号、下拉通知栏、截图等瞬时切换），
  都会触发首页的 `home-summary` + `stats/mine` 两个并发请求。
- 在「线索详情」拨号返回这种用户明显不在首页的场景，请求照发，纯属浪费流量 / 电量。

## 二、根因分析

1. **首页是常驻页面**：`MainShell` 用 `IndexedStack` 装载 4 个底部 Tab，`HomePage`（Tab 0）
   始终挂载、永不 dispose。无论切到哪个 Tab 或 push 进线索详情，`HomePage` 的 `State` 一直存活。
2. **全局生命周期监听**：`home_page.dart:51` 在 `initState` 注册 `WidgetsBinding` observer，
   `didChangeAppLifecycleState`（resumed/paused）是**全局回调**——只要 App 前后台切换就触发，
   与当前所在页面无关。
3. **resumed 无条件刷新**：`home_provider.onResume()` 直接 `_silentRefresh()`，并发请求
   `stats/mine` + `home-summary`。代码里虽有「检查是否距上次更新超过 10 分钟」的注释，但**从未实现**，
   实际是无条件刷新。

## 三、修复方案

### 1. 按 Tab 可见性门控（核心）
`home_page.dart` 的 `didChangeAppLifecycleState` 在 `resumed` 时，仅当
`ref.read(currentTabProvider) == 0`（首页是当前 Tab）才调用 `onResume()`。
`paused` 分支保持全局 `onPause()`（暂停轮询与当前 Tab 无关，无害）。

### 2. 补上缺失的节流
`HomePageNotifier` 增加 `_lastSilentRefreshAt` 字段；`loadData()` 与 `_silentRefresh()`
发起时记录时间戳。`onResume()` 中若距上次静默刷新 `< 60 秒` 则跳过网络请求——
杜绝瞬时前后台切换（拨号 / 截图 / 下拉通知栏）反复拉取。轮询（10 分钟）自然不受此限。

### 3. 切回首页 Tab 时主动刷新
在 `HomePage.build` 用 `ref.listen(currentTabProvider, …)`：当用户从别的 Tab **切回首页**
（`next == 0`）时主动 `onResume()`，承接原先依赖全局 `resumed` 的那次刷新，保证首页数据新鲜。

### 4. 抽取 `currentTabProvider`（消除循环依赖）
`currentTabProvider` 原定义在 `main_shell.dart`，`HomePage` 需读取它。为避免
`home_page.dart ⇄ main_shell.dart` 循环 import，将其抽到独立文件
`lib/providers/tab_provider.dart`，两处均 import 新文件。

### 5. 顺带修正 options 缓存注释
`options_cache_service.dart` 两处注释写「默认 1800 秒/30 分钟」，但实际
`ApiConstants.optionsCacheTTL = 36000`（10 小时，用户本意即 10 小时），统一改为「36000 秒/10 小时」。

## 四、改动文件清单

| 文件 | 改动 |
|------|------|
| `lib/providers/tab_provider.dart` | 新建，定义 `currentTabProvider` |
| `lib/pages/main_shell.dart` | 删除本地 `currentTabProvider` 定义，改 import `tab_provider.dart` |
| `lib/pages/home/home_page.dart` | 加 import；`didChangeAppLifecycleState` 门控；`build` 内 `ref.listen` 切回刷新 |
| `lib/providers/home_provider.dart` | 加 `_lastSilentRefreshAt`；`loadData`/`_silentRefresh` 记时间；`onResume` 节流 |
| `lib/services/options_cache_service.dart` | 修正 2 处 TTL 注释为 10 小时 |

## 五、预期效果与验证

- **首页且真回前台**：仍刷新（门控通过 + 节流允许时）。
- **别的 Tab / 线索详情拨号返回**：`currentTabProvider != 0` → 不发这两个请求 ✅。
- **切回首页 Tab**：`ref.listen(next==0)` → 正常刷新 ✅。
- **瞬时切换（<60s）**：节流跳过，不再重复拉取 ✅。
- 真机 Alice 验证：线索详情拨号返回 → 不再出现 `home-summary` / `stats/mine` 请求；
  切回首页 Tab → 出现一次。
