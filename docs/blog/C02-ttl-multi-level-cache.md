# C02 · Flutter 带 TTL 的多级缓存设计模式，Options+服务层缓存实战，各位同学记得收藏哦！

> 作者：FungLeo ｜ 适用：Flutter / Dart（思路可迁移到任意端）
> 目标：让"几乎不变的字典数据"和"列表首屏"少发一半以上的请求，同时保证数据还能更新。

### 前言

先说个我自己都觉得有点丢人的观察。

前段时间我拿抓包工具看了一下自己项目的请求，发现一个很尴尬的事实：**用户每切一次页面，我就要重新拉一遍下拉选项**。分类、状态、归属人这些字典数据，一天到晚也不见得变一次，我却老老实实每次进页面都去问服务端一遍"这些选项是啥"。

页面进得越勤，请求发得越欢。用户看到的就是每次进列表页都要先转个圈，体验很一般。

一开始我想的很简单：那我加个变量存起来不就完了？结果很快被现实打脸——**内存缓存重开 App 就没了**，冷启动第一次进页面照样转圈；后来又加了本地持久化，结果走向另一个极端：**数据永远不刷新**，服务端改了一个选项名，客户端半个月还显示老的。

来回折腾了几轮，最后沉淀出一套还算好用的模式：**内存 + 磁盘 + TTL 三层结构**。这篇就把它完整写出来，各位看官可以直接抄到自己项目里。

### 先想清楚：缓存到底要解决几个问题

在贴代码之前，我想先把需求拆清楚。说实话，缓存这东西写起来不难，难的是想清楚边界。一个能用的缓存方案，至少要同时回答四个问题：

1. **命中怎么办** —— 有数据就直接用，一个包都别发；
2. **没命中怎么办** —— 降级到下一层，最后才走网络；
3. **过期怎么办** —— 得有个时间概念，不能永远吃老本；
4. **要强制更新怎么办** —— 用户下拉刷新的时候，缓存得给我让路。

只解决第 1 个问题的，那叫"变量存了一下"，算不上缓存方案。四个问题都答上了，才是能长期跑在生产里的东西。

好啦，思路理清楚了，开干。

### 模式一：Options 缓存（内存 + 磁盘 + TTL）

这个模式适合那些**变化频率极低、但到处都要用**的字典数据。

```dart
class OptionsCacheService {
  // 第一层：内存缓存，进程内最快
  List<OptionItem>? _categories;
  List<OptionItem>? _users;
  DateTime? _lastFetchTime;

  // TTL：这里给 10 小时（36000 秒），按数据变化频率自己定
  static const int ttlSeconds = 36000;

  bool get _isValid =>
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!).inSeconds < ttlSeconds;

  /// 对外暴露：按 id 取名称
  /// 命中内存或磁盘就直接返回，过期了才会真的发请求
  Future<String> getCategoryName(String id) async {
    await _ensureLoaded();
    // 注意 orElse：查不到就回退显示 id，别让它抛异常
    final hit = _categories?.firstWhere(
      (e) => e.id == id,
      orElse: () => OptionItem(id: id, name: id),
    );
    return hit?.name ?? id;
  }

  /// 三层降级的核心逻辑
  Future<void> _ensureLoaded() async {
    if (_isValid && _categories != null) return;  // 1. 内存命中，直接走人
    if (await _loadFromLocal()) return;           // 2. 磁盘命中（含时间戳校验）
    await _refreshFromApi();                      // 3. 都没有，才走网络
    await _saveToLocal();                         // 4. 回写磁盘，下次冷启动能用
    _lastFetchTime = DateTime.now();
  }

  /// 手动强制刷新：绕过所有缓存
  Future<void> refresh() async {
    await _refreshFromApi();
    await _saveToLocal();
    _lastFetchTime = DateTime.now();
  }
}
```

#### 这里面有几个点特别容易写错

**第一，磁盘持久化一定要连时间戳一起存。**

这是我当初翻车最狠的地方。我最早只把数据本身写进了本地存储，时间戳留在内存里。结果 App 一重启，内存里的 `_lastFetchTime` 归零，磁盘里的数据却还在——于是 `_loadFromLocal()` 每次都命中，TTL 形同虚设，**数据永远不刷新**。

所以磁盘里存的应该是这么个结构：

```json
{
  "fetchedAt": 1717029000000,
  "categories": [
    { "id": "1", "name": "选项 A" },
    { "id": "2", "name": "选项 B" }
  ]
}
```

`_loadFromLocal()` 读出来之后，得先拿 `fetchedAt` 和 TTL 比一比，过期了就当没读到，老老实实返回 `false` 去走网络。

**第二，三层的顺序不能乱：内存 → 磁盘 → 网络。**

内存最快但活不过进程；磁盘慢一点但能扛冷启动；网络最慢但数据最新。按这个顺序降级，才能做到"绝大多数情况下零请求，冷启动一次请求，过期一次请求"。

**第三，`firstWhere` 记得带 `orElse`。**

Dart 的 `firstWhere` 查不到会直接抛 `StateError`。字典数据这种东西，服务端删掉一个选项、而客户端还缓存着旧数据引用的场景太常见了。带上 `orElse` 回退成显示 id，页面顶多丑一点，总比整个列表崩了强，对吧。

### 模式二：服务层首屏缓存 + peekCache

