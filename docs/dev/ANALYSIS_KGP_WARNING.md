# 分析：编译 APK 时的 KGP 告警

> 状态：已分析、已尝试修复、已回退到可工作基线。告警当前**重新出现但非致命**。
> 日期：2026-07-25

## 一、告警原文

```
WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP):
package_info_plus, sensors_plus, share_plus
Future versions of Flutter will fail to build if your app uses plugins that apply KGP.
```

含义：这三个插件的 `android/build.gradle` 仍在自行 `apply Kotlin Gradle Plugin`。
Flutter 正在切到 **Built-in Kotlin**（工具链内置 Kotlin，插件不再自行 apply KGP）。
当前 Flutter（3.44.7）只是**警告**；未来某版 Flutter 会把它变成**硬失败**。

## 二、根因（谁在 apply KGP）

这三个插件**全部来自 `alice`**（`alice: ^1.0.0`，开发期网络浮窗，仅 `DEV_TOOLS` 启用）：

| 插件 | 直接/传递 | alice 约束（上限） | 当前锁定 | Built-in Kotlin 版本 |
|------|-----------|------------------|----------|----------------------|
| `package_info_plus` | 直接 + alice 传递 | `^8.3.0`（<9.0.0） | 8.3.1 | 需 10.2.0+（最新 10.2.1） |
| `sensors_plus` | alice 传递 | `^6.1.1`（<7.0.0） | 6.1.2 | 需 7.1.0 |
| `share_plus` | alice 传递 | `^11.0.0`（<12.0.0） | 11.1.0 | 需 13.2.0+（最新 13.3.0） |

`alice 1.0.0` 把三者锁在「迁移版本」之下，所以单纯 `pub upgrade` 升不上去。

> 兼容性已确认：alice 对这三个插件的调用均为**稳定 API**——
> - `sensors_plus`：`accelerometerEventStream().listen(...)`（6.x/7.x 通用）
> - `share_plus`：`SharePlus.instance.share(ShareParams(...))`（7.0.0 引入的新 API，11→13 稳定，不碰被删的旧 `Share.shareFiles`）
> - `package_info_plus`：`PackageInfo.fromPlatform()` + `.version`/`.buildNumber`（10.x 兼容）

## 三、尝试过的修复 & 为什么失败

**做法**：用 `dependency_overrides` 强制定到 Built-in Kotlin 版本，并连带升级一个依赖：

```yaml
dependency_overrides:
  sensors_plus: 7.1.0          # Built-in Kotlin 自 7.1.0
  share_plus: 13.2.0           # Built-in Kotlin 自 13.2.0（先试此版，规避 13.3.0 上游编译回归）
  package_info_plus: 10.2.1    # Built-in Kotlin 自 10.2.0
dependencies:
  flutter_secure_storage: ^10.3.1  # share_plus 13.x 要求 win32 ^6，flutter_secure_storage 10.x 的 Windows 实现才支持
```

> 注：`share_plus 13.3.0` 自身 Kotlin 源码有上游打包回归（引用 `SharePlusPendingIntent`/`ShareSuccessManager` 报 Unresolved reference），故退回 13.2.0。

**结果**：

- ✅ KGP 告警**消失**（目标达成一半）。
- ❌ 但**构建失败**——这三个 Built-in Kotlin 插件的 Kotlin 源码**没被编入 app 的 classpath**：

```
android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java:49: 错误: 找不到符号
    符号: 类 PackageInfoPlugin
android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java:59: 错误: 找不到符号
    符号: 类 SensorsPlugin
android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java:64: 错误: 找不到符号
    符号: 类 SharePlusPlugin
```

**根因**：旧版插件（8.x/6.x/11.x）在自己的 `build.gradle` 里**自行 apply KGP**，其 Kotlin 能单独编译成 artifact；
强制升到的 Built-in Kotlin 版（10.x/7.x/13.x）**不再自行 apply KGP**，改由 Flutter 工具链把插件 Kotlin 源码折叠进 app 编译。
但当前项目的 Flutter Gradle 装配（`flutter-plugin-loader` 1.0.0 + Kotlin 2.3.20 + AGP 9.0.1，与 Flutter 3.44.7 模板一致）**没能把这些插件源码折叠进 app**，于是类缺失。

> 这是 **Flutter Built-in Kotlin ↔ 项目 Android Gradle 的兼容性**问题，**不是改一行 pubspec 能解决的**——它属于「Android Gradle 迁移」级别的工作。

## 四、当前状态（已回退）

- 所有改动已 `git checkout` 回退，`flutter clean` 清掉脏缓存后重新 `pub get` + 构建。
- ✅ **构建成功**（APK 60.4MB，`build/app/outputs/flutter-apk/app-release.apk`）。
- ⚠️ KGP 告警**如期重现**，但在 Flutter 3.44.7 上**非致命**（只会在未来强制该规则的 Flutter 版本才变硬失败）。
- git 工作区干净，HEAD 仍为 v0.30 基线。

## 五、真正消除告警的三种路径（待定夺）

| 方案 | 说明 | 风险/成本 |
|------|------|-----------|
| **A. 暂且接受告警** | 当前 Flutter 3.44.7 上非致命；等将来升级到强制该规则的 Flutter 版本时再处理 | 最低，零风险 |
| **B. 做 Android Gradle 迁移** | 用 Flutter 3.44 模板重新生成 `android/` Gradle 文件，再重新套用我们的自定义配置（coreLibraryDesugaring、namespace 等），使 Built-in Kotlin 插件能被正确编译 | 较大、较危险，建议作为独立任务专门做并充分测试 |
| **C. 替换 `alice`** | `alice` 是这三个插件的来源（开发期网络浮窗）。换成不拉入旧 KGP 插件的替代方案，从根上消除告警 | 中等；alice 已通过 `DEV_TOOLS` 开关、`AliceDioAdapter`、`showInspector()` 深度集成，替换需重新接 Dio 拦截与浮窗 |

**建议**：当前告警不阻塞任何功能，方案 A 最稳；若想彻底消除，推荐方案 C（从来源解决）或方案 B（完整迁移），二者均为独立任务，需单独排期与真机验证。
