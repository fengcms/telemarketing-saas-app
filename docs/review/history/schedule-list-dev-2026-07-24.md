# 日程列表页 开发计划与记录（v0.12）

> 日期：2026-07-24
> 对应设计文档：`docs/design/page-design/10-日程列表.md`
> 范围：仅列表页；详情页（doc 11）/ 新建（doc 12）拆下一节点 v0.13

## 一、决策确认（用户拍板）

| 决策 | 内容 |
|------|------|
| **a** | 本次只做**列表页**，日程详情页（doc 11）拆下一节点 v0.13 |
| **b** | **跨天重算**先简化（MVP 只做回前台/切 Tab 重算），在本文档记为"待开发"，机制用户暂不判断 |
| **c** | 按建议建**轻量共享 `ScheduleStatsProvider`**，底部 Tab 角标与列表 Tab 计数同源 |
| **d** | 现在就补 `users` 缓存 —— 经核对 `OptionsCacheService` 的 `getUserName`/缓存**已存在**，直接复用，无需新增 |

## 二、接口核对结论

**当前接口完全满足设计文档，无需后端改动。**

| 设计需求（doc 10） | api.md 现状 | 结论 |
|------|------|------|
| 列表 `GET /api/tenant/schedules` | §1345+ | ✅ 已含 `status`/`status__in`/`page`/`size`/`sort`/`userId`（⚠️ `order` 为 api.md 笔误，后端不认，已删除，见 PITFALLS §8.2） |
| 统计 `GET /api/tenant/schedules/stats/mine` | §1638+ | ✅ 返回 `byStatus{pending,completed,cancelled,overdue,dueToday}` |
| 团队视图 | §1347「TE 仅自己，TM/TA 全团队」 | ✅ **不传 `userId`** 即团队，传 `userId=当前用户.id` 即"我的" |
| 电话不脱敏 | §1347/1391 | ✅ `lead.name/phone` 直接返回 |
| 归属映射 `options/users` | §729 | ✅ 已存在，`OptionsCacheService.getUserName` 就绪（决策 d 免补） |

## 三、实现要点

### 1. 模型 / 服务层（新增）
- `lib/models/schedule_stats.dart`：`ScheduleStats`（byStatus 五字段 + `fromJson`，兼容完整响应或 data 层）
- `lib/models/schedule.dart`：**补 `userId` 字段**（`fromJson` 解析），供"归属"映射
- `lib/services/schedule_service.dart`：
  - `fetchSchedules(status/userId/page/size/sort)` → `(items, total, serverTime)`（**`order` 参数为 api.md 笔误，后端不认，已删除**）
  - `fetchMyScheduleStats()` → `ScheduleStats`
  - **服务端时间**复用 `HomeService.getServerTime(response)`（从响应头 Date 解析），免额外请求；逾期判定用
- `OptionsCacheService`：`getUserName` 已具备，直接复用（决策 d 免改）

### 2. 共享统计（决策 c）
- `lib/providers/schedule_stats_provider.dart`：
  - `scheduleStatsProvider`：单一拉取 `/schedules/stats/mine`，暴露 `dueToday`/`pending`/`completed`
  - 底部 Tab 角标（dueToday）+ 列表 Tab 计数（pending/completed）**共用此源**，避免重复请求

### 3. 列表状态（决策 a + 防竞态）
- `lib/providers/schedule_list_provider.dart`：
  - 双 Tab（pending/completed）+ 范围（mine/team，仅 TM/TA）
  - 切 Tab / 范围重置 `page=1`，并用 **`_generation` 代际守卫**忽略过期响应（对齐首页 §7.1"取消上一请求"，并复用详情页闪跳修复思路）
  - 下拉刷新同时刷新统计 + 列表；上拉 `page+1` 拼接

### 4. 页面与组件（新增 `lib/pages/schedules/`）
- `schedule_list_page.dart`：TD 风格顶栏（标题 + TM/TA 范围切换）+ 双 Tab 栏（带计数）+ `CustomScrollView`
- `widgets/schedule_card.dart`：常规/逾期/已完成/已取消 四态；归属人经 `userNameProvider` 异步解析
- `widgets/schedule_date_header.dart`：日期吸顶头（今天/明天/后天/本周/更早）
- `widgets/schedule_overdue_header.dart`：红色"已逾期(N)"吸顶
- **分组算法**（纯前端）：待办 Tab 先取逾期（serverTime 判定）置顶，其余按 `scheduledAt` 日期分桶；逾期/日期头用 `SliverPersistentHeader(pinned:true)` 吸顶
- 空态/错误态/骨架屏；点击卡片 → 暂跳 `ComingSoonPage(featureName:'日程详情')`（v0.13 落地）

### 5. 路由与角标联动
- `lib/pages/main_shell.dart`：日程 Tab 由 `ComingSoonPage` 占位替换为 `ScheduleListPage()`；底部「日程」icon 包 `Badge` 显示 `scheduleStatsProvider.dueToday`

## 四、待开发项（本节点未做，已记入文档）

### ⚠️ 跨天重算（决策 b）
- **现状**：日期分组标签按**设备本地时间**计算，跨天后不会自动刷新；逾期判定用接口返回的服务端时间（准确）。
- **影响**：凌晨跨天后，"今天/明天"等标签需等下拉刷新或切 Tab 重建才更新。
- **计划**：在回前台（`onResume`）/ 切 Tab 时触发重算（类同首页 `HomePage` 的 `WidgetsBindingObserver` + `onResume`）。**机制用户暂不判断**，记为待开发。

