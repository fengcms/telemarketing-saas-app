# D02 · Flutter 超长 StatefulWidget 拆分术，part of + extension on State 实战全记录，必看！

> 作者：FungLeo ｜ 适用：Flutter / Dart
> 场景：一个表单页 `StatefulWidget` 写到 1000+ 行，想拆文件，可子组件要访问 `_dirty`、`_selectedIndex` 这些私有状态，还要调 `setState`。

### 前言

上一篇 [D01](D01-shimmer-skeleton.md) 我们把骨架屏收拾利索了，这篇聊个更让人头大的事儿：**文件太长了怎么拆**。

事情的起因是我提了个 MR，自己点开 diff 一看就脸红了——一个表单页的 `StatefulWidget`，从头到尾 1000 多行，滚轮滚半天到不了底。里面塞了十几个字段的构建逻辑、一堆校验、还有若干个弹窗。别说同事 review 了，我自己过两周回来都得重新找一遍某个字段在哪。

那就拆呗。我信心满满地开工，结果第一刀下去就卡住了：**拆出去的那部分，读不到页面的私有状态了**。

`_dirty`、`_selectedIndex` 这些字段全是 `_` 开头的，拆到新文件里就是一片红。当时我想的第一个方案是 `mixin`，结果被现实啪啪打脸；第二个方案是全部传参，写了两个字段就受不了了。最后落到 `part of` + `extension on State` 这套组合上，才算真正舒服。

这篇就把我这三次尝试完整记下来，顺带把**为什么会这样**讲清楚——这个原理搞明白了，以后类似的问题你自己就能推出答案。

### 一、根子在这：Dart 的 `_` 是「库私有」，不是「类私有」

先说结论，这是整篇文章的地基：

> **Dart 里 `_` 开头的成员，作用域是「库（library）」，不是「类」。**

这跟 Java / C# 那套 `private` 完全不是一回事。在 Dart 里：

- 同一个库里的代码，**互相都能访问对方的 `_` 私有成员**，哪怕是不同的类。
- 不同库之间，`_` 成员就是彻底看不见。

那什么叫"一个库"？默认情况下，**一个 `.dart` 文件就是一个库**。

好，那我上面为什么会踩坑就很清楚了：我把代码拆到新文件 → 新文件自成一个库 → 它当然看不见原文件里那些 `_` 开头的字段。**这跟我用 mixin 还是 extension 一点关系都没有，跟"文件分家"有关系。**

想明白这一层，解法就自然浮出来了：**别让它分家**。Dart 提供的 `part` / `part of` 指令，作用恰恰就是"把多个物理文件合并成同一个库"。

### 二、我试过的三条路

按我踩的顺序排：

**路线 1：把逻辑抽成 `mixin on State`，放到新文件**

```dart
// ❌ 单独一个文件里的 mixin，看不见 _dirty
mixin ItemFormFields on State<ItemFormContent> {
  Widget buildNoteSection() {
    return TextField(onChanged: (v) {
      _dirty = true; // 报错：Undefined name '_dirty'
    });
  }
}
```

实测直接扑街。原因上面说了——新文件是新库。当时我还以为是 `mixin on State` 这个用法本身有毛病，冤枉它了。

**路线 2：抽成顶层函数 + 参数全传进去**

```dart
// 🤔 能跑，但样板太多
Widget buildNoteSection({
  required bool dirty,
  required ValueChanged<bool> onDirtyChanged,
  required int selectedIndex,
  required ValueChanged<int> onIndexChanged,
  // ... 还有十来个
}) { /* ... */ }
```

这个是能跑的，纯函数化甚至还挺"优雅"。但实际写起来，一个字段的构建函数要传七八个参数和回调，加一个状态就得改三处签名，改到第三个我就放弃了。**为了拆文件而制造出比原来还多的代码，这不是脱裤子放屁么。**

**路线 3：`part of` + `extension on State`** ✅

这就是最后落地的方案，零样板，直接读写私有状态。

三条路对比一下：

| 做法 | 能读私有状态 | 样板量 | 要不要改类声明 |
|------|-------------|--------|---------------|
| 独立文件 mixin | ❌ | 少 | 要（`with` 一下） |
| 顶层函数传参 | ✅ | **巨多** | 不用 |
| `part of` + extension | ✅ | **零** | 不用 |

> 补一句实话：如果把 mixin **也放进 part 文件**里，它其实同样能访问私有成员——因为这时候大家又是一个库了。所以真正的关键先生是 `part`，不是 extension。之所以最后选 extension，是因为它不用去动类声明上的 `with` 列表，加一个文件、删一个文件都不牵连主文件，更省心。

### 三、上代码

**主文件 `item_form_sheet.dart`：**

```dart
import 'package:flutter/material.dart';
// ...其他 import

// part 指令要放在所有 import 之后
part 'item_form_fields.dart';

class ItemFormContent extends StatefulWidget {
  const ItemFormContent({super.key});

  @override
  State<ItemFormContent> createState() => _ItemFormContentState();
}

class _ItemFormContentState extends State<ItemFormContent> {
  int _selectedIndex = 0;
  bool _dirty = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildNoteSection(),   // 直接调，跟写在本文件里一模一样
        _buildFooterBar(),
      ],
    );
  }
}
```

**拆出去的 `item_form_fields.dart`：**

