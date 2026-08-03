# B04 · Flutter 可复用公共组件库设计与落地，AppDialog/BottomSheet 等实战，必看！

> 作者：FungLeo ｜ 适用：Flutter 3.x / Material 3
> 目标：把"每个页面都长差不多"的那部分 UI 抽成一层薄封装，统一风格、统一质量。

### 前言

这是主题系列的最后一篇了，前面 [B01](B01-material3-theme-system.md) 讲主题四件套、[B02](B02-tdesign-to-m3-migration.md) 讲 UI 库迁移、[B03](B03-brand-colors-token.md) 讲颜色收口，这篇聊聊公共组件库。

先说说我为什么会去抽这个东西。

有一次做需求，我要在一个列表页上加个"确认删除"的弹窗。很简单对吧，我顺手就写了：

```dart
showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    title: const Text('确认'),
    content: const Text('确定删除？'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定')),
    ],
  ),
);
```

写完提交，测试同学过来说：这个弹窗跟隔壁那个页面的不一样啊。

我去看了一眼隔壁，好家伙——按钮顺序是反的（确定在左），文案是"是/否"，而且它用的是 `Navigator.of(context).pop()` 不带返回值，外面靠一个变量接。再翻第三个页面，那个的取消按钮居然是 `OutlinedButton`。

三个页面，三种弹窗。全都是我们自己人写的，而且每一个单独看都没毛病。

这就是[B03](B03-brand-colors-token.md) 里说的"风格漂移"，只不过 B03 漂的是颜色，这里漂的是交互。

说实话，这事儿怪不着谁。写业务的时候谁会专门去翻别的页面看弹窗长什么样呢？大家都是凭手感写的，手感自然各不相同。

所以解法还是那个：**别靠自觉，靠机制。**我们抽了一个 `lib/widgets/` 公共组件库，目前大概 20 个组件。这篇就讲讲怎么设计、怎么落地。

### 一、先别急着抽，先做分析

我想先泼一盆冷水：**抽组件之前，先搞清楚哪些东西真的值得抽。**

我见过一种很典型的过度设计：项目刚起步，先花两周搭一个"公共组件库"，把想象中会用到的组件都写一遍。结果做到后面发现，一半组件从来没被第二个页面用过，另一半因为当初没预料到实际需求，参数设计得完全不合适，用的时候还得改。

这就是典型的脱裤子放屁。

我的判断标准很土：**同样的 UI 出现第三次的时候，才考虑抽。**

- 出现一次：正常写。
- 出现两次：留意一下，可能是巧合。
- 出现三次：这就是模式了，抽。

按这个标准，我们动手前先跑了一轮扫描，把项目里重复的 UI 模式列出来：

```sh
# 看看有多少页面在自己拼搜索框
➜ grep -rln "TextField" lib/pages/ | wc -l

# 看看 showDialog 散落在多少处
➜ grep -rn "showDialog\|showModalBottomSheet" lib/ | wc -l

# 看看有多少处在手写"空态"
➜ grep -rn "暂无数据\|没有更多" lib/
```

跑完就有数了：搜索框 12 个页面各写各的、弹窗 20 多处、空态提示 15 处文案还不统一。这些就是该抽的。而某些我原以为"肯定要抽"的东西，实际只出现过一次，那就先放着。

**别盲目抽，先有分析报告。**这是我最想说的第一条。

### 二、组件清单（节选）

分析完，我们最终沉淀下来的组件大概是这些：

| 组件 | 用途 |
|------|------|
| `AppSearchBar` | 统一搜索栏（聚焦边框 + 透明底） |
| `AppFormSection` | 表单区块（标签 + 必填 * + 间距） |
| `AppActionBar` | 底部操作栏（单提交 / 多按钮） |
| `AppDialog` | 统一弹窗（`confirm` / `alert` 静态方法） |
| `AppBottomSheet` | 底部抽屉（拖拽手柄 + 居中标题 + 关闭） |
| `AppToast` | 全局轻提示 |
| `AppTextarea` | 多行输入（带字数计数浮层） |
| `AppErrorBody` / `AppEmptyBody` | 错误态 / 空态 |
| `AppFilterChips` | 横滚药丸筛选条 |
| `AppTag` / `AppInfoRow` | 状态标签 / 图标信息行 |
| `AppSegmentedTab` / `AppScopeToggle` | 分段 Tab / 二选一范围切换 |
| `AppListFooter` / `AppStickyHeader` | 加载更多 footer / 吸顶头 |

统一用 `App` 前缀，好处是打字的时候输入 `App` 就能唤起补全，一眼看到全部可用组件。这个小细节对新同学特别友好——他不需要读文档，IDE 会告诉他有什么。

### 三、设计原则

#### 1. 用 `abstract final class` + 静态方法，消灭样板

对于弹窗、Toast 这种"调一下就完事"的东西，我不建议做成 Widget，做成**静态方法**更顺手：

