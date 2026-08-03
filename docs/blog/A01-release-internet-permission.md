# A01 · Flutter/Android Release 包连不上网？AndroidManifest INTERNET 权限排查实录，各位同学记得收藏哦！

> 作者：FungLeo ｜ 适用：Flutter / Android
> 现象：本地 `flutter run` 一切正常，可一旦 `flutter build apk`（release）装到真机，所有接口全部"网络连接失败"。

### 前言

说实话，这个坑我踩得挺丢人的。

事情是这样的：我本地用 `flutter run` 跑得好好的，接口一个一个都通，心想这项目稳了，就打了个 release 包发给测试。结果测试同学回我一句："你这 app 是不是没网啊？所有页面都转圈圈。"

我当时就懵了。代码一行没动，debug 明明好好的，怎么一打包就不行了？

于是我开启了漫长的排查之路——先是怀疑 DNS 解析有问题，然后又想是不是 IPv6 的锅，再后来甚至开始怀疑是不是哪个三方插件在 release 模式下把网络栈给污染了。各种抓包、换网络、清缓存，折腾了大半天，最后发现……

就特么一行权限的事儿。

所以今天我把这个坑写出来，希望各位看官别像我一样，在一个这么基础的地方浪费大半天。

### 根因：debug 清单自带权限，release 不自带

要搞明白，得先说清楚 Flutter 工程在 `android/app/src/` 下那三个清单目录。

```sh
android/app/src/
├── main/AndroidManifest.xml      # 主清单（release 只合并它）
├── debug/AndroidManifest.xml     # debug 构建时合并
└── profile/AndroidManifest.xml   # profile 构建时合并
```

Flutter 官方模板，在 **debug / profile** 的清单里，默认就给咱们写好了这么一行：

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

而 **`src/main` 的主清单，默认是不带这一行的**。

这就埋下了雷。release 构建的时候，系统只合并 `main` 这一个清单，debug / profile 里那行权限压根不会被带进去。于是最终打出来的包里，**没有联网权限**。Android 系统看到没有 `INTERNET` 权限，直接就把所有 Dio 请求给拒了，表现到界面上，就是一片"网络连接失败"。

debug 为什么一直能连？因为它借着 debug 清单里那行权限的东风。你以为是你代码写得好，其实是对方送的。

> 这就是为什么"debug 永远能连、release 全版本都不行"，而且和你的任何代码改动都没关系。这个坑最恶心的地方就在这：它披着"网络问题"的外衣，骗你去翻网络层，实际上根子压根不在那。

### 我是怎么一步步排查的

既然说到这了，我也跟各位看官唠唠我当时那段"弯路"，免得你们再走一遍。

1. **先看报错日志**。release 模式下 Dart 的异常是不抛红屏的（这个后面 [A05](A05-release-swallow-exceptions.md) 会专门讲），所以控制台干干净净，啥有用的都没有。这就更让人往"环境问题"上想了。
2. **怀疑 DNS / IPv6**。换了手机热点、切了 4G、甚至把域名换成 IP 直连，结果都一样。基本排除。
3. **怀疑三方库**。项目里用了好几个网络相关的插件，挨个注释掉试，还是连不上。这时候其实已经该警惕"是不是请求根本没发出去"了。
4. **最后查清单**。随便写了个最小 demo 比对，才发现 release 包里压根没有 `INTERNET` 权限这个声明。

你看，绕了一大圈，真正的元凶就静静躺在 `src/main/AndroidManifest.xml` 里，等着我去发现。

### 修复：在主清单显式声明

办法简单得让人想笑。在 `android/app/src/main/AndroidManifest.xml` 的 `<manifest>` 根节点下，和其他 `<uses-permission>` 并列，把那行补上：

```xml
<manifest ...>
    <!-- 原来的权限 -->
    <uses-permission android:name="android.permission.INTERNET" />
    <!-- 其他已有权限 -->
</manifest>
```

然后老规矩，清一下重新打：

```sh
# 清理构建缓存，避免旧清单被沿用
flutter clean
# 重新打 release 包
flutter build apk
```

装到真机上，接口唰唰就通了。那一刻我心情很复杂——既想骂街，又想笑。

### 还有哪些权限也容易踩这个坑

其实不止 `INTERNET` 一个。凡是你**只在 debug 清单里见过、main 清单里没写**的权限，release 都会丢。常见的几个：

- `android.permission.INTERNET` —— 联网，最基础的，必加。
- `android.permission.ACCESS_NETWORK_STATE` —— 如果你代码里要判断网络类型（WiFi / 移动数据），这个也得进 `main`，否则 release 下一样歇菜。
- 其他如打电话、定位、存储之类的敏感权限，模板默认也不会给你塞进 `main`，该声明声明。

一句话：**release 需要的权限，一律写进 `src/main`，别去指望 debug 清单替你兜底。**

### 小结

好啦，这个坑的故事就讲到这。

回头看，它就是个"清单合并默认行为差异"导致的排查盲区：debug 清单自带权限、main 清单不带，release 只认 main，于是联网功能在 release 下凭空消失。最坑的是它伪装成网络问题，让你去翻根本没问题的网络层代码。

各位看官记住一句话就行：**遇到"只有 release 才出现的联网问题"，第一反应查清单权限，别一上来就怀疑人生。**

最后，如果这篇小文帮你省下了大半天折腾的时间，希望看官您用发财的小手点个小赞哈！要是你也被这个坑打过脸，欢迎在评论区吐槽，让更多同学看到，少走弯路。谢谢大家！

> 本文由 FungLeo 主导，Deepseek 优化校阅，转发请注明首发地址，谢谢大家！。
