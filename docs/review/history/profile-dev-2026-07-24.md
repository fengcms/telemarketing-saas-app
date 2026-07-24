# 个人中心页（doc 13）开发记录 — 2026-07-24

> 关联计划：`docs/dev/PLAN_13_PROFILE.md`
> 关联设计：`docs/design/page-design/13-个人中心.md`
> 取代对象：`lib/pages/main_shell.dart` 的 `_ProfileTab` 占位页

## 一、开发前核查（接口 vs 设计文档冲突）

按项目约定，动手前先读透设计文档 + `api.md` + 源码，发现 doc 13 与真实接口字段**不符**，已通过 `AskUserQuestion` 与用户确认口径：

| 项 | doc 13 原描述 | 真实接口/模型 | 决策 |
|----|------|------|------|
| 业绩概览 | `myFollowed` / `myAnswered` / `myConverted` | `GET /api/tenant/stats/mine` 仅返回 `myLeadsTotal` + `myToday.followupCount` + `myToday.answeredCount` | 用真实字段 |
| 所属租户 | `User.tenantName` | `User` 模型无此字段 | 取自 `GET /api/tenant/profile` 的 `data.name`，新增 `fetchTenantName()` |

业绩 4 列最终口径：**我的线索** (`myLeadsTotal`) / **今日跟进** (`myToday.followupCount`) / **今日接通** (`myToday.answeredCount`) / **今日待办** (`dueToday`，复用共享 `scheduleStatsProvider`)。

## 二、实现内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| `lib/pages/profile/profile_page.dart` | 🆕 新建 | `ConsumerStatefulWidget`：首屏骨架屏 / 业绩错误重试 / 下拉刷新 / 角色可见性 / 退出登录确认弹窗；约 330 行 < 560 红线 |
| `widgets/profile_user_card.dart` | 🆕 新建 | 头像(姓名首字) + 姓名 + 角色标签 + 邮箱 + 租户名 |
| `widgets/profile_stats_card.dart` | 🆕 新建 | 我的业绩 4 列白卡 + 列间细线 |
| `widgets/profile_menu_row.dart` | 🆕 新建 | `ProfileMenuGroup`(标题+白卡) + `ProfileMenuRow`(图标+标题+箭头) |
| `lib/services/tenant_service.dart` | ✅ 修改 | 新增 `fetchTenantName()`（`profile.data.name`），不动原 `fetchProfile()` |
| `lib/pages/main_shell.dart` | ✅ 修改 | 删除 `_ProfileTab` 占位类，4 号位换 `const ProfilePage()`，移除无用 `authProvider` 引用 |

### 数据来源
- 用户信息：`authProvider`（本地缓存，来自登录响应）。
- 所属租户：`tenantService.fetchTenantName()`（`GET /api/tenant/profile`）。
- 业绩概览：`homeService.fetchMyStats(today)`（`GET /api/tenant/stats/mine`）。
- 今日待办：共享 `scheduleStatsProvider.dueToday`（`GET /api/tenant/schedules/stats/mine`，幂等 load）。
- 角色可见性：`TE` 隐藏「团队统计」入口，`TM`/`TA` 显示。
- 子页（通话记录/客户列表/设置/团队统计/个人统计）：本轮跳 `ComingSoonPage` 占位，待后续节点。

### 关键坑规避
`TDCell` / `TDAvatar` / `TDRefreshHeader` / `TDSkeleton` 等项目**零先例**组件 + tdesign 0.2.7 兼容坑 → 全部改用已验证模式（`CircleAvatar` / 自定义 `Container` 行 / `RefreshIndicator` / `ShimmerBlock` / 自定义 `Tag`）。颜色对齐 TDesign 规范（brand-7 `#0052D9`、gray-1 `#F3F3F3`、gray-6 `#A6A6A6`、gray-12 `#181818`）。

## 三、真机实测后 5 处 UI 调整（纯 UI，不改逻辑/接口）

| # | 调整 | 改动点 |
|---|------|------|
| 1 | 用户卡删「所属租户」前缀 | `profile_user_card.dart`：`'所属租户: $tenantName'` → `'$tenantName'` |
| 2 | 「我的业绩」标题缩小+灰 | `profile_page._sectionTitle`：16px gray-12 → 14px gray-6；删未用 `_textPrimary` |
| 3 | 4 指标收白卡 + 细线分隔 | `profile_stats_card.dart`：背景 gray-1 → `Colors.white`+轻阴影；列间插细线；骨架屏同步白底 |
| 4 | 删「功能」标题 | `ProfileMenuGroup` 改 `title.isEmpty` 不渲染标题；`profile_page` 功能组 `title: ''` |
| 5 | 退出登录整合进菜单 | `ProfileMenuRow` 新增 `Color? color`；功能组末尾加退出项（红字）；删底部独立按钮 |

## 四、修复：`VerticalDivider` 在 Row 内不显示（踩坑）

**现象**：用户实测指出第 3 项「列间细灰线」未按约定出现。

**根因**：原 `_divider()` 用 `VerticalDivider(width:1, thickness:1, indent:14, endIndent:14)` 置于 `Row` + `Expanded` 列之间。`VerticalDivider` 内部 `height: double.infinity`，在 Row 与 `Expanded` 混排、交叉轴高度约束不确定的情况下，渲染成 **0 高不可见**（或高度塌缩）。

**修复**：改为手写固定高细线，保证上下留隙且必定显示：
```dart
Widget _divider() => SizedBox(
      height: 28,
      child: Container(width: 1, color: const Color(0xFFE7E7E7)),
    );
```
详见 `docs/dev/DEVELOPMENT_PITFALLS.md §11.7`。

## 五、验证

- `flutter analyze` 全工程 **0 issue**（含 profile 模块新增 4 文件）。
- `flutter build apk --debug --dart-define=DEV_TOOLS=true` 构建成功。
- `adb install -r` 安装到 Redmi K60（`3e06fd6d`）并启动，真机复测 5 处调整 + 细线修复通过。

## 六、遗留（非阻塞，用户未要求本轮做）

- 子页（通话记录/客户列表/设置/团队统计/个人统计）均为 `ComingSoonPage` 占位。
- `login_page.dart` 仍 612 行（第三轮审查 P3 观察项）。
