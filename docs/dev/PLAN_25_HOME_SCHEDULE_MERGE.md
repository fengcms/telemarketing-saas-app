# 首页日程接口合并改造计划（PLAN_25）

> 关联需求：`docs/dev/API_HOME_SCHEDULE_MERGE.md`
> 后端对接指引：`docs/dev/HOME_SCHEDULE_MERGE_FRONTEND_GUIDE.md`
> 目标版本：v0.27（首页请求 4 → 2）
> 日期：2026-07-25

---

## 一、评审结论：后端回复**符合需求**

对照需求文档（`API_HOME_SCHEDULE_MERGE.md`）逐字段核验后端回复（`HOME_SCHEDULE_MERGE_FRONTEND_GUIDE.md`）：

| 需求项 | 后端实现 | 结论 |
|---------|-----------|------|
| 端点 `GET /api/tenant/schedules/home-summary`，无参 | ✅ 一致，鉴权 `Bearer` 与列表一致 | 通过 |
| 角色收敛（TE 仅本人 / TM-TA 全团队） | ✅ 一致 | 通过 |
| `todayPending`（严格今日窗口，00:00:00~23:59:59） | ✅ 一致 | 通过 |
| `dueSoonCount`（未来 30 分钟） | ✅ 一致 | 通过 |
| `schedules[≤5]`（结构与 `Schedule.fromJson` 同构，含 `lead` 快照） | ✅ 一致，`phone` 永非空字符串（无则 `""`） | 通过，前端零模型改动 |
| `pendingTotal`（全量待办） | ✅ 需求标注「可选」，后端提升为**必返** | 更优，接受 |
| `todayCompleted` / `todayCancelled` | ⚪ 后端未返回 | 需求标注「预留未来版本，当前未使用」，可接受 |

**总评**：字段、口径、结构、时区（服务端北京时间）全部对齐，可直接进入改造。

### ⚠️ 需产品确认的差异点（评审发现）

1. **`todayPending` ≠ 旧 `dueToday`（口径收窄）**
   旧 `dueToday` = `scheduledAt ≤ 今日 23:59:59`（**含历史逾期**）；新 `todayPending` = 严格今日窗口（**排除逾期**）。存在逾期待办时，新值更小、更精确。
   → 此口径为我方需求文档**明确定义**的预期行为，后端实现正确，**非缺陷**。

2. **首页与底部 Tab / 个人中心角标会出现数值不一致（重要）**
   `dueToday` 被 4 处消费：
   - ① 首页「待办日程」Badge（`home_schedule_section`）
   - ② 首页四宫格「今日到期」卡（`home_stats_section`，经 `HomePageState.stats.dueToday` 合并而来）
   - ③ 底部 Tab「日程」角标（`main_shell` → 共享 `scheduleStatsProvider.dueToday`）
   - ④ 个人中心「今日待办」（`profile_page` → 同一共享 provider）

   本次合并**只替换首页的 3 个请求**（① ② 改读 `home-summary.todayPending`），后端**未下线** `GET /api/tenant/schedules/stats/mine`。因此 ③ ④ 仍读旧 `dueToday`（含逾期）。
   → 改造后：首页 Badge/四宫格 用 `todayPending`（偏小），Tab 角标/个人中心 用 `dueToday`（偏大），**两者可能不一致**。

   处理建议（见第四节待确认）：首页按需求用 `todayPending`；Tab/个人中心是否同步切换为 `todayPending` 口径，需产品决策 + 后端在 `schedules/stats/mine` 也返回 `todayPending`（或前端改读 `home-summary`）。**本次改造不涵盖 ③ ④**。

---

## 二、改造范围（仅首页，不动 Tab / 个人中心）

### 改动文件
| # | 文件 | 改动 |
|---|------|------|
| 1 | `lib/services/api_constants.dart` | 新增 `homeSummary` 常量；**保留** `schedulesStatsMine`（Tab/个人中心仍用） |
| 2 | `lib/services/home_service.dart` | 删除 `fetchPendingSchedules` / `fetchMyScheduleStats` / `fetchDueSoonCount`（**注意：是 `HomeService` 的这三个，不是 `ScheduleService` 的**）；新增 `fetchHomeSummary()` |
| 3 | `lib/models/home_summary.dart`（**新建**） | `HomeSummary.fromJson` 解析聚合对象 |
| 4 | `lib/providers/home_provider.dart` | `HomePageState` 增加 `todayPending`；移除 `scheduleTotal`（仅占位、UI 从未渲染）；`loadData` / `_silentRefresh` 改为 2 个并发（`fetchMyStats` + `fetchHomeSummary`）；移除 `scheduleStats` 合并逻辑 |
| 5 | `lib/pages/home/home_stats_section.dart` | 四宫格「今日到期」卡：`stats.dueToday` → `state.todayPending` |
| 6 | `lib/pages/home/home_schedule_section.dart` | Badge：`state.stats?.dueToday` → `state.todayPending` |

### 不动文件（明确排除，避免误删）
- `lib/services/schedule_service.dart` 的 `fetchMyScheduleStats`（Tab/个人中心用）
- `lib/providers/schedule_stats_provider.dart`
- `lib/pages/main_shell.dart`、`lib/pages/profile/*`（依赖 `schedules/stats/mine` 的 `dueToday`）

---

## 三、详细改造

### 3.1 常量 `api_constants.dart`
```dart
static const String homeSummary = '/api/tenant/schedules/home-summary';
// schedulesStatsMine 保留不动（main_shell / profile 仍调用）
```

