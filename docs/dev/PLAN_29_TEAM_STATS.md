# 开发计划：v0.25 团队统计独立页（PLAN_29）

> 设计文档：`docs/design/page-design/21-团队统计.md`（v1.1）
> 接口依据：`docs/api.md` §2196 `GET /api/tenant/stats`
> 前置节点：v0.24（团队日程视图，已提交 `9dbde3e`）
> 关联常量：`lib/services/api_constants.dart:44` `statsTeam = '/api/tenant/stats'`（已定义，此前未调用）

## 一、目标与范围

**做满设计文档 21 的全部内容**（一个独立 Push 页面，TM/TA 可见）：

1. 顶部 AppBar（标题"团队看板" + 返回 + 刷新）
2. 吸顶日期范围选择器：今日 / 本周 / 本月 / 自定义（≤90 天，Material 日期范围选择器）
3. 概览卡片 2×2：总线索数 / 公海线索 / 转化率 / 跟进中
4. 转化漏斗（4 阶段进度条，基=漏斗 pool）
5. 状态分布环形图（fl_chart PieChart，5 状态）
6. 逐日趋势折线图（fl_chart LineChart，3 系列）
7. 坐席绩效排行（可排序列表，前 10 + 查看更多）
8. 状态：首屏骨架 / 空态（total=0 或"no data in range"） / 错误态 + 重试 / 部分数据缺失降级
9. 轻量动画（数字淡入、进度条展开、fl_chart 内置动画）+ 跟随 M3 主题（深色自适应）

**不做（本节点）**：`byCategory` / `byProject` / `byAnswerType` 展示（设计文档 §7.4 明确 MVP 不展示）；个人统计页（14-个人统计.md，独立占位，不在 v0.25）；漏斗/折线"第四条线"（`dailyTrend.added`/`total`）。

## 二、接口与真实响应结构（已用 TA token 抓包确认）

> ✅ **契约已锁定（2026-07-26 后端修正）**：seed 聚合键误写 `pool` 已全链路修正为 `pending`（`byStatus["pending"]` 即公海 = status=pending & ownerId IS NULL），`design.md` 已同步、测试库脏数据已 UPDATE。客户端**统一用 `pending` 单键，不写 `pool` 兼容**。`agentPerf[]` 仍**不返回 `conversionRate`**（前端算）。其余字段与文档一致。

真实响应（已验证，`GET /api/tenant/stats?dateFrom=2026-07-16&dateTo=2026-07-23`）：

```json
{
  "success": true,
  "data": {
    "total": 1125,
    "byStatus": { "pending": 186, "assigned": 535, "following": 220, "converted": 103, "invalid": 81 },
    "poolTotal": 0,
    "staleInPool": 0,
    "funnel": { "pending": 1125, "assigned": 755, "following": 220, "converted": 103 },
    "addedCount": 229, "followupCount": 70, "convertedCount": 7, "answeredCount": 32,
    "agentPerf": [
      { "userId":"u...03", "name":"销售经理", "ownedLeads":4, "followupCount":27,
        "answeredCount":14, "noAnswerCount":1, "convertedCount":3, "avgDuration":0, "lastFollowupAt":1784707340 }
    ],
    "dailyTrend": [
      { "date":"2026-07-16", "added":4, "followup":12, "converted":1, "answered":3, "total":86 }
    ],
    "compareYesterday": { "addedDiff":-205, "followupDiff":-4, "convertedDiff":0 }
  },
  "error": null
}
```

### 字段映射表（前端模型 ← 真实响应）

| 页面位置 | 真实字段 | 设计文档原字段 | 备注 |
|---------|---------|-------------|------|
| 概览·总线索数 | `total` | `total` | 千分位 |
| 概览·公海线索 | `poolTotal` | `poolTotal` | 公海总量（样本=0） |
| 概览·公海呆滞 | `staleInPool` | `staleInPool` | >0 时 warning 高亮 |
| 概览·转化率 | `ΣagentPerf.convertedCount / ΣagentPerf.ownedLeads` | 同上 | **前端算**，无 `conversionRate` 字段 |
| 概览·跟进中 | `byStatus.following` | `byStatus.following` | |
| 漏斗 4 阶段 | `funnel.{pending,assigned,following,converted}` | 同 | 基=`funnel.pending`（修正键） |
| 状态分布环形 | `byStatus.{pending,assigned,following,converted,invalid}` | 同 | 公海=`pending`（修正键） |
| 折线 3 系列 | `dailyTrend[].{followup,answered,converted}` | 同 | X=`date`(MM-DD) |
| 坐席排行 | `agentPerf[]{name,ownedLeads,followupCount,answeredCount,convertedCount}` | 同 | `conversionRate` 前端算 |
| 环比（仅今日范围） | `compareYesterday.{addedDiff,followupDiff}` | 同 | `convertedDiff` 不展示 |

