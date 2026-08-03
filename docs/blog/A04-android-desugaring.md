# A04 · Flutter Android 构建报错？core library desugaring 必修项排查实录，各位同学记得收藏哦！

> 作者：FungLeo ｜ 适用：Flutter / Android / Gradle
> 现象：加了个跟通知八竿子打不着的库，Android 构建突然就挂了，报错还看不懂。

### 前言

上一篇 [A03](A03-alice-network-debug.md) 接完调试面板，我以为这事儿就算完了。

结果一执行 `flutter build apk`，Gradle 直接给我甩了一堆红字。我当时第一反应是：不对啊，我就加了个网络日志面板，怎么 Android 侧构建都崩了？

翻了半天才反应过来——那个调试库间接依赖了 `flutter_local_notifications`，而这货需要开启 **core library desugaring**。

说实话，这类问题特别烦人：**报错信息和你刚做的事情之间，看不出任何因果关系**。你加的是 A，挂的是 B，中间还隔着一层 C。如果不知道这条规律，能在这儿卡半天。

所以这篇我就把这个"必修项"讲清楚。内容不长，但属于 Android 侧基建，各位看官配一次能省后面无数次。

### 现象：报错长什么样

这个坑的报错有好几副面孔，我见过的主要是这两类。

**第一类，AGP 直接点名要你开 desugaring：**

```
Dependency ':flutter_local_notifications' requires core library desugaring to be enabled
for :app.
See https://developer.android.com/studio/write/java8-support.html for more details.
```

这种算是仁慈的，它把答案都写脸上了，照做就行。

**第二类，只告诉你缺 Java 8 API，不告诉你为啥：**

```
e: ... requires Java 8+ API, which is not available in android.jar
```

这种就有点难受了，尤其是你还不知道是哪个依赖引起的。还有更阴间的情况：**构建能过，但运行到通知相关路径时直接崩**，那排查难度又上一个台阶。

#### 根因是啥

说白了就一句话：**有些三方库用了 Java 8 才有的 API，但老版本 Android 系统上压根没有这些类。**

典型的比如 `java.time.*`（`LocalDateTime`、`Duration` 那一套）、`java.util.function.*`、`java.util.stream.*`。这些是 Java 8 引入的，而 Android 的 `android.jar` 在低版本上是不带的。

那怎么办呢？Google 给的方案就是 **desugaring（脱糖）**——在编译期把这些新 API "翻译"成老设备也能跑的实现，顺手把兼容代码打进包里。你可以理解成编译期的 polyfill，跟前端那套 babel 的思路是一个意思，各位前端出身的看官应该秒懂。

它默认是关着的，所以你得自己开。

### 修复：两处配置

配置就两个地方，都在 `android/app/build.gradle.kts` 里。

```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true   // ← 开关在这儿
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    // 版本需 >= 2.1.4，低版本不覆盖新版 JDK 的 API
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
```

注意这俩得**成对出现**：光开开关不加依赖，构建会告诉你缺 desugar 库；光加依赖不开开关，等于白加。我第一次就只加了依赖，然后对着报错纳闷了好一会儿。

> 版本这块多提一嘴：`desugar_jdk_libs` 建议 **≥ 2.1.4**。低于这个版本，对较新的 JDK API 覆盖不全，你会遇到"明明开了 desugaring，还是报缺 API"的情况，那种时候是真的容易怀疑人生。

#### 还在用 Groovy DSL 的看官看这里

老项目如果还是 `build.gradle`（不带 `.kts`）的，语法不一样，别照抄上面那份：

```groovy
android {
    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.5'
}
```

区别就是 Kotlin DSL 里布尔属性带 `is` 前缀、赋值用 `=`、依赖用括号，Groovy 里则是空格分隔。这俩混着抄是新手翻车重灾区，各位看官看清楚自己项目用的是哪种。

#### 配置改完记得清一下

Gradle 的缓存有时候挺倔的，改完配置最好清一把再构建：

