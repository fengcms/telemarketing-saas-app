# D03 · Flutter 两个反直觉布局坑：ListTile 水波纹 / VerticalDivider，踩坑实录，各位同学记得收藏哦！

> 作者：FungLeo ｜ 适用：Flutter 3.x
> 现象：代码怎么看都没问题，`flutter analyze` 一个警告都不报，可真机上就是"点着没反应"、"线画不出来"。

### 前言

说实话，Flutter 里最让我难受的不是报错，是**不报错**。

报错好办，复制粘贴一搜，十有八九能找到答案。最气人的是那种"代码看着完全正确、analyzer 干干净净、跑起来视觉就是不对"的坑。你盯着代码看半天，怀疑人生，最后发现是某个 Widget 的层级关系没摆对。

这篇就记两个我实打实栽过的：一个是**卡片式 `ListTile` 点下去没有水波纹**，一个是**`VerticalDivider` 放进 `Row` 里死活不显示**。这俩坑有个共同点——它们都是"约束和层级"的问题，都跟你写的业务逻辑一毛钱关系没有，而且都得真机跑起来才看得见。

### 坑一：ListTile 的水波纹，被 Container 给吃了

#### 我原来的写法

做设置页、列表页，"白底圆角卡片 + 一行 ListTile"是个特别常见的组合。我当时顺手就这么写了：

```dart
// ❌ 看着没毛病，实际有问题
Container(
  margin: const EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
  ),
  child: const ListTile(title: Text('设置项')),
);
```

卡片是出来了，圆角也有了，白底也有了。但点下去——**没有水波纹**。手指按上去屏幕跟死了一样，完全没有"我点到了"的反馈。而且控制台还会给你甩一条大意如下的提示：

```
ListTile background color or ink splashes may be invisible
```

#### 为什么

这里得说说 Flutter 的水波纹（Ink splash）是怎么画的。

`ListTile` 也好、`InkWell` 也好，**水波纹并不是画在它们自己身上的，而是画在离它最近的那个 `Material` 祖先身上**。你可以理解成：Material 是一块画布，水波纹这层"墨水"是泼在这块画布上的。

那问题来了。我上面那个 `Container` 带了 `decoration`，它内部其实会生成一个 `DecoratedBox`，而这个 `DecoratedBox` 在绘制顺序上，是**盖在 Material 这块画布上面的**。

于是就出现了这么个局面：墨水确实泼出去了，泼在下面那层 Material 上了，但被我这个不透明的白色 `DecoratedBox` 严严实实地挡住了。**水波纹画了，你看不见。**

Flutter 觉得这大概率不是你想要的效果，就好心给你提示了一下。说实话这个提示挺善良的，只是我当时没往层级上想，还以为是 `ListTile` 需要额外开什么开关。

#### 修法：让 Material 自己去当那张"卡片"

思路很直白：**既然是 decoration 挡住了 Material，那就别用 decoration 画背景，让 Material 自己把背景和圆角一起画了。**

```dart
// ✅ 正确：Material 自己出背景 + 圆角
Container(
  margin: const EdgeInsets.all(8), // Container 只管外边距，不碰 decoration
  child: Material(
    type: MaterialType.card,
    color: Colors.white,
    elevation: 0,
    // 圆角交给 Material，水波纹会跟着这个 shape 一起裁剪
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    clipBehavior: Clip.antiAlias,
    child: const ListTile(title: Text('设置项')),
  ),
);
```

这么一改，水波纹立马就回来了，而且**是带圆角裁剪的**——`shape` 给了 Material，水波纹扩散到边界就被切住，不会溢出圆角变成个方块。这个细节挺重要，我见过不少人用 `ClipRRect` 在外面硬裁，效果是能出来，但多套一层裁剪，性能上不太划算。

顺带说几个等价或相关的写法，各位看官按场景挑：

- 直接用 `Card`：`Card` 本身就是 `Material` 的封装，懒得配就用它，记得设 `clipBehavior: Clip.antiAlias`。
- 想保留 `decoration` 的写法（比如要渐变背景、要边框）：把 `Container(decoration:)` 换成 **`Ink(decoration:)`**。`Ink` 这个 Widget 就是专门为了解决这个问题存在的——它会把 decoration 画到 Material 那层上去，水波纹就能盖在它上面了。
- 如果只是要个可点击区域，不需要 `ListTile` 那套布局，`Material` + `InkWell` 组合更轻。

> 提醒一句：`Ink` 也有它的脾气，它要求自己必须在 `Material` 里面，而且不能给它设 `width/height` 之外的奇怪约束，否则一样会 assert。这块各位看官用的时候留个心眼。

### 坑二：VerticalDivider 在 Row 里死活不显示

#### 我原来的写法

需求也简单：一行里放两块内容，中间来根竖线隔开。我理所当然地这么写：

```dart
// ❌ 经常什么都看不见
Row(
  children: const [
    Expanded(child: Text('A')),
    VerticalDivider(),   // 说好的竖线呢？
    Expanded(child: Text('B')),
  ],
)
```

跑起来，A 和 B 都在，中间那根线**根本不存在**。我第一反应是颜色问题，把 `color` 手动设成红色，还是没有。再把 `thickness` 调到 5，依然没有。这时候我才意识到：它不是"看不清"，它是**高度为 0**。

#### 为什么

`VerticalDivider` 内部是希望自己"撑满可用高度"的，它给自己要的高度约束是 `double.infinity`。

