# D05 · Flutter fl_chart 0.70 破坏性 API 迁移实录，duration/getTooltipColor/withValues 全解，各位同学记得收藏哦！

> 作者：FungLeo ｜ 适用：Flutter 3.x + [fl_chart](https://pub.dev/packages/fl_chart) 0.70
> 现象：`flutter pub upgrade` 之后，图表相关的代码从上到下一片红，全是"参数不存在"。

### 前言

这事儿的起因，是我例行跑了一次 `flutter pub upgrade`。

说实话我当时挺随意的，就想着把依赖顺手往上提一提，反正 Flutter 生态更新快，别落太多版本。命令跑完，控制台没红，我心情还挺好。然后打开统计页的代码文件——**IDE 给我标了满屏的红波浪线**。

`swapAnimationDuration` 没了，`tooltipBgColor` 没了，连 `withOpacity` 都在划删除线。好家伙，一个 `0.6x` 到 `0.70` 的小版本号，改动量倒是不小。

后来我才想起来，pub 上的包只要主版本号是 `0.`，按 Dart 的语义化版本规则，**次版本号的变化就允许包含破坏性改动**。也就是说 `0.69 → 0.70` 这种看着不起眼的跳跃，人家完全有权利把 API 给你改了。是我自己太想当然了。

好在改动都不复杂，改完还挺清爽。这篇就把我实际遇到的四处差异 + 一套迁移流程记下来，各位看官要升级的话，照着抄能省不少时间。

### 一、动画参数改名：swapAnimation* → duration / curve

这个是报错最多的，因为所有图表组件（Pie / Bar / Line）都有这俩参数。

```dart
// ❌ old：包在 swapAnimation 前缀里
PieChart(
  PieChartData(/* ... */),
  swapAnimationDuration: const Duration(milliseconds: 500),
  swapAnimationCurve: Curves.easeInOut,
);

// ✅ new：直接透传，名字更短更符合 Flutter 习惯
PieChart(
  PieChartData(/* ... */),
  duration: const Duration(milliseconds: 500),
  curve: Curves.easeInOut,
);
```

改名规则很简单：

- `swapAnimationDuration` → `duration`
- `swapAnimationCurve` → `curve`

这个改动我是认可的。原来那套 `swapAnimation` 前缀属于自造词，跟 Flutter 里 `AnimatedContainer` 那套 `duration` / `curve` 的惯例对不上，看着别扭。现在统一了，挺好。

**这一处可以放心用编辑器全局替换**，风险很低。

### 二、tooltip 背景色：tooltipBgColor → getTooltipColor

这个改得稍微"重"一点，从**一个固定值**变成了**一个回调函数**。

```dart
// ❌ old：一个死颜色
BarTouchTooltipData(
  tooltipBgColor: Colors.black,
);

// ✅ new：改成回调，参数是当前触摸到的数据
BarTouchTooltipData(
  getTooltipColor: (BarChartGroupData group) => Colors.black,
);
```

这里有个**容易踩的点**：不同图表类型，这个回调的**参数类型是不一样的**，别以为签名都一样闭着眼睛抄。

| 图表 | 回调签名 |
|------|---------|
| 柱状图 `BarTouchTooltipData` | `Color Function(BarChartGroupData group)` |
| 折线图 `LineTouchTooltipData` | `Color Function(LineBarSpot spot)` |

我当时就是从柱状图那儿复制过来改折线图，参数类型写错了，报了个类型不匹配，愣了两秒才反应过来。各位看官改的时候留意一下。

改成回调其实是有好处的——现在你能**按数据动态决定 tooltip 的颜色**了。比如某个柱子超标了，tooltip 给个红底：

```dart
BarTouchTooltipData(
  getTooltipColor: (group) {
    // 拿到当前柱子的值，按阈值给不同背景色
    final value = group.barRods.first.toY;
    return value > 100 ? Colors.red.shade700 : Colors.black87;
  },
);
```

以前想做这个效果得自己绕一大圈，现在一行就完了，这波不亏。

### 三、withOpacity → withValues(alpha:)

这条严格说不是 fl_chart 的锅，是 **Flutter 框架本身**的改动，但升级的时候一定会一块儿撞上，所以放这儿一起讲。

Flutter 3.27 之后，`Color.withOpacity()` 被标记为 deprecated，推荐改用 `withValues()`：

```dart
// ❌ old
color: someColor.withOpacity(0.2);

// ✅ new
color: someColor.withValues(alpha: 0.2);
```

为什么要改？因为 Flutter 在往**宽色域（wide gamut）**上走，颜色通道内部从 0~255 的整数改成了 0~1 的浮点数。老的 `withOpacity` 走的是整数通道，会有精度损失；`withValues` 是新的浮点接口，`alpha` 同样接收 0.0~1.0，含义和原来一致，**换个名字直接用就行**。

顺带一提，同一批被 deprecated 的还有 `.red` / `.green` / `.blue` / `.opacity` 这几个 int 取值器，对应换成 `.r` / `.g` / `.b` / `.a`（都是 0~1 的 double）。如果你代码里有手动拆颜色通道的地方，也一并改了吧。

`withOpacity` 目前只是 deprecated，还没删，所以不改也能编译过，就是 analyzer 一直给你念叨。我建议还是趁这次一起收拾干净，别攒着。

### 四、饼图实心 + "总数为 0" 的兜底

这一条不是 API 变更，是我在迁移过程中顺手修掉的一个**真·线上问题**，价值可能比上面三条还大。

先看正常写法：

```dart
PieChart(
  PieChartData(
    sections: [
      PieChartSectionData(value: done.toDouble(), color: BrandColors.primary),
      PieChartSectionData(value: (total - done).toDouble(), color: BrandColors.line),
    ],
    centerSpaceRadius: 0,   // 0 = 实心饼图；给个正数就变成环形图
    startDegreeOffset: -90, // 从 12 点钟方向起笔，符合阅读习惯
  ),
)
```

看着没毛病对吧。但**当 `total == 0` 的时候**，两个扇区的 value 全是 0，饼图要按比例算每个扇区占多少度，分母是 0——轻则整个图空白啥也不画，重则内部算角度时直接给你算出个 `NaN` 来。

我这个页面就是新用户进来没有任何数据时，统计页白了一块，看着像加载失败。

修法很土但很有效：**兜底一个非零扇区**。

```dart
PieChart(
  PieChartData(
    sections: total == 0
        // 没数据时，画一个完整的灰圆占位，别让它空着
        ? [PieChartSectionData(value: 1, color: BrandColors.textDisabled)]
        : [
            PieChartSectionData(value: done.toDouble(), color: BrandColors.primary),
            PieChartSectionData(value: (total - done).toDouble(), color: BrandColors.line),
          ],
    centerSpaceRadius: 0,
    startDegreeOffset: -90,
  ),
)
```

**凡是"按比例分配"的图表，都要过一遍分母为 0 的场景**。饼图、环图、进度环、堆叠柱状图，一个都跑不了。这个我建议直接写进你自己的 checklist 里。

### 五、我的迁移流程，五步走

改完之后我总结了一套流程，下次再遇到破坏性升级照着走就行：

**第一步：先看 changelog，别急着改代码**

```sh
# 直接去 pub 上翻，或者本地看
➜ open https://pub.dev/packages/fl_chart/changelog
```

花五分钟通读一遍，心里对"这次改了哪些大块"有个数。我一开始就是没看，闷头一个一个报错去改，改到第三个才发现原来官方 changelog 里全列着呢，白折腾。

**第二步：锁版本，别用 `any`**

```yaml
dependencies:
  # 明确写死大版本，避免下次 pub upgrade 又给你偷偷跳上去
  fl_chart: ^0.70.0
```

对于这种 `0.x` 版本、次版本号就敢带破坏性改动的包，我现在的习惯是**看得紧一点**，不给它自由发挥的空间。

**第三步：跑 analyze，把红点一次性列出来**

```sh
➜ flutter analyze
```

别靠 IDE 一个文件一个文件翻，直接一把梭列出全部问题，改起来有数得多。

**第四步：能自动修的先自动修**

```sh
# withOpacity 这类框架级 deprecated，官方 fix 工具能直接改掉一批
➜ dart fix --dry-run   # 先看看它想改什么
➜ dart fix --apply     # 确认没问题再执行
```

`dart fix` 对框架自身的 deprecated API 挺好使，对三方包的改名就无能为力了，那部分还得手动来。

**第五步：真机跑一遍，别只看编译过了**

这条最重要。编译通过 ≠ 效果对。像 tooltip 颜色回调这种，参数类型改了但逻辑写错了，编译器可能不吭声，得你手指头点上去才知道对不对。图表的动画、触摸交互，都得真机上手摸一遍。

**另外补一句关于封装的**：我这次改起来相对轻松，是因为图表都抽成了公共组件（比如一个 `RatioPieChart`），fl_chart 的 API 只在那几个文件里出现。要是二十个页面里到处都直接 `PieChart(...)`，这次升级够我改一天的。

**三方 UI 库尽量包一层再用**，这是我这些年最认的一条经验之一。多写十行封装，换的是升级时的一整天。

### 小结

好啦，fl_chart 0.70 的迁移就记录到这儿。

复盘一下，这次升级本身不难，四个改动点半小时就改完了。真正值钱的是三个认知：

1. **`0.x` 版本的包，次版本号变化就可能是破坏性的**，升级前先看 changelog，这不是可选动作。
2. **`duration/curve`、`getTooltipColor`、`.withValues(alpha:)`** 是这次的三个高频改动，前两个是 fl_chart 的，第三个是 Flutter 框架的，会一起撞上。
3. **三方库包一层再用**，把 API 变更的影响面锁在几个文件里，比什么迁移技巧都管用。

另外那个"总数为 0 兜底"的坑，虽然跟升级没关系，但真心建议各位看官回头去自己项目里翻一翻，这类边界问题平时测不出来，一上线遇到新用户就露馅。

最后，如果本文对你有所增益，希望看官您用发财的小手点个小赞哈！要是您在升级 fl_chart 时还撞上了别的坑，欢迎在评论区补充，让后来的同学少走点弯路。谢谢大家！

---

*上一篇：[D04 吸顶分组列表](D04-sticky-grouping-list.md) ｜ 返回 [内容规划](./00-内容规划.md)*

> 本文由 FungLeo 主导，Deepseek 优化校阅，转发请注明首发地址，谢谢大家！
