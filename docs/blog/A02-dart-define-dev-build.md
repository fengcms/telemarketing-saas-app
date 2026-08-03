# A02 · Flutter dart-define 实现 dev/正式双构建，调试代码正式包零残留，各位同学记得收藏哦！

> 作者：FungLeo ｜ 适用：Flutter
> 需求：开发阶段想要一个"调试浮窗 + 登录预填账号"的便捷通道，但正式包里绝不能留下任何痕迹——不是"不显示"，是编译产物里干脆不存在。

### 前言

说实话，这个需求是被自己吓出来的。

我在项目里加了个调试浮窗，点一下能看所有网络请求；顺手又在登录页塞了几行预填测试账号的代码，省得每次手输。开发阶段爽是真爽，但打正式包的时候我心里就开始打鼓了——万一哪天我忘了注释，测试账号跟着正式包发出去了，那就不是丢人的问题了。

我一开始的做法特别原始：加一个 `bool isDev = true;` 的全局变量，打包前手动改成 `false`。

结果第二周我就翻车了。改了忘了改回来，改回来又忘了改过去，来回折腾好几次。而且最要命的是，**那段代码它还在包里躺着**，只是没执行而已。反编译一扒，测试账号密码明晃晃写在那儿，你说尴尬不尴尬。

后来我才老老实实地用上了 `dart-define` 配合 `const` 常量。这套组合最爽的地方在于：**不是"不执行"，是编译期就把那段代码从产物里抹掉了**。今天就把这套东西完整地给各位看官讲一遍。

### 核心：一个编译期常量开关

先建一个文件 `lib/core/dev_tools.dart`，全项目就靠它一个开关：

```dart
/// 是否启用开发调试工具（浮窗 / 预填账号等）。
///
/// 通过构建参数 `--dart-define=DEV_TOOLS=true` 开启。
/// 不传时默认 false，且相关代码在 release 编译期被彻底消除。
const bool enableDevTools = bool.fromEnvironment('DEV_TOOLS', defaultValue: false);
```

就这么一行，但里面有几个关键点，各位看官务必留意：

- `bool.fromEnvironment` 是在**编译期**求值的，配上 `const` 声明，结果就是一个货真价实的编译期常量。
- 在 `if (enableDevTools) { ... }` 这样的分支里，当值为 `false` 时，整个分支会被判定成死代码，AOT 编译 + tree-shaking 会把它连同它引用到的东西一起删掉。
- 千万别用运行时变量（读配置文件、读环境变量、读接口下发）来做这种"是否打包"的判断。那样代码还在产物里，只是不执行，防不住反编译。

#### `const` 和 `final`，差的可不是一个字

这里有个特别容易写错的地方，我自己就写错过：

```dart
// ❌ 用 final：值是对的，但编译器不会拿它做死代码消除
final bool enableDevTools = bool.fromEnvironment('DEV_TOOLS');

// ✅ 用 const：这才是编译期常量，分支才会被真正删掉
const bool enableDevTools = bool.fromEnvironment('DEV_TOOLS');
```

`final` 的语义是"运行时只赋值一次"，编译器在做 tree-shaking 的时候不敢假设它一定是 `false`，所以那段调试代码大概率还会留在包里。**一个字母的差别，效果天差地别**，对吧。

#### 那 `kDebugMode` 不行吗？

有看官可能会问：Flutter 自带的 `kDebugMode` 也是 `const`，为啥不直接用它？

```dart
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  // debug 包里才有
}
```

这么写也能 tree-shaking，没毛病。但它有个硬伤：**它和构建模式死死绑在一起**。

我实际的需求是——我想给测试同学发一个"带调试浮窗的 release 包"，让他们在真机上抓包看接口，同时又保持 release 的性能表现。用 `kDebugMode` 就做不到，因为一旦打 release，浮窗必然没了。

而 `dart-define` 是和构建模式**正交**的：debug 包可以不带调试工具，release 包也可以带。想怎么组合就怎么组合，灵活得多。

### 用法一：网络层按需注入调试拦截器

```dart
// lib/core/api_client.dart
ApiClient() {
  _dio = Dio();
  if (enableDevTools) {
    _dio.interceptors.add(aliceDioAdapter); // 仅开发包注入调试拦截器
  }
}
```

正式构建不传 `DEV_TOOLS`，这段 `if` 里的东西连同 `aliceDioAdapter` 的引用一起被擦除。至于这个调试面板具体怎么接，下一篇 [A03](A03-alice-network-debug.md) 会细讲，里面还藏着个能把人送走的大坑。

### 用法二：登录页预填测试账号

```dart
// lib/pages/login_page.dart
void _loadSavedCredentials() {
  // ...正常加载本地保存的账号...
  if (enableDevTools) {
    _emailCtrl.text = 'dev@example.com';
    _passwordCtrl.text = 'Dev@123456';
  }
}
```