### ⚠️ 后端数据坑（需后端确认，前端按规则兜底）

样本里 `funnel.pool = 0`（而 `funnel.assigned = 755`）。按设计文档 §7.1 规则"若 `pool=0`，所有进度条显示 0%"，**漏斗会渲染为空**。
这疑似后端 `funnel.pool` 计算错误（应为最大基数）。**前端严格按 §7.1 实现（pool=0 → 0%），不猜测后端修复方式**；同时在本计划标注，请 TA 确认 `funnel.pool` 是否应为非零基数。若后端修正，无需改前端。

## 三、数据层设计

### 3.1 模型 `lib/models/team_stats.dart`（新建）

```dart
class TeamStats {
  final int total;
  final TeamStatusBreakdown byStatus;   // pending/assigned/following/converted/invalid
  final int poolTotal;
  final int staleInPool;
  final TeamFunnel funnel;                // pending/assigned/following/converted
  final List<AgentPerf> agentPerf;
  final List<DailyTrend> dailyTrend;
  final TeamCompare compareYesterday;
  // byCategory/byProject/byAnswerType：解析但本节点不展示
  const TeamStats({...});
  factory TeamStats.fromJson(Map<String,dynamic> json) {...}
  double get teamConversionRate {  // 团队级口径 §3.3
    final owned = agentPerf.fold(0, (s,a)=>s+a.ownedLeads);
    final conv = agentPerf.fold(0, (s,a)=>s+a.convertedCount);
    return owned == 0 ? 0.0 : conv / owned * 100;
  }
}
// TeamStatusBreakdown{pending,assigned,following,converted,invalid} + get sum
// TeamFunnel{pending,assigned,following,converted}
// AgentPerf{userId,name,ownedLeads,followupCount,answeredCount,noAnswerCount,convertedCount,avgDuration,lastFollowupAt}
//   + get conversionRate => ownedLeads==0?0:convertedCount/ownedLeads*100
// DailyTrend{date,added,followup,converted,answered,total} + get mmdd
// TeamCompare{addedDiff,followupDiff,convertedDiff}
```

> 字段名直接对齐 JSON（camelCase）：`ownedLeads`/`followupCount`/`answeredCount`/`convertedCount`/`noAnswerCount`/`avgDuration`/`lastFollowupAt` 均原样。

### 3.2 服务 `lib/services/team_stats_service.dart`（新建）

```dart
class TeamStatsService {
  final ApiClient _api;
  TeamStatsService({required this._api});
  Future<TeamStats> fetchTeamStats({
    required String dateFrom, required String dateTo,
  }) async {
    final resp = await _api.get(ApiConstants.statsTeam,
      queryParameters: {'dateFrom': dateFrom, 'dateTo': dateTo});
    final data = resp.data['data'];
    // "no data in range"：data 含 message 无统计字段 → 抛 NoDataInRangeException
    if (data is Map && data.containsKey('message') && !data.containsKey('total')) {
      throw NoDataInRangeException();
    }
    return TeamStats.fromJson(data as Map<String,dynamic>);
  }
}
final teamStatsServiceProvider = Provider<TeamStatsService>((ref) =>
  TeamStatsService(apiClient: ref.read(apiClientProvider)));
```

### 3.3 Provider `lib/providers/team_stats_provider.dart`（新建）

```dart
enum DateRangeKind { today, thisWeek, thisMonth, custom }

class TeamStatsState {
  final bool isLoading;
  final TeamStats? stats;
  final Object? errorMessage;
  final DateRangeKind rangeKind;
  final String dateFrom;   // YYYY-MM-DD
  final String dateTo;
  // 同范围 5 分钟缓存（§7.2）：key="$from~$to"
}

class TeamStatsNotifier extends StateNotifier<TeamStatsState> {
  load({bool force = false});          // 命中缓存 5min 且不 force 则跳过
  setRangeToday();                    // from=to=今天
  setRangeThisWeek();                 // from=本周一, to=今天
  setRangeThisMonth();                // from=本月1号, to=今天
  setCustomRange(String from, String to); // 校验 from<=to, 跨度<=90天
  refresh() => load(force: true);
}
final teamStatsProvider =
  StateNotifierProvider<TeamStatsNotifier, TeamStatsState>((ref) =>
    TeamStatsNotifier(ref)..load());
```

