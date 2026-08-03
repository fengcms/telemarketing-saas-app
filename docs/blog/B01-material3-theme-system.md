# B01 · Flutter Material 3 从 0 搭品牌主题系统，四件套实战全记录，各位同学记得收藏哦！

> 作者：FungLeo ｜ 适用：Flutter 3.x / Material 3
> 目标：让全项目的颜色、字体、组件样式，收敛到一处可维护、可审计的主题层。

### 前言

说实话，我一开始是不打算搞什么"主题系统"的。

项目刚起步那会儿，就几个页面，哪里要蓝色就写个 `Color(0xFF0052D9)`，哪里要灰字就写个 `Color(0xFFA6A6A6)`，多爽快，一秒钟的事儿。写主题文件？那多麻烦，感觉是大厂才需要的排场。

然后项目跑了两个月，页面从 5 个变成 40 多个。有一天设计同学过来说：主色要往深里调一点点。

我打开编辑器全局搜 `0xFF0052D9`，搜出来七十多处。更要命的是，还有一堆是 `0xFF0052d9`（小写）、`0xff0052D9`，甚至有几个地方是眼睛看着"差不多"就随手写的 `0xFF0052DA`——差了一个数值，肉眼根本看不出来，但它就是不在搜索结果里。

那次改完，我在真机上还是找到了两个漏网之鱼。被设计同学抓包了，挺没面子的。

所以从那之后，我给项目补了一套**主题四件套**。今天这篇就把它从 0 到 1 拆开讲讲，各位看官要是也在写中大型 Flutter 项目，建议一开始就搭上，别像我一样等到七十多处硬编码才回头收拾。

### 为什么是"四件套"，而不是一个大文件

最偷懒的做法，是把所有主题相关的东西塞进一个 `theme.dart`。我最早也是这么干的，写到三百行的时候就开始翻不动了——找一个按钮圆角，得在颜色、字体、间距里面扒拉半天。

所以我按**职责**把它切成四个文件：

```sh
lib/theme/
├── color_scheme.dart      # 品牌色 + BrandColors 语义常量
├── text_theme.dart        # 字体层级
├── component_tokens.dart  # 组件级主题覆写（AppBar / 按钮 / 输入框…）
└── app_theme.dart         # 入口 buildBrandTheme() 组合以上三个
```

这么切的好处很直白：

- 改颜色只开 `color_scheme.dart`，不会误伤别的；
- 组件样式全在 `component_tokens.dart`，新人接手一看就知道去哪儿改；
- `app_theme.dart` 只负责"组装"，永远只有几十行，一眼看到全貌；
- code review 的时候，看 diff 落在哪个文件，就知道这次改动的影响面有多大。

对吧，分层这事儿听着像老生常谈，但它省的是三个月之后的你的时间。

好啦，闲言少叙，我们一个一个来。

### 一、color_scheme.dart：品牌色 + 语义常量

这一层是整套系统的地基。核心思路就一句：**所有色值只在这个文件里出现一次，别的地方一律引用常量。**

```dart
const Color brandBlue = Color(0xFF0052D9); // 品牌主色，整个项目唯一色源

/// 全站语义色，业务代码里禁止再硬编码 0xFFxxxxxx
class BrandColors {
  static const Color primary = brandBlue;
  static const Color primaryLight = Color(0xFF366EF4);
  static const Color primarySurface = Color(0xFFF2F3FF); // 选中态浅蓝底
  static const Color success = Color(0xFF2BA471);
  static const Color warning = Color(0xFFED7B2F);
  static const Color error = Color(0xFFD54941);
  static const Color textPrimary = Color(0xFF181818);    // 主文案
  static const Color textSecondary = Color(0xFFA6A6A6);  // 次要文案
  static const Color textDisabled = Color(0xFFC5C5C5);   // 禁用态
  static const Color surface = Color(0xFFF3F3F3);        // 页面灰底
  static const Color line = Color(0xFFEEEEEE);           // 1px 分割线
  static const Color border = Color(0xFFE7E7E7);         // 卡片灰边框
}

ColorScheme buildColorScheme() => ColorScheme.fromSeed(
  seedColor: brandBlue,        // 让 M3 基于品牌色推导整套配色
  primary: BrandColors.primary, // 关键色手动兜住，不让算法自由发挥
  surface: BrandColors.surface,
  // ...
);
```

这里有个点我想多啰嗦两句，就是 `ColorScheme.fromSeed`。

Material 3 的一大卖点，是你给一个种子色，它能帮你推导出一整套和谐的配色（primary / onPrimary / primaryContainer / surface 一大堆）。听起来很美，我第一次用的时候也被唬得一愣一愣的。