```dart
// part of 必须写在文件最顶部，前面不能有 import
part of 'item_form_sheet.dart';

// extension 里调 setState 会报 protected 警告，这行压掉
// ignore_for_file: invalid_use_of_protected_member

extension _ItemFormFields on _ItemFormContentState {
  Widget buildNoteSection() {
    return TextField(
      decoration: const InputDecoration(hintText: '备注'),
      onChanged: (v) {
        _dirty = true;   // 直接写私有字段，零样板
        setState(() {}); // 直接 setState
      },
    );
  }

  Widget _buildFooterBar() {
    return Row(
      children: [
        Text('已选：$_selectedIndex'), // 直接读私有字段
        const Spacer(),
        FilledButton(
          onPressed: _dirty ? () => Navigator.pop(context, true) : null,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
```

看到没，`_dirty`、`_selectedIndex`、`setState`、`context`，全都能直接用，**跟写在同一个文件里的体验完全一致**。1000 行的主文件，我最后拆成了"主骨架 + 字段构建 + 弹窗交互"三个文件，每个都在 300 行以内，review 的时候同事终于不骂我了。

### 四、四个前提条件，一条都不能少

这套东西好用，但门槛卡得挺死，踩错一条就编译不过。我按报错频率排了个序：

**1. `part of 'xxx.dart';` 写在 part 文件的第一行**

前面不能有 `import`，不能有别的语句，注释可以有。

**2. 主文件的 `part 'xxx.dart';` 放在所有 `import` 之后**

顺序反了会直接报错。我一开始手贱把它拖到文件最上面去了，编译器立马就不干了。

**3. part 文件里不能写自己的 `import`**

这条最容易忘。part 文件跟主文件共用同一套 import，所以你在 part 里要用什么包，**得回主文件去 import**。刚拆完那会儿我在 part 文件里习惯性敲了个 `import 'package:flutter/material.dart';`，报错信息还挺莫名其妙的，愣了一会儿才反应过来。

**4. 两个 analyzer 警告要处理掉**

```dart
// setState 是 @protected 的，在 extension 里调会被 analyzer 念叨
// ignore_for_file: invalid_use_of_protected_member
```

还有一个：如果 extension 里某个 **public** 函数的返回值类型是库私有类型（`_` 开头的类），会触发 `library_private_types_in_public_api`。解法很简单，把这个函数也改成库私有的（前面加 `_`）就行了，反正它本来也只在库内部用。

### 五、拆到什么粒度合适？

技术问题解决了，聊点手艺上的事儿。我自己摸出来的几条：

- **按「职责」拆，别按「行数」机械切**。看到 1000 行就一刀切成两个 500 行，那是自欺欺人，下次改代码你还是得两个文件来回跳。我一般拆成：主文件放 `build` 骨架 + 生命周期 + 状态字段；`_fields.dart` 放各个表单项的构建；`_actions.dart` 放提交、校验、弹窗这类交互。
- **命名带上主文件前缀**，`item_form_sheet.dart` / `item_form_fields.dart` / `item_form_actions.dart`，一眼看出是一家人，文件树里也自动挨在一起。
- **状态字段统统留在主文件**，别分散到各个 part 里去。虽然技术上分散也能跑，但那样你就再也说不清"这个页面到底有多少状态"了。
- **拆完记得复核**：

```sh
# 先过静态检查，part 相关的报错都在这一步暴露
➜ flutter analyze

# 再数一下行数，看看有没有哪个文件又偷偷胖起来了
➜ wc -l lib/pages/item_form/*.dart
```

这套拆法配合"单文件行数红线"（见 [G01](G01-style-guide-hard-rules.md)）用，效果最好——红线负责"提醒你该拆了"，这套手法负责"让你拆得动"。

最后提个醒：**这不是让你把所有大文件都这么拆**。如果一段 UI 本身就是可复用的、不依赖页面私有状态，那老老实实抽成独立的 `StatelessWidget` 才是正解，那玩意儿能复用、能单测、能热重载得更快。`part` + `extension` 是给"强耦合于页面状态、拆不干净"的那部分兜底用的，别拿着锤子看啥都像钉子哈。

### 小结

好啦，超长 `StatefulWidget` 的拆分就聊到这。

复盘一下，这次踩坑真正的价值不在于记住 `part of` 这个语法，而是把 **「Dart 的 `_` 是库私有，一个文件默认就是一个库」** 这条规则给刻进脑子里了。想通了这个，`part` 为什么能解决问题、mixin 为什么"看起来不行"，全都串起来了。

三句话带走：

1. 拆超长 `StatefulWidget`，**首选 `part of` + `extension on State`**，读写私有状态零样板。
2. 别冤枉 `mixin on State`，它不是不行，是**跨文件（跨库）不行**。
3. 四个前提条件卡得死：part of 在首行、part 指令在 import 后、part 文件不写 import、两个警告记得压。

最后，希望这篇文章能够对各位看官有所帮助。那么各位看官，您平时拆超长页面用的是什么套路？是抽 Widget、上状态管理，还是也在用 part 这一招？欢迎在留言区交流，一定要多多点赞收藏，关注留言哈！谢谢大家！

---

*上一篇：[D01 Shimmer 骨架屏](D01-shimmer-skeleton.md) ｜ 下一篇：[D03 布局反直觉坑](D03-layout-pitfalls.md)*

> 本文由 FungLeo 主导，Deepseek 优化校阅，转发请注明首发地址，谢谢大家！