- 日期计算：周一 = `now.subtract(Duration(days: now.weekday - 1))`；格式化用 `DateFormat('yyyy-MM-dd')`（Flutter 自带 intl）。
- 自定义范围：`showDateRangePicker` 选起止；`from > to` 前端拦截提示；跨度 >90 天提示"最多查看 90 天"。
- 缓存：`Map<String, _CachedItem>` 存 `TeamStats` + 时间戳，5 分钟内同 key 直接复用。

## 四、UI 结构（M3 适配，替代设计文档 TDesign 组件）

> 设计文档用 TDesign 组件，本项目已全面换 M3（见项目记忆）。按下表等价替换：

| 设计文档组件 | M3 实现 |
|------|------|
| `TDNavBar` | `AppBar`（title "团队看板"、leading 返回、actions 刷新 IconButton） |
| `TDTagGroup`（日期范围） | `ChoiceChip` 行（选中 brand 色调，未选 gray），`CustomScrollView`+`SliverPersistentHeader` 吸顶 |
| 概览卡片 | M3 `Card`（白底，页面灰底 `BrandColors.surface` 透出）+ 大数字 `Text` |
| `TDCollapse` | `ExpansionTile`（包在 `Card` 内） |
| `TDSkeleton` | 现有 `ShimmerBlock` |
| `TDCalendarPicker` | `showDateRangePicker`（Material 原生） |

### 页面骨架 `lib/pages/team_stats/team_stats_page.dart`

```
Scaffold(
  appBar: AppBar(leading: 返回, title: 团队看板, actions: [刷新]),
  body: Consumer(builder: (ctx, ref, _) {
    final s = ref.watch(teamStatsProvider);
    if (s.errorMessage != null) return ErrorState(retry: refresh);
    if (s.stats == null) return Skeleton;            // 首屏骨架
    if (s.stats!.total == 0) return EmptyState(切换日期);
    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(日期范围 ChoiceChip 行, pinned: true),
        SliverToBoxAdapter(概览 2×2 卡片),
        SliverToBoxAdapter(ExpansionTile 转化漏斗),
        SliverToBoxAdapter(ExpansionTile 状态分布 + fl_chart PieChart),
        SliverToBoxAdapter(ExpansionTile 逐日趋势 + fl_chart LineChart),
        SliverToBoxAdapter(ExpansionTile 坐席排行 + 排序 Chip + 列表),
      ],
    );
  }),
)
```

### 子组件（均放 `lib/pages/team_stats/widgets/`）

| 组件 | 内容 |
|------|------|
| `date_range_selector.dart` | `ChoiceChip` 行（今日/本周/本月/自定义）+ 自定义触发 `showDateRangePicker` |
| `overview_cards.dart` | 2×2 卡片；大数字 `formatBigNumber` + 千分位 + >7 位转"万"；环比行仅 `rangeKind==today` 显示 |
| `conversion_funnel.dart` | 4 行进度条（`AnimatedContainer` 宽度动画），基=`funnel.pending`（后端修正键，正常为非零基数；base<=0 防御显 0%） |
| `status_donut.dart` | `fl_chart` `PieChart`（环宽 32、中心叠 `total` 文字、右排图例 5 项） |
| `trend_line_chart.dart` | `fl_chart` `LineChart`（3 系列 followup/answered/converted、tooltip、区域填充 10%） |
| `agent_ranking.dart` | 排序 `ChoiceChip`（转化率/转化数/跟进数/接通数）+ `ListView`（前 10，>10 显"查看全部 N 名"）+ 排名徽标金/银/铜 |

### 颜色（抽 `lib/theme/chart_colors.dart`，复用 BrandColors 常量）

| 语义 | 色值 |
|------|------|
| 品牌蓝 brand-7 | `#0052D9` |
| 品牌蓝浅 brand-6 | `#366EF4` |
| 成功绿 success-7 | `#2BA471` |
| 成功绿深 success-7-deep | `#1F8A56` |
| 警告橙 warning-7 | `#E37318` |
| 无效灰 gray-4 | `#DCDCDC` |

> 折线"转化数"用 success-7-deep（与接通数 success-7 区分，修正设计文档原红色语义，见 §3.7 v1.1）。

### 大数字格式化 `formatBigNumber(int)`

