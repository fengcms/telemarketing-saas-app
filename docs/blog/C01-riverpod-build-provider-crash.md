# C01 · Flutter Riverpod 在 build 期改 provider 导致整页崩溃，踩坑实录，必看！

> 作者：FungLeo ｜ 适用：Flutter / Riverpod
> 现象：Web 端登录进首页，页面一个请求都不发，安卓真机却完全正常。

### 前言

说实话，这个坑折磨了我小半天，最后发现根子在一行看起来人畜无害的赋值语句上。

事情是这样的：项目在安卓真机上跑得好好的，进首页刷刷刷全是请求。我顺手在 Chrome 里跑了一下 Web 版，登录完进首页——白的，转圈都不转，Network 面板干干净净，**一个业务请求都没发出去**。

我第一反应是跨域，第二反应是 Web 端的网络层配置有问题。结果打开控制台一看，躺着一条 Riverpod 抛的错，关键词是 `_debugCanModifyProviders`。

哦豁，原来根本不是网络的事儿，是页面在构建阶段就已经崩了，请求压根没走到发起那一步。

这篇就把这个坑完整讲一遍。它有个很讨厌的特点：**平时不显形，一显形就是整页崩溃，而且大概率只在 Web 上暴露**，各位看官要是没见过，真挺难往这个方向想。

### 现象：只有 Web 崩，安卓一切正常

先把现象摆清楚，方便你对号入座：

- Web 端登录后进首页，页面结构渲染不出来或者卡在空白/骨架屏；
- 首页对应的 `loadData()` 没有任何执行痕迹，接口一个不发；
- 安卓真机、iOS 真机跑同样的代码，完全正常；
- 控制台能看到 Riverpod 的构建期保护异常（`_debugCanModifyProviders` 相关）。

最迷惑人的就是「安卓正常」这一条。它会把你的注意力全部引到"Web 平台适配"上去，什么 CORS、什么 `dart:html`、什么 Web 端存储不兼容，一通乱查——我就是这么浪费掉大半天的。

### 根因：Riverpod 不允许你在构建期改 provider

Riverpod 有个保护机制：在 **build / initState / didChangeDependencies** 这些"构建期"的方法里修改 provider 的状态，它会直接抛异常。

这个设计本身是合理的。Widget 正在构建的过程中你去改状态，就等于告诉框架"我刚渲染出来的这一帧已经过期了"，数据流会变得不可预测，所以 Riverpod 干脆在 debug 模式下把这条路堵死。

那么，我的代码是怎么撞上去的呢？两个因素叠加。

#### 因素一：`load()` 的第一行是同步 setState

有一个统计类的 provider，写法大概长这样：

```dart
class StatsNotifier extends StateNotifier<StatsState> {
  StatsNotifier() : super(const StatsState()) {
    load(); // 构造函数里直接调 load
  }

  void load() {
    state = state.copyWith(isLoading: true); // ❌ 同步就把 state 改了
    // ... 后面才是 await 请求
  }
}
```

各位看官注意 `load()` 的第一行。它在 **任何 await 之前** 就把 `state` 改掉了，也就是说这行代码是**同步执行**的。

同步意味着什么？意味着谁调用 `load()`，这次状态修改就发生在谁的执行栈里。如果调用方是 `initState`，那这次修改就实实在在发生在构建期。

#### 因素二：`IndexedStack` 把所有 Tab 一次性挂载了

外层的 `MainShell` 用的是 `IndexedStack` 来做 Tab 切换。`IndexedStack` 有个特性：**它会一次性构建所有子页面**，只是把非当前页藏起来不显示而已。

这个特性平时是优点（切 Tab 不丢状态、不重建），但在这里成了放大器：

```dart
// 进首页的那一瞬间，4 个 Tab 页的 initState 全都跑了一遍
IndexedStack(
  index: currentIndex,
  children: const [
    HomePage(),
    ItemListPage(),
    StatsPage(),   // 这一页的 initState 里同步调了 .notifier.load()
    ProfilePage(),
  ],
)
```

于是链路就串起来了：

1. 进入首页，`MainShell` 开始构建；
2. `IndexedStack` 顺手把 4 个 Tab 全建了；
3. 其中某个 Tab 的 `initState` 同步调用了 `.notifier.load()`；
4. `load()` 第一行同步改 `state`；
5. Riverpod 判定"你在构建期改 provider"，抛异常；
6. 异常发生在 `MainShell` 的构建过程中，**整个壳子构建失败**；
7. 首页的 `HomePageNotifier.loadData()` 根本没机会执行；
8. 表现出来就是——首页不发包。

> 至于为什么只有 Web 暴露：构建期保护的触发依赖时序，原生端的调度时序相对"宽松"，这一下可能就滑过去了；Web 上的时序更脆，一撞一个准。所以这类问题在原生端往往是"定时炸弹"，只是还没炸而已，不代表你的写法是对的。

### 我是怎么一步步排查的

这段弯路我也一并写出来，免得各位看官再走一遍。