而 `Row` 在交叉轴（也就是纵向）上，默认是 `CrossAxisAlignment.center`，它给孩子的高度约束是**松约束**（loose，也就是 `0 <= height <= 父级给的最大高度`）。如果这个 `Row` 本身又处在一个高度不确定的环境里（比如放在 `Column` 里、放在可滚动区域里），那 Row 的高度其实是由"最高的那个孩子"决定的。

于是就死循环了：分隔线问"我能有多高"，Row 说"你自己定"，分隔线要无穷高，最后被约束成——**0**。

线在，只是高度是 0，所以你怎么调颜色、调粗细都没用。

#### 两个修法

**方案 A：固定高度的 `SizedBox` + 1px 容器（我常用这个）**

```dart
// ✅ 最稳，高度完全可控
Row(
  children: [
    const Expanded(child: Text('A')),
    SizedBox(
      height: 28, // 明确给个高度，别再让它自己猜
      child: Container(width: 1, color: BrandColors.line),
    ),
    const Expanded(child: Text('B')),
  ],
)
```

**方案 B：用 `IntrinsicHeight` 包住 Row**

```dart
// ✅ 让 Row 先算出"最高孩子的高度"，再把这个高度给分隔线
IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch, // 关键：让孩子纵向撑满
    children: const [
      Expanded(child: Text('A')),
      VerticalDivider(width: 16, thickness: 1),
      Expanded(child: Text('B')),
    ],
  ),
)
```

怎么选？我的建议是**优先方案 A**。

原因有两个。一是视觉上更好看——分隔线跟内容一样高，两头顶格，其实是有点丑的，留点余量（比如内容高 40，线高 28）观感更舒服。二是性能——`IntrinsicHeight` 需要额外做一次布局测量来求"最高的孩子有多高"，官方文档也明说了它相对比较费，放在长列表的 item 里成百上千地用，不太划算。

方案 B 的优势是"自适应"，内容变高线跟着变高，做那种左右两栏高度不定的卡片挺合适。**够用就好，看场景挑。**

### 还有几个同一家族的坑，一并说了

既然聊到"约束和层级"，我把同类型踩过的再补几个，都是 analyzer 查不出来的：

**1. `Divider` 的 `height` 不是线的粗细**

这个太多人搞错了。`Divider` 默认 `height` 是 **16**，`VerticalDivider` 默认 `width` 也是 **16**——这个值是**整体占位**，线只是画在这块占位区域的正中间。真正控制线粗细的是 `thickness`。

所以如果你发现"加了根分隔线，上下间距莫名其妙变大了"，就是这么来的：

```dart
// 只要线，不要额外间距
const Divider(height: 1, thickness: 1);
```

**2. `Row` 里直接放 `Text` / `TextField`，一长就溢出**

`Row` 在主轴上给孩子的是**无限宽约束**，`Text` 就会一直往右画，然后你就看到那条经典的黄黑警戒条了。解法是拿 `Expanded` 或 `Flexible` 包一下。`TextField` 更狠，不包直接 assert 报无限宽。

**3. `Column` 里嵌 `ListView`，直接报 unbounded height**

同理，`Column` 主轴给的是无限高，`ListView` 又想撑满，冲突。解法二选一：外面套 `Expanded`（列表占满剩余空间），或者给 `ListView` 加 `shrinkWrap: true` + `physics: NeverScrollableScrollPhysics()`（列表按内容撑开，交给外层滚）。后者数据多了会有性能问题，能用 `Expanded` 就别用 `shrinkWrap`。

**4. `InkWell` 没有水波纹**

跟坑一是同一个病因。`InkWell` 上面没有 `Material` 祖先，或者被不透明背景挡住了，都会导致点了没反应。修法一样：套 `Material`，背景色交给 Material。

你看，这四个坑加上前面两个，说到底就两句话：**要么是约束没给够，要么是层级摆错了。** 想明白这两条，Flutter 布局上百分之八十的怪事儿都能自己推出来。

### 小结

好啦，这两个反直觉的布局坑就唠到这。

回头复盘，这类坑最恶心的地方在于：**它们不报错，或者报的错跟真正的原因隔着一层。** analyzer 只管语法和类型，管不了"你这个 Widget 摆的位置对不对"，所以这种问题只能靠真机跑、靠肉眼看，靠一次次踩出来的直觉。这也是为什么我一直坚持"改完 UI 必须真机实测"（这事儿我在 [G02](G02-ai-collaboration-workflow.md) 里专门唠过）。

三条经验带走：

1. `ListTile` / `InkWell` 想要"卡片感"，用 **`Material(type: card)` 出背景和圆角**，别拿 `Container(decoration)` 去糊。非要用 decoration，就换成 `Ink`。
2. 行内竖分隔线，**优先「固定高 `SizedBox` + 1px 容器」**，比 `VerticalDivider` 省心；要自适应再上 `IntrinsicHeight`。
3. `Divider` 的 `height`/`VerticalDivider` 的 `width` 是占位，`thickness` 才是线粗，别搞混。

最后，希望这篇文章能够对各位看官有所帮助，各位看官一定要多多点赞收藏，关注留言哈！要是您还踩过什么"代码没错但视觉不对"的奇葩坑，也欢迎在评论区甩出来，咱们一起长长见识。谢谢大家！

---

*上一篇：[D02 拆分术](D02-part-extension-split.md) ｜ 下一篇：[D04 吸顶分组列表](D04-sticky-grouping-list.md)*

> 本文由 FungLeo 主导，Deepseek 优化校阅，转发请注明首发地址，谢谢大家！
