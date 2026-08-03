# E02 · Flutter Web 中文字体困境与渲染器选择，CanvasKit vs HTML renderer 实战，各位同学记得收藏哦！

> 作者：FungLeo ｜ 适用：Flutter / Web
> 现象：Flutter Web 默认 CanvasKit 渲染器从 `gstatic` CDN 拉 `Noto Sans SC`，弱网超时，中文回退成方块。

### 前言

说实话，Flutter Web 这玩意儿，中文字体这块真是个老大难。我刚把项目跑上 Web 的时候，满心欢喜打开页面，结果中文全成了方块，控制台刷 `Could not find a set of Noto fonts`——当场给我整懵了。

这事儿的根子，是 Flutter Web 默认用 **CanvasKit** 渲染器，它会从 Google 的 `gstatic` CDN 去拉 `Noto Sans SC` 中文字体。国内 / 弱网环境下，这个请求动不动就超时，字体没加载出来，中文就回退成方块。各位看官，这坑不深，但特别影响体验，今天就把它讲透，顺便聊聊渲染器到底怎么选。

### 问题一：gstatic 拉取超时

```sh
fonts.gstatic.com/notosanssc/...woff2 net::ERR_TIMED_OUT
Could not find a set of Noto fonts...
```

CanvasKit 模式下，Flutter 引擎需要完整的字体文件才能渲染文本。默认走 CDN，国内 / 弱网环境下极易超时。现象就是你看到中文方块，控制台刷上面那两行。

#### 解法 A：本地化字体（彻底脱离 CDN）

把 Noto Sans SC 下载到 `assets/fonts/`，在 `pubspec.yaml` 声明，从此不再依赖外网：

```yaml
flutter:
  fonts:
    - family: Noto Sans SC
      fonts:
        - asset: assets/fonts/NotoSansSC-Regular.otf
```

代价：中文字体文件很大（几 MB+），会显著增大 Web 产物体积。

#### 解法 B：切到 HTML 渲染器，用系统字体

```bash
➜  my_app flutter run -d chrome --web-renderer html
```

HTML 渲染器走浏览器原生文本渲染，**直接用系统字体**（Mac 上就是苹方），不拉 CDN，零字体文件体积。

> 我本地调试就走这条：Mac 上 `--web-renderer html` 直接吃系统苹方，又快又清晰，验证业务逻辑一点不耽误。

### 问题二：苹方（PingFang）的授权边界

很多人想"打包苹方"做统一字体，但这有个**法律红线**，绕不开：

- 苹方是 **Apple 专有字体**，**禁止提取 / 打包 / 再分发**。
- 仅能在 Apple 平台随系统使用（iOS 默认已用苹方，Mac 上 Web 走系统字体合法）。
- Android / 非苹果设备的 Web，**不能打包苹方**，必须用语开源字体（思源黑体 / Noto 本地化）。

### 渲染器怎么选

| 场景 | 推荐渲染器 | 字体策略 |
|------|-----------|---------|
| 本地调试（Mac） | `html` | 系统苹方，快 |
| 正式 Web（非苹果设备） | `canvaskit` | 本地化思源黑体 / Noto |
| 需要精确像素一致 | `canvaskit` | 本地化字体 |

好啦，选型逻辑就这三行，够用就好，别过度折腾。

### 小结

回头复盘一句话：CanvasKit 默认从 `gstatic` 拉中文字体，弱网必超时，要么本地化字体、要么切 HTML 渲染器用系统字体；而苹方是 Apple 专有字体，绝不可打包再分发，跨平台部署务必用语开源字体。

各位看官记住：渲染器选择本质是「体积 / 一致性 / 字体可用性」的权衡，没有一刀切对吧！正式发包别偷懒沿用本地调试那套 HTML 渲染器，该本地化字体就本地化，免得线上中文又变方块。

最后，希望这篇文章能够对各位看官有所帮助，各位看官一定要多多点赞收藏，关注留言哈！谢谢大家！

> 本文由 FungLeo 主导，Deepseek 优化校阅，转发请注明首发地址，谢谢大家！

*上一篇：[E01 Web token 存储](E01-web-token-storage.md) ｜ 返回 [内容规划](./00-内容规划.md)*