```dart
/// 统一弹窗入口。
/// abstract final 表示：既不能被继承，也不能被实例化，纯粹当命名空间用。
abstract final class AppDialog {
  /// 确认弹窗：一行调用拿到 bool 结果，没有 builder 样板
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String content,
    String cancelText = '取消',
    String confirmText = '确定',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    // 用户点遮罩关闭时 result 是 null，统一收敛成 false
    return result ?? false;
  }
}
```

业务页里就一行：

```dart
final ok = await AppDialog.confirm(
  context: context,
  title: '确认',
  content: '确定删除？',
);
if (ok) {
  // 执行删除
}
```

对比一下开头那十几行，清爽多了对吧。

这里有两个细节值得单独说说：

**一是 `return result ?? false` 这个兜底。**`showDialog` 返回的是可空类型，因为用户可能点遮罩或者按返回键关掉弹窗，这时候你的 `Navigator.pop(ctx, true/false)` 根本没执行，拿到的就是 `null`。

如果不收敛，调用方就得每次写 `if (ok == true)`。而人是会偷懒的，总有人写成 `if (ok)`——然后编译报错，再改成 `if (ok!)`，好了，用户点个遮罩就崩溃。把它收敛在组件内部，这类问题从源头上就不存在了。

**二是 `abstract final class` 这个写法。**这是 Dart 3 的类修饰符，含义是"这个类既不能被继承，也不能被实例化"。

为什么要这么严？因为 `AppDialog` 本质上只是个**命名空间**，我们要的就是 `AppDialog.confirm(...)` 这个调用形式，没人应该去 `new AppDialog()`。用 `abstract final` 声明出来，编译器直接帮你把错误用法堵死了，比写注释"请勿实例化"靠谱一万倍。

如果你的项目还在 Dart 2，退而求其次可以用私有构造器：

```dart
class AppDialog {
  AppDialog._(); // Dart 2 时代的老办法，防止被实例化
  static Future<bool> confirm({...}) async { /* ... */ }
}
```

#### 2. 命名构造器 + 私有字段，把"形态"编进类型里

有些组件会有几种形态。比如底部操作栏，有时候是一个大提交按钮，有时候是并排几个按钮。

最容易想到的写法是加参数：`AppActionBar(submitText: ..., items: ...)`，然后内部判断哪个不为 null。但这样有个问题——**调用方可以两个都传，也可以两个都不传**，这两种情况你都得处理，还得想好优先级。

更好的做法是用**命名构造器**，把形态编进类型里：

```dart
class AppActionBar extends StatelessWidget {
  /// 形态一：单个提交按钮
  const AppActionBar.submit({
    super.key,
    required String text,
    required VoidCallback onPressed,
  })  : _items = const [],
        _submitText = text,
        _onSubmit = onPressed;

  /// 形态二：并排多个操作按钮
  const AppActionBar.actions({
    super.key,
    required List<ActionItem> items,
  })  : _items = items,
        _submitText = null,
        _onSubmit = null;

  final List<ActionItem> _items;
  final String? _submitText;      // 非 null 即代表 submit 形态
  final VoidCallback? _onSubmit;

  @override
  Widget build(BuildContext context) {
    // 靠 _submitText 是否为空来分流，两种形态互斥且必有其一
    return _submitText != null ? _buildSubmit() : _buildActions(_items);
  }
  // ...
}
```

这么写之后，调用方只有两条路可走：

```dart
// 提交形态
AppActionBar.submit(text: '保存', onPressed: _onSave);

// 多按钮形态
AppActionBar.actions(items: [/* ... */]);
```

**非法状态在编译期就不存在了**，你不可能构造出一个"既有提交按钮又有多按钮"的怪东西。这个思路在 Flutter 里挺常用的，官方的 `ListView` / `ListView.builder` / `ListView.separated` 就是这个路子。

字段用下划线开头设为私有，是因为它们只是内部实现细节，不希望外部读取。

#### 3. 所有组件只用 `BrandColors`，不接外部色值

公共组件是"设计系统的门面"，所以内部颜色一律走 [B03](B03-brand-colors-token.md) 的语义色。

这条要**主动做减法**：即使有同学来提需求说"能不能给 `AppTag` 加个 `color` 参数，我这儿要个紫色的"，也建议先问一句"为什么需要紫色"。

因为一旦开了这个口子，组件就守不住了。今天加个 `color`，明天加个 `borderRadius`，后天加个 `padding`——加到最后，这个组件就退化成了一个"参数特别多的 Container"，它统一风格的价值荡然无存。

我的处理方式一般是：

- 如果确实是一个新的**语义**（比如"待处理"状态需要一个新颜色），那就在 `BrandColors` 里加一个语义常量，然后在组件内部支持这个语义枚举；
- 如果只是某个页面想搞点特殊，那就……委婉拒绝哈。真的特殊到这个地步，那就说明它不该用公共组件。

#### 4. 组件自己不管数据，只管展示

这条是红线，我单独拎出来说。

公共组件里**不要**出现任何请求、任何全局状态读取。它应该是纯粹的"输入参数 → 渲染 UI + 抛出回调"。

