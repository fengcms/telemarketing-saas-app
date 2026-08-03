# D04 · Flutter 吸顶分组列表 + 点击头平滑滚动，语义桶分组算法实战，必看！

> 作者：FungLeo ｜ 适用：Flutter 3.x
> 场景：时间类列表要"按语义分组 + 组头吸顶 + 点组头跳到那一组"，看着简单，细节全是坑。

### 前言

时间类的列表，各位看官肯定都做过——待办、日程、消息、订单，凡是带时间的，产品迟早会提一句："能不能按时间分个组？"

我接到这个需求的时候心想，这有啥难的。按日期排个序，遍历一遍，日期变了就插个头，半小时的事儿。

结果第一版跑出来，界面上出现了两个"本周"。

我盯着看了半天才反应过来：我是按 `YYYY-MM-DD` 切的，同一个自然周里有周三和周五两条数据，那自然就切出来两组，标题一算又都是"本周"，可不就重复了么。这个 bug 一出，整个列表看着就特别不专业。

后来我把分组逻辑整个推翻重写，改成**语义桶**，才算真正对了。这篇就把这套东西完整记一下：怎么分桶、吸顶头怎么做才是真吸顶、点组头怎么平滑滚过去。

### 一、别按天切，要按「语义桶」切

#### 我原来错在哪

先看我第一版的错误思路：

```dart
// ❌ 按日期字符串分组，同一周会切出好几组
final key = '${t.year}-${t.month}-${t.day}';
```

问题在于，**用户脑子里的分组，和日历上的分组，压根不是一回事**。

用户想看到的是"今天有几件事、明天有几件事、这周剩下的有几件事"，是个**语义**上的划分。而按天切，切出来的是物理日期，一周能给你切出七组，标题还全叫"本周"。

#### 正确姿势：先定桶，再往桶里扔

思路反过来：**先把桶定死，每个桶全局只有一个头，然后把每条数据算一下该扔进哪个桶。**

比如一个"待办 / 已完成"两个 Tab 的列表，桶可以这么定（从上到下）：

```
待办（未来方向）：
  已逾期 / 今天 / 明天 / 后天 / 本周 / 下周 / 更晚

已完成（过去方向，镜像过来）：
  今天 / 昨天 / 本周 / 上周 / 更早
```

这么一来，**"本周"永远只有一个头**，多少条数据都往它里面塞，重复头的问题从根上没了。

#### 三个函数搞定

具体实现我拆成三个纯函数，好写好测：

```dart
/// 1. 算这条数据属于哪个桶（只判断"哪一类"，不关心具体日期）
String _bucketKey(DateTime time, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(time.year, time.month, time.day);
  final diff = target.difference(today).inDays;

  if (diff < 0) return 'overdue';    // 比今天早，逾期
  if (diff == 0) return 'today';
  if (diff == 1) return 'tomorrow';
  if (diff == 2) return 'day_after';
  // weekday: 周一=1 ... 周日=7，所以本周还剩 (7 - weekday) 天
  if (diff <= 7 - today.weekday) return 'this_week';
  if (diff <= 14 - today.weekday) return 'next_week';
  return 'later';
}

/// 2. 给桶排序权重，数字小的排前面
const _bucketOrder = <String, int>{
  'overdue': 0,
  'today': 1,
  'tomorrow': 2,
  'day_after': 3,
  'this_week': 4,
  'next_week': 5,
  'later': 6,
};

/// 3. 桶的中文标题
const _bucketTitle = <String, String>{
  'overdue': '已逾期',
  'today': '今天',
  'tomorrow': '明天',
  'day_after': '后天',
  'this_week': '本周',
  'next_week': '下周',
  'later': '更晚',
};
```

组装的时候就很轻松了：

```dart
List<GroupModel> _buildGroups(List<ItemModel> items, DateTime now) {
  final map = <String, List<ItemModel>>{};
  for (final it in items) {
    map.putIfAbsent(_bucketKey(it.time, now), () => []).add(it);
  }

  final groups = map.entries
      // 空桶自然就不在 map 里，不用额外过滤
      .map((e) => GroupModel(
            key: e.key,
            title: _bucketTitle[e.key]!,
            // 桶内按时间升序
            items: e.value..sort((a, b) => a.time.compareTo(b.time)),
          ))
      .toList();

  // 桶之间按权重排
  groups.sort((a, b) => _bucketOrder[a.key]!.compareTo(_bucketOrder[b.key]!));
  return groups;
}
```

