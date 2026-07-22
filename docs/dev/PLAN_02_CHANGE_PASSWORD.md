# 开发计划：02-强制改密页

> 设计文档：`docs/design/page-design/02-强制改密页.md`
> 接口文档：`docs/api.md`
> 预计工时：1d

---

## 一、前置依赖改动

### 1.1 User 模型新增字段

**文件：** `lib/models/user.dart`

在 `User` 类中新增 `mustResetPassword` 字段：

```dart
class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool mustResetPassword;  // ← 新增
}
```

- `fromJson` 中解析：`json['mustResetPassword'] == 1 || json['mustResetPassword'] == true`
- `toJson` 中也要处理

### 1.2 AuthService 新增强制改密方法

**文件：** `lib/services/auth_service.dart`

新增一个专门用于强制改密场景的方法（无需 `oldPassword`）：

```dart
Future<void> forceChangePassword({required String newPassword}) async {
  // POST /api/auth/change-password { newPassword }
}
```

> ⚠️ **待确认：** API 文档（docs/api.md §POST /api/auth/change-password）要求传入 `oldPassword`，但设计文档（§6.1）明确说明强制改密场景不需要 `oldPassword`。这两个文档存在差异，**需要用户确认后端接口是否已适配「无旧密码」的强制改密场景**。

### 1.3 AuthService 登录响应读取 mustResetPassword

**文件：** `lib/services/auth_service.dart`

修改 `login()` 方法，第 53 行去掉 `mustResetPassword: false` 硬编码，改为从 API 响应中读取：

```dart
final mustReset = body['user']['mustResetPassword'] == 1;
return (user: user, mustResetPassword: mustReset);
```

### 1.4 AuthNotifier 新增强制改密路由跳转

**文件：** `lib/providers/auth_provider.dart`

- 新增 `AuthStatus.forceChangePassword` 枚举值
- 登录成功后检测 `mustResetPassword == true` → 状态设为 `forceChangePassword`（不走 `authenticated`）
- 新增 `forceChangePassword()` 方法（调用 AuthService.forceChangePassword）
- 成功后清空 Token，状态设为 `unauthenticated`

### 1.5 ApiClient 新增 423 拦截器处理（兜底）

**文件：** `lib/services/api_client.dart`

- 在 `onError` 拦截器中新增 423 `FORCE_CHANGE_PASSWORD` 的判断
- 不走 refresh→retry 路径
- 触发全局跳转改密页

> ⚠️ **需要确认：** 423 兜底的跳转机制如何实现？目前是 Riverpod 状态驱动路由（AuthGate 根据 AuthStatus 切换页面），拦截器需要触发状态变化。方案：
> - 在拦截器中通过一个 `GlobalKey<NavigatorState>` 或事件总线触发跳转
> - 或直接在拦截器回调中调用 `ref.read(authProvider.notifier).forceRedirect()` 修改状态

---

## 二、改密页 UI 开发步骤

### Step 1：创建页面骨架

**文件：** `lib/pages/force_change_password/force_change_password_page.dart`

- `ConsumerStatefulWidget`，与登录页相同的布局结构
- TDNavBar（标题"设置新密码"，返回按钮带确认弹窗）
- SafeArea + SingleChildScrollView（处理键盘遮挡）

### Step 2：安全提示卡片

顶部 Container 组件，brand-1 背景色，包含：
- 🔒 图标（TDIcons.security）
- "安全提示" 标题
- 说明文字两行

### Step 3：新密码输入框 + 密码强度指示器

密码输入框：
- TDInput，前缀图标 TDIcons.key
- 后缀密码可见性切换按钮
- obscureText 模式
- hintText: "请输入新密码"

密码强度指示器（自定义 Widget）：
- 8 段圆角条形，4px 高，2px 圆角
- 强度规则：弱(2段)/中(5段)/强(8段)
- 字符类型：小写、大写、数字、特殊字符
- 使用 AnimatedContainer 动画
- 强度文字跟随颜色变化

### Step 4：确认密码输入框

- 同新密码框结构
- hintText: "请再次输入新密码"
- 实时一致性校验
- 不一致时边框变 error-7，下方显示错误提示

### Step 5：密码规则提示

- 静态文字，gray-6 色，12sp
- "密码至少 8 位，且须同时包含字母和数字..."

### Step 6：确认按钮（Loading 态）

- TDButton(primary, round)，文本"确 认"
- 点击触发前端校验 → Loading → 调 API
- 成功：TDToast + 1.5s 延迟 → 跳转登录页
- 失败：页面内错误提示

### Step 7：错误提示区

- 条件渲染，默认隐藏
- 淡入动画（200ms）
- error-7 颜色文字 + 错误图标

### Step 8：整合到路由

**文件：** `lib/app.dart` 的 AuthGate

- 新增 `AuthStatus.forceChangePassword` 分支 → 渲染改密页

---

## 三、状态与交互矩阵

| 状态 | 触发条件 | UI 表现 |
|------|---------|--------|
| 初始态 | 页面加载 | 两个输入框空态，强度指示器不显示，按钮可点 |
| 输入中 | 用户输入新密码 | 实时计算强度，更新指示器 |
| 密码不一致 | 确认密码与新密码不同 | 确认框边框变红，下方提示"两次密码输入不一致" |
| Loading | 点击确认，校验通过 | 按钮显示 loading，所有输入框禁用 |
| 成功 | API 返回 200 | TDToast 提示 → 1.5s 后跳转登录页 |
| 服务端错误 | API 返回 400/500 | 错误提示区显示错误文案，输入框恢复可编辑 |
| Token 失效 | API 返回 401 | 清空 Token → 跳转登录页 |

---

## 四、边界情况

| 场景 | 处理方式 |
|------|---------|
| 返回按钮 | TDDialog 确认框 → 确认后清空 Token → 跳转登录页 |
| 快速连续点击确认 | Loading 态阻止重复提交 |
| 键盘遮挡 | SingleChildScrollView + resizeToAvoidBottomInset |
| 密码粘贴 | 允许粘贴，默认不可见 |
| 新密码前后空格 | 不自动 trim（密码中空格有效），提示用户避免首尾空格 |

---

## 五、待确认问题

| # | 问题 | 建议方案 |
|---|------|---------|
| 1 | API 文档要求 `POST /api/auth/change-password` 带 `oldPassword`，但设计文档说强制改密不需要 | 先按设计文档实现（不带 `oldPassword`），**请用户确认后端是否已支持** |
| 2 | 423 兜底拦截器中如何触发全局跳转？ | 方案 A：在 ApiClient 中添加回调/事件总线。方案 B：在拦截器中读取一个全局 Provider。确认后实施 |

---

## 六、开发顺序

```
依赖改动 → UI 骨架 → 安全提示卡片 → 密码强度指示器（最复杂）
  → 新密码输入框 → 确认密码框 → 按钮 & 错误提示
  → 接入 API → 集成到路由 → 真机测试
```

---

> 计划版本：v1 | 编制日期：2026-07-22
