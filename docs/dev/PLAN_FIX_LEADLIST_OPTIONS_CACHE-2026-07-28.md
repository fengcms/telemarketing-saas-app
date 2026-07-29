# 计划：线索列表下拉刷新不再请求 options 接口

**日期**：2026-07-28
**提出**：用户（App 测试中发现线索列表下拉刷新同时请求 options 各接口）

## 一、现象

在「我的线索」列表页下拉刷新时，除了 `GET /api/tenant/leads` 列表接口外，
还同时请求了 `options/categories`、`options/projects`、`options/users` 三个接口。
这些接口本应被 10 小时缓存覆盖，不应在每次刷新时重复请求。

## 二、根因

`lib/providers/lead_list_provider.dart` 的 `_loadOptions()` 走的是 `LeadService`
的无缓存方法：

```dart
// 当前（有问题）
Future<void> _loadOptions(LeadService service) async {
  final results = await Future.wait([
    service.fetchCategories(),   // LeadService ⇒ 直接 dio.get，无缓存
    service.fetchProjects(),
    service.fetchUsers(),
  ]);
  state = state.copyWith(categories: cats, projects: projs, users: users);
}
```

而 `LeadService.fetchCategories/fetchProjects/fetchUsers` 经 `_fetchOptions`
**直接打 API**，没有 TTL、没有内存/磁盘缓存、没有并发去重。

全仓其他位置（跟进面板、日程表单、编辑线索、卡片渲染）早已改用带 10h
缓存的 `optionsCacheProvider`（`OptionsCacheService.getCategories/getProjects/
getUsers`），内存有效时零请求。`_loadOptions` 是历史遗留的旁路——当初修
「筛选抽屉项目不刷新」时为图省事直接用了 `LeadService.fetch*`，埋下每次刷新
都发 options 请求的坑。

## 三、修复方案

`_loadOptions` 改走 `optionsCacheProvider`（与全仓一致）：

```dart
Future<void> _loadOptions() async {
  try {
    final cache = _ref.read(optionsCacheProvider);
    final results = await Future.wait([
      cache.getCategories(),
      cache.getProjects(),
      cache.getUsers(),
    ]);
    if (mounted) {
      state = state.copyWith(
        categories: results[0],
        projects: results[1],
        users: results[2],
      );
    }
  } catch (_) {}
}
```

`_loadInitial()` / `refresh()` 调用处去掉 `service` 参数即可。

## 四、影响与兼容性

- **缓存有效（10h 内）**：`getCategories()` 等直接返回内存/磁盘缓存，**不发请求**，
  state 仍被填充，筛选抽屉照常工作。
- **缓存过期**：仅自动发 1 批请求（并发去重，全仓共享同一 Future）。
- **「更新公司数据」按钮**：仍调 `optionsCacheProvider.refresh()` 强制刷新缓存，
  之后列表抽屉拿到最新选项——原修复诉求仍满足，不破坏。

## 五、验证（真机 + Alice 抓包）

1. 冷启动后首次进「我的线索」：options 三个接口发 **1 批**（缓存预热），之后 10h 内不再发。
2. 列表页下拉刷新：Alice 中**只看到 `leads` 一个请求**，options 三个接口不再出现。
3. 打开筛选抽屉：分类/项目/归属人选项正常显示（来自缓存）。
4. 点「更新公司数据」后，筛选抽屉选项更新为最新。

## 六、改动文件

- `lib/providers/lead_list_provider.dart`（改 `_loadOptions` 签名与实现、更新 2 处调用、加 import）
