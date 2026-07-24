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
6. [数据与缓存坑点](#6-数据与缓存坑点)
7. [搜索交互坑点](#7-搜索交互坑点)
8. [异步状态竞态坑点](#8-异步状态竞态坑点)
9. [网络与权限坑点](#9-网络与权限坑点)
10. [已知待解决问题](#10-已知待解决问题)
11. [日程模块开发坑点](#11-日程模块开发坑点)

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

### 2.4 TDesign `TDPicker.showDatePicker` 的 `onConfirm` 是 `Map` 不是 `DateTime`
**严重级别**：🔴 **阻断性（P0，release 下静默无反应）**

**现象**：线索详情→新建日程抽屉里，日期/时间选择器的「确定」按钮点了毫无反应（「取消」正常），date/time 两个控件都如此；debug 下则会直接红屏。

**原因**：翻 `tdesign_flutter 0.2.7` 源码 `TDPicker` 坐实——`onConfirm` 的类型是：
```dart
typedef DatePickerCallback = void Function(Map<String, int> selected);
```
回调拿到的是 **Map**（键为 `year`/`month`/`day`/`hour`/`minute`/`second`，未启用列值为 `-1`），**不是 `DateTime`**。项目里原写法 `final dt = date as DateTime;`：
① release 下该 `as` 抛 `CastError` 被吞 → 确定「无反应」；
② `TDDatePicker._buildHeader` 的「确定」只调 `widget.onConfirm!(selected)`、**不会自动 `pop`**；故即便类型正确，也必须在回调里自己 `Navigator.of(context).pop()` 关掉选择器。

**解决方案**：
```dart
// ✅ 从 Map 取字段重建，并手动 pop
void _onConfirmDate(Map selected) {
  final dt = DateTime(
    selected['year']!, selected['month']!, selected['day']!,
  );
  // ...回填到表单...
  Navigator.of(context).pop();
}
```
对照 `tdesign_flutter` 官方示例 `td_date_picker_page.dart`（同样是读 Map + 手动 pop）。

**教训**：用 tdesign_flutter 的 `TDPicker`，`onConfirm`/`onChange` 参数是 `Map<String,int>` 而非 `DateTime`；且**确认后必须手动 pop 选择器**。本项目 STYLE 约定"不确定就翻三方源码/官方示例核实，不靠猜"，又一次避免了误判。

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

---

### 5.5 筛选标签栏推挤卡片内容

**严重级别**：🟠 **功能性（P1）**

**现象**：添加筛选条件后，筛选标签栏出现在搜索框下方，将整个卡片列表向下推挤。

**原因**：标签栏作为 `Column` 的 inline 子元素渲染，`hasActiveFilters` 为 true 时插入布局流。

**解决方案**：将标签栏改为 `Stack` + `Positioned` 浮层渲染，不参与 Column 布局流。

---

### 5.6 筛选面板打开后状态丢失

**严重级别**：🟠 **功能性（P1）**

**现象**：打开筛选面板选择条件→确定→再次打开筛选面板，之前选择的条件没有高亮选中。

**原因**：`_showFilterSheet(state)` 接收的 `state` 参数来自 build 方法的 `ref.watch`，可能不是最新值。

**解决方案**：在 `_showFilterSheet` 方法内直接使用 `ref.read(leadListProvider)` 读取最新状态。

---

### 5.7 分组 key 字符串 round-trip 解析致 release 整页灰屏
**严重级别**：🔴 **阻断性（P0）**

**现象**：日程列表下拉刷新后整页变灰、顶栏消失；杀进程重开仍灰。debug 下是红屏（`FormatException`）。

**原因**：分组 key 用 `'${y}-${m}-${d}'`（月/日未补零，如 `2026-7-24`），随后又在 `build()` 内用 `DateTime.parse(key)` 回解析该串 → 单数字月/日必抛 `FormatException`。因 key 在 `build()` 内被使用，异常冒泡导致整页 build 失败。

**解决方案**：
- key 生成时对月/日 `padLeft(2,'0')` 统一为 `YYYY-MM-DD`；
- **分组 key 不要字符串 round-trip 再 parse**，尽量直接持 `DateTime` 对象做比较。

**教训**：**release 灰屏 = build 期未捕获异常**（debug 是红屏 StackTrace，release 被 `ErrorWidget` 取代且日志不明显）。任何在 `build()` 内对**服务端数据**做解析/格式化的代码，都必须防御非法/异常输入，否则一个脏数据字段就能让整页白/灰屏。

### 5.8 Flutter `LinearGradient` 无 `transform` 参数（shimmer 实现）
**严重级别**：🟡 **警告（非阻断）**

**现象**：想用 `LinearGradient(transform: GradientTransform(...))` 实现骨架屏扫光，编译报 `undefined_named_parameter: transform`。

**原因**：本项目 Flutter 3.44.7 内置的 `LinearGradient` 尚未提供 `transform`/`GradientTransform`（该能力在更新的 Flutter 版本才有）。

**解决方案**：shimmer 改用随 `AnimationController` 进度**平移 `stops`** 实现（repeat(reverse:true) 平滑扫动）：
```dart
final t = controller.value;
final stops = [t - 0.4, t - 0.2, t]; // 随进度平移
return LinearGradient(
  begin: Alignment.centerLeft, end: Alignment.centerRight,
  colors: [base, highlight, base],
  stops: stops.map((s) => s.clamp(0.0, 1.0)).toList(),
);
```

**教训**：升级 Flutter 前别假设新版 API 已存在；实现动画渐变扫光优先用 `stops` 平移法，兼容性最好。

## 6. 数据与缓存坑点

### 6.1 API 返回 ID 而非名称

**严重级别**：🔴 **阻断性（P0）**

**现象**：线索卡片上分类和项目名称为空，显示占位符。

**原因**：设计文档中 API 响应示例是 `"category": "住宅"`（字符串名称），但实际接口返回的是 `"categoryId": "uuid-string"`（ID）。同样 `project` 字段也可能仅返回 `projectId` 而非嵌套对象。

**解决方案**：创建 `OptionsCacheService`，通过下拉选项接口拉取映射表，用 `getCategoryName(id)` / `getProjectName(id)` 解析显示名。ID 找不到时降级显示 ID 本身。

**教训**：API 响应的字段命名与设计文档可能不一致。开发前应通过实际 curl 验证接口返回的真实字段名。

---

### 6.2 下拉选项数据未持久化

**严重级别**：🟡 **视觉（P2）**

**现象**：每次重开 APP 后，卡片上的分类/项目名需等待网络请求完成后才显示，首次打开时显示原始 ID。

**原因**：OptionsCacheService 仅保存在内存中，APP 重启后缓存丢失。

**解决方案**：增加 SharedPreferences 持久化层，启动时加载本地缓存，同时后台静默刷新。TTL 可在 `ApiConstants.optionsCacheTTL` 中配置（默认 1800 秒/30 分钟）。

---

### 6.3 `copyWith` 可空参数覆盖陷阱

**严重级别**：🔴 **阻断性（P0）**

**现象**：选择筛选条件→确定→接口返回数据后，筛选条件被清空（角标消失，筛选面板条件丢失）。

**原因**：`LeadListState.copyWith()` 中对 `statusFilter`、`categoryId` 等可空字段直接赋值：

```dart
// ❌ 错误写法：不传参数时默认为 null，覆盖了当前值
LeadListState copyWith({..., String? statusFilter, ...}) {
  return LeadListState(
    ..., statusFilter: statusFilter, // ← null 覆盖了当前筛选条件
  );
}
```

当 `_reloadPage()` 调用 `state.copyWith(isInitialLoading: false, leads: ...)` 时，因为没有传 `statusFilter`，Dart 将其默认设为 `null`，导致筛选条件被清空。

**解决方案**：使用 sentinel 对象区分"未传参"和"传 null"：

```dart
class _Unset { const _Unset(); }
const _unset = _Unset();

LeadListState copyWith({..., Object? statusFilter = _unset, ...}) {
  return LeadListState(
    ..., 
    statusFilter: statusFilter is _Unset ? this.statusFilter : statusFilter as String?,
  );
}
```

调用 `copyWith(statusFilter: null)` → 显式传 null → 清除筛选条件。
调用 `copyWith()`（不传 statusFilter）→ 使用 `_unset` → 保留当前值。

**教训**：在 Dart 中，可空类型参数 `String? param` 不传时默认值为 `null`，这与"显式传 null"无法区分。处理可空字段的 `copyWith` 必须使用 sentinel 模式。这是一个 Dart 语言层面的常见陷阱。

## 7. 搜索交互坑点

### 7.1 自动搜索浪费服务器带宽

**严重级别**：🟡 **性能（P2）**

**现象**：用户在搜索框输入时，每个字符变化都触发 API 请求（即使有 500ms 防抖），短时间产生大量无效请求。

**原因**：使用 `onChanged` 监听 + 500ms `Timer` 防抖实现自动搜索。

**解决方案**：改为用户手动触发搜索——去掉 `onChanged` 监听，仅保留 `onSubmitted`（键盘回车），并在搜索框右侧添加蓝色「搜索」按钮。

---

## 8. 异步状态竞态坑点

### 8.1 unawaited 静默刷新覆盖当前页导致翻页闪跳

**严重级别**：🟠 **正确性（P2）**

**现象**：线索详情页反复「下一个 ×N → 上一个 ×N」时，页面会从当前线索突然闪跳到别的线索（如停在 A，却闪现 B/C）。

**原因**：详情重构后 `loadLead` 为做到「缓存命中秒开」，在缓存命中分支里用 `unawaited(_fetchBundle(leadId))` 发射一个**后台静默刷新**并立刻 `return`。快速翻页时，多个 `_fetchBundle` 的 Future 重叠在飞；而 `_fetchBundle` 写回 `state.bundle` 时只检查了 `mounted`，**没有校验「这个请求对应的 leadId 是否还是当前正在看的线索」**。于是哪个网络请求最后落地，哪个就无条件覆盖 `state`——迟到的旧请求把当前页盖掉，表现为闪跳。

```dart
// ❌ 错误：只查 mounted，未校验 leadId 是否仍是当前线索
Future<void> _fetchBundle(String leadId, bool raw) async {
  final bundle = await _service.fetchLeadDetail(id: leadId, raw: raw);
  if (bundle != null) _cache.put(leadId, bundle);
  if (mounted) {                          // ← 旧请求落地时 mounted 永远为 true
    state = state.copyWith(bundle: bundle); // ← 无条件覆盖当前页
  }
}
```

**解决方案**：写回 UI 前加 `_currentLeadId` 守卫；`_cache.put` 仍无条件执行（保证缓存新鲜，再翻回去数据依旧新）。`refreshBundle`（写操作后刷新）走同一方法，守卫自然通过。

```dart
// ✅ 正确：仅当「请求对应的线索 == 当前正在看的线索」才写回 UI
Future<void> _fetchBundle(String leadId, bool raw) async {
  final bundle = await _service.fetchLeadDetail(id: leadId, raw: raw);
  if (bundle != null) _cache.put(leadId, bundle); // 缓存照写
  if (mounted && leadId == _currentLeadId) {       // ← 关键守卫
    state = state.copyWith(bundle: bundle, ...);
  }
}
```

**教训**：任何「`unawaited` 静默刷新 / 预加载 + 写 `state`」的模式，必须带「目标 id == 当前 id」守卫，否则在快速导航 / 翻页场景下必然产生竞态覆盖。`mounted` 只能防止组件销毁后的写入，挡不住「导航到别的实体后旧请求落地」这类覆盖。

---

### 8.2 API 文档字段笔误（`order` 排序参数不存在）

**严重级别**：🟠 **正确性（P1）**

**现象**：日程列表页调 `GET /api/tenant/schedules` 时，按 `api.md` 写的 `order=asc` 传入，后端返回 `400 INVALID_FILTER_FIELD: unknown field order`，整个请求被拒 → 列表页统一显示"加载失败"。首页因为用的参数**不带 `order`** 反而正常，成了对照证据。

**原因**：`api.md` 日程接口那段写了 `sort` / `order` 参数并说"默认 `order=asc`"，但后端该端点实际**只认 `sort`**（值如 `scheduledAt`），**不认 `order` / `sortBy` / `sortDir` 任何方向参数**；排序方向由后端固定默认（按 `scheduledAt` 升序，正好是想要的"最近优先"）。通用查询 DSL（§9.4）定义的 `sortBy` / `sortDir` 在此端点同样不被接受。

**验证**（curl 实测，lina 账号）：

| 参数 | 后端反应 |
|---|---|
| `sort=scheduledAt` | ✅ 接受（首页即用，正常） |
| `order=asc` | ❌ unknown field order |
| `sortBy=scheduledAt` | ❌ unknown field sortBy |
| `sortDir=asc` | ❌ unknown field sortDir |

**解决方案**：`lib/services/schedule_service.dart` 的 `fetchSchedules` 删除 `order` 参数与其在 query 中的注入（所有调用方都没传它，删除零风险）。`api.md` 该处笔误已修正。

**教训**：照文档写请求参数前，**先 curl 验证端点真实接受的字段**，尤其"排序方向"这类常被文档夸大 / 写错的参数。文档和后端实现不一致时，以 curl 实测为准。

---

### 8.3 Alice 网络调试浮窗集成（dev-only）

**严重级别**：🟢 **调试基建（非阻断）**

**背景**：排查真机网络问题时，需要在 app 内看到每个请求的完整 URL / 参数 / 响应体 / 错误码。成熟第三方方案是 **Alice**（`pub.dev` 上的 HTTP Inspector）。

**坑点（alice 已升级，旧教程失效）**：

1. **`alice: ^1.0.0` 已重构为适配器模式**：无旧版的 `getDioInterceptor()`、也无旧版自动浮标。网上大量旧代码里的 `alice.getDioInterceptor()` 现在直接编译报错。
2. **Dio 拦截器需单独装 `alice_dio` 包**（^1.0.7）。`AliceDioAdapter` 本身是 Dio `Interceptor` 子类，直接 `_dio.interceptors.add(AliceDioAdapter(alice))` 即可，**会覆盖全 app 共用的同一个 Dio 实例**（所有 Service 经 `apiClientProvider` 取到）。
3. **1.0.0 取消自动浮标**：需自定义一个全局浮标按钮（右下角 FAB），点击调 `alice.showInspector()` 唤出请求列表面板。
4. **Android 构建失败**：`flutter_local_notifications`（alice 间接依赖）要求开启 **core library desugaring**。需在 `android/app/build.gradle.kts` 加：
   ```kotlin
   compileOptions {
       // Alice 依赖 flutter_local_notifications，需开启 core library desugaring
       isCoreLibraryDesugaringEnabled = true
       sourceCompatibility = JavaVersion.VERSION_17
       targetCompatibility = JavaVersion.VERSION_17
   }
   dependencies {
       coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
   }
   ```
   ⚠️ Kotlin DSL 里属性名是 `isCoreLibraryDesugaringEnabled`（不是 `coreLibraryDesugaringEnabled`），desugar 版本需 ≥ 2.1.4。

**方案**：`lib/core/alice_manager.dart` 封装 Alice 单例 + `AliceDioAdapter` 注入 + `showInspector()`；`lib/app.dart` 的 `MaterialApp.builder` 注入全局浮标；是否启用由 `lib/core/dev_tools.dart` 的 `enableDevTools` 控制（仅 dev 构建）。

---

### 8.4 dev-only 编译开关（`--dart-define=DEV_TOOLS`）

**背景**：希望调试浮窗 + 登录预填只在开发包出现，正式包**零残留**。

**方案**：`lib/core/dev_tools.dart` 定义：

```dart
const bool enableDevTools = bool.fromEnvironment('DEV_TOOLS', defaultValue: false);
```

- 开发版：`flutter build apk --dart-define=DEV_TOOLS=true`（浮窗 + 预填都生效）
- 正式版：`flutter build apk`（不传则 `false`，相关代码被编译期死代码消除）

Dart 编译器对 `if (enableDevTools) { ... }` 在 `false` 分支做消除，正式包不携带 alice / 测试凭据。

**注意**：alice 的初始化与浮标必须包在 `enableDevTools` 守卫内，否则正式包会因"引用了 dev 才存在的 alice 实例"或误触浮标而出问题。`pubspec.yaml` 里的 `alice` / `alice_dio` 依赖可常驻（不影响正式包体积多少，且避免切换构建时重复 pub get）。

---

### 8.5 登录预填测试账号（仅 dev）

**背景**：真机每次登录手输账号麻烦，开发阶段希望自动填好测试账号。

**方案**：`lib/pages/login/login_page.dart` 的 `_loadSavedCredentials` 末尾，`enableDevTools` 为 true 时自动填入测试账号前缀 + 域名（本项目即 `lina@qq.com`）与密码（`Dev@123456`）。正式包该分支编译期消除，不包含任何测试凭据。

**注意**：测试账号明文只存在于 dev 分支代码，且被编译期消除——**切勿把真实生产账号写进此处**。若担心泄露，可改为读取环境变量而非硬编码。

---

### 8.6 `flutter install` 不认 apk 路径

**现象**：执行 `flutter install build/app/outputs/flutter-apk/app-debug.apk` 时，apk 路径参数被**忽略**，Flutter 自行重新 `flutter build` 一个 **release** 并安装到它默认的"第一个"设备。输出里显示的 `Installing ... to 2211133C` 中的 `2211133C` 实为**设备型号名**（非另一台设备序列号），极易误判。

**后果**：装上去的不是你要的那个包（比如你想装 debug 却装了 release），且可能装错设备。

**解决方案**：要安装**指定 apk 文件**，用 `adb` 直接装：

```bash
adb -s <deviceId> install -r build/app/outputs/flutter-apk/app-debug.apk
```

`flutter install`（不带路径）只适合"构建当前项目并装上去"的场景；一旦你想装某个已构建好的 apk，必须走 `adb install`。

---

### 8.7 真机"无法登录"排查教训（release 模式 Dart 异常不可见）

> ⚠️ **本节结论已被 [§9 网络与权限坑点](#9-网络与权限坑点) 推翻。** 那次"无法登录"的真正根因是 `main` 清单缺 `INTERNET` 权限（release 不合并 debug 清单自带的那行），**不是** "网络环境波动 + release 吞异常"。本节记录的"排查方法论"（先用 `adb shell curl` 验证手机侧真实可达性、用 debug 版看 Dart 真实异常）仍然有效，但末尾"未在代码层复现硬伤"的判断是**错误**的，请勿据此放松对清单权限的审查。

**严重级别**：🟠 **排查方法论**

**现象**：用户报 app 无法登录，Alice 里能看到请求已发出、但无响应；`adb logcat` 却**无任何** DioException / 超时 / 证书报错，看似"零报错"。

**根因**：之前安装的是 `flutter build apk`（**release 模式**）。release 下 Dart 的异常和 `print` **不输出到 logcat**，所以"零报错"是**假象**——Dio 其实在 15s 超时内抛了异常，只是看不见。你在 Alice 面板里看到的"有请求、无响应"，是请求卡在网络 / TLS 层、直到超时 `onError` 触发前的 pending 状态。

**方法论（已验证有效）**：

1. **先用 `adb shell` 实测手机侧真实可达性**，区分"app 代码问题"还是"手机网络 / 软路由隧道未覆盖 app"：
   ```bash
   adb -s <id> shell curl -s -m 12 https://<域名>/health
   adb -s <id> shell curl -s -m 12 -X POST https://<域名>/api/auth/login -H 'Content-Type: application/json' -d '{"email":"x","password":"y"}'
   adb -s <id> shell nslookup <域名>
   ```
2. **要看到 Dart 真实异常，必须装 debug 版**（`flutter build apk --debug --dart-define=DEV_TOOLS=true`），或用 `flutter logs` / `adb logcat` 抓 Dart 输出。release 版只会吞异常。
3. 本项目测试 API（`tm-api-test.kao9.com`）经**软路由全屋隧道**，手机浏览器 / `adb curl` 均通，app 也应通。若 app 异常而 curl 通，优先怀疑 **release 模式吞异常 / WiFi 手动代理残留 / Dio 拦截器**，而非"域名不可达"（后者用 `adb curl` 一测便知）。

**本次结论**：最终在 **debug 版**下验证登录 / 日程列表 / Alice 浮窗**均正常**；之前"无法登录"更可能是临时网络环境波动 + release 模式异常不可见共同造成的排查盲区，**未在代码层复现硬伤**。提交后建议再用日常 release 构建命令实机验一次，确认 release 路径也正常。

---

### 8.12 下拉/用户缓存 fire-and-forget 预热致首查落空并被 FutureProvider 缓存
**严重级别**：🟠 **功能性（P1）**

**现象**：日程卡片「归属」首屏显示的是用户 id 而非姓名；重新下拉刷新或切 Tab 后才变正确。

**原因**：`OptionsCacheService._ensureLoaded()` 用 fire-and-forget 调 `_refreshFromApi()`（不 await），首查时刻 `_users` 仍为空 → `getUserName(id)` 立即回退成 id；而上层用的是 `userNameProvider`（Riverpod `FutureProvider.family`），它把这次"返回 id"的结果**按 id 永久缓存**，后续即便缓存预热完成也不再重查。

**解决方案**：把预热改为 **`await` 同一个共享 Future**——`_ensureLoaded()` 返回 `_loadingFuture`（首次创建、仅发一次请求；并发调用复用同一 Future），所有读取方 `await` 它完成后再取 `getUserName`，确保首查即为正确姓名。
```dart
Future<void> _ensureLoaded() => _loadingFuture ??= _refreshFromApi();
// 调用方：await optionsCache._ensureLoaded(); final name = optionsCache.getUserName(id);
```

**教训**：任何"先 fire-and-forget 预热、再同步读缓存"的模式，在 `FutureProvider`/`AsyncNotifier` 等会自动缓存首次结果的框架里都会翻车——首查的 fallback 值会被框架永久记住。**预热必须是可被 await 的共享 Future，读取前 await 它完成。**

## 9. 网络与权限坑点

### 9.1 release 全版本无法联网 = `main` 清单缺 `INTERNET` 权限（真因）

**严重级别**：🔴 **阻断性（P0）**

**现象**：`flutter build apk`（release）装真机后，登录 / 所有接口均报"网络连接失败"；而 `flutter run` / `flutter build apk --debug` / `--profile` 一切正常。用日常 release 命令构建**最早的历史版本（a1fef91，早于任何近期改动）** 直连测试，同样失败 → 排除"代码回归"。

**根因**：Flutter 模板在不同 build 类型下放了**不同的 AndroidManifest**：

| 清单位置 | 是否含 `INTERNET` 权限 |
|---|---|
| `android/app/src/debug/AndroidManifest.xml` | ✅ 自带 `<uses-permission android:name="android.permission.INTERNET"/>` |
| `android/app/src/profile/AndroidManifest.xml` | ✅ 同上 |
| `android/app/src/main/AndroidManifest.xml` | ❌ **默认不带** |

release 构建**只合并 `main` 清单**，不会带入 debug/profile 里那行 `INTERNET`。于是所有 release 包都没有联网权限，Dio 请求被 Android 系统直接拒绝，表现即"网络连接失败"。debug 一直能联网，纯粹是借了 debug 清单里的 `INTERNET` 权限——这也正是前面几轮死活查不出代码问题的原因：根因压根不在 Dart 代码，而在清单合并。

**验证过程（弯路，记此警醒）**：曾误判为"Alice 顶层 `final` 在 AOT 下抢跑污染网络栈""release 吞 Dart 异常""软路由隧道 DNS 劫持"等，逐一排除后，最终由用户定位到权限缺失。教训见下方。

**修复**：在 `android/app/src/main/AndroidManifest.xml` 的 `<manifest>` 下、`READ_CALL_LOG` 那行**并列**补一行：

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

补完后重新 `flutter clean && flutter build apk` 装真机，登录 / 接口 / 日程列表立即全部正常。

**教训（铁律）**：
- Flutter 项目若要用网络，**必须显式在 `main/AndroidManifest.xml` 声明 `INTERNET` 权限**，绝不能依赖 debug 清单"借"来的那行——它只在 debug/profile 构建里生效，release 一打包就没了。
- 遇到"**debug 能联网、release 不能**"的表象，第一反应应是**对比 debug/main 两份清单的权限差异**，而不是去怀疑业务代码、DNS、TLS、或第三方库初始化时机。这一条能省掉数小时的无效排查。
- 新增任何需要网络的功能后，务必用**日常 release 命令**（`flutter build apk`）真机验一次，别只跑 debug。

---

## 11. 日程模块开发坑点

### 11.1 tdesign_flutter 0.2.7 的 `TDButtonTheme` 枚举值有限
**严重级别**：🟡 **编译期（P2）**

**现象**：用 `TDButtonTheme.secondary` / `TDButtonTheme.text` 编译直接报 `undefined_getter`（枚举不存在）。

**原因**：tdesign_flutter 0.2.7 的 `TDButtonTheme` 枚举**只有四个值**：`defaultTheme` / `primary` / `danger` / `light`。没有 `secondary`、`text` 等命名。需查源码 `enum TDButtonTheme` 确认实际值，不要凭其他组件库的经验猜测。

**解决方案**：浅色次要按钮用 `TDButtonTheme.light`；纯图标按钮直接用原生 `IconButton` 或 `TDButton` 配 `light` + `iconWidget`。项目内按钮风格统一前务必先 grep 一次实际枚举。

---

### 11.2 DEV_TOOLS 浮标首帧 `clamp` 负上界致启动崩溃
**严重级别**：🔴 **阻断性（P0，仅 dev 构建暴露）**

**现象**：用计划命令 `flutter build apk --dart-define=DEV_TOOLS=true --release` 构建后，真机启动即红屏崩溃，logcat 报 `Invalid argument(s): 0.0`（来自 `double.clamp`）；但普通 `flutter build apk`（无 DEV_TOOLS）正常。

**原因**：`app.dart` 的 DEV_TOOLS 浮标按钮在首帧用 `MediaQuery.of(context).size` 计算位置，`clamp(0, screen.width - _size)`。首帧 `MediaQuery` 尚未就绪时 `size` 为 `0`，上界 `0 - _size` 变**负数** → `clamp` 抛 `ArgumentError`。普通构建因 `enableDevTools=false`、浮标不渲染，故不触发；这也解释了为什么之前 debug 包（不开该 flag）从没暴露过。

**解决方案**：所有 `clamp` 上界用 `max(0, …)` 兜底（需 `import 'dart:math'`）：
```dart
left: left.clamp(0, max(0, screen.width - _size)),
top: top.clamp(0, max(0, screen.height - _size)),
```
**教训**：任何在首帧依赖 `MediaQuery.size` 做 `clamp`/`/ 2` 等运算的浮层，都要假设首帧 size 可能为 0，对上界做 `max(0, …)` 保护。带 dev 开关的功能也要走一遍带 flag 的 release 构建验证启动。

---

### 11.3 详情数据「缓存优先 + 操作后失效」模式（复用 `LeadDetailCache`）
**严重级别**：🟢 **模式参考（P3）**

**现象/需求**：详情页每次进入都重新请求接口，列表→详情→返回→再进反复拉取，体验差且浪费流量。

**方案**：新增 `ScheduleDetailCache`，**严格照已有 `LeadDetailCache` 的 API 范式**：`get(id)` / `put(id, detail)` / `invalidate(id)` / `invalidateAll()` + 10 分钟 TTL（纯内存，不落盘）。详情页加载逻辑改为：
1. 命中缓存 → 先秒开旧数据（不转圈），再后台静默 `fetchScheduleDetail` 刷新；
2. 后台刷新失败**且已有旧数据** → 不覆盖、不弹错误；
3. 任何写操作（完成/取消/重开/删除/编辑保存）成功后 `invalidate(id)`，下次进入重新拉取。

**好处**：与线索详情缓存行为完全一致，维护心智统一；TTL 防止长期脏数据。注意：纯内存缓存在杀进程后失效，属预期。

---

### 11.4 `showModalBottomSheet` 满屏表单抽屉写法
**严重级别**：🟢 **模式参考（P3）**

**需求**：新建/编辑日程从全屏页改为底部抽屉，且键盘弹起时底部「取消/保存」按钮不被遮挡。

**关键参数**：
```dart
showModalBottomSheet<bool?>(
  context: context,
  isScrollControlled: true,          // 必须，否则最多半屏且不可撑高
  backgroundColor: Colors.white,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (ctx) => DraggableScrollableSheet(
    initialChildSize: 0.9, expand: false,
    builder: (_, sc) => Column(children: [
      _handleBar(), _titleBar(),
      Expanded(child: ListView(controller: sc, ...)),  // 表单区可滚动
      _bottomBar(),                                 // 取消/保存，不被键盘遮
    ]),
  ),
);
```
容器最大高度用 `MediaQuery.sizeOf(context).height * 0.92` 约束。配合 `Scaffold.resizeToAvoidBottomInset`（默认 true）或底部 `Padding(bottom: MediaQuery.viewInsetsOf(ctx).bottom)`，键盘弹起时底部按钮始终可见。

**复用**：表单逻辑抽进 `ScheduleFormContent`，`showScheduleFormSheet(...)` 静态方法包上面这段，线索详情「预约」与日程详情「编辑」两处共用同一抽屉组件。

---

### 11.5 全屏遮罩 `Stack` + `Center` 不能放在零高度子组件内
**严重级别**：🟠 **功能性（P1）**

**现象**：删除日程时，loading 圈圈出现在屏幕左上角状态栏位置，而非屏幕中央。

**原因**：删除 loading 的 `Stack(children: [ModalBarrier, Center(CircularProgressIndicator)])` 放在 `_buildActionBar()` 方法内，而 ActionBar 是 `Scaffold` → `Column` 的底部子元素。当 `_isDeleting=true` 时 ActionBar 内的操作按钮被隐藏，`Stack` 的高度坍缩为零，`Center` 的参考系缩到左上角 → loading 圈跑到屏幕左上角。

**解决方案**：将遮罩 + loading 移到最外层 `Scaffold` 的 `Stack` 中，作为 `SafeArea` 的同级兄弟，而不是放在子组件内：

```dart
return Scaffold(
  body: Stack(
    children: [
      SafeArea(child: Column(children: […] )),  // 正常页面内容
      if (_isDeleting) const ModalBarrier(dismissible: false, color: Color(0x66000000)),
      if (_isDeleting) const Center(child: CircularProgressIndicator()),
    ],
  ),
);
```

**教训**：任何全屏 `Overlay` / `ModalBarrier` + `Center` 的组合，都必须放在**能撑满全屏的外层 Widget**（如 `Scaffold.body` 的 `Stack`）中，不要放在可能为零高度的子区块内。`Center` 的参考系是其父 `Stack` 的大小，父 Stack 的高度不足时就会定位偏移。

---

### 11.6 公开 ShimmerBlock 需补 `super.key` 参数
**严重级别**：🟢 **info 级（P3）**

**现象**：将 `_ShimmerBlock` 从私有类改为公开类 `ShimmerBlock` 后，`flutter analyze` 报 `use_key_in_widget_constructors`  info。

**原因**：Dart 规范要求公开 Widget 的构造函数必须提供可选的 `Key? key` 参数（`super.key`）。原有私有构造没有，暴露为公开类后 analyze 提示。

**修复**：
```dart
class ShimmerBlock extends StatelessWidget {
  const ShimmerBlock({
    super.key,        // ← 补上
    required this.ctrl,
    this.width = double.infinity,
    this.height = 14,
  });
```

**教训**：任何 Widget 从 `_私有` 改为公开时，需同时检查构造函数是否接受 `super.key`（`super.key`），否则 analyzer 会报 info。

---

## 10. 已知待解决问题

| # | 问题 | 优先级 | 状态 | 说明 |
|---|------|--------|------|------|
| 1 | `tdesign_flutter` 的 `_TDIconsData extends IconData` | P0 | ⚠️ 已本地 patch | 需等官方发布新版本后移除 patch |
| 2 | `package_info_plus` KGP 警告 | P3 | ⚠️ 可忽略 | 未来 Flutter 版本可能会阻断构建 |
| 3 | TDesign `TDCheckbox` 在 Android 上白屏 | P0 | ✅ 已规避 | 改用 Material 复选框，待官方修复后切换回 |
| 4 | 夜间模式适配 | P2 | 📋 未开始 | TDesign 支持，需配置 dark theme |
| 5 | 真机调试 service protocol 连接失败 | P3 | ⚠️ 无害 | CI/自动化环境正常现象，不影响 APP 运行 |

---

> 最后更新：2026-07-24  
> 维护人：Mobile App Builder