正式包里这段代码压根不存在，`_emailCtrl` 永远不会被预填。这下我终于能睡个安稳觉了。

### 构建命令

```sh
# 开发包（带调试浮窗 + 预填账号）
➜ flutter build apk --dart-define=DEV_TOOLS=true

# 正式包（什么都没有，干干净净）
➜ flutter build apk
```

多个开关就多写几个 `--dart-define`，一个一个往后排：

```sh
➜ flutter build apk \
  --dart-define=DEV_TOOLS=true \
  --dart-define=MOCK_DATA=false
```

CI 里正式发布的那条流水线，**什么都不传**，天然零残留。这一点我觉得特别香——安全性不再依赖"人记不记得改代码"，而是依赖流水线配置，这才叫工程化。

#### 开关太多了？用 `--dart-define-from-file`

如果开关攒到七八个，命令行会长得没法看。Flutter 3.7 之后支持从 JSON 文件里读：

```json
// dev-config.json
{
  "DEV_TOOLS": true,
  "MOCK_DATA": false
}
```

```sh
➜ flutter build apk --dart-define-from-file=dev-config.json
```

记得把这个文件加进 `.gitignore`，或者只提交一份 `dev-config.example.json` 做模板。

#### IDE 里怎么带参数跑

天天敲命令行也累，我一般直接配到 IDE 里。

VS Code 改 `.vscode/launch.json`：

```json
{
  "configurations": [
    {
      "name": "Flutter (Dev Tools)",
      "request": "launch",
      "type": "dart",
      // 注意是 toolArgs，传给 flutter 命令；args 是传给 App 本身的
      "toolArgs": ["--dart-define=DEV_TOOLS=true"]
    }
  ]
}
```

Android Studio 的话，在 `Run/Debug Configurations` 里找到 `Additional run args`，把 `--dart-define=DEV_TOOLS=true` 填进去就行。

### 几个我自己踩过的注意事项

好啦，正经用法讲完了，再唠几个容易翻车的细节。

**1. 改了 dart-define 却没生效**

我遇到过改完参数重新跑，发现行为跟之前一模一样的情况。这时候别怀疑人生，先 `flutter clean` 一把再来：

```sh
➜ flutter clean && flutter pub get
➜ flutter build apk --dart-define=DEV_TOOLS=true
```

增量构建对构建参数变化的感知，在某些版本上貌似不太靠谱，清一下最省心。

**2. 千万别拿它传敏感密钥**

这是个高频误用。`dart-define` 传进去的值，**是会以某种形式留在构建产物里的**（比如 iOS 侧会写进 Xcode 的构建配置，Android 侧也能从产物中翻出来）。它防的是"调试代码残留"，防不了"有心人扒你的密钥"。

真正的密钥，要么后端接口下发，要么走 NDK / 原生层保管，别图省事塞 `dart-define`。

**3. 别在开关判断里写副作用**

```dart
// ❌ 别这么写：把重要初始化藏在开关里，正式包直接少一块逻辑
if (enableDevTools) {
  initSomethingImportant();   // 这玩意儿正式包也需要！
  showDebugOverlay();
}
```

开关里只放"调试专属"的东西。我见过有人图省事把正常初始化也塞进去，结果正式包起来就白屏，排查半天。

**4. 类型别搞混**

`bool.fromEnvironment` 只认字符串 `'true'`，其他任何值都是 `false`。所以 `--dart-define=DEV_TOOLS=1` 是不管用的，得老老实实写 `true`。同理还有 `String.fromEnvironment` 和 `int.fromEnvironment`，各取所需。

### 小结

好啦，这套 dev/正式双构建的方案就讲完了。

回头看，核心其实就一句话：**`dart-define` + `const` = 真·编译期开关，优于任何运行时判断。** 它适合的场景挺多的——调试浮窗、Mock 数据、预填账号、内部日志、接口地址切换，都能靠它一刀切干净。

而它最大的价值，我感觉不在技术本身，在于**把"会不会漏"这件事从人的记性转移到了构建命令上**。人是会忘的，流水线不会。

至于不适合的场景也很明确：敏感密钥别用它，需要运行时动态切换的东西也别用它——那是配置中心该干的活儿，各位看官分清楚就好。

最后，希望这篇小文能对各位看官有所帮助，如果你也曾经被"忘了把 isDev 改回去"坑过，欢迎在评论区吐个槽哈！觉得有用的话，麻烦您用发财的小手点个赞、收个藏，谢谢大家！

---

*上一篇：[A01 Release 联网权限](A01-release-internet-permission.md) ｜ 下一篇：[A03 接入 Alice 调试浮窗](A03-alice-network-debug.md)*

> 本文由 FungLeo 主导，Deepseek 优化校阅，转发请注明首发地址，谢谢大家！
