# 电销工作台 APP — 开发踩坑记录

> 本文档记录开发过程中遇到的各种问题及解决方案，供后续开发者参考。
> 版本：v1.0（2026-07-22）

---

## 目录

1. [环境搭建坑点](#1-环境搭建坑点)
2. [TDesign Flutter 兼容性坑点](#2-tdesign-flutter-兼容性坑点)
3. [Android 构建坑点](#3-android-构建坑点)
4. [真机渲染坑点](#4-真机渲染坑点)
5. [UI 交互坑点](#5-ui-交互坑点)
6. [已知待解决问题](#6-已知待解决问题)

---

## 1. 环境搭建坑点

### 1.1 Java JDK 安装需要 sudo 权限

**现象**：`brew install --cask temurin` 安装 JDK 时，`installer` 命令需要 sudo 权限，在某些自动化工环境中无法执行。

**解决方案**：用户在自己的终端中手动执行 `brew install --cask temurin`，输入系统密码完成安装。

**影响**：无。JDK 安装完成后即可正常使用。

---

### 1.2 Android Build Tools 36.0.0 损坏

**现象**：首次 Gradle 构建时报错：

```
Installed Build Tools revision 36.0.0 is corrupted. Remove and install again using the SDK Manager.
```

查看 `~/Library/Android/sdk/build-tools/36.0.0/` 目录后发现文件不完整，缺少 `aapt`、`d8`、`aidl` 等核心工具。

**原因**：初始的 SDK Manager 下载被中断，导致 build-tools 下载不完整。

**解决方案**：

```bash
rm -rf ~/Library/Android/sdk/build-tools/36.0.0
sdkmanager "build-tools;36.0.0"
```

**预防**：首次安装 Android SDK 组件时确保网络稳定，避免下载中断。

---

### 1.3 Gradle 首次构建耗时过长

**现象**：首次 `flutter run` 时 Gradle 构建耗时 1-5 分钟。

**原因**：首次构建需要：
- 下载 Gradle 发行版（~150MB）
- 下载 Android NDK（~1GB）
- 下载 Maven 依赖包
- Kotlin 编译缓存

**解决方案**：耐心等待首次构建完成。后续构建仅需 5-10 秒（增量编译）。

---

## 2. TDesign Flutter 兼容性坑点

### 2.1 `_TDIconsData extends IconData` — Dart 3.12 不兼容

**严重级别**：🔴 **阻断性（P0）**

**现象**：Web/Android 构建均报错：

```
Error: The class 'IconData' can't be extended outside of its library because it's a final class.
class _TDIconsData extends IconData {
```

**原因**：`tdesign_flutter 0.2.7` 内部的 `td_icons.dart` 文件中 `_TDIconsData` 类使用 `extends IconData`，而 Dart 3.5+ 将 `IconData` 标记为 `final class`，禁止外部继承。Flutter 3.44.7 内置 Dart 3.12，受影响。

- GitHub Issue：https://github.com/Tencent/tdesign-flutter/issues/963
- 状态：**官方未修复**（截至 2026-07-22）

**解决方案**：手动修改本地 pub 缓存中的 `td_icons.dart`：

```bash
# 找到文件
find ~/.pub-cache -path "*/tdesign_flutter*/td_icons.dart"

# 操作：删除 _TDIconsData 类定义，将所有 _TDIconsData(...) 替换为 IconData(..., fontFamily: 'TDIcons', fontPackage: 'tdesign_flutter')
```

具体操作：

```bash
cd ~/.pub-cache/hosted/pub.dev/tdesign_flutter-0.2.7/lib/src/components/icon

# 1. 移除类定义（手动编辑或用 sed）
# 将 "class _TDIconsData extends IconData {" 等定义替换为直接使用 IconData
# class _TDIconsData { ... } → 直接删除

# 2. 替换所有引用
sed -i '' 's/ = _TDIconsData(/ = IconData(/g' td_icons.dart
# 然后手动补全 fontFamily 和 fontPackage 参数
```

**注意**：`flutter pub get` 不会覆盖已修改的缓存文件。但 `flutter clean` 也不会影响缓存。

**长期解决方案**：等待 TDesign Flutter 发布修复版本（≥ 0.3.0），或自行 fork 修复。

---

### 2.2 image_picker_android 嵌套类兼容性（D8 编译失败）

**严重级别**：🔴 **阻断性（P0）**

**现象**：Android 构建时报错：

```
ERROR: ...D8: Compilation of classes ...ImagePickerPlugin,
...ImagePickerPlugin$ActivityState requires its nest mates
...ImagePickerPlugin$LifeCycleObserver (unavailable)
```

**原因**：`tdesign_flutter 0.2.7` 依赖 `image_picker: 1.1.2`，后者依赖 `image_picker_android: 0.8.x`。该版本中 `LifeCycleObserver` 作为 `ImagePickerPlugin` 的内部类，在 Java 26 + AGP 9.x 的 D8 编译器中因 nestmate 访问规则无法找到。

**解决方案**：在 `pubspec.yaml` 中使用 `dependency_overrides`：

```yaml
dependency_overrides:
  image_picker_android: 0.8.13+13
```

**参考链接**：
- https://github.com/flutter/flutter/issues/65334
- https://github.com/flutter/flutter/issues/58479#issuecomment-763259817

---

### 2.3 KGP（Kotlin Gradle Plugin）兼容性警告

**严重级别**：🟡 **警告（非阻断）**

**现象**：构建时出现警告：

```
WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): package_info_plus
Future versions of Flutter will fail to build if your app uses plugins that apply KGP.
```

**原因**：`package_info_plus` 插件使用了旧版的 Kotlin Gradle Plugin 注册方式，Flutter 未来版本将不再支持。

**影响**：当前版本（Flutter 3.44.7）仅为警告，**不影响构建和运行**。

**处理建议**：关注 `package_info_plus` 更新，升级到支持 Built-in Kotlin 的版本。

---

## 3. Android 构建坑点

### 3.1 `package_info_plus` 在 Android 上的 KGP 兼容性

详见 [2.3 KGP 兼容性警告](#23-kgpkotlin-gradle-plugin兼容性警告)。

---

## 4. 真机渲染坑点

### 4.1 TDCheckbox 导致 Android 白屏

**严重级别**：🔴 **阻断性（P0）**

**现象**：APP 在真机上启动后显示空白页（白屏），Web 版正常。`flutter analyze` 无错误，APK 构建成功但启动后无任何 UI。

**原因**：`TDCheckbox` 组件（`style: TDCheckboxStyle.check`）在 Android 上渲染时抛出未捕获异常，导致 Flutter 引擎无法完成首帧渲染。由于没有错误边界，表现为静默白屏。

**解决方案**：用 Material 原生复选框替代 TDCheckbox：

```dart
// ❌ 不要使用 TDCheckbox
TDCheckbox(
  title: '保存登录邮箱',
  checked: _saveEmail,
  ...
)

// ✅ 使用 Material 图标模拟
GestureDetector(
  onTap: () => onChanged(!checked),
  child: Icon(
    checked ? Icons.check_box : Icons.check_box_outline_blank,
    ...
  ),
)
```

**教训**：第三方组件库的组件在真机上可能有不兼容问题，**必须同时在 Web 和真机上验证**。Web 正常不等于 Android 正常。

---

### 4.2 Flutter Impeller 渲染引擎

**现象**：启动日志显示 `Width is zero. 0,0`。

**说明**：这是 Impeller（Vulkan）渲染后端的已知行为，在首次布局完成前会短暂出现零尺寸。**不影响实际渲染**，属于无害日志。

**处理建议**：忽略。如果未来出现实际渲染问题，可关注 Flutter 官方关于 Impeller 的更新。

---

## 5. UI 交互坑点

### 5.1 @ 输入导致文本错乱

**严重级别**：🟠 **功能性（P1）**

**现象**：在邮箱输入框中输入 `@` 字符并选择输入法自动补全后，文本框内容出现重复/错乱（如 `eee@gmail.comeee@`）。

**原因**：最初使用两个独立的 `TextEditingController`（`_emailPrefixCtrl` 和 `_emailFullCtrl`），检测到 `@` 后通过 `setState` 切换显示不同的 TextField。但切换后键盘 IME 的焦点仍然在原输入框（已被隐藏），IME 继续往隐藏的 controller 中写入内容。

**解决方案**：改用**单一 TextField + 单一 controller**：

```dart
// 统一使用一个 TextEditingController
final TextEditingController _emailCtrl = TextEditingController();

// 监听内容变化，仅切换模式标记，不切换输入框
void _onEmailChanged() {
  final hasAt = _emailCtrl.text.contains('@');
  if (hasAt != _isFullEmailMode) {
    setState(() => _isFullEmailMode = hasAt);
  }
}

// 在 build 中仅根据模式切换 hint 文案
TextField(
  controller: _emailCtrl,
  decoration: InputDecoration(
    hintText: _isFullEmailMode ? '请输入完整邮箱地址' : '请输入邮箱前缀',
  ),
)
```

**教训**：**永远不要用两个 TextField 的切换来实现输入模式变更**。IME 的焦点绑定在 widget 实例上，切换 widget 会导致 IME 行为异常。应始终使用单一 controller，只改变校验逻辑和 UI 提示。

---

### 5.2 域名下拉面板导致页面溢出

**严重级别**：🟠 **功能性（P1）**

**现象**：点击邮箱后缀选择器后，整个页面上移，底部出现黄黑条纹的 Flutter overflow 指示器和 `bottom overflowed by 1.3 pixels` 错误。

**原因**：域名下拉面板作为 `Column` 的 inline 子元素渲染。面板展开后增加了内容高度，导致 `SizedBox` 固定高度的内容超出容器。

**解决方案**：将页面主体改为 `Stack` 布局，下拉面板作为 `Positioned` 覆盖层浮在最上层，不参与正常布局流：

```dart
Scaffold(
  body: SafeArea(
    child: Stack(
      children: [
        // 主内容（正常布局流）
        SingleChildScrollView(
          child: SizedBox(
            height: screenHeight,
            child: Column(...),
          ),
        ),
        // 下拉覆盖层（浮动，不影响布局）
        if (_isDomainDropdownOpen)
          Positioned(
            left: 32,
            right: 32,
            top: screenHeight * 0.35,
            child: _buildDomainDropdown(),
          ),
      ],
    ),
  ),
)
```

---

---

### 5.3 下拉选项文字溢出

**严重级别**：🟡 **视觉（P2）**

**现象**：选择 `outlook.com` 时，下拉选项右侧显示 `overflowed by 14 pixels`。

**原因**：下拉面板宽度固定为 110px，而 `@outlook.com` + 选中图标超出了该宽度。

**解决方案**：
- 选项使用 `Expanded` + `TextOverflow.ellipsis` 防止溢出
- 选中图标放在 `Expanded` 外部，右对齐
- 选择器容器宽度从 110px 调整为 120px

---

### 5.4 `TokenStorage.clearAll()` 误删已保存的密码

**严重级别**：🔴 **阻断性（P0）**

**现象**：勾选了「保存登录密码」登录后退出，再次打开登录页时复选框勾选状态正确，但密码框为空。

**原因**：`TokenStorage.clearAll()` 调用 `_storage.deleteAll()` 清空了整个 `FlutterSecureStorage` 实例。

```dart
// ❌ 错误写法——deleteAll() 会删除所有 key，包括 LocalStorageService 保存的密码
Future<void> clearAll() async {
  await _storage.deleteAll();  // ← 连带删除了已保存的密码
}
```

`TokenStorage` 和 `LocalStorageService` 共用同一个 `FlutterSecureStorage` 实例（默认 `const FlutterSecureStorage()`），所以 `deleteAll()` 一锅端了。

**解决方案**：改为只删除 Token/用户信息相关的 key：

```dart
// ✅ 正确写法——只删除本 service 负责的 key
Future<void> clearAll() async {
  await Future.wait([
    _storage.delete(key: _keyAccessToken),
    _storage.delete(key: _keyRefreshToken),
    _storage.delete(key: _keyUserId),
    _storage.delete(key: _keyUserName),
    _storage.delete(key: _keyUserEmail),
    _storage.delete(key: _keyUserRole),
  ]);
}
```

**教训**：使用 `FlutterSecureStorage`（或其他全局存储）时，**绝不要轻易调用 `deleteAll()`**。不同 Service 可能共享同一个存储实例，`deleteAll()` 会误伤其他模块的数据。始终只删除自己明确管理的 key。

## 6. 已知待解决问题

| # | 问题 | 优先级 | 状态 | 说明 |
|---|------|--------|------|------|
| 1 | `tdesign_flutter` 的 `_TDIconsData extends IconData` | P0 | ⚠️ 已本地 patch | 需等官方发布新版本后移除 patch |
| 2 | `package_info_plus` KGP 警告 | P3 | ⚠️ 可忽略 | 未来 Flutter 版本可能会阻断构建 |
| 3 | TDesign `TDCheckbox` 在 Android 上白屏 | P0 | ✅ 已规避 | 改用 Material 复选框，待官方修复后切换回 |
| 4 | 夜间模式适配 | P2 | 📋 未开始 | TDesign 支持，需配置 dark theme |
| 5 | 真机调试 service protocol 连接失败 | P3 | ⚠️ 无害 | CI/自动化环境正常现象，不影响 APP 运行 |

---

> 最后更新：2026-07-22  
> 维护人：Mobile App Builder
