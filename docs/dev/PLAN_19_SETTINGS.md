# 开发计划：v0.20 设置页（doc 19）

> **设计文档**：`docs/design/page-design/19-设置页.md`
> **入口**：个人中心 → 设置
> **目标版本**：v0.20
> **计划日期**：2026-07-25
> **UI 框架**：Material 3（TDesign 已移除）

---

## 一、页面概述

设置页为从个人中心 **Push 进入的二级页面**，**不含底部 TabBar**，仅顶部 AppBar 带返回箭头。

### 布局结构（自顶向下）

```
┌──────────────────────────────────────┐
│ AppBar: "设置"（品牌蓝底 + 返回箭头）│
├──────────────────────────────────────┤
│                                      │
│  ── 账户安全（品牌蓝 14px 区域标题） │
│  [Icons.lock]  修改密码           >  │
│                                      │
│  ── 账户操作（品牌蓝 14px 区域标题） │
│  [Icons.logout] 退出登录（红色）     │
│  [devices]     全设备退出登录        │
│                                      │
│  ── 关于（品牌蓝 14px 区域标题）     │
│  [Icons.info_outline] 关于        >  │
│                                      │
│            (底部留白)                 │
│        电销工作台 v1.0.0             │
│        后端版本: v0.1.0              │
└──────────────────────────────────────┘
```

### TDesign → M3 组件映射

| 设计文档旧组件 | M3 替代 |
|--------------|---------|
| `TDNavBar` | `AppBar`（主题已配置：蓝底白字 18px Medium） |
| `TDCellGroup` + `TDCell` | `Card` + `ListTile`（主题已配置：白底细边框 6px 圆角） |
| `TDDialog`（退出确认） | `AppDialog.confirm` |
| `TDDialog`（关于弹窗） | `AlertDialog`（自定义内容布局） |
| `TDToast` | `AppToast.show` |
| `TDIcons.*` | `Icons.*`（见下方映射） |

### 图标映射

| TDIcons | Material Icons | 说明 |
|---------|---------------|------|
| `lock_on` | `Icons.lock` | 修改密码 |
| `logout` | `Icons.logout` | 退出登录（红色） |
| `desktop` | `Icons.devices` | 全设备退出登录 |
| `info_circle` | `Icons.info_outline` | 关于 |
| `chevron_right` | `Icons.chevron_right` | 右侧箭头 |

---

## 二、接口依赖

### 2.1 GET /health — 获取后端版本

- **用途**：页面加载时后台静默请求，获取后端版本号用于关于弹窗和底部版本信息
- **响应**（已确认真实返回）：
  ```json
  {
    "success": true,
    "data": { "ok": true, "ts": 1784954786417, "version": "0.1.0" },
    "error": null
  }
  ```
- **无需鉴权**
- **错误处理**：失败时版本显示"获取失败"，不影响页面其他功能

### 2.2 POST /api/auth/logout — 退出登录

- **已有实现**：`AuthNotifier.logout()` / `AuthService.logout()`
- **行为**：调接口 → finally 清除本地 Token → 跳转登录页（失败也清除）

### 2.3 POST /api/auth/logout-all — 全设备退出登录

- **需新增实现**：`AuthService.logoutAll()`
- **行为**：调接口 → 成功清除 Token 跳转登录页 + Toast "已在所有设备上退出登录"
- **失败处理**：Toast "操作失败，请重试"，不执行本地退出

---

## 三、改动清单

### 3.1 新增文件

| 文件 | 说明 |
|------|------|
| `lib/pages/settings/settings_page.dart` | 设置页主文件（ConsumerStatefulWidget，约 200-300 行） |
| `lib/services/health_service.dart` | GET /health 取版本号 |

### 3.2 修改文件

| 文件 | 改动 |
|------|------|
| `lib/services/api_constants.dart` | 补 `static const String health = '/health'` |
| `lib/services/auth_service.dart` | 新增 `logoutAll()` 方法 |
| `lib/providers/auth_provider.dart` | 新增 `logoutAll()` 方法（如必要） |
| `lib/pages/profile/profile_page.dart` | 设置菜单由 `ComingSoonPage` 改为 `SettingsPage()` |

---

## 四、交互细节

### 4.1 退出登录
1. 点击「退出登录」→ `AppDialog.confirm(title: '退出登录', content: '确定退出登录？')`
2. 用户点「确定」→ 调 `authProvider.logout()`
3. 无论接口成功/失败 → 清除本地 Token → 跳转登录页

### 4.2 全设备退出登录
1. 点击「全设备退出登录」→ `AppDialog.confirm(title: '全设备退出登录', ...)`
2. 确认后调 `authProvider.logoutAll()`（需新增）
3. 仅成功才清除本地 Token + AppToast "已在所有设备上退出登录" + 跳转登录页
4. 失败时 AppToast "操作失败，请重试"，不跳转

### 4.3 关于
1. 点击「关于」→ 弹出自定义 AlertDialog（标题"关于"、APP 图标/名称/版本信息行）
2. 底部「确定」按钮关闭

### 4.4 修改密码
- 跳转修改密码页（doc 15 未开发），**暂跳 ComingSoonPage 占位**

---

## 五、样式规格

| 元素 | 规格 |
|------|------|
| AppBar 背景 | `BrandColors.primary` (#0052D9) |
| AppBar 标题 | 18px Medium 白色 |
| 区域标题 | 14px, `BrandColors.primary`, 左 padding 16px, 上间距 24px(首区域16px), 下间距 8px |
| 列表容器 | 白底 6px 圆角 Card（主题 CardTheme 已配） |
| 列表项 | ListTile，左图标 20px 灰色，标题 16px |
| 退出登录（特殊） | 图标和标题红色 `BrandColors.error` |
| 底部版本 | 12px 灰色 60% 透明度，居中 |

---

## 六、状态设计

| 状态 | 表现 |
|------|------|
| 初始加载 | 页面渲染静态列表，/health 请求中 → 后端版本显示"加载中..." |
| 加载完成 | 后端版本更新显示 |
| /health 失败 | 后端版本显示"获取失败" |
| 退出登录中 | 弹窗按钮显示 loading |
| 全设备登出中 | 弹窗按钮显示 loading |

---

## 七、待确认事项

> ☑ 已确认：/health 返回 version 字段，可按 api.md 实现。

**等待用户确认本计划**，确认后进入开发。