```sh
➜ flutter clean
➜ flutter pub get
➜ flutter build apk
```

如果还不行，可以再往下清一层 Gradle 的缓存：

```sh
➜ cd android && ./gradlew clean && cd ..
```

### 顺手说几个同类易踩的点

既然改到 `build.gradle.kts` 了，我把这块儿相邻的几个高频坑一起说了，都是我实打实撞过的。

**1. 位置必须在 app 模块**

`coreLibraryDesugaring` 这个依赖，要加在 **application 模块**（也就是 `android/app/build.gradle.kts`）里。加到 library 模块或者项目根目录的 `build.gradle.kts` 里，是不生效的。

**2. Java 版本前后要对齐**

如果项目里同时配了 Kotlin 的 `jvmTarget`，它得跟 `compileOptions` 里的版本保持一致，否则会报 "Inconsistent JVM-target compatibility" 之类的错：

```kotlin
android {
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()  // 保持一致
    }
}
```

这个错和 desugaring 没直接关系，但因为改的是同一个文件同一个块，特别容易在这时候一起冒出来，顺手一并处理掉。

**3. AGP 版本太老也不行**

`coreLibraryDesugaring` 需要比较新的 Android Gradle Plugin 支持。如果你是从很老的模板升上来的项目，报错可能是"找不到这个方法"，那就得先把 AGP 和 Gradle Wrapper 升上去。

**4. 报错别只看最后一行**

Gradle 的报错输出又臭又长，很多人（包括当年的我）只看最后那几行，然后一脸茫然。其实真正有用的信息经常埋在中间。实在看不出来，把 stacktrace 全打出来：

```sh
➜ flutter build apk --verbose
# 或者直接用 gradle 的详细模式
➜ cd android && ./gradlew assembleRelease --stacktrace
```

用 `--stacktrace` 跑一遍，通常能直接看到是哪个依赖在要 desugaring，比瞎猜强多了。

### 哪些库大概率需要它

给各位看官一个速查清单，遇到下面这些，可以直接先把 desugaring 开上，别等它报错：

- `flutter_local_notifications` —— 最典型的，几乎是必开；
- 各类**通知 / 定时任务**相关插件（`workmanager` 这类）；
- 部分**加密 / 证书**相关库；
- 任何在原生侧显式使用 `java.time`、`java.util.stream` 的插件。

判断方法也很朴素：**这个插件的原生实现是不是比较新、有没有用到日期时间处理**。是的话，八成跑不掉。

### 小结

好啦，这个必修项就说完了，内容确实不多，但值不值就看你有没有在它上面卡过。

我自己的复盘是这样的：这属于典型的"**加一个依赖，构建就挂，而报错还不指向根因**"的问题。技术上一点不难，两行配置搞定；难的是从那堆红字里意识到"哦，这是要开 desugaring"。这个映射关系一旦建立起来，下次三秒钟解决。

所以我现在的做法是——**直接把 desugaring 当成 Android 模块的默认基建，新项目起手就配上**。它对包体积的影响很小（就多打进去一点兼容实现），但能帮你规避掉一整类构建问题，我觉得这买卖很划算。

当然，也不是说所有项目都得这么干哈，如果你的项目依赖极简、明确不碰这些 API，那不开也没毛病，够用就好。

最后，希望这篇文章能够对各位看官有所帮助。各位看官在留言区留言可以给我加分，所以希望各位看官帮帮忙，点评一下哦！当然，我们程序开发都是很忙滴，没时间点评没关系哈，点个赞，收个藏，也不是不可以哈！小可在这边谢谢各位看官了哈！

---

*上一篇：[A03 Alice 调试浮窗](A03-alice-network-debug.md) ｜ 下一篇：[A05 Release 吞异常](A05-release-swallow-exceptions.md)*

> 本文由 FungLeo 主导，Deepseek 优化校阅，转发请注明首发地址，谢谢大家！
