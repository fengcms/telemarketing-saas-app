# 项目级记忆 — 电销工作台 APP

## 项目约定（2026-07-22）

### 开发风格规范
- 参考 `docs/dev/STYLE_GUIDE.md`
- 每个 Dart 文件顶部必须加 `///` 文件说明注释
- 每个公开方法和重要私有方法必须加 `///` Dart Doc 注释
- 注释用中文

### TDesign 兼容性
- `tdesign_flutter 0.2.7` 有 Dart 3.12 兼容问题（`extends IconData`），已本地 patch pub cache
- `TDCheckbox` 在 Android 上会导致白屏，用 Material 复选框替代
- `image_picker_android` 有 D8 嵌套类问题，`dependency_overrides` 锁定 0.8.13+13

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

### 开发流程（2026-07-22 确立）
1. 每次最多开发一个页面
2. 开发前读透设计文档，从 api.md 中找出对应接口
3. 如果 api.md 接口返回结构不清晰、字段不明，**必须向用户提问确认**，不能猜测
4. 写开发计划文档，待用户确认后进入开发
5. 开发完成要求用户真机实测并反馈
6. 确认没问题后写进度文档、踩坑文档
7. git commit & push

### 仓库与 .gitignore 约定（2026-07-23）
- 本项目为**私有项目、仅单人维护**
- `.workbuddy/` 目录**有意纳入 git 仓库**（用户为自身方便），审查时**不得**将其作为"仓库整洁度/误提交"问题提出
- 即：`.gitignore` 无需忽略 `.workbuddy/`，相关文件随业务代码一起提交属正常做法