但实际跑下来我发现，**算法推导出的 primary，和设计稿给的品牌色，往往不是同一个色**。M3 会按它的色彩科学做一轮调整，让色调更"和谐"。这对独立开发者挺友好，可对于有品牌规范的项目就是灾难——设计同学拿取色器一量，直接找过来了。

所以我的做法是：**用 `fromSeed` 打底，保证那些我懒得一个个定义的辅助色是协调的；然后把 `primary`、`surface` 这几个用户一眼能看见的关键色手动指定，不给算法发挥的空间。**这样既省事，又守住了品牌。

另外，`BrandColors` 里的命名我也踩过坑。早期我图省事，写的是 `grey1` / `grey2` / `grey3`，结果后来设计加了一档灰，我得插一个 `grey25`……越写越离谱。后来全部改成**按用途命名**：`textSecondary`、`line`、`border`。名字长了点，但语义清楚，也不怕加新色。这块我在 [B03](B03-brand-colors-token.md) 里还会专门展开讲。

### 二、text_theme.dart：字体层级

字体这层我建议**基于系统默认 `TextTheme` 做 `copyWith`，而不是从零全量定义**。

```dart
TextTheme buildTextTheme(TextTheme base) => base.copyWith(
  // 页面大标题
  titleLarge: base.titleLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
  // 正文默认字号，绝大多数 Text 走这个
  bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, color: BrandColors.textPrimary),
  // 辅助说明文字
  labelSmall: base.labelSmall?.copyWith(fontSize: 12, color: BrandColors.textSecondary),
);
```

为啥用 `copyWith`？因为 Material 3 的 `TextTheme` 一共有 15 个字段（display / headline / title / body / label 各三档）。你要是从零 `TextTheme(...)` 全量写，就得把 15 个都填满，漏一个，对应的内置组件就会拿到 `null`，字体样式直接退化。

而 `copyWith` 只覆盖你真正在意的那几档，剩下的沿用 Flutter 给的合理默认值。改动小，风险也小。这就是典型的"够用就好"，没必要一上来把 15 档全定义一遍——大多数项目其实用不到那么多层级。

还有一个小提醒：`bodyMedium` 是 `Text` 组件在没有显式 style 时的兜底样式，所以**它的 color 一定要设成你的主文案色**。我早期忘了设，结果全站文字都是 Flutter 默认的纯黑 `#000000`，跟设计稿的 `#181818` 差那么一丢丢，远看没事，凑近看就是"脏"。

### 三、component_tokens.dart：组件级覆写

这一层是主题系统真正**省代码**的地方。

思路是：与其在每个页面里给 AppBar 手动设背景色、给按钮手动设圆角，不如在主题里统一定义一次，全站自动生效。

```dart
AppBarTheme buildAppBarTheme() => const AppBarTheme(
  backgroundColor: BrandColors.primary,
  foregroundColor: Colors.white, // 标题和返回箭头都跟着变白
  centerTitle: true,             // 标题居中，安卓默认是靠左的
  elevation: 0,                  // 去掉默认阴影，走扁平风
);

// 按钮大圆角（这是我们的品牌特征）
FilledButtonThemeData buildFilledButtonTheme() => FilledButtonThemeData(
  style: FilledButton.styleFrom(
    // 半径给个足够大的值，效果就是完整的胶囊形
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
  ),
);
```

#### 关于 centerTitle，顺手说个跨平台的坑

`centerTitle` 这个属性，你要是不显式设置，Flutter 会按平台给不同的默认值：**iOS 上默认居中，Android 上默认靠左**。

所以就会出现一个很诡异的现象：你在 iOS 模拟器上开发，标题一直好好地居中；等交付测试，安卓机上全部变成靠左了。然后你开始怀疑是不是哪个版本升级改了行为……其实人家一直是这么设计的，只是你没显式指定过。

一句话：**跨平台项目里，凡是"平台相关默认值"的属性，都建议显式写死。**别赌默认值和你想的一样。

#### 覆写要克制，别一次写满

`ThemeData` 能覆写的组件主题有几十个，从 `cardTheme` 到 `chipTheme` 到 `dividerTheme`，看得人手痒。

我的建议是**用到哪个写哪个**。我见过有同学一上来把二十多个组件主题全定义一遍，结果项目里有一半组件压根没用上，纯粹是给后人留了一堆需要维护的死代码。而且这些覆写之间还会互相影响，出了样式问题排查起来特别费劲。

够用就好，真的。

### 四、app_theme.dart：组合入口

前面三个文件都是"零件"，这个文件负责把它们拧成一个 `ThemeData`：