- ≤4 位：`48sp`；5~7 位：回落 `36sp`；>7 位：转"万"单位（如 `12.3万`）回 `48sp`。
- `Text` 始终 `maxLines:1 + overflow:ellipsis`。

### 动画（轻量，不引新依赖）

- 数字：`AnimatedSwitcher`（fade 300ms）。
- 漏斗条：`AnimatedContainer`（width 动画 500ms）。
- 图表：fl_chart 自带 `animationDuration`（环形 600ms / 折线 800ms）。
- 坐席列表：条目淡入（可选，先不做交错动画，保持简单）。

## 五、关键技术决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 图表库 | 引入 `fl_chart` | 用户确认；环形+折线开箱即用、可定制 M3 风格 |
| 字段来源 | 以 `pending` 为统一键 | 后端已修正 seed 键 `pool`→`pending`；`conversionRate` 后端不返需前端算 |
| 入口 | 替换 `profile_page` 的 `ComingSoonPage` | 已有 `if(isManager)` 门禁，直推 `TeamStatsPage`，无需 go_router 注册 |
| 路由 | `Navigator.push(MaterialPageRoute)` | 与全仓既有页面一致 |
| 缓存 | Provider 内 5 分钟按范围 key | 设计文档 §7.2，避免频繁切范围重复请求 |
| 漏斗基 | `funnel.pending`（修正键） | 后端 seed 键已修 `pool`→`pending`，正常为非零基数；保留 base<=0 防御（显 0%） |
| 深色模式 | 跟随 M3 `colorScheme` | 不单独建深色色板，低风险 |
| 空态触发 | `total==0` 或 `NoDataInRangeException` | 对齐 §5.2 |

## 六、文件清单

**新建**
- `lib/models/team_stats.dart`
- `lib/services/team_stats_service.dart`
- `lib/providers/team_stats_provider.dart`
- `lib/theme/chart_colors.dart`
- `lib/pages/team_stats/team_stats_page.dart`
- `lib/pages/team_stats/widgets/date_range_selector.dart`
- `lib/pages/team_stats/widgets/overview_cards.dart`
- `lib/pages/team_stats/widgets/conversion_funnel.dart`
- `lib/pages/team_stats/widgets/status_donut.dart`
- `lib/pages/team_stats/widgets/trend_line_chart.dart`
- `lib/pages/team_stats/widgets/agent_ranking.dart`
- `docs/dev/PLAN_29_TEAM_STATS.md`（本文件）
- `docs/dev/PROGRESS_TEAM_STATS-2026-07-26.md`（进度，开发后补）

**修改**
- `pubspec.yaml`（加 `fl_chart: ^0.70.0`，版本以 `flutter pub get` 解析为准）
- `lib/pages/profile/profile_page.dart`（团队统计入口 `ComingSoonPage` → `TeamStatsPage`）

## 七、验证计划（按项目流程）

1. `flutter pub get` 拉 `fl_chart`，`flutter analyze` 全仓 0 issue（除预存 `token_storage.dart` 无关 warning）。
2. 构建 `app-release.apk`（dev 浮标开关可选），装 Redmi K60 真机实测。
3. 真机验证项：
   - 默认"本周"范围正常出数；切今日/本月/自定义均正常；自定义 >90 天 / `from>to` 拦截提示。
   - 4 模块（漏斗/环形/折线/排行）渲染正确；环形 5 色、折线 3 色与文档一致。
   - 坐席排序切换生效；>10 人显"查看全部"。
   - 环比行仅"今日"范围显示。
   - 空态（切到无数据范围）、错误态（断网重试）正常。
4. 实测通过后写进度文档 + 踩坑文档，`git commit & push`。

## 八、风险 / 待确认

1. ~~**`funnel.pool` 样本为 0**~~ → 已解决：后端全链路修正 seed 键 `pool`→`pending`（`design.md` 已同步、测试库脏数据已 UPDATE），客户端统一用 `pending`，漏斗基数正常。
2. `fl_chart` 具体版本以 `pub get` 解析为准（可能 0.70/0.71+），若有兼容告警再调。
3. 状态分布环形：公海段对应 `byStatus.pending`（=status=pending & ownerId IS NULL，权威定义），标签用"公海"；其余 已分配/跟进中/已转化/无效 沿用文档。
4. `compareYesterday` 仅 `addedDiff`/`followupDiff` 用于概览卡片（设计文档 §6.1：`convertedDiff` MVP 不展示）。