### 其他待开发
- **日程详情页（doc 11）**：卡片点击目标，下一节点 v0.13。
- **列表项操作（完成/取消）** + **新建日程（doc 12）**：详情/操作面板，拆 v0.13。
- **团队视图统计**：`/schedules/stats`（团队）未接入，当前角标取"我的"`dueToday`。

## 五、校验
- `flutter analyze`：**No issues found**（全量 0 issue）
- debug APK（含 Alice 浮窗 + 登录预填，dev-only）已构建并 `adb install` 供真机实测
- ✅ **真机实测通过（2026-07-24，debug 版）**：登录正常、日程列表双 Tab / TM-TA 范围切换 / 逾期置顶 / 吸顶头 / 底部角标 / 下拉刷新 / 上拉加载 / 反复切 Tab 不闪跳 均正常；Alice 浮窗可抓全部请求与响应
- ⚠️ 待日常 release 构建命令再验一次（排查期间发现 release 模式 Dart 异常不可见，见 PITFALLS §8.7）

## 六、文件清单
| 文件 | 动作 |
|------|------|
| `lib/models/schedule_stats.dart` | 新增 |
| `lib/models/schedule.dart` | 改（补 `userId`） |
| `lib/services/schedule_service.dart` | 新增 |
| `lib/providers/schedule_stats_provider.dart` | 新增 |
| `lib/providers/schedule_list_provider.dart` | 新增 |
| `lib/pages/schedules/schedule_list_page.dart` | 新增 |
| `lib/pages/schedules/widgets/schedule_card.dart` | 新增 |
| `lib/pages/schedules/widgets/schedule_date_header.dart` | 新增 |
| `lib/pages/schedules/widgets/schedule_overdue_header.dart` | 新增 |
| `lib/pages/main_shell.dart` | 改（接列表页 + 角标） |

## 七、修复追加记录（v0.12 实测后）

> 以下为 2026-07-24 真机实测后陆续修复的问题，均已在 release + dev 构建下验证。

### 7.1 下拉刷新整页变灰（release 灰屏）
- 根因：`_dateKey` 生成分组 key 时月份/日期未补零（如 `2026-7-24`），`_dateTitle` 又用 `DateTime.parse(key)` 回解析 → release 下抛 `FormatException`，整页 build 失败被灰屏 ErrorWidget 取代。
- 修复：key 统一补零为 `YYYY-MM-DD`；并明确"分组 key 不要字符串 round-trip 再 parse，尽量直接持 DateTime"。
- 教训：**release 灰屏 = build 期未捕获异常**（debug 是红屏）。凡在 build 内对服务端数据做解析/格式化，必须防御非法输入。

### 7.2 切 Tab / 范围不重加载（数据缓存）
- `schedule_list_provider` 新增 `_TabCache`（`key=$scope:$tab`）。`switchTab`/`switchScope` 命中缓存直接复用；`_reload({force})` 留给下拉刷新；`loadMore`/`_loadInitial` 也回写缓存。

### 7.3 归属显示 id 而非姓名
- 根因：`options_cache_service` 的 `_ensureLoaded()` 用 fire-and-forget 调刷新，首查时 `_users` 仍空 → `getUserName` 回退 id，且 `userNameProvider`(FutureProvider) 把 id 永久缓存。
- 修复：改为 `await` 同一刷新 Future（`_loadingFuture` 共享，仅发一次请求）。

### 7.4 卡片时间仅 hh:mm → 加年月日
- `schedule.dart` 新增 `dateTimeDisplay`（yyyy-MM-dd HH:mm，月日时分补零）；`schedule_card` 改用；保留 `timeDisplay`(hh:mm) 供首页紧凑预览。

### 7.5 Alice 浮标挡控件 → 可拖拽
- `app.dart` 的 `_DevToolsFloatingButton` 改 StatefulWidget + `GestureDetector` 拖拽（clamp 屏内）；纯点击才 `showInspector()`。

### 7.6 自然周分组边界
- `_dateTitle` 改为自然周（周一为起点）：本周=`_isSameWeek(dt,today)`、下周=`_isSameWeek(dt,today+7d)`，避免滚动窗口误判出两个「本周」。

### 7.7 线索详情「新建日程」日期/时间「确定」无反应
- 根因：`TDPicker.showDatePicker` 的 `onConfirm` 类型是 `Map<String,int>`（不是 `DateTime`），原 `as DateTime` 在 release 下抛 `CastError` 被吞；且确认后需手动 `pop`。
- 修复：回调读 `Map` 重建 `DateTime`/`TimeOfDay`，并补 `Navigator.pop()`。

### 7.8 分组重构为语义桶（消除重复头）
- 原按天分桶 → 同一自然周多天各带日程时出多个同名头。重写为**语义桶**（每类仅一个头）：待办=已逾期/今天/明天/后天/本周/下周/更晚；已完成镜像（今天/昨天/本周/上周/更早）。空桶不显示。

### 7.9 下拉刷新闪现 + 骨架屏优化 + 吸顶头
- `isRefreshing` 状态：刷新时显骨架屏，不再闪现旧数据。
- 抽离公共 `schedule_skeleton.dart`（`ScheduleSkeleton` + shimmer 扫光，待办/已完成两 Tab 共用）。
- 吸顶头加底部分割线（`0xFFE0E0E0` 0.5px），点击平滑滚动到对应组别（`Scrollable.ensureVisible`）。
- 踩坑：本项目 Flutter 版 `LinearGradient` 不支持 `transform`，shimmer 改用随动画进度平移 `stops` 实现。

### 7.10 移除卡片「线索姓名+手机号」展示
- 用户调整策略：新建日程时把线索姓名+手机号写进标题，卡片不再单独展示该行。删除 `schedule_card` 中 `leadName`+`leadPhone`（`phoneSuffix`）整块，保留归属行（userId→用户名）。