几个小讲究：

- **空桶不渲染**。没数据的桶压根不进 map，界面上也就不会出现一个光秃秃的"下周"头下面啥也没有。
- **桶内升序，桶间按权重**。这两个排序是独立的，别混在一起写。
- **"已完成" Tab 就是把方向镜像一下**，把 `diff < 0` 那一侧展开成"昨天 / 本周 / 上周 / 更早"，逻辑完全对称，改个映射表的事儿。

### 二、吸顶头：怎么做才是"真吸顶"

这块我得多说两句，因为我看到过不少写法其实是**假吸顶**——头会跟着列表一起滚走。

#### 做法 A：真吸顶，`SliverMainAxisGroup` + `SliverPersistentHeader`

想让组头在滚到顶部时"钉住"，头本身就得是个 **Sliver**，而且要 `pinned: true`。同时还得让它"只在自己这一组的范围内钉住"，下一组上来的时候要被顶走——这就是 `SliverMainAxisGroup`（Flutter 3.16 之后可用）干的活儿：

```dart
CustomScrollView(
  controller: _scrollController,
  slivers: [
    for (final group in _groups)
      SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true, // 关键：钉住
            delegate: _GroupHeaderDelegate(
              title: group.title,
              onTap: () => _scrollToGroup(group.key),
            ),
          ),
          SliverList.builder(
            itemCount: group.items.length,
            itemBuilder: (ctx, i) => _buildCard(group.items[i]),
          ),
        ],
      ),
  ],
)
```

`_GroupHeaderDelegate` 要实现 `SliverPersistentHeaderDelegate`，最小实现长这样：

```dart
class _GroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  _GroupHeaderDelegate({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  double get minExtent => 36;
  @override
  double get maxExtent => 36; // 不需要伸缩，两个值给一样即可

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // 必须给不透明背景！否则吸顶时下面的内容会透上来，糊成一片
        color: Colors.white,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_up, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_GroupHeaderDelegate old) => old.title != title;
}
```

#### 做法 B：不强求吸顶，`Column` 塞进 `SliverList`

说实话，很多时候产品要的其实只是"有个分组头 + 能点"，并不是真的非要钉在顶上。那就没必要上 Sliver 那套了，直接把头和卡片拼成一个 `Column` 丢进 `SliverList` 就完事：

```dart
SliverList(
  delegate: SliverChildBuilderDelegate(
    (ctx, i) {
      final group = _groups[i];
      // 给每组第一张卡挂一个持久 key，下面滚动要用
      final firstCardKey = _groupKeys.putIfAbsent(group.key, GlobalKey.new);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GroupStickyHeader(
            title: group.title,
            onTap: () => _scrollToGroup(group.key),
          ),
          KeyedSubtree(
            key: firstCardKey,
            child: _buildCards(group.items),
          ),
        ],
      );
    },
    childCount: _groups.length,
  ),
)
```

**但要说清楚：这种写法组头是会跟着滚走的，不会钉在顶部。** 我一开始就是这么写的，还美滋滋地跟产品说"吸顶做好了"，结果人家一滚动就发现头没了，挺尴尬的哈。所以要真吸顶，老老实实走做法 A。

这里也有个取舍：做法 B 把一整组塞进一个 item 里，组内卡片是**一次性全建出来**的，失去了列表懒加载的优势。组内数据量大的时候（比如几百条），还是得拆开或者走做法 A。

### 三、点组头，平滑滚动到那一组

这个功能体验加分特别明显：列表拉得老长，点一下"下周"直接就跳过去了。

实现靠 `Scrollable.ensureVisible`，前提是你得**拿到目标位置的 `BuildContext`**——这就是上面那个 `GlobalKey` 的用途。

