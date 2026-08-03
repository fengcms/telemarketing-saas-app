# A03 · Flutter 接入 Alice 网络调试浮窗实战，含 AOT 顶层 final 抢跑大坑，必看！

> 作者：FungLeo ｜ 适用：Flutter / Dio
> 现象预告：接完调试面板之后，debug 一切正常，release 死活连不上网，报 `Failed host lookup`。

### 前言

真机调试最头疼的是什么？我的答案是：**看不清接口**。

在电脑上跑的时候还好，Dio 挂个 `LogInterceptor` 或者 `pretty_dio_logger`，控制台哗哗打日志，想看啥有啥。可一旦包装到真机上交给测试同学，链路就断了——他跟你说"这个页面数据不对"，你只能靠猜。是请求没发出去？是参数错了？是后端返回的字段变了？全靠脑补。

后来我就想，能不能把调试面板做进 App 里，直接在手机上点开看。找了一圈，[Alice](https://pub.dev/packages/alice) 是个挺成熟的方案：一个 Dio 拦截器 + 一个 Inspector 面板，所有请求、响应、错误全在里面，点开就能看，还能分享出来。

想法很美好，接的时候也挺顺利，debug 跑得飞起。然后我打了个 release 包，**登录直接失败，一个接口都连不上**。

那一刻我是懵的。我就加了个日志面板，怎么把网络给整没了？

这个坑我排查了整整一个下午，而且它极其隐蔽，我觉得非常值得单独写一篇。各位看官慢慢看，别急，先讲怎么接，再讲怎么翻的车。

### 接入方式（alice 1.0.0）

先提个醒，也是我踩的第一个小坑：**alice 1.0.0 的 API 和网上那些老博客写的完全不一样**。

具体变了这几处：

- Dio 适配器被拆到了独立包 `alice_dio` 里，不装这个包啥也干不了；
- 旧版的 `getDioInterceptor()` 方法**没了**；
- 旧版那个"摇一摇自动弹浮标"的功能也**移除了**，得自己动手做入口。

所以你照着两年前的博客抄，是一定跑不起来的。先把依赖装对：

```yaml
# pubspec.yaml
dependencies:
  alice: ^1.0.0
  alice_dio: ^1.0.0
```

然后写一个管理类。这里我先把结论写出来，**注意是懒加载单例，不是顶层 final**，为什么后面细说：

```dart
// lib/core/alice_manager.dart
class AliceManager {
  AliceManager._();
  static AliceManager? _instance;

  // 懒加载单例：首次访问时才真正创建，此时引擎已经就绪
  static AliceManager get instance {
    _instance ??= AliceManager._();
    return _instance!;
  }

  late final Alice alice = Alice(
    configuration: AliceConfiguration(
      showInspectorOnShake: false, // 1.0.0 已移除摇一摇，这里显式关掉
      showNotification: false,     // 通知也关掉，少一个平台通道依赖
    ),
  );

  late final AliceDioAdapter dioAdapter = AliceDioAdapter();
}
```

接着在网络层里挂上去。注意外面那层 `if (enableDevTools)`，这就是上一篇 [A02](A02-dart-define-dev-build.md) 讲的编译期开关，正式包里这一整块都会被抹掉：

```dart
// lib/core/api_client.dart
if (enableDevTools) {
  final m = AliceManager.instance;
  m.alice.addAdapter(m.dioAdapter);   // 先把适配器注册给 alice
  _dio.interceptors.add(m.dioAdapter); // 再把它挂到 Dio 拦截器链上
}
```

#### 自己叠一个浮窗入口

前面说了，1.0.0 没有自动浮标了，所以唤出面板的入口得咱们自己造。我的做法是在 `MaterialApp` 的 `builder` 里叠一个 `Stack`：

```dart
// lib/app.dart
MaterialApp(
  // alice 弹面板需要拿到 navigator，正式包传 null 即可
  navigatorKey: enableDevTools ? AliceManager.instance.alice.getNavigatorKey() : null,
  builder: (ctx, child) => Stack(
    children: [
      child!,
      if (enableDevTools) const _DevToolsFloatingButton(),
    ],
  ),
);

class _DevToolsFloatingButton extends StatefulWidget {
  const _DevToolsFloatingButton();
  @override
  State<_DevToolsFloatingButton> createState() => _DevToolsFloatingButtonState();
}

class _DevToolsFloatingButtonState extends State<_DevToolsFloatingButton> {
  Offset _offset = const Offset(0, 0); // 可拖拽，初始右下角
  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16 + _offset.dx,
      bottom: 16 + _offset.dy,
      child: GestureDetector(
        onTap: () => AliceManager.instance.alice.showInspector(),
        child: const FloatingActionButton.small(
          onPressed: null,
          child: Icon(Icons.bug_report),
        ),
      ),
    );
  }
}
```

一个小虫子图标浮在右下角，点一下面板就出来了，所有请求列表清清楚楚。到这一步，debug 包完美运行，我当时还挺得意。

### 大坑：别在模块顶层用 `final` 初始化 Alice

好啦，重头戏来了。

我最初的写法，是图省事直接在文件顶层甩了两个 `final`：

```dart
// ❌ 我最开始的错误写法
final Alice alice = Alice(...);                 // 模块顶层 final
final AliceDioAdapter aliceDioAdapter = ...;    // 模块顶层 final
```

看着多干净啊，一个单例类都省了。

结果就是我前面说的：**debug 一切正常，release 死活连不上网**，报错长这样：

```
DioException [unknown]: null
Error: SocketException: Failed host lookup: 'xxx'
(OS Error: No address associated with hostname, errno = 7)
```

`Failed host lookup`，这不就是 DNS 解析不了嘛。任谁看到这个报错，第一反应都是网络问题、域名问题、权限问题——反正跟"我加了个日志面板"这件事，八竿子打不着。

#### 我是怎么一步步排查的

这段弯路我详细说说，比结论本身有用。

**第一步，怀疑联网权限。** 这是老经验了，我上一次踩的就是这个（[A01](A01-release-internet-permission.md)）。翻开 `AndroidManifest.xml` 一看，`INTERNET` 权限好好地待在 `main` 清单里。排除。

**第二步，怀疑 DNS 和网络环境。** 换 WiFi、换 4G、换手机热点，甚至把域名直接换成 IP 硬怼，结果全都一样。这时候我心里就有点数了——**如果换成 IP 直连都还报 host lookup，那问题多半不在"解析"本身，而在发起请求的这一整套底层状态上**。

**第三步，做减法。** 这一步是转折点。我把最近这几天加的东西一个一个往回撤，撤到把 Alice 相关代码全注释掉的时候，release 包突然就通了。

那一刻我人都精神了：合着是这货干的。

**第四步，定位到初始化时机。** 既然是 Alice，那问题出在哪儿？我注意到一个特别关键的现象——**我并没有调用任何 Alice 的方法，光是"声明了那两个顶层 final 变量"，网络就废了**。

那就只剩一个可能：**问题出在它的构造过程本身，而且是在我意识到之前就已经执行了。**

#### 原因分析

顺着这条线往下想，我的判断是这样的：

- `Alice` / `AliceDioAdapter` 的构造内部会触碰 **MethodChannel**（它要处理通知、要拿导航能力，这些都是平台通道）。
- 在 **AOT（release）** 环境下，这两个顶层 `final` 的初始化，赶在了 Flutter 引擎 / MethodChannel 完全就绪**之前**。
- 这么一"抢跑"，貌似把 Dart 侧网络栈的底层状态给带偏了，导致后续所有 Dio 请求的 DNS 解析统统失败。
- 而 debug 是 JIT，初始化时机和 AOT 不一样，所以一点事没有——这也就解释了那个诡异的"debug 能登、release 不能登"。

我得实事求是地说一句：上面第三条的具体机理，我并没有扒到引擎源码级别去证实，属于我根据现象做的推断。但**现象是确凿的，修复方案也是百分之百有效的**，各位看官照做就行。

#### 修复：改成懒加载单例

修法很简单，就是前面贴的 `AliceManager.instance` 那一版：

```dart
// ✅ 懒加载：只有第一次真正用到的时候才构造
static AliceManager get instance {
  _instance ??= AliceManager._();
  return _instance!;
}
```

核心就一句话：**把初始化时机往后推，推到引擎已经 ready 之后**。改完重新打 release 包，接口唰唰全通，浮窗也正常。

如果你的场景没法用懒加载，那就明确放进 `main()` 里，并且记得先 `ensureInitialized`：

```dart
void main() {
  // 先确保 Flutter 引擎绑定初始化完成
  WidgetsFlutterBinding.ensureInitialized();
  // 再做需要平台通道的初始化
  runApp(const MyApp());
}
```

### 还有哪些东西也不能放顶层 `final`

既然踩到这儿了，我顺手总结一下同类风险，各位看官对照自查一下。

**判断标准很简单：这个对象的构造过程，会不会碰平台通道（MethodChannel / 原生插件）？** 会，就别放顶层。

常见的高危选手：

- **本地存储类**：`SharedPreferences`、`path_provider` 之类，拿路径就是走平台通道的；
- **通知 / 推送类**：`flutter_local_notifications` 及各种推送 SDK；
- **设备信息类**：`device_info_plus`、`package_info_plus`；
- **各种需要 `initialize()` 的第三方 SDK**：地图、统计、崩溃上报、支付等等。

这些东西的正确姿势就三种：

```dart
// 姿势一：懒加载单例（推荐，最省心）
static Foo get instance => _instance ??= Foo._();

// 姿势二：放进 main()，且在 ensureInitialized() 之后
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  await Foo.init();
  runApp(const MyApp());
}

// 姿势三：类成员的 late final，用到才初始化
late final Foo foo = Foo();
```

另外顺带说一句：Dart 里顶层 `final` 的初始化本来就是"惰性"的语义，这也是它坑人的地方——**你以为它不会提前跑，可一旦哪个不起眼的引用链把它提前唤醒了，你根本察觉不到**。所以与其去赌时机，不如从写法上就把风险掐死。

### 小结

好啦，这一篇的故事就讲到这里。

回头复盘，这个坑真正恶心的地方有两点：

一是**报错信息完全指向错误的方向**。`Failed host lookup` 让你去查 DNS、查权限、查网络，而真凶是一个日志面板的初始化时机，你说气不气。

二是**它只在 release 下出现**。debug 永远正常，你连复现都费劲，只能靠 release 包一遍一遍试，效率极低。关于"release 为什么这么会藏事儿"，下一篇之后的 [A05](A05-release-swallow-exceptions.md) 会专门展开讲。

所以我想留给各位看官的经验就两条：

1. **任何涉及 MethodChannel / 平台通道 / 插件实例的初始化，一律别放在模块顶层 `final`。** 要么懒加载，要么放进 `main()`。
2. **遇到"debug 能、release 不能"的诡异问题，优先怀疑初始化时机和 AOT 行为差异，而不是业务逻辑。** 业务代码在两个模式下是同一份，它一般不会背这个锅。

哦对了还有一条：alice 1.0.0 跟旧版差异非常大，直接看 pub 上的最新示例，别照着老博客抄，能省你一小时。

最后，希望这篇文章能够对各位看官有所帮助。这个坑我是真觉得挺值钱的，各位看官一定要多多点赞收藏，关注留言哈！要是你也遇到过类似的"release 专属灵异事件"，欢迎在评论区分享出来，让更多同学少走弯路。谢谢大家！

---

*上一篇：[A02 dart-define 双构建](A02-dart-define-dev-build.md) ｜ 下一篇：[A04 Android desugaring](A04-android-desugaring.md)*

> 本文由 FungLeo 主导，Deepseek 优化校阅，转发请注明首发地址，谢谢大家！