### 3.2 新建模型 `lib/models/home_summary.dart`
```dart
/// 首页日程聚合响应（GET /api/tenant/schedules/home-summary）
class HomeSummary {
  final int todayPending;
  final int dueSoonCount;
  final int pendingTotal;
  final List<Schedule> schedules;

  const HomeSummary({
    this.todayPending = 0,
    this.dueSoonCount = 0,
    this.pendingTotal = 0,
    this.schedules = const [],
  });

  factory HomeSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map? ?? {};
    final List<Schedule> items = (data['schedules'] as List?)
            ?.map((e) => Schedule.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return HomeSummary(
      todayPending: _toInt(data['todayPending']),
      dueSoonCount: _toInt(data['dueSoonCount']),
      pendingTotal: _toInt(data['pendingTotal']),
      schedules: items,
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
```
> `schedules` 直接复用 `Schedule.fromJson`；`phone` 由后端保证永非空字符串，`leadPhone` 得到 `""` 而非 `null`，无崩溃风险。

### 3.3 `home_service.dart`
- **删除** `fetchPendingSchedules` / `fetchMyScheduleStats` / `fetchDueSoonCount` 三个方法及其文件头注释。
- **新增**：
```dart
/// 首页日程聚合（今日待办 + 即将到期 + 预览列表）
Future<HomeSummary> fetchHomeSummary() async {
  try {
    final response = await _apiClient.dio.get(ApiConstants.homeSummary);
    final data = response.data;
    if (data is Map && data['success'] == true) {
      return HomeSummary.fromJson(data as Map<String, dynamic>);
    }
    throw const ApiException(
      statusCode: 200, code: 'UNKNOWN', message: '获取首页日程失败');
  } on DioException catch (e) {
    throw ApiClient.parseError(e);
  }
}
```
- `fetchMyStats`（四宫格业务统计）保留。

### 3.4 `home_provider.dart`
**`HomePageState`** 增加字段、移除 `scheduleTotal`：
```dart
final int todayPending;   // 新增：首页「今日待办」来源（替代 stats.dueToday）
// scheduleTotal 删除（原仅占位，UI 从未渲染）
```
`copyWith` 同步：`todayPending: todayPending ?? this.todayPending`，删除 `scheduleTotal` 行。

**`loadData()`** 改为 2 并发：
```dart
final results = await Future.wait([
  _safeCall(() => homeService.fetchMyStats(today)),
  _safeCall(() => homeService.fetchHomeSummary()),
]);
if (_isDisposed) return;

final statsResult = results[0];
final summary = results[1] as HomeSummary?;

HomeStats? mergedStats;
String? statsError;
if (statsResult is HomeStats) {
  mergedStats = statsResult;
} else {
  statsError = '加载统计数据失败';
}

state = state.copyWith(
  isInitialLoading: false,
  stats: mergedStats,
  schedules: summary?.schedules,
  todayPending: summary?.todayPending ?? 0,
  dueSoonCount: summary?.dueSoonCount ?? 0,
  isLoadingStats: false,
  isLoadingSchedules: false,
  statsError: statsError,
  schedulesError: summary == null ? '加载日程失败' : null,
);
```
> 删除原 `scheduleStatsResult` 合并分支、`scheduleTotal` 赋值、`schedulesResult` 元组解构。

**`_silentRefresh()`** 同样改为 2 并发（`fetchMyStats` + `fetchHomeSummary`），映射 `todayPending` / `dueSoonCount` / `schedules`。

### 3.5 UI 改动
- `home_stats_section.dart:104`：
  `'${state.todayPending}'`（原 `'${stats.dueToday}'`；`state` 在 widget 内可直接访问）。
- `home_schedule_section.dart:51` 与 `:63`：
  `state.todayPending`（原 `state.stats?.dueToday ?? 0`）。
- `home_page.dart` 到期提醒条已用 `state.dueSoonCount`，**不变**。

---

## 四、验证清单

- [ ] `flutter analyze` 0 issue
- [ ] release + `DEV_TOOLS=true` APK 构建成功，安装 Redmi K60
- [ ] 真机首屏：四宫格「今日到期」、待办 Badge、预览列表（≤5）、到期提醒条、空态、错误重试均正常
- [ ] **Alice 抓包确认首屏仅 2 个请求**：`stats/mine` + `home-summary`（不再有 `schedules/stats/mine` 与 `schedules?status=pending` 两次冗余）
- [ ] 回归：退出重登后首页数据正确重置（`reset()` 不受影响）

## 五、待确认（产品决策，不阻塞本次改造）

1. **Tab / 个人中心角标口径**：是否同步切换为 `todayPending`（严格今日、排除逾期）？若切换：
   - 需后端在 `GET /api/tenant/schedules/stats/mine` 也返回 `todayPending`，或前端改由 `home-summary` 读取；
   - 涉及 `main_shell.dart` / `profile_page.dart` / `schedule_stats_provider.dart` 三处改动，另排期。
   - 不切换则接受首页与 Tab 角标数值可能不一致。

## 六、收益

| 指标 | 改造前 | 改造后 |
|------|--------|--------|
| 首页并行请求 | 4 次 | **2 次** |
| 日程区冗余/重复请求 | 3 次（#2 列表 + #3 统计 + #4 时间窗） | 0（合并进 `home-summary`） |
| 删除代码 | — | 约 70 行（3 方法 + 合并逻辑） |
| 新增代码 | — | 约 40 行（模型 + 聚合方法 + 字段映射） |
