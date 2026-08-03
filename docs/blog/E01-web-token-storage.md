# E01 · Flutter Web token 存储陷阱，crypto.subtle 非安全上下文失效排查实录，必看！

> 作者：FungLeo ｜ 适用：Flutter / Web
> 现象：登录（public 接口）正常，但登录后所有带 token 的接口都不发请求；只在 HTTP + 非 localhost 的"非安全上下文"下才暴露。

### 前言

说实话，这个坑我是在一个跨端项目里踩的。我们那个项目，Android 原生和 Web 端同一套代码，token 这事儿我本想"一套通吃"。

原生端我用 `flutter_secure_storage`（Keystore / Keychain），一直稳得一批。我就寻思，Web 端也用它得了，省事。结果一跑 Web，登录能进，登录之后所有带 token 的接口全灭——页面转圈圈，控制台还给你刷 `Selected call is null` 这种迷惑噪声，真正的错被静默吞了。

我当时就纳闷了：登录明明是 public 接口好好的，怎么一带上 token 就全挂？各位看官，这就是典型的"只在非安全上下文才暴露"的坑，我折腾了大半天才定位到。今天把它写出来，希望您别再走一遍我的弯路。

### 现象：登录能，其它全挂

Web 端登录（public 接口）正常，但登录后所有带 token 的接口都不发请求。控制台有 `Selected call is null` 之类噪声，但真正的错误被静默吞了——一眼看过去，根本不知道是哪一步炸了。

### 根因：crypto.subtle 在非 HTTPS 下是 undefined

`flutter_secure_storage_web` 1.2.x 的 `read` 走 **AES-GCM 解密**，强依赖 `window.crypto.subtle`。

- `window.crypto.subtle` 只在**安全上下文**（HTTPS 或 `localhost`）可用。
- 如果 dev server 用 **HTTP、且不是 localhost**（比如局域网 IP `http://192.168.x.x:端口`），就是非安全上下文 → `crypto.subtle` 为 `undefined` → `read` 抛异常。
- 而登录是 public 接口、拦截器里提前 return 不碰 token 存储，所以只有**带 token 的请求**才崩 → 表现成"登录能、其它全挂"。

这意味着：**Web 端的 token 根本没成功持久化过**，每次刷新页面都要重新登录。

> 这就是为什么"登录能、其它全挂"——根子不在网络层，也不在你的请求代码，而在 token 读取那一下就炸了，而且只在 HTTP + 局域网 IP 这种非安全上下文下才炸。这个坑最恶心的地方，是它披着"网络问题"的外衣骗你去翻请求层，实际上根子压根不在那。

### 我是怎么一步步排查的

既然踩了坑，我也跟各位看官唠唠当时的弯路，免得你们再绕一遍。

1. **先看控制台**。满屏 `Selected call is null`，但 Dart 层没红屏、没明确异常（Web 下异常也容易被吞，这块后面 [A05](A05-release-swallow-exceptions.md) 会专门讲），一眼望过去根本不知道哪炸的。
2. **怀疑拦截器逻辑写错**。把鉴权 header 那一段注释掉，请求照样发不出去——才意识到不是"加 header"的问题，是"读 token"那一步就挂了。
3. **怀疑 flutter_secure_storage 不支持 Web**。去翻源码，发现 1.2.x 的 web 实现走 AES-GCM 解密，而解密强依赖 `window.crypto.subtle`。
4. **最后查上下文**。把 dev server 从局域网 IP 的 HTTP 换成 `localhost` 再跑，问题消失。回头一看——哦，原来是 `crypto.subtle` 在非安全上下文里是 `undefined`。

你看，绕了一大圈，元凶就是"这个环境下压根没有 `crypto.subtle`"这件小事。

### 修复：Web 走 shared_preferences 分流

办法是分平台实现：Web 端干脆不碰 crypto，直接用 `shared_preferences` 落 localStorage。

```dart
// lib/services/token_storage.dart
Future<String?> readToken() async {
  if (kIsWeb) {
    // Web：localStorage，无 crypto 依赖，兼容非安全上下文
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_key);
  }
  // 原生：Keystore / Keychain
  final storage = FlutterSecureStorage();
  return storage.read(key: _key);
}
```

同时在 token 读取处加 try/catch，读取失败只降级为"不带鉴权发出"，不再中止请求（避免再次静默失败）：

```dart
// lib/core/api_client.dart token 拦截器
try {
  final token = await tokenStorage.readToken();
  if (token != null) options.headers?['Authorization'] = 'Bearer $token';
} catch (e) {
  debugPrint('[API][TOKEN-ERR] $e'); // 常驻打印，保留可观测性
}
```

### 安全权衡

- Web 用 `shared_preferences` = **明文 localStorage**，弱于 Keystore。
- 仅适合调试 / 内测。正式 Web 发布需评估：HTTPS + 短期 token + refresh 兜底，或后端 `httpOnly` Cookie。

好啦，到这里坑就填平了。

### 小结

回头看，这就是个"Web 特有的非安全上下文陷阱"：`flutter_secure_storage_web` 依赖 `crypto.subtle`，而它在 HTTP + 非 localhost 下是 `undefined`，于是 Web 端 token 读取直接炸，表现成"只有带 token 的请求才挂"。最坑的是它伪装成网络问题，骗你去翻请求层代码。

各位看官记住一句话：**Web 和原生的 token 存储，别想一套通吃，得分平台实现；遇到"登录能、其它全挂"，第一反应确认 dev server 是不是 HTTPS / localhost，别一上来就怀疑人生对吧！**

最后，如果这篇文章帮你省下了大半天折腾时间，希望看官您用发财的小手点个小赞哈！要是你也被这个坑打过脸，欢迎在评论区吐槽，让更多同学看到，少走弯路。谢谢大家！

> 本文由 FungLeo 主导，Deepseek 优化校阅，转发请注明首发地址，谢谢大家！

*下一篇：[E02 Web 中文字体困境](E02-web-chinese-fonts.md)*