1. **先怀疑跨域**。Web 端嘛，第一反应就是 CORS。结果 Network 面板里连 OPTIONS 预检都没有——请求根本没发，那就跟跨域没关系。
2. **再怀疑鉴权状态**。以为是 Web 端 token 存取有问题导致提前拦截了。打日志看了一圈，token 好好地躺在那儿。
3. **发现"请求没发"这件事本身才是线索**。既然一个包都不发，那问题就不在网络层，而在"发请求的那段代码没被执行"。方向一下子就转过来了。
4. **回头认真读控制台**。之前只扫了一眼，看到一堆红字就以为是常规 Web 警告。仔细读才发现 `_debugCanModifyProviders` 这个关键词，Riverpod 明明白白告诉我：你在构建期改 provider 了。
5. **顺着栈往上找调用方**。定位到某个 Tab 页的 `initState` → `.notifier.load()` → `load()` 首行同步 setState，真凶落网。

说实话，第 3 步是转折点。**当你发现"请求没发出去"的时候，就别在网络层耗着了**，去查渲染和状态流，效率高得多。

### 修复：把初始 loading 态放到构造器里

改法非常简单，思路就一句话：**别在 `load()` 里同步改状态，初始状态在构造的时候就给足。**

```dart
class StatsNotifier extends StateNotifier<StatsState> {
  // 初始就是 loading 态，在 super 里一次性给到，不再进 load()
  StatsNotifier() : super(const StatsState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    // ❌ 删掉原来首行的同步 state = state.copyWith(isLoading: true);
    final data = await _fetch();   // 只有在 await 之后才改 state
    state = state.copyWith(isLoading: false, data: data);
  }
}
```

为什么这样就好了？因为 `await` 之后的代码会被丢到下一个微任务里执行，那时候当前这一帧的构建早就结束了，不在构建期，Riverpod 自然不拦。

顺手还要做一件事：**把页面 `initState` 里多余的 `.notifier.load()` 删掉**。

```dart
// old ❌ 构造器里已经 load 过一次了，这里再来一次纯属重复请求
@override
void initState() {
  super.initState();
  ref.read(statsProvider.notifier).load();
}

// new ✅ 什么都不用写，provider 被首次读取时构造器自己会 load
```

改完 Web 端一刷新，首页请求唰唰全出来了。OK，收工。

### 顺带说说：哪些地方改 provider 是安全的

既然踩了这个坑，就把边界一次性理清楚，省得以后写代码提心吊胆。

**不安全（构建期，会被拦）：**

- `build()` 方法体里；
- `initState()` 里同步调用；
- `didChangeDependencies()` 里同步调用；
- 任何在上述方法执行栈中同步触发的状态修改。

**安全（事件回调，随便改）：**

- 按钮 `onPressed`、`onTap` 之类的用户交互回调；
- `onRefresh`（下拉刷新）；
- 滚动监听、定时器回调；
- 任何 `await` 之后的代码。

如果你确实需要"页面一出来就干点什么"，又不想改 Notifier 的构造器，还有个常规办法是把动作推迟到当前帧渲染完之后：

```dart
@override
void initState() {
  super.initState();
  // 等这一帧画完再动 provider，就不算构建期了
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(someProvider.notifier).refresh();
  });
}
```

这个写法能用，但我个人更推荐前面那种"初始态放构造器"的做法——语义更干净，也不用额外记一个 API。`addPostFrameCallback` 更适合那种"必须等布局完成才能算的逻辑"，拿它来绕构建期检查，多少有点治标不治本的意思哈。

另外建议各位看官改完之后，**全仓搜一遍 `.notifier.` 的调用点**，确认它们都待在事件回调里。这类隐患往往不止一处，你只修了报错的那个，剩下的还在暗处等着你。

### 小结

好啦，这个坑就讲到这儿。

复盘一下：一行写在 `load()` 首行的同步 `state = ...`，加上 `IndexedStack` 一次性挂载所有子页的特性，两者一叠加，就把一个不起眼的写法问题放大成了"整个页面壳子构建崩溃"。而崩溃又发生在请求发起之前，最终伪装成"首页不发请求"这么一个跟根因八竿子打不着的现象。

给各位看官留三条能直接用的结论：

1. **初始 loading 态用 `super(const State(isLoading: true))` 表达**，别在 `load()` 首行同步 setState；
2. **看到"页面不发请求"，先查渲染有没有崩**，不要一头扎进网络层；
3. **`IndexedStack` 是构建期副作用的放大器**，用它做 Tab 的项目，尤其要注意各子页 `initState` 里的动作。

最后，如果这篇文章帮你少熬了一个通宵，希望看官您用发财的小手点个小赞哈！要是你在 Riverpod 上还踩过别的坑，欢迎在评论区聊聊，让更多同学少走弯路。谢谢大家！

---

*下一篇：[C02 带 TTL 的多级缓存设计](C02-ttl-multi-level-cache.md)*

> 本文由 FungLeo 主导，Deepseek 优化校阅，转发请注明首发地址，谢谢大家！