```dart
ThemeData buildBrandTheme() {
  final color = buildColorScheme();
  return ThemeData(
    useMaterial3: true,   // M3 开关，不开的话上面很多东西不生效
    colorScheme: color,
    textTheme: buildTextTheme(ThemeData.light().textTheme),
    appBarTheme: buildAppBarTheme(),
    filledButtonTheme: buildFilledButtonTheme(),
    // 其它组件覆写继续从 component_tokens.dart 里取
  );
}
```

注意 `useMaterial3: true` 这一行，Flutter 3.16 之后新建项目默认就是 true 了，但老项目升上来的话，得自己确认一下。这个开关不打开，M3 的 `FilledButton`、新的 `ColorScheme` 语义都会走 M2 的老逻辑，你会发现"怎么改了半天没反应"。

### 五、接入 MaterialApp

最后一步，在应用入口挂上去：

```dart
MaterialApp(
  theme: buildBrandTheme(),
  locale: const Locale('zh'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: const MyApp(),
);
```

顺手说一下 `locale` 和 `localizationsDelegates`。很多人搭主题的时候不管这俩，然后就会发现：日期选择器、长按文本弹出的"复制/粘贴"菜单，全是英文的。

这不是主题的锅，是本地化代理没配。既然都在改入口了，一起补上，省得以后再回来一趟。

配好之后跑一下，OK，一个页面都不用改，全站 AppBar 就统一成品牌蓝了，按钮也都变成胶囊形了。这种"改一处、全站生效"的感觉，还是挺爽的。

### 六、验证一下：主题到底有没有生效

搭完别急着提交，我一般会新建一个临时的测试页，把常用组件都摆上去看一眼：

```dart
// 一个简易的主题测试页，验证完就可以删
Column(
  children: [
    FilledButton(onPressed: () {}, child: const Text('主按钮')),
    OutlinedButton(onPressed: () {}, child: const Text('次按钮')),
    TextButton(onPressed: () {}, child: const Text('文字按钮')),
    const TextField(decoration: InputDecoration(hintText: '输入框')),
    Text('主文案', style: Theme.of(context).textTheme.bodyMedium),
    Text('辅助文案', style: Theme.of(context).textTheme.labelSmall),
  ],
);
```

这一步很多人嫌麻烦跳过，但我建议做。因为主题的问题往往不是"报错"，而是"某个组件悄悄没跟上"——比如你改了 `primary`，结果发现 `OutlinedButton` 的边框还是老颜色。这种问题在业务页面里混着一堆内容，你是看不出来的；单独摆一页，一眼就发现了。

排查的时候还有个小技巧，直接把当前生效的颜色打出来：

```dart
// 在任意页面的 build 里临时加一行，确认主题真的传下来了
debugPrint('当前 primary = ${Theme.of(context).colorScheme.primary}');
```

我有一次死活觉得主题没生效，打出来才发现——我在某个子树里套了个 `Theme(data: ThemeData(), child: ...)`，把整套主题给覆盖没了。这种事儿光看代码是真看不出来，打一行日志两秒钟解决。

### 小结

好啦，主题四件套就讲到这。回头捋一下核心的几条：

1. **四件套分工明确**：品牌色 / 字体 / 组件 / 入口，各管一摊，互不纠缠。文件小了，改起来才不怕。
2. **语义色集中到 `BrandColors`**，全站只引用它，改色只动一处。这是整套系统里收益最大的一条。
3. **`fromSeed` 打底，关键色手动兜**。别让算法替你决定品牌色长什么样。
4. **`copyWith` 改字体，别全量重写**，漏一档就是一处样式退化。
5. **组件覆写用到哪写哪**，别一次写满二十个，那是给自己挖坑。
6. 页面背景交给 `Scaffold` 自动套 `BrandColors.surface`，业务页面不用手动设背景——这条能省掉一大堆重复代码。

说实话，主题系统这东西前期投入也就一两个小时，但它省的是后面无数次"全局搜索替换还漏了两处"的尴尬。我是被打过脸才回头补的，各位看官要是项目还在早期，建议直接搭上，不亏。

最后，如果这篇小文对您有点用，希望看官您用发财的小手点个小赞哈！要是您的项目里主题分层有别的玩法，或者踩过 M3 什么别的坑，也欢迎在评论区聊聊，大家一起少走弯路。谢谢各位看官了哈！

---

*下一篇：[B02 第三方 UI 库渐进迁移到 Material 3](B02-tdesign-to-m3-migration.md)*

> 本文由 FungLeo 主导，Deepseek 优化校阅，转发请注明首发地址，谢谢大家！
