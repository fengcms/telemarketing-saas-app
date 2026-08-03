# D01 · Flutter 骨架屏 Shimmer 实现，LinearGradient 无 transform 扫光法实战，各位同学记得收藏哦！

> 作者：FungLeo ｜ 适用：Flutter 3.x
> 场景：列表页想做「骨架屏 + 扫光」，照着老教程写 `LinearGradient(transform: ...)`，结果编译直接不过。

### 前言

说实话，骨架屏这玩意儿现在基本算列表页的标配了。

我以前是不太在乎这个的，页面加载中就丢个转圈圈（`CircularProgressIndicator`）在屏幕正中间，能用就行。直到有一次我自己拿真机点了几十遍我们那个列表页，越点越烦——每次都是白屏一闪、转圈一秒、内容"啪"地弹出来，跳动感特别强，看着就廉价。

于是我决定上骨架屏。灰色块块摆好之后，效果确实好多了，但总觉得少点意思：静态的灰块看久了跟"卡死了"没啥区别。那就再加个**扫光**吧，让灰块上有一道浅色的亮带来回滑，一看就知道"我在加载，我还活着"。

结果就是这一步，把我卡了小半个下午。

网上一搜，全是 `LinearGradient(transform: GradientTransform(...))` 的写法，我复制过来，IDE 直接给我标红：

```
undefined_named_parameter: The named parameter 'transform' isn't defined.
```

好家伙。那会儿我第一反应是"这参数被新版删了吧"，然后就顺着这个错误的判断，自己摸了另一条路出来。这条路后来证明还挺好用，所以这篇就把两条路都写给各位看官，顺便把我当时判断错的地方也一并交代清楚。

### 一、先说那个报错，以及我判断错的地方

当时报错的代码大概长这样：

```dart
// ❌ 我当时抄来的写法，直接标红
LinearGradient(
  transform: GradientRotation(0.5), // 报 undefined_named_parameter
  stops: const [0.0, 0.5, 1.0],
  colors: const [Color(0xFFEDEDED), Color(0xFFF5F5F5), Color(0xFFEDEDED)],
)
```

我当时的结论是：「`transform` 这个参数在新版 API 里没了。」

然后我就照着这个结论绕道走了。**但后来我被自己打脸了**——`Gradient`（包括 `LinearGradient`）其实是带 `transform` 参数的，类型是 `GradientTransform`，`GradientRotation` 也确实还在。我那个报错，八成是当时把它写到了不接受这个参数的地方（比如误挂在 `BoxDecoration` 上），或者项目里的 Flutter 版本跟我以为的对不上号。

所以这里先把话说清楚，免得误导各位看官：**不是这个参数被删了**。

那为什么我还要把这篇写出来？因为绕出来的那条路——**平移 `stops`**——反而更简单、更好控，做简单扫光的时候我现在还在用。两条路我都贴，各位看官自己挑。

### 二、绕法：让 stops 随时间平移

思路特别朴素：扫光的本质就是「一道亮带在灰底上从左滑到右」。既然亮带的位置由渐变的 `stops` 决定，那我不动 transform，**直接让 stops 随时间左右平移**，不就等效了吗？

闲言少叙，上代码：

```dart
class ShimmerBlock extends StatefulWidget {
  const ShimmerBlock({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  final double? width;  // 不传就撑满父级可用宽度
  final double height;
  final double radius;

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true); // 来回跑，不是单向循环

  @override
  void dispose() {
    _ctrl.dispose(); // 这行千万别漏，下面专门说
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final p = _ctrl.value;           // 0 → 1 → 0
        final shift = (p - 0.5) * 0.6;   // 平移量，控制在 ±0.3
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              // stops 必须是递增的，所以每个都要 clamp 回 [0, 1]
              stops: [
                (0.0 + shift).clamp(0.0, 1.0),
                (0.5 + shift).clamp(0.0, 1.0),
                (1.0 + shift).clamp(0.0, 1.0),
              ],
              colors: const [
                Color(0xFFEDEDED), // 底色
                Color(0xFFF5F5F5), // 亮带
                Color(0xFFEDEDED), // 底色
              ],
            ),
          ),
        );
      },
    );
  }
}
```

跑起来就是一道浅色亮带在灰块上来回滑，OK，效果到位了。

几个点解释一下：

- **为什么 `stops` 要 clamp**：`LinearGradient` 要求 `stops` 单调不减、且落在 `[0, 1]` 区间内。平移之后必然会有值跑出界（比如 `1.0 + 0.3`），不夹一下就要出问题。夹完之后三个点依然是递增的，所以视觉上没毛病。
- **为什么用 `repeat(reverse: true)`**：如果用普通的 `repeat()`，动画跑到 1 之后会瞬间跳回 0，亮带就会有一下"闪回"，很出戏。`reverse: true` 是让它 0→1→0 来回走，扫光就变成"滑过去、再滑回来"，平滑很多。
- **为什么用 `AnimatedBuilder` 而不是 `setState`**：`AnimatedBuilder` 只重建 builder 里那一小坨，不会把整棵子树拖下水。骨架屏一屏可能有几十个块块，这点开销差别还是挺明显的。
- **`width` 为什么可以不传**：`Container` 自己不带尺寸，宽度不传就跟着父级走。做骨架屏的时候，"标题行"我一般给个固定宽度（比如 120），"正文行"就让它撑满，看着更像真实内容。