```dart
// ✅ 好：数据从外面来，事件往外面抛
AppFilterChips(
  items: options,
  selected: currentIndex,
  onChanged: (i) => setState(() => currentIndex = i),
);
```

一旦组件内部自己去取数据，它就跟具体场景绑死了，第二个页面想复用的时候一定会发现"它取的不是我要的东西"。那就白抽了。

### 四、落地过程中踩的坑

光讲原则有点虚，说两个我实际踩到的。

#### 坑一：BuildContext 用错，弹窗关不掉

写 `AppDialog` 的时候我一开始是这么写的：

```dart
// ❌ 错误示范：builder 里用了外层的 context
final result = await showDialog<bool>(
  context: context,
  builder: (_) => AlertDialog(
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false), // 注意这里用的是外层 context
        child: const Text('取消'),
      ),
    ],
  ),
);
```

看着好像没问题，很多时候也确实能跑。但在嵌套 Navigator 的场景下（比如底部 Tab 每个都有自己的 Navigator），这个外层 `context` 找到的可能是错误的那个 Navigator，结果就是**点取消把整个页面 pop 掉了，弹窗还在那儿杵着**。

正确做法就是前面代码里那样，**用 builder 给你的那个 `ctx`**。这个 context 是弹窗自己那一层的，pop 的一定是弹窗本身。

排查这个问题的时候我绕了不少弯路，一度以为是路由配置的问题。后来是靠打印 context 的层级才定位到：

```dart
// 临时加一行，看看当前 context 找到的是哪个 Navigator
debugPrint('navigator = ${Navigator.of(ctx)}');
```

#### 坑二：异步之后用 context，lint 会警告

写异步弹窗的时候，你大概率会撞上这个警告：

```sh
info • Don't use 'BuildContext's across async gaps • use_build_context_synchronously
```

意思是：`await` 之后，这个 widget 可能已经被销毁了，你再用它的 `context` 就是访问一个失效的对象，运行时可能崩。

正确的处理是加 `mounted` 检查：

```dart
final ok = await AppDialog.confirm(context: context, title: '确认', content: '确定删除？');
// await 之后，先确认组件还活着，再用 context
if (!mounted) return;
if (ok) {
  AppToast.show(context, '已删除');
}
```

我知道有些同学嫌烦，会用 `// ignore: use_build_context_synchronously` 一把把它按掉。我劝各位看官别这么干哈——这个警告是真能救命的，用户在弹窗还开着的时候点了返回键，就是妥妥的崩溃现场。

### 五、光有组件不够，还得有规则

最后说个"非技术"但很关键的点。

组件抽出来了，不代表大家就会用。总有人因为不知道、或者觉得"我这个场景有点特殊"，绕过去自己写一个。

所以组件库一定要配套规则，写进团队的 UI 规范文档里，比如：

> - 列表页筛选条一律使用 `AppFilterChips`，禁止自绘；
> - 确认类弹窗一律使用 `AppDialog.confirm`，禁止直接调 `showDialog`；
> - 空态 / 错误态一律使用 `AppEmptyBody` / `AppErrorBody`。

有了这几条，code review 的时候就有据可依了。看到 diff 里出现裸的 `showDialog`，一句"用 `AppDialog` 哈"就能打回去，不用每次都重新论证一遍为什么。

这块的更多想法，可以看 [G01](G01-style-guide-hard-rules.md)。

### 小结

好啦，公共组件库这块就聊完了，顺带整个主题系列也告一段落。捋一下核心的几条：

1. **公共组件的价值不在"少写几行"，而在风格统一 + 质量门禁**。一个组件被全站复用的前提，是它自己的质量过得去。
2. **抽组件前先做分析**，同一个 UI 出现第三次再抽。别盲目抽，更别提前造一堆用不上的。
3. **`abstract final class` + 静态方法 / 命名构造器**，是 Flutter 组件 API 的优雅范式。把非法状态在编译期干掉，比运行时判断强得多。
4. **组件内部只用 `BrandColors`**，对"加个自定义颜色参数"的需求要克制，开了口子就守不住。
5. **组件只管展示，不碰数据**，否则复用性归零。
6. **配套规范文档**，否则总会有人绕过去。

说实话，这一层封装的代码量真不大，二十个组件加起来也就一两千行。但它带来的变化挺明显的：新同学接手页面，不用再纠结"弹窗该长什么样"，`AppDialog.confirm` 一行搞定，样式自动就对了。这种"想写错都难"的状态，才是组件库真正的价值。

最后，希望这篇文章能够对各位看官有所帮助。各位看官的项目里公共组件是怎么划边界的？有没有遇到过"抽早了"或者"抽过头了"的情况？欢迎在评论区交流哈。各位看官一定要多多点赞收藏，关注留言哈！谢谢大家！

---

*上一篇：[B03 BrandColors Token](B03-brand-colors-token.md) ｜ 返回 [内容规划](./00-内容规划.md)*

> 本文由 FungLeo 主导，Deepseek 优化校阅，转发请注明首发地址，谢谢大家！
