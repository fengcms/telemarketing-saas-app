# 电销工作台 APP — 代码开发风格规范

> 本文档定义项目统一的代码风格和规范，所有团队成员在开发前应阅读并遵守。
> 版本：v1.0（2026-07-22）

---

## 目录

1. [文档注释规范](#1-文档注释规范)
2. [文件结构规范](#2-文件结构规范)
3. [命名规范](#3-命名规范)
4. [Widget 编写规范](#4-widget-编写规范)
5. [状态管理规范](#5-状态管理规范)
6. [导入规范](#6-导入规范)
7. [错误处理规范](#7-错误处理规范)
8. [提交规范](#8-提交规范)
   - 8.1 [Commit Message 格式](#81-commit-message-格式)
   - 8.2 [提交规范强制性规则](#82-提交规范强制性规则)
   - 8.3 [提交前检查清单](#83-提交前检查清单)

---

## 1. 文档注释规范

Dart 使用 **`///`**（三斜线）作为文档注释。`dart doc` 工具会自动将 `///` 注释生成 API 文档。

### 1.1 文件头注释

每个 Dart 文件顶部必须包含文件说明注释：

```dart
/// 登录页面
///
/// 提供邮箱+密码登录功能，包含邮箱前缀+后缀选择器、
/// @ 自动切换完整邮箱模式、密码可见性切换、登录态管理。
/// 使用 Material 组件实现（TDesign TDCheckbox 在 Android 上有兼容问题，已替换）。
///
/// 设计文档参考：docs/design/page-design/01-登录页.md
```

| 规范 | 说明 |

### 1.2 类注释

每个公开类（包括 Widget）必须添加类注释：

```dart
/// 登录页面的 StatefulWidget。
///
/// 管理登录表单的所有状态，包括输入框内容、校验、
/// Loading 态、错误态、账号锁定倒计时等。
///
/// 使用单一 TextEditingController（_emailCtrl）处理
/// 前缀模式和完整邮箱模式的切换，避免 IME 焦点错乱。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}
```

### 1.3 方法/函数注释

方法必须有 `///` 注释，说明功能、参数和返回值：

```dart
/// 构建邮箱输入区域。
///
/// 根据 [_isFullEmailMode] 状态显示两种模式：
/// - 前缀模式：左侧输入框 + 右侧 @域名 下拉选择器
/// - 完整邮箱模式：单一输入框，隐藏域名选择器
///
/// 当输入框聚焦时边框变品牌色（#0052D9），失焦恢复灰色（#E7E7E7）。
Widget _buildEmailInput() { ... }
```

带参数的方法：

```dart
/// 构建复选框组件。
///
/// [label] 复选框的标签文字
/// [checked] 当前选中状态
/// [onChanged] 状态变化回调，接收新的选中值
///
/// 使用 Material Icons（check_box/check_box_outline_blank）实现，
/// 选中色为品牌色 #0052D9，未选中为灰色 #DCDCDC。
Widget _buildCheckbox(
  String label,
  bool checked,
  ValueChanged<bool?> onChanged,
) { ... }
```

```dart
// Dart Doc 风格
/// 构建复选框组件。
///
/// [label] 标签文字
/// [checked] 选中状态
/// [onChanged] 状态变化回调
```

> **要点**：
> - `[参数名]` 用于引用参数（Dart Doc 会自动链接到参数定义）
> - 参数说明跟在方括号后面，用空格分隔
> - 不需要 `@param`、`@return` 等标签，Dart Doc 会自动推断

### 1.4 成员变量注释

重要的成员变量和状态字段需要注释：

```dart
/// 邮箱输入框控制器（单控制器模式）
///
/// 前缀模式（不含 @）下与域名选择器联动拼接完整邮箱；
/// 完整邮箱模式（含 @）下直接使用输入值。
final TextEditingController _emailCtrl = TextEditingController();

/// 当前选中的邮箱后缀（默认 qq.com）
String _selectedDomain = 'qq.com';

/// 是否为完整邮箱模式（输入了 @ 字符后自动切换）
bool _isFullEmailMode = false;
```

### 1.5 常量注释

```dart
/// 可选的邮箱后缀列表
static const List<String> _domainOptions = [
  'qq.com', '163.com', '126.com', 'sina.com',
  'gmail.com', 'outlook.com', 'foxmail.com', 'yeah.net',
];
```

---

## 2. 文件结构规范

### 2.1 目录组织

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # 根组件（主题配置、路由）
├── pages/                    # 页面目录
│   ├── login/                # 登录模块
│   │   ├── login_page.dart   # 登录页
│   │   └── login_page_vm.dart # 登录页 ViewModel（未来使用）
│   ├── home/                 # 首页模块
│   ├── leads/                # 线索模块
│   ├── schedule/             # 日程模块
│   └── profile/              # 个人中心模块
├── widgets/                  # 公共组件
│   ├── app_scaffold.dart     # 通用页面壳
│   ├── empty_state.dart      # 空状态组件
│   └── error_widget.dart     # 错误提示组件
├── models/                   # 数据模型
│   ├── user.dart
│   ├── lead.dart
│   └── ...
├── services/                 # 网络层 / API 服务
│   ├── api_client.dart       # dio 封装
│   ├── auth_service.dart     # 认证 API
│   └── ...
├── providers/                # 状态管理
│   └── ...
└── utils/                    # 工具类
    ├── constants.dart        # 全局常量
    └── validators.dart       # 表单校验
```

### 2.2 文件内部结构

每个 Dart 文件应按以下顺序组织：

```dart
/// 文件头注释（说明文件用途）

// 1. 导入语句（标准 → 第三方 → 本地）
import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../widgets/app_bar.dart';

// 2. 常量定义
const double _kDefaultPadding = 16.0;

// 3. Widget/Class 定义
class LoginPage extends StatefulWidget { ... }

class _LoginPageState extends State<LoginPage> { ... }

// 4. 辅助函数（非公开的顶级函数）
String _formatDuration(Duration d) { ... }
```

---

## 3. 命名规范

| 类别 | 规范 | 示例 |
|------|------|------|
| **文件名** | 小写 + 下划线（`snake_case`） | `login_page.dart`、`lead_model.dart` |
| **类名** | 大驼峰（`PascalCase`） | `LoginPage`、`LeadModel`、`AuthService` |
| **变量/函数** | 小驼峰（`camelCase`） | `_emailCtrl`、`_onLogin()`、`_buildEmailInput()` |
| **常量** | 小驼峰，建议加 `k` 前缀 | `const kDefaultPageSize = 20;` |
| **私有成员** | 下划线前缀 | `_isLoading`、`_buildEmailInput()` |
| **枚举** | 大驼峰 | `enum LoadStatus { initial, loading, success, failure }` |
| **类型别名** | 大驼峰 | `typedef OnLoginCallback = void Function(bool success);` |

### 注意事项

- **不要用匈牙利命名法**（如 `mEmail`、`strName` 等）
- **不要用全大写常量**（如 `MAX_COUNT`，Dart 风格不用 `SCREAMING_SNAKE_CASE`）
- **布尔变量用肯定句式**（`_isLoading` ✅，`_notLoading` ❌）
- **回调参数用 `on` 前缀**（`onTap`、`onChanged`、`onSubmitted`）

---

## 4. Widget 编写规范

### 4.1 优先使用 `const` 构造函数

```dart
// ✅ 正确：能 const 的尽量 const
const SizedBox(height: 16)
const EdgeInsets.symmetric(horizontal: 32)
const Icon(Icons.email, size: 20)

// ❌ 错误：不必要的 new 或非 const
SizedBox(height: 16)
EdgeInsets.all(16.0)
```

### 4.2 提取子 Widget 和方法

不要在一个 `build()` 方法里堆几百行代码：

```dart
// ✅ 正确：按模块拆分方法
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        _buildHeader(),
        _buildForm(),
        _buildFooter(),
      ],
    ),
  );
}

Widget _buildHeader() { ... }
Widget _buildForm() { ... }
Widget _buildFooter() { ... }

// ❌ 错误：全部写在 build 里，超过 100 行
```

### 4.3 使用 `SizedBox` 而非 `Container` 做间距

```dart
// ✅ 正确
const SizedBox(height: 16)

// ❌ 错误：Container 开销更大
Container(height: 16)
```

### 4.4 避免不必要的 `setState`

只在真正需要重建 UI 时调用 `setState`。异步操作完成后要检查 `mounted`：

```dart
// ✅ 正确
Future.delayed(const Duration(seconds: 1), () {
  if (!mounted) return;  // 组件可能已被销毁
  setState(() { _isLoading = false; });
});
```

### 4.5 颜色和尺寸用常量

```dart
// ✅ 正确：定义在文件顶部
static const Color _brandColor = Color(0xFF0052D9);
static const Color _gray3 = Color(0xFFE7E7E7);

// ❌ 错误：散落在代码各处的魔数
Container(color: const Color(0xFF0052D9))
```

> 颜色常量可参考 `docs/design/page-design/00-TDesign-Flutter-设计规范.md` 中的色板定义。

---

## 5. 状态管理规范

### 5.1 当前状态：页面内 `setState`

MVP 阶段暂用 `setState`。随着功能增加应迁移到 Riverpod 或 Bloc。

### 5.2 状态分组

在 Widget 中管理多个状态时，用注释分组：

```dart
// ── 控制器 ──
final TextEditingController _emailCtrl = ...;
final TextEditingController _passwordCtrl = ...;

// ── 表单状态 ──
bool _obscurePassword = true;
bool _saveEmail = true;
bool _isLoading = false;

// ── 域名选择器 ──
String _selectedDomain = 'qq.com';
bool _isFullEmailMode = false;
```

### 5.3 状态更新原则

- 状态变量放在 `State` 类中，不要放在 `Widget` 中
- 不可变数据优先（使用 `final`）
- 布尔值不要用三元表达式，直接赋值（`_isLoading = true`）

---

## 6. 导入规范

### 6.1 导入顺序

```dart
// 1. Flutter SDK
import 'package:flutter/material.dart';

// 2. 第三方包
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

// 3. 项目内部
import '../widgets/app_bar.dart';
```

组之间空一行，组内按字母排序。

### 6.2 使用相对路径导入项目内部文件

```dart
// ✅ 正确：相对路径
import '../widgets/app_bar.dart';
import 'lead_detail_page.dart';

// ❌ 错误：绝对包路径
import 'package:telemarketing_app/widgets/app_bar.dart';
```

---

## 7. 错误处理规范

### 7.1 网络请求错误

使用 dio 拦截器统一处理，页面层不处理具体错误码：

```dart
// ✅ 正确：页面层只关心成功/失败
try {
  final result = await authService.login(email, password);
  // 处理成功
} on ApiException catch (e) {
  // 显示统一错误提示
  _showError(e.message);
} catch (e) {
  // 网络异常等
  _showError('网络连接异常，请检查后重试');
}
```

### 7.2 异步操作容错

```dart
// ✅ 正确：try-catch 包裹所有异步操作
Future<void> _loadVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    setState(() => _version = 'v${info.version}');
  } catch (_) {
    // 降级处理：版本号加载失败不影响核心功能
    setState(() => _version = 'v1.0.0');
  }
}
```

---

## 8. 提交规范

### 8.1 Commit Message 格式

```
<type>(<scope>): <subject>

<body>
```

| type | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat(login): 实现邮箱后缀选择器` |
| `fix` | 修复 bug | `fix(login): 修复 @ 输入导致文本错乱` |
| `docs` | 文档 | `docs: 新增踩坑记录文档` |
| `refactor` | 重构 | `refactor(login): 合并邮箱输入框为单 controller` |
| `style` | 样式/UI | `style(login): 复选框改为左对齐` |
| `chore` | 构建/工具 | `chore: 添加 dependency_overrides` |

### 8.2 提交规范强制性规则

#### 类型必须真实

commit message 的 `<type>` 必须如实反映改动内容。禁止将功能代码标注为 `docs:` 或 `chore:`。

```
# ❌ 禁止：2230 行功能代码标为 docs
docs: 更新文档          # 实际合入 2230 行业务代码

# ✅ 正确：功能代码标 feat
feat(leads): 线索列表页  # 2230 行功能代码用 feat
```

违反此规则的提交需返工。

#### scope 必填规则

`feat` / `fix` / `refactor` / `style` 类型**必须包含 scope**。`docs` / `chore` 类型可选。

```
# ❌ 缺少 scope
feat: 新增线索详情页

# ✅ 带 scope
feat(leads): 新增线索详情页
```

scope 使用小写英文，表示影响的模块（见 §8.1 表意 scope）。

#### 单提交单一职责

一个提交只做一件事。不相关的改动（如 UI 调整 + 新 API 集成）应分拆为多个提交，便于 revert / bisect。

```
# ❌ kitchen-sink：UI + API + 文档混在一起
fix: 跟进面板调整 + 通话记录API

# ✅ 分拆
fix(follow-up-panel): 跟进面板多项 UI 调整
feat: 新增通话记录查询 API
```

### 8.3 提交前检查清单

- [ ] `flutter analyze` 无错误
- [ ] 文件头添加了注释说明
- [ ] 新增的方法添加了 `///` 文档注释
- [ ] 在真机上验证过（不只是 Web）
- [ ] 没有遗留的 TODO 或 debug print

---

> 本规范参照 Dart 官方风格指南（[Effective Dart](https://dart.dev/effective-dart)）制定。
> 规范版本：v1.0 | 最后更新：2026-07-22