字典数据搞定了，那列表本身呢？

列表数据当然不能像字典那样缓存 10 小时，但"用户刚从详情页返回列表"这种场景，重新请求一遍确实没必要。所以我给列表服务也加了一层短 TTL 的首屏缓存。

```dart
class SomeService {
  List<ItemModel>? _cache;
  String? _cacheKey;
  DateTime? _cacheTime;

  static const int ttl = 300; // 列表数据变化快，5 分钟足够了

  bool _isCacheValid(String key) =>
      _cacheKey == key &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!).inSeconds < ttl;

  /// 引用安全的 peek：命中就返回数据，不命中返回 null
  /// 关键是它绝不触发请求，纯查询
  List<ItemModel>? peekCache(String key) =>
      _isCacheValid(key) ? _cache : null;

  Future<PageResult> fetch({
    required int page,
    required String key,     // 缓存维度，见下面的说明
    bool force = false,      // 下拉刷新时传 true，绕过缓存
  }) async {
    // 只缓存第一页；force 时直接跳过缓存判定
    if (page == 1 && !force && _isCacheValid(key)) {
      return PageResult(items: _cache!, total: _cache!.length);
    }

    final r = await _api(page);

    if (page == 1) {
      _cache = r.items;
      _cacheKey = key;               // ← 存的是本次请求的 key，别写成 _cacheKey = _cacheKey
      _cacheTime = DateTime.now();
    }
    return r;
  }
}
```

#### 几个设计上的讲究

**缓存判定要放在"请求守卫"前面。**

很多人的列表服务里都有个 `_isLoading` 之类的守卫变量，防止重复请求。如果你把缓存判定写在守卫后面，就会出现"明明有缓存，却因为守卫拦截而什么都没返回"的尴尬情况。正确的顺序是：**先查缓存 → 命中就返回 → 没命中再进守卫逻辑 → 最后才发请求**。

顺带一提，"首屏 loading 标志"和"请求守卫"最好用两个不同的变量，混用一个会引出另一串列表页的怪现象，这个坑在 [D 系列](./00-内容规划.md) 里有专门的篇幅聊。

**`peekCache` 为什么要单独存在？**

因为它把"要不要发请求"的决定权交还给了调用方。页面可以这么用：

```dart
// 进页面先 peek 一把，有缓存就先把界面画出来，用户不用看骨架屏
final cached = service.peekCache(currentKey);
if (cached != null) {
  setState(() => items = cached);
}
// 然后再决定要不要静默拉一次新数据
```

这就是所谓的 **stale-while-revalidate**：先拿旧数据把界面填满，后台再悄悄更新。用户感知到的就是"秒开"。如果 `peekCache` 自己会触发请求，这个模式就玩不起来了。

**缓存 key 一定要带维度。**

这条是血的教训。`_cacheKey` 里除了筛选条件，还应该带上用户标识、租户标识这类维度。否则 A 账号退出、B 账号登录，一进列表页看到的还是 A 的数据——这已经不是体验问题了，是事故。相关的隔离约定可以看 [G01](G01-style-guide-hard-rules.md)。

另外提醒一句，**退出登录的时候记得把这些缓存清干净**，包括内存里的和磁盘里的。缓存服务最好统一提供一个 `clear()` 方法，登出流程里挨个调一遍。

### TTL 该设多长？我的经验值

这个没有标准答案，我一般按"数据能容忍多久不更新"来倒推：

| 数据类型 | 建议 TTL | 说明 |
|---------|---------|------|
| 字典 / 枚举 / 分类选项 | 数小时 ~ 一天 | 基本不变，配合手动 refresh 兜底 |
| 用户信息 / 权限配置 | 十几分钟 ~ 半小时 | 变了要相对及时地反映出来 |
| 列表首屏 | 几分钟 | 主要是解决"页面来回切"的重复请求 |
| 实时性数据（余额、状态） | 不缓存 | 缓存的收益远小于显示错数据的代价 |

一般而言，**够用就好，没必要太折腾**。TTL 设得再精妙，也不如给用户留一个下拉刷新的口子来得实在。

### 小结

好啦，两个模式都讲完了。

回头看，这套东西的核心其实就一句话：**用内存扛住高频访问，用磁盘扛住冷启动，用 TTL 扛住数据陈旧，用 force 参数把最终决定权还给用户。** 四层加起来，才是一个跑得住的缓存方案。

再把几个容易翻车的点强调一遍：

1. **磁盘缓存必须连时间戳一起存**，否则 TTL 等于没写；
2. **缓存 key 带上用户/租户维度**，防止切账号串数据；
3. **`peekCache` 只查不发**，把 stale-while-revalidate 的能力留给页面；
4. **登出时统一清缓存**，内存和磁盘都别落下。

那么各位看官，您在项目里是怎么做缓存的呢？有没有更省事的封装方式？欢迎在评论区交流一下。如果这篇文章对你有点用，麻烦点个赞收个藏哈，谢谢大家！

---

*上一篇：[C01 build 期改 provider 崩溃](C01-riverpod-build-provider-crash.md) ｜ 下一篇：[C03 401 刷新死锁](C03-401-refresh-deadlock.md)*

> 本文由 FungLeo 主导，Deepseek 优化校阅，转发请注明首发地址，谢谢大家！
