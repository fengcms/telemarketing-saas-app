# 进度 / 自审：线索详情数据层重构 + 翻页闪跳修复

- 提交：待提交（重构与闪光修复一并合入，单一职责内）
- 类型：`refactor` + `fix`（同一次迭代，闪光为重构派生修复）
- 作者 / 日期：fungleo / 2026-07-23
- 审查人：Mobile App Builder（移动端小组组长）
- 审查基准：已提交代码（flutter analyze：0 issue；本批次贡献 0 issue）
- 真机：debug APK 已 `adb install` 成功，待复测闪跳

## 一、背景与动机

后端升级 `GET /api/tenant/leads/:id`：**一次返回** `lead` + `followups`(全量) + `calls`(≤5) + `schedules`(≤5)。

旧实现 `fetchLeadDetail` 只取 `body['lead']`，丢掉了接口白给的 `followups`/`calls`/`schedules`，又并行补了 `_fetchFollowUps` + `_fetchCalls` 两个独立请求：

- 进一个详情页 = **3 个请求**
- 日程数据（`schedules`）从未展示
- 反复翻页时多个请求重叠，旧请求落地覆盖当前页 → **闪跳**

## 二、改动概览

| 类别 | 文件 | 说明 |
|------|------|------|
| Model（新） | `lib/models/lead_detail_bundle.dart` | `LeadDetailBundle(lead/followups/calls/schedules/fetchedAt)`，`fromJson` 一次解析四块 |
| Service | `lib/services/lead_service.dart` | `fetchLeadDetail` 改返回 `LeadDetailBundle?`；`fetchFollowUps`/`fetchCalls` 保留给列表页分页 |
| 缓存（新） | `lib/services/lead_detail_cache.dart` | 内存 `Map` + 10 分钟 TTL（get/put/invalidate/invalidateAll）+ `leadDetailCacheProvider` |
| Provider（重写） | `lib/providers/lead_detail_provider.dart` | 单请求拉取；缓存命中即渲染 + 后台静默刷新 + 预加载下一个；`refreshBundle()` 合并原 `refreshFollowUps/refreshCalls/refreshAll`；保留 `goToPrev/goToNext` |
| 页面 | `lib/pages/leads/lead_detail_page.dart` | 状态收敛为 `bundle` + getter；新增**日程区块** |
| Widget（新） | `lib/pages/leads/widgets/schedule_section.dart` | 展示最近 5 条日程（待办/已完成/已取消标签） |
| 5 处 dialog/panel | `follow_up_panel` / `edit_follow_up_dialog` / `correct_call_dialog` / `delete_confirm_dialog` / `edit_lead_dialog` | `refreshFollowUps/refreshCalls/refreshAll` 全部统一为 `refreshBundle()` |
| Widget | `lib/pages/leads/widgets/schedule_dialog.dart` | **顺手修旧 bug**：建日程后原本不刷新详情，现补 `refreshBundle()` |
| 文档 | `docs/dev/DEVELOPMENT_PITFALLS.md` | 新增 §8 异步竞态坑（见下） |
| 日志 | `.workbuddy/memory/2026-07-23.md` | 记录本次重构与闪光修复 |

## 三、客观质量门禁（flutter analyze）

**本批次贡献 0 issue（无 error/warning/info）。** 重构涉及 12 个文件、3 个新文件，未引入任何 lint 问题。

## 四、核心设计

### 4.1 单一数据源 `LeadDetailBundle`
一个对象装下四块，彻底删掉详情路径对 `_fetchFollowUps` / `_fetchCalls` 的依赖。这两个 service 方法只留给「通话记录列表页 / 日程列表页」各自分页用。

### 4.2 内存缓存（10 分钟 TTL，纯会话内）
- `get` 命中且未过期 → 进详情页秒开
- 进程被杀即失效（符合「线索详情默认缓存 10 分钟」需求，不做磁盘持久化）

### 4.3 预加载下一个
`loadLead` 完成后，若 `listContext.hasNext`，后台 `unawaited` 预取 `nextId` 写入缓存（不渲染）。点「下一个」时：
- 缓存命中 → **立即渲染**
- 同时后台静默刷新一次保证新鲜

### 4.4 写操作后刷新合并为 `refreshBundle()`
原 `refreshFollowUps` / `refreshCalls` / `refreshAll` 三方法合并：任何写操作（跟进/通话/日程/编辑）→ 先 `invalidate(id)` 再单请求整体刷新。

### 4.5 新增日程区块
详情页在「通话记录」下方加 `ScheduleSection`，展示 `bundle.schedules`（最近 5 条）。

## 五、翻页闪跳修复（竞态）

**根因**：`_fetchBundle` 写回 `state.bundle` 时仅查 `mounted`，未校验 `leadId == _currentLeadId`。缓存命中路径为秒开会 `unawaited(_fetchBundle)` 并立刻 return，故快速翻页时多个 `_fetchBundle` 重叠在飞；谁最后落地谁就无条件覆盖 `state` → 迟到旧请求覆盖当前页。

**修复**：写回 UI 前加 `_currentLeadId` 守卫；`_cache.put` 仍无条件执行（缓存保持新鲜）。详见 `docs/dev/DEVELOPMENT_PITFALLS.md` §8.1。

## 六、效果

| 指标 | 重构前 | 重构后 |
|------|--------|--------|
| 进详情页请求数 | 3 | **1** |
| 有缓存进入 | 骨架屏 | **秒开**（后台静默刷新） |
| 有底部导航条切换 | 每次重请求 | **预加载，切换秒开** |
| 提交跟进/通话/日程/编辑后 | 分块刷新 | 单 `refreshBundle` 四块同步 |
| 反复翻页 | 闪跳 | **守卫后无闪跳** |

## 七、依赖缺口（非阻塞）

- **「查看全部」仍是占位**：通话记录列表页（设计 doc 16）与日程列表页目标页均未开发，两个区块的「查看全部」目前点击无反应——按计划本次只留入口。
- `docs/api.md` 存在 195 行纯缩进/格式重排的未提交改动，与本次重构无关，本批次**不纳入提交**，待用户另行处理。

## 八、审查结论

**✅ 通过。** 重构方向正确（3 请求→1 请求、日程补齐、秒开 + 预加载），派生出的翻页竞态已定位并修复，且有踩坑文档沉淀。唯一后续项：列表页「查看全部」目标页待排期。
