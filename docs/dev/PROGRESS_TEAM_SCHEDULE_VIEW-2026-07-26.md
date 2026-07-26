# 进度文档：团队日程视图（v0.24）+ 角色标签修复

> 日期：2026-07-26
> 计划：`docs/dev/PLAN_28_TEAM_SCHEDULE_VIEW.md`
> 对应 `PLAN_24_TEAM_MODULE.md` 阶段二；可见角色：TM（租户经理）/ TA（租户管理员），TE 不可见切换。

## 完成内容

| 模块 | 状态 | 说明 |
|------|:----:|------|
| 归属人颜色圆点 | ✅ | `ScheduleCard` 增 `ownerColor`（`Color?`）参数；列表页在 `items` 循环里统一用 `userColor(id)` 计算后下发（卡片保持纯展示，与现有 `ownerName` 下发方式一致）。圆点 10px 圆形色块，置于归属人行。 |
| 团队统计摘要条 | ✅ | 新建 `widgets/team_schedule_header.dart` 的 `TeamScheduleHeader`（仅 `scope==team` 渲染）：今日待办 N（brand 色 bold）/ 逾期 M（error 色 bold，为 0 时转灰），高 48、背景 `BrandColors.surface`。 |
| 员工筛选 | ✅（方案② 后端 userId 过滤） | `_OwnerSheetContent` + `_MemberTile`；`AppBottomSheet.show` 列出成员（颜色圆点 + 姓名 + 角色标签），顶部「全部成员」项（灰圆点）。选中 `selectOwner(id)` 重新请求 `fetchSchedules(userId: 选中id)` 替换团队列表；成员维度独立缓存键，不污染全团队缓存。 |
| Provider 改造 | ✅ | `ScheduleListState` 增 `teamStats`（`ScheduleStats?`）+ `selectedOwnerId`（`String?`）；`_cacheKey` 改为含 owner；切 team 时 `_loadTeamStats()`；`switchScope` 重置 `selectedOwnerId` + 重拉；`selectOwner` 重置+重拉；`refresh` 同步拉团队统计。 |
| 角色标签修复（开发中发现，连带） | ✅ | 用户贴出 `/options/users` 返回每条带 `role`，但筛选只显姓名 → 读源码坐实 `OptionItem.fromJson` 只取 `id/name/type`、`role` 被静默丢弃。补 `OptionItem.role` 字段 + 解析；抽共享 `lib/theme/role_label.dart` 的 `roleLabel()`（电销专员/团队经理/管理员），`profile_page` 私有 `_roleLabel` 改为复用；筛选成员项现显示「姓名 · 角色」。 |

## 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 员工筛选实现 | 方案② 后端 userId 过滤 | 与现有分页加载现状吻合，列表与统计均准确；方案① 前端过滤易漏未滚动加载到的分页数据，统计偏差 |
| 日期筛选 | 放弃 | 现有按日期分组 + 吸顶头 + 点击滚动已覆盖核心诉求，避免一次塞太多 |
| 角色标签 | 补 `OptionItem.role` + 抽 `roleLabel()` 共享 | 接口一直返回 role，本地模型此前未接；抽共享函数避免与 `profile_page` 既有映射重复、保证全端术语一致 |

## 验证

- `flutter analyze`：本次 5 个改动文件 + 新建 3 文件（team_schedule_header / role_label / PLAN）**0 error 0 warning**；全仓仅余 `token_storage.dart` 11 个预存 `unnecessary_non_null_assertion` warning（与本次无关）。
- 构建 `flutter build apk --release --dart-define=DEV_TOOLS=true` 成功（60.4MB），`flutter install` 装到 Redmi K60（2211133C，旧版自动卸载替换）。
- 真机实测通过（用户确认），验证清单（PLAN_28 §七）5 项全部满足。

## 待开发（本节点未做）

- 团队统计独立页（阶段三 v0.25，需引入 `fl_chart`）——独立节点，本次明确不做。
- 日期筛选——已放弃。
- `OptionItem` 增 `role` 为 nullable，不影响分类/项目/快捷备注等其它 `fromJson` 调用方（那些接口不返回 role，得 null）。