### 三、另一条路：老老实实实现 GradientTransform

既然上面已经说了 `transform` 参数是在的，那这条路也顺手补全，省得各位看官还得自己去翻。

`GradientTransform` 是个抽象类，你得自己写个子类，返回一个 `Matrix4`：

```dart
/// 让整个渐变沿 X 轴平移的 transform
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent; // -1 ~ 1

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // 按控件自身宽度的百分比平移
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}
```

用的时候把动画值喂给它：

```dart
LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: const [
    Color(0xFFEDEDED),
    Color(0xFFF5F5F5),
    Color(0xFFEDEDED),
  ],
  // 动画值 0→1 映射成 -1→1 的平移
  transform: _SlidingGradientTransform(_ctrl.value * 2 - 1),
)
```

两条路怎么选，我的看法是：

| 做法 | 优点 | 什么时候用 |
|------|------|-----------|
| 平移 `stops` | 代码短，没有额外类，参数直观 | 简单的横向扫光，大多数骨架屏够用了 |
| 自定义 `GradientTransform` | 能旋转、能缩放，玩得花 | 需要斜向扫光、或者要复用到复杂渐变上 |

一般而言，做骨架屏我就用前者了，够用就好，没必要太折腾。

### 四、几个我踩过或者差点踩到的细节

**1. `dispose` 里一定要 `_ctrl.dispose()`**

这个是真事儿。我第一版忘了写，页面退出去之后 `AnimationController` 还在那儿突突地跑，`repeat` 又是无限的，控制台立马给我甩了一条：

```
_ShimmerBlockState#a1b2c(ticker active) was disposed with an active Ticker.
```

更要命的是列表页反复进出之后，CPU 占用肉眼可见地往上爬。各位看官写带 `repeat` 的动画，`dispose` 请当成肌肉记忆。

**2. 亮带和底色的差值别拉太大**

我最早为了"效果明显"，把底色写成 `0xFFE0E0E0`、亮带写成 `0xFFFFFFFF`，结果扫起来跟舞台灯似的，晃眼。后来收到 `EDEDED` / `F5F5F5` 这个程度，反而高级了。**骨架屏是用来降低焦虑的，不是用来抢戏的。**

**3. 骨架屏的形状要"像"真实内容**

这条比扫光重要多了。如果真实卡片是「左边一个头像圆块 + 右边两行文字」，你的骨架屏就该摆一个圆 + 两条长短不一的横杠。要是随便糊几个等宽方块上去，内容一加载完，布局哗地一变，那跳动感跟不做骨架屏没啥区别，对吧。

**4. 抽成公共组件，别每页手写一份**

我一开始是在列表页里直接写的，后来详情页、统计页也要用，复制了三份。改个圆角要改三个地方，扫光速度三个页面还不一样，看着特别业余。后来统一抽成 `ShimmerBlock`，所有骨架屏都拿它拼，风格立马就齐了。

顺手再抽两个组合件会更爽：

```dart
/// 一行文字骨架：宽度按百分比给，长短错落更像真内容
class ShimmerLine extends StatelessWidget {
  const ShimmerLine({super.key, this.widthFactor = 1.0});
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: const ShimmerBlock(height: 14, radius: 4),
    );
  }
}
```

**5. 一屏的骨架块数量控制一下**

骨架屏的意义是"占位"，不是"还原"。一屏摆 5~8 个卡片占位就够了，摆 30 个既没人看得见，动画又白跑。我一般直接固定渲染 6 条，简单省事。

### 小结

好啦，骨架屏扫光这点事儿就唠到这。

回头看，这篇最大的收获其实不是那段代码，而是提醒我自己一件事：**遇到报错先别急着下"这个 API 被删了"的结论**。我当时要是多花两分钟去翻一眼源码或者官方文档，就不用绕这一圈了。当然绕出来的 `stops` 平移法确实好用，也算因祸得福哈。

核心就三句话：

1. 扫光不一定非得靠 `transform`，**平移 `stops`** 一样能做，而且更好控。
2. `repeat(reverse: true)` + `AnimatedBuilder`，平滑且省性能，`dispose` 别忘。
3. 骨架屏抽成公共 `ShimmerBlock`，形状贴近真实内容，颜色对比别太冲。

最后，如果这篇小文帮各位看官省下了一个下午，希望您用发财的小手点个小赞哈！那么各位看官，您做骨架屏是自己手撸还是直接上 `shimmer` 这类现成的包呢？欢迎在评论区聊聊，我也想看看有没有更省事的路子。谢谢大家！

---

*下一篇：[D02 超长 Widget 拆分术](D02-part-extension-split.md)*

> 本文由 FungLeo 主导，Deepseek 优化校阅，转发请注明首发地址，谢谢大家！
