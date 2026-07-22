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

### 书写规范
- 使用 `///` 三斜线文档注释（Dart Doc），类似 JSDoc
- `[参数名]` 引用参数，无需 `@param` 标签
- 文件名：`snake_case`
- 类名：`PascalCase`
- 变量/方法：`camelCase`，私有加 `_` 前缀
