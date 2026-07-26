# 项目级记忆 — 电销工作台 APP

## 项目约定（2026-07-25 更新）

### UI 框架：Material 3（已替换 TDesign）
- **2026-07-25**：TDesign Flutter 0.2.7 已全面替换为 Material 3，`tdesign_flutter` 依赖已从 `pubspec.yaml` 移除。
- 主题系统位于 `lib/theme/`：`color_scheme.dart`（品牌色 #0052D9 + BrandColors 常量）、`text_theme.dart`、`component_tokens.dart`（组件主题覆写）、`app_theme.dart`（入口 `buildBrandTheme()`）。
- 公共组件位于 `lib/widgets/`（7 个）：`AppSearchBar` / `AppFormSection` / `AppActionBar` / `AppDialog` / `AppBottomSheet` / `AppTextarea` / `AppToast`。
- **所有新页面必须使用 M3 组件 + 公共组件**，不得再引入 TDesign。
- `image_picker_android` 仍有 D8 嵌套类问题，`dependency_overrides` 锁定 0.8.13+13。

#### M3 组件快速参考
| 场景 | 使用方式 |
|------|---------|
| 主要按钮 | `FilledButton(onPressed: _, child: Text('确定'))` |
| 浅色按钮 | `FilledButton.tonal(onPressed: _, child: Text('取消'))` |
| 文字按钮 | `TextButton(onPressed: _, child: Text('编辑'))` |
| 提示 | `AppToast.show(context, '保存成功')` |
| 搜索栏 | `AppSearchBar(controller: _, hintText: '搜索...', onSearch: _)` |
| 表单区块 | `AppFormSection(label: '姓名', child: TextField(...))` |
| 底部操作栏 | `AppActionBar.submit(text: '保存', onPressed: _)` 或 `AppActionBar(actions: [...])` |
| 确认弹窗 | `final ok = await AppDialog.confirm(context: _, title: '确认', content: '内容?')` |
| 底部抽屉 | `final r = await AppBottomSheet.show(context: _, title: '标题', child: ...)` |
| 多行文本 | `AppTextarea(controller: _, hintText: '输入...', maxLength: 200)` |
| 日期选择 | `showDatePicker(context: _, initialDate: _, firstDate: _, lastDate: _)`（Material 原生） |
| 图标 | `Icons.xxx`（映射表见交接文档 §四） |
| 页面背景 | `BrandColors.surface`（#F3F3F3），白色卡片用 `Colors.white` |
| 文字色 | `BrandColors.textPrimary`（#181818）/ `textSecondary`（#A6A6A6） |

#### 主题应用方式
```dart
MaterialApp(
  theme: buildBrandTheme(),       // lib/theme/app_theme.dart
  locale: const Locale('zh'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
)
```

### 调试工具（Alice 网络浮窗，2026-07-24）
- 用途：dev-only 在真机抓全部接口请求/响应，点浮标看详情。
- 开关方案：`bool.fromEnvironment('DEV_TOOLS', defaultValue:false)`（`lib/core/dev_tools.dart`），
  构建时 `flutter build apk --dart-define=DEV_TOOLS=true` 才注入；不传即正式版，相关引用被编译期消除。
- 依赖：`alice: ^1.0.0` + `alice_dio: ^1.0.0`（Dio 适配器已拆独立包）。
- alice 1.0.0 **已无 `getDioInterceptor()`、无自动浮标**：
  - 拦截器改用 `AliceDioAdapter`（本身是 Dio `InterceptorsWrapper` 子类）→ `alice.addAdapter(adapter)` + `_dio.interceptors.add(adapter)`；
  - 唤出面板用 `alice.showInspector()`，需 `MaterialApp.navigatorKey = alice.getNavigatorKey()`；
  - 旧版「聊天头浮标」没了，需自建一个全局浮标按钮（本项目在 `app.dart` 用 `builder`+`Stack`+`Positioned` 叠一个按钮调用 `showInspector`）。
- Android 构建必须开 core library desugaring（`android/app/build.gradle.kts`）：
  `compileOptions { isCoreLibraryDesugaringEnabled = true }` + `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5") }`
  （alice 间接依赖 flutter_local_notifications 触发，版本需 ≥ 2.1.4）。
- 登录预填测试账号也用同一 `enableDevTools` 开关（`login_page.dart` `_loadSavedCredentials` 末尾），正式版不编译。

### 书写规范
- 使用 `///` 三斜线文档注释（Dart Doc），类似 JSDoc
- `[参数名]` 引用参数，无需 `@param` 标签
- 文件名：`snake_case`
- 类名：`PascalCase`
- 变量/方法：`camelCase`，私有加 `_` 前缀
- 页面背景：`Scaffold` 会自动应用 `BrandColors.surface`（灰底），无需手动设置

### 开发流程（2026-07-22 确立）
1. 每次最多开发一个页面
2. 开发前读透设计文档，从 api.md 中找出对应接口
3. 如果 api.md 接口返回结构不清晰、字段不明，**必须向用户提问确认**，不能猜测
4. 写开发计划文档，待用户确认后进入开发
5. 开发完成要求用户真机实测并反馈
6. 确认没问题后写进度文档、踩坑文档
7. git commit & push

### Web 字体偏好（2026-07-26 确立）
- **用户明确拒绝 Noto Sans SC**，倾向系统苹方（PingFang SC）。
- 事实边界（重要）：苹方是 Apple 专有字体，**禁止提取/打包/再分发**；仅能在 Apple 平台随系统使用（iOS 默认已用苹方、Mac 上 Web 走系统字体合法）。
- Android / Web 部署到非苹果设备**不能打包苹方**，必须用语开源字体（思源黑体 / Noto 本地化）。
- Web 调试时 Flutter 引擎(CanvasKit)会自动从 gstatic 拉 Noto 导致超时：可改用 HTML renderer
  （`flutter run -d chrome --web-renderer html`）走浏览器系统字体（Mac=苹方）。
- 当前决定：**暂不持久化改动** web 渲染模式，保持现状；未来若要做 web 字体方案需先确认。
