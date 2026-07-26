# 线索筛选「归属人」角色可见性修复（v0.33）

> 类型：bug 修复（非功能新增）
> 日期：2026-07-26
> 关联节点：`docs/dev/MILESTONES.md` v0.33

## 问题

员工（`tenant_employee`）登录后，进入「我的线索 → 筛选抽屉」，里面出现了「归属人」选项。

但后端对该角色的线索列表请求强制 `scope='mine'`，员工只能看自己的线索，
`ownerId` 参数被后端忽略——「归属人」筛选对员工既不可用、也与列表数据口径矛盾，属错误暴露。

## 根因

`lib/pages/ads/widgets/leads_filter_sheet.dart` 的 `_buildOwnerSection()`（「归属人」区块）
对所有角色**无条件渲染**，UI 没有与后端 `scope` 语义对齐：

- `tenant_admin` / `tenant_manager`（TM/TA）→ `scope='all'`，能看到全部线索，「归属人」筛选有意义；
- `tenant_employee`（员工）→ `scope='mine'`，只能看自己，「归属人」筛选无意义。

## 修复

| 文件 | 改动 |
|------|------|
| `lib/pages/ads/widgets/leads_filter_sheet.dart` | `build()` 内取 `ref.read(authProvider).user?.role`，仅当 `role == 'tenant_admin' \|\| role == 'tenant_manager'` 时才渲染「归属人」区块（连同其前后 `SizedBox(height:16)` 间距一并包进 `if (canFilterByOwner) ...[]`，间距不残留、不缺失） |
| `lib/pages/ads/leads_list_page.dart` | 顶部激活筛选标签栏里的「归属」标签同样加 `isManager` 判定（`_buildFilterTags(state, isManager)` 显式传参），与抽屉角色可见性保持一致 |

判定写法沿用全端既有真实值约定（`lib/theme/role_label.dart` 为单一术语源），不引入新字符串常量。

## 验证

| 验证项 | 结果 |
|------|------|
| `flutter analyze` | 2 文件 0 issue |
| 构建 + 装真机 | `app-release.apk` 59MB（DEV_TOOLS 浮标），Redmi K60（`3e06fd6d`） |
| 真机实测 | ✅ 通过（用户确认「测试通过」）：员工登录筛选抽屉**不再出现「归属人」**；TM/TA 登录正常显示并可按归属人筛选 |

## 影响面说明

- 仅影响「我的线索」筛选 UI 的角色可见性，**不动任何接口 / 数据层 / scope 逻辑**。
- 员工即便历史上残留 `ownerId`，后端 `scope='mine'` 本就忽略，无功能影响；本次额外把激活标签栏的「归属」也门控，避免残留标签呈现。
- 与 v0.29 已修复的「角色短写 TM/TA → 真实值」为同一角色语义体系，本次是同一体系下的可见性补全。