```dart
// 按 group.key 复用 GlobalKey，注意别在 build 里 new
final Map<String, GlobalKey> _groupKeys = {};

void _scrollToGroup(String groupKey) {
  final ctx = _groupKeys[groupKey]?.currentContext;
  if (ctx == null) return; // 还没挂载出来就别滚了

  Scrollable.ensureVisible(
    ctx,
    alignment: 0.08, // 停在距顶 8% 的位置，别死贴边
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
}
```

两个参数值得说一下：

- **`alignment: 0.08`**：`0` 是贴着顶部，`1` 是贴着底部。我试了下，正好贴顶的话组头会跟 AppBar 挤在一起，看着很局促，留 8% 的余量刚刚好。这个值各位看官按自己的顶部布局微调。
- **`duration` + `curve`**：不给 duration 就是瞬间跳过去，很生硬。300ms + `easeInOut` 是我觉得比较舒服的组合，再长就显得拖沓了。

**关于 `GlobalKey` 的两个注意事项**，这俩我都栽过：

1. **千万别在 `build` 方法里 `GlobalKey()` 新建**。每次 build 都换一个新 key，不仅 `currentContext` 抓不稳，还会让整棵子树被重建，滚动直接乱跳。用 `putIfAbsent` 按业务 key 缓存住，这是关键。
2. **key 用完要清理**。数据一刷新，某些桶可能就空了，但它的 key 还赖在 map 里。虽然一个 key 不占多少内存，但架不住反复刷新，还是顺手擦一下干净：

```dart
// 重建分组后，把已经不存在的桶对应的 key 清掉
_groupKeys.removeWhere((k, v) => !_groups.any((g) => g.key == k));
```

### 四、剩下几个细节，都是血泪

**1. "今天"是什么时候的今天？**

分桶依赖"当前时间"，那这个时间什么时候取、多久重算一次，是个真问题。

我的做法是：**只在下拉刷新、页面重建、Tab 切换这几个时机重算**，滚动过程中绝对不重算。原因很简单——你要是搞个定时器每分钟重算一遍，用户正好在跨零点那会儿滚列表，整个分组"啪"地重排，滚动位置直接飞了，体验极差。

宁可让用户看到几分钟的"旧分组"，也别让列表在他手底下自己蹦迪。

**2. 组头一定要给不透明背景**

上面代码注释里提了一嘴，这里再强调下。吸顶的时候组头是浮在内容上面的，你要是没给背景色（或者给了半透明），下面滚过去的卡片就会从字缝里透出来，糊成一坨灰，特别难看。

顺便，给组头底部加一条 1px 的分割线，吸顶时层次感会好很多。

**3. 组头别做太高**

吸顶头是常驻占屏的，做个 32~40 的高度就够了。我见过做到 60 多的，一屏的可用空间白白少一大块，不值当。

### 小结

好啦，吸顶分组列表这套东西就拆解完了。

回头看，这篇里技术含量最低但价值最高的，其实是第一节那个**「语义桶」**的思路转变——从"按数据的物理属性切"，转到"按用户的心理预期切"。这个转变一旦想通，重复头的 bug 根本不会发生。后面的吸顶、滚动，说白了都是查 API 的活儿。

四条经验：

1. 时间分组用**语义桶**，一类一个头，别按天切，否则同周必出重复头。
2. 要**真吸顶**就得用 `SliverMainAxisGroup` + `SliverPersistentHeader(pinned: true)`，`Column` 塞 `SliverList` 那是假吸顶。
3. 点头跳转靠**持久化的 `GlobalKey`** + `Scrollable.ensureVisible`，key 别在 build 里新建，用完记得清。
4. 跨天重算只在刷新/重建时做，滚动中重排是灾难。

最后，希望这篇文章能够对各位看官有所帮助。那么各位看官，您做分组列表的时候是自己撸 Sliver，还是直接上现成的 sticky header 库？有没有更省事的路子？欢迎在评论区交流。也请多多点赞收藏，谢谢大家！

---

*上一篇：[D03 布局坑](D03-layout-pitfalls.md) ｜ 下一篇：[D05 fl_chart 迁移](D05-fl-chart-migration.md)*

> 本文由 FungLeo 主导，Deepseek 优化校阅，转发请注明首发地址，谢谢大家！
