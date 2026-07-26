# 首页/个人中心 入口接线修复（2026-07-26）

> 本节点为 v0.25 团队统计页完成后的快修：修复两处「已建好页面却仍跳 ComingSoon 占位」的漏接线入口。
> 个人中心「我的业绩」按用户选择**保持 ComingSoon**（个人统计整页未建，属另一独立功能）。

## 完成内容

| 入口 | 位置 | 修复前 | 修复后 |
|------|------|--------|--------|
| 首页快捷入口「通话记录」 | `home_quick_entry_section.dart:49` | 跳 `ComingSoonPage(featureName:'通话记录')` | 跳 `CallRecordsPage()`（v0.17 已建） |
| 首页 AppBar「团队看板」（TM/TA 可见） | `home_page.dart:133` | 跳 `ComingSoonPage(featureName:'团队看板')` | 跳 `TeamStatsPage()`（v0.25 已建） |
| 个人中心「我的业绩」 | `profile_page.dart:200` | 保持 `ComingSoonPage` | **保持不变**（个人统计整页未建） |

### 改动文件

| 文件 | 改动类型 | 说明 |
|------|---------|------|
| `lib/pages/home/home_quick_entry_section.dart` | ✅ 修改 | import `coming_soon_page` → `call_records_page`；onTap 改 push `CallRecordsPage()` |
| `lib/pages/home/home_page.dart` | ✅ 修改 | import `coming_soon_page` → `team_stats_page`；AppBar 入口 onTap 改 push `TeamStatsPage()` |

### 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 个人中心「我的业绩」 | 保持 ComingSoon | 用户明确选「首页/个人中心 占位接线」快修方向，个人统计整页未建，不在本次范围 |
| 导航方式 | `Navigator.push`（非 go_router） | 全仓既有入口统一走 `Navigator.push`，保持一致性 |

## 验证

| 验证项 | 结果 |
|------|------|
| `flutter analyze`（2 文件） | No issues found（0 error 0 warning） |
| 构建 + 装真机 | `app-release.apk` 59MB（DEV_TOOLS 浮标），`adb install -r` 到 Redmi K60 |
| 真机实测 | 通过（用户确认两条入口跳转正常） |

## 残留 ComingSoon 占位（全仓现状）

经扫描，当前剩余 `ComingSoonPage` 引用仅：

- `profile_page.dart`：「我的业绩 / 个人统计」入口（个人统计整页未建）

其余此前占位的页面（通话记录 v0.17 / 客户列表 v0.18 / 设置 v0.20 / 修改密码 v0.21 / 团队统计 v0.25 / 日程搜索 v0.19 等）**已全部接好**。

## 下一步建议

- **个人统计页**（设计文档 `14-个人统计.md` 已就绪）：个人中心唯一仍占位的子页，是天然的下一个功能节点（v0.32 候选）。
- 或：团队视图日期筛选（v0.24 放弃项）、线索子页硬编码色收尾等增强项。
